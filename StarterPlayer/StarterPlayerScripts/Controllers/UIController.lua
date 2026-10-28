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
-- Static GUI (P2-3) is cloned into PlayerGui when the character first spawns,
-- which can take longer than any fixed timeout on a slow join: wait for it.
local HUD = playerGui:WaitForChild("HUD")
local HUDControls = playerGui:WaitForChild("HUDControls")
local InventoryUI = playerGui:WaitForChild("InventoryUI")
local ShopUI = playerGui:WaitForChild("ShopUI")

-- Feature 001: single-window state and layout constants.
local Utils = script.Parent.Parent:WaitForChild("Utils")
local WindowManager = require(Utils:WaitForChild("WindowManager"))
local ResponsiveLayout = require(Utils:WaitForChild("ResponsiveLayout"))

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
        -- The HUD nests the bar: DayNightIndicator > ProgressBarContainer > ProgressBar
        local barContainer = dayNightIndicator:WaitForChild("ProgressBarContainer", 5)
        progressBar = barContainer and barContainer:WaitForChild("ProgressBar", 5)
    end
end

-- UI open/close state now lives in WindowManager (one window at a time, FR-003).

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
    -- Delegates to WindowManager; opening closes any other window and runs the
    -- registered onOpen (InventoryController.RefreshGrid).
    WindowManager.Toggle("Inventory")
end

--[[
    Toggle shop UI
    Opens shop and closes inventory if open
]]
function UIController.ToggleShop()
    -- Delegates to WindowManager; opening closes any other window and runs the
    -- registered onOpen (ShopController.LoadShopData).
    WindowManager.Toggle("Shop")
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
    WindowManager.Close()
end

--[[
    Get current UI state
    @return table with inventoryOpen and shopOpen booleans
]]
function UIController.GetUIState()
    local open = WindowManager.GetOpen()
    return {
        inventoryOpen = open == "Inventory",
        shopOpen = open == "Shop"
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
    
    -- Feature 001: register the two windows with WindowManager (one open at a
    -- time, FR-003). Window aspect/maxSize come from ResponsiveLayout.WINDOWS
    -- (single source, constitution II). The keyboard/gamepad open actions are
    -- owned by InputActions; the menu buttons are wired below (touch path).
    local function findFrame(gui, ...)
        for _, n in ipairs({...}) do
            local f = gui:FindFirstChild(n)
            if f then return f end
        end
        return nil
    end

    WindowManager.Register("Shop", {
        gui = ShopUI,
        frame = findFrame(ShopUI, "ShopFrame", "MainFrame", "Frame"),
        backdrop = ShopUI:FindFirstChild("Backdrop"),
        aspect = ResponsiveLayout.WINDOWS.Shop.aspect,
        maxSize = Vector2.new(ResponsiveLayout.WINDOWS.Shop.maxW, ResponsiveLayout.WINDOWS.Shop.maxH),
        onOpen = function()
            local ok, shop = pcall(require, script.Parent.ShopController)
            if ok and shop then shop.LoadShopData() else warn("⚠️ Could not load ShopController:", shop) end
        end,
    })

    WindowManager.Register("Inventory", {
        gui = InventoryUI,
        frame = findFrame(InventoryUI, "InventoryFrame", "MainFrame", "Frame"),
        backdrop = InventoryUI:FindFirstChild("Backdrop"),
        aspect = ResponsiveLayout.WINDOWS.Inventory.aspect,
        maxSize = Vector2.new(ResponsiveLayout.WINDOWS.Inventory.maxW, ResponsiveLayout.WINDOWS.Inventory.maxH),
        onOpen = function()
            local ok, inv = pcall(require, script.Parent.InventoryController)
            if ok and inv then inv.RefreshGrid() else warn("⚠️ Could not load InventoryController:", inv) end
        end,
    })

    -- Wire the always-visible menu buttons so touch players can open/switch the
    -- windows without a keyboard (US1, FR-001/FR-003).
    local menuButtons = HUDControls:WaitForChild("MenuButtons")
    menuButtons:WaitForChild("ShopButton").Activated:Connect(function()
        UIController.ToggleShop()
    end)
    menuButtons:WaitForChild("InventoryButton").Activated:Connect(function()
        UIController.ToggleInventory()
    end)

    -- US2 (FR-004): size and position the menu column and the windows from
    -- ResponsiveLayout so they fit every screen inside the safe area. Recompute
    -- only on viewport-size or input-mode changes, never per frame (R2, SC-006).
    -- The touch hotbar geometry (slot resize) is applied in US4.
    local InputActions = require(Utils:WaitForChild("InputActions"))
    local camera = workspace.CurrentCamera
    local shopFrame = ShopUI:WaitForChild("ShopFrame")
    local inventoryFrame = InventoryUI:WaitForChild("InventoryFrame")
    local hotbarFrame = HUDControls:WaitForChild("Hotbar")

    -- Live jump-button rect (US4): read Roblox's touch JumpButton so the hotbar
    -- is placed clear of it; nil falls back to the formula inside ResponsiveLayout.
    local function jumpRect()
        local touchGui = playerGui:FindFirstChild("TouchGui")
        local tcf = touchGui and touchGui:FindFirstChild("TouchControlFrame")
        local jb = tcf and tcf:FindFirstChild("JumpButton")
        if jb and jb.Visible and jb.AbsoluteSize.X > 0 then
            local origin = HUDControls.AbsolutePosition
            return {
                x = jb.AbsolutePosition.X - origin.X,
                y = jb.AbsolutePosition.Y - origin.Y,
                w = jb.AbsoluteSize.X,
                h = jb.AbsoluteSize.Y,
            }
        end
        return nil
    end

    local function placeFrame(frame, r)
        if frame and r then
            frame.AnchorPoint = Vector2.new(0, 0)
            frame.Position = UDim2.fromOffset(r.x, r.y)
            frame.Size = UDim2.fromOffset(r.w, r.h)
        end
    end

    local function applyLayout()
        local absSize = HUDControls.AbsoluteSize
        if absSize.X < 1 or absSize.Y < 1 then return end
        local vp = camera and camera.ViewportSize or absSize
        local res = ResponsiveLayout.compute({
            viewport = { w = vp.X, h = vp.Y },
            gui = { x = 0, y = 0, w = absSize.X, h = absSize.Y },
            mode = InputActions.GetMode() or "KeyboardMouse",
            jump = jumpRect(),
        })
        menuButtons.AnchorPoint = Vector2.new(0, 0)
        menuButtons.Position = UDim2.fromOffset(res.menuColumn.x, res.menuColumn.y)
        menuButtons.Size = UDim2.fromOffset(res.menuColumn.w, res.menuColumn.h)
        -- Size both windows (hidden ones too) so they are fitted when opened.
        placeFrame(shopFrame, res.windows.Shop)
        placeFrame(inventoryFrame, res.windows.Inventory)
        -- Hotbar (US4): position the frame and resize the 3 slots to the mode's
        -- slot size (64 touch / 100 otherwise), clear of the thumbstick and jump.
        hotbarFrame.AnchorPoint = Vector2.new(0, 0)
        hotbarFrame.Position = UDim2.fromOffset(res.hotbar.x, res.hotbar.y)
        hotbarFrame.Size = UDim2.fromOffset(res.hotbar.w, res.hotbar.h)
        local slotSize, gap = res.hotbar.slotSize, res.hotbar.gap
        for i = 1, 3 do
            local slot = hotbarFrame:FindFirstChild("Slot" .. i)
            if slot then
                slot.Size = UDim2.fromOffset(slotSize, slotSize)
                slot.Position = UDim2.fromOffset((i - 1) * (slotSize + gap), 0)
            end
        end
    end

    applyLayout()
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
    end
    HUDControls:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)
    InputActions.ModeChanged:Connect(applyLayout)
    WindowManager.Changed:Connect(applyLayout)

    -- US3 (FR-009): no game action depends on Esc — it belongs to the Roblox
    -- menu. Windows close via X, the dim backdrop, or gamepad B (bound by
    -- InputActions while a window is open).

    -- Set initial currency values from StateManager
    local coins = StateManager.getCurrency("Coins") or 0
    local dreamSeeds = StateManager.getCurrency("DreamSeeds") or 0
    UIController.UpdateCurrency(coins, dreamSeeds, false) -- No animation on init
    
    -- Set initial day/night state from StateManager
    local phase, progress = StateManager.getDayNight()
    UIController.UpdateDayNight(phase or "Day", progress or 0)
    
    print("✅ Windows registered with WindowManager (actions via InputActions):")
    print("   [I] / Y  - Toggle Inventory")
    print("   [B] / X  - Toggle Shop")
    print("   close: X button, backdrop tap, or gamepad B (Esc is Roblox menu only)")
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
