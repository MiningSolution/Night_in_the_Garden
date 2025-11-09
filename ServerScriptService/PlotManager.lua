-- PlotManager.lua
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
local PlantData = require(RS:WaitForChild("PlantData"))

local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")

local M = {}

local VALID_PLOT_IDS = { "Plot1","Plot2","Plot3" }
local function isValidPlotId(id)
    for _,v in ipairs(VALID_PLOT_IDS) do if v==id then return true end end
    return false
end

local function ok(payload) payload = payload or {}; payload.Success=true; return payload end
local function fail(msg) return {Success=false, Error=tostring(msg or "Unknown")} end

local function parseSeed(toolName)
    if type(toolName)~="string" then return nil end
    if toolName:match("_seed$") then
        return toolName:gsub("_seed$","")
    end
    return nil
end

function M.HandleInteraction(player, plotModel, toolName)
    if typeof(plotModel) ~= "Instance" then return fail("No target") end
    local plotId = plotModel.Name
    if not isValidPlotId(plotId) then return fail("Invalid plot: "..tostring(plotId)) end

    -- distance check
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local plotPos = plotModel:GetPivot().Position
        if (hrp.Position - plotPos).Magnitude > 25 then
            return fail("Too far from plot")
        end
    end

    local data = PlayerData.Get(player); if not data then return fail("Data not loaded") end
    local plot = PlayerData.GetPlot(player, plotId)
    local seedPlant = parseSeed(toolName)

    -- Watering
    if toolName == "basic_watering_can" or toolName == "improved_watering_can" then
        if plot.State == "Growing" then
            plot.IsWatered = true
            plot.LastWatered = os.time()
            PlotStateChanged:FireClient(player, plotId, plot)
            return ok({Action="Watered"})
        else
            return fail("Nothing to water")
        end
    end

    -- Planting
    if seedPlant then
        local pid = seedPlant
        if not PlantData[pid] then return fail("Unknown plant") end
        if plot.State ~= "Empty" then return fail("Plot is not empty") end
        if not PlayerData.HasItem(player, pid.."_seed", 1) then return fail("No seeds") end

        PlayerData.TryConsumeItem(player, pid.."_seed", 1)
        plot.State = "Planted"
        plot.PlantId = pid
        plot.PlantedAt = os.time()
        plot.GrowthProgress = 0
        plot.IsWatered = false

        PlotStateChanged:FireClient(player, plotId, plot)
        local snap = PlayerData.Snapshot(player)
        PlotStateUpdated:FireClient(player, {PlotId=plotId, Success=true, Snapshot=snap})
        return ok({Action="Planted", PlotId=plotId})
    end

    -- Harvest
    if toolName == "Harvest" then
        if plot.State ~= "ReadyToHarvest" then return fail("Not ripe") end
        local crop = (plot.PlantId or "carrot").."_crop"
        PlayerData.AddItem(player, crop, 1)

        -- Temporary harvest effect
        PlotStateChanged:FireClient(player, plotId, {State="Harvesting", PlantId=plot.PlantId, GrowthProgress=1, IsWatered=false})
        task.wait(0.5)

        plot.State = "Empty"
        plot.PlantId = nil
        plot.GrowthProgress = 0
        plot.IsWatered = false

        PlotStateChanged:FireClient(player, plotId, plot)
        local snap = PlayerData.Snapshot(player)
        PlotStateUpdated:FireClient(player, {PlotId=plotId, Success=true, Snapshot=snap})
        return ok({Action="Harvested", PlotId=plotId})
    end

    return fail("Invalid action")
end

return M
