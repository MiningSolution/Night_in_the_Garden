
local RS=game:GetService("ReplicatedStorage"); local SSS=game:GetService("ServerScriptService")
local ShopManager=require(SSS:WaitForChild("ShopManager")); local PlotManager=require(SSS:WaitForChild("PlotManager")); local PlayerData=require(SSS:WaitForChild("PlayerDataManager"))
local GetShopData=RS:WaitForChild("GetShopData"); local BuyItem=RS:WaitForChild("BuyItem"); local SellItem=RS:WaitForChild("SellItem")
local GetPlayerData=RS:WaitForChild("GetPlayerData"); local SyncPlayerData=RS:WaitForChild("SyncPlayerData"); local InteractWithPlot=RS:WaitForChild("InteractWithPlot")
GetShopData.OnServerInvoke=function(p) return ShopManager.HandleGetShopData(p) end
BuyItem.OnServerInvoke=function(p,c,i,q) return ShopManager.HandleBuyItem(p,c,i,q) end
SellItem.OnServerInvoke=function(p,i,q) return ShopManager.HandleSellItem(p,i,q) end
GetPlayerData.OnServerInvoke=function(p) local s=PlayerData.Snapshot(p) if not s then return {Success=false,Error="No data"} end return {Success=true,Currency=s.Currency,Inventory=s.Inventory,Plots=s.Plots,Stats=s.Stats} end
SyncPlayerData.OnServerInvoke=function(p,pl) if type(pl)=="table" and type(pl.Inventory)=="table" then local r=PlayerData.Get(p) for k,v in pairs(pl.Inventory) do local q=tonumber(v) if q and q>=0 then if q==0 then r.Inventory[k]=nil else r.Inventory[k]=math.floor(q) end end end end local s=PlayerData.Snapshot(p) return {Success=true,Snapshot=s} end
InteractWithPlot.OnServerEvent:Connect(function(p,plotModel,toolName) PlotManager.HandleInteraction(p,plotModel,toolName) end)
