--[[
	InputActions.lua
	Location: StarterPlayer/StarterPlayerScripts/Utils (ModuleScript)

	The one action layer for feature 001 (FR-013). Every Phase 1 action is
	defined once and bound for keyboard, touch and gamepad through
	ContextActionService, and the module tracks the current input mode so the
	controls can show key labels, gamepad glyphs or nothing.

	Phase 1 / US1 scope implemented here:
	  - input-mode detection (Touch | KeyboardMouse | Gamepad) with ModeChanged
	  - the always-on actions ToggleShop (B / ButtonX) and ToggleInventory
	    (I / ButtonY), delegating to WindowManager

	Window-scoped actions (CloseWindow on B), hotbar cycling (L1/R1) and the
	per-mode hint swapping are added by US3 and US5.
]]

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local WindowManager = require(script.Parent:WaitForChild("WindowManager"))

local function hotbarController()
	return require(script.Parent.Parent.Controllers:WaitForChild("HotbarController"))
end

local InputActions = {}

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

InputActions.ModeChanged = newSignal() -- (newMode, oldMode)

local currentMode = nil

local function modeForInputType(inputType)
	local T = Enum.UserInputType
	if inputType == T.Touch then
		return "Touch"
	elseif inputType == T.Keyboard
		or inputType == T.MouseButton1
		or inputType == T.MouseButton2
		or inputType == T.MouseButton3
		or inputType == T.MouseMovement
		or inputType == T.MouseWheel then
		return "KeyboardMouse"
	elseif inputType.Name and string.sub(inputType.Name, 1, 7) == "Gamepad" then
		return "Gamepad"
	end
	return nil -- Accelerometer, Gyro, TextInput, Focus, ... leave mode unchanged
end

local function setMode(newMode)
	if not newMode or newMode == currentMode then
		return
	end
	local old = currentMode
	currentMode = newMode
	InputActions.ModeChanged:Fire(currentMode, old)
end

function InputActions.GetMode()
	return currentMode
end

-- Window-scoped actions: bound only while a window is open, so gamepad B keeps
-- its default behaviour otherwise (US3, FR-009/FR-013a). Driven by the
-- WindowManager.Changed subscription in Init.
function InputActions.BindWindowActions()
	ContextActionService:BindActionAtPriority(
		"NightGarden_CloseWindow",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				WindowManager.Close()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.ButtonB
	)
end
function InputActions.UnbindWindowActions()
	ContextActionService:UnbindAction("NightGarden_CloseWindow")
end

local function bindAlwaysActions()
	ContextActionService:BindActionAtPriority(
		"NightGarden_ToggleShop",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				WindowManager.Toggle("Shop")
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.B,
		Enum.KeyCode.ButtonX
	)

	ContextActionService:BindActionAtPriority(
		"NightGarden_ToggleInventory",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				WindowManager.Toggle("Inventory")
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.I,
		Enum.KeyCode.ButtonY
	)

	-- Gamepad hotbar cycling (L1/R1), wrapping at the ends (FR-013a).
	ContextActionService:BindActionAtPriority(
		"NightGarden_HotbarPrev",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				hotbarController().PreviousSlot()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.ButtonL1
	)
	ContextActionService:BindActionAtPriority(
		"NightGarden_HotbarNext",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				hotbarController().NextSlot()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.ButtonR1
	)
end

-- US5 (R9): show key labels in KeyboardMouse mode, gamepad glyphs in Gamepad
-- mode (images from UserInputService:GetImageForKeyCode), neither on Touch.
local function applyHints(mode)
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local hudc = pg and pg:FindFirstChild("HUDControls")
	if not hudc then return end
	local isKbd = mode == "KeyboardMouse"
	local isPad = mode == "Gamepad"

	local function setButton(btn, padKey)
		if not btn then return end
		local kh = btn:FindFirstChild("KeyHint")
		local ph = btn:FindFirstChild("PadHint")
		if kh then kh.Visible = isKbd end
		if ph then
			ph.Visible = isPad
			if isPad then ph.Image = UserInputService:GetImageForKeyCode(padKey) end
		end
	end

	local menu = hudc:FindFirstChild("MenuButtons")
	if menu then
		setButton(menu:FindFirstChild("ShopButton"), Enum.KeyCode.ButtonX)
		setButton(menu:FindFirstChild("InventoryButton"), Enum.KeyCode.ButtonY)
	end

	local hotbar = hudc:FindFirstChild("Hotbar")
	if hotbar then
		for i = 1, 3 do
			local slot = hotbar:FindFirstChild("Slot" .. i)
			local kbh = slot and slot:FindFirstChild("KeybindHint")
			if kbh then kbh.Visible = isKbd end
		end
		local pl = hotbar:FindFirstChild("PadHintLeft")
		local pr = hotbar:FindFirstChild("PadHintRight")
		if pl then
			pl.Visible = isPad
			if isPad then pl.Image = UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonL1) end
		end
		if pr then
			pr.Visible = isPad
			if isPad then pr.Image = UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonR1) end
		end
	end
end

local initialized = false

function InputActions.Init()
	if initialized then
		return
	end
	initialized = true

	-- Initial mode.
	local last = UserInputService:GetLastInputType()
	local mode = modeForInputType(last)
	if not mode then
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
			mode = "Touch"
		else
			mode = "KeyboardMouse"
		end
	end
	currentMode = mode

	UserInputService.LastInputTypeChanged:Connect(function(inputType)
		setMode(modeForInputType(inputType))
	end)

	bindAlwaysActions()

	-- Hints follow the active input mode (US5, FR-015).
	applyHints(currentMode)
	InputActions.ModeChanged:Connect(applyHints)

	-- Bind the window-scoped gamepad B close only while a window is open.
	WindowManager.Changed:Connect(function(openName)
		if openName then
			InputActions.BindWindowActions()
		else
			InputActions.UnbindWindowActions()
		end
	end)

	print("✅ InputActions ready (mode:", currentMode, ")")
end

return InputActions
