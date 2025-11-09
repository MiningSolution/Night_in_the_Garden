local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local PlantData = require(RS:WaitForChild('PlantData'))
local PlayerData = require(script.Parent:WaitForChild('PlayerDataManager'))

local PlotStateChanged = RS:WaitForChild('PlotStateChanged')
local PlotStateUpdated = RS:WaitForChild('PlotStateUpdated')

task.spawn(function()
    while true do
        task.wait(1)
        for _, plr in ipairs(Players:GetPlayers()) do
            local data = PlayerData.Get(plr)
            if data then
                for plotId, plot in pairs(data.Plots) do
                    if plot.State == 'Planted' or plot.State == 'Growing' then
                        local info = PlantData[plot.PlantId or '']
                        if info then
                            local elapsed = os.time() - (plot.PlantedAt or os.time())
                            local total = info.growthTimeSec or 60
                            local progress = math.clamp(elapsed / total, 0, 1)
                            plot.GrowthProgress = progress
                            plot.State = (progress >= 1) and 'ReadyToHarvest' or 'Growing'
                            plot.TimeRemaining = math.max(0, total - elapsed)
                            PlotStateChanged:FireClient(plr, plotId, plot)
                        end
                    end
                end
            end
        end
    end
end)
