-- StarterPlayer / StarterPlayerScripts / Utils / ClientDataCache
-- P1-2: Refactored to use StateManager as single source of truth
-- Provides backward-compatible API while using StateManager internally

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StateManager = require(script.Parent:WaitForChild("StateManager"))

local ClientDataCache = {}

--[[
    Get cached currency (P1-2: Uses StateManager)
]]
function ClientDataCache.GetCurrency(currencyType)
    return StateManager.getCurrency(currencyType)
end

--[[
    Get cached inventory (P1-2: Uses StateManager)
]]
function ClientDataCache.GetInventory()
    return StateManager.getInventory()
end

--[[
    Get cached plot data (P1-2: Uses StateManager)
    @param plotId (string) - Plot identifier
    @return table - Plot data
]]
function ClientDataCache.GetPlot(plotId)
    return StateManager.getPlot(plotId)
end

--[[
    Get all cached plots (P1-2: Uses StateManager)
    @return table - All plot data
]]
function ClientDataCache.GetAllPlots()
    return StateManager.getAllPlots()
end

--[[
    Update cache when server sends changes (P1-2: Uses StateManager dispatch)
    @param currencyType (string) - "Coins" or "DreamSeeds"
    @param newValue (number) - New currency value
    @param shouldNotifyUI (boolean) - Deprecated, kept for compatibility
]]
function ClientDataCache.UpdateCurrency(currencyType, newValue, shouldNotifyUI)
    -- P1-2: Dispatch action to StateManager
    StateManager.dispatch({
        type = "UPDATE_CURRENCY",
        currencyType = currencyType,
        value = newValue
    })
end

--[[
    Update inventory cache (P1-2: Uses StateManager dispatch)
    @param newInventory (table) - New inventory data
    @param shouldNotifyUI (boolean) - Deprecated, kept for compatibility
]]
function ClientDataCache.UpdateInventory(newInventory, shouldNotifyUI)
    -- P1-2: Dispatch action to StateManager
    StateManager.dispatch({
        type = "UPDATE_INVENTORY",
        inventory = newInventory
    })
end

--[[
    Update plot cache (P1-2: Uses StateManager dispatch)
    @param plotId (string) - Plot identifier
    @param plotData (table) - New plot data
]]
function ClientDataCache.UpdatePlot(plotId, plotData)
    -- P1-2: Dispatch action to StateManager
    StateManager.dispatch({
        type = "UPDATE_PLOT",
        plotId = plotId,
        plotData = plotData
    })
    
    print(string.format("💾 Cache updated: %s → %s (%.0f%%)", 
        plotId, 
        plotData.State or "Unknown",
        (plotData.GrowthProgress or 0) * 100
    ))
end

--[[
    Update day/night state (P1-2: New function for StateManager)
    @param phase (string) - "Day" or "Night"
    @param progress (number) - Progress through phase (0-1)
]]
function ClientDataCache.UpdateDayNight(phase, progress)
    StateManager.dispatch({
        type = "UPDATE_DAY_NIGHT",
        phase = phase,
        progress = progress
    })
end

--[[
    Request full data refresh from server (P1-2: Uses StateManager)
    (Call this when player joins)
]]
function ClientDataCache.RequestFullSync()
    print("🔄 Syncing data from server...")
    
    local GetPlayerData = ReplicatedStorage:FindFirstChild("GetPlayerData")
    
    if not GetPlayerData then
        warn("⚠️ GetPlayerData RemoteFunction not found")
        return false
    end
    
    local success, result = pcall(function()
        return GetPlayerData:InvokeServer()
    end)
    
    if success and result and result.Success then
        print("✅ Received full data sync from server")
        
        -- P1-2: Dispatch snapshot to StateManager
        StateManager.dispatch({
            type = "APPLY_SNAPSHOT",
            snapshot = result
        })
        
        -- Count inventory items (dictionary-style table)
        local inventoryCount = 0
        for _ in pairs(result.Inventory or {}) do inventoryCount = inventoryCount + 1 end
        
        -- Count plots (dictionary-style table)
        local plotCount = 0
        for _ in pairs(result.Plots or {}) do plotCount = plotCount + 1 end
        
        print("💾 Full data cache synchronized:")
        print(string.format("   💰 Coins: %d", result.Currency and result.Currency.Coins or 0))
        print(string.format("   🌙 Dreams: %d", result.Currency and result.Currency.DreamSeeds or 0))
        print(string.format("   📦 Inventory: %d items", inventoryCount))
        print(string.format("   🌱 Plots: %d plots", plotCount))
        return true
    else
        warn("❌ Failed to sync data:", result)
        return false
    end
end

-- === ApplySnapshot for full syncs (P1-2: Uses StateManager) ===
function ClientDataCache.ApplySnapshot(snapshot)
    if type(snapshot) ~= "table" then return end

    -- P1-2: Dispatch snapshot to StateManager
    StateManager.dispatch({
        type = "APPLY_SNAPSHOT",
        snapshot = snapshot
    })
end

-- P1-2: Backward compatibility - SetAll function
function ClientDataCache.SetAll(data)
    ClientDataCache.ApplySnapshot(data)
end

-- Initialize: Request full sync on load.
-- The server answers "Data not loaded" until ProfileService has loaded the
-- profile, which can take longer than the first request, so retry with backoff.
task.spawn(function()
    task.wait(2) -- Wait for game to load
    local delay = 1
    for attempt = 1, 8 do
        if ClientDataCache.RequestFullSync() then return end
        task.wait(delay)
        delay = math.min(delay * 2, 8)
    end
    warn("❌ ClientDataCache: initial data sync gave up after 8 attempts")
end)

return ClientDataCache
