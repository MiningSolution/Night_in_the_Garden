--[[
    ClientDataCache.lua
    Location: StarterPlayer/StarterPlayerScripts/
    
    PURPOSE:
    Centralized client-side data management including:
    - Currency caching (coins, dream seeds)
    - Inventory caching
    - Plot data caching (future)
    - Reduces RemoteFunction calls
    - Syncs with all controllers
    - Provides unified data access
    
    USAGE:
    local ClientDataCache = require(script.Parent.ClientDataCache)
    
    local coins = ClientDataCache.GetCurrency("Coins")
    local inventory = ClientDataCache.GetInventory()
    
    ClientDataCache.UpdateCurrency("Coins", 150)
    ClientDataCache.UpdateInventory({...})
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientDataCache = {}

-- Local player reference
local player = Players.LocalPlayer

-- Cache storage
local cache = {
    Currency = {
        Coins = 50,        -- Starting balance
        DreamSeeds = 0
    },
    
    Inventory = {
        -- Sample starting items
        ["carrot_seed"] = 5,
        ["watering_can"] = 1,
        ["lantern"] = 1
    },
    
    Plots = {
        -- Will be populated by server
        -- Structure: [plotId] = {state, plantedCrop, growthProgress, etc.}
    },
    
    PlayerData = {
        -- Additional player data
        level = 1,
        experience = 0,
        unlockedAreas = {"GardenCore"}
    },
    
    -- Metadata
    lastSyncTime = 0,
    syncInterval = 60, -- Sync with server every 60 seconds
    isDirty = false -- Has local changes that need server sync
}

-- Controllers to notify on data changes
local controllers = {}

-- RemoteFunctions for server sync (optional)
local GetPlayerDataFunc
local SyncPlayerDataFunc

-- Attempt to get RemoteFunctions (they may not exist yet)
task.spawn(function()
    GetPlayerDataFunc = ReplicatedStorage:WaitForChild("GetPlayerData", 30)
    SyncPlayerDataFunc = ReplicatedStorage:WaitForChild("SyncPlayerData", 30)
    
    if GetPlayerDataFunc then
        print("✅ GetPlayerData RemoteFunction connected")
    end
    
    if SyncPlayerDataFunc then
        print("✅ SyncPlayerData RemoteFunction connected")
    end
end)

--[[
    Register a controller for automatic updates
    @param controllerName (string) - Name of the controller
    @param controller (table) - Controller module with update methods
]]
function ClientDataCache.RegisterController(controllerName, controller)
    controllers[controllerName] = controller
    print(string.format("📝 Registered controller: %s", controllerName))
end

--[[
    Get currency value
    @param currencyType (string) - "Coins" or "DreamSeeds"
    @return number - Current balance
]]
function ClientDataCache.GetCurrency(currencyType)
    return cache.Currency[currencyType] or 0
end

--[[
    Get all currency
    @return table - {Coins = X, DreamSeeds = Y}
]]
function ClientDataCache.GetAllCurrency()
    return {
        Coins = cache.Currency.Coins,
        DreamSeeds = cache.Currency.DreamSeeds
    }
end

--[[
    Update currency (local cache only)
    @param currencyType (string) - "Coins" or "DreamSeeds"
    @param newValue (number) - New balance
    @param notifyControllers (boolean) - Whether to notify controllers (default: true)
]]
function ClientDataCache.UpdateCurrency(currencyType, newValue, notifyControllers)
    if type(newValue) ~= "number" then
        warn("⚠️ Invalid currency value:", newValue)
        return
    end
    
    notifyControllers = notifyControllers == nil and true or notifyControllers
    
    local oldValue = cache.Currency[currencyType]
    cache.Currency[currencyType] = math.max(0, newValue)
    cache.isDirty = true
    
    print(string.format("💰 %s updated: %d → %d", currencyType, oldValue, newValue))
    
    -- Notify UIController
    if notifyControllers and controllers.UIController then
        controllers.UIController.UpdateCurrency(
            cache.Currency.Coins,
            cache.Currency.DreamSeeds
        )
    end
end

--[[
    Modify currency by delta
    @param currencyType (string) - "Coins" or "DreamSeeds"
    @param delta (number) - Amount to add/subtract
]]
function ClientDataCache.ModifyCurrency(currencyType, delta)
    local current = ClientDataCache.GetCurrency(currencyType)
    ClientDataCache.UpdateCurrency(currencyType, current + delta)
end

--[[
    Get entire inventory
    @return table - Inventory dictionary {itemName = quantity}
]]
function ClientDataCache.GetInventory()
    return cache.Inventory
end

--[[
    Get specific item quantity
    @param itemName (string) - Item to check
    @return number - Quantity owned
]]
function ClientDataCache.GetItemQuantity(itemName)
    return cache.Inventory[itemName] or 0
end

--[[
    Check if player has item
    @param itemName (string) - Item to check
    @param quantity (number) - Required quantity (default: 1)
    @return boolean - Has enough
]]
function ClientDataCache.HasItem(itemName, quantity)
    quantity = quantity or 1
    return ClientDataCache.GetItemQuantity(itemName) >= quantity
end

--[[
    Update entire inventory
    @param newInventory (table) - New inventory data
    @param notifyControllers (boolean) - Whether to notify controllers (default: true)
]]
function ClientDataCache.UpdateInventory(newInventory, notifyControllers)
    if type(newInventory) ~= "table" then
        warn("⚠️ Invalid inventory data")
        return
    end
    
    notifyControllers = notifyControllers == nil and true or notifyControllers
    
    cache.Inventory = newInventory
    cache.isDirty = true
    
    print("📦 Inventory updated:", ClientDataCache.GetInventoryCount(), "unique items")
    
    -- Notify InventoryController
    if notifyControllers and controllers.InventoryController then
        controllers.InventoryController.UpdateInventory(newInventory)
    end
end

--[[
    Add item to inventory
    @param itemName (string) - Item to add
    @param quantity (number) - Amount to add (default: 1)
]]
function ClientDataCache.AddItem(itemName, quantity)
    quantity = quantity or 1
    
    local current = cache.Inventory[itemName] or 0
    cache.Inventory[itemName] = current + quantity
    cache.isDirty = true
    
    print(string.format("➕ Added %dx %s (total: %d)", quantity, itemName, cache.Inventory[itemName]))
    
    -- Notify InventoryController
    if controllers.InventoryController then
        controllers.InventoryController.AddItem(itemName, quantity)
    end
end

--[[
    Remove item from inventory
    @param itemName (string) - Item to remove
    @param quantity (number) - Amount to remove (default: 1)
    @return boolean - Success status
]]
function ClientDataCache.RemoveItem(itemName, quantity)
    quantity = quantity or 1
    
    local current = cache.Inventory[itemName] or 0
    
    if current < quantity then
        warn(string.format("⚠️ Not enough %s (have %d, need %d)", itemName, current, quantity))
        return false
    end
    
    cache.Inventory[itemName] = current - quantity
    
    if cache.Inventory[itemName] <= 0 then
        cache.Inventory[itemName] = nil
    end
    
    cache.isDirty = true
    
    print(string.format("➖ Removed %dx %s (remaining: %d)", quantity, itemName, cache.Inventory[itemName] or 0))
    
    -- Notify InventoryController
    if controllers.InventoryController then
        controllers.InventoryController.RemoveItem(itemName, quantity)
    end
    
    return true
end

--[[
    Get number of unique items in inventory
    @return number - Count of unique items
]]
function ClientDataCache.GetInventoryCount()
    local count = 0
    for _ in pairs(cache.Inventory) do
        count = count + 1
    end
    return count
end

--[[
    Get total quantity of all items
    @return number - Total item count
]]
function ClientDataCache.GetTotalItemCount()
    local total = 0
    for _, quantity in pairs(cache.Inventory) do
        total = total + quantity
    end
    return total
end

--[[
    Update plot data
    @param plotId (string) - Plot identifier
    @param plotData (table) - Plot state data
]]
function ClientDataCache.UpdatePlot(plotId, plotData)
    cache.Plots[plotId] = plotData
    cache.isDirty = true
    
    print(string.format("🌱 Plot updated: %s", plotId))
end

--[[
    Get plot data
    @param plotId (string) - Plot identifier
    @return table|nil - Plot data or nil
]]
function ClientDataCache.GetPlot(plotId)
    return cache.Plots[plotId]
end

--[[
    Get all plots
    @return table - All plot data
]]
function ClientDataCache.GetAllPlots()
    return cache.Plots
end

--[[
    Update player data field
    @param field (string) - Field name
    @param value (any) - New value
]]
function ClientDataCache.UpdatePlayerData(field, value)
    cache.PlayerData[field] = value
    cache.isDirty = true
    
    print(string.format("👤 Player data updated: %s = %s", field, tostring(value)))
end

--[[
    Get player data field
    @param field (string) - Field name
    @return any - Field value
]]
function ClientDataCache.GetPlayerData(field)
    return cache.PlayerData[field]
end

--[[
    Request full data sync from server
    (Call this when player joins or after long idle)
]]
function ClientDataCache.RequestFullSync()
    if not GetPlayerDataFunc then
        warn("⚠️ GetPlayerData RemoteFunction not available")
        return
    end
    
    print("🔄 Requesting full data sync from server...")
    
    local success, result = pcall(function()
        return GetPlayerDataFunc:InvokeServer()
    end)
    
    if success and result then
        if result.Currency then
            cache.Currency = result.Currency
            
            if controllers.UIController then
                controllers.UIController.UpdateCurrency(
                    cache.Currency.Coins,
                    cache.Currency.DreamSeeds,
                    false -- No animation on sync
                )
            end
        end
        
        if result.Inventory then
            cache.Inventory = result.Inventory
            
            if controllers.InventoryController then
                controllers.InventoryController.UpdateInventory(result.Inventory)
            end
        end
        
        if result.Plots then
            cache.Plots = result.Plots
        end
        
        if result.PlayerData then
            for key, value in pairs(result.PlayerData) do
                cache.PlayerData[key] = value
            end
        end
        
        cache.lastSyncTime = tick()
        cache.isDirty = false
        
        print("✅ Full sync completed successfully")
    else
        warn("⚠️ Failed to sync data:", result)
    end
end

--[[
    Push local changes to server
    (Call this periodically or before important actions)
]]
function ClientDataCache.PushToServer()
    if not cache.isDirty then
        print("💾 No local changes to push")
        return
    end
    
    if not SyncPlayerDataFunc then
        warn("⚠️ SyncPlayerData RemoteFunction not available")
        return
    end
    
    print("📤 Pushing local changes to server...")
    
    local success, result = pcall(function()
        return SyncPlayerDataFunc:InvokeServer({
            Currency = cache.Currency,
            Inventory = cache.Inventory,
            PlayerData = cache.PlayerData
        })
    end)
    
    if success and result and result.Success then
        cache.isDirty = false
        cache.lastSyncTime = tick()
        print("✅ Data synced to server")
    else
        warn("⚠️ Failed to push data to server:", result)
    end
end

--[[
    Clear all cached data (use with caution)
]]
function ClientDataCache.ClearCache()
    print("🗑️ Clearing client cache...")
    
    cache.Currency = {Coins = 0, DreamSeeds = 0}
    cache.Inventory = {}
    cache.Plots = {}
    cache.PlayerData = {level = 1, experience = 0, unlockedAreas = {}}
    cache.isDirty = false
    
    print("✅ Cache cleared")
end

--[[
    Get cache statistics
    @return table - Cache stats
]]
function ClientDataCache.GetStats()
    return {
        coins = cache.Currency.Coins,
        dreamSeeds = cache.Currency.DreamSeeds,
        uniqueItems = ClientDataCache.GetInventoryCount(),
        totalItems = ClientDataCache.GetTotalItemCount(),
        plots = #cache.Plots,
        lastSync = cache.lastSyncTime,
        isDirty = cache.isDirty
    }
end

--[[
    Print cache debug info
]]
function ClientDataCache.DebugPrint()
    print("========================================")
    print("📊 ClientDataCache Debug Info")
    print("========================================")
    print("Currency:")
    print(string.format("  💰 Coins: %d", cache.Currency.Coins))
    print(string.format("  🌙 Dream Seeds: %d", cache.Currency.DreamSeeds))
    print("")
    print("Inventory:")
    print(string.format("  Unique items: %d", ClientDataCache.GetInventoryCount()))
    print(string.format("  Total items: %d", ClientDataCache.GetTotalItemCount()))
    for itemName, quantity in pairs(cache.Inventory) do
        print(string.format("    - %s: %d", itemName, quantity))
    end
    print("")
    print("Player Data:")
    for key, value in pairs(cache.PlayerData) do
        print(string.format("  %s: %s", key, tostring(value)))
    end
    print("")
    print("Cache Status:")
    print(string.format("  Last sync: %.1fs ago", tick() - cache.lastSyncTime))
    print(string.format("  Has changes: %s", cache.isDirty and "Yes" or "No"))
    print("========================================")
end

--[[
    Initialize cache system
]]
function ClientDataCache.Initialize()
    print("========================================")
    print("💾 Initializing ClientDataCache...")
    print("========================================")
    
    -- Auto-register controllers if they exist
    task.spawn(function()
        task.wait(2) -- Wait for controllers to load
        
        local playerScripts = player:WaitForChild("PlayerScripts")
        local controllersFolder = playerScripts:FindFirstChild("Controllers")
        
        if controllersFolder then
            local uiController = controllersFolder:FindFirstChild("UIController")
            if uiController then
                ClientDataCache.RegisterController("UIController", require(uiController))
            end
            
            local inventoryController = controllersFolder:FindFirstChild("InventoryController")
            if inventoryController then
                ClientDataCache.RegisterController("InventoryController", require(inventoryController))
            end
        end
    end)
    
    -- Initial sync attempt
    task.spawn(function()
        task.wait(3) -- Wait for server to be ready
        ClientDataCache.RequestFullSync()
    end)
    
    -- Periodic sync loop
    task.spawn(function()
        while true do
            task.wait(cache.syncInterval)
            
            if cache.isDirty then
                ClientDataCache.PushToServer()
            end
        end
    end)
    
    print("✅ Starting data:")
    print(string.format("   💰 Coins: %d", cache.Currency.Coins))
    print(string.format("   🌙 Dreams: %d", cache.Currency.DreamSeeds))
    print(string.format("   📦 Items: %d unique", ClientDataCache.GetInventoryCount()))
    print("========================================")
    print("✨ ClientDataCache ready!")
    print("========================================")
end

-- Auto-initialize
ClientDataCache.Initialize()

return ClientDataCache
