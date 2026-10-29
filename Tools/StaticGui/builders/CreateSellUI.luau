--[[
    CreateSellUI.lua
    Location: StarterGui (as LocalScript) — feature 002, User Story 1

    Builds the SellUI ScreenGui: a single-window modal opened at the seller's
    stall. Shows the player's sellable crops, each crop's sell value, a running
    coin total, a per-row favourite (star) toggle and "Sell" button, and a
    "Sell all" footer. SellController attaches behaviour and clones SellRowTemplate
    per sellable crop (constitution III: a static template cloned at runtime, never
    a screen built in Lua). Colours from UITheme (V); tap targets >= 44; body text
    >= 18, titles/buttons >= 20 (IV).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SellUI") then
    print("⚠️ SellUI already exists, skipping creation")
    return
end

print("🎨 Creating SellUI...")

-- Theme tokens: offline the generator sets the global UI_THEME; in Studio the
-- module is required directly.
local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))

local SellUI = Instance.new("ScreenGui")
SellUI.Name = "SellUI"
SellUI.ResetOnSpawn = false
SellUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SellUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
SellUI.IgnoreGuiInset = false
SellUI.Enabled = false
SellUI.Parent = playerGui

-- Full-screen dim backdrop; tapping it closes the window (WindowManager wires it).
local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Theme.Backdrop
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = SellUI

local SellFrame = Instance.new("Frame")
SellFrame.Name = "SellFrame"
-- Scale to the viewport but cap the size, so it fits a landscape phone (~375 tall)
-- without needing ResponsiveLayout (IV: content stays inside the safe area).
SellFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
SellFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
SellFrame.AnchorPoint = Vector2.new(0.5, 0.5)
SellFrame.BackgroundColor3 = Theme.Surface
SellFrame.BorderSizePixel = 0

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(560, 480)
sizeConstraint.MinSize = Vector2.new(320, 260)
sizeConstraint.Parent = SellFrame
-- Gamepad: keep selection navigation inside the open window (R8).
SellFrame.SelectionGroup = true
SellFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
SellFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
SellFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
SellFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
SellFrame.Parent = SellUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = SellFrame

-- Header
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Theme.Header
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = SellFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "💰 SELL"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextSize = 24
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 44, 0, 44)
CloseButton.Position = UDim2.new(1, -54, 0.5, 0)
CloseButton.AnchorPoint = Vector2.new(0, 0.5)
CloseButton.BackgroundColor3 = Theme.Danger
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Theme.TextPrimary
CloseButton.TextSize = 24
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = false
CloseButton.Parent = HeaderBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = CloseButton

-- Running total line
local TotalLabel = Instance.new("TextLabel")
TotalLabel.Name = "TotalLabel"
TotalLabel.Size = UDim2.new(1, -40, 0, 30)
TotalLabel.Position = UDim2.new(0, 20, 0, 58)
TotalLabel.BackgroundTransparency = 1
TotalLabel.Text = "Sell all total: 0 coins"
TotalLabel.TextColor3 = Theme.TextMuted
TotalLabel.TextSize = 20
TotalLabel.Font = Enum.Font.GothamMedium
TotalLabel.TextXAlignment = Enum.TextXAlignment.Left
TotalLabel.Parent = SellFrame

-- Scrolling list of sellable crops
local ItemsScroll = Instance.new("ScrollingFrame")
ItemsScroll.Name = "ItemsScroll"
ItemsScroll.Size = UDim2.new(1, -40, 1, -160)
ItemsScroll.Position = UDim2.new(0, 20, 0, 94)
ItemsScroll.BackgroundColor3 = Theme.SurfaceRaised
ItemsScroll.BackgroundTransparency = 0.4
ItemsScroll.BorderSizePixel = 0
ItemsScroll.ScrollBarThickness = 8
ItemsScroll.ScrollBarImageColor3 = Theme.Control
ItemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ItemsScroll.Parent = SellFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = ItemsScroll

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = ItemsScroll

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)
listPadding.Parent = ItemsScroll

-- Empty state (shown when nothing is sellable)
local EmptyState = Instance.new("TextLabel")
EmptyState.Name = "EmptyState"
EmptyState.Size = UDim2.new(1, -40, 0, 40)
EmptyState.Position = UDim2.new(0, 20, 0, 150)
EmptyState.BackgroundTransparency = 1
EmptyState.Text = "Nothing to sell — harvest some crops first."
EmptyState.TextColor3 = Theme.TextMuted
EmptyState.TextSize = 18
EmptyState.Font = Enum.Font.Gotham
EmptyState.TextWrapped = true
EmptyState.Visible = false
EmptyState.Parent = SellFrame

--[[ Row template (hidden; SellController clones it per sellable crop) ]]
local Row = Instance.new("Frame")
Row.Name = "SellRowTemplate"
Row.Size = UDim2.new(1, -12, 0, 56)
Row.BackgroundColor3 = Theme.SurfaceRaised
Row.BorderSizePixel = 0
Row.Visible = false
Row.Parent = ItemsScroll

local rowCorner = Instance.new("UICorner")
rowCorner.CornerRadius = UDim.new(0, 6)
rowCorner.Parent = Row

-- rarity colour strip on the left edge
local RarityStrip = Instance.new("Frame")
RarityStrip.Name = "RarityStrip"
RarityStrip.Size = UDim2.new(0, 6, 1, -12)
RarityStrip.Position = UDim2.new(0, 6, 0, 6)
RarityStrip.BackgroundColor3 = Theme.RarityCommon
RarityStrip.BorderSizePixel = 0
RarityStrip.Parent = Row

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 40, 0, 40)
Icon.Position = UDim2.new(0, 20, 0.5, 0)
Icon.AnchorPoint = Vector2.new(0, 0.5)
Icon.BackgroundTransparency = 1
Icon.Image = ""
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = Row

-- fallback glyph when no icon image is set (US8 keeps this consistent)
local FallbackLetter = Instance.new("TextLabel")
FallbackLetter.Name = "FallbackLetter"
FallbackLetter.Size = UDim2.new(1, 0, 1, 0)
FallbackLetter.BackgroundTransparency = 1
FallbackLetter.Text = "?"
FallbackLetter.TextColor3 = Theme.TextMuted
FallbackLetter.TextSize = 24
FallbackLetter.Font = Enum.Font.GothamBold
FallbackLetter.Parent = Icon

local NameLabel = Instance.new("TextLabel")
NameLabel.Name = "NameLabel"
NameLabel.Size = UDim2.new(0, 170, 1, 0)
NameLabel.Position = UDim2.new(0, 70, 0, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = "Crop"
NameLabel.TextColor3 = Theme.TextPrimary
NameLabel.TextSize = 18
NameLabel.Font = Enum.Font.GothamMedium
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.Parent = Row

local CountLabel = Instance.new("TextLabel")
CountLabel.Name = "CountLabel"
CountLabel.Size = UDim2.new(0, 46, 1, 0)
CountLabel.Position = UDim2.new(0, 246, 0, 0)
CountLabel.BackgroundTransparency = 1
CountLabel.Text = "x0"
CountLabel.TextColor3 = Theme.TextMuted
CountLabel.TextSize = 18
CountLabel.Font = Enum.Font.Gotham
CountLabel.Parent = Row

local ValueLabel = Instance.new("TextLabel")
ValueLabel.Name = "ValueLabel"
ValueLabel.Size = UDim2.new(0, 58, 1, 0)
ValueLabel.Position = UDim2.new(0, 294, 0, 0)
ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
ValueLabel.BackgroundTransparency = 1
ValueLabel.Text = "0 ea"
ValueLabel.TextColor3 = Theme.TextMuted
ValueLabel.TextSize = 18
ValueLabel.Font = Enum.Font.Gotham
ValueLabel.Parent = Row

local StarToggle = Instance.new("TextButton")
StarToggle.Name = "StarToggle"
StarToggle.Size = UDim2.new(0, 44, 0, 44)
StarToggle.Position = UDim2.new(1, -150, 0.5, 0)
StarToggle.AnchorPoint = Vector2.new(0, 0.5)
StarToggle.BackgroundColor3 = Theme.Control
StarToggle.BorderSizePixel = 0
StarToggle.Text = "☆"
StarToggle.TextColor3 = Theme.TextPrimary
StarToggle.TextSize = 24
StarToggle.Font = Enum.Font.GothamBold
StarToggle.AutoButtonColor = false
StarToggle.Parent = Row

local starCorner = Instance.new("UICorner")
starCorner.CornerRadius = UDim.new(0, 8)
starCorner.Parent = StarToggle

local SellOneButton = Instance.new("TextButton")
SellOneButton.Name = "SellOneButton"
SellOneButton.Size = UDim2.new(0, 90, 0, 44)
SellOneButton.Position = UDim2.new(1, -98, 0.5, 0)
SellOneButton.AnchorPoint = Vector2.new(0, 0.5)
SellOneButton.BackgroundColor3 = Theme.Accent
SellOneButton.BorderSizePixel = 0
SellOneButton.Text = "Sell"
SellOneButton.TextColor3 = Theme.TextPrimary
SellOneButton.TextSize = 20
SellOneButton.Font = Enum.Font.GothamBold
SellOneButton.AutoButtonColor = false
SellOneButton.Parent = Row

local sellOneCorner = Instance.new("UICorner")
sellOneCorner.CornerRadius = UDim.new(0, 8)
sellOneCorner.Parent = SellOneButton

-- Footer: Sell all
local SellAllButton = Instance.new("TextButton")
SellAllButton.Name = "SellAllButton"
SellAllButton.Size = UDim2.new(1, -40, 0, 48)
SellAllButton.Position = UDim2.new(0, 20, 1, -56)
SellAllButton.AnchorPoint = Vector2.new(0, 0)
SellAllButton.BackgroundColor3 = Theme.Accent
SellAllButton.BorderSizePixel = 0
SellAllButton.Text = "SELL ALL"
SellAllButton.TextColor3 = Theme.TextPrimary
SellAllButton.TextSize = 22
SellAllButton.Font = Enum.Font.GothamBold
SellAllButton.AutoButtonColor = false
SellAllButton.Parent = SellFrame

local sellAllCorner = Instance.new("UICorner")
sellAllCorner.CornerRadius = UDim.new(0, 8)
sellAllCorner.Parent = SellAllButton

print("✅ SellUI created successfully!")
