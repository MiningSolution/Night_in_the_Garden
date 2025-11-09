-- DayNightManager.lua
local RS = game:GetService("ReplicatedStorage")
local GameSettings = require(RS:WaitForChild("GameSettings"))
local DayNightUpdate = RS:WaitForChild("DayNightUpdate")
local SpiritManager = require(script.Parent:WaitForChild("Spirit"):WaitForChild("SpiritManager"))

local M = {}
function M.Start()
    local phase = "Day"
    -- P1-1: Use tick() for monotonic time (won't jump if system time changes)
    local start = tick()
    
    while true do
        task.wait(1)
        local duration = (phase=="Day") and GameSettings.DayLengthSec or GameSettings.NightLengthSec
        -- P1-1: Monotonic time calculation
        local elapsed = tick() - start
        local progress = elapsed / duration
        DayNightUpdate:FireAllClients(phase, progress)
        
        if progress >= 1 then
            -- P1-1: Reset with monotonic time
            start = tick()
            phase = (phase=="Day") and "Night" or "Day"
            -- Phase change: notify SpiritManager
            if phase == "Night" then
                SpiritManager.SetPhaseNight(true)
            else
                SpiritManager.SetPhaseNight(false)
            end
        end
    end
end
task.spawn(M.Start)
return M
