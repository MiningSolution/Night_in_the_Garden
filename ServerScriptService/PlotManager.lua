
local RS=game:GetService("ReplicatedStorage"); local SSS=game:GetService("ServerScriptService")
local PlayerData=require(SSS:WaitForChild("PlayerDataManager")); local PlantData=require(RS:WaitForChild("PlantData"))
local PlotStateChanged=RS:WaitForChild("PlotStateChanged"); local PlotStateUpdated=RS:WaitForChild("PlotStateUpdated")
local M={} local function ok(t)t=t or{};t.Success=true;return t end local function fail(m)return{Success=false,Error=tostring(m or"Error")}end
local function parseTool(n) n=tostring(n or""); if n=="WateringCan" or n=="basic_watering_can" then return{type="water"} end if n:match("^Seed_") then return{type="seed",plantId=n:gsub("^Seed_",""):lower()} end return{type="unknown"} end
function M.HandleInteraction(p,plotModel,toolName)
 if typeof(plotModel)~="Instance" then return fail("No target") end
 local plotId=plotModel.Name; local tool=parseTool(toolName); local plot=PlayerData.GetPlot(p,plotId)
 if tool.type=="seed" and tool.plantId then if plot.State~="Empty" then return fail("Plot not empty") end local key=tool.plantId.."_seed"; if not PlayerData.HasItem(p,key,1) then return fail("No seed") end
  PlayerData.TryConsumeItem(p,key,1); plot.State="Planted"; plot.PlantId=tool.plantId; plot.PlantedAt=os.time(); plot.GrowthProgress=0; plot.IsWatered=false
 elseif tool.type=="water" then if plot.State~="Planted" and plot.State~="Growing" then return fail("Nothing to water") end plot.IsWatered=true; plot.LastWatered=os.time(); plot.State="Growing"
 else if plot.State~="ReadyToHarvest" then return fail("Not ripe") end local crop=(plot.PlantId or"carrot").."_crop"; PlayerData.AddItem(p,crop,1); plot.State="Empty"; plot.PlantId=nil; plot.GrowthProgress=0 end
 local snap=PlayerData.Snapshot(p); PlotStateChanged:FireClient(p,plotId,plot); PlotStateUpdated:FireClient(p,{PlotId=plotId,Success=true,Snapshot=snap}); return ok({PlotId=plotId,Plot=plot,Snapshot=snap})
end
return M
