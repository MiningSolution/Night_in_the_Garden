local RS = game:GetService('ReplicatedStorage')
local PlantData = require(RS:WaitForChild('PlantData'))
local PlayerData = require(script.Parent:WaitForChild('PlayerDataManager'))
local PlotStateChanged = RS:WaitForChild('PlotStateChanged')
local PlotStateUpdated = RS:WaitForChild('PlotStateUpdated')

local VALID_PLOT_IDS = {'Plot1','Plot2','Plot3'}
local function isValidPlotId(id) for _,v in ipairs(VALID_PLOT_IDS) do if v==id then return true end end return false end
local function ok(t) t=t or {}; t.Success=true; return t end
local function fail(msg) return {Success=false, Error=msg} end

local M = {}
function M.HandleInteraction(player, plotModel, toolName)
    if typeof(plotModel) ~= 'Instance' then return fail('No target') end
    local plotId = plotModel.Name
    if not isValidPlotId(plotId) then return fail('Invalid plot: '..tostring(plotId)) end
    local plot = PlayerData.GetPlot(player, plotId)
    toolName = tostring(toolName or '')

    if toolName:match('_seed$') then
        if plot.State ~= 'Empty' then return fail('Plot not empty') end
        local plantId = toolName:gsub('_seed','')
        if not PlantData[plantId] then return fail('Unknown plant') end
        if not PlayerData.TryConsumeItem(player, toolName, 1) then return fail('No seeds') end
        plot.State='Planted'; plot.PlantId=plantId; plot.PlantedAt=os.time(); plot.LastWatered=os.time(); plot.GrowthProgress=0; plot.IsWatered=true; plot.TimeRemaining = PlantData[plantId].growthTimeSec or 60
        PlotStateChanged:FireClient(player, plotId, plot)
        PlotStateUpdated:FireClient(player, {PlotId=plotId, Success=true, Snapshot=PlayerData.Snapshot(player)})
        return ok({PlotId=plotId})
    elseif toolName == 'WateringCan' or toolName == 'basic_watering_can' then
        if plot.State ~= 'Planted' and plot.State ~= 'Growing' then return fail('Nothing to water') end
        plot.IsWatered=true; plot.LastWatered=os.time()
        PlotStateChanged:FireClient(player, plotId, plot)
        return ok({PlotId=plotId})
    elseif toolName == 'Harvest' or toolName == 'HarvestTool' then
        if plot.State ~= 'ReadyToHarvest' then return fail('Not ripe') end
        local cropId = (plot.PlantId or 'carrot') .. '_crop'
        PlayerData.AddItem(player, cropId, 1)
        PlotStateChanged:FireClient(player, plotId, {State='Harvesting', PlantId=plot.PlantId, GrowthProgress=1, IsWatered=false, TimeRemaining=0})
        task.wait(0.5)
        plot.State='Empty'; plot.PlantId=nil; plot.GrowthProgress=0; plot.IsWatered=false; plot.TimeRemaining=nil
        PlotStateChanged:FireClient(player, plotId, plot)
        PlotStateUpdated:FireClient(player, {PlotId=plotId, Success=true, Snapshot=PlayerData.Snapshot(player)})
        return ok({PlotId=plotId})
    end
    return fail('Invalid action')
end
return M
