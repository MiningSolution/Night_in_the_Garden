--!nocheck
--[[
	Offline tests for UITheme (feature 004-visual-style): palette parity,
	back-compat flat fields, resolver, WCAG contrast and rarity distinguishability.

	Run:  luau Tools/Tests/theme.spec.luau
]]

-- UITheme builds Color3 / Enum values at load time; mock them for plain luau.
Color3 = {
	fromRGB = function(r, g, b)
		return { R = r / 255, G = g / 255, B = b / 255 }
	end,
}
Enum = setmetatable({}, {
	__index = function()
		return setmetatable({}, {
			__index = function(_, n)
				return { Name = n }
			end,
		})
	end,
})

local UITheme = require("../../ReplicatedStorage/UITheme")

local failures = 0
local checks = 0
local function check(cond: boolean, msg: string)
	checks += 1
	if not cond then
		failures += 1
		print("  ✗ " .. msg)
	end
end

local function isColor(v): boolean
	return type(v) == "table" and type(v.R) == "number" and type(v.G) == "number" and type(v.B) == "number"
end

local function sameColor(a, b): boolean
	return isColor(a) and isColor(b) and a.R == b.R and a.G == b.G and a.B == b.B
end

-- 1. Parity
local Day, Night = UITheme.Palettes.Day, UITheme.Palettes.Night
check(type(Day) == "table", "Palettes.Day exists")
check(type(Night) == "table", "Palettes.Night exists")
for k in pairs(Day) do
	check(Night[k] ~= nil, "Night defines token " .. tostring(k))
end
for k in pairs(Night) do
	check(Day[k] ~= nil, "Day defines token " .. tostring(k))
end

-- 2. Every value is a colour
for name, palette in pairs({ Day = Day, Night = Night }) do
	for k, v in pairs(palette) do
		check(isColor(v), name .. "." .. tostring(k) .. " is a colour")
	end
end

-- 3. Default phase
check(UITheme.DefaultPhase == "Night", "DefaultPhase == Night")

-- 4. Back-compat flat fields
for k, v in pairs(Night) do
	check(sameColor(UITheme[k], v), "flat UITheme." .. tostring(k) .. " equals Night value")
end

-- 5. Style table
check(type(UITheme.Style) == "table", "UITheme.Style is a table")
for _, key in ipairs({
	"CornerRadius", "OutlineThickness", "WindowOutlineThickness", "ButtonShadowOffset",
	"DisplayFont", "BodyFont", "BackdropTransparency",
}) do
	check(type(UITheme.Style) == "table" and UITheme.Style[key] ~= nil, "Style." .. key .. " defined")
end

-- 6. Resolver
check(sameColor(UITheme.Resolve("Surface", "Day"), Day.Surface), "Resolve(Surface, Day) == Day.Surface")
check(sameColor(UITheme.Resolve("Surface", "Night"), Night.Surface), "Resolve(Surface, Night) == Night.Surface")
check(sameColor(UITheme.Resolve("Surface", "bogus"), Night.Surface), "Resolve(Surface, bogus) falls back to Night")

-- 7. WCAG contrast
local function lin(c: number): number
	if c <= 0.03928 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(col): number
	return 0.2126 * lin(col.R) + 0.7152 * lin(col.G) + 0.0722 * lin(col.B)
end
local function contrast(a, b): number
	local l1, l2 = luminance(a), luminance(b)
	return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05)
end

-- Body text / currency numbers: WCAG AA normal (>= 4.5:1).
local bodyPairs = {
	{ "TextPrimary", "Surface" },
	{ "TextPrimary", "SurfaceRaised" },
	{ "TextPrimary", "Control" },
	{ "TextPrimary", "ControlHover" },
	{ "TextMuted", "Surface" },
	{ "Coins", "Surface" },
}
-- Large bold display text (button labels, header titles): WCAG AA large (>= 3:1).
local displayPairs = {
	{ "TextOnAccent", "Accent" },
	{ "TextOnHeader", "HeaderBottom" },
	{ "TextOnHeader", "HeaderTop" },
}
local function checkPairs(list, bar)
	for _, phase in ipairs({ "Day", "Night" }) do
		local palette = UITheme.Palettes[phase]
		for _, p in ipairs(list) do
			local fg, bg = palette[p[1]], palette[p[2]]
			if isColor(fg) and isColor(bg) then
				local ratio = contrast(fg, bg)
				check(ratio >= bar, string.format("%s: %s on %s %.2f:1 >= %.1f", phase, p[1], p[2], ratio, bar))
			else
				check(false, string.format("%s: %s on %s missing token", phase, p[1], p[2]))
			end
		end
	end
end
checkPairs(bodyPairs, 4.5)
checkPairs(displayPairs, 3.0)

-- 8. Rarity distinguishability
local rarities = { "RarityCommon", "RarityUncommon", "RarityRare", "RarityEpic", "RarityLegendary" }
for _, phase in ipairs({ "Day", "Night" }) do
	local palette = UITheme.Palettes[phase]
	for i = 1, #rarities do
		for j = i + 1, #rarities do
			local a, b = palette[rarities[i]], palette[rarities[j]]
			if isColor(a) and isColor(b) then
				local dR, dG, dB = a.R - b.R, a.G - b.G, a.B - b.B
				local d = dR * dR + dG * dG + dB * dB
				check(d >= 0.02, string.format("%s: %s vs %s distance %.4f >= 0.02", phase, rarities[i], rarities[j], d))
			else
				check(false, string.format("%s: %s vs %s missing token", phase, rarities[i], rarities[j]))
			end
		end
	end
end

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
	error(string.format("theme.spec: %d failure(s)", failures))
end
print("✅ theme.spec passed")
