--[[
    HarvestHintController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/
    Feature 005, FR-007 (User Story 1, acceptance scenario 5).

    PURPOSE:
    A contextual day-time "Harvest" hint on the HUD. When the player stands near a
    ready-to-harvest plant BY DAY, a themed hint button (HUD.HarvestHint, built by
    Tools/StaticGui/builders/CreateHUD.luau) appears bottom-centre, above the tool
    strip. Tapping it — or pressing F on PC — harvests the nearest ready plot. It is
    hidden at night, when no ready plant is in range, and while a window is open.

    REUSES EXISTING SYSTEMS ONLY (constitution I; no new remotes, no client trust):
      - plot state: StateManager.getAllPlots()[plotId].State == "ReadyToHarvest"
        (fed from the server's PlotStateChanged/PlotStateUpdated via ClientDataCache).
      - proximity:  a throttled Heartbeat range-watch like SellController's STALL_RANGE,
        finding the nearest ready plot within HARVEST_RANGE of the HumanoidRootPart.
      - harvest:    HotbarController equips "Harvest" (EquipTool) then UseTool fires
        InteractWithPlot. The server stays authoritative — it ignores the client tool
        name and uses its own equipped state (and logs a mismatch as a cheat attempt),
        so we equip Harvest first and only then interact.
      - phase:      DayNightUpdate, already handled by UIController.UpdateDayNight.

    DEPENDENCIES:
      - HUD.HarvestHint (TextButton with a KeyHint chip)
      - HotbarController (EquipByItemName / UseTool / GetEquippedTool)
      - StateManager, WindowManager, InputActions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Controllers = script.Parent
local Utils = script.Parent.Parent:WaitForChild("Utils")
local StateManager = require(Utils:WaitForChild("StateManager"))
local WindowManager = require(Utils:WaitForChild("WindowManager"))
local InputActions = require(Utils:WaitForChild("InputActions"))
local HotbarController = require(Controllers:WaitForChild("HotbarController"))

local HarvestHintController = {}

-- studs; comfortably inside the server's plot InteractionDistance (GameSettings = 25)
-- so a hint that is shown always harvests when acted on.
local HARVEST_RANGE = 18
local CHECK_INTERVAL = 0.2 -- s; range-watch cadence (not per frame)
-- Brief suppression after acting so the hint can't re-show / re-fire before the
-- server's "Harvesting" state reaches the client.
local ACT_SUPPRESS = 0.6

local HarvestHint, KeyHint
local currentPhase = "Day"
local currentPlot = nil
local accumulator = 0
local suppressUntil = 0

-- Nearest plot in StateManager whose state is ReadyToHarvest, by world distance.
local function findNearestReadyPlot(fromPos)
    local best, bestDist
    for plotId, data in pairs(StateManager.getAllPlots()) do
        if type(data) == "table" and data.State == "ReadyToHarvest" then
            local model = Workspace:FindFirstChild(plotId)
            if model then
                local ok, pos = pcall(function() return model:GetPivot().Position end)
                if ok then
                    local d = (pos - fromPos).Magnitude
                    if not bestDist or d < bestDist then
                        best, bestDist = model, d
                    end
                end
            end
        end
    end
    return best, bestDist
end

local function hide()
    currentPlot = nil
    if HarvestHint and HarvestHint.Visible then
        HarvestHint.Visible = false
    end
end

local function show(plot)
    currentPlot = plot
    if not HarvestHint then return end
    -- E chip only on PC; tap is the primary path on touch/gamepad (FR-007).
    if KeyHint then
        KeyHint.Visible = InputActions.GetMode() == "KeyboardMouse"
    end
    HarvestHint.Visible = true
end

-- Show only by day, out of windows, near a ready plant.
local function evaluate()
    if os.clock() < suppressUntil then hide(); return end
    if currentPhase ~= "Day" or WindowManager.GetOpen() ~= nil then hide(); return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then hide(); return end
    local plot, dist = findNearestReadyPlot(hrp.Position)
    if plot and dist <= HARVEST_RANGE then
        show(plot)
    else
        hide()
    end
end

local function doHarvest()
    local plot = currentPlot
    if not plot then return end
    -- Equip Harvest first: the server harvests with ITS equipped tool, not the name we
    -- send, and flags a mismatched client tool as suspicious. EquipTool is ordered
    -- before the following InteractWithPlot (same client), so the server sees Harvest.
    if HotbarController.GetEquippedTool() ~= "Harvest" then
        HotbarController.EquipByItemName("Harvest")
    end
    HotbarController.UseTool(plot)
    -- Hide at once so a second tap/press can't re-fire before the state updates.
    suppressUntil = os.clock() + ACT_SUPPRESS
    hide()
end

function HarvestHintController.Init()
    local HUD = playerGui:WaitForChild("HUD")
    HarvestHint = HUD:WaitForChild("HarvestHint", 10)
    if not HarvestHint then
        warn("⚠️ HarvestHintController: HUD.HarvestHint not found")
        return
    end
    KeyHint = HarvestHint:FindFirstChild("KeyHint")
    HarvestHint.Visible = false

    -- On-screen tap (primary path, works on every input type).
    HarvestHint.Activated:Connect(doHarvest)

    -- Keyboard F (PC shortcut, not the only path). F rather than E so it never
    -- clashes with the seller stall's ProximityPrompt, which consumes E.
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F and HarvestHint.Visible and currentPlot then
            doHarvest()
        end
    end)

    -- Phase: seed from current state, then follow DayNightUpdate (same source as
    -- UIController.UpdateDayNight). Hide immediately on nightfall.
    currentPhase = select(1, StateManager.getDayNight()) or "Day"
    task.spawn(function()
        local DayNightUpdate = ReplicatedStorage:WaitForChild("DayNightUpdate", 30)
        if DayNightUpdate then
            DayNightUpdate.OnClientEvent:Connect(function(phase)
                if phase == "Day" or phase == "Night" then
                    currentPhase = phase
                    if currentPhase ~= "Day" then hide() end
                end
            end)
        end
    end)

    -- Keep the E chip in sync if the input mode changes while the hint is shown.
    InputActions.ModeChanged:Connect(function()
        if HarvestHint.Visible and KeyHint then
            KeyHint.Visible = InputActions.GetMode() == "KeyboardMouse"
        end
    end)

    -- Throttled range-watch: evaluate every CHECK_INTERVAL, not per frame.
    RunService.Heartbeat:Connect(function(dt)
        accumulator += dt
        if accumulator < CHECK_INTERVAL then return end
        accumulator = 0
        evaluate()
    end)

    print("✅ HarvestHintController ready (FR-007: day harvest hint)")
end

HarvestHintController.Init()

return HarvestHintController
