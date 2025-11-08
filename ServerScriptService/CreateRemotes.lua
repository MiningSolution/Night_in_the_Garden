local RS=game:GetService("ReplicatedStorage")
local function RE(n)local r=RS:FindFirstChild(n)if not r then r=Instance.new("RemoteEvent")r.Name=n r.Parent=RS end return r end
local function RF(n)local r=RS:FindFirstChild(n)if not r then r=Instance.new("RemoteFunction")r.Name=n r.Parent=RS end return r end
RE("InteractWithPlot"); RE("OnToolUse")
RF("GetShopData"); RF("BuyItem"); RF("SellItem"); RF("GetPlayerData"); RF("SyncPlayerData")
RE("UpdateCurrency"); RE("UpdateInventory"); RE("PlotStateChanged"); RE("DayNightUpdate"); RE("PlotStateUpdated")
print("✅ Remotes ensured")