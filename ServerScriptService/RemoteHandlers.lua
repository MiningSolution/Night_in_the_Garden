-- RemoteHandlers.lua
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local PlotManager = require(script.Parent:WaitForChild("PlotManager"))

-- Remotes
local InteractWithPlot = RS:WaitForChild("InteractWithPlot")
local GetShopData = RS:WaitForChild("GetShopData")
local BuyItem = RS:WaitForChild("BuyItem")
local SellItem = RS:WaitForChild("SellItem")
local GetPlayerData = RS:WaitForChild("GetPlayerData")

-- Simple per-player rate limit (RFs)
local _rl = {}
local RATE_LIMIT = 5 -- req/s per method
local function rate_ok(player, key)
    local t = os.clock()
    _rl[player] = _rl[player] or {}
    local r = _rl[player][key] or {t=t, n=0}
    if t - r.t >= 1 then r.t, r.n = t, 0 end
    r.n = r.n + 1
    _rl[player][key] = r
    return r.n <= RATE_LIMIT
end

local function ok(payload) payload = payload or {}; payload.Success=true; return payload end
local function fail(msg) return {Success=false, Error=tostring(msg or "Unknown")} end

local function buyPrice(cat, itemId)
    local c = ShopConfig.buy[cat]; if not c then return 0 end
    local row = c[itemId]; if not row then return 0 end
    return tonumber(row.price) or 0
end
local function sellPrice(itemId)
    local row = ShopConfig.sell[itemId]
    return row and (tonumber(row.price) or 0) or 0
end

GetPlayerData.OnServerInvoke = function(player)
    if not rate_ok(player,"GetPlayerData") then return fail("You're doing that too fast. Please wait a moment.") end
    local d = PlayerData.Get(player); if not d then return fail("Data not loaded") end
    return ok({ Currency=d.Currency, Inventory=d.Inventory, Plots=d.Plots, Stats=d.Stats })
end

GetShopData.OnServerInvoke = function(player)
    if not rate_ok(player,"GetShopData") then return fail("You're doing that too fast. Please wait a moment.") end
    local d = PlayerData.Get(player); if not d then return fail("Data not loaded") end
    return ok({ Config=ShopConfig, PlayerCoins=d.Currency.Coins })
end

BuyItem.OnServerInvoke = function(player, category, itemId, quantity)
    if not rate_ok(player,"BuyItem") then return fail("You're doing that too fast. Please wait a moment.") end
    if type(category)~="string" or type(itemId)~="string" then return fail("Bad args") end
    quantity = math.max(1, math.min(999, math.floor(tonumber(quantity) or 1)))

    local price = buyPrice(category, itemId)
    if price <= 0 then return fail("Item not purchasable") end

    local oksp, newBal = PlayerData.TrySpendCoins(player, price*quantity)
    if not oksp then return fail("Not enough coins") end

    PlayerData.AddItem(player, itemId, quantity)
    local snap = PlayerData.Snapshot(player)
    return ok({ ItemName=itemId, Quantity=quantity, NewBalance=snap.Currency.Coins, NewInventory=snap.Inventory })
end

SellItem.OnServerInvoke = function(player, itemId, quantity)
    if not rate_ok(player,"SellItem") then return fail("You're doing that too fast. Please wait a moment.") end
    if type(itemId)~="string" then return fail("Bad args") end
    quantity = math.max(1, math.min(999, math.floor(tonumber(quantity) or 1)))

    if not PlayerData.HasItem(player, itemId, quantity) then return fail("Not enough items") end
    local price = sellPrice(itemId)
    if price <= 0 then return fail("Item cannot be sold") end

    if not PlayerData.TryConsumeItem(player, itemId, quantity) then return fail("Failed to remove") end
    PlayerData.AddCoins(player, price*quantity)

    local snap = PlayerData.Snapshot(player)
    return ok({ ItemName=itemId, Quantity=quantity, TotalEarned=price*quantity, NewBalance=snap.Currency.Coins, NewInventory=snap.Inventory })
end

InteractWithPlot.OnServerEvent:Connect(function(player, plotModel, toolName)
    local res = PlotManager.HandleInteraction(player, plotModel, toolName)
    -- This is an event; we don't return a value. Client listens to PlotState* updates.
    if not res.Success then
        warn(string.format("[PLOT] %s: %s", player.Name, tostring(res.Error)))
    end
end)

print("[RemoteHandlers] Bound")
