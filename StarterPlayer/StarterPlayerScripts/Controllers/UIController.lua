--[[
    UIController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/
    
    PURPOSE:
    Central controller for all UI management including:
    - Currency display updates
    - Day/Night cycle indicator
    - Inventory toggle
    - Shop toggle
    - Notification system
    - Keyboard shortcuts
    
    DEPENDENCIES:
    - HUD ScreenGui (with CurrencyDisplay, DayNightIndicator, Hotbar)
    - InventoryUI ScreenGui
    - ShopUI ScreenGui
    - InventoryController module
    - ShopController module
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StateManager = require(script.Parent.Parent.Utils:WaitForChild("StateManager"))

local UIController = {}

-- References to GUI elements
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Main UI references (with error handling)
local HUD = playerGui:WaitForChild("HUD", 10)
local InventoryUI = playerGui:WaitForChild("InventoryUI", 10)
local ShopUI = playerGui:WaitForChild("ShopUI", 10)

-- Currency Display elements
local currencyDisplay, coinsLabel, dreamSeedsLabel
if HUD then
    currencyDisplay = HUD:WaitForChild("CurrencyDisplay", 5)
    if currencyDisplay then
        coinsLabel = currencyDisplay:WaitForChild("CoinsLabel", 5)
        dreamSeedsLabel = currencyDisplay:WaitForChild("DreamSeedsLabel", 5)
    end
end

-- Day/Night Indicator elements
local dayNightIndicator, phaseLabel, progressBar
if HUD then
    dayNightIndicator = HUD:WaitForChild("DayNightIndicator", 5)
    if dayNightIndicator then
        phaseLabel = dayNightIndicator:WaitForChild("PhaseLabel", 5)
        -- CreateHUD nests the bar: DayNightIndicator > ProgressBarContainer > ProgressBar
        local barContainer = dayNightIndicator:WaitForChild("ProgressBarContainer", 5)
        progressBar = barContainer and barContainer:WaitForChild("ProgressBar", 5)
    end
end

-- UI State
local inventoryOpen = false
local shopOpen = false

-- Cache for smooth animations
local lastCoins = 0
local lastDreamSeeds = 0

--[[
    Update currency display with optional animation
    
    @param coins (number) - Current coin balance
    @param dreamSeeds (number) - Current dream seed balance
    @param animate (boolean) - Whether to animate the change (default: true)
]]
function UIController.UpdateCurrency(coins, dreamSeeds, animate)
    if not coinsLabel or not dreamSeedsLabel then
        warn("⚠️ Currency labels not found in HUD")
        return
    end
    
    animate = animate == nil and true or animate
    
    -- Update coins
    if animate and coins ~= lastCoins then
        -- Animate number change
        local startValue = lastCoins
        local endValue = coins
        local duration = 0.5
        
        local tweenInfo = TweenInfo.new(
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        -- Create value object for tweening
        local valueObject = Instance.new("NumberValue")
        valueObject.Value = startValue
        
        valueObject.Changed:Connect(function()
            coinsLabel.Text = string.format("💰 Coins: %d", math.floor(valueObject.Value))
        end)
        
        local tween = TweenService:Create(valueObject, tweenInfo, {Value = endValue})
        tween:Play()
        
        -- Add pulse effect
        local originalSize = coinsLabel.TextSize
        local pulseInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
        local pulseTween = TweenService:Create(coinsLabel, pulseInfo, {TextSize = originalSize + 4})
        pulseTween:Play()
        
        tween.Completed:Connect(function()
            valueObject:Destroy()
        end)
    else
        coinsLabel.Text = string.format("💰 Coins: %d", coins)
    end
    
    lastCoins = coins
    
    -- Update dream seeds
    if animate and dreamSeeds ~= lastDreamSeeds then
        -- Animate dream seeds
        local startValue = lastDreamSeeds
        local endValue = dreamSeeds
        local duration = 0.5
        
        local tweenInfo = TweenInfo.new(
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        local valueObject = Instance.new("NumberValue")
        valueObject.Value = startValue
        
        valueObject.Changed:Connect(function()
            dreamSeedsLabel.Text = string.format("🌙 Dreams: %d", math.floor(valueObject.Value))
        end)
        
        local tween = TweenService:Create(valueObject, tweenInfo, {Value = endValue})
        tween:Play()
        
        -- Add pulse effect
        local originalSize = dreamSeedsLabel.TextSize
        local pulseInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
        local pulseTween = TweenService:Create(dreamSeedsLabel, pulseInfo, {TextSize = originalSize + 4})
        pulseTween:Play()
        
        tween.Completed:Connect(function()
            valueObject:Destroy()
        end)
    else
        dreamSeedsLabel.Text = string.format("🌙 Dreams: %d", dreamSeeds)
    end
    
    lastDreamSeeds = dreamSeeds
end

--[[
    Update day/night cycle indicator
    
    @param phase (string) - "Day" or "Night"
    @param progress (number) - Progress through current phase (0 to 1)
]]
function UIController.UpdateDayNight(phase, progress)
    if not phaseLabel or not progressBar then
        warn("⚠️ Day/Night indicator not found in HUD")
        return
    end
    
    progress = math.clamp(progress, 0, 1)
    
    -- Update phase label with appropriate styling
    if phase == "Day" then
        phaseLabel.Text = "☀️ Day"
        phaseLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        
        -- Yellow progress bar for day
        if progressBar:IsA("Frame") then
            progressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        end
    elseif phase == "Night" then
        phaseLabel.Text = "🌙 Night"
        phaseLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
        
        -- Blue progress bar for night
        if progressBar:IsA("Frame") then
            progressBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        end
    else
        phaseLabel.Text = "⏳ Transition"
        phaseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- Animate progress bar
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(progressBar, tweenInfo, {
        Size = UDim2.new(progress, 0, 1, 0)
    })
    tween:Play()
end

--[[
    Toggle inventory UI
    Opens inventory and closes shop if open
]]
function UIController.ToggleInventory()
    if not InventoryUI then
        warn("⚠️ InventoryUI not found")
        return
    end
    
    inventoryOpen = not inventoryOpen
    InventoryUI.Enabled = inventoryOpen
    
    if inventoryOpen then
        -- Close shop if open
        if shopOpen then
            UIController.ToggleShop()
        end
        
        -- Refresh inventory display
        local success, inventoryController = pcall(function()
            return require(script.Parent.InventoryController)
        end)
        
        if success and inventoryController then
            inventoryController.RefreshGrid()
        else
            warn("⚠️ Could not load InventoryController:", inventoryController)
        end
        
        print("📦 Inventory opened")
    else
        print("📦 Inventory closed")
    end
end

--[[
    Toggle shop UI
    Opens shop and closes inventory if open
]]
function UIController.ToggleShop()
    if not ShopUI then
        warn("⚠️ ShopUI not found")
        return
    end
    
    shopOpen = not shopOpen
    ShopUI.Enabled = shopOpen
    
    if shopOpen then
        -- Close inventory if open
        if inventoryOpen then
            UIController.ToggleInventory()
        end
        
        -- Load shop data
        local success, shopController = pcall(function()
            return require(script.Parent.ShopController)
        end)
        
        if success and shopController then
            shopController.LoadShopData()
        else
            warn("⚠️ Could not load ShopController:", shopController)
        end
        
        print("🏪 Shop opened")
    else
        print("🏪 Shop closed")
    end
end

--[[
    Show notification message to player
    
    @param message (string) - Message to display
    @param messageType (string) - "success", "error", "info", or "warning"
    @param duration (number) - How long to show notification (default: 3 seconds)
]]
function UIController.ShowNotification(message, messageType, duration)
    messageType = messageType or "info"
    duration = duration or 3
    
    -- Color coding for message types
    local colors = {
        success = Color3.fromRGB(80, 200, 120),
        error = Color3.fromRGB(220, 80, 80),
        info = Color3.fromRGB(100, 150, 255),
        warning = Color3.fromRGB(255, 180, 50),
        spirit = Color3.fromRGB(180, 120, 255)  -- Фиолетовый для духов
    }
    
    local icons = {
        success = "✅",
        error = "❌",
        info = "ℹ️",
        warning = "⚠️",
        spirit = "👻"  -- Призрак для духов
    }
    
    local color = colors[messageType] or colors.info
    local icon = icons[messageType] or icons.info
    
    -- For now, print to console
    -- TODO: Create notification frame UI element
    local fullMessage = string.format("%s [%s] %s", icon, messageType:upper(), message)
    print(fullMessage)
    
    -- Placeholder for future notification UI
    --[[
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 300, 0, 60)
    notificationFrame.Position = UDim2.new(0.5, 0, 0, -70)
    notificationFrame.AnchorPoint = Vector2.new(0.5, 0)
    notificationFrame.BackgroundColor3 = color
    notificationFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = icon .. " " .. message
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = notificationFrame
    
    notificationFrame.Parent = playerGui:WaitForChild("HUD")
    
    -- Animate in
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = TweenService:Create(notificationFrame, tweenInfo, {
        Position = UDim2.new(0.5, 0, 0, 20)
    })
    tween:Play()
    
    -- Remove after duration
    task.delay(duration, function()
        local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local fadeTween = TweenService:Create(notificationFrame, fadeInfo, {
            Position = UDim2.new(0.5, 0, 0, -70)
        })
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            notificationFrame:Destroy()
        end)
    end)
    ]]
end

--[[
    Close all open UIs
]]
function UIController.CloseAllUIs()
    if inventoryOpen then
        UIController.ToggleInventory()
    end
    if shopOpen then
        UIController.ToggleShop()
    end
end

--[[
    Get current UI state
    @return table with inventoryOpen and shopOpen booleans
]]
function UIController.GetUIState()
    return {
        inventoryOpen = inventoryOpen,
        shopOpen = shopOpen
    }
end

--[[
    Initialize UI Controller
    Sets up keyboard shortcuts and initial values
]]
function UIController.Initialize()
    print("========================================")
    print("🎮 Initializing UIController...")
    print("========================================")
    
    -- P1-2: Subscribe to StateManager changes
    StateManager.subscribe(function(state, oldState, action)
        -- Handle currency updates
        if action.type == "UPDATE_CURRENCY" or action.type == "UPDATE_CURRENCY_FULL" or action.type == "APPLY_SNAPSHOT" then
            local coins = state.player.currency.Coins or 0
            local dreamSeeds = state.player.currency.DreamSeeds or 0
            UIController.UpdateCurrency(coins, dreamSeeds, true)
        end
        
        -- Handle day/night updates
        if action.type == "UPDATE_DAY_NIGHT" then
            UIController.UpdateDayNight(state.ui.dayNightPhase, state.ui.dayNightProgress)
        end
    end)
    
    -- Bind keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        -- Don't process input if player is typing in chat
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.I then
            UIController.ToggleInventory()
            
        elseif input.KeyCode == Enum.KeyCode.B then
            UIController.ToggleShop()
            
        elseif input.KeyCode == Enum.KeyCode.Escape then
            -- Close all UIs
            UIController.CloseAllUIs()
        end
    end)
    
    -- Set initial currency values from StateManager
    local coins = StateManager.getCurrency("Coins") or 0
    local dreamSeeds = StateManager.getCurrency("DreamSeeds") or 0
    UIController.UpdateCurrency(coins, dreamSeeds, false) -- No animation on init
    
    -- Set initial day/night state from StateManager
    local phase, progress = StateManager.getDayNight()
    UIController.UpdateDayNight(phase or "Day", progress or 0)
    
    print("✅ Keyboard shortcuts registered:")
    print("   [I] - Toggle Inventory")
    print("   [B] - Toggle Shop")
    print("   [ESC] - Close all UIs")
    print("")
    print("✅ StateManager subscription active")
    print("✅ Initial values loaded from StateManager")
    print("========================================")
    print("✨ UIController ready!")
    print("========================================")
end

-- Auto-initialize when module loads
UIController.Initialize()

return UIController
