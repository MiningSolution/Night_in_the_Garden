local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProfileService = require(ServerScriptService:WaitForChild("ProfileServiceLoader"))

local M = {}

local PROFILE_STORE_NAME = "PlayerData_v1"
local SCHEMA_VERSION = 1

local DEFAULT_DATA = {
    SchemaVersion = SCHEMA_VERSION,
    Currency = { Coins = 50, DreamSeeds = 0 },
    Inventory = {
        carrot_seed = 5, tomato_seed = 0, wheat_seed = 0, pumpkin_seed = 0,
        moonflower_seed = 0, starberry_seed = 0,
        basic_watering_can = 1, improved_watering_can = 0,
        basic_lantern = 1, bright_lantern = 0, fertilizer = 0, lantern_fuel = 0,
        carrot_crop = 0, tomato_crop = 0, wheat_crop = 0, pumpkin_crop = 0,
        moonflower_crop = 0, starberry_crop = 0,
    },
    Plots = {
        Plot1 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false, TimeRemaining=nil },
        Plot2 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false, TimeRemaining=nil },
        Plot3 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false, TimeRemaining=nil },
    },
    Stats = { Level = 1, XP = 0, TotalHarvests = 0, TotalEarnings = 0, PlayTimeSeconds = 0 },
    Settings = { MusicEnabled = true, SFXEnabled = true, UIScale = 1.0 },
    LastLogin = os.time(), TotalLogins = 0, CreatedAt = os.time()
}

local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, DEFAULT_DATA)
local Profiles = {}

local function migrateProfile(profile)
    local d = profile.Data
    if (d.SchemaVersion or 0) >= SCHEMA_VERSION then return end
    d.SchemaVersion = SCHEMA_VERSION
end

function M.InitPlayer(player)
    if Profiles[player] then return end
    local profile = ProfileStore:LoadProfileAsync(("Player_%d"):format(player.UserId), "ForceLoad")
    if not profile then player:Kick("Failed to load data. Please try again later."); return end
    profile:AddUserId(player.UserId)
    profile:Reconcile()
    migrateProfile(profile)
    profile.Data.LastLogin = os.time()
    profile.Data.TotalLogins = (profile.Data.TotalLogins or 0) + 1

    profile:ListenToRelease(function()
        Profiles[player] = nil
        if player:IsDescendantOf(Players) then
            player:Kick("Profile session ended. Please rejoin.")
        end
    end)

    if not player:IsDescendantOf(Players) then
        profile:Release()
        return
    end
    Profiles[player] = profile
end

function M.RemovePlayer(player)
    local profile = Profiles[player]
    if not profile then return end
    local start = profile.Data.LastLogin or os.time()
    profile.Data.Stats.PlayTimeSeconds = (profile.Data.Stats.PlayTimeSeconds or 0) + math.max(0, os.time() - start)
    profile:Release()
    Profiles[player] = nil
end

Players.PlayerAdded:Connect(M.InitPlayer)
Players.PlayerRemoving:Connect(M.RemovePlayer)

function M.Get(player) local p=Profiles[player]; return p and p.Data or nil end
local function deepCopy(t) if type(t)~="table" then return t end local r={} for k,v in pairs(t) do r[k]=deepCopy(v) end return r end
function M.Snapshot(player) local d=M.Get(player); if not d then return nil end return deepCopy(d) end

function M.AddCoins(player, amount) local d=M.Get(player); if not d then return 0 end amount=math.max(0,math.floor(amount or 0)); d.Currency.Coins=(d.Currency.Coins or 0)+amount; d.Stats.TotalEarnings=(d.Stats.TotalEarnings or 0)+amount; return d.Currency.Coins end
function M.TrySpendCoins(player, amount) local d=M.Get(player); if not d then return false,0 end amount=math.max(0,math.floor(amount or 0)); if (d.Currency.Coins or 0) < amount then return false,d.Currency.Coins end d.Currency.Coins=d.Currency.Coins-amount; return true,d.Currency.Coins end

function M.AddItem(player, itemId, quantity) local d=M.Get(player); if not d then return 0 end quantity=math.max(1,math.floor(quantity or 1)); d.Inventory[itemId]=(d.Inventory[itemId] or 0)+quantity; return d.Inventory[itemId] end
function M.HasItem(player, itemId, quantity) local d=M.Get(player); if not d then return false end quantity=math.max(1,math.floor(quantity or 1)); return (d.Inventory[itemId] or 0) >= quantity end
function M.TryConsumeItem(player, itemId, quantity) local d=M.Get(player); if not d then return false end quantity=math.max(1,math.floor(quantity or 1)); local have=d.Inventory[itemId] or 0; if have < quantity then return false end local left = have - quantity; d.Inventory[itemId] = left > 0 and left or nil; return true end

function M.GetPlot(player, plotId)
    local d = M.Get(player)
    if not d then
        return { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false, TimeRemaining=nil }
    end
    d.Plots[plotId] = d.Plots[plotId] or { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false, TimeRemaining=nil }
    return d.Plots[plotId]
end

game:BindToClose(function()
    if RunService:IsStudio() then task.wait(3); return end
    for _, profile in pairs(Profiles) do profile:Release() end
    local start=os.clock()
    while next(Profiles) and os.clock()-start < 30 do task.wait(0.1) end
end)

return M
