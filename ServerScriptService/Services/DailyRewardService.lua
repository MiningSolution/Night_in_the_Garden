-- DailyRewardService.lua
-- Server-authoritative daily login reward on a 7-day streak (feature 003, US1/FR-001).
--
-- A "day" is the UTC day index os.time()//86400 (RetentionConfig.DayIndex): a reward
-- is claimable at most once per day index. Claiming advances the streak by one day;
-- a gap of two or more day indices resets it to day 1; after day 7 it loops to day 1.
-- All of this is decided here from the server clock — the client never sends a day
-- (constitution I). Reward amounts come once from RetentionConfig.DailyRewards (II).

local RS = game:GetService("ReplicatedStorage")
local RetentionConfig = require(RS:WaitForChild("RetentionConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))

local M = {}

local REWARDS = RetentionConfig.DailyRewards
local MAX_DAY = #REWARDS -- 7

-- The streak day a claim right now would grant, given the stored state and today's
-- day index. Only meaningful when claimable; when not, the current StreakDay stands.
local function nextStreakDay(streakDay, lastClaimDay, dayIndex)
    if streakDay <= 0 then
        return 1 -- never claimed
    elseif dayIndex == lastClaimDay + 1 then
        return (streakDay % MAX_DAY) + 1 -- advance, looping 7 -> 1
    else
        return 1 -- missed a day (gap >= 2) -> reset
    end
end

-- Read-only view for the client (GetDailyReward).
function M.GetState(player)
    local dr = PlayerData.GetDailyReward(player)
    if not dr then return nil end
    local dayIndex = RetentionConfig.DayIndex(os.time())
    local claimable = dayIndex > dr.LastClaimDay
    local today = claimable and nextStreakDay(dr.StreakDay, dr.LastClaimDay, dayIndex) or dr.StreakDay
    return {
        StreakDay = dr.StreakDay,
        LastClaimDay = dr.LastClaimDay,
        Claimable = claimable,
        Today = today,
        Rewards = REWARDS,
    }
end

-- Grant today's reward if claimable; advance/reset/loop the streak. Returns the
-- result table, or nil + reason on failure (fail closed, constitution I).
function M.Claim(player)
    local dr = PlayerData.GetDailyReward(player)
    if not dr then return nil, "Data not loaded" end
    local dayIndex = RetentionConfig.DayIndex(os.time())
    if dayIndex <= dr.LastClaimDay then
        return nil, "Already claimed"
    end

    local streakDay = nextStreakDay(dr.StreakDay, dr.LastClaimDay, dayIndex)
    local reward = REWARDS[streakDay] or {}
    local coins = tonumber(reward.coins) or 0
    local seeds = tonumber(reward.seeds) or 0

    local newCoins, newSeeds
    if coins > 0 then newCoins = PlayerData.AddCoins(player, coins) end
    if seeds > 0 then newSeeds = PlayerData.AddDreamSeeds(player, seeds) end

    PlayerData.SetDailyReward(player, streakDay, dayIndex)

    local snap = PlayerData.Snapshot(player)
    return {
        StreakDay = streakDay,
        Granted = { coins = coins, seeds = seeds },
        NewBalance = snap and snap.Currency.Coins or newCoins or 0,
        NewSeeds = snap and snap.Currency.DreamSeeds or newSeeds or 0,
    }
end

return M
