-- StateManager.lua
-- P1-2: Unified State Manager using Redux/Flux pattern
-- Single source of truth for all client-side game state

local StateManager = {}

-- Single source of truth
local state = {
    player = {
        currency = {
            Coins = 0,
            DreamSeeds = 0
        },
        inventory = {},
        plots = {},
        stats = {}
    },
    shop = {
        config = nil,
        isLoading = false
    },
    ui = {
        inventoryOpen = false,
        shopOpen = false,
        dayNightPhase = "Day",
        dayNightProgress = 0
    }
}

-- Subscribers (controllers that want state updates)
local subscribers = {}

--[[
    Deep copy helper for immutable state
]]
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do
        r[k] = deepCopy(v)
    end
    return r
end

--[[
    Dispatch an action to update state
    @param action (table) - Action with type and payload
]]
function StateManager.dispatch(action)
    if type(action) ~= "table" or not action.type then
        warn("[StateManager] Invalid action:", action)
        return
    end
    
    local oldState = deepCopy(state)
    
    -- Reducer pattern - update state based on action type
    if action.type == "UPDATE_CURRENCY" then
        if action.currencyType and action.value ~= nil then
            state.player.currency[action.currencyType] = action.value
        end
        
    elseif action.type == "UPDATE_CURRENCY_FULL" then
        if action.currency then
            state.player.currency = deepCopy(action.currency)
        end
        
    elseif action.type == "UPDATE_INVENTORY" then
        if action.inventory then
            state.player.inventory = deepCopy(action.inventory)
        end
        
    elseif action.type == "UPDATE_INVENTORY_ITEM" then
        if action.itemName and action.quantity ~= nil then
            if action.quantity > 0 then
                state.player.inventory[action.itemName] = action.quantity
            else
                state.player.inventory[action.itemName] = nil
            end
        end
        
    elseif action.type == "UPDATE_PLOT" then
        if action.plotId and action.plotData then
            if not state.player.plots[action.plotId] then
                state.player.plots[action.plotId] = {}
            end
            for key, value in pairs(action.plotData) do
                state.player.plots[action.plotId][key] = value
            end
        end
        
    elseif action.type == "UPDATE_PLOTS" then
        if action.plots then
            state.player.plots = deepCopy(action.plots)
        end
        
    elseif action.type == "UPDATE_DAY_NIGHT" then
        if action.phase then
            state.ui.dayNightPhase = action.phase
        end
        if action.progress ~= nil then
            state.ui.dayNightProgress = action.progress
        end
        
    elseif action.type == "UPDATE_SHOP_CONFIG" then
        if action.config then
            state.shop.config = deepCopy(action.config)
        end
        
    elseif action.type == "SET_UI_STATE" then
        if action.uiState then
            for key, value in pairs(action.uiState) do
                state.ui[key] = value
            end
        end
        
    elseif action.type == "APPLY_SNAPSHOT" then
        -- Full state replacement from server snapshot
        if action.snapshot then
            if action.snapshot.Currency then
                state.player.currency = deepCopy(action.snapshot.Currency)
            end
            if action.snapshot.Inventory then
                state.player.inventory = deepCopy(action.snapshot.Inventory)
            end
            if action.snapshot.Plots then
                state.player.plots = deepCopy(action.snapshot.Plots)
            end
            if action.snapshot.Stats then
                state.player.stats = deepCopy(action.snapshot.Stats)
            end
        end
        
    else
        warn("[StateManager] Unknown action type:", action.type)
        return
    end
    
    -- Notify all subscribers
    for _, callback in ipairs(subscribers) do
        local success, err = pcall(function()
            callback(state, oldState, action)
        end)
        
        if not success then
            warn("[StateManager] Subscriber error:", err)
        end
    end
end

--[[
    Subscribe to state changes
    @param callback (function) - Function(state, oldState, action)
    @return function - Unsubscribe function
]]
function StateManager.subscribe(callback)
    if type(callback) ~= "function" then
        warn("[StateManager] Invalid subscriber callback")
        return function() end
    end
    
    table.insert(subscribers, callback)
    
    -- Return unsubscribe function
    return function()
        for i, cb in ipairs(subscribers) do
            if cb == callback then
                table.remove(subscribers, i)
                break
            end
        end
    end
end

--[[
    Get current state (immutable copy)
    @return table - Current state
]]
function StateManager.getState()
    return deepCopy(state)
end

--[[
    Get currency value
    @param currencyType (string) - "Coins" or "DreamSeeds"
    @return number - Currency value
]]
function StateManager.getCurrency(currencyType)
    return state.player.currency[currencyType] or 0
end

--[[
    Get inventory
    @return table - Inventory dictionary
]]
function StateManager.getInventory()
    return deepCopy(state.player.inventory)
end

--[[
    Get plot data
    @param plotId (string) - Plot identifier
    @return table - Plot data or nil
]]
function StateManager.getPlot(plotId)
    return deepCopy(state.player.plots[plotId])
end

--[[
    Get all plots
    @return table - All plots dictionary
]]
function StateManager.getAllPlots()
    return deepCopy(state.player.plots)
end

--[[
    Get day/night state
    @return string, number - Phase and progress
]]
function StateManager.getDayNight()
    return state.ui.dayNightPhase, state.ui.dayNightProgress
end

--[[
    Get shop config
    @return table - Shop config or nil
]]
function StateManager.getShopConfig()
    return state.shop.config and deepCopy(state.shop.config) or nil
end

--[[
    Initialize StateManager
]]
function StateManager.init()
    print("🗂️ StateManager initialized")
    print("   Subscribers: 0")
    print("   State structure ready")
end

-- Initialize on load
StateManager.init()

return StateManager

