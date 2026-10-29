--!strict
--[[
	Offline checks for the retention config (feature 003).

	Run:  luau Tools/Tests/retention_config.spec.luau

	Validates RetentionConfig (the single source for the retention numbers) against
	the balance document (specs/003-retention/balance.md) and the data-model
	invariants: the 7-day reward table (coins non-decreasing), the quest pool
	(targets/rewards/kinds), the restock interval and per-item stock (keys resolve to
	known items), and the pure helpers (day index, restock window, deterministic quest
	pick).

	RetentionConfig is PURE (no `game` global), so it is required directly, like
	PlantData. Non-plant stock keys (tools/items) live in ShopConfig, which needs the
	Roblox `game` global; those keys are checked here against a fixed allow-list
	transcribed from balance.md, and their real resolution is exercised in the Studio
	playtest (quickstart O2/V7).
]]

local RetentionConfig = require("../../ReplicatedStorage/RetentionConfig")
local PlantData = require("../../ReplicatedStorage/PlantData")

-- Expected numbers, transcribed from specs/003-retention/balance.md.
-- If balance.md changes, update this file; a mismatch here is the SC-006 gate.
local EXPECTED_REWARDS = {
	{ coins = 25 },
	{ coins = 40 },
	{ coins = 60 },
	{ coins = 90,  seeds = 1 },
	{ coins = 120 },
	{ coins = 160, seeds = 2 },
	{ coins = 250, seeds = 5 },
}

local EXPECTED_QUESTS = {
	plant_5   = { kind = "plant",        target = 5,  coins = 30 },
	harvest_3 = { kind = "harvest",      target = 3,  coins = 40 },
	sell_5    = { kind = "sell",         target = 5,  coins = 50 },
	catch_3   = { kind = "catch_spirit", target = 3,  seeds = 3  },
	plant_10  = { kind = "plant",        target = 10, coins = 60 },
	sell_10   = { kind = "sell",         target = 10, coins = 90 },
}

local EXPECTED_INTERVAL = 300

local EXPECTED_STOCK = {
	carrot_seed = 20, wheat_seed = 20, tomato_seed = 12, pumpkin_seed = 10,
	moonflower_seed = 6, starberry_seed = 4, dreamroot_seed = 2,
	improved_watering_can = 3, fertilizer = 10, dream_dust = 5,
}

-- Non-plant item ids that are allowed stock keys (transcribed from ShopConfig; that
-- module needs `game`, so this mirror keeps the test pure — see header).
local NON_PLANT_ITEMS = {
	basic_watering_can = true, improved_watering_can = true,
	fertilizer = true, dream_dust = true,
}

local KINDS = { plant = true, harvest = true, sell = true, catch_spirit = true }

local failures = 0
local checks = 0
local function check(cond: boolean, msg: string)
	checks += 1
	if not cond then
		failures += 1
		print("  ✗ " .. msg)
	end
end

-- ── Daily rewards (7 days, non-decreasing coins, amounts match balance.md) ──────
print("• daily rewards")
check(#RetentionConfig.DailyRewards == 7, "exactly 7 reward days")
local prevCoins = -1
for day, exp in ipairs(EXPECTED_REWARDS) do
	local got = RetentionConfig.DailyRewards[day]
	check(got ~= nil, "day " .. day .. ": defined")
	if got then
		check(got.coins == exp.coins, "day " .. day .. ": coins == " .. tostring(exp.coins))
		check((got.seeds or 0) == (exp.seeds or 0), "day " .. day .. ": seeds == " .. tostring(exp.seeds or 0))
		check(type(got.coins) == "number" and got.coins > 0, "day " .. day .. ": coins > 0")
		check(got.coins >= prevCoins, "day " .. day .. ": coins non-decreasing")
		prevCoins = got.coins
	end
end

-- ── Quests (pool matches balance.md; pool size > QuestsPerDay; valid kinds) ─────
print("• quests")
check(RetentionConfig.QuestsPerDay == 3, "QuestsPerDay == 3")
check(#RetentionConfig.Quests > RetentionConfig.QuestsPerDay, "#pool > QuestsPerDay")
local seenIds = {}
for _, q in ipairs(RetentionConfig.Quests) do
	local exp = EXPECTED_QUESTS[q.id]
	check(exp ~= nil, "quest " .. tostring(q.id) .. ": expected in balance.md")
	check(not seenIds[q.id], "quest " .. tostring(q.id) .. ": id unique")
	seenIds[q.id] = true
	check(KINDS[q.kind] == true, q.id .. ": kind is plant/harvest/sell/catch_spirit")
	check(type(q.target) == "number" and q.target > 0, q.id .. ": target > 0")
	check((tonumber(q.coins) or 0) > 0 or (tonumber(q.seeds) or 0) > 0, q.id .. ": has a reward")
	check(type(q.text) == "string" and #q.text > 0, q.id .. ": has text")
	if exp then
		check(q.kind == exp.kind, q.id .. ": kind == " .. exp.kind)
		check(q.target == exp.target, q.id .. ": target == " .. tostring(exp.target))
		check((q.coins or 0) == (exp.coins or 0), q.id .. ": coins == " .. tostring(exp.coins or 0))
		check((q.seeds or 0) == (exp.seeds or 0), q.id .. ": seeds == " .. tostring(exp.seeds or 0))
	end
end
for id in pairs(EXPECTED_QUESTS) do
	check(seenIds[id] == true, "pool has expected quest: " .. id)
end

-- ── Restock (interval + per-item stock; every key resolves to a known item) ─────
print("• restock")
check(RetentionConfig.RestockIntervalSec == EXPECTED_INTERVAL, "RestockIntervalSec == " .. EXPECTED_INTERVAL)
check(RetentionConfig.RestockIntervalSec > 0, "RestockIntervalSec > 0")
for itemId, n in pairs(RetentionConfig.ShopStock) do
	check(EXPECTED_STOCK[itemId] == n, itemId .. ": stock == " .. tostring(EXPECTED_STOCK[itemId]))
	check(type(n) == "number" and n > 0, itemId .. ": stock > 0")
	-- key resolves: a <base>_seed of a known plant, or a known non-plant item.
	local base = itemId:gsub("_seed$", "")
	local resolves = (PlantData[base] ~= nil and itemId == base .. "_seed") or NON_PLANT_ITEMS[itemId] == true
	check(resolves, itemId .. ": resolves to a known item")
end
for itemId, n in pairs(EXPECTED_STOCK) do
	check(RetentionConfig.ShopStock[itemId] == n, "stock has expected key: " .. itemId)
end

-- ── Night event thresholds ──────────────────────────────────────────────────--
print("• night event")
check(RetentionConfig.AnnounceRarities.Rare == true, "Rare announces")
check(RetentionConfig.AnnounceRarities.Epic == true, "Epic announces")
check(RetentionConfig.AnnounceRarities.Common == nil, "Common does not announce")
check(type(RetentionConfig.AnnounceDedupeSec) == "number" and RetentionConfig.AnnounceDedupeSec > 0, "AnnounceDedupeSec > 0")
check(type(RetentionConfig.NightBannerSeconds) == "number" and RetentionConfig.NightBannerSeconds > 0, "NightBannerSeconds > 0")

-- ── Pure helpers ──────────────────────────────────────────────────────────────
print("• helpers")
check(RetentionConfig.DayIndex(86400 * 5 + 123) == 5, "DayIndex(5d+123s) == 5")
check(RetentionConfig.DayIndex(0) == 0, "DayIndex(0) == 0")
check(RetentionConfig.RestockWindow(EXPECTED_INTERVAL * 7 + 5) == 7, "RestockWindow == 7 inside window 7")
check(RetentionConfig.RestockAt(EXPECTED_INTERVAL * 7 + 5) == EXPECTED_INTERVAL * 8, "RestockAt == next boundary")

local pickA = RetentionConfig.PickDailyQuests(10)
local pickA2 = RetentionConfig.PickDailyQuests(10)
check(#pickA == RetentionConfig.QuestsPerDay, "PickDailyQuests returns QuestsPerDay entries")
local distinct = {}
local allDistinct = true
for _, q in ipairs(pickA) do
	if distinct[q.id] then allDistinct = false end
	distinct[q.id] = true
end
check(allDistinct, "PickDailyQuests entries are distinct")
local sameAsRepeat = true
for i, q in ipairs(pickA) do
	if pickA2[i].id ~= q.id then sameAsRepeat = false end
end
check(sameAsRepeat, "PickDailyQuests is deterministic for a given day")
local pickB = RetentionConfig.PickDailyQuests(11)
check(pickB[1].id ~= pickA[1].id, "PickDailyQuests rotates across days")

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
	error(string.format("retention_config.spec: %d failing assertion(s)", failures))
end
print("✅ retention_config.spec passed")
