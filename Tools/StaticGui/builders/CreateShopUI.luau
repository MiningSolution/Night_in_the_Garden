--[[
    CreateShopUI.lua
    Location: StarterGui (as LocalScript) — reworked for feature 002, User Story 3.

    The shop is a scrolling grid of cards. Each card (cloned by ShopController from
    the hidden CardTemplate) shows an icon, name, price, a rarity colour strip and
    x1/x5/x10 quantity buttons; unaffordable cards are dimmed. Seeds / Tools / Items
    are chosen with the tab row. The ShopFrame is sized responsively by
    UIController.applyLayout (ResponsiveLayout.WINDOWS.Shop), so inner elements use
    relative sizing. Static GUI only (constitution III); colours from UITheme (V);
    tap targets >= 44, text >= 18/20 (IV).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ShopUI") then
    print("⚠️ ShopUI already exists, skipping creation")
    return
end

print("🎨 Creating ShopUI (card grid)...")

local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))

local ShopUI = Instance.new("ScreenGui")
ShopUI.Name = "ShopUI"
ShopUI.ResetOnSpawn = false
ShopUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ShopUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
ShopUI.IgnoreGuiInset = false
ShopUI.Enabled = false
ShopUI.Parent = playerGui

local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Theme.Backdrop
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = ShopUI

local ShopFrame = Instance.new("Frame")
ShopFrame.Name = "ShopFrame"
ShopFrame.Size = UDim2.new(0, 800, 0, 520) -- replaced at runtime by ResponsiveLayout
ShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
ShopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ShopFrame.BackgroundColor3 = Theme.Surface
ShopFrame.BorderSizePixel = 0
ShopFrame.SelectionGroup = true
ShopFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
ShopFrame.Parent = ShopUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = ShopFrame

-- Header
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Theme.Header
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = ShopFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🏪 SHOP"
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

-- Category tabs (Seeds / Tools / Items)
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -30, 0, 44)
TabContainer.Position = UDim2.new(0, 15, 0, 58)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = ShopFrame

local function makeTab(name, text, order)
    local tab = Instance.new("TextButton")
    tab.Name = name
    tab.Size = UDim2.new(0.32, 0, 1, 0)
    tab.Position = UDim2.new(order * 0.34, 0, 0, 0)
    tab.BackgroundColor3 = Theme.Control
    tab.BorderSizePixel = 0
    tab.Text = text
    tab.TextColor3 = Theme.TextPrimary
    tab.TextSize = 20
    tab.Font = Enum.Font.GothamBold
    tab.AutoButtonColor = false
    tab.Parent = TabContainer
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = tab
    return tab
end
makeTab("seedsTab", "🌱 Seeds", 0)
makeTab("toolsTab", "🔧 Tools", 1)
makeTab("itemsTab", "📦 Items", 2)

-- Scrolling card grid
local CardsScroll = Instance.new("ScrollingFrame")
CardsScroll.Name = "CardsScroll"
CardsScroll.Size = UDim2.new(1, -30, 1, -116)
CardsScroll.Position = UDim2.new(0, 15, 0, 108)
CardsScroll.BackgroundColor3 = Theme.SurfaceRaised
CardsScroll.BackgroundTransparency = 0.5
CardsScroll.BorderSizePixel = 0
CardsScroll.ScrollBarThickness = 8
CardsScroll.ScrollBarImageColor3 = Theme.Control
CardsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CardsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
CardsScroll.Parent = ShopFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = CardsScroll

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 160, 0, 216)
grid.CellPadding = UDim2.new(0, 12, 0, 12)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
grid.Parent = CardsScroll

local gridPad = Instance.new("UIPadding")
gridPad.PaddingTop = UDim.new(0, 12)
gridPad.PaddingBottom = UDim.new(0, 12)
gridPad.PaddingLeft = UDim.new(0, 12)
gridPad.PaddingRight = UDim.new(0, 12)
gridPad.Parent = CardsScroll

--[[ Card template (hidden; ShopController clones it per item) ]]
local Card = Instance.new("Frame")
Card.Name = "CardTemplate"
Card.Size = UDim2.new(0, 160, 0, 216)
Card.BackgroundColor3 = Theme.SurfaceRaised
Card.BorderSizePixel = 0
Card.Visible = false
Card.Parent = CardsScroll

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 8)
cardCorner.Parent = Card

local RarityStrip = Instance.new("Frame")
RarityStrip.Name = "RarityStrip"
RarityStrip.Size = UDim2.new(1, 0, 0, 6)
RarityStrip.BackgroundColor3 = Theme.RarityCommon
RarityStrip.BorderSizePixel = 0
RarityStrip.Parent = Card

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 48, 0, 48)
Icon.Position = UDim2.new(0.5, 0, 0, 12)
Icon.AnchorPoint = Vector2.new(0.5, 0)
Icon.BackgroundTransparency = 1
Icon.Image = ""
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = Card

local FallbackLetter = Instance.new("TextLabel")
FallbackLetter.Name = "FallbackLetter"
FallbackLetter.Size = UDim2.new(1, 0, 1, 0)
FallbackLetter.BackgroundTransparency = 1
FallbackLetter.Text = "?"
FallbackLetter.TextColor3 = Theme.TextMuted
FallbackLetter.TextSize = 32
FallbackLetter.Font = Enum.Font.GothamBold
FallbackLetter.Parent = Icon

local NameLabel = Instance.new("TextLabel")
NameLabel.Name = "NameLabel"
NameLabel.Size = UDim2.new(1, -12, 0, 32)
NameLabel.Position = UDim2.new(0, 6, 0, 62)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = "Item"
NameLabel.TextColor3 = Theme.TextPrimary
NameLabel.TextSize = 18
NameLabel.Font = Enum.Font.GothamBold
NameLabel.TextWrapped = true
NameLabel.Parent = Card

local PriceLabel = Instance.new("TextLabel")
PriceLabel.Name = "PriceLabel"
PriceLabel.Size = UDim2.new(1, -12, 0, 22)
PriceLabel.Position = UDim2.new(0, 6, 0, 94)
PriceLabel.BackgroundTransparency = 1
PriceLabel.Text = "💰 0"
PriceLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
PriceLabel.TextSize = 18
PriceLabel.Font = Enum.Font.GothamBold
PriceLabel.Parent = Card

-- Quantity row: x1 / x5 / x10 (each >= 44 tall for a touch target)
local QtyRow = Instance.new("Frame")
QtyRow.Name = "QtyRow"
QtyRow.Size = UDim2.new(1, -12, 0, 44)
QtyRow.Position = UDim2.new(0, 6, 0, 120)
QtyRow.BackgroundTransparency = 1
QtyRow.Parent = Card

local function makeQty(name, text, order)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0.32, 0, 1, 0)
    b.Position = UDim2.new(order * 0.34, 0, 0, 0)
    b.BackgroundColor3 = Theme.Control
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Theme.TextPrimary
    b.TextSize = 18
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = QtyRow
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    return b
end
makeQty("QtyX1", "x1", 0)
makeQty("QtyX5", "x5", 1)
makeQty("QtyX10", "x10", 2)

local BuyButton = Instance.new("TextButton")
BuyButton.Name = "BuyButton"
BuyButton.Size = UDim2.new(1, -12, 0, 44)
BuyButton.Position = UDim2.new(0, 6, 0, 168)
BuyButton.BackgroundColor3 = Theme.Accent
BuyButton.BorderSizePixel = 0
BuyButton.Text = "BUY"
BuyButton.TextColor3 = Theme.TextPrimary
BuyButton.TextSize = 20
BuyButton.Font = Enum.Font.GothamBold
BuyButton.AutoButtonColor = false
BuyButton.Parent = Card

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 8)
buyCorner.Parent = BuyButton

-- Loading overlay (shown during a purchase request)
local LoadingOverlay = Instance.new("Frame")
LoadingOverlay.Name = "LoadingOverlay"
LoadingOverlay.Size = UDim2.new(1, 0, 1, -50)
LoadingOverlay.Position = UDim2.new(0, 0, 0, 50)
LoadingOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LoadingOverlay.BackgroundTransparency = 0.7
LoadingOverlay.BorderSizePixel = 0
LoadingOverlay.Visible = false
LoadingOverlay.ZIndex = 100
LoadingOverlay.Parent = ShopFrame

local loadingCorner = Instance.new("UICorner")
loadingCorner.CornerRadius = UDim.new(0, 12)
loadingCorner.Parent = LoadingOverlay

local LoadingText = Instance.new("TextLabel")
LoadingText.Name = "LoadingText"
LoadingText.Size = UDim2.new(1, 0, 0, 30)
LoadingText.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingText.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Processing..."
LoadingText.TextColor3 = Theme.TextPrimary
LoadingText.TextSize = 20
LoadingText.Font = Enum.Font.GothamBold
LoadingText.ZIndex = 101
LoadingText.Parent = LoadingOverlay

print("✅ ShopUI (card grid) created successfully!")
