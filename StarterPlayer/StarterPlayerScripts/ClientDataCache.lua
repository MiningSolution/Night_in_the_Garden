-- StarterPlayer / StarterPlayerScripts / ClientDataCache
-- Caches player data from server to avoid repeated RemoteFunction calls

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ClientDataCache = {}

-- State
local cachedData = {
    Currency = {
        Coins = 50,
        DreamSeeds = 0
    },
    Inventory = {
        ["carrot_seed"] = 5,
        ["basic_watering_can"] = 1,
        ["basic_lantern"] = 1
    },
    Plots = {
        ["Plot1"] = {
            State = "Empty",
            PlantId = nil,
            GrowthProgress = 0,
            IsWatered = false,
            TimeRemaining = nil
        },
        ["Plot2"] = {
            State = "Empty",
            PlantId = nil,
            GrowthProgress = 0,
            IsWatered = false,
            TimeRemaining = nil
        },
        ["Plot3"] = {
            State = "Empty",
            PlantId = nil,
            GrowthProgress = 0,
            IsWatered = false,
            TimeRemaining = nil
        }
    }
}

--[[
    Get cached currency
]]
function ClientDataCache.GetCurrency(currencyType)
    return cachedData.Currency[currencyType] or 0
end

--[[
    Get cached inventory
]]
function ClientDataCache.GetInventory()
    return cachedData.Inventory
end

--[[
    Get cached plot data
    @param plotId (string) - Plot identifier
    @return table - Plot data
]]
function ClientDataCache.GetPlot(plotId)
    return cachedData.Plots[plotId]
end

--[[
    Get all cached plots
    @return table - All plot data
]]
function ClientDataCache.GetAllPlots()
    return cachedData.Plots
end

--[[
    Update cache when server sends changes
    @param currencyType (string) - "Coins" or "DreamSeeds"
    @param newValue (number) - New currency value
    @param shouldNotifyUI (boolean) - Whether to update UI (default: true)
]]
function ClientDataCache.UpdateCurrency(currencyType, newValue, shouldNotifyUI)
    if shouldNotifyUI == nil then shouldNotifyUI = true end
    
    cachedData.Currency[currencyType] = newValue
    
    -- Notify UI
    if shouldNotifyUI then
        local UIController = require(script.Parent.Controllers.UIController)
        UIController.UpdateCurrency(
            cachedData.Currency.Coins,
            cachedData.Currency.DreamSeeds
        )
    end
end

--[[
    Update inventory cache
    @param newInventory (table) - New inventory data
    @param shouldNotifyUI (boolean) - Whether to update UI (default: true)
]]
function ClientDataCache.UpdateInventory(newInventory, shouldNotifyUI)
    if shouldNotifyUI == nil then shouldNotifyUI = true end
    
    cachedData.Inventory = newInventory
    
    -- Notify inventory UI
    if shouldNotifyUI then
        local InventoryController = require(script.Parent.Controllers.InventoryController)
        InventoryController.UpdateInventory(newInventory)
    end
end

--[[
    Update plot cache
    @param plotId (string) - Plot identifier
    @param plotData (table) - New plot data
]]
function ClientDataCache.UpdatePlot(plotId, plotData)
    -- Create plot entry if doesn't exist
    if not cachedData.Plots[plotId] then
        cachedData.Plots[plotId] = {}
    end
    
    -- Update plot data
    for key, value in pairs(plotData) do
        cachedData.Plots[plotId][key] = value
    end
    
    print(string.format("💾 Cache updated: %s → %s (%.0f%%)", 
        plotId, 
        plotData.State or "Unknown",
        (plotData.GrowthProgress or 0) * 100
    ))
end

--[[
    Request full data refresh from server
    (Call this when player joins)
]]
function ClientDataCache.RequestFullSync()
    print("🔄 Syncing data from server...")
    
    local GetPlayerData = ReplicatedStorage:FindFirstChild("GetPlayerData")
    
    if not GetPlayerData then
        warn("⚠️ GetPlayerData RemoteFunction not found")
        return
    end
    
    local success, result = pcall(function()
        return GetPlayerData:InvokeServer()
    end)
    
    if success and result then
        print("✅ Received full data sync from server")
        
        -- Update currency
        if result.Currency then
            cachedData.Currency = result.Currency
            local UIController = require(script.Parent.Controllers.UIController)
            UIController.UpdateCurrency(
                cachedData.Currency.Coins or 0,
                cachedData.Currency.DreamSeeds or 0
            )
        end
        
        -- Update inventory
        if result.Inventory then
            cachedData.Inventory = result.Inventory
            local InventoryController = require(script.Parent.Controllers.InventoryController)
            InventoryController.UpdateInventory(cachedData.Inventory)
        end
        
        -- Update plots
        if result.Plots then
            cachedData.Plots = result.Plots
            
            -- Update plot visuals
            local PlotVisualizer = require(script.Parent.PlotVisualizer)
            for plotId, plotData in pairs(result.Plots) do
                PlotVisualizer.UpdatePlot(plotId, plotData)
            end
        end
        
        print("💾 Full data cache synchronized:")
        print(string.format("   💰 Coins: %d", cachedData.Currency.Coins))
        print(string.format("   🌙 Dreams: %d", cachedData.Currency.DreamSeeds))
        print(string.format("   📦 Inventory: %d items", #cachedData.Inventory))
        print(string.format("   🌱 Plots: %d plots", #cachedData.Plots))
    else
        warn("❌ Failed to sync data:", result)
    end
end

-- Initialize
task.spawn(function()
    task.wait(2) -- Wait for game to load
    ClientDataCache.RequestFullSync()
end)

-- Initialize
task.spawn(function()
    task.wait(2) -- Wait for game to load
    ClientDataCache.RequestFullSync()
end)

-- === Added: ApplySnapshot for full syncs ===
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotVisualizer = require(script.Parent:WaitForChild("PlotVisualizer"))

-- Попробуем подтянуть контроллеры, но мягко
local UIController, InventoryController = nil, nil
pcall(function()
    UIController = require(script.Parent.Controllers:WaitForChild("UIController"))
    InventoryController = require(script.Parent.Controllers:WaitForChild("InventoryController"))
end)

-- Гарантируем, что локальный кеш есть
cachedData = cachedData or {
    Currency = {Coins = 0, DreamSeeds = 0},
    Inventory = {},
    Plots = {}
}

function ClientDataCache.ApplySnapshot(snapshot)
    if type(snapshot) ~= "table" then return end

    -- Валюта
    if snapshot.Currency then
        cachedData.Currency = snapshot.Currency
        if UIController and UIController.UpdateCurrency then
            UIController.UpdateCurrency(
                snapshot.Currency.Coins or 0,
                snapshot.Currency.DreamSeeds or 0
            )
        end
    end

    -- Инвентарь
    if snapshot.Inventory then
        cachedData.Inventory = snapshot.Inventory
        if InventoryController and InventoryController.UpdateInventory then
            InventoryController.UpdateInventory(snapshot.Inventory)
        end
    end

    -- Грядки
    if snapshot.Plots then
        cachedData.Plots = snapshot.Plots
        for plotId, plotData in pairs(snapshot.Plots) do
            if PlotVisualizer and PlotVisualizer.UpdatePlot then
                PlotVisualizer.UpdatePlot(plotId, plotData)
            end
        end
    end
end

return ClientDataCache
