-- QuestService.lua
-- Server-authoritative daily quests (feature 003, US2/FR-003/004/005).
--
-- The day's quest set is chosen deterministically from RetentionConfig.Quests by the
-- UTC day index (PickDailyQuests), so every player on every server shares it with no
-- stored RNG. Progress is incremented only from authoritative server events through
-- Track(player, kind, amount) — the client never reports progress (constitution I).
-- Rewards (coins/DreamSeeds) come once from config (II) and are grantable once.

local RS = game:GetService("ReplicatedStorage")
local RetentionConfig = require(RS:WaitForChild("RetentionConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))

local QuestUpdated = RS:WaitForChild("QuestUpdated")

local M = {}

-- Ensure the player's stored quest state belongs to today; rebuild + reset if the
-- day rolled over. Returns (questState, daySet) where daySet is the array of defs.
local function ensureDay(player)
    local qs = PlayerData.GetQuestState(player)
    if not qs then return nil, nil end
    local dayIndex = RetentionConfig.DayIndex(os.time())
    if qs.Day ~= dayIndex then
        qs.Day = dayIndex
        qs.Progress = {}
        qs.Claimed = {}
    end
    return qs, RetentionConfig.PickDailyQuests(dayIndex)
end

-- Find a def by id within today's set (nil if not part of today's quests).
local function defInSet(daySet, questId)
    for _, def in ipairs(daySet) do
        if def.id == questId then return def end
    end
    return nil
end

local function rewardOf(def)
    return { coins = tonumber(def.coins) or 0, seeds = tonumber(def.seeds) or 0 }
end

-- Client view: today's quests with per-player progress and claimed state.
function M.GetQuests(player)
    local qs, daySet = ensureDay(player)
    if not qs then return nil end
    local out = {}
    for _, def in ipairs(daySet) do
        out[#out + 1] = {
            id = def.id, kind = def.kind, target = def.target, text = def.text,
            reward = rewardOf(def),
            progress = math.min(def.target, qs.Progress[def.id] or 0),
            claimed = qs.Claimed[def.id] == true,
        }
    end
    return { Day = qs.Day, Quests = out }
end

-- Increment progress for every today-quest of the given kind, clamped at target, and
-- push the change to the player (QuestUpdated). Called from the authoritative event
-- sites (plant/harvest in PlotManager, sell in RemoteHandlers, catch in SpiritCollector).
function M.Track(player, kind, amount)
    if type(kind) ~= "string" then return end
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    local qs, daySet = ensureDay(player)
    if not qs then return end
    for _, def in ipairs(daySet) do
        if def.kind == kind then
            local cur = qs.Progress[def.id] or 0
            if cur < def.target then
                local newProgress = math.min(def.target, cur + amount)
                qs.Progress[def.id] = newProgress
                if QuestUpdated then
                    QuestUpdated:FireClient(player, def.id, newProgress, qs.Claimed[def.id] == true)
                end
            end
        end
    end
end

-- Grant a completed quest's reward once. Returns result table, or nil + reason.
function M.Claim(player, questId)
    if type(questId) ~= "string" then return nil, "Bad args" end
    local qs, daySet = ensureDay(player)
    if not qs then return nil, "Data not loaded" end
    local def = defInSet(daySet, questId)
    if not def then return nil, "Unknown quest" end
    if (qs.Progress[questId] or 0) < def.target then return nil, "Not complete" end
    if qs.Claimed[questId] then return nil, "Already claimed" end

    local reward = rewardOf(def)
    if reward.coins > 0 then PlayerData.AddCoins(player, reward.coins) end
    if reward.seeds > 0 then PlayerData.AddDreamSeeds(player, reward.seeds) end
    qs.Claimed[questId] = true

    if QuestUpdated then
        QuestUpdated:FireClient(player, questId, qs.Progress[questId] or def.target, true)
    end

    local snap = PlayerData.Snapshot(player)
    return {
        QuestId = questId,
        Granted = reward,
        NewBalance = snap and snap.Currency.Coins or 0,
        NewSeeds = snap and snap.Currency.DreamSeeds or 0,
    }
end

return M
