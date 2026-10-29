--[[
    CreateDailyRewardUI.lua
    Location: StarterGui (generated into StarterGui/DailyRewardUI.model.json) — feature 003, US1

    Builds the DailyRewardUI ScreenGui: a single-window modal showing the 7-day
    streak track. DailyRewardController fills each day's coins/seeds and state from
    RetentionConfig at runtime (constitution II: no reward number is baked into the
    GUI text here) and wires ClaimButton -> ClaimDailyReward. Colours from UITheme
    (V); tap targets >= 44; body text >= 18, titles/buttons >= 20 (IV).
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
Backdrop.BackgroundColor3 = Theme.Backdrop
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
RewardFrame.BackgroundColor3 = Theme.Surface
RewardFrame.BorderSizePixel = 0

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(680, 380)
sizeConstraint.MinSize = Vector2.new(320, 240)
sizeConstraint.Parent = RewardFrame
-- Gamepad: keep selection navigation inside the open window.
RewardFrame.SelectionGroup = true
RewardFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
RewardFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
RewardFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
RewardFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
RewardFrame.Parent = DailyRewardUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = RewardFrame

-- Header
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Theme.Header
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = RewardFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎁 DAILY REWARD"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextSize = 24
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local StreakLabel = Instance.new("TextLabel")
StreakLabel.Name = "StreakLabel"
StreakLabel.Size = UDim2.new(0.5, -74, 1, 0)
StreakLabel.Position = UDim2.new(0.5, 0, 0, 0)
StreakLabel.BackgroundTransparency = 1
StreakLabel.Text = "Day 0 / 7"
StreakLabel.TextColor3 = Theme.TextMuted
StreakLabel.TextSize = 20
StreakLabel.Font = Enum.Font.GothamMedium
StreakLabel.TextXAlignment = Enum.TextXAlignment.Right
StreakLabel.Parent = HeaderBar

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

-- Track of 7 day cells, laid out in a row (controller fills amounts + state).
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

-- One day cell. DayNumber is the position on the track (not a balance number);
-- CoinsLabel / SeedsLabel are placeholders filled by the controller from config.
local function makeDayCell(i)
    local cell = Instance.new("Frame")
    cell.Name = "Day" .. i
    cell.BackgroundColor3 = Theme.SurfaceRaised
    cell.BorderSizePixel = 0
    cell.LayoutOrder = i
    cell.Parent = TrackRow

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = cell

    -- "today" highlight stroke (controller shows/hides by setting Enabled).
    local stroke = Instance.new("UIStroke")
    stroke.Name = "TodayStroke"
    stroke.Color = Theme.Accent
    stroke.Thickness = 2
    stroke.Enabled = false
    stroke.Parent = cell

    local dayLabel = Instance.new("TextLabel")
    dayLabel.Name = "DayNumberLabel"
    dayLabel.Size = UDim2.new(1, 0, 0, 22)
    dayLabel.Position = UDim2.new(0, 0, 0, 6)
    dayLabel.BackgroundTransparency = 1
    dayLabel.Text = "Day " .. i
    dayLabel.TextColor3 = Theme.TextMuted
    dayLabel.TextSize = 18
    dayLabel.Font = Enum.Font.GothamMedium
    dayLabel.Parent = cell

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -4, 0, 24)
    coinsLabel.Position = UDim2.new(0, 2, 0.5, -6)
    coinsLabel.AnchorPoint = Vector2.new(0, 0.5)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = ""
    coinsLabel.TextColor3 = Theme.Coins
    coinsLabel.TextSize = 18
    coinsLabel.Font = Enum.Font.GothamBold
    coinsLabel.TextScaled = false
    coinsLabel.Parent = cell

    local seedsLabel = Instance.new("TextLabel")
    seedsLabel.Name = "SeedsLabel"
    seedsLabel.Size = UDim2.new(1, -4, 0, 20)
    seedsLabel.Position = UDim2.new(0, 2, 1, -24)
    seedsLabel.BackgroundTransparency = 1
    seedsLabel.Text = ""
    seedsLabel.TextColor3 = Theme.RarityRare
    seedsLabel.TextSize = 16
    seedsLabel.Font = Enum.Font.GothamMedium
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
    check.TextColor3 = Theme.Accent
    check.TextSize = 20
    check.Font = Enum.Font.GothamBold
    check.Visible = false
    check.Parent = cell
end

for i = 1, 7 do
    makeDayCell(i)
end

-- Footer: claim
local ClaimButton = Instance.new("TextButton")
ClaimButton.Name = "ClaimButton"
ClaimButton.Size = UDim2.new(1, -40, 0, 48)
ClaimButton.Position = UDim2.new(0, 20, 1, -56)
ClaimButton.AnchorPoint = Vector2.new(0, 0)
ClaimButton.BackgroundColor3 = Theme.Accent
ClaimButton.BorderSizePixel = 0
ClaimButton.Text = "CLAIM"
ClaimButton.TextColor3 = Theme.TextPrimary
ClaimButton.TextSize = 22
ClaimButton.Font = Enum.Font.GothamBold
ClaimButton.AutoButtonColor = false
ClaimButton.Parent = RewardFrame

local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 8)
claimCorner.Parent = ClaimButton

print("✅ DailyRewardUI created successfully!")
