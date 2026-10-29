--[[
	UITheme.lua
	Location: ReplicatedStorage (ModuleScript)

	The single colour + style vocabulary for the game UI (constitution principle V).
	Two palettes — Day ("cosy garden") and Night ("moonlit") — plus the structural
	tokens (outlines, gradients, display font) that give the UI its "juicy" look.

	How the two palettes reach the screen:
	  * STATIC GUI (build time): the builders (Tools/StaticGui/builders/*.luau) read the
	    global `UI_THEME`, which is THIS module. The flat keys on the module are the
	    Night palette, so the baked StarterGui/*.model.json rests in the Night look.
	  * RUNTIME (live switch): builders also bake a `Theme_<Property> = "<Token>"`
	    attribute next to each themed property. On the `DayNightUpdate` phase change,
	    ThemeController resolves each attribute through `UITheme.Resolve(token, phase)`
	    and tweens the element to the active palette — no model regeneration.

	Back-compat: existing code that reads `UITheme.Surface`, `UITheme.Coins`, etc.
	still gets the Night value (the flat keys below ARE the Night palette plus a few
	legacy aliases), so screens not yet re-skinned keep working unchanged.
]]

-- Use the real Roblox globals in Studio (and the generator's mocks at build time);
-- fall back to a plain-table stub so the offline test can `require` this module under
-- plain luau, where `Color3`/`Enum` do not exist. Behaviour is identical in Roblox.
local Color3 = Color3 or { fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end }
local Enum = Enum or setmetatable({}, { __index = function()
	return setmetatable({}, { __index = function(_, n) return { Name = n } end })
end })

local function c(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- ---------------------------------------------------------------------------
-- Palettes. Every token MUST exist in BOTH palettes (parity-tested in
-- Tools/Tests/theme.spec.luau). Values: specs/004-visual-style/contracts/theme-tokens.md.
-- ---------------------------------------------------------------------------

local Night = {
	-- Surfaces
	Surface = c(17, 31, 59),        -- panel / window background (deep indigo)
	SurfaceRaised = c(32, 51, 77),  -- raised tiles / cards

	-- Text
	TextPrimary = c(245, 244, 233),
	TextMuted = c(185, 201, 223),
	TextOnBright = c(32, 28, 16),   -- dark text on bright gold fills (e.g. coin pill)
	TextOnAccent = c(245, 244, 233),-- light label on a primary (Accent) button
	TextOnHeader = c(245, 244, 233),-- light title on the dark header gradient

	-- Interactive controls
	Control = c(42, 64, 96),        -- neutral / secondary button at rest
	ControlHover = c(54, 80, 116),  -- neutral button hover / focus

	-- Semantic actions
	Accent = c(22, 107, 179),       -- primary action / confirm / selection (blue by night)
	AccentDeep = c(16, 69, 116),    -- primary-button gradient bottom + 3D shadow
	Positive = c(90, 200, 120),     -- seed / garden "grow" semantic (always green)
	Sell = c(214, 140, 60),         -- sell / stall action (always orange)
	Danger = c(224, 96, 96),        -- destructive / error (red)

	-- Currency gold (counter, "+N coins" float, prices)
	Coins = c(255, 218, 123),
	-- Dream Seeds currency (cool blue; the game's existing second currency)
	Dream = c(150, 190, 255),

	-- Window backdrop (full-screen dim behind an open window)
	Backdrop = c(4, 10, 22),

	-- Rarity tiers
	RarityCommon = c(150, 162, 182),
	RarityUncommon = c(90, 200, 120),
	RarityRare = c(143, 211, 255),
	RarityEpic = c(212, 173, 255),
	RarityLegendary = c(255, 218, 123),

	-- Structural / design-language colours
	Outline = c(64, 94, 132),       -- card / tile stroke
	OutlineDeep = c(6, 23, 46),     -- window / header stroke
	HeaderTop = c(21, 55, 104),     -- header gradient top
	HeaderBottom = c(11, 31, 66),   -- header gradient bottom
}

local Day = {
	-- Surfaces
	Surface = c(255, 243, 213),     -- cream / parchment
	SurfaceRaised = c(234, 219, 185),

	-- Text
	TextPrimary = c(48, 42, 28),
	TextMuted = c(104, 91, 66),
	TextOnBright = c(32, 28, 16),
	TextOnAccent = c(245, 244, 233),-- light label on a primary (Accent) button
	TextOnHeader = c(245, 244, 233),-- light title on the dark header gradient

	-- Interactive controls
	Control = c(219, 205, 174),
	ControlHover = c(240, 229, 204),

	-- Semantic actions
	Accent = c(43, 146, 31),        -- primary action (green by day)
	AccentDeep = c(24, 102, 21),
	Positive = c(43, 146, 31),
	Sell = c(196, 110, 30),
	Danger = c(200, 60, 55),

	-- Currency gold
	Coins = c(150, 100, 12),
	-- Dream Seeds currency (deep blue, readable on cream)
	Dream = c(40, 90, 170),

	-- Backdrop
	Backdrop = c(20, 16, 10),

	-- Rarity tiers
	RarityCommon = c(110, 102, 86),
	RarityUncommon = c(43, 146, 31),
	RarityRare = c(16, 92, 166),
	RarityEpic = c(113, 49, 163),
	RarityLegendary = c(121, 80, 10),

	-- Structural / design-language colours
	Outline = c(197, 178, 134),
	OutlineDeep = c(36, 69, 35),
	HeaderTop = c(35, 107, 41),
	HeaderBottom = c(18, 69, 28),
}

-- ---------------------------------------------------------------------------
-- Module table: the flat Night palette (back-compat) + palettes + resolver + style.
-- ---------------------------------------------------------------------------

local UITheme = {}

-- Flat keys = Night palette (so `UITheme.Surface` etc. keep returning the night value).
for k, v in pairs(Night) do
	UITheme[k] = v
end

-- Legacy aliases still referenced by screens not yet re-skinned (kept = Night look).
UITheme.Header = Night.HeaderTop            -- old solid header bar colour
UITheme.BannerNight = c(40, 50, 92)         -- nightfall banner background (feature 003)
UITheme.BackdropTransparency = 0.5

-- Palettes + default phase.
UITheme.Palettes = { Day = Day, Night = Night }
UITheme.DefaultPhase = "Night"

-- Non-colour style constants (single source; not per-palette).
UITheme.Style = {
	OutlineThickness = 3,          -- UIStroke on cards / tiles
	WindowOutlineThickness = 4,    -- UIStroke on windows / headers
	ButtonShadowOffset = 4,        -- px the AccentDeep 3D "ledge" sits below a button
	CornerRadius = 14,             -- px, chunky rounded corners
	BackdropTransparency = 0.5,
	-- Clean bold sans to match the mock-up (Inter-like), not a cartoon rounded face.
	DisplayFont = Enum.Font.GothamBold,
	BodyFont = Enum.Font.Gotham,
}

-- Resolve a token name to its Color3 for a phase. Unknown phase falls back to Night;
-- unknown token returns nil (callers skip it).
function UITheme.Resolve(token, phase)
	local palette = UITheme.Palettes[phase] or Night
	return palette[token]
end

return UITheme
