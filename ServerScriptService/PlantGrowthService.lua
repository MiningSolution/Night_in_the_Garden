-- PlantGrowthService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
local PlantData = require(RS:WaitForChild("PlantData"))
local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")

local M = {}

local function updatePlayerPlots(plr)
    local data = PlayerData.Get(plr); if not data then return end
    for plotId, plot in pairs(data.Plots) do
        if plot.State == "Planted" or plot.State == "Growing" then
            local plant = PlantData[plot.PlantId or ""]
            if plant then
                local elapsed = os.time() - (plot.PlantedAt or os.time())
                local total = plant.growthTimeSec or 120
                local progress = math.clamp(elapsed / total, 0, 1)
                plot.GrowthProgress = progress

                if progress >= 1 then
                    plot.State = "ReadyToHarvest"
                    plot.IsWatered = false
                    PlotStateChanged:FireClient(plr, plotId, plot)
                    local snap = PlayerData.Snapshot(plr)
                    PlotStateUpdated:FireClient(plr, {PlotId=plotId, Success=true, Snapshot=snap})
                else
                    local timeRemaining = math.max(0, math.floor(total - elapsed))
                    local update = {
                        State = "Growing",
                        PlantId = plot.PlantId,
                        GrowthProgress = progress,
                        IsWatered = plot.IsWatered,
                        TimeRemaining = timeRemaining,
                    }
                    PlotStateChanged:FireClient(plr, plotId, update)
                end
            end
        end
    end
end

function M.Start()
    while true do
        task.wait(1)
        for _, plr in ipairs(Players:GetPlayers()) do
            updatePlayerPlots(plr)
        end
    end
end

task.spawn(M.Start)
return M
