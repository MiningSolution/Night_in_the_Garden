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
ensureEvent("GetPlayerData", "RemoteFunction")

-- Spirit system
ensureEvent("CollectSpirit", "RemoteFunction")

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
