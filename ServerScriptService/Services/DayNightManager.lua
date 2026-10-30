-- DayNightManager.lua
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameSettings = require(RS:WaitForChild("GameSettings"))
local DayNightUpdate = RS:WaitForChild("DayNightUpdate")
local SpiritManager = require(script.Parent:WaitForChild("Spirit"):WaitForChild("SpiritManager"))

local M = {}

-- Current phase as module state so other services can query it (feature 002, R3).
-- PlantGrowthService reads this to gate night-plant growth (FR-007).
M.currentPhase = "Day"

-- Garden World Kit bridge: mirror the active phase into
-- ReplicatedStorage.NITG_WorldState (Phase + PhaseEndsAt) so the kit's client
-- lighting adapter (GardenLighting) reacts to our single clock. We stay the only
-- phase authority here; the kit's optional GardenCycle.server is intentionally unused.
local WORLD_STATE_NAME = "NITG_WorldState"
local function ensureWorldState()
    local state = RS:FindFirstChild(WORLD_STATE_NAME)
    if not state then
        state = Instance.new("Folder")
        state.Name = WORLD_STATE_NAME
        state.Parent = RS
    end
    return state
end
local function publishPhase(state, phase)
    local duration = (phase == "Day") and GameSettings.DayLengthSec or GameSettings.NightLengthSec
    state:SetAttribute("Phase", phase)
    state:SetAttribute("PhaseEndsAt", Workspace:GetServerTimeNow() + duration)
end

-- Returns "Day" or "Night".
function M.GetPhase()
    return M.currentPhase
end

function M.Start()
    M.currentPhase = "Day"
    local worldState = ensureWorldState()
    publishPhase(worldState, M.currentPhase)
    -- P1-1: Use tick() for monotonic time (won't jump if system time changes)
    local start = tick()

    while true do
        task.wait(1)
        local phase = M.currentPhase
        local duration = (phase=="Day") and GameSettings.DayLengthSec or GameSettings.NightLengthSec
        -- P1-1: Monotonic time calculation
        local elapsed = tick() - start
        local progress = elapsed / duration
        DayNightUpdate:FireAllClients(phase, progress)

        if progress >= 1 then
            -- P1-1: Reset with monotonic time
            start = tick()
            M.currentPhase = (phase=="Day") and "Night" or "Day"
            publishPhase(worldState, M.currentPhase)
            -- Phase change: notify SpiritManager
            if M.currentPhase == "Night" then
                SpiritManager.SetPhaseNight(true)
            else
                SpiritManager.SetPhaseNight(false)
            end
        end
    end
end
task.spawn(M.Start)
return M
