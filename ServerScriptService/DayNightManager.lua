-- DayNightManager.lua
local RS = game:GetService("ReplicatedStorage")
local GameSettings = require(RS:WaitForChild("GameSettings"))
local DayNightUpdate = RS:WaitForChild("DayNightUpdate")
local SpiritManager = require(script.Parent:WaitForChild("SpiritManager"))

local M = {}
function M.Start()
    local phase = "Day"
    local start = os.time() -- Use os.time() for game time, not os.clock()
    while true do
        task.wait(1)
        local duration = (phase=="Day") and GameSettings.DayLengthSec or GameSettings.NightLengthSec
        local elapsed = os.time() - start -- Use os.time() consistently
        local progress = elapsed / duration
        DayNightUpdate:FireAllClients(phase, progress)
        if progress >= 1 then
            start = os.time() -- Use os.time() consistently
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
