--!strict
--[[
	Offline checks for the spirit catalog (feature 006, Stage 2).

	Run:  luau Tools/Tests/spirit_config.spec.luau

	Validates ReplicatedStorage/SpiritData (the single source for spirit-type metadata)
	against specs/006-redesign-stage2/balance.md and the data-model invariants:
	every entry is well-formed, rarity is one of the five tiers, captureMethod is
	proximity|net, net types have a catchChance in (0,1] and a positive firstCatchBonus,
	the numbers match balance.md, and the pure rollCatch() behaves deterministically.

	SpiritData is pure (no Roblox globals) so it runs under the luau CLI.
]]

local SpiritData = require("../../ReplicatedStorage/SpiritData")

-- Expected catalog, transcribed from specs/006-redesign-stage2/balance.md.
-- If balance.md changes, update this table; a mismatch here is the gate.
local EXPECTED = {
	wisp_common = { rarity="Common", weight=70, captureMethod="proximity" },
	wisp_rare   = { rarity="Rare",   weight=25, captureMethod="proximity" },
	wisp_epic   = { rarity="Epic",   weight=5,  captureMethod="proximity" },
	moonmoth    = { rarity="Uncommon", weight=22, captureMethod="net", catchChance=0.60, firstCatchBonus=30 },
	moth_spirit = { rarity="Rare",     weight=10, captureMethod="net", catchChance=0.40, firstCatchBonus=60 },
}

local RARITIES = { Common=true, Uncommon=true, Rare=true, Epic=true, Legendary=true }
local METHODS = { proximity=true, net=true }

local failures = 0
local checks = 0
local function check(cond: boolean, msg: string)
	checks += 1
	if not cond then
		failures += 1
		print("  ✗ " .. msg)
	end
end

-- Catalog is present and the Rarities set matches the five tiers.
check(type(SpiritData.Types) == "table" and #SpiritData.Types > 0, "SpiritData.Types is a non-empty array")
for tier in pairs(RARITIES) do
	check(SpiritData.Rarities[tier] == true, "SpiritData.Rarities has tier: " .. tier)
end

-- Every entry is well-formed and matches balance.md.
local seen = {}
for _, t in ipairs(SpiritData.Types) do
	local id = t.id
	check(type(id) == "string" and #id > 0, "entry has an id")
	seen[id] = true
	local exp = EXPECTED[id]
	check(exp ~= nil, "catalog has no unexpected spirit: " .. tostring(id))
	check(type(t.displayName) == "string" and #t.displayName > 0, id .. ": has displayName")
	check(RARITIES[t.rarity] == true, id .. ": rarity is one of the five tiers")
	check(METHODS[t.captureMethod] == true, id .. ": captureMethod is proximity|net")
	check(type(t.weight) == "number" and t.weight > 0, id .. ": weight > 0")
	if exp then
		check(t.rarity == exp.rarity, id .. ": rarity matches balance.md")
		check(t.weight == exp.weight, id .. ": weight matches balance.md")
		check(t.captureMethod == exp.captureMethod, id .. ": captureMethod matches balance.md")
	end
	if t.captureMethod == "net" then
		check(type(t.catchChance) == "number" and t.catchChance > 0 and t.catchChance <= 1, id .. ": catchChance in (0,1]")
		check(type(t.firstCatchBonus) == "number" and t.firstCatchBonus > 0, id .. ": firstCatchBonus > 0")
		if exp then
			check(t.catchChance == exp.catchChance, id .. ": catchChance matches balance.md")
			check(t.firstCatchBonus == exp.firstCatchBonus, id .. ": firstCatchBonus matches balance.md")
		end
	else
		check(t.catchChance == nil or t.catchChance == 0, id .. ": proximity type has no catchChance")
	end
end

-- No expected spirit is missing.
for id in pairs(EXPECTED) do
	check(seen[id] == true, "catalog includes expected spirit: " .. id)
end

-- FindById resolves and misses.
check(SpiritData.FindById("moonmoth") ~= nil, "FindById resolves a known id")
check(SpiritData.FindById("nope_xyz") == nil, "FindById returns nil for an unknown id")

-- Pure rollCatch(): deterministic for a given roll.
check(SpiritData.rollCatch(0.5, 0.3) == true, "rollCatch(0.5, 0.3) succeeds (roll < chance)")
check(SpiritData.rollCatch(0.5, 0.5) == false, "rollCatch(0.5, 0.5) fails (roll == chance)")
check(SpiritData.rollCatch(0.5, 0.7) == false, "rollCatch(0.5, 0.7) fails (roll > chance)")
check(SpiritData.rollCatch(1.0, 0.99) == true, "rollCatch(1.0, x) always succeeds")
check(SpiritData.rollCatch(0.0, 0.0) == false, "rollCatch(0.0, x) always fails")

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
	error(string.format("spirit_config.spec: %d failing assertion(s)", failures))
end
print("✅ spirit_config.spec passed")
