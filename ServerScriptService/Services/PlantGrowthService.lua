-- PlantGrowthService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
local PlantData = require(RS:WaitForChild("PlantData"))
local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")

local M = {}

-- P0-4: Protection against multiple Start() calls (memory leak fix)
local growthThread = nil
local isRunning = false

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
    -- P0-4: Prevent multiple starts (memory leak protection)
    if isRunning then 
        warn("[PlantGrowth] Already running! Ignoring duplicate Start() call.")
        return false
    end
    
    isRunning = true
    print("[PlantGrowth] Starting growth service...")
    
    growthThread = task.spawn(function()
        while isRunning do
            task.wait(1)
            
            for _, plr in ipairs(Players:GetPlayers()) do
                local success, err = pcall(function()
                    updatePlayerPlots(plr)
                end)
                
                if not success then
                    warn("[PlantGrowth] Error updating player:", plr.Name, err)
                end
            end
        end
        print("[PlantGrowth] Stopped.")
    end)
    
    return true
end

-- P0-4: Stop function for cleanup
function M.Stop()
    if not isRunning then 
        return 
    end
    
    print("[PlantGrowth] Stopping growth service...")
    isRunning = false
    
    if growthThread then
        task.cancel(growthThread)
        growthThread = nil
    end
end

-- P0-4: Cleanup on game close
game:BindToClose(function()
    M.Stop()
end)

-- Auto-start (only once)
task.spawn(function()
    M.Start()
end)

return M
