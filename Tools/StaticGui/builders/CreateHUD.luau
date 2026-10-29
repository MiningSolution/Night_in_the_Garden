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
DreamSeedsLabel.Text = "🌙 Dreams: 0"
bind(DreamSeedsLabel, "TextColor3", "Dream")
DreamSeedsLabel.TextSize = 18
DreamSeedsLabel.Font = Style.DisplayFont
DreamSeedsLabel.TextXAlignment = Enum.TextXAlignment.Left
DreamSeedsLabel.Parent = CurrencyDisplay

--[[
    DAY/NIGHT INDICATOR
    Top-center showing current phase and progress
]]
local DayNightIndicator = Instance.new("Frame")
DayNightIndicator.Name = "DayNightIndicator"
DayNightIndicator.Size = UDim2.new(0, 200, 0, 60)
DayNightIndicator.Position = UDim2.new(0.5, -100, 0, 20)
bind(DayNightIndicator, "BackgroundColor3", "Surface")
DayNightIndicator.BorderSizePixel = 0
DayNightIndicator.Parent = HUD

local dayNightCorner = Instance.new("UICorner")
dayNightCorner.CornerRadius = UDim.new(0, Style.CornerRadius)
dayNightCorner.Parent = DayNightIndicator

strokeOf(DayNightIndicator, "Outline")

-- Phase label
local PhaseLabel = Instance.new("TextLabel")
PhaseLabel.Name = "PhaseLabel"
PhaseLabel.Size = UDim2.new(1, -20, 0, 30)
PhaseLabel.Position = UDim2.new(0, 10, 0, 5)
PhaseLabel.BackgroundTransparency = 1
PhaseLabel.Text = "☀️ Day"
PhaseLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
PhaseLabel.TextSize = 18
PhaseLabel.Font = Enum.Font.GothamBold
PhaseLabel.Parent = DayNightIndicator

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

-- Progress bar (fills from left to right)
local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBarContainer

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, 6)
progressBarCorner.Parent = ProgressBar

print("✅ HUD created successfully!")
print("   Components:")
print("   - CurrencyDisplay (Coins, Dream Seeds)")
print("   - DayNightIndicator (Phase, Progress)")
print("")
print("🎮 HUD is ready for UIController!")
