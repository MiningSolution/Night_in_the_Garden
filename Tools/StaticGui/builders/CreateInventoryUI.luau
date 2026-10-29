--[[
    CreateInventoryUI.lua
    Location: StarterGui (as LocalScript)

    PURPOSE:
    Programmatically creates the Backpack (Inventory) UI including:
    - Header bar with title and close button
    - Five tabs (All / Seeds / Tools / Crops / Spirits)
    - Scrolling card grid (hidden CardTemplate cloned per item by InventoryController)
    - Detail panel (selected item, favourite toggle, one context action button)
    - Spirits "coming soon" placeholder and a hover tooltip

    Feature 005 US3: every themed colour is baked (Night default) AND tagged with a
    Theme_<Prop> attribute so ThemeController retints it on the day/night switch.
    Cloned cards are painted by the controller via ThemeController (R9).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Check if InventoryUI already exists
if playerGui:FindFirstChild("InventoryUI") then
    print("⚠️ InventoryUI already exists, skipping creation")
    return
end

print("🎨 Creating InventoryUI...")

-- Theme tokens: offline the generator sets the global UI_THEME; in Studio the
-- module is required directly.
local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))
local Style = Theme.Style

-- Bake the Night (default) colour AND tag the token (Theme_<Prop> = "<Token>").
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
local function gradientOf(parent, topToken, botToken)
    parent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new(Theme[topToken], Theme[botToken])
    g:SetAttribute("Theme_GradientTop", topToken)
    g:SetAttribute("Theme_GradientBottom", botToken)
    g.Parent = parent
    return g
end
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or Style.CornerRadius)
    c.Parent = parent
    return c
end
local function label(parent, name, text, size, token, font)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.BackgroundTransparency = 1
    l.Text = text
    bind(l, "TextColor3", token)
    l.TextSize = size
    l.Font = font or Style.BodyFont
    l.Parent = parent
    return l
end

-- Create main ScreenGui
local InventoryUI = Instance.new("ScreenGui")
InventoryUI.Name = "InventoryUI"
InventoryUI.ResetOnSpawn = false
InventoryUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
InventoryUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
InventoryUI.IgnoreGuiInset = false
InventoryUI.Enabled = false -- Hidden by default, opened with 'I' key
InventoryUI.Parent = playerGui

-- Full-screen dim backdrop: tapping it closes the window and the Active
-- TextButton keeps the tap from reaching the game world (FR-008).
local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
bind(Backdrop, "BackgroundColor3", "Backdrop")
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = InventoryUI

--[[ MAIN INVENTORY FRAME (sized responsively by UIController.applyLayout) ]]
local InventoryFrame = Instance.new("Frame")
InventoryFrame.Name = "InventoryFrame"
InventoryFrame.Size = UDim2.new(0, 600, 0, 500)
InventoryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
InventoryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bind(InventoryFrame, "BackgroundColor3", "Surface")
InventoryFrame.BorderSizePixel = 0
-- US5 (R8): keep gamepad selection navigation inside the open window.
InventoryFrame.SelectionGroup = true
InventoryFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
InventoryFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
InventoryFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
InventoryFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
InventoryFrame.Parent = InventoryUI
corner(InventoryFrame)
strokeOf(InventoryFrame, "OutlineDeep", Style.WindowOutlineThickness)

--[[ HEADER BAR ]]
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = InventoryFrame
gradientOf(HeaderBar, "HeaderTop", "HeaderBottom")
corner(HeaderBar)

local TitleLabel = label(HeaderBar, "TitleLabel", "🎒 BACKPACK", 24, "TextOnHeader", Style.DisplayFont)
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 44, 0, 44) -- >= 44x44 (FR-007)
CloseButton.Position = UDim2.new(1, -54, 0.5, 0)
CloseButton.AnchorPoint = Vector2.new(0, 0.5)
bind(CloseButton, "BackgroundColor3", "Danger")
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
bind(CloseButton, "TextColor3", "TextOnAccent")
CloseButton.TextSize = 24
CloseButton.Font = Style.DisplayFont
CloseButton.AutoButtonColor = false
CloseButton.Parent = HeaderBar
corner(CloseButton)

--[[ TAB CONTAINER: All / Seeds / Tools / Crops / Spirits (controller paints the active one) ]]
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -40, 0, 44)
TabContainer.Position = UDim2.new(0, 20, 0, 58)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = InventoryFrame

-- widths (scale) + 4 gaps of 0.0075 stay <= 1; wide enough for 20pt labels
local TAB_DEFS = {
    { "AllTab", "All", 0.14 },
    { "SeedsTab", "🌱 Seeds", 0.21 },
    { "ToolsTab", "🔧 Tools", 0.21 },
    { "CropsTab", "🥕 Crops", 0.21 },
    { "SpiritsTab", "👻 Spirits", 0.22 },
}
local tabX = 0
local allTab
for _, def in ipairs(TAB_DEFS) do
    local tab = Instance.new("TextButton")
    tab.Name = def[1]
    tab.Size = UDim2.new(def[3], 0, 1, 0)
    tab.Position = UDim2.new(tabX, 0, 0, 0)
    bind(tab, "BackgroundColor3", "Control")
    tab.BorderSizePixel = 0
    tab.Text = def[2]
    bind(tab, "TextColor3", "TextPrimary")
    tab.TextSize = 20 -- button label >= 20 (FR-005)
    tab.Font = Style.DisplayFont
    tab.AutoButtonColor = false
    tab.Parent = TabContainer
    corner(tab)
    strokeOf(tab, "Outline")
    if def[1] == "AllTab" then allTab = tab end
    tabX = tabX + def[3] + 0.0075
end
-- Default active tab (All) baked as the Accent look; the controller repaints on switch.
bind(allTab, "BackgroundColor3", "Accent")
bind(allTab, "TextColor3", "TextOnAccent")

--[[ ITEM GRID: scrolling cards, left column ]]
local ItemGrid = Instance.new("ScrollingFrame")
ItemGrid.Name = "ItemGrid"
ItemGrid.Size = UDim2.new(0.62, -20, 1, -116)
ItemGrid.Position = UDim2.new(0, 20, 0, 108)
bind(ItemGrid, "BackgroundColor3", "SurfaceRaised")
ItemGrid.BackgroundTransparency = 0.5
ItemGrid.BorderSizePixel = 0
ItemGrid.ScrollBarThickness = 8
bind(ItemGrid, "ScrollBarImageColor3", "Control")
ItemGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ItemGrid.Parent = InventoryFrame
corner(ItemGrid, 8)

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0, 100, 0, 130)
GridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
GridLayout.SortOrder = Enum.SortOrder.Name
GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GridLayout.Parent = ItemGrid

local GridPadding = Instance.new("UIPadding")
GridPadding.PaddingTop = UDim.new(0, 8)
GridPadding.PaddingBottom = UDim.new(0, 8)
GridPadding.PaddingLeft = UDim.new(0, 8)
GridPadding.PaddingRight = UDim.new(0, 8)
GridPadding.Parent = ItemGrid

--[[ CARD TEMPLATE (hidden; InventoryController clones + paints it per item) ]]
local Card = Instance.new("Frame")
Card.Name = "CardTemplate"
Card.Size = UDim2.new(0, 100, 0, 130)
bind(Card, "BackgroundColor3", "SurfaceRaised")
Card.BorderSizePixel = 0
Card.Visible = false
Card.Parent = ItemGrid
corner(Card)
strokeOf(Card, "Outline")

local CardIcon = Instance.new("ImageLabel")
CardIcon.Name = "Icon"
CardIcon.Size = UDim2.new(0, 48, 0, 48)
CardIcon.Position = UDim2.new(0.5, 0, 0, 6)
CardIcon.AnchorPoint = Vector2.new(0.5, 0)
CardIcon.BackgroundTransparency = 1
CardIcon.Image = ""
CardIcon.ScaleType = Enum.ScaleType.Fit
CardIcon.Parent = Card

local CardFallback = label(CardIcon, "FallbackLetter", "?", 32, "TextMuted", Style.DisplayFont)
CardFallback.Size = UDim2.new(1, 0, 1, 0)

local CardName = label(Card, "NameLabel", "Item", 18, "TextPrimary", Style.DisplayFont)
CardName.Size = UDim2.new(1, -8, 0, 40)
CardName.Position = UDim2.new(0, 4, 0, 56)
CardName.TextWrapped = true
CardName.TextTruncate = Enum.TextTruncate.AtEnd
CardName.TextYAlignment = Enum.TextYAlignment.Top

local CardQty = label(Card, "QtyLabel", "x1", 16, "TextMuted", Style.DisplayFont)
CardQty.Size = UDim2.new(0, 40, 0, 20)
CardQty.Position = UDim2.new(1, -6, 0, 6)
CardQty.AnchorPoint = Vector2.new(1, 0)
CardQty.TextXAlignment = Enum.TextXAlignment.Right

local CardFav = label(Card, "FavouriteMark", "★", 18, "RarityLegendary", Style.DisplayFont)
CardFav.Size = UDim2.new(0, 22, 0, 22)
CardFav.Position = UDim2.new(0, 6, 0, 6)
CardFav.Visible = false

-- Rarity badge (identical to the Shop card's). The controller sets the per-item
-- tier colour (Theme_BackgroundColor3 = "Rarity<Tier>") and the tier text (FR-025).
local badge = Instance.new("Frame")
badge.Name = "RarityBadge"
badge.Size = UDim2.new(0, 92, 0, 22)
bind(badge, "BackgroundColor3", "RarityCommon")
badge.BorderSizePixel = 0
badge.Position = UDim2.new(0.5, 0, 1, -6)
badge.AnchorPoint = Vector2.new(0.5, 1)
badge.Parent = Card
local badgeCorner = Instance.new("UICorner"); badgeCorner.CornerRadius = UDim.new(0, 8); badgeCorner.Parent = badge
strokeOf(badge, "OutlineDeep", 2)
local badgeText = Instance.new("TextLabel")
badgeText.Name = "BadgeText"; badgeText.Size = UDim2.new(1,0,1,0); badgeText.BackgroundTransparency = 1
badgeText.Text = "COMMON"; bind(badgeText, "TextColor3", "TextOnAccent"); badgeText.TextSize = 13; badgeText.Font = Style.DisplayFont
badgeText.Parent = badge

-- Full-card transparent button: the whole card is the tap target (selection).
local CardButton = Instance.new("TextButton")
CardButton.Name = "SlotButton"
CardButton.Size = UDim2.new(1, 0, 1, 0)
CardButton.BackgroundTransparency = 1
CardButton.Text = ""
CardButton.ZIndex = 3
CardButton.Parent = Card

--[[ SPIRITS PLACEHOLDER (shown only on the Spirits tab; the spirit system is deferred) ]]
local SpiritsEmptyState = Instance.new("Frame")
SpiritsEmptyState.Name = "SpiritsEmptyState"
SpiritsEmptyState.Size = ItemGrid.Size
SpiritsEmptyState.Position = ItemGrid.Position
bind(SpiritsEmptyState, "BackgroundColor3", "SurfaceRaised")
SpiritsEmptyState.BackgroundTransparency = 0.5
SpiritsEmptyState.BorderSizePixel = 0
SpiritsEmptyState.Visible = false
SpiritsEmptyState.Parent = InventoryFrame
corner(SpiritsEmptyState, 8)
local spiritsText = label(SpiritsEmptyState, "ComingSoonLabel", "👻 Coming soon\nSpirits will appear here.", 20, "TextMuted", Style.DisplayFont)
spiritsText.Size = UDim2.new(1, -20, 1, 0)
spiritsText.Position = UDim2.new(0, 10, 0, 0)
spiritsText.TextWrapped = true

--[[ DETAIL PANEL: selected item + one context action (right column) ]]
local DetailPanel = Instance.new("Frame")
DetailPanel.Name = "DetailPanel"
DetailPanel.Size = UDim2.new(0.38, -30, 1, -116)
DetailPanel.Position = UDim2.new(0.62, 10, 0, 108)
bind(DetailPanel, "BackgroundColor3", "SurfaceRaised")
DetailPanel.BorderSizePixel = 0
DetailPanel.Parent = InventoryFrame
corner(DetailPanel)
strokeOf(DetailPanel, "Outline")

local SelectedIcon = Instance.new("ImageLabel")
SelectedIcon.Name = "SelectedIcon"
SelectedIcon.Size = UDim2.new(0, 80, 0, 80)
SelectedIcon.Position = UDim2.new(0.5, 0, 0, 12)
SelectedIcon.AnchorPoint = Vector2.new(0.5, 0)
SelectedIcon.BackgroundTransparency = 1
SelectedIcon.Image = ""
SelectedIcon.ScaleType = Enum.ScaleType.Fit
SelectedIcon.Parent = DetailPanel
local SelFallback = label(SelectedIcon, "FallbackLetter", "?", 48, "TextMuted", Style.DisplayFont)
SelFallback.Size = UDim2.new(1, 0, 1, 0)

local SelectedName = label(DetailPanel, "SelectedName", "Select an item", 20, "TextPrimary", Style.DisplayFont)
SelectedName.Size = UDim2.new(1, -16, 0, 48)
SelectedName.Position = UDim2.new(0, 8, 0, 98)
SelectedName.TextWrapped = true
SelectedName.TextTruncate = Enum.TextTruncate.AtEnd

local SelectedDescription = label(DetailPanel, "SelectedDescription", "Tap an item to see details.", 18, "TextMuted", Style.BodyFont)
SelectedDescription.Size = UDim2.new(1, -16, 1, -226)
SelectedDescription.Position = UDim2.new(0, 8, 0, 148)
SelectedDescription.TextWrapped = true
SelectedDescription.TextXAlignment = Enum.TextXAlignment.Left
SelectedDescription.TextYAlignment = Enum.TextYAlignment.Top

local FavouriteToggle = Instance.new("TextButton")
FavouriteToggle.Name = "FavouriteToggle"
FavouriteToggle.Size = UDim2.new(0, 44, 0, 44)
FavouriteToggle.Position = UDim2.new(1, -6, 0, 6)
FavouriteToggle.AnchorPoint = Vector2.new(1, 0)
bind(FavouriteToggle, "BackgroundColor3", "Control")
FavouriteToggle.BorderSizePixel = 0
FavouriteToggle.Text = "☆"
bind(FavouriteToggle, "TextColor3", "RarityLegendary")
FavouriteToggle.TextSize = 24
FavouriteToggle.Font = Style.DisplayFont
FavouriteToggle.AutoButtonColor = false
FavouriteToggle.Parent = DetailPanel
corner(FavouriteToggle)
strokeOf(FavouriteToggle, "Outline")

local ActionButton = Instance.new("TextButton")
ActionButton.Name = "ActionButton"
ActionButton.Size = UDim2.new(1, -16, 0, 48)
ActionButton.Position = UDim2.new(0.5, 0, 1, -8)
ActionButton.AnchorPoint = Vector2.new(0.5, 1)
bind(ActionButton, "BackgroundColor3", "Positive")
ActionButton.BorderSizePixel = 0
ActionButton.Text = "Equip"
bind(ActionButton, "TextColor3", "TextOnAccent")
ActionButton.TextSize = 20
ActionButton.Font = Style.DisplayFont
ActionButton.AutoButtonColor = false
ActionButton.Parent = DetailPanel
corner(ActionButton)
strokeOf(ActionButton, "OutlineDeep")

--[[ TOOLTIP FRAME: hover details (kept; the DetailPanel is the primary surface) ]]
local TooltipFrame = Instance.new("Frame")
TooltipFrame.Name = "TooltipFrame"
TooltipFrame.Size = UDim2.new(0, 250, 0, 120)
TooltipFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
TooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
bind(TooltipFrame, "BackgroundColor3", "SurfaceRaised")
TooltipFrame.BorderSizePixel = 0
TooltipFrame.Visible = false
TooltipFrame.ZIndex = 10
TooltipFrame.Parent = InventoryUI
corner(TooltipFrame, 8)
strokeOf(TooltipFrame, "Outline")

local TooltipPadding = Instance.new("UIPadding")
TooltipPadding.PaddingTop = UDim.new(0, 10)
TooltipPadding.PaddingBottom = UDim.new(0, 10)
TooltipPadding.PaddingLeft = UDim.new(0, 12)
TooltipPadding.PaddingRight = UDim.new(0, 12)
TooltipPadding.Parent = TooltipFrame

local TooltipTitle = label(TooltipFrame, "TooltipTitle", "Item Name", 20, "TextPrimary", Style.DisplayFont)
TooltipTitle.Size = UDim2.new(1, 0, 0, 25)
TooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
TooltipTitle.TextYAlignment = Enum.TextYAlignment.Top

local TooltipDescription = label(TooltipFrame, "TooltipDescription", "Item description goes here", 18, "TextMuted", Style.BodyFont)
TooltipDescription.Size = UDim2.new(1, 0, 0, 40)
TooltipDescription.Position = UDim2.new(0, 0, 0, 30)
TooltipDescription.TextXAlignment = Enum.TextXAlignment.Left
TooltipDescription.TextYAlignment = Enum.TextYAlignment.Top
TooltipDescription.TextWrapped = true

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, 0, 0, 1)
Separator.Position = UDim2.new(0, 0, 0, 75)
bind(Separator, "BackgroundColor3", "Outline")
Separator.BorderSizePixel = 0
Separator.Parent = TooltipFrame

local TooltipStats = label(TooltipFrame, "TooltipStats", "Quantity: 10\n💰 Sell Value: 15 coins\n🌱 Type: Seed", 18, "TextPrimary", Style.BodyFont)
TooltipStats.Size = UDim2.new(1, 0, 1, -80)
TooltipStats.Position = UDim2.new(0, 0, 0, 80)
TooltipStats.TextXAlignment = Enum.TextXAlignment.Left
TooltipStats.TextYAlignment = Enum.TextYAlignment.Top

print("✅ InventoryUI created successfully!")
print("   Components: HeaderBar, 5 tabs, ItemGrid + CardTemplate, DetailPanel, SpiritsEmptyState, TooltipFrame")
print("🎮 InventoryUI is ready for InventoryController! Press 'I' to toggle inventory")
