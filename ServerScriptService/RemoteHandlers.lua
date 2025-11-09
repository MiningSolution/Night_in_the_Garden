local RS = game:GetService('ReplicatedStorage')
local PlayerData = require(script.Parent:WaitForChild('PlayerDataManager'))
local PlotManager = require(script.Parent:WaitForChild('PlotManager'))
local ShopConfig = require(RS:WaitForChild('ShopConfig'))

local GetPlayerData = RS:WaitForChild('GetPlayerData')
local BuyItem = RS:WaitForChild('BuyItem')
local SellItem = RS:WaitForChild('SellItem')
local GetShopData = RS:WaitForChild('GetShopData')
local InteractWithPlot = RS:WaitForChild('InteractWithPlot')

GetPlayerData.OnServerInvoke = function(player) return PlayerData.Snapshot(player) end
GetShopData.OnServerInvoke = function(player)
    local snap = PlayerData.Snapshot(player)
    return {Success=true, Config=ShopConfig, PlayerCoins = snap and snap.Currency and snap.Currency.Coins or 0}
end

BuyItem.OnServerInvoke = function(player, category, itemId, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local cfg = ShopConfig.buy and ShopConfig.buy[category]
    if not cfg or not cfg[itemId] then return {Success=false, Error='Not purchasable'} end
    local price = cfg[itemId].price or 0
    local oksp,newbal = PlayerData.TrySpendCoins(player, price*quantity)
    if not oksp then return {Success=false, Error='Not enough coins'} end
    local gives = cfg[itemId].gives or itemId
    PlayerData.AddItem(player, gives, quantity)
    local snap = PlayerData.Snapshot(player)
    return {Success=true, ItemName=itemId, Quantity=quantity, NewBalance=snap.Currency.Coins, NewInventory=snap.Inventory}
end

SellItem.OnServerInvoke = function(player, itemId, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local price = (ShopConfig.sell and ShopConfig.sell[itemId] and ShopConfig.sell[itemId].price) or 0
    if price <= 0 then return {Success=false, Error='Cannot sell'} end
    if not PlayerData.HasItem(player, itemId, quantity) then return {Success=false, Error='Not enough items'} end
    if not PlayerData.TryConsumeItem(player, itemId, quantity) then return {Success=false, Error='Remove failed'} end
    PlayerData.AddCoins(player, price*quantity)
    local snap = PlayerData.Snapshot(player)
    return {Success=true, ItemName=itemId, Quantity=quantity, TotalEarned=price*quantity, NewBalance=snap.Currency.Coins, NewInventory=snap.Inventory}
end

InteractWithPlot.OnServerEvent:Connect(function(player, plotModel, toolName)
    PlotManager.HandleInteraction(player, plotModel, toolName)
end)

print('✅ RemoteHandlers wired')
