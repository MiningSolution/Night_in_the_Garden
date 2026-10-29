--[[
	UITheme.lua
	Location: ReplicatedStorage (ModuleScript)

	Named colour tokens for the game UI. Phase 1 carries only the current dark
	("night") palette; the day palette and runtime switching arrive in Phase 4
	(constitution principle V). New and changed UI elements MUST read their
	colours from these tokens instead of hard-coding Color3 values.

	Both the static GUI builders (Tools/StaticGui/builders/*.luau) and the
	runtime controllers require this module so there is a single source for the
	palette. The offline generator (build_models.py) also loads it and exposes
	it to the builders as the global `UI_THEME`.
]]

local UITheme = {
	-- Surfaces
	Surface = Color3.fromRGB(30, 30, 40),        -- panel / window background
	SurfaceRaised = Color3.fromRGB(40, 40, 50),  -- raised tiles (hotbar slots, cards)
	Header = Color3.fromRGB(36, 36, 48),         -- window header bars

	-- Interactive controls
	Control = Color3.fromRGB(60, 60, 70),        -- buttons at rest
	ControlHover = Color3.fromRGB(70, 70, 80),   -- button hover / focus

	-- Semantic
	Accent = Color3.fromRGB(80, 200, 120),       -- selection / confirm (green)
	Danger = Color3.fromRGB(220, 80, 80),        -- destructive / error (red)

	-- Text
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(200, 200, 200),

	-- Currency (coin gold) — single source for prices and the "+N coins" float.
	Coins = Color3.fromRGB(255, 220, 100),

	-- Rarity tiers (feature 002, dark/night palette only; day palette is Phase 4).
	-- Used by shop cards and sell rows to colour an item by its rarity (FR-008/018).
	RarityCommon = Color3.fromRGB(170, 170, 180),    -- neutral grey
	RarityUncommon = Color3.fromRGB(90, 200, 120),   -- green
	RarityRare = Color3.fromRGB(80, 150, 240),       -- blue
	RarityEpic = Color3.fromRGB(170, 110, 240),      -- purple
	RarityLegendary = Color3.fromRGB(240, 190, 70),  -- gold

	-- Window backdrop (full-screen dim behind an open window)
	Backdrop = Color3.fromRGB(0, 0, 0),
	BackdropTransparency = 0.5,
}

return UITheme
