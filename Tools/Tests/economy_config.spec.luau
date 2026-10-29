--!strict
--[[
	Offline checks for the economy config (feature 002).

	Run:  luau Tools/Tests/economy_config.spec.luau

	Validates PlantData (the single source for seed/crop numbers, from which
	ShopConfig derives) against the balance document
	(specs/002-buy-sell-economy/balance.md) and the data-model invariants:
	numbers match (O1), only crops are sellable / all values present, rarity and
	dayNight are from their fixed sets, and ids resolve (O2).

	ShopConfig itself requires the Roblox `game` global (it derives its rows from
	PlantData at runtime), so it is exercised in the Studio playtest (quickstart
	V2/V3), not here. This file stays pure so it runs under the luau CLI.
]]

local PlantData = require("../../ReplicatedStorage/PlantData")

-- Expected numbers, transcribed from specs/002-buy-sell-economy/balance.md.
-- If balance.md changes, update this table; a mismatch here is the SC-003 gate.
local EXPECTED = {
	carrot     = { rarity="Common",    seedPrice=5,  sellValue=8,   growthTimeSec=120, dayNight="any"   },
	wheat      = { rarity="Common",    seedPrice=6,  sellValue=10,  growthTimeSec=150, dayNight="any"   },
	tomato     = { rarity="Uncommon",  seedPrice=8,  sellValue=14,  growthTimeSec=180, dayNight="any"   },
	pumpkin    = { rarity="Uncommon",  seedPrice=12, sellValue=21,  growthTimeSec=240, dayNight="any"   },
	moonflower = { rarity="Rare",      seedPrice=20, sellValue=38,  growthTimeSec=200, dayNight="night" },
	starberry  = { rarity="Epic",      seedPrice=28, sellValue=55,  growthTimeSec=210, dayNight="night" },
	dreamroot  = { rarity="Legendary", seedPrice=60, sellValue=130, growthTimeSec=300, dayNight="night" },
}

local RARITIES = { Common=true, Uncommon=true, Rare=true, Epic=true, Legendary=true }
local PHASES = { day=true, night=true, any=true }

local failures = 0
local checks = 0
local function check(cond: boolean, msg: string)
	checks += 1
	if not cond then
		failures += 1
		print("  ✗ " .. msg)
	end
end

-- Every expected plant exists and matches balance.md (O1 / SC-003).
for base, exp in pairs(EXPECTED) do
	print("• " .. base)
	local def = PlantData[base]
	check(def ~= nil, base .. ": defined in PlantData")
	if def then
		check(def.rarity == exp.rarity, base .. ": rarity == " .. exp.rarity)
		check(def.seedPrice == exp.seedPrice, base .. ": seedPrice == " .. tostring(exp.seedPrice))
		check(def.sellValue == exp.sellValue, base .. ": sellValue == " .. tostring(exp.sellValue))
		check(def.growthTimeSec == exp.growthTimeSec, base .. ": growthTimeSec == " .. tostring(exp.growthTimeSec))
		check(def.dayNight == exp.dayNight, base .. ": dayNight == " .. exp.dayNight)
		-- margin invariant: a crop sells for more than its seed costs (balance.md)
		check(def.sellValue > def.seedPrice, base .. ": sellValue > seedPrice (profitable)")
	end
end

-- No unexpected plants slipped in (keeps the test and config in lockstep).
for base in pairs(PlantData) do
	check(EXPECTED[base] ~= nil, "PlantData has no unexpected plant: " .. base)
end

-- Integrity invariants on every definition (O2).
for base, def in pairs(PlantData) do
	check(type(def.displayName) == "string" and #def.displayName > 0, base .. ": has displayName")
	check(RARITIES[def.rarity] == true, base .. ": rarity is one of the five tiers")
	check(PHASES[def.dayNight] == true, base .. ": dayNight is day/night/any")
	check(type(def.seedPrice) == "number" and def.seedPrice > 0, base .. ": seedPrice > 0")
	check(type(def.sellValue) == "number" and def.sellValue > 0, base .. ": sellValue > 0 (crop sellable)")
	check(type(def.growthTimeSec) == "number" and def.growthTimeSec > 0, base .. ": growthTimeSec > 0")
end

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
	error(string.format("economy_config.spec: %d failing assertion(s)", failures))
end
print("✅ economy_config.spec passed")
