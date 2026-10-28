--!strict
--[[
	Offline unit tests for ResponsiveLayout (feature 001).

	Run:  luau Tools/Tests/responsive_layout.spec.luau

	Asserts the data-model invariants for the five reference screens
	(specs/001-mobile-ui-access/data-model.md > LayoutResult, research R3/R5):
	windows inside the free area, no overlap with the menu column / hotbar /
	jump button / thumbstick zone, height caps, aspect and max size, and the
	44x44 minimum tap target.
]]

local RL = require("../../StarterPlayer/StarterPlayerScripts/Utils/ResponsiveLayout")

local EPS = 1.0 -- 1px tolerance (R3: "within a few pixels")
local TOP_BAR = 36 -- Roblox top bar; safe-area height = viewport - 36 (R3)

local failures = 0
local checks = 0
local function check(cond: boolean, msg: string)
	checks += 1
	if not cond then
		failures += 1
		print("  ✗ " .. msg)
	end
end

local function contains(outer, inner, label)
	check(inner.x >= outer.x - EPS, label .. ": left inside")
	check(inner.y >= outer.y - EPS, label .. ": top inside")
	check(inner.x + inner.w <= outer.x + outer.w + EPS, label .. ": right inside")
	check(inner.y + inner.h <= outer.y + outer.h + EPS, label .. ": bottom inside")
end

local function disjoint(a, b, label)
	local overlap = a.x < b.x + b.w - EPS and b.x < a.x + a.w - EPS
		and a.y < b.y + b.h - EPS and b.y < a.y + a.h - EPS
	check(not overlap, label .. ": no overlap")
end

-- Reference screens (viewport) and the active input mode, from R3.
local CASES = {
	{ name = "844x390 phone", w = 844, h = 390, mode = "Touch" },
	{ name = "667x375 phone", w = 667, h = 375, mode = "Touch" },
	{ name = "1024x768 tablet", w = 1024, h = 768, mode = "Touch" },
	{ name = "1920x1080 PC", w = 1920, h = 1080, mode = "KeyboardMouse" },
	{ name = "2560x1080 PC", w = 2560, h = 1080, mode = "KeyboardMouse" },
}

-- Jump-button fallback + thumbstick zone, mirrored from ResponsiveLayout (R5),
-- so the test can verify the touch hotbar avoids both.
local function jumpAndThumb(vp, gui, isPhone)
	local inset = isPhone and 95 or 170
	local size = isPhone and 70 or 120
	local jump = { x = gui.x + vp.w - inset, y = gui.y + gui.h - size, w = size, h = size }
	local thumb = { x = gui.x, y = gui.y + gui.h / 3, w = vp.w * 0.40, h = gui.h * 2 / 3 }
	return jump, thumb
end

for _, c in ipairs(CASES) do
	print("• " .. c.name)
	local vp = { w = c.w, h = c.h }
	local gui = { x = 0, y = TOP_BAR, w = c.w, h = c.h - TOP_BAR }
	local res = RL.compute({ viewport = vp, gui = gui, mode = c.mode })

	-- Phone classification (R3: shorter side <= 500).
	check(res.isPhone == (math.min(c.w, c.h) <= 500), "isPhone correct")

	-- Menu button and (touch) hotbar slot >= 44x44.
	check(res.menuColumn.buttonSize >= 44, "menu button >= 44")
	if c.mode == "Touch" then
		check(res.hotbar.slotSize >= 44, "touch hotbar slot >= 44")
	end

	-- Free area inside the ScreenGui rect.
	contains(gui, res.freeArea, "freeArea in gui")

	-- Touch hotbar clear of the Roblox controls (SC-004).
	if c.mode == "Touch" then
		local jump, thumb = jumpAndThumb(vp, gui, res.isPhone)
		disjoint(res.hotbar, jump, "hotbar vs jump")
		disjoint(res.hotbar, thumb, "hotbar vs thumbstick")
	end

	for name, win in pairs(res.windows) do
		local spec = RL.WINDOWS[name]
		-- Window inside free area inside ScreenGui.
		contains(res.freeArea, win, name .. " in freeArea")
		contains(gui, res.freeArea, name .. " freeArea in gui")
		-- No overlap with the menu column or the hotbar.
		disjoint(win, res.menuColumn, name .. " vs menuColumn")
		disjoint(win, res.hotbar, name .. " vs hotbar")
		-- Aspect and max size.
		check(math.abs(win.w / win.h - spec.aspect) <= 0.01, name .. " aspect == " .. spec.aspect)
		check(win.w <= spec.maxW + EPS, name .. " width <= maxW")
		check(win.h <= spec.maxH + EPS, name .. " height <= maxH")
		-- Height cap.
		local cap = 0.85 * res.freeArea.h
		if not res.isPhone then
			cap = math.min(cap, 0.6 * gui.h)
		end
		check(win.h <= cap + EPS, name .. " height <= cap")
	end
end

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
	error(string.format("responsive_layout.spec: %d failing assertion(s)", failures))
end
print("✅ responsive_layout.spec passed")
