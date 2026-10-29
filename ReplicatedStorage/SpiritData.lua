--[[
	SpiritData.lua
	Location: ReplicatedStorage (ModuleScript)

	Feature 006 (Stage 2): the single source of truth for spirit-type metadata
	(constitution II). The server spirit system (ServerScriptService/Services/Spirit)
	reads this catalog for spawning and capture; the client Spirit Journal reads it to
	list EVERY known type, including ones the player has not caught yet (undiscovered).

	Exposing this metadata to the client is safe: it is static content (names, rarities,
	spawn weights, catch chances), NOT live gameplay state. Catch outcomes and rewards
	are still decided and applied only on the server.

	Each entry:
	  id            stable key (matches the spawned model's SpiritId)
	  displayName   shown in feedback / Journal / Spirits cards
	  rarity        one of the five tiers (badge colour + chance tier)
	  weight        weighted spawn pick
	  reward        proximity per-collect DreamSeeds (0 = use SpiritConfig range); wisps only
	  captureMethod "proximity" (wisps, walk-up collect) | "net" (new flying creatures)
	  catchChance   net only: P(success) per attempt, 0..1 (rarer = lower)
	  firstCatchBonus one-time discovery reward (DreamSeeds) on the first catch; 0 = none

	Numbers are transcribed from specs/006-redesign-stage2/balance.md
	(checked by Tools/Tests/spirit_config.spec.luau). No Roblox globals are used here so
	the module stays requirable under the plain luau CLI for the offline spec.
]]

local SpiritData = {}

-- The five rarity tiers used across the game (matches PlantData / ShopConfig).
SpiritData.Rarities = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true }

SpiritData.Types = {
	-- Existing wisps (unchanged behaviour: proximity collect, DreamSeeds via config range).
	{ id = "wisp_common", displayName = "Wisp",         rarity = "Common", weight = 70, reward = 0, captureMethod = "proximity" },
	{ id = "wisp_rare",   displayName = "Bright Wisp",  rarity = "Rare",   weight = 25, reward = 0, captureMethod = "proximity" },
	{ id = "wisp_epic",   displayName = "Ancient Wisp", rarity = "Epic",   weight = 5,  reward = 0, captureMethod = "proximity" },
	-- New night creatures (feature 006, US2): caught only with the net, by a rarity-based chance.
	{ id = "moonmoth",    displayName = "Moonmoth",     rarity = "Uncommon", weight = 22, reward = 0, captureMethod = "net", catchChance = 0.60, firstCatchBonus = 30 },
	{ id = "moth_spirit", displayName = "Moth-Spirit",  rarity = "Rare",     weight = 10, reward = 0, captureMethod = "net", catchChance = 0.40, firstCatchBonus = 60 },
}

--[[ Find a spirit type by id. ]]
function SpiritData.FindById(id)
	for _, t in ipairs(SpiritData.Types) do
		if t.id == id then
			return t
		end
	end
	return nil
end

--[[
	Pure capture roll: succeed when `roll` (a number in [0,1), e.g. math.random())
	is below the type's `chance`. Kept pure (no RNG, no Roblox) so it is deterministic
	and offline-testable; the caller supplies the roll.
	@param chance number 0..1
	@param roll number in [0,1)
	@return boolean success
]]
function SpiritData.rollCatch(chance, roll)
	chance = tonumber(chance) or 0
	if chance <= 0 then return false end
	if chance >= 1 then return true end
	return (tonumber(roll) or 0) < chance
end

return SpiritData
