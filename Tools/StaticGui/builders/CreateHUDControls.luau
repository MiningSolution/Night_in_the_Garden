--[[
	CreateHUDControls.lua
	Location: StarterGui (as LocalScript) — generated into StarterGui/HUDControls.model.json

	PURPOSE (feature 001, relaid out in feature 005):
	Always-on-top controls that stay usable above an open window's backdrop:
	  - PrimaryNav: a top-centre horizontal bar SEEDS / GARDEN / SELL (feature 005
	    cosy-garden concept). SEEDS opens the shop, GARDEN/SELL request a teleport.
	  - MenuButtons: a left-centre vertical column BAG / QUESTS / GIFTS, each >= 56x56
	    with a key label and a gamepad glyph.
	  - Hotbar: a bottom-centre strip of five tool slots (feature 005). Slots fill
	    from the inventory-driven hotbar list; trailing empty slots show a locked
	    placeholder until a tool/seed exists for them.

	DisplayOrder 10 keeps this ScreenGui above InventoryUI/ShopUI (5) and HUD (0).
	Sizes/positions marked "runtime" are set by ResponsiveLayout; the values here
	are the 1920x1080 defaults. Colours come from the UITheme tokens.
]]

-- Theme tokens: offline the generator sets the global UI_THEME; in Studio the
-- module is required directly.
local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))
local Style = Theme.Style

-- Theme helpers: bake the Night (default) colour AND tag the token so the runtime
-- ThemeController can retint this property on a day/night switch (Theme_<Prop> =
-- "<Token>"). Non-colour style (outline thickness, corner, fonts) is single-source
-- from UITheme.Style.
local function bind(obj, prop, token)
	obj[prop] = Theme[token]
	obj:SetAttribute("Theme_" .. prop, token)
end
local function strokeOf(parent, token, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or Style.OutlineThickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = Theme[token]
	s:SetAttribute("Theme_Color", token)
	s.Parent = parent
	return s
end

local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("HUDControls") then
	print("⚠️ HUDControls already exists, skipping creation")
	return
end

print("🎨 Creating HUDControls...")

local HUDControls = Instance.new("ScreenGui")
HUDControls.Name = "HUDControls"
HUDControls.ResetOnSpawn = false
HUDControls.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HUDControls.DisplayOrder = 10
HUDControls.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
HUDControls.IgnoreGuiInset = false
HUDControls.Parent = playerGui

--[[ PRIMARY NAV (feature 005) — top-centre SEEDS / GARDEN / SELL. Fixed-size,
     centred, so it is baked here (like the old TeleportRow) rather than placed by
     ResponsiveLayout. Green = seeds/garden (action), orange = sell (handoff rule 4). ]]
local PrimaryNav = Instance.new("Frame")
PrimaryNav.Name = "PrimaryNav"
PrimaryNav.AnchorPoint = Vector2.new(0.5, 0)
PrimaryNav.Position = UDim2.new(0.5, 0, 0, 12)
PrimaryNav.Size = UDim2.new(0, 3 * 128 + 2 * 12, 0, 56)
PrimaryNav.BackgroundTransparency = 1
PrimaryNav.Parent = HUDControls

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 12)
navLayout.Parent = PrimaryNav

-- A big label-pill nav button. `bgToken` colours the pill (Accent green / Sell orange);
-- text uses TextOnAccent so it stays readable on the bright fill (both palettes).
local function makeNavButton(name, label, emoji, bgToken, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 128, 0, 56) -- >= 44x44 (FR-001)
	bind(button, "BackgroundColor3", bgToken)
	button.BorderSizePixel = 0
	button.Text = emoji .. " " .. label
	button.TextSize = 22
	bind(button, "TextColor3", "TextOnAccent")
	button.Font = Style.DisplayFont
	button.AutoButtonColor = true
	button.LayoutOrder = order
	button.Parent = PrimaryNav

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Style.CornerRadius)
	corner.Parent = button

	strokeOf(button, "OutlineDeep")

	-- PC key hint / gamepad glyph slots (filled + toggled by InputActions).
	local keyHint = Instance.new("TextLabel")
	keyHint.Name = "KeyHint"
	keyHint.AnchorPoint = Vector2.new(1, 1)
	keyHint.Position = UDim2.new(1, -2, 1, -2)
	keyHint.Size = UDim2.new(0, 20, 0, 20)
	keyHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- neutral key-chip tint (not themed)
	keyHint.BackgroundTransparency = 0.4
	keyHint.BorderSizePixel = 0
	keyHint.Text = ""
	keyHint.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyHint.TextSize = 16
	keyHint.Font = Enum.Font.GothamBold
	keyHint.Visible = false
	keyHint.Parent = button

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 6)
	keyCorner.Parent = keyHint

	local padHint = Instance.new("ImageLabel")
	padHint.Name = "PadHint"
	padHint.AnchorPoint = Vector2.new(1, 1)
	padHint.Position = UDim2.new(1, -2, 1, -2)
	padHint.Size = UDim2.new(0, 24, 0, 24)
	padHint.BackgroundTransparency = 1
	padHint.Image = ""
	padHint.Visible = false
	padHint.Parent = button

	return button
end

-- Render-safe glyphs. SEEDS opens the shop (seeds tab); GARDEN/SELL teleport.
makeNavButton("SeedsButton", "SEEDS", "🌱", "Accent", 1)
makeNavButton("GardenButton", "GARDEN", "🌼", "Accent", 2)
makeNavButton("SellButton", "SELL", "💰", "Sell", 3)

--[[ MENU BUTTONS — left-centre vertical column: BAG / QUESTS / GIFTS (feature 005) ]]
local MenuButtons = Instance.new("Frame")
MenuButtons.Name = "MenuButtons"
MenuButtons.AnchorPoint = Vector2.new(0, 0.5)
MenuButtons.Position = UDim2.new(0, 12, 0.5, 0) -- runtime
MenuButtons.Size = UDim2.new(0, 56, 0, 184)     -- runtime (3 buttons tall)
MenuButtons.BackgroundTransparency = 1
MenuButtons.Parent = HUDControls

local menuLayout = Instance.new("UIListLayout")
menuLayout.FillDirection = Enum.FillDirection.Vertical
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Padding = UDim.new(0, 8)
menuLayout.Parent = MenuButtons

-- Builds one menu button with a key label and a gamepad-glyph slot.
local function makeMenuButton(name, emoji, keyLabel, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 56, 0, 56) -- >= 44x44 (FR-002)
	bind(button, "BackgroundColor3", "Control")
	button.BorderSizePixel = 0
	button.Text = emoji
	button.TextSize = 30
	bind(button, "TextColor3", "TextPrimary")
	button.Font = Style.DisplayFont
	button.AutoButtonColor = true
	button.Selectable = false -- window frames own gamepad selection, not these
	button.LayoutOrder = order
	button.Parent = MenuButtons

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Style.CornerRadius)
	corner.Parent = button

	strokeOf(button, "OutlineDeep")

	-- Key label (PC): shown in KeyboardMouse mode by InputActions.
	local keyHint = Instance.new("TextLabel")
	keyHint.Name = "KeyHint"
	keyHint.AnchorPoint = Vector2.new(1, 1)
	keyHint.Position = UDim2.new(1, -2, 1, -2)
	keyHint.Size = UDim2.new(0, 20, 0, 20)
	keyHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- neutral key-chip tint (not themed)
	keyHint.BackgroundTransparency = 0.4
	keyHint.BorderSizePixel = 0
	keyHint.Text = keyLabel
	keyHint.TextColor3 = Color3.fromRGB(255, 255, 255) -- always white on the dark chip
	keyHint.TextSize = 18
	keyHint.Font = Enum.Font.GothamBold
	keyHint.Visible = true
	keyHint.Parent = button

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 6)
	keyCorner.Parent = keyHint

	-- Gamepad glyph: image filled + shown in Gamepad mode by InputActions.
	local padHint = Instance.new("ImageLabel")
	padHint.Name = "PadHint"
	padHint.AnchorPoint = Vector2.new(1, 1)
	padHint.Position = UDim2.new(1, -2, 1, -2)
	padHint.Size = UDim2.new(0, 24, 0, 24)
	padHint.BackgroundTransparency = 1
	padHint.Image = ""
	padHint.Visible = false
	padHint.Parent = button

	return button
end

-- Left column order: BAG (inventory), QUESTS, GIFTS (daily reward). Keys I / Q / R.
makeMenuButton("InventoryButton", "🎒", "I", 1)
makeMenuButton("QuestsButton", "📋", "Q", 2)
makeMenuButton("RewardsButton", "🎁", "R", 3)

--[[ HOTBAR — bottom-centre, five slots (feature 005); runtime position and slot size ]]
local HOTBAR_SLOTS = 5
local Hotbar = Instance.new("Frame")
Hotbar.Name = "Hotbar"
Hotbar.Size = UDim2.new(0, HOTBAR_SLOTS * 100 + (HOTBAR_SLOTS - 1) * 10, 0, 110) -- runtime
Hotbar.Position = UDim2.new(0.5, -280, 1, -130) -- runtime
Hotbar.BackgroundTransparency = 1
Hotbar.Parent = HUDControls

local defaultEmojis = { "💧", "🥕", "🏮", "🕸️", "🪏" }
for i = 1, HOTBAR_SLOTS do
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. i
	slot.Size = UDim2.new(0, 100, 0, 100)
	slot.Position = UDim2.new(0, (i - 1) * 110, 0, 0)
	bind(slot, "BackgroundColor3", "SurfaceRaised")
	slot.BorderSizePixel = 0
	slot.Parent = Hotbar

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 10)
	slotCorner.Parent = slot

	strokeOf(slot, "Outline")

	local slotButton = Instance.new("TextButton")
	slotButton.Name = "SlotButton"
	slotButton.Size = UDim2.new(1, 0, 1, 0)
	bind(slotButton, "BackgroundColor3", "Control")
	slotButton.BackgroundTransparency = 0.3
	slotButton.BorderSizePixel = 0
	slotButton.Text = ""
	slotButton.AutoButtonColor = false
	slotButton.Parent = slot

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = slotButton

	local itemIcon = Instance.new("ImageLabel")
	itemIcon.Name = "ItemIcon"
	itemIcon.Size = UDim2.new(0, 60, 0, 60)
	itemIcon.Position = UDim2.new(0.5, 0, 0.4, 0)
	itemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	itemIcon.BackgroundTransparency = 1
	itemIcon.Image = "rbxassetid://0"
	itemIcon.ScaleType = Enum.ScaleType.Fit
	itemIcon.Parent = slot

	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Name = "EmojiLabel"
	emojiLabel.Size = UDim2.new(1, 0, 1, 0)
	emojiLabel.BackgroundTransparency = 1
	bind(emojiLabel, "TextColor3", "TextMuted")
	emojiLabel.TextSize = 40
	emojiLabel.Font = Enum.Font.GothamBold
	emojiLabel.Text = defaultEmojis[i]
	emojiLabel.Parent = itemIcon

	-- Locked/empty placeholder (feature 005): a dim overlay + lock shown by
	-- HotbarController on a slot that has no tool/seed yet (e.g. the future
	-- lantern/net/shovel slots). Hidden the moment an item fills the slot.
	local lockOverlay = Instance.new("Frame")
	lockOverlay.Name = "LockOverlay"
	lockOverlay.Size = UDim2.new(1, 0, 1, 0)
	bind(lockOverlay, "BackgroundColor3", "SurfaceRaised")
	lockOverlay.BackgroundTransparency = 0.25
	lockOverlay.BorderSizePixel = 0
	lockOverlay.Visible = false
	lockOverlay.ZIndex = 3
	lockOverlay.Parent = slot

	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, 10)
	lockCorner.Parent = lockOverlay

	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockLabel"
	lockLabel.Size = UDim2.new(1, 0, 1, 0)
	lockLabel.BackgroundTransparency = 1
	lockLabel.Text = "🔒"
	bind(lockLabel, "TextColor3", "TextMuted")
	lockLabel.TextSize = 34
	lockLabel.Font = Enum.Font.GothamBold
	lockLabel.ZIndex = 3
	lockLabel.Parent = lockOverlay

	local selectionBorder = Instance.new("ImageLabel")
	selectionBorder.Name = "SelectionBorder"
	selectionBorder.Size = UDim2.new(1, 8, 1, 8)
	selectionBorder.Position = UDim2.new(0.5, 0, 0.5, 0)
	selectionBorder.AnchorPoint = Vector2.new(0.5, 0.5)
	selectionBorder.BackgroundTransparency = 1
	selectionBorder.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	bind(selectionBorder, "ImageColor3", "Accent")
	selectionBorder.ScaleType = Enum.ScaleType.Slice
	selectionBorder.SliceCenter = Rect.new(8, 8, 8, 8)
	selectionBorder.Visible = i == 1
	selectionBorder.ZIndex = 0
	selectionBorder.Parent = slot

	local keybindHint = Instance.new("TextLabel")
	keybindHint.Name = "KeybindHint"
	keybindHint.Size = UDim2.new(0, 30, 0, 25)
	keybindHint.Position = UDim2.new(0.5, 0, 1, -5)
	keybindHint.AnchorPoint = Vector2.new(0.5, 1)
	keybindHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- neutral key-chip tint (not themed)
	keybindHint.BackgroundTransparency = 0.5
	keybindHint.BorderSizePixel = 0
	keybindHint.Text = tostring(i)
	keybindHint.TextColor3 = Color3.fromRGB(255, 255, 255) -- always white on the dark chip
	keybindHint.TextSize = 18
	keybindHint.Font = Enum.Font.GothamBold
	keybindHint.ZIndex = 4
	keybindHint.Parent = slot

	local keybindCorner = Instance.new("UICorner")
	keybindCorner.CornerRadius = UDim.new(0, 6)
	keybindCorner.Parent = keybindHint
end

-- Gamepad glyphs for hotbar prev/next (L1/R1). Images are filled and shown in
-- Gamepad mode by InputActions; hidden otherwise (US5, R9).
local padHintLeft = Instance.new("ImageLabel")
padHintLeft.Name = "PadHintLeft"
padHintLeft.AnchorPoint = Vector2.new(1, 0.5)
padHintLeft.Position = UDim2.new(0, -6, 0.5, 0)
padHintLeft.Size = UDim2.new(0, 28, 0, 28)
padHintLeft.BackgroundTransparency = 1
padHintLeft.Image = ""
padHintLeft.Visible = false
padHintLeft.Parent = Hotbar

local padHintRight = Instance.new("ImageLabel")
padHintRight.Name = "PadHintRight"
padHintRight.AnchorPoint = Vector2.new(0, 0.5)
padHintRight.Position = UDim2.new(1, 6, 0.5, 0)
padHintRight.Size = UDim2.new(0, 28, 0, 28)
padHintRight.BackgroundTransparency = 1
padHintRight.Image = ""
padHintRight.Visible = false
padHintRight.Parent = Hotbar

print("✅ HUDControls created (PrimaryNav + MenuButtons + Hotbar)")
