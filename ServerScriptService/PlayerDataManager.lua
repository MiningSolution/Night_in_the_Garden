-- PlayerDataManager.lua
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ServerScriptService:WaitForChild("ProfileService"))
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))
local DEFAULT_DATA = require(ReplicatedStorage:WaitForChild("DefaultData"))

local M = {}
local Profiles = {}
local ProfileStore = ProfileService.GetProfileStore(GameSettings.ProfileStoreName(), DEFAULT_DATA)

local SCHEMA_VERSION = DEFAULT_DATA.SchemaVersion or 1

local function Migrate(profile)
    local data = profile.Data
    if (data.SchemaVersion or 0) < SCHEMA_VERSION then
        -- Example Migration hook
        data.SchemaVersion = SCHEMA_VERSION
    end
end

-- Retry logic for DataStore operations
local function loadProfileWithRetry(player, maxRetries)
    maxRetries = maxRetries or 3
    local retryDelay = 1
    
    for attempt = 1, maxRetries do
        local success, profile = pcall(function()
            return ProfileStore:LoadProfileAsync("Player_"..player.UserId, "ForceLoad")
        end)
        
        if success and profile then
            return profile
        end
        
        if attempt < maxRetries then
            warn(string.format("[PlayerData] Failed to load profile for %s (attempt %d/%d), retrying...", 
                player.Name, attempt, maxRetries))
            task.wait(retryDelay)
            retryDelay = retryDelay * 2 -- Exponential backoff
        else
            warn(string.format("[PlayerData] Failed to load profile for %s after %d attempts", 
                player.Name, maxRetries))
        end
    end
    
    return nil
end

function M.InitPlayer(player)
    local profile = loadProfileWithRetry(player)
    if not profile then
        player:Kick("Failed to load profile. Try again later.")
        return
    end
    profile:AddUserId(player.UserId)
    profile:Reconcile()
    Migrate(profile)
    profile.Data.LastLogin = os.time()
    profile.Data.TotalLogins = (profile.Data.TotalLogins or 0) + 1

    profile:ListenToRelease(function()
        Profiles[player] = nil
        if player:IsDescendantOf(Players) then
            player:Kick("Session closed. Please rejoin.")
        end
    end)

    if player:IsDescendantOf(Players) then
        Profiles[player] = profile
        -- Optionally notify client
        local ready = ReplicatedStorage:FindFirstChild("PlayerDataReady")
        if ready then ready:FireClient(player) end
    else
        profile:Release()
    end
end

function M.RemovePlayer(player)
    local profile = Profiles[player]
    if profile then
        local sessionStart = profile.Data.LastLogin or os.time()
        local sessionDuration = os.time() - sessionStart
        profile.Data.Stats.PlayTimeSeconds = (profile.Data.Stats.PlayTimeSeconds or 0) + sessionDuration
        profile:Release()
        Profiles[player] = nil
    end
end

function M.BindPlayerLifecycle()
    Players.PlayerAdded:Connect(M.InitPlayer)
    Players.PlayerRemoving:Connect(M.RemovePlayer)
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(M.InitPlayer, p)
    end
end

function M.Get(player)
    local profile = Profiles[player]
    return profile and profile.Data or nil
end

function M.Snapshot(player)
    local data = M.Get(player)
    if not data then return nil end
    local function deepcopy(t)
        if type(t) ~= "table" then return t end
        local r = {}
        for k,v in pairs(t) do r[k] = deepcopy(v) end
        return r
    end
    return deepcopy(data)
end

-- Currency helpers
function M.AddCoins(p, amt)
    local d = M.Get(p); if not d then return 0 end
    amt = math.max(0, math.floor(tonumber(amt) or 0))
    d.Currency.Coins = d.Currency.Coins + amt
    d.Stats.TotalEarnings = (d.Stats.TotalEarnings or 0) + amt
    return d.Currency.Coins
end

function M.TrySpendCoins(p, amt)
    local d = M.Get(p); if not d then return false, 0 end
    amt = math.max(0, math.floor(tonumber(amt) or 0))
    if d.Currency.Coins < amt then return false, d.Currency.Coins end
    d.Currency.Coins = d.Currency.Coins - amt
    return true, d.Currency.Coins
end

-- Inventory helpers
function M.AddItem(p, itemId, qty)
    local d = M.Get(p); if not d then return 0 end
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    d.Inventory[itemId] = (d.Inventory[itemId] or 0) + qty
    return d.Inventory[itemId]
end

function M.HasItem(p, itemId, qty)
    local d = M.Get(p); if not d then return false end
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    return (d.Inventory[itemId] or 0) >= qty
end

function M.TryConsumeItem(p, itemId, qty)
    local d = M.Get(p); if not d then return false end
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    local have = d.Inventory[itemId] or 0
    if have < qty then return false end
    local left = have - qty
    if left > 0 then d.Inventory[itemId] = left else d.Inventory[itemId] = nil end
    return true
end

-- P0-3: Atomic check-and-consume operation (prevents race conditions)
-- This combines HasItem check and TryConsumeItem into one atomic operation
function M.TryConsumeItemAtomic(p, itemId, qty)
    local d = M.Get(p)
    if not d then 
        return false, "No data" 
    end
    
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    local have = d.Inventory[itemId] or 0
    
    -- Atomic: check and consume in one step (no race condition window)
    if have < qty then 
        return false, "Not enough items" 
    end
    
    -- Consume immediately
    local left = have - qty
    if left > 0 then 
        d.Inventory[itemId] = left 
    else 
        d.Inventory[itemId] = nil 
    end
    
    return true, nil
end

function M.AddDreamSeeds(player, amount)
    local data = M.Get(player)
    if not data then return 0 end
    amount = math.max(0, math.floor(amount or 0))
    data.Currency.DreamSeeds = (data.Currency.DreamSeeds or 0) + amount
    return data.Currency.DreamSeeds
end

-- Plots
function M.GetPlot(p, plotId)
    local d = M.Get(p); if not d then return nil end
    d.Plots[plotId] = d.Plots[plotId] or { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false }
    return d.Plots[plotId]
end

game:BindToClose(function()
    task.wait(3)
end)

return M
