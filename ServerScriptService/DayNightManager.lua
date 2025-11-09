local RS = game:GetService('ReplicatedStorage')
local DayNightUpdate = RS:WaitForChild('DayNightUpdate')
local Settings = require(RS:WaitForChild('GameSettings'))
local DAY_LENGTH = Settings.DAY_LENGTH or 300
local NIGHT_LENGTH = Settings.NIGHT_LENGTH or 180

task.spawn(function()
    local phase = 'Day'
    local start = os.clock()
    while true do
        task.wait(1)
        local duration = (phase=='Day') and DAY_LENGTH or NIGHT_LENGTH
        local progress = (os.clock()-start)/duration
        DayNightUpdate:FireAllClients(phase, math.clamp(progress,0,1))
        if progress >= 1 then
            phase = (phase=='Day') and 'Night' or 'Day'
            start = os.clock()
        end
    end
end)
