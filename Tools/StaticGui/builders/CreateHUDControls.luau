--[[
	CreateHUDControls.lua
	Location: StarterGui (as LocalScript) — generated into StarterGui/HUDControls.model.json

	PURPOSE (feature 001):
	Always-on-top controls that stay usable above an open window's backdrop:
	  - MenuButtons: a left-centre vertical column (Shop, Inventory; room for
	    Rewards/Quests later), each >= 56x56 with a key label and a gamepad glyph
	  - Hotbar: moved out of HUD so it also sits above the backdrop

	DisplayOrder 10 keeps this ScreenGui above InventoryUI/ShopUI (5) and HUD (0).
	Sizes/positions marked "runtime" are set by ResponsiveLayout; the values here
	are the 1920x1080 defaults. Colours come from the UITheme tokens.
]]

-- Theme tokens: offline the generator sets the global UI_THEME; in Studio the
-- module is required directly.
local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))

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

--[[ MENU BUTTONS — left-centre vertical column ]]
local MenuButtons = Instance.new("Frame")
MenuButtons.Name = "MenuButtons"
MenuButtons.AnchorPoint = Vector2.new(0, 0.5)
MenuButtons.Position = UDim2.new(0, 12, 0.5, 0) -- runtime
MenuButtons.Size = UDim2.new(0, 56, 0, 248)     -- runtime (4 buttons tall)
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
	button.BackgroundColor3 = Theme.Control
	button.BorderSizePixel = 0
	button.Text = emoji
	button.TextSize = 30
	button.TextColor3 = Theme.TextPrimary
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Selectable = false -- window frames own gamepad selection, not these
	button.LayoutOrder = order
	button.Parent = MenuButtons

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	-- Key label (PC): shown in KeyboardMouse mode by InputActions.
	local keyHint = Instance.new("TextLabel")
	keyHint.Name = "KeyHint"
	keyHint.AnchorPoint = Vector2.new(1, 1)
	keyHint.Position = UDim2.new(1, -2, 1, -2)
	keyHint.Size = UDim2.new(0, 20, 0, 20)
	keyHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	keyHint.BackgroundTransparency = 0.4
	keyHint.BorderSizePixel = 0
	keyHint.Text = keyLabel
	keyHint.TextColor3 = Theme.TextPrimary
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

makeMenuButton("ShopButton", "🛒", "B", 1)
makeMenuButton("InventoryButton", "🎒", "I", 2)

--[[ TELEPORT ROW (US6) — a horizontal row of quick-travel buttons, top-right so
     it is clear of the coin HUD (top-left), the day/night bar (top-centre), the
     menu column (left) and the hotbar (bottom). Inside the safe area via the
     ScreenGui's CoreUISafeInsets. Each button >= 44x44. ]]
local TeleportRow = Instance.new("Frame")
TeleportRow.Name = "TeleportRow"
TeleportRow.AnchorPoint = Vector2.new(1, 0)
TeleportRow.Position = UDim2.new(1, -8, 0, 8)
TeleportRow.Size = UDim2.new(0, 3 * 52 + 2 * 6, 0, 52)
TeleportRow.BackgroundTransparency = 1
TeleportRow.Parent = HUDControls

local teleLayout = Instance.new("UIListLayout")
teleLayout.FillDirection = Enum.FillDirection.Horizontal
teleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
teleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
teleLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleLayout.Padding = UDim.new(0, 6)
teleLayout.Parent = TeleportRow

local function makeTeleportButton(name, emoji, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 52, 0, 52) -- >= 44x44 (FR-013)
	button.BackgroundColor3 = Theme.Control
	button.BorderSizePixel = 0
	button.Text = emoji
	button.TextSize = 26
	button.TextColor3 = Theme.TextPrimary
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.LayoutOrder = order
	button.Parent = TeleportRow

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	return button
end

-- Render-safe glyphs (Roblox's font does not render 🏪 / 🪙): shop cart, seedling,
-- coin bag for the seller's stall.
makeTeleportButton("TeleportShop", "🛒", 1)
makeTeleportButton("TeleportGarden", "🌱", 2)
makeTeleportButton("TeleportStall", "💰", 3)

--[[ HOTBAR — moved from HUD; runtime position and slot size ]]
local Hotbar = Instance.new("Frame")
Hotbar.Name = "Hotbar"
Hotbar.Size = UDim2.new(0, 340, 0, 110)        -- runtime
Hotbar.Position = UDim2.new(0.5, -170, 1, -130) -- runtime
Hotbar.BackgroundTransparency = 1
Hotbar.Parent = HUDControls

local defaultEmojis = { "💧", "🥕", "🏮" }
for i = 1, 3 do
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. i
	slot.Size = UDim2.new(0, 100, 0, 100)
	slot.Position = UDim2.new(0, (i - 1) * 110, 0, 0)
	slot.BackgroundColor3 = Theme.SurfaceRaised
	slot.BorderSizePixel = 0
	slot.Parent = Hotbar

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 10)
	slotCorner.Parent = slot

	local slotButton = Instance.new("TextButton")
	slotButton.Name = "SlotButton"
	slotButton.Size = UDim2.new(1, 0, 1, 0)
	slotButton.BackgroundColor3 = Theme.Control
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
	emojiLabel.TextColor3 = Theme.TextMuted
	emojiLabel.TextSize = 40
	emojiLabel.Font = Enum.Font.GothamBold
	emojiLabel.Text = defaultEmojis[i]
	emojiLabel.Parent = itemIcon

	local selectionBorder = Instance.new("ImageLabel")
	selectionBorder.Name = "SelectionBorder"
	selectionBorder.Size = UDim2.new(1, 8, 1, 8)
	selectionBorder.Position = UDim2.new(0.5, 0, 0.5, 0)
	selectionBorder.AnchorPoint = Vector2.new(0.5, 0.5)
	selectionBorder.BackgroundTransparency = 1
	selectionBorder.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	selectionBorder.ImageColor3 = Theme.Accent
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
	keybindHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	keybindHint.BackgroundTransparency = 0.5
	keybindHint.BorderSizePixel = 0
	keybindHint.Text = tostring(i)
	keybindHint.TextColor3 = Theme.TextPrimary
	keybindHint.TextSize = 18
	keybindHint.Font = Enum.Font.GothamBold
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

print("✅ HUDControls created (MenuButtons + Hotbar)")
