--[[
	ItemEmoji.lua
	Location: ReplicatedStorage (ModuleScript)

	Feature 005 (US4, interim): a single source of per-item emoji glyphs used as the
	icon FALLBACK across the shop, backpack and hotbar until real image icons are
	wired into the config icon fields (PlantData.seedIcon/cropIcon, ShopConfig icon).
	The glyphs are the render-safe ones already proven in the hotbar (feature 002).

	`ItemEmoji.get(itemId)` returns the glyph for an item id, matching a seed/crop by
	its base name (strips the "_seed"/"_crop" suffix), or "" when none is known (the
	caller then shows its letter fallback). No balance data lives here.
]]

local ItemEmoji = {}

-- Exact-id glyphs (tools, special items, the Harvest action).
local BY_ID = {
	basic_watering_can = "💧",
	improved_watering_can = "🚿",
	fertilizer = "🌿",
	dream_dust = "✨",
	Harvest = "🧺",
}

-- Base-plant glyphs: apply to "<base>", "<base>_seed" and "<base>_crop".
local BY_BASE = {
	carrot = "🥕",
	wheat = "🌾",
	tomato = "🍅",
	pumpkin = "🎃",
	moonflower = "🌙",
	starberry = "⭐",
	dreamroot = "💤",
}

function ItemEmoji.get(itemId)
	if not itemId or itemId == "" then
		return ""
	end
	local byId = BY_ID[itemId]
	if byId then
		return byId
	end
	local base = tostring(itemId):gsub("_seed$", ""):gsub("_crop$", "")
	return BY_BASE[base] or ""
end

return ItemEmoji
