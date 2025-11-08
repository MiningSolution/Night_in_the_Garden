
local RS=game:GetService("ReplicatedStorage"); local SSS=game:GetService("ServerScriptService"); local Players=game:GetService("Players"); local RunService=game:GetService("RunService")
local PlayerData=require(SSS:WaitForChild("PlayerDataManager")); local PlantData=require(RS:WaitForChild("PlantData"))
local PlotStateChanged=RS:WaitForChild("PlotStateChanged"); local PlotStateUpdated=RS:WaitForChild("PlotStateUpdated")
local STEP,acc=1.0,0
RunService.Heartbeat:Connect(function(dt) acc+=dt; if acc<STEP then return end; acc=0
 for _,plr in ipairs(Players:GetPlayers()) do local data=PlayerData.Get(plr) if data and data.Plots then
  for plotId,plot in pairs(data.Plots) do if plot.State=="Planted" or plot.State=="Growing" then local info=PlantData[plot.PlantId or""] if info then
    plot.State="Growing"; local gt=info.growthTimeSec or 120; local delta=(plot.IsWatered and 2 or 1)*(1/gt)
    plot.GrowthProgress=math.clamp((plot.GrowthProgress or 0)+delta,0,1)
    if plot.GrowthProgress>=1 then plot.State="ReadyToHarvest"; plot.IsWatered=false; PlotStateChanged:FireClient(plr,plotId,plot); local snap=PlayerData.Snapshot(plr); PlotStateUpdated:FireClient(plr,{PlotId=plotId,Success=true,Snapshot=snap}) end
  end end end end end)
