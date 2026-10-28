--[[
	WindowManager.lua
	Location: StarterPlayer/StarterPlayerScripts/Utils (ModuleScript)

	Owns the single open window for feature 001. At most one window (Shop,
	Inventory; later Rewards, Quests) is open at a time (FR-003). Opening and
	closing flip `ScreenGui.Enabled` immediately, with no tween to wait on, so
	repeated presses cannot leave a half-open or doubled state (FR-017, SC-006).

	Backdrop / gamepad-selection wiring is added by later user stories (US3, US5);
	this module only owns the open-window state and the enable/disable + onOpen.

	Window spec (see data-model.md > Window):
		{ gui = ScreenGui, frame = Frame, closeButton = TextButton?,
		  aspect = number, maxSize = Vector2, onOpen = () -> ()? }
]]

local WindowManager = {}

-- Minimal signal (no external dependency).
local function newSignal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return {
				Disconnect = function()
					for i, h in ipairs(handlers) do
						if h == fn then
							table.remove(handlers, i)
							break
						end
					end
				end,
			}
		end,
		Fire = function(_, ...)
			for _, fn in ipairs(table.clone(handlers)) do
				task.spawn(fn, ...)
			end
		end,
	}
end

local windows = {} -- [name] = spec
local openWindow = nil -- nil | name

WindowManager.Changed = newSignal() -- (openName?, previousName?)

function WindowManager.Register(name, spec)
	assert(type(name) == "string", "WindowManager.Register: name must be a string")
	assert(spec and spec.gui, "WindowManager.Register: spec.gui is required")
	windows[name] = spec
	spec.gui.Enabled = false

	-- US3: tapping the dim backdrop closes the window (FR-008). The close (X)
	-- button is already wired by the window's controller to UIController, which
	-- delegates here. A window-scoped gamepad B close is bound by InputActions.
	if spec.backdrop then
		spec.backdrop.Activated:Connect(function()
			WindowManager.Close()
		end)
	end
end

function WindowManager.GetOpen()
	return openWindow
end

function WindowManager.Open(name)
	local spec = windows[name]
	if not spec then
		warn("⚠️ WindowManager.Open: unknown window", name)
		return
	end
	if openWindow == name then
		return
	end

	local previous = openWindow
	-- Close any other open window first (immediate).
	if previous and windows[previous] then
		windows[previous].gui.Enabled = false
	end

	openWindow = name
	spec.gui.Enabled = true
	if spec.onOpen then
		local ok, err = pcall(spec.onOpen)
		if not ok then
			warn("⚠️ WindowManager onOpen for", name, "failed:", err)
		end
	end

	WindowManager.Changed:Fire(openWindow, previous)
end

function WindowManager.Close()
	if not openWindow then
		return
	end
	local previous = openWindow
	local spec = windows[previous]
	if spec then
		spec.gui.Enabled = false
	end
	openWindow = nil
	WindowManager.Changed:Fire(nil, previous)
end

function WindowManager.Toggle(name)
	if openWindow == name then
		WindowManager.Close()
	else
		WindowManager.Open(name)
	end
end

return WindowManager
