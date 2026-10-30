-- RemoteHandlers.lua
local RS = game:GetService("ReplicatedStorage")
local Services = script.Parent:WaitForChild("Services")
local PlayerData = require(Services:WaitForChild("PlayerDataManager"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local AntiCheat = require(Services:WaitForChild("AntiCheatLogger"))
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local PlotManager = require(Services:WaitForChild("PlotManager"))
local SpiritFolder = Services:WaitForChild("Spirit")
local SpiritManager = require(SpiritFolder:WaitForChild("SpiritManager"))
local SpiritSpawner = require(SpiritFolder:WaitForChild("SpiritSpawner"))
local SpiritCollector = require(SpiritFolder:WaitForChild("SpiritCollector"))
local DailyRewardService = require(Services:WaitForChild("DailyRewardService"))
local QuestService = require(Services:WaitForChild("QuestService"))
local ShopStockService = require(Services:WaitForChild("ShopStockService"))

-- Remotes
local InteractWithPlot = RS:WaitForChild("InteractWithPlot")
local EquipTool = RS:WaitForChild("EquipTool")
local GetShopData = RS:WaitForChild("GetShopData")
local BuyItem = RS:WaitForChild("BuyItem")
local SellItem = RS:WaitForChild("SellItem")
local SellAll = RS:WaitForChild("SellAll")
local ToggleFavourite = RS:WaitForChild("ToggleFavourite")
local RequestTeleport = RS:WaitForChild("RequestTeleport")
local GetPlayerData = RS:WaitForChild("GetPlayerData")
local CollectSpirit = RS:WaitForChild("CollectSpirit")
local SetTutorialDone = RS:WaitForChild("SetTutorialDone")
local GetDailyReward = RS:WaitForChild("GetDailyReward")
local ClaimDailyReward = RS:WaitForChild("ClaimDailyReward")
local GetQuests = RS:WaitForChild("GetQuests")
local ClaimQuest = RS:WaitForChild("ClaimQuest")
local UpdateCurrency = RS:WaitForChild("UpdateCurrency")

-- Simple per-player rate limit (RFs)
local _rl = {}
local RATE_LIMIT = 5 -- req/s per method
local function rate_ok(player, key)
    local t = tick() -- Use tick() for real-time tracking, not os.clock()
    _rl[player] = _rl[player] or {}
    local r = _rl[player][key] or {t=t, n=0}
    if t - r.t >= 1 then r.t, r.n = t, 0 end
    r.n = r.n + 1
    _rl[player][key] = r
    return r.n <= RATE_LIMIT
end

-- Cleanup rate limit data when player leaves
local Players = game:GetService("Players")
Players.PlayerRemoving:Connect(function(player)
    if _rl[player] then
        _rl[player] = nil
    end
end)

local function ok(payload) payload = payload or {}; payload.Success=true; return payload end
local function fail(msg) return {Success=false, Error=tostring(msg or "Unknown")} end

-- Strict quantity validation (P0-2: Security fix)
-- P2-4: Use constant from Constants
local Constants = require(RS:WaitForChild("Constants"))
local function validateQuantity(qty, maxQty)
    maxQty = maxQty or Constants.SHOP.MAX_PURCHASE_QUANTITY
    
    -- First check type
    if type(qty) ~= "number" and type(qty) ~= "string" then
        return nil, "Invalid quantity type"
    end
    
    -- Convert to number
    qty = tonumber(qty)
    if not qty then
        return nil, "Quantity must be a number"
    end
    
    -- Check for NaN or Infinity
    if qty ~= qty or qty == math.huge or qty == -math.huge then
        return nil, "Invalid quantity value"
    end
    
    -- Check positive
    if qty < 1 then
        return nil, "Quantity must be positive"
    end
    
    -- Check max limit
    if qty > maxQty then
        return nil, string.format("Quantity too large (max: %d)", maxQty)
    end
    
    -- Check integer
    if qty ~= math.floor(qty) then
        return nil, "Quantity must be an integer"
    end
    
    return math.floor(qty), nil
end

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
    -- P0-5: Error handling wrapper
    local success, result = pcall(function()
        if not rate_ok(player,"GetPlayerData") then 
            return fail("You're doing that too fast. Please wait a moment.") 
        end
        local d = PlayerData.Get(player)
        if not d then 
            return fail("Data not loaded") 
        end
        return ok({ Currency=d.Currency, Inventory=d.Inventory, Plots=d.Plots, Stats=d.Stats, Favourites=(d.Favourites or {}), Onboarding=(d.Onboarding or {Done=false, Step=0}) })
    end)
    
    if not success then
        warn("[RemoteHandlers] GetPlayerData error for", player.Name, ":", result)
        -- Log to analytics/monitoring if available
        return fail("Internal server error")
    end
    
    return result
end

GetShopData.OnServerInvoke = function(player)
    -- P0-5: Error handling wrapper
    local success, result = pcall(function()
        if not rate_ok(player,"GetShopData") then 
            return fail("You're doing that too fast. Please wait a moment.") 
        end
        local d = PlayerData.Get(player)
        if not d then 
            return fail("Data not loaded") 
        end
        -- Send data only: ShopConfig also holds helper functions, which do not belong on the wire.
        -- Feature 003 (US3): include per-item remaining stock + the shared restock schedule.
        return ok({
            Config={ buy=ShopConfig.buy, sell=ShopConfig.sell },
            PlayerCoins=d.Currency.Coins,
            Stock=ShopStockService.GetStock(),
            RestockAt=ShopStockService.RestockAt(),
            Interval=ShopStockService.Interval(),
        })
    end)
    
    if not success then
        warn("[RemoteHandlers] GetShopData error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    
    return result
end

BuyItem.OnServerInvoke = function(player, category, itemId, quantity)
    -- P0-5: Error handling wrapper
    local success, result = pcall(function()
        if not rate_ok(player,"BuyItem") then 
            return fail("You're doing that too fast. Please wait a moment.") 
        end
        if type(category)~="string" or type(itemId)~="string" then 
            return fail("Bad args") 
        end
        
        -- P0-2: Strict quantity validation BEFORE any operations
        local validQty, err = validateQuantity(quantity, Constants.SHOP.MAX_SALE_QUANTITY)
        if not validQty then
            -- P1-5: Log suspicious quantity
            AntiCheat.log(player, AntiCheat.LOG_LEVELS.SUSPICIOUS, "INVALID_QUANTITY_BUY", {
                category = category,
                item = itemId,
                quantity = quantity,
                error = err
            })
            warn(string.format("[BuyItem] Invalid quantity from %s: %s (value: %s)", player.Name, err, tostring(quantity)))
            return fail(err)
        end
        quantity = validQty

        -- P1-5: Log large purchases
        if quantity > Constants.ANTICHEAT.LARGE_PURCHASE_THRESHOLD then
            AntiCheat.log(player, AntiCheat.LOG_LEVELS.INFO, "LARGE_PURCHASE", {
                category = category,
                item = itemId,
                quantity = quantity
            })
        end

        local price = buyPrice(category, itemId)
        if price <= 0 then
            return fail("Item not purchasable")
        end

        -- Feature 003 (US3): reserve limited stock before spending; fail closed when
        -- out of stock (no coins spent, no item granted). Unlimited items always pass.
        if not ShopStockService.TryReserve(itemId, quantity) then
            return fail("Out of stock")
        end

        local oksp, newBal = PlayerData.TrySpendCoins(player, price*quantity)
        if not oksp then
            ShopStockService.Release(itemId, quantity) -- unwind the reservation
            return fail("Not enough coins")
        end

        PlayerData.AddItem(player, itemId, quantity)
        local snap = PlayerData.Snapshot(player)
        return ok({ ItemName=itemId, Quantity=quantity, NewBalance=snap.Currency.Coins, NewInventory=snap.Inventory, Stock=ShopStockService.Remaining(itemId) })
    end)
    
    if not success then
        warn("[RemoteHandlers] BuyItem error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    
    return result
end

SellItem.OnServerInvoke = function(player, itemId, quantity)
    -- P0-5: Error handling wrapper
    local success, result = pcall(function()
        if not rate_ok(player,"SellItem") then 
            return fail("You're doing that too fast. Please wait a moment.") 
        end
        if type(itemId)~="string" then 
            return fail("Bad args") 
        end
        
        -- P0-2: Strict quantity validation BEFORE any operations
        local validQty, err = validateQuantity(quantity, Constants.SHOP.MAX_SALE_QUANTITY)
        if not validQty then
            warn(string.format("[SellItem] Invalid quantity from %s: %s (value: %s)", player.Name, err, tostring(quantity)))
            return fail(err)
        end
        quantity = validQty

        -- FR-001: only harvested crops are sellable (crops are the only items in
        -- the sell table). Seeds/tools are rejected.
        if not ShopConfig.CanSell(itemId) then
            return fail("Item cannot be sold")
        end
        if not PlayerData.HasItem(player, itemId, quantity) then
            return fail("Not enough items")
        end
        local price = sellPrice(itemId)
        if price <= 0 then
            return fail("Item cannot be sold")
        end

        if not PlayerData.TryConsumeItem(player, itemId, quantity) then
            return fail("Failed to remove")
        end
        PlayerData.AddCoins(player, price*quantity)
        QuestService.Track(player, "sell", quantity) -- feature 003 (US2)

        local snap = PlayerData.Snapshot(player)
        return ok({ ItemName=itemId, Quantity=quantity, TotalEarned=price*quantity, NewBalance=snap.Currency.Coins, NewInventory=snap.Inventory })
    end)
    
    if not success then
        warn("[RemoteHandlers] SellItem error for", player.Name, ":", result)
        return fail("Internal server error")
    end

    return result
end

-- Feature 002 (FR-001/004/005): sell every non-favourite crop stack in one action.
-- The server decides what is sellable (crops only) and what is protected (the
-- server-owned Favourites set); the client sends nothing but the request.
SellAll.OnServerInvoke = function(player)
    local success, result = pcall(function()
        if not rate_ok(player, "SellAll") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        local snap = PlayerData.Snapshot(player)
        if not snap then return fail("Data not loaded") end

        local favourites = PlayerData.GetFavourites(player)
        local totalEarned, soldCount, skippedFavourites = 0, 0, 0

        for itemId, count in pairs(snap.Inventory or {}) do
            count = tonumber(count) or 0
            if count > 0 and ShopConfig.CanSell(itemId) then
                if favourites[itemId] then
                    skippedFavourites = skippedFavourites + 1
                else
                    -- consume the whole stack, then credit its value
                    if PlayerData.TryConsumeItem(player, itemId, count) then
                        local price = sellPrice(itemId)
                        totalEarned = totalEarned + price * count
                        soldCount = soldCount + count
                    end
                end
            end
        end

        if totalEarned > 0 then
            PlayerData.AddCoins(player, totalEarned)
        end
        if soldCount > 0 then
            QuestService.Track(player, "sell", soldCount) -- feature 003 (US2)
        end

        local out = PlayerData.Snapshot(player)
        return ok({
            SoldCount = soldCount,
            TotalEarned = totalEarned,
            SkippedFavourites = skippedFavourites,
            NewBalance = out.Currency.Coins,
            NewInventory = out.Inventory,
        })
    end)

    if not success then
        warn("[RemoteHandlers] SellAll error for", player.Name, ":", result)
        return fail("Internal server error")
    end

    return result
end

-- Feature 002 (FR-004): toggle a crop's membership in the protected Favourites set.
ToggleFavourite.OnServerInvoke = function(player, itemId)
    local success, result = pcall(function()
        if not rate_ok(player, "ToggleFavourite") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        if type(itemId) ~= "string" then
            return fail("Bad args")
        end
        -- Only sellable crops can be favourited (favourites gate Sell all).
        if not ShopConfig.CanSell(itemId) then
            return fail("Item cannot be favourited")
        end
        local isFav = PlayerData.ToggleFavourite(player, itemId)
        return ok({ ItemId = itemId, IsFavourite = isFav, Favourites = PlayerData.GetFavourites(player) })
    end)

    if not success then
        warn("[RemoteHandlers] ToggleFavourite error for", player.Name, ":", result)
        return fail("Internal server error")
    end

    return result
end

-- Feature 002 (US6, FR-013/019): quick travel to a fixed, named destination. The
-- server resolves the target position from the world and moves the character; the
-- client never sends a position. Targets are limited to a fixed set (fail closed).
local Workspace = game:GetService("Workspace")
local TELEPORT_TARGETS = { shop = true, garden = true, stall = true }

-- Garden World Kit: resolve quick-travel to the map's invisible markers when present,
-- so GARDEN/SELL/SEEDS land at the real buildings. Falls back to the pre-kit targets
-- when the map (or a marker) is absent, so teleport still works and fails closed.
local function kitMarker(name)
    local map = Workspace:FindFirstChild("NITG_GardenWorld")
    local markers = map and map:FindFirstChild("Markers")
    local m = markers and markers:FindFirstChild(name)
    if m and m:IsA("BasePart") then return m.Position + Vector3.new(0, 3, 0) end
    return nil
end

local function resolveTargetPosition(targetId)
    if targetId == "stall" then
        local m = kitMarker("SellTeleport")
        if m then return m end
        local stall = Workspace:FindFirstChild("SellStall")
        local base = stall and (stall.PrimaryPart or stall:FindFirstChildWhichIsA("BasePart"))
        if base then return base.Position + Vector3.new(0, 5, 8) end
    elseif targetId == "garden" then
        local m = kitMarker("GardenTeleport")
        if m then return m end
        local plot = Workspace:FindFirstChild("Plot1")
        if plot then return plot:GetPivot().Position + Vector3.new(0, 5, 6) end
    elseif targetId == "shop" then
        local m = kitMarker("SeedsTeleport")
        if m then return m end
        -- no dedicated shop building in the test place; a fixed point near spawn
        return Vector3.new(-18, 6, 0)
    end
    return nil
end

RequestTeleport.OnServerInvoke = function(player, targetId)
    local success, result = pcall(function()
        if not rate_ok(player, "RequestTeleport") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        if type(targetId) ~= "string" or not TELEPORT_TARGETS[targetId] then
            return fail("Unknown destination")
        end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return fail("Character not ready")
        end
        local pos = resolveTargetPosition(targetId)
        if not pos then
            return fail("Destination unavailable")
        end
        hrp.CFrame = CFrame.new(pos)
        return ok({ Target = targetId })
    end)

    if not success then
        warn("[RemoteHandlers] RequestTeleport error for", player.Name, ":", result)
        return fail("Internal server error")
    end

    return result
end

-- Handle tool equipping (client → server sync)
EquipTool.OnServerEvent:Connect(function(player, toolName)
    -- P0-5: Error handling wrapper
    local success, err = pcall(function()
        if not rate_ok(player, "EquipTool") then 
            warn(string.format("[EquipTool] Rate limit exceeded for %s", player.Name))
            return 
        end
        
        if type(toolName) ~= "string" then
            warn(string.format("[EquipTool] Invalid tool name from %s: %s", player.Name, tostring(toolName)))
            return
        end
        
        local equipSuccess = InventoryService.SetEquipped(player, toolName)
        if equipSuccess then
            print(string.format("[EquipTool] %s equipped: %s", player.Name, toolName))
        else
            warn(string.format("[EquipTool] Failed to equip tool '%s' for %s (validation failed)", toolName, player.Name))
        end
    end)
    
    if not success then
        warn("[RemoteHandlers] EquipTool error for", player.Name, ":", err)
    end
end)

InteractWithPlot.OnServerEvent:Connect(function(player, plotModel, toolName)
    -- P0-5: Error handling wrapper
    local success, err = pcall(function()
        local res = PlotManager.HandleInteraction(player, plotModel, toolName)
        -- This is an event; we don't return a value. Client listens to PlotState* updates.
        if not res.Success then
            warn(string.format("[PLOT] %s: %s", player.Name, tostring(res.Error)))
        end
    end)
    
    if not success then
        warn("[RemoteHandlers] InteractWithPlot error for", player.Name, ":", err)
    end
end)

-- Handle spirit collection (client → server)
CollectSpirit.OnServerInvoke = function(player, spiritId)
    -- P0-5: Error handling wrapper
    local success, result = pcall(function()
        if not rate_ok(player, "CollectSpirit") then 
            return fail("You're doing that too fast. Please wait a moment.") 
        end
        
        if type(spiritId) ~= "string" or spiritId == "" then
            return fail("Invalid spirit ID")
        end
        
        -- Get spirit data
        local spiritData = SpiritSpawner.getSpirit(spiritId)
        if not spiritData or not spiritData.model then
            return fail("Spirit not found or already collected")
        end
        
        local spirit = spiritData.model
        local spiritType = spiritData.type
        
        -- Check if spirit is still active
        local isActive = function(id)
            return SpiritSpawner.getSpirit(id) ~= nil
        end
        
        local removeSpirit = function(id)
            SpiritSpawner.removeSpirit(id)
        end
        
        -- Try to collect (validates distance, cooldown, etc.)
        local collectSuccess, rewardAmount = SpiritCollector.tryCollect(
            player, 
            spiritId, 
            spirit, 
            spiritType, 
            isActive, 
            removeSpirit
        )
        
        if not collectSuccess then
            return fail("Failed to collect spirit (cooldown or distance)")
        end
        
        -- Return success with snapshot
        local snap = PlayerData.Snapshot(player)
        return ok({
            Success = true,
            Reward = rewardAmount,
            NewBalance = snap.Currency.DreamSeeds,
            Currency = snap.Currency,
            Inventory = snap.Inventory
        })
    end)
    
    if not success then
        warn("[RemoteHandlers] CollectSpirit error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    
    return result
end

-- Feature 003 (US1, FR-001/002/013): daily login reward. The server decides
-- claimability and the streak from its own clock; the client only reads and claims.
GetDailyReward.OnServerInvoke = function(player)
    local success, result = pcall(function()
        if not rate_ok(player, "GetDailyReward") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        local state = DailyRewardService.GetState(player)
        if not state then return fail("Data not loaded") end
        return ok(state)
    end)
    if not success then
        warn("[RemoteHandlers] GetDailyReward error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    return result
end

ClaimDailyReward.OnServerInvoke = function(player)
    local success, result = pcall(function()
        if not rate_ok(player, "ClaimDailyReward") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        local res, reason = DailyRewardService.Claim(player)
        if not res then
            return fail(reason or "Cannot claim")
        end
        -- Push the new balances so the HUD counter animates (US1 feedback).
        if UpdateCurrency then
            UpdateCurrency:FireClient(player, "Coins", res.NewBalance)
            UpdateCurrency:FireClient(player, "DreamSeeds", res.NewSeeds)
        end
        return ok(res)
    end)
    if not success then
        warn("[RemoteHandlers] ClaimDailyReward error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    return result
end

-- Feature 003 (US2, FR-003/004/005/013): daily quests. Progress is tracked only by
-- QuestService.Track at the authoritative event sites; these only read and claim.
GetQuests.OnServerInvoke = function(player)
    local success, result = pcall(function()
        if not rate_ok(player, "GetQuests") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        local data = QuestService.GetQuests(player)
        if not data then return fail("Data not loaded") end
        return ok(data)
    end)
    if not success then
        warn("[RemoteHandlers] GetQuests error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    return result
end

ClaimQuest.OnServerInvoke = function(player, questId)
    local success, result = pcall(function()
        if not rate_ok(player, "ClaimQuest") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        if type(questId) ~= "string" then return fail("Bad args") end
        local res, reason = QuestService.Claim(player, questId)
        if not res then return fail(reason or "Cannot claim") end
        if UpdateCurrency then
            UpdateCurrency:FireClient(player, "Coins", res.NewBalance)
            UpdateCurrency:FireClient(player, "DreamSeeds", res.NewSeeds)
        end
        return ok(res)
    end)
    if not success then
        warn("[RemoteHandlers] ClaimQuest error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    return result
end

-- Feature 003 (US5, FR-011): mark first-session onboarding complete (write-once-true).
SetTutorialDone.OnServerInvoke = function(player)
    local success, result = pcall(function()
        if not rate_ok(player, "SetTutorialDone") then
            return fail("You're doing that too fast. Please wait a moment.")
        end
        PlayerData.SetOnboardingDone(player)
        return ok()
    end)
    if not success then
        warn("[RemoteHandlers] SetTutorialDone error for", player.Name, ":", result)
        return fail("Internal server error")
    end
    return result
end

print("[RemoteHandlers] Bound")

-- Required by Init.lua as a ModuleScript: must return exactly one value
return true
