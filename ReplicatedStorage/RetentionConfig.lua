-- RetentionConfig.lua
-- Single source of truth for the Phase 3 "retention" numbers (constitution II):
-- the daily-reward streak table, the daily-quest pool, the shop restock interval
-- and per-item stock, and the night-event thresholds. Numbers are transcribed from
-- specs/003-retention/balance.md; the offline test Tools/Tests/retention_config.spec.luau
-- checks this module against that document and the data-model invariants.
--
-- This module is PURE (no `game` global): server and client both require it, and the
-- offline Luau test requires it directly. The stateful services (DailyRewardService,
-- QuestService, ShopStockService) read these tables and helpers; they never duplicate
-- a number (II).

local RetentionConfig = {}

-- ── Daily reward ──────────────────────────────────────────────────────────────
-- 7-day streak track. Coins are non-decreasing; `seeds` (DreamSeeds) appear on
-- milestone days only. After day 7 the track loops to day 1 (DailyRewardService).
RetentionConfig.DailyRewards = {
    { coins = 25 },
    { coins = 40 },
    { coins = 60 },
    { coins = 90,  seeds = 1 },
    { coins = 120 },
    { coins = 160, seeds = 2 },
    { coins = 250, seeds = 5 },
}

-- ── Daily quests ────────────────────────────────────────────────────────────--
-- QuestsPerDay quests are chosen each day from the pool below, deterministically by
-- the day index (PickDailyQuests), so every player on every server shares the set.
-- `kind` matches a server event: plant / harvest / sell / catch_spirit.
RetentionConfig.QuestsPerDay = 3

RetentionConfig.Quests = {
    { id = "plant_5",   kind = "plant",        target = 5,  coins = 30, text = "Plant 5 seeds" },
    { id = "harvest_3", kind = "harvest",      target = 3,  coins = 40, text = "Harvest 3 crops" },
    { id = "sell_5",    kind = "sell",         target = 5,  coins = 50, text = "Sell 5 crops" },
    { id = "catch_3",   kind = "catch_spirit", target = 3,  seeds = 3,  text = "Catch 3 spirits at night" },
    { id = "plant_10",  kind = "plant",        target = 10, coins = 60, text = "Plant 10 seeds" },
    { id = "sell_10",   kind = "sell",         target = 10, coins = 90, text = "Sell 10 crops" },
}

-- ── Shop restock ──────────────────────────────────────────────────────────────
-- The restock schedule is derived from time (window = os.time() // interval), so all
-- servers agree on the moment/countdown. Stock is per-server, per-window: it refills
-- to the values below at each window boundary. Items absent from ShopStock are
-- UNLIMITED (e.g. the free basic_watering_can). Keys must resolve to known items in
-- ShopConfig/PlantData (checked by the offline test).
RetentionConfig.RestockIntervalSec = 300

RetentionConfig.ShopStock = {
    carrot_seed            = 20,
    wheat_seed             = 20,
    tomato_seed            = 12,
    pumpkin_seed           = 10,
    moonflower_seed        = 6,
    starberry_seed         = 4,
    dreamroot_seed         = 2,
    improved_watering_can  = 3,
    fertilizer             = 10,
    dream_dust             = 5,
}

-- ── Night event ─────────────────────────────────────────────────────────────--
-- Spirit tiers that trigger the server-wide announcement (Common never announces).
RetentionConfig.AnnounceRarities = { Rare = true, Epic = true }
-- Client-side de-dupe window for announcements (seconds).
RetentionConfig.AnnounceDedupeSec = 5
-- Nightfall banner duration (seconds), non-blocking.
RetentionConfig.NightBannerSeconds = 2.5

-- ── Pure helpers (unit-tested offline) ─────────────────────────────────────────
local SECONDS_PER_DAY = 86400

-- UTC calendar day index. Claimability and quest resets key off this (research R1).
function RetentionConfig.DayIndex(now)
    return math.floor((tonumber(now) or 0) / SECONDS_PER_DAY)
end

-- Restock window number. Boundary = when stock refills (research R4).
function RetentionConfig.RestockWindow(now)
    return math.floor((tonumber(now) or 0) / RetentionConfig.RestockIntervalSec)
end

-- The server `os.time()` at which the current window ends / the next begins.
function RetentionConfig.RestockAt(now)
    return (RetentionConfig.RestockWindow(now) + 1) * RetentionConfig.RestockIntervalSec
end

-- Deterministic daily quest set: QuestsPerDay distinct pool entries chosen by the day
-- index, identical for a given dayIndex on every server (research R3).
function RetentionConfig.PickDailyQuests(dayIndex)
    local pool = RetentionConfig.Quests
    local n = #pool
    local out = {}
    for i = 0, RetentionConfig.QuestsPerDay - 1 do
        out[#out + 1] = pool[((dayIndex + i) % n) + 1]
    end
    return out
end

-- Look up a quest definition by id (nil if not in the pool).
function RetentionConfig.GetQuestDef(questId)
    for _, q in ipairs(RetentionConfig.Quests) do
        if q.id == questId then return q end
    end
    return nil
end

return RetentionConfig
