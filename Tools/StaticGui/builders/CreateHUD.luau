--[[
    CreateHUD.lua
    Location: StarterGui (as LocalScript)
    
    PURPOSE:
    Programmatically creates the HUD GUI including:
    - Currency display (Coins and Dream Seeds)
    - Day/Night cycle indicator with progress bar
    - Hotbar with 3 tool slots
    
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

-- Create main ScreenGui
local HUD = Instance.new("ScreenGui")
HUD.Name = "HUD"
HUD.ResetOnSpawn = false
HUD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HUD.Parent = playerGui

--[[
    CURRENCY DISPLAY
    Top-left corner showing coins and dream seeds
]]
local CurrencyDisplay = Instance.new("Frame")
CurrencyDisplay.Name = "CurrencyDisplay"
CurrencyDisplay.Size = UDim2.new(0, 250, 0, 80)
CurrencyDisplay.Position = UDim2.new(0, 20, 0, 20)
CurrencyDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
CurrencyDisplay.BorderSizePixel = 0
CurrencyDisplay.Parent = HUD

local currencyCorner = Instance.new("UICorner")
currencyCorner.CornerRadius = UDim.new(0, 12)
currencyCorner.Parent = CurrencyDisplay

-- Coins label
local CoinsLabel = Instance.new("TextLabel")
CoinsLabel.Name = "CoinsLabel"
CoinsLabel.Size = UDim2.new(1, -20, 0, 30)
CoinsLabel.Position = UDim2.new(0, 10, 0, 10)
CoinsLabel.BackgroundTransparency = 1
CoinsLabel.Text = "💰 Coins: 50"
CoinsLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
CoinsLabel.TextSize = 20
CoinsLabel.Font = Enum.Font.GothamBold
CoinsLabel.TextXAlignment = Enum.TextXAlignment.Left
CoinsLabel.Parent = CurrencyDisplay

-- Dream Seeds label
local DreamSeedsLabel = Instance.new("TextLabel")
DreamSeedsLabel.Name = "DreamSeedsLabel"
DreamSeedsLabel.Size = UDim2.new(1, -20, 0, 30)
DreamSeedsLabel.Position = UDim2.new(0, 10, 0, 40)
DreamSeedsLabel.BackgroundTransparency = 1
DreamSeedsLabel.Text = "🌙 Dreams: 0"
DreamSeedsLabel.TextColor3 = Color3.fromRGB(150, 180, 255)
DreamSeedsLabel.TextSize = 18
DreamSeedsLabel.Font = Enum.Font.GothamBold
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
DayNightIndicator.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DayNightIndicator.BorderSizePixel = 0
DayNightIndicator.Parent = HUD

local dayNightCorner = Instance.new("UICorner")
dayNightCorner.CornerRadius = UDim.new(0, 12)
dayNightCorner.Parent = DayNightIndicator

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
ProgressBarContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
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

--[[
    HOTBAR
    Bottom-center with 3 tool slots
]]
local Hotbar = Instance.new("Frame")
Hotbar.Name = "Hotbar"
Hotbar.Size = UDim2.new(0, 340, 0, 110)
Hotbar.Position = UDim2.new(0.5, -170, 1, -130)
Hotbar.BackgroundTransparency = 1
Hotbar.Parent = HUD

-- Create 3 hotbar slots
for i = 1, 3 do
    local slot = Instance.new("Frame")
    slot.Name = "Slot" .. i
    slot.Size = UDim2.new(0, 100, 0, 100)
    slot.Position = UDim2.new(0, (i-1) * 110, 0, 0)
    slot.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    slot.BorderSizePixel = 0
    slot.Parent = Hotbar
    
    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 10)
    slotCorner.Parent = slot
    
    -- Slot button (for click detection)
    local slotButton = Instance.new("TextButton")
    slotButton.Name = "SlotButton"
    slotButton.Size = UDim2.new(1, 0, 1, 0)
    slotButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slotButton.BackgroundTransparency = 0.3
    slotButton.BorderSizePixel = 0
    slotButton.Text = ""
    slotButton.AutoButtonColor = false
    slotButton.Parent = slot
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = slotButton
    
    -- Item icon
    local itemIcon = Instance.new("ImageLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(0, 60, 0, 60)
    itemIcon.Position = UDim2.new(0.5, 0, 0.4, 0)
    itemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Image = "rbxassetid://0"
    itemIcon.ScaleType = Enum.ScaleType.Fit
    itemIcon.Parent = slot
    
    -- Emoji label (fallback when no icon)
    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Name = "EmojiLabel"
    emojiLabel.Size = UDim2.new(1, 0, 1, 0)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    emojiLabel.TextSize = 40
    emojiLabel.Font = Enum.Font.GothamBold
    emojiLabel.Parent = itemIcon
    
    -- Set default emojis
    local defaultEmojis = {"💧", "🥕", "🏮"}
    emojiLabel.Text = defaultEmojis[i]
    
    -- Selection border (hidden by default)
    local selectionBorder = Instance.new("ImageLabel")
    selectionBorder.Name = "SelectionBorder"
    selectionBorder.Size = UDim2.new(1, 8, 1, 8)
    selectionBorder.Position = UDim2.new(0.5, 0, 0.5, 0)
    selectionBorder.AnchorPoint = Vector2.new(0.5, 0.5)
    selectionBorder.BackgroundTransparency = 1
    selectionBorder.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    selectionBorder.ImageColor3 = Color3.fromRGB(80, 200, 120)
    selectionBorder.ScaleType = Enum.ScaleType.Slice
    selectionBorder.SliceCenter = Rect.new(8, 8, 8, 8)
    selectionBorder.Visible = false
    selectionBorder.ZIndex = 0
    selectionBorder.Parent = slot
    
    -- Keybind hint (bottom of slot)
    local keybindHint = Instance.new("TextLabel")
    keybindHint.Name = "KeybindHint"
    keybindHint.Size = UDim2.new(0, 30, 0, 25)
    keybindHint.Position = UDim2.new(0.5, 0, 1, -5)
    keybindHint.AnchorPoint = Vector2.new(0.5, 1)
    keybindHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    keybindHint.BackgroundTransparency = 0.5
    keybindHint.BorderSizePixel = 0
    keybindHint.Text = tostring(i)
    keybindHint.TextColor3 = Color3.fromRGB(255, 255, 255)
    keybindHint.TextSize = 16
    keybindHint.Font = Enum.Font.GothamBold
    keybindHint.Parent = slot
    
    local keybindCorner = Instance.new("UICorner")
    keybindCorner.CornerRadius = UDim.new(0, 6)
    keybindCorner.Parent = keybindHint
end

-- Show selection on first slot by default
local firstSlot = Hotbar:FindFirstChild("Slot1")
if firstSlot then
    local selectionBorder = firstSlot:FindFirstChild("SelectionBorder")
    if selectionBorder then
        selectionBorder.Visible = true
    end
end

print("✅ HUD created successfully!")
print("   Components:")
print("   - CurrencyDisplay (Coins, Dream Seeds)")
print("   - DayNightIndicator (Phase, Progress)")
print("   - Hotbar (3 slots with keybinds)")
print("")
print("🎮 HUD is ready for UIController!")
