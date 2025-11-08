
local RS=game:GetService("ReplicatedStorage"); local RunService=game:GetService("RunService")
local GameSettings=require(RS:WaitForChild("GameSettings")); local DayNightUpdate=RS:WaitForChild("DayNightUpdate")
local DAY,NIGHT=GameSettings.DayLengthSec,GameSettings.NightLengthSec local TOTAL=DAY+NIGHT local t,acc=0,0
local function compute(s)local m=s%TOTAL if m<DAY then return"Day",(m/DAY) else local k=m-DAY; return"Night",(k/NIGHT) end end
RunService.Heartbeat:Connect(function(dt) t+=dt; acc+=dt; if acc>=1 then acc=0; local ph,pr=compute(t); DayNightUpdate:FireAllClients(ph,pr) end end)
