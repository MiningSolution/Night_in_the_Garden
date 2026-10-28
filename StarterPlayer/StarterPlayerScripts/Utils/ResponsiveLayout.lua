--[[
	ResponsiveLayout.lua
	Location: StarterPlayer/StarterPlayerScripts/Utils (ModuleScript)

	Pure layout math for the mobile UI (feature 001). No Roblox services are
	touched here so the module can be unit-tested offline with the Luau CLI
	(Tools/Tests/responsive_layout.spec.luau).

	`compute(input) -> result` turns the viewport, the ScreenGui safe-area rect
	and the current input mode into Offset rects for the menu column, the hotbar,
	the free area and each window. See specs/001-mobile-ui-access/data-model.md
	and research.md R3/R5 for the constants and the derivation.

	All rects are {x, y, w, h} in ScreenGui (Offset) coordinates.
]]

local ResponsiveLayout = {}

-- Reference constants (Offset units), research R3.
local MENU_BUTTON = 56
local MENU_GAP = 8
local MENU_LEFT_MARGIN = 12
local MENU_CAPACITY = 4 -- room for Shop, Inventory, Rewards, Quests (FR-001)

local HOTBAR_SLOTS = 3
local HOTBAR_TOUCH_SLOT = 64
local HOTBAR_TOUCH_GAP = 8
local HOTBAR_BOTTOM_MARGIN = 12
-- Keyboard / gamepad hotbar keeps today's geometry.
local HOTBAR_DESKTOP_W = 340
local HOTBAR_DESKTOP_H = 110
local HOTBAR_DESKTOP_BOTTOM = 20

local FREE_MARGIN = 12 -- gap from the menu column / right edge to the free area
local FREE_TOP = 8
local FREE_HOTBAR_GAP = 8

local PHONE_SHORT_SIDE = 500 -- min(viewport side) <= this => phone (R3)

-- Jump-button fallback offsets from the right edge when no live TouchGui rect is
-- supplied (research R5). `inset` is the distance from the viewport right edge to
-- the button's LEFT edge; `size` is the square button size.
local JUMP_SMALL = { inset = 95, size = 70 }
local JUMP_LARGE = { inset = 170, size = 120 }

-- Window aspect / maximum size. Single source of truth for both this module and
-- WindowManager.Register (constitution II); read it, never re-type the numbers.
ResponsiveLayout.WINDOWS = {
	Shop = { aspect = 1.85, maxW = 960, maxH = 520 },
	Inventory = { aspect = 1.4, maxW = 700, maxH = 500 },
}

local function rectsIntersect(a, b)
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
ResponsiveLayout.rectsIntersect = rectsIntersect

-- Largest rect of the given aspect (w/h) that fits inside (maxW x maxH) and the
-- per-window size cap, then centred in `area`.
local function fitWindow(area, heightCap, aspect, capW, capH)
	local height = math.min(heightCap, area.h)
	local width = height * aspect
	if width > area.w then
		width = area.w
		height = width / aspect
	end
	if width > capW then
		width = capW
		height = width / aspect
	end
	if height > capH then
		height = capH
		width = height * aspect
	end
	return {
		x = area.x + (area.w - width) / 2,
		y = area.y + (area.h - height) / 2,
		w = width,
		h = height,
	}
end

--[[
	input = {
		viewport = {w, h},             -- camera viewport size
		gui = {x, y, w, h},            -- ScreenGui absolute position/size (safe area)
		mode = "Touch"|"KeyboardMouse"|"Gamepad",
		jump = {x, y, w, h} | nil,     -- live jump-button rect, viewport coords
		windows = { [name] = {aspect, maxW, maxH} } | nil,  -- defaults to WINDOWS
	}
]]
function ResponsiveLayout.compute(input)
	local vp = input.viewport
	local gui = input.gui
	local mode = input.mode or "KeyboardMouse"
	local isTouch = mode == "Touch"
	local isPhone = math.min(vp.w, vp.h) <= PHONE_SHORT_SIDE
	local windows = input.windows or ResponsiveLayout.WINDOWS

	-- Menu column: fixed-size vertical strip at the left, vertically centred.
	local menuHeight = MENU_CAPACITY * MENU_BUTTON + (MENU_CAPACITY - 1) * MENU_GAP
	local menuColumn = {
		x = gui.x + MENU_LEFT_MARGIN,
		y = gui.y + (gui.h - menuHeight) / 2,
		w = MENU_BUTTON,
		h = menuHeight,
		buttonSize = MENU_BUTTON,
		gap = MENU_GAP,
	}

	-- Hotbar.
	local hotbar
	if isTouch then
		local w = HOTBAR_SLOTS * HOTBAR_TOUCH_SLOT + (HOTBAR_SLOTS - 1) * HOTBAR_TOUCH_GAP
		-- Horizontal gap between the thumbstick zone (left 40% of the viewport)
		-- and the jump button (right side); centre the hotbar in it (R5).
		local thumbRight = gui.x + vp.w * 0.40
		local jumpLeft
		if input.jump then
			jumpLeft = input.jump.x
		else
			local fallback = isPhone and JUMP_SMALL or JUMP_LARGE
			jumpLeft = gui.x + vp.w - fallback.inset
		end
		local center = (thumbRight + jumpLeft) / 2
		local x = center - w / 2
		-- Keep inside the safe area if the gap is tight.
		x = math.max(gui.x, math.min(x, gui.x + gui.w - w))
		hotbar = {
			x = x,
			y = gui.y + gui.h - HOTBAR_TOUCH_SLOT - HOTBAR_BOTTOM_MARGIN,
			w = w,
			h = HOTBAR_TOUCH_SLOT,
			slotSize = HOTBAR_TOUCH_SLOT,
			gap = HOTBAR_TOUCH_GAP,
		}
	else
		hotbar = {
			x = gui.x + (gui.w - HOTBAR_DESKTOP_W) / 2,
			y = gui.y + gui.h - HOTBAR_DESKTOP_H - HOTBAR_DESKTOP_BOTTOM,
			w = HOTBAR_DESKTOP_W,
			h = HOTBAR_DESKTOP_H,
			slotSize = 100,
			gap = 10,
		}
	end

	-- Free area for windows: right of the menu column, above the hotbar.
	local freeArea = {
		x = menuColumn.x + menuColumn.w + FREE_MARGIN,
		y = gui.y + FREE_TOP,
	}
	freeArea.w = (gui.x + gui.w - FREE_MARGIN) - freeArea.x
	freeArea.h = (hotbar.y - FREE_HOTBAR_GAP) - freeArea.y

	-- Window rects.
	local out = {}
	for name, spec in pairs(windows) do
		local heightCap = 0.85 * freeArea.h
		if not isPhone then
			heightCap = math.min(heightCap, 0.6 * gui.h)
		end
		out[name] = fitWindow(freeArea, heightCap, spec.aspect, spec.maxW, spec.maxH)
	end

	return {
		isPhone = isPhone,
		isTouch = isTouch,
		menuColumn = menuColumn,
		hotbar = hotbar,
		freeArea = freeArea,
		windows = out,
	}
end

return ResponsiveLayout
