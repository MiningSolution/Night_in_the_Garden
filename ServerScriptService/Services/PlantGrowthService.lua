-- PlantGrowthService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
local PlantData = require(RS:WaitForChild("PlantData"))
local DayNightManager = require(script.Parent:WaitForChild("DayNightManager"))
local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")

local M = {}

-- P0-4: Protection against multiple Start() calls (memory leak fix)
local growthThread = nil
local isRunning = false

-- Feature 002 (FR-002/FR-007, R3): growth is accrued into a per-plot accumulator
-- `GrowthSeconds`, advanced by the real elapsed time each tick ONLY when the
-- plant's dayNight allows the current phase. Night plants (dayNight == "night")
-- pause during the day; day/any plants always advance.
local function plantGrowsNow(plant, phase)
    if plant.dayNight == "night" then
        return phase == "Night"
    end
    return true -- "day" or "any"
end

local function updatePlayerPlots(plr, dt, phase)
    local data = PlayerData.Get(plr); if not data then return end
    for plotId, plot in pairs(data.Plots) do
        if plot.State == "Planted" or plot.State == "Growing" then
            local plant = PlantData[plot.PlantId or ""]
            if plant then
                local total = plant.growthTimeSec or 120
                plot.GrowthSeconds = plot.GrowthSeconds or 0
                if plantGrowsNow(plant, phase) then
                    plot.GrowthSeconds = math.min(total, plot.GrowthSeconds + dt)
                end
                local progress = math.clamp(plot.GrowthSeconds / total, 0, 1)
                plot.GrowthProgress = progress

                if progress >= 1 then
                    plot.State = "ReadyToHarvest"
                    plot.IsWatered = false
                    PlotStateChanged:FireClient(plr, plotId, plot)
                    local snap = PlayerData.Snapshot(plr)
                    PlotStateUpdated:FireClient(plr, {PlotId=plotId, Success=true, Snapshot=snap})
                else
                    -- Feature 003 (US5): persist the "Growing" state (it was only ever
                    -- sent transiently before, so the stored state stayed "Planted" and
                    -- watering — which requires plot.State == "Growing" — could never
                    -- succeed). Planting still rejects non-empty plots and harvest still
                    -- requires "ReadyToHarvest", so this only unblocks watering.
                    plot.State = "Growing"
                    local timeRemaining = math.max(0, math.floor(total - plot.GrowthSeconds))
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
        local lastTick = tick()
        while isRunning do
            task.wait(1)
            local now = tick()
            local dt = now - lastTick
            lastTick = now
            local phase = DayNightManager.GetPhase()

            for _, plr in ipairs(Players:GetPlayers()) do
                local success, err = pcall(function()
                    updatePlayerPlots(plr, dt, phase)
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
