-- CreateRemotes.lua
local RS = game:GetService("ReplicatedStorage")

local function ensureEvent(name, className)
    local obj = RS:FindFirstChild(name)
    if not obj then
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = RS
    end
    return obj
end

ensureEvent("InteractWithPlot", "RemoteEvent")
ensureEvent("OnToolUse", "RemoteEvent")

ensureEvent("GetShopData", "RemoteFunction")
ensureEvent("BuyItem", "RemoteFunction")
ensureEvent("SellItem", "RemoteFunction")
ensureEvent("GetPlayerData", "RemoteFunction")

ensureEvent("UpdateCurrency", "RemoteEvent")
ensureEvent("UpdateInventory", "RemoteEvent")
ensureEvent("PlotStateChanged", "RemoteEvent")
ensureEvent("PlotStateUpdated", "RemoteEvent")
ensureEvent("DayNightUpdate", "RemoteEvent")

print("[Remotes] Ready")
