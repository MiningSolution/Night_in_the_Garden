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

    Feature 004: every themed colour is baked (Night default) AND tagged with a
    Theme_<Prop> attribute so ThemeController retints it on the day/night switch.
    The approved "juicy" look adds outlines, a gradient header, a 3D gradient Buy
    button and the display font.
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
-- Two-stop vertical gradient; the parent's BackgroundColor3 is set white so the
-- gradient shows its true colours, and the stops are tagged for the live switch.
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
bind(Backdrop, "BackgroundColor3", "Backdrop")
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
bind(ShopFrame, "BackgroundColor3", "Surface")
ShopFrame.BorderSizePixel = 0
ShopFrame.SelectionGroup = true
ShopFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
ShopFrame.Parent = ShopUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
frameCorner.Parent = ShopFrame

strokeOf(ShopFrame, "OutlineDeep", Style.WindowOutlineThickness)

-- Header (gradient bar with a light title)
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = ShopFrame
gradientOf(HeaderBar, "HeaderTop", "HeaderBottom")

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
headerCorner.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -270, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🏪 SHOP"
bind(TitleLabel, "TextColor3", "TextOnHeader")
TitleLabel.TextSize = 24
TitleLabel.Font = Style.DisplayFont
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 44, 0, 44)
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

-- Restock countdown (feature 003, US3). ShopController ticks the text from RestockAt.
local RestockLabel = Instance.new("TextLabel")
RestockLabel.Name = "RestockLabel"
RestockLabel.Size = UDim2.new(0, 190, 1, 0)
RestockLabel.Position = UDim2.new(1, -64, 0, 0)
RestockLabel.AnchorPoint = Vector2.new(1, 0)
RestockLabel.BackgroundTransparency = 1
RestockLabel.Text = "Restock in --:--"
bind(RestockLabel, "TextColor3", "TextOnHeader")
RestockLabel.TextSize = 18
RestockLabel.Font = Style.BodyFont
RestockLabel.TextXAlignment = Enum.TextXAlignment.Right
RestockLabel.Parent = HeaderBar

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
    bind(tab, "BackgroundColor3", "Control")
    tab.BorderSizePixel = 0
    tab.Text = text
    bind(tab, "TextColor3", "TextPrimary")
    tab.TextSize = 20
    tab.Font = Style.DisplayFont
    tab.AutoButtonColor = false
    tab.Parent = TabContainer
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, Style.CornerRadius)
    c.Parent = tab
    strokeOf(tab, "Outline")
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
bind(CardsScroll, "BackgroundColor3", "SurfaceRaised")
CardsScroll.BackgroundTransparency = 0.5
CardsScroll.BorderSizePixel = 0
CardsScroll.ScrollBarThickness = 8
bind(CardsScroll, "ScrollBarImageColor3", "Control")
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
bind(Card, "BackgroundColor3", "SurfaceRaised")
Card.BorderSizePixel = 0
Card.Visible = false
Card.Parent = CardsScroll

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
cardCorner.Parent = Card

strokeOf(Card, "Outline")

-- Rarity strip: ShopController sets its colour per item (via ThemeController), so it
-- carries NO static Theme_ tag — the per-item rarity must win over a palette repaint.
local RarityStrip = Instance.new("Frame")
RarityStrip.Name = "RarityStrip"
RarityStrip.Size = UDim2.new(1, 0, 0, 6)
RarityStrip.BackgroundColor3 = Theme.RarityCommon
RarityStrip.BorderSizePixel = 0
RarityStrip.Parent = Card

-- Stock badge (feature 003, US3): top-right "xN" / "Out". ShopController fills it;
-- hidden for unlimited items.
local StockLabel = Instance.new("TextLabel")
StockLabel.Name = "StockLabel"
StockLabel.Size = UDim2.new(0, 60, 0, 20)
StockLabel.Position = UDim2.new(1, -6, 0, 12)
StockLabel.AnchorPoint = Vector2.new(1, 0)
StockLabel.BackgroundTransparency = 1
StockLabel.Text = ""
bind(StockLabel, "TextColor3", "TextMuted")
StockLabel.TextSize = 16
StockLabel.Font = Style.BodyFont
StockLabel.TextXAlignment = Enum.TextXAlignment.Right
StockLabel.Visible = false
StockLabel.Parent = Card

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
bind(FallbackLetter, "TextColor3", "TextMuted")
FallbackLetter.TextSize = 32
FallbackLetter.Font = Style.DisplayFont
FallbackLetter.Parent = Icon

local NameLabel = Instance.new("TextLabel")
NameLabel.Name = "NameLabel"
NameLabel.Size = UDim2.new(1, -12, 0, 32)
NameLabel.Position = UDim2.new(0, 6, 0, 62)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = "Item"
bind(NameLabel, "TextColor3", "TextPrimary")
NameLabel.TextSize = 18
NameLabel.Font = Style.DisplayFont
NameLabel.TextWrapped = true
NameLabel.Parent = Card

local PriceLabel = Instance.new("TextLabel")
PriceLabel.Name = "PriceLabel"
PriceLabel.Size = UDim2.new(1, -12, 0, 22)
PriceLabel.Position = UDim2.new(0, 6, 0, 94)
PriceLabel.BackgroundTransparency = 1
PriceLabel.Text = "💰 0"
bind(PriceLabel, "TextColor3", "Coins")
PriceLabel.TextSize = 18
PriceLabel.Font = Style.DisplayFont
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
    bind(b, "BackgroundColor3", "Control")
    b.BorderSizePixel = 0
    b.Text = text
    bind(b, "TextColor3", "TextPrimary")
    b.TextSize = 20 -- buttons >= 20 (FR-017)
    b.Font = Style.DisplayFont
    b.AutoButtonColor = false
    b.Parent = QtyRow
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    return b
end
makeQty("QtyX1", "x1", 0)
makeQty("QtyX5", "x5", 1)
makeQty("QtyX10", "x10", 2)

-- Buy button: the hero action — a 3D gradient (Accent → AccentDeep) with a darker
-- outline, light label.
local BuyButton = Instance.new("TextButton")
BuyButton.Name = "BuyButton"
BuyButton.Size = UDim2.new(1, -12, 0, 44)
BuyButton.Position = UDim2.new(0, 6, 0, 168)
BuyButton.BorderSizePixel = 0
BuyButton.Text = "BUY"
bind(BuyButton, "TextColor3", "TextOnAccent")
BuyButton.TextSize = 20
BuyButton.Font = Style.DisplayFont
BuyButton.AutoButtonColor = false
BuyButton.Parent = Card
gradientOf(BuyButton, "Accent", "AccentDeep")

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
buyCorner.Parent = BuyButton

strokeOf(BuyButton, "AccentDeep")

-- Loading overlay (shown during a purchase request)
local LoadingOverlay = Instance.new("Frame")
LoadingOverlay.Name = "LoadingOverlay"
LoadingOverlay.Size = UDim2.new(1, 0, 1, -50)
LoadingOverlay.Position = UDim2.new(0, 0, 0, 50)
LoadingOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- neutral dim overlay (not themed)
LoadingOverlay.BackgroundTransparency = 0.7
LoadingOverlay.BorderSizePixel = 0
LoadingOverlay.Visible = false
LoadingOverlay.ZIndex = 100
LoadingOverlay.Parent = ShopFrame

local loadingCorner = Instance.new("UICorner")
loadingCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
loadingCorner.Parent = LoadingOverlay

local LoadingText = Instance.new("TextLabel")
LoadingText.Name = "LoadingText"
LoadingText.Size = UDim2.new(1, 0, 0, 30)
LoadingText.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingText.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Processing..."
bind(LoadingText, "TextColor3", "TextOnHeader") -- light on the dark overlay (both palettes)
LoadingText.TextSize = 20
LoadingText.Font = Style.DisplayFont
LoadingText.ZIndex = 101
LoadingText.Parent = LoadingOverlay

print("✅ ShopUI (card grid) created successfully!")
