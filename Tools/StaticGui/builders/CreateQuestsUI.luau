--[[
    CreateQuestsUI.lua
    Location: StarterGui (generated into StarterGui/QuestsUI.model.json) — feature 003, US2

    Builds the QuestsUI ScreenGui: a single-window modal listing the day's quests.
    QuestController clones QuestRowTemplate per quest and fills objective/progress/
    reward from the server (constitution III: a static template cloned at runtime).
    Colours from UITheme (V); tap targets >= 44; body text >= 18, titles/buttons >= 20 (IV).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("QuestsUI") then
    print("⚠️ QuestsUI already exists, skipping creation")
    return
end

print("🎨 Creating QuestsUI...")

local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))

local QuestsUI = Instance.new("ScreenGui")
QuestsUI.Name = "QuestsUI"
QuestsUI.ResetOnSpawn = false
QuestsUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
QuestsUI.DisplayOrder = 5
QuestsUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
QuestsUI.IgnoreGuiInset = false
QuestsUI.Enabled = false
QuestsUI.Parent = playerGui

local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Theme.Backdrop
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = QuestsUI

local QuestsFrame = Instance.new("Frame")
QuestsFrame.Name = "QuestsFrame"
QuestsFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
QuestsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
QuestsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
QuestsFrame.BackgroundColor3 = Theme.Surface
QuestsFrame.BorderSizePixel = 0

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(560, 460)
sizeConstraint.MinSize = Vector2.new(320, 260)
sizeConstraint.Parent = QuestsFrame
QuestsFrame.SelectionGroup = true
QuestsFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
QuestsFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
QuestsFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
QuestsFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
QuestsFrame.Parent = QuestsUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = QuestsFrame

local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Theme.Header
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = QuestsFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -74, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📋 DAILY QUESTS"
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

local QuestScroll = Instance.new("ScrollingFrame")
QuestScroll.Name = "QuestScroll"
QuestScroll.Size = UDim2.new(1, -40, 1, -70)
QuestScroll.Position = UDim2.new(0, 20, 0, 60)
QuestScroll.BackgroundTransparency = 1
QuestScroll.BorderSizePixel = 0
QuestScroll.ScrollBarThickness = 8
QuestScroll.ScrollBarImageColor3 = Theme.Control
QuestScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
QuestScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
QuestScroll.Parent = QuestsFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = QuestScroll

-- Row template (hidden; QuestController clones it per quest).
local Row = Instance.new("Frame")
Row.Name = "QuestRowTemplate"
Row.Size = UDim2.new(1, -8, 0, 86)
Row.BackgroundColor3 = Theme.SurfaceRaised
Row.BorderSizePixel = 0
Row.Visible = false
Row.Parent = QuestScroll

local rowCorner = Instance.new("UICorner")
rowCorner.CornerRadius = UDim.new(0, 8)
rowCorner.Parent = Row

local rowPadding = Instance.new("UIPadding")
rowPadding.PaddingTop = UDim.new(0, 8)
rowPadding.PaddingBottom = UDim.new(0, 8)
rowPadding.PaddingLeft = UDim.new(0, 12)
rowPadding.PaddingRight = UDim.new(0, 12)
rowPadding.Parent = Row

local ObjectiveLabel = Instance.new("TextLabel")
ObjectiveLabel.Name = "ObjectiveLabel"
ObjectiveLabel.Size = UDim2.new(1, -110, 0, 24)
ObjectiveLabel.Position = UDim2.new(0, 0, 0, 0)
ObjectiveLabel.BackgroundTransparency = 1
ObjectiveLabel.Text = "Objective"
ObjectiveLabel.TextColor3 = Theme.TextPrimary
ObjectiveLabel.TextSize = 18
ObjectiveLabel.Font = Enum.Font.GothamMedium
ObjectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
ObjectiveLabel.Parent = Row

local RewardLabel = Instance.new("TextLabel")
RewardLabel.Name = "RewardLabel"
RewardLabel.Size = UDim2.new(1, -110, 0, 20)
RewardLabel.Position = UDim2.new(0, 0, 0, 26)
RewardLabel.BackgroundTransparency = 1
RewardLabel.Text = ""
RewardLabel.TextColor3 = Theme.Coins
RewardLabel.TextSize = 16
RewardLabel.Font = Enum.Font.Gotham
RewardLabel.TextXAlignment = Enum.TextXAlignment.Left
RewardLabel.Parent = Row

-- progress bar (background + fill) with a count label
local ProgressBarBG = Instance.new("Frame")
ProgressBarBG.Name = "ProgressBarBG"
ProgressBarBG.Size = UDim2.new(1, -110, 0, 14)
ProgressBarBG.Position = UDim2.new(0, 0, 1, -14)
ProgressBarBG.AnchorPoint = Vector2.new(0, 1)
ProgressBarBG.BackgroundColor3 = Theme.Surface
ProgressBarBG.BorderSizePixel = 0
ProgressBarBG.Parent = Row

local pbgCorner = Instance.new("UICorner")
pbgCorner.CornerRadius = UDim.new(0, 6)
pbgCorner.Parent = ProgressBarBG

local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Theme.Accent
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBarBG

local pbCorner = Instance.new("UICorner")
pbCorner.CornerRadius = UDim.new(0, 6)
pbCorner.Parent = ProgressBar

local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Name = "ProgressLabel"
ProgressLabel.Size = UDim2.new(1, 0, 1, 0)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "0 / 0"
ProgressLabel.TextColor3 = Theme.TextPrimary
ProgressLabel.TextSize = 14
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.Parent = ProgressBarBG

local ClaimButton = Instance.new("TextButton")
ClaimButton.Name = "ClaimButton"
ClaimButton.Size = UDim2.new(0, 96, 0, 44)
ClaimButton.Position = UDim2.new(1, -96, 0.5, 0)
ClaimButton.AnchorPoint = Vector2.new(0, 0.5)
ClaimButton.BackgroundColor3 = Theme.Control
ClaimButton.BorderSizePixel = 0
ClaimButton.Text = "CLAIM"
ClaimButton.TextColor3 = Theme.TextPrimary
ClaimButton.TextSize = 20
ClaimButton.Font = Enum.Font.GothamBold
ClaimButton.AutoButtonColor = false
ClaimButton.Active = false
ClaimButton.Parent = Row

local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 8)
claimCorner.Parent = ClaimButton

-- Empty state (shown when there are no quests, defensive)
local EmptyState = Instance.new("TextLabel")
EmptyState.Name = "EmptyState"
EmptyState.Size = UDim2.new(1, -40, 0, 40)
EmptyState.Position = UDim2.new(0, 20, 0, 70)
EmptyState.BackgroundTransparency = 1
EmptyState.Text = "No quests today — check back tomorrow."
EmptyState.TextColor3 = Theme.TextMuted
EmptyState.TextSize = 18
EmptyState.Font = Enum.Font.Gotham
EmptyState.TextWrapped = true
EmptyState.Visible = false
EmptyState.Parent = QuestsFrame

print("✅ QuestsUI created successfully!")
