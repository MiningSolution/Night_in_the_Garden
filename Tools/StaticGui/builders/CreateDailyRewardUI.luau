--[[
    CreateDailyRewardUI.lua
    Location: StarterGui (generated into StarterGui/DailyRewardUI.model.json) — feature 003, US1.
    Re-skinned feature 006 (US4): cosy-garden concept, theme-tagged for both palettes.

    Builds the DailyRewardUI ScreenGui: a single-window modal showing the 7-day streak
    track. DailyRewardController fills each day's coins/seeds and state from RetentionConfig
    at runtime (constitution II) and wires ClaimButton -> ClaimDailyReward. Element
    names/structure are unchanged so the controller keeps working; every themed colour is
    tagged with Theme_<Prop> so ThemeController retints it on day/night (V). >= 44 / >= 18 (IV).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("DailyRewardUI") then
    print("⚠️ DailyRewardUI already exists, skipping creation")
    return
end

print("🎨 Creating DailyRewardUI...")

local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))
local Style = Theme.Style

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
local function roundCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or Style.CornerRadius)
    c.Parent = parent
    return c
end

local DailyRewardUI = Instance.new("ScreenGui")
DailyRewardUI.Name = "DailyRewardUI"
DailyRewardUI.ResetOnSpawn = false
DailyRewardUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DailyRewardUI.DisplayOrder = 5
DailyRewardUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
DailyRewardUI.IgnoreGuiInset = false
DailyRewardUI.Enabled = false
DailyRewardUI.Parent = playerGui

local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
bind(Backdrop, "BackgroundColor3", "Backdrop")
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = DailyRewardUI

local RewardFrame = Instance.new("Frame")
RewardFrame.Name = "RewardFrame"
RewardFrame.Size = UDim2.new(0.95, 0, 0.7, 0)
RewardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
RewardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bind(RewardFrame, "BackgroundColor3", "Surface")
RewardFrame.BorderSizePixel = 0

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(680, 380)
sizeConstraint.MinSize = Vector2.new(320, 240)
sizeConstraint.Parent = RewardFrame
RewardFrame.SelectionGroup = true
RewardFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
RewardFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
RewardFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
RewardFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
RewardFrame.Parent = DailyRewardUI
roundCorner(RewardFrame)
strokeOf(RewardFrame, "OutlineDeep", Style.WindowOutlineThickness)

local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = RewardFrame
gradientOf(HeaderBar, "HeaderTop", "HeaderBottom")
roundCorner(HeaderBar)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎁 DAILY REWARD"
bind(TitleLabel, "TextColor3", "TextOnHeader")
TitleLabel.TextSize = 24
TitleLabel.Font = Style.DisplayFont
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local StreakLabel = Instance.new("TextLabel")
StreakLabel.Name = "StreakLabel"
StreakLabel.Size = UDim2.new(0.5, -74, 1, 0)
StreakLabel.Position = UDim2.new(0.5, 0, 0, 0)
StreakLabel.BackgroundTransparency = 1
StreakLabel.Text = "Day 0 / 7"
bind(StreakLabel, "TextColor3", "TextOnHeader")
StreakLabel.TextSize = 20
StreakLabel.Font = Style.DisplayFont
StreakLabel.TextXAlignment = Enum.TextXAlignment.Right
StreakLabel.Parent = HeaderBar

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
roundCorner(CloseButton, 8)

local TrackRow = Instance.new("Frame")
TrackRow.Name = "TrackRow"
TrackRow.Size = UDim2.new(1, -40, 1, -124)
TrackRow.Position = UDim2.new(0, 20, 0, 62)
TrackRow.BackgroundTransparency = 1
TrackRow.Parent = RewardFrame

local trackLayout = Instance.new("UIGridLayout")
trackLayout.FillDirection = Enum.FillDirection.Horizontal
trackLayout.SortOrder = Enum.SortOrder.LayoutOrder
trackLayout.CellPadding = UDim2.new(0, 6, 0, 6)
trackLayout.CellSize = UDim2.new(1 / 7, -6, 1, 0)
trackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
trackLayout.VerticalAlignment = Enum.VerticalAlignment.Center
trackLayout.Parent = TrackRow

-- One day cell (DayNumber = track position, not a balance; CoinsLabel/SeedsLabel filled by controller).
local function makeDayCell(i)
    local cell = Instance.new("Frame")
    cell.Name = "Day" .. i
    bind(cell, "BackgroundColor3", "SurfaceRaised")
    cell.BorderSizePixel = 0
    cell.LayoutOrder = i
    cell.Parent = TrackRow
    roundCorner(cell, 10)
    strokeOf(cell, "Outline")

    -- "today" highlight stroke (controller shows/hides by setting Enabled).
    local stroke = Instance.new("UIStroke")
    stroke.Name = "TodayStroke"
    stroke.Color = Theme.Accent
    stroke:SetAttribute("Theme_Color", "Accent")
    stroke.Thickness = 3
    stroke.Enabled = false
    stroke.Parent = cell

    local dayLabel = Instance.new("TextLabel")
    dayLabel.Name = "DayNumberLabel"
    dayLabel.Size = UDim2.new(1, 0, 0, 22)
    dayLabel.Position = UDim2.new(0, 0, 0, 6)
    dayLabel.BackgroundTransparency = 1
    dayLabel.Text = "Day " .. i
    bind(dayLabel, "TextColor3", "TextMuted")
    dayLabel.TextSize = 18
    dayLabel.Font = Style.DisplayFont
    dayLabel.Parent = cell

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -4, 0, 24)
    coinsLabel.Position = UDim2.new(0, 2, 0.5, -6)
    coinsLabel.AnchorPoint = Vector2.new(0, 0.5)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = ""
    bind(coinsLabel, "TextColor3", "Coins")
    coinsLabel.TextSize = 18
    coinsLabel.Font = Style.DisplayFont
    coinsLabel.TextScaled = false
    coinsLabel.Parent = cell

    local seedsLabel = Instance.new("TextLabel")
    seedsLabel.Name = "SeedsLabel"
    seedsLabel.Size = UDim2.new(1, -4, 0, 20)
    seedsLabel.Position = UDim2.new(0, 2, 1, -24)
    seedsLabel.BackgroundTransparency = 1
    seedsLabel.Text = ""
    bind(seedsLabel, "TextColor3", "Dream")
    seedsLabel.TextSize = 16
    seedsLabel.Font = Style.DisplayFont
    seedsLabel.Visible = false
    seedsLabel.Parent = cell

    -- claimed check overlay (controller shows for claimed days)
    local check = Instance.new("TextLabel")
    check.Name = "ClaimedCheck"
    check.Size = UDim2.new(0, 22, 0, 22)
    check.Position = UDim2.new(1, -4, 0, 4)
    check.AnchorPoint = Vector2.new(1, 0)
    check.BackgroundTransparency = 1
    check.Text = "✓"
    bind(check, "TextColor3", "Positive")
    check.TextSize = 20
    check.Font = Style.DisplayFont
    check.Visible = false
    check.Parent = cell
end

for i = 1, 7 do
    makeDayCell(i)
end

local ClaimButton = Instance.new("TextButton")
ClaimButton.Name = "ClaimButton"
ClaimButton.Size = UDim2.new(1, -40, 0, 48)
ClaimButton.Position = UDim2.new(0, 20, 1, -56)
ClaimButton.AnchorPoint = Vector2.new(0, 0)
bind(ClaimButton, "BackgroundColor3", "Positive")
ClaimButton.BorderSizePixel = 0
ClaimButton.Text = "CLAIM"
bind(ClaimButton, "TextColor3", "TextOnAccent")
ClaimButton.TextSize = 22
ClaimButton.Font = Style.DisplayFont
ClaimButton.AutoButtonColor = false
ClaimButton.Parent = RewardFrame
roundCorner(ClaimButton, 8)
strokeOf(ClaimButton, "OutlineDeep")

print("✅ DailyRewardUI created successfully!")
