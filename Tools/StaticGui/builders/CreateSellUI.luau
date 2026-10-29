--[[
    CreateSellUI.lua
    Location: StarterGui (as LocalScript) — feature 002, re-skinned feature 006 (US4)

    Builds the SellUI ScreenGui: a single-window modal opened at the seller's stall.
    Shows the player's sellable crops, each crop's sell value, a running coin total, a
    per-row favourite (star) toggle and "Sell" button, and a "Sell all" footer.
    SellController attaches behaviour and clones SellRowTemplate per sellable crop
    (constitution III). Feature 006 (US4): re-skinned to the cosy-garden concept — every
    themed colour is tagged with a Theme_<Prop> attribute so ThemeController retints it on
    the day/night switch (V, both palettes). Element names/structure are unchanged so
    SellController keeps working; tap targets >= 44, body >= 18, titles/buttons >= 20 (IV).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SellUI") then
    print("⚠️ SellUI already exists, skipping creation")
    return
end

print("🎨 Creating SellUI...")

local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))
local Style = Theme.Style

-- Bake the Night (default) colour AND tag the token so ThemeController retints it.
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

local SellUI = Instance.new("ScreenGui")
SellUI.Name = "SellUI"
SellUI.ResetOnSpawn = false
SellUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SellUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
SellUI.IgnoreGuiInset = false
SellUI.Enabled = false
SellUI.Parent = playerGui

local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
bind(Backdrop, "BackgroundColor3", "Backdrop")
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = SellUI

local SellFrame = Instance.new("Frame")
SellFrame.Name = "SellFrame"
SellFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
SellFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
SellFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bind(SellFrame, "BackgroundColor3", "Surface")
SellFrame.BorderSizePixel = 0

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(560, 480)
sizeConstraint.MinSize = Vector2.new(320, 260)
sizeConstraint.Parent = SellFrame
SellFrame.SelectionGroup = true
SellFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
SellFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
SellFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
SellFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
SellFrame.Parent = SellUI
corner(SellFrame)
strokeOf(SellFrame, "OutlineDeep", Style.WindowOutlineThickness)

-- Header (cosy-garden gradient)
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = SellFrame
gradientOf(HeaderBar, "HeaderTop", "HeaderBottom")
corner(HeaderBar)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "💰 SELL"
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
corner(CloseButton, 8)

local TotalLabel = Instance.new("TextLabel")
TotalLabel.Name = "TotalLabel"
TotalLabel.Size = UDim2.new(1, -40, 0, 30)
TotalLabel.Position = UDim2.new(0, 20, 0, 58)
TotalLabel.BackgroundTransparency = 1
TotalLabel.Text = "Sell all total: 0 coins"
bind(TotalLabel, "TextColor3", "Coins")
TotalLabel.TextSize = 20
TotalLabel.Font = Style.DisplayFont
TotalLabel.TextXAlignment = Enum.TextXAlignment.Left
TotalLabel.Parent = SellFrame

local ItemsScroll = Instance.new("ScrollingFrame")
ItemsScroll.Name = "ItemsScroll"
ItemsScroll.Size = UDim2.new(1, -40, 1, -160)
ItemsScroll.Position = UDim2.new(0, 20, 0, 94)
bind(ItemsScroll, "BackgroundColor3", "SurfaceRaised")
ItemsScroll.BackgroundTransparency = 0.4
ItemsScroll.BorderSizePixel = 0
ItemsScroll.ScrollBarThickness = 8
bind(ItemsScroll, "ScrollBarImageColor3", "Control")
ItemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ItemsScroll.Parent = SellFrame
corner(ItemsScroll, 8)

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

local EmptyState = Instance.new("TextLabel")
EmptyState.Name = "EmptyState"
EmptyState.Size = UDim2.new(1, -40, 0, 40)
EmptyState.Position = UDim2.new(0, 20, 0, 150)
EmptyState.BackgroundTransparency = 1
EmptyState.Text = "Nothing to sell — harvest some crops first."
bind(EmptyState, "TextColor3", "TextMuted")
EmptyState.TextSize = 18
EmptyState.Font = Style.BodyFont
EmptyState.TextWrapped = true
EmptyState.Visible = false
EmptyState.Parent = SellFrame

--[[ Row template (hidden; SellController clones it per sellable crop) ]]
local Row = Instance.new("Frame")
Row.Name = "SellRowTemplate"
Row.Size = UDim2.new(1, -12, 0, 56)
bind(Row, "BackgroundColor3", "SurfaceRaised")
Row.BorderSizePixel = 0
Row.Visible = false
Row.Parent = ItemsScroll
corner(Row, 10)
strokeOf(Row, "Outline")

-- rarity colour strip on the left edge (SellController sets the per-rarity colour)
local RarityStrip = Instance.new("Frame")
RarityStrip.Name = "RarityStrip"
RarityStrip.Size = UDim2.new(0, 6, 1, -12)
RarityStrip.Position = UDim2.new(0, 6, 0, 6)
RarityStrip.BackgroundColor3 = Theme.RarityCommon
RarityStrip.BorderSizePixel = 0
RarityStrip.Parent = Row
corner(RarityStrip, 3)

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 40, 0, 40)
Icon.Position = UDim2.new(0, 20, 0.5, 0)
Icon.AnchorPoint = Vector2.new(0, 0.5)
Icon.BackgroundTransparency = 1
Icon.Image = ""
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = Row

local FallbackLetter = Instance.new("TextLabel")
FallbackLetter.Name = "FallbackLetter"
FallbackLetter.Size = UDim2.new(1, 0, 1, 0)
FallbackLetter.BackgroundTransparency = 1
FallbackLetter.Text = "?"
bind(FallbackLetter, "TextColor3", "TextMuted")
FallbackLetter.TextSize = 24
FallbackLetter.Font = Style.DisplayFont
FallbackLetter.Parent = Icon

local NameLabel = Instance.new("TextLabel")
NameLabel.Name = "NameLabel"
NameLabel.Size = UDim2.new(0, 170, 1, 0)
NameLabel.Position = UDim2.new(0, 70, 0, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = "Crop"
bind(NameLabel, "TextColor3", "TextPrimary")
NameLabel.TextSize = 18
NameLabel.Font = Style.DisplayFont
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.Parent = Row

local CountLabel = Instance.new("TextLabel")
CountLabel.Name = "CountLabel"
CountLabel.Size = UDim2.new(0, 46, 1, 0)
CountLabel.Position = UDim2.new(0, 246, 0, 0)
CountLabel.BackgroundTransparency = 1
CountLabel.Text = "x0"
bind(CountLabel, "TextColor3", "TextMuted")
CountLabel.TextSize = 18
CountLabel.Font = Style.BodyFont
CountLabel.Parent = Row

local ValueLabel = Instance.new("TextLabel")
ValueLabel.Name = "ValueLabel"
ValueLabel.Size = UDim2.new(0, 58, 1, 0)
ValueLabel.Position = UDim2.new(0, 294, 0, 0)
ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
ValueLabel.BackgroundTransparency = 1
ValueLabel.Text = "0 ea"
bind(ValueLabel, "TextColor3", "Coins")
ValueLabel.TextSize = 18
ValueLabel.Font = Style.BodyFont
ValueLabel.Parent = Row

local StarToggle = Instance.new("TextButton")
StarToggle.Name = "StarToggle"
StarToggle.Size = UDim2.new(0, 44, 0, 44)
StarToggle.Position = UDim2.new(1, -150, 0.5, 0)
StarToggle.AnchorPoint = Vector2.new(0, 0.5)
bind(StarToggle, "BackgroundColor3", "Control")
StarToggle.BorderSizePixel = 0
StarToggle.Text = "☆"
bind(StarToggle, "TextColor3", "RarityLegendary")
StarToggle.TextSize = 24
StarToggle.Font = Style.DisplayFont
StarToggle.AutoButtonColor = false
StarToggle.Parent = Row
corner(StarToggle, 8)
strokeOf(StarToggle, "Outline")

local SellOneButton = Instance.new("TextButton")
SellOneButton.Name = "SellOneButton"
SellOneButton.Size = UDim2.new(0, 90, 0, 44)
SellOneButton.Position = UDim2.new(1, -98, 0.5, 0)
SellOneButton.AnchorPoint = Vector2.new(0, 0.5)
bind(SellOneButton, "BackgroundColor3", "Sell")
SellOneButton.BorderSizePixel = 0
SellOneButton.Text = "Sell"
bind(SellOneButton, "TextColor3", "TextOnAccent")
SellOneButton.TextSize = 20
SellOneButton.Font = Style.DisplayFont
SellOneButton.AutoButtonColor = false
SellOneButton.Parent = Row
corner(SellOneButton, 8)
strokeOf(SellOneButton, "OutlineDeep")

local SellAllButton = Instance.new("TextButton")
SellAllButton.Name = "SellAllButton"
SellAllButton.Size = UDim2.new(1, -40, 0, 48)
SellAllButton.Position = UDim2.new(0, 20, 1, -56)
SellAllButton.AnchorPoint = Vector2.new(0, 0)
bind(SellAllButton, "BackgroundColor3", "Sell")
SellAllButton.BorderSizePixel = 0
SellAllButton.Text = "SELL ALL"
bind(SellAllButton, "TextColor3", "TextOnAccent")
SellAllButton.TextSize = 22
SellAllButton.Font = Style.DisplayFont
SellAllButton.AutoButtonColor = false
SellAllButton.Parent = SellFrame
corner(SellAllButton, 8)
strokeOf(SellAllButton, "OutlineDeep")

print("✅ SellUI created successfully!")
