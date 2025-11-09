-- StarterPlayer/StarterPlayerScripts/EventHandlers.lua
-- Client-side event handlers for server updates
-- VERSION: 1.1 (Added SpiritCollected handler with visual feedback)

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ClientDataCache = require(script.Parent:WaitForChild("ClientDataCache"))
local PlotVisualizer = require(script.Parent:WaitForChild("PlotVisualizer"))

-- Get RemoteEvents
local DayNightUpdate = RS:WaitForChild("DayNightUpdate")
local UpdateCurrency = RS:WaitForChild("UpdateCurrency", 1)
local UpdateInventory = RS:WaitForChild("UpdateInventory", 1)
local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")
local SpiritCollected = RS:WaitForChild("SpiritCollected", 5) -- NEW: Spirit feedback

-- ========================================
-- DAY/NIGHT CYCLE UPDATES
-- ========================================
DayNightUpdate.OnClientEvent:Connect(function(phase, progress)
    if ClientDataCache.UpdateDayNight then
        ClientDataCache.UpdateDayNight(phase, progress)
    end
end)

-- ========================================
-- CURRENCY UPDATES
-- ========================================
if UpdateCurrency then
    UpdateCurrency.OnClientEvent:Connect(function(currencyType, newValue)
        print(string.format("💰 Currency update: %s = %d", currencyType, newValue))
        
        if ClientDataCache.UpdateCurrency then
            ClientDataCache.UpdateCurrency(currencyType, newValue)
        end
    end)
end

-- ========================================
-- INVENTORY UPDATES
-- ========================================
if UpdateInventory then
    UpdateInventory.OnClientEvent:Connect(function(newInventory)
        print("📦 Inventory updated")
        
        if ClientDataCache.UpdateInventory then
            ClientDataCache.UpdateInventory(newInventory)
        end
    end)
end

-- ========================================
-- PLOT STATE CHANGES (Real-time updates)
-- ========================================
PlotStateChanged.OnClientEvent:Connect(function(plotId, plotData)
    if type(plotId) ~= "string" or type(plotData) ~= "table" then 
        warn("⚠️ Invalid PlotStateChanged data received")
        return 
    end
    
    -- Update cache
    if ClientDataCache.UpdatePlot then
        ClientDataCache.UpdatePlot(plotId, plotData)
    end
    
    -- Update visuals
    if PlotVisualizer.UpdatePlot then
        PlotVisualizer.UpdatePlot(plotId, plotData)
    end
end)

-- ========================================
-- PLOT STATE SNAPSHOTS (After actions)
-- ========================================
PlotStateUpdated.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then 
        warn("⚠️ Invalid PlotStateUpdated payload")
        return 
    end
    
    local snap = payload.Snapshot
    if snap then
        -- Apply full snapshot to cache
        if ClientDataCache.ApplySnapshot then
            ClientDataCache.ApplySnapshot(snap)
        elseif ClientDataCache.SetAll then
            ClientDataCache.SetAll(snap)
        end
        
        -- Update all plot visuals from snapshot
        if snap.Plots then
            for pid, pdata in pairs(snap.Plots) do
                if PlotVisualizer.UpdatePlot then 
                    PlotVisualizer.UpdatePlot(pid, pdata) 
                end
            end
        end
    end
end)

-- ========================================
-- SPIRIT COLLECTION FEEDBACK (NEW)
-- ========================================
if SpiritCollected then
    SpiritCollected.OnClientEvent:Connect(function(spiritName, spiritRarity, amount)
        print(string.format("👻 Collected %s (%s) for +%d Dream Seeds!", spiritName, spiritRarity, amount))
        
        -- Try to get UIController for visual feedback
        local success, UIController = pcall(function()
            return require(script.Parent.Controllers.UIController)
        end)
        
        if success and UIController and UIController.ShowNotification then
            -- Determine icon based on rarity
            local rarityIcons = {
                Common = "👻",
                Rare = "✨",
                Epic = "🌟"
            }
            local icon = rarityIcons[spiritRarity] or "👻"
            
            -- Show notification with spirit info
            UIController.ShowNotification(
                string.format("%s +%d 🌙 from %s!", icon, amount, spiritName),
                "spirit",
                2.5
            )
        else
            -- Fallback: Just print if UIController not available
            warn("⚠️ UIController not available for spirit notification")
        end
    end)
    
    print("✅ Spirit collection feedback handler registered")
else
    warn("⚠️ SpiritCollected RemoteEvent not found - spirit feedback disabled")
end

-- ========================================
-- INITIALIZATION LOG
-- ========================================
print("========================================")
print("✅ EventHandlers loaded successfully!")
print("========================================")
print("📡 Registered handlers:")
print("   ✓ DayNightUpdate")
print("   ✓ UpdateCurrency")
print("   ✓ UpdateInventory")
print("   ✓ PlotStateChanged")
print("   ✓ PlotStateUpdated")
print("   ✓ SpiritCollected (NEW)")
print("========================================")