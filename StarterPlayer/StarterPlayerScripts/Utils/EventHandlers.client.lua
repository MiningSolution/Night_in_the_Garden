-- StarterPlayer/StarterPlayerScripts/Utils/EventHandlers.lua
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
    -- P0-5: Error handling wrapper
    local success, err = pcall(function()
        if ClientDataCache.UpdateDayNight then
            ClientDataCache.UpdateDayNight(phase, progress)
        end
    end)
    
    if not success then
        warn("❌ DayNightUpdate handler error:", err)
    end
end)

-- ========================================
-- CURRENCY UPDATES
-- ========================================
if UpdateCurrency then
    UpdateCurrency.OnClientEvent:Connect(function(currencyType, newValue)
        -- P0-5: Error handling wrapper
        local success, err = pcall(function()
            print(string.format("💰 Currency update: %s = %d", currencyType, newValue))
            
            if ClientDataCache.UpdateCurrency then
                ClientDataCache.UpdateCurrency(currencyType, newValue)
            end
        end)
        
        if not success then
            warn("❌ UpdateCurrency handler error:", err)
        end
    end)
end

-- ========================================
-- INVENTORY UPDATES
-- ========================================
if UpdateInventory then
    UpdateInventory.OnClientEvent:Connect(function(newInventory)
        -- P0-5: Error handling wrapper
        local success, err = pcall(function()
            print("📦 Inventory updated")
            
            if ClientDataCache.UpdateInventory then
                ClientDataCache.UpdateInventory(newInventory)
            end
        end)
        
        if not success then
            warn("❌ UpdateInventory handler error:", err)
        end
    end)
end

-- ========================================
-- PLOT STATE CHANGES (Real-time updates)
-- ========================================
PlotStateChanged.OnClientEvent:Connect(function(plotId, plotData)
    -- P0-5: Error handling wrapper
    local success, err = pcall(function()
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

        -- US4 (FR-011): toast when a crop becomes ready to harvest. This state
        -- fires once per plot (the growth service stops touching a ready plot).
        if plotData.State == "ReadyToHarvest" then
            local ok, UIController = pcall(function()
                return require(script.Parent.Parent.Controllers.UIController)
            end)
            if ok and UIController and UIController.ShowNotification then
                local name = tostring(plotData.PlantId or "A crop")
                name = name:sub(1, 1):upper() .. name:sub(2)
                UIController.ShowNotification(name .. " is ready to harvest!", "info")
            end
        end
    end)
    
    if not success then
        warn("❌ PlotStateChanged handler error:", err)
        -- Could show notification to user
    end
end)

-- ========================================
-- PLOT STATE SNAPSHOTS (After actions)
-- ========================================
PlotStateUpdated.OnClientEvent:Connect(function(payload)
    -- P0-5: Error handling wrapper
    local success, err = pcall(function()
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
    
    if not success then
        warn("❌ PlotStateUpdated handler error:", err)
    end
end)

-- ========================================
-- SPIRIT COLLECTION FEEDBACK (NEW)
-- ========================================
if SpiritCollected then
    SpiritCollected.OnClientEvent:Connect(function(spiritName, spiritRarity, amount, outcome)
        -- feature 006 (US2): `outcome` distinguishes a successful catch from a missed net
        -- roll or a no-net attempt (amount can be 0 on a successful repeat catch).
        outcome = outcome or "caught"
        -- P0-5: Error handling wrapper
        local success, err = pcall(function()
            local uiSuccess, UIController = pcall(function()
                return require(script.Parent.Parent.Controllers.UIController)
            end)
            if not (uiSuccess and UIController and UIController.ShowNotification) then
                warn("⚠️ UIController not available for spirit notification")
                return
            end

            if outcome == "missed" then
                UIController.ShowNotification(string.format("💨 %s slipped away!", spiritName), "info", 2)
                return
            elseif outcome == "needs_net" then
                UIController.ShowNotification(string.format("🥅 You need a Net to catch the %s", spiritName), "info", 2.5)
                return
            end

            -- Caught (proximity wisp or netted creature).
            local rarityIcons = { Common = "👻", Uncommon = "🦋", Rare = "✨", Epic = "🌟", Legendary = "🌈" }
            local icon = rarityIcons[spiritRarity] or "👻"
            local msg
            if (tonumber(amount) or 0) > 0 then
                msg = string.format("%s +%d 🌙 from %s!", icon, amount, spiritName)
            else
                msg = string.format("%s Caught a %s!", icon, spiritName)
            end
            UIController.ShowNotification(msg, "spirit", 2.5)
        end)
        
        if not success then
            warn("❌ SpiritCollected handler error:", err)
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
