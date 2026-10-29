--[[
    CreateInventoryUI.lua
    Location: StarterGui (as LocalScript)

    PURPOSE:
    Programmatically creates the Inventory UI including:
    - Header bar with title and close button
    - Tab system (Seeds / Items)
    - Scrolling item grid
    - Tooltip for item details

    Static GUI only (constitution III); interactions (tab switching, hover, close)
    live in InventoryController, not here. Colours come from UITheme tokens (V) and
    are tagged with Theme_<Prop> attributes so ThemeController retints them on the
    day/night switch (feature 004). The approved look adds outlines, a gradient
    header, rounded corners and the display font.
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

-- Bake the Night (default) colour AND tag the token (Theme_<Prop> = "<Token>") so
-- ThemeController can retint this property on a day/night switch.
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

-- Create main ScreenGui
local InventoryUI = Instance.new("ScreenGui")
InventoryUI.Name = "InventoryUI"
InventoryUI.ResetOnSpawn = false
InventoryUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
InventoryUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
InventoryUI.IgnoreGuiInset = false
InventoryUI.Enabled = false -- Hidden by default, opened with 'I' key
InventoryUI.Parent = playerGui

-- Full-screen dim backdrop (US3): tapping it closes the window and the Active
-- TextButton keeps the tap from reaching the game world (FR-008). Parented
-- before InventoryFrame so it renders behind it.
local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.Position = UDim2.new(0, 0, 0, 0)
bind(Backdrop, "BackgroundColor3", "Backdrop")
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = InventoryUI

--[[
    MAIN INVENTORY FRAME
    Centered modal window
]]
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

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
frameCorner.Parent = InventoryFrame

strokeOf(InventoryFrame, "OutlineDeep", Style.WindowOutlineThickness)

-- Drop shadow effect (neutral soft shadow, not themed)
local frameShadow = Instance.new("ImageLabel")
frameShadow.Name = "Shadow"
frameShadow.Size = UDim2.new(1, 30, 1, 30)
frameShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
frameShadow.AnchorPoint = Vector2.new(0.5, 0.5)
frameShadow.BackgroundTransparency = 1
frameShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
frameShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
frameShadow.ImageTransparency = 0.7
frameShadow.ScaleType = Enum.ScaleType.Slice
frameShadow.SliceCenter = Rect.new(8, 8, 8, 8)
frameShadow.ZIndex = -1
frameShadow.Parent = InventoryFrame

--[[
    HEADER BAR
    Title and close button
]]
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = InventoryFrame
gradientOf(HeaderBar, "HeaderTop", "HeaderBottom")

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
headerCorner.Parent = HeaderBar

-- Cover bottom corners (matches the gradient's bottom stop)
local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 12)
headerCover.Position = UDim2.new(0, 0, 1, -12)
bind(headerCover, "BackgroundColor3", "HeaderBottom")
headerCover.BorderSizePixel = 0
headerCover.Parent = HeaderBar

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📦 INVENTORY"
bind(TitleLabel, "TextColor3", "TextOnHeader")
TitleLabel.TextSize = 24
TitleLabel.Font = Style.DisplayFont
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

-- Close button
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

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
closeCorner.Parent = CloseButton

--[[
    TAB CONTAINER
    Seeds and Items tabs. The active/inactive colours are applied by
    InventoryController; the static defaults below are Seeds = active (Accent),
    Items = inactive (Control).
]]
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -40, 0, 45)
TabContainer.Position = UDim2.new(0, 20, 0, 60)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = InventoryFrame

-- Seeds tab (active default)
local SeedsTab = Instance.new("TextButton")
SeedsTab.Name = "SeedsTab"
SeedsTab.Size = UDim2.new(0, 140, 1, 0)
SeedsTab.Position = UDim2.new(0, 0, 0, 0)
bind(SeedsTab, "BackgroundColor3", "Accent")
SeedsTab.BorderSizePixel = 0
SeedsTab.Text = "🌱 Seeds"
bind(SeedsTab, "TextColor3", "TextOnAccent")
SeedsTab.TextSize = 20 -- button label >= 20 (FR-005)
SeedsTab.Font = Style.DisplayFont
SeedsTab.AutoButtonColor = false
SeedsTab.Parent = TabContainer

local seedsCorner = Instance.new("UICorner")
seedsCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
seedsCorner.Parent = SeedsTab

-- Items tab (inactive default)
local ItemsTab = Instance.new("TextButton")
ItemsTab.Name = "ItemsTab"
ItemsTab.Size = UDim2.new(0, 140, 1, 0)
ItemsTab.Position = UDim2.new(0, 150, 0, 0)
bind(ItemsTab, "BackgroundColor3", "Control")
ItemsTab.BorderSizePixel = 0
ItemsTab.Text = "📦 Items"
bind(ItemsTab, "TextColor3", "TextPrimary")
ItemsTab.TextSize = 20 -- button label >= 20 (FR-005)
ItemsTab.Font = Style.DisplayFont
ItemsTab.AutoButtonColor = false
ItemsTab.Parent = TabContainer

local itemsCorner = Instance.new("UICorner")
itemsCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
itemsCorner.Parent = ItemsTab

--[[
    ITEM GRID
    Scrolling frame with grid layout
]]
local ItemGrid = Instance.new("ScrollingFrame")
ItemGrid.Name = "ItemGrid"
ItemGrid.Size = UDim2.new(1, -40, 1, -125)
ItemGrid.Position = UDim2.new(0, 20, 0, 115)
bind(ItemGrid, "BackgroundColor3", "SurfaceRaised")
ItemGrid.BackgroundTransparency = 0.5
ItemGrid.BorderSizePixel = 0
ItemGrid.ScrollBarThickness = 8
bind(ItemGrid, "ScrollBarImageColor3", "Control")
ItemGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ItemGrid.Parent = InventoryFrame

local gridCorner = Instance.new("UICorner")
gridCorner.CornerRadius = UDim.new(0, 8)
gridCorner.Parent = ItemGrid

-- Grid layout
local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0, 100, 0, 100)
GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
GridLayout.SortOrder = Enum.SortOrder.Name
GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GridLayout.Parent = ItemGrid

-- Padding for grid
local GridPadding = Instance.new("UIPadding")
GridPadding.PaddingTop = UDim.new(0, 10)
GridPadding.PaddingBottom = UDim.new(0, 10)
GridPadding.PaddingLeft = UDim.new(0, 10)
GridPadding.PaddingRight = UDim.new(0, 10)
GridPadding.Parent = ItemGrid

--[[
    TOOLTIP FRAME
    Shows item details on hover
]]
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

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
tooltipCorner.Parent = TooltipFrame

strokeOf(TooltipFrame, "Outline")

-- Tooltip shadow (neutral soft shadow, not themed)
local tooltipShadow = Instance.new("ImageLabel")
tooltipShadow.Name = "Shadow"
tooltipShadow.Size = UDim2.new(1, 20, 1, 20)
tooltipShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
tooltipShadow.AnchorPoint = Vector2.new(0.5, 0.5)
tooltipShadow.BackgroundTransparency = 1
tooltipShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
tooltipShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
tooltipShadow.ImageTransparency = 0.6
tooltipShadow.ScaleType = Enum.ScaleType.Slice
tooltipShadow.SliceCenter = Rect.new(8, 8, 8, 8)
tooltipShadow.ZIndex = 9
tooltipShadow.Parent = TooltipFrame

-- Tooltip padding
local TooltipPadding = Instance.new("UIPadding")
TooltipPadding.PaddingTop = UDim.new(0, 10)
TooltipPadding.PaddingBottom = UDim.new(0, 10)
TooltipPadding.PaddingLeft = UDim.new(0, 12)
TooltipPadding.PaddingRight = UDim.new(0, 12)
TooltipPadding.Parent = TooltipFrame

-- Tooltip title
local TooltipTitle = Instance.new("TextLabel")
TooltipTitle.Name = "TooltipTitle"
TooltipTitle.Size = UDim2.new(1, 0, 0, 25)
TooltipTitle.BackgroundTransparency = 1
TooltipTitle.Text = "Item Name"
bind(TooltipTitle, "TextColor3", "TextPrimary")
TooltipTitle.TextSize = 20 -- title >= 20 (FR-005)
TooltipTitle.Font = Style.DisplayFont
TooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
TooltipTitle.TextYAlignment = Enum.TextYAlignment.Top
TooltipTitle.Parent = TooltipFrame

-- Tooltip description
local TooltipDescription = Instance.new("TextLabel")
TooltipDescription.Name = "TooltipDescription"
TooltipDescription.Size = UDim2.new(1, 0, 0, 40)
TooltipDescription.Position = UDim2.new(0, 0, 0, 30)
TooltipDescription.BackgroundTransparency = 1
TooltipDescription.Text = "Item description goes here"
bind(TooltipDescription, "TextColor3", "TextMuted")
TooltipDescription.TextSize = 18 -- body >= 18 (FR-005)
TooltipDescription.Font = Style.BodyFont
TooltipDescription.TextXAlignment = Enum.TextXAlignment.Left
TooltipDescription.TextYAlignment = Enum.TextYAlignment.Top
TooltipDescription.TextWrapped = true
TooltipDescription.Parent = TooltipFrame

-- Separator line
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, 0, 0, 1)
Separator.Position = UDim2.new(0, 0, 0, 75)
bind(Separator, "BackgroundColor3", "Outline")
Separator.BorderSizePixel = 0
Separator.Parent = TooltipFrame

-- Tooltip stats
local TooltipStats = Instance.new("TextLabel")
TooltipStats.Name = "TooltipStats"
TooltipStats.Size = UDim2.new(1, 0, 1, -80)
TooltipStats.Position = UDim2.new(0, 0, 0, 80)
TooltipStats.BackgroundTransparency = 1
TooltipStats.Text = "Quantity: 10\n💰 Sell Value: 15 coins\n🌱 Type: Seed"
bind(TooltipStats, "TextColor3", "TextMuted")
TooltipStats.TextSize = 18 -- body >= 18 (FR-005)
TooltipStats.Font = Style.BodyFont
TooltipStats.TextXAlignment = Enum.TextXAlignment.Left
TooltipStats.TextYAlignment = Enum.TextYAlignment.Top
TooltipStats.Parent = TooltipFrame

print("✅ InventoryUI created successfully!")
