local RS = game:GetService("ReplicatedStorage")
local function ensure(className, name)
    local obj = RS:FindFirstChild(name)
    if not obj then
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = RS
    end
    return obj
end
ensure("RemoteEvent","InteractWithPlot")
ensure("RemoteEvent","OnToolUse")
ensure("RemoteEvent","UpdateCurrency")
ensure("RemoteEvent","UpdateInventory")
ensure("RemoteEvent","PlotStateChanged")
ensure("RemoteEvent","PlotStateUpdated")
ensure("RemoteEvent","DayNightUpdate")
ensure("RemoteFunction","GetShopData")
ensure("RemoteFunction","BuyItem")
ensure("RemoteFunction","SellItem")
ensure("RemoteFunction","GetPlayerData")
print("✅ Remotes ensured")
