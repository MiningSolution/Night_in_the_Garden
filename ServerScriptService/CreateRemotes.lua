-- ServerScriptService/CreateRemotes.lua
-- Creates all RemoteEvents and RemoteFunctions
-- VERSION: 1.1 (Added SpiritCollected for client feedback)

local RS = game:GetService("ReplicatedStorage")

local function ensureEvent(name, className)
    local obj = RS:FindFirstChild(name)
    if not obj then
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = RS
        print(string.format("✅ Created %s (%s)", name, className))
    else
        print(string.format("ℹ️  %s already exists", name))
    end
    return obj
end

-- Plot interaction
ensureEvent("InteractWithPlot", "RemoteEvent")
ensureEvent("OnToolUse", "RemoteEvent")
ensureEvent("EquipTool", "RemoteEvent") -- NEW: Sync equipped tool to server

-- Shop system
ensureEvent("GetShopData", "RemoteFunction")
ensureEvent("BuyItem", "RemoteFunction")
ensureEvent("SellItem", "RemoteFunction")
ensureEvent("SellAll", "RemoteFunction")          -- feature 002: sell all non-favourite crops
ensureEvent("ToggleFavourite", "RemoteFunction")  -- feature 002: protect a crop from Sell all
ensureEvent("RequestTeleport", "RemoteFunction")  -- feature 002: quick travel (shop/garden/stall)
ensureEvent("GetPlayerData", "RemoteFunction")

-- Spirit system
ensureEvent("CollectSpirit", "RemoteFunction")

-- Retention system (feature 003)
ensureEvent("GetDailyReward", "RemoteFunction")   -- read streak state + reward table
ensureEvent("ClaimDailyReward", "RemoteFunction")  -- claim today's reward (server-decided)
ensureEvent("GetQuests", "RemoteFunction")        -- read today's quests + progress
ensureEvent("ClaimQuest", "RemoteFunction")       -- claim a completed quest's reward
ensureEvent("QuestUpdated", "RemoteEvent")        -- server → client progress/claim push

-- Data updates (server → client)
ensureEvent("UpdateCurrency", "RemoteEvent")
ensureEvent("UpdateInventory", "RemoteEvent")
ensureEvent("PlotStateChanged", "RemoteEvent")
ensureEvent("PlotStateUpdated", "RemoteEvent")
ensureEvent("DayNightUpdate", "RemoteEvent")

-- NEW: Spirit system feedback (server → client)
ensureEvent("SpiritCollected", "RemoteEvent")

print("========================================")
print("✅ All RemoteEvents/Functions ready!")
print("========================================")
print("📡 Events:")
print("   - InteractWithPlot, OnToolUse")
print("   - UpdateCurrency, UpdateInventory")
print("   - PlotStateChanged, PlotStateUpdated")
print("   - DayNightUpdate")
print("   - SpiritCollected (NEW)")
print("")
print("📞 Functions:")
print("   - GetShopData, BuyItem, SellItem")
print("   - GetPlayerData")
print("========================================")

-- Required by Init.lua as a ModuleScript: must return exactly one value
return true
