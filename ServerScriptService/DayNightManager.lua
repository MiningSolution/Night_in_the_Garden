-- DayNightManager.lua
local RS = game:GetService("ReplicatedStorage")
local GameSettings = require(RS:WaitForChild("GameSettings"))
local DayNightUpdate = RS:WaitForChild("DayNightUpdate")

local M = {}
function M.Start()
    local phase = "Day"
    local start = os.clock()
    while true do
        task.wait(1)
        local duration = (phase=="Day") and GameSettings.DayLengthSec or GameSettings.NightLengthSec
        local elapsed = os.clock() - start
        local progress = elapsed / duration
        DayNightUpdate:FireAllClients(phase, progress)
        if progress >= 1 then
            phase = (phase=="Day") and "Night" or "Day"
            start = os.clock()
        end
    end
end
task.spawn(M.Start)
return M
