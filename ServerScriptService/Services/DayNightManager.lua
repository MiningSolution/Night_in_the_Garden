-- DayNightManager.lua
local RS = game:GetService("ReplicatedStorage")
local GameSettings = require(RS:WaitForChild("GameSettings"))
local DayNightUpdate = RS:WaitForChild("DayNightUpdate")
local SpiritManager = require(script.Parent:WaitForChild("Spirit"):WaitForChild("SpiritManager"))

local M = {}

-- Current phase as module state so other services can query it (feature 002, R3).
-- PlantGrowthService reads this to gate night-plant growth (FR-007).
M.currentPhase = "Day"

-- Returns "Day" or "Night".
function M.GetPhase()
    return M.currentPhase
end

function M.Start()
    M.currentPhase = "Day"
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
