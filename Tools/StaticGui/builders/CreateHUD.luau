--[[
    CreateHUD.lua
    Location: StarterGui (as LocalScript)

    PURPOSE:
    Programmatically creates the HUD GUI including:
    - Currency display (Coins and Dream Seeds)
    - Day/Night cycle indicator with progress bar

    The hotbar and the menu buttons live in HUDControls (feature 001), a
    separate ScreenGui that stays above the window backdrops; this HUD holds
    only the always-background currency and day/night indicator.

    INSTALLATION:
    1. Place this script in StarterGui as a LocalScript
    2. Run the game once - HUD will be created automatically
    3. You can disable this script after creation if desired

    NOTE: This script runs once per player when they join
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Check if HUD already exists
if playerGui:FindFirstChild("HUD") then
    print("⚠️ HUD already exists, skipping creation")
    return
end

print("🎨 Creating HUD...")

-- Theme tokens (offline: the generator sets UI_THEME; in Studio: required directly).
local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))
local Style = Theme.Style
-- Bake the Night (default) colour AND tag the token so ThemeController can retint
-- this property on a day/night switch (Theme_<Prop> = "<Token>").
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

-- Create main ScreenGui
local HUD = Instance.new("ScreenGui")
HUD.Name = "HUD"
HUD.ResetOnSpawn = false
HUD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HUD.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
HUD.IgnoreGuiInset = false
HUD.Parent = playerGui

--[[
    CURRENCY DISPLAY
    Top-left corner showing coins and dream seeds
]]
local CurrencyDisplay = Instance.new("Frame")
CurrencyDisplay.Name = "CurrencyDisplay"
CurrencyDisplay.Size = UDim2.new(0, 250, 0, 80)
CurrencyDisplay.Position = UDim2.new(0, 20, 0, 20)
bind(CurrencyDisplay, "BackgroundColor3", "Surface")
CurrencyDisplay.BorderSizePixel = 0
CurrencyDisplay.Parent = HUD

local currencyCorner = Instance.new("UICorner")
currencyCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
currencyCorner.Parent = CurrencyDisplay

strokeOf(CurrencyDisplay, "Outline")

-- Coins label
local CoinsLabel = Instance.new("TextLabel")
CoinsLabel.Name = "CoinsLabel"
CoinsLabel.Size = UDim2.new(1, -20, 0, 30)
CoinsLabel.Position = UDim2.new(0, 10, 0, 10)
CoinsLabel.BackgroundTransparency = 1
CoinsLabel.Text = "💰 Coins: 50"
bind(CoinsLabel, "TextColor3", "Coins")
CoinsLabel.TextSize = 20
CoinsLabel.Font = Style.DisplayFont
CoinsLabel.TextXAlignment = Enum.TextXAlignment.Left
CoinsLabel.Parent = CurrencyDisplay

-- Dream Seeds label
local DreamSeedsLabel = Instance.new("TextLabel")
DreamSeedsLabel.Name = "DreamSeedsLabel"
DreamSeedsLabel.Size = UDim2.new(1, -20, 0, 30)
DreamSeedsLabel.Position = UDim2.new(0, 10, 0, 40)
DreamSeedsLabel.BackgroundTransparency = 1
DreamSeedsLabel.Text = "💎 Dream Seeds: 0"
bind(DreamSeedsLabel, "TextColor3", "Dream")
DreamSeedsLabel.TextSize = 18
DreamSeedsLabel.Font = Style.DisplayFont
DreamSeedsLabel.TextXAlignment = Enum.TextXAlignment.Left
DreamSeedsLabel.Parent = CurrencyDisplay

--[[
    DAY/NIGHT INDICATOR
    Top-center showing current phase and progress
]]
-- Feature 005: the phase pill moves to the TOP-RIGHT (the concept HUD); the
-- top-centre is now the SEEDS/GARDEN/SELL nav in HUDControls.
local DayNightIndicator = Instance.new("Frame")
DayNightIndicator.Name = "DayNightIndicator"
DayNightIndicator.AnchorPoint = Vector2.new(1, 0)
DayNightIndicator.Size = UDim2.new(0, 220, 0, 64)
DayNightIndicator.Position = UDim2.new(1, -20, 0, 20)
bind(DayNightIndicator, "BackgroundColor3", "Surface")
DayNightIndicator.BorderSizePixel = 0
DayNightIndicator.Parent = HUD

local dayNightCorner = Instance.new("UICorner")
dayNightCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
dayNightCorner.Parent = DayNightIndicator

strokeOf(DayNightIndicator, "Outline")

-- Phase label (left of the pill). Feature 005: themed via tokens; the phase is
-- read from the text ("☀️ Day" / "🌙 Night"), not a per-phase hard-coded colour.
local PhaseLabel = Instance.new("TextLabel")
PhaseLabel.Name = "PhaseLabel"
PhaseLabel.Size = UDim2.new(0, 110, 0, 30)
PhaseLabel.Position = UDim2.new(0, 10, 0, 5)
PhaseLabel.BackgroundTransparency = 1
PhaseLabel.Text = "☀️ Day"
bind(PhaseLabel, "TextColor3", "TextPrimary")
PhaseLabel.TextXAlignment = Enum.TextXAlignment.Left
PhaseLabel.TextSize = 18
PhaseLabel.Font = Style.DisplayFont
PhaseLabel.Parent = DayNightIndicator

-- Time-left label (right of the pill). Feature 005: countdown to the phase end,
-- filled by UIController from the phase progress + a config duration (no client
-- clock); blank until data is available.
local TimeLeftLabel = Instance.new("TextLabel")
TimeLeftLabel.Name = "TimeLeftLabel"
TimeLeftLabel.AnchorPoint = Vector2.new(1, 0)
TimeLeftLabel.Size = UDim2.new(0, 80, 0, 30)
TimeLeftLabel.Position = UDim2.new(1, -10, 0, 5)
TimeLeftLabel.BackgroundTransparency = 1
TimeLeftLabel.Text = ""
bind(TimeLeftLabel, "TextColor3", "TextMuted")
TimeLeftLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLeftLabel.TextSize = 16
TimeLeftLabel.Font = Style.BodyFont
TimeLeftLabel.Parent = DayNightIndicator

-- Progress bar container
local ProgressBarContainer = Instance.new("Frame")
ProgressBarContainer.Name = "ProgressBarContainer"
ProgressBarContainer.Size = UDim2.new(1, -20, 0, 12)
ProgressBarContainer.Position = UDim2.new(0, 10, 1, -17)
bind(ProgressBarContainer, "BackgroundColor3", "Backdrop")
ProgressBarContainer.BorderSizePixel = 0
ProgressBarContainer.Parent = DayNightIndicator

local progressContainerCorner = Instance.new("UICorner")
progressContainerCorner.CornerRadius = UDim.new(0, 6)
progressContainerCorner.Parent = ProgressBarContainer

-- Progress bar (fills from left to right). Feature 005: themed Accent fill.
local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
bind(ProgressBar, "BackgroundColor3", "Accent")
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBarContainer

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, 6)
progressBarCorner.Parent = ProgressBar

--[[
    QUEST CARD (feature 005)
    Right side, under the phase pill: one current goal with its progress and reward.
    Populated by UIController from the existing quest state (first incomplete quest);
    a tap opens the full Quests window. Hidden until there is a quest to show.
]]
local QuestCard = Instance.new("TextButton")
QuestCard.Name = "QuestCard"
QuestCard.AnchorPoint = Vector2.new(1, 0)
QuestCard.Size = UDim2.new(0, 230, 0, 86)
QuestCard.Position = UDim2.new(1, -20, 0, 96)
bind(QuestCard, "BackgroundColor3", "SurfaceRaised")
QuestCard.BorderSizePixel = 0
QuestCard.AutoButtonColor = true
QuestCard.Text = ""
QuestCard.Visible = false
QuestCard.Parent = HUD

local questCorner = Instance.new("UICorner")
questCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
questCorner.Parent = QuestCard

strokeOf(QuestCard, "Outline")

local questHeading = Instance.new("TextLabel")
questHeading.Name = "HeadingLabel"
questHeading.Size = UDim2.new(1, -20, 0, 18)
questHeading.Position = UDim2.new(0, 10, 0, 6)
questHeading.BackgroundTransparency = 1
questHeading.Text = "📋 Current Quest"
bind(questHeading, "TextColor3", "TextMuted")
questHeading.TextXAlignment = Enum.TextXAlignment.Left
questHeading.TextSize = 13
questHeading.Font = Style.BodyFont
questHeading.Parent = QuestCard

local questTitle = Instance.new("TextLabel")
questTitle.Name = "TitleLabel"
questTitle.Size = UDim2.new(1, -20, 0, 24)
questTitle.Position = UDim2.new(0, 10, 0, 24)
questTitle.BackgroundTransparency = 1
questTitle.Text = "—"
bind(questTitle, "TextColor3", "TextPrimary")
questTitle.TextXAlignment = Enum.TextXAlignment.Left
questTitle.TextTruncate = Enum.TextTruncate.AtEnd
questTitle.TextSize = 17
questTitle.Font = Style.DisplayFont
questTitle.Parent = QuestCard

local questProgress = Instance.new("TextLabel")
questProgress.Name = "ProgressLabel"
questProgress.Size = UDim2.new(0.6, -10, 0, 20)
questProgress.Position = UDim2.new(0, 10, 1, -24)
questProgress.BackgroundTransparency = 1
questProgress.Text = ""
bind(questProgress, "TextColor3", "TextMuted")
questProgress.TextXAlignment = Enum.TextXAlignment.Left
questProgress.TextSize = 14
questProgress.Font = Style.BodyFont
questProgress.Parent = QuestCard

local questReward = Instance.new("TextLabel")
questReward.Name = "RewardLabel"
questReward.AnchorPoint = Vector2.new(1, 0)
questReward.Size = UDim2.new(0.4, -10, 0, 20)
questReward.Position = UDim2.new(1, -10, 1, -24)
questReward.BackgroundTransparency = 1
questReward.Text = ""
bind(questReward, "TextColor3", "Coins")
questReward.TextXAlignment = Enum.TextXAlignment.Right
questReward.TextSize = 14
questReward.Font = Style.DisplayFont
questReward.Parent = QuestCard

--[[
    HARVEST HINT (feature 005, FR-007)
    A contextual day-time hint shown bottom-centre, above the tool strip. It appears
    only when the player is near a ready-to-harvest plant by day (driven by
    HarvestHintController) and is actionable by an on-screen tap, not only the E key.
    A primary (Accent) button so it reads as the one thing to do; hidden by default.
    The anchored bottom-centre position clears the hotbar in every input mode, so it
    needs no per-mode ResponsiveLayout math.
]]
local HarvestHint = Instance.new("TextButton")
HarvestHint.Name = "HarvestHint"
HarvestHint.AnchorPoint = Vector2.new(0.5, 1)
HarvestHint.Size = UDim2.new(0, 190, 0, 52)
HarvestHint.Position = UDim2.new(0.5, 0, 1, -150)
bind(HarvestHint, "BackgroundColor3", "Accent")
HarvestHint.BorderSizePixel = 0
HarvestHint.AutoButtonColor = true
HarvestHint.Text = "🧺 Harvest"
bind(HarvestHint, "TextColor3", "TextOnAccent")
HarvestHint.TextSize = 22
HarvestHint.Font = Style.DisplayFont
HarvestHint.Visible = false
HarvestHint.Parent = HUD

local harvestCorner = Instance.new("UICorner")
harvestCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
harvestCorner.Parent = HarvestHint

strokeOf(HarvestHint, "OutlineDeep")

-- Key chip (PC): the E shortcut. Shown in KeyboardMouse mode by HarvestHintController;
-- a neutral dark chip with white text, matching the hotbar keybind chips (not themed).
local HarvestKeyHint = Instance.new("TextLabel")
HarvestKeyHint.Name = "KeyHint"
HarvestKeyHint.AnchorPoint = Vector2.new(1, 0.5)
HarvestKeyHint.Position = UDim2.new(1, -8, 0.5, 0)
HarvestKeyHint.Size = UDim2.new(0, 24, 0, 24)
HarvestKeyHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HarvestKeyHint.BackgroundTransparency = 0.4
HarvestKeyHint.BorderSizePixel = 0
HarvestKeyHint.Text = "E"
HarvestKeyHint.TextColor3 = Color3.fromRGB(255, 255, 255)
HarvestKeyHint.TextSize = 16
HarvestKeyHint.Font = Enum.Font.GothamBold
HarvestKeyHint.Visible = false
HarvestKeyHint.Parent = HarvestHint

local harvestKeyCorner = Instance.new("UICorner")
harvestKeyCorner.CornerRadius = UDim.new(0, 6)
harvestKeyCorner.Parent = HarvestKeyHint

print("✅ HUD created successfully!")
print("   Components:")
print("   - CurrencyDisplay (Coins, Dream Seeds)")
print("   - DayNightIndicator (Phase, Progress)")
print("")
print("🎮 HUD is ready for UIController!")
