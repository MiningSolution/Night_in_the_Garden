-- GardenLighting.client.lua
-- Garden World Kit visual adapter (LocalScript). Visual only: it grants no items
-- or rewards and runs no phase clock. It reacts to ReplicatedStorage.NITG_WorldState
-- (Phase), which DayNightManager publishes from the single server clock.
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local root=workspace:WaitForChild("NITG_GardenWorld",20)
if not root then warn("Insert NITG_GardenWorld first"); return end
-- In a project with an Atmosphere, reuse it instead of stacking atmospheres.
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then atmosphere=Instance.new("Atmosphere"); atmosphere.Name="NITG_Atmosphere"; atmosphere.Parent=Lighting end
local bloom=Lighting:FindFirstChild("NITG_Bloom")
if not bloom then bloom=Instance.new("BloomEffect"); bloom.Name="NITG_Bloom"; bloom.Parent=Lighting end
bloom.Intensity=.13; bloom.Size=20; bloom.Threshold=1.4
local tagged={}
local function register(obj)
 if obj:GetAttribute("NITGWarmGlow") or obj:GetAttribute("NITGMoonGlow") or obj:GetAttribute("NITGFirefly") or obj:GetAttribute("NITGNightLight") then tagged[obj]=true end
end
for _,obj in ipairs(root:GetDescendants()) do register(obj) end
local night=false
local function styleObject(obj)
 if obj:IsA("PointLight") then obj.Enabled=night; return end
 if not obj:IsA("BasePart") then return end
 if obj:GetAttribute("NITGFirefly") then
  obj.Transparency=night and .12 or 1
  obj.Material=night and Enum.Material.Neon or Enum.Material.SmoothPlastic
 else obj.Material=night and Enum.Material.Neon or Enum.Material.SmoothPlastic end
end
local function apply(phase)
 night=phase=="Night"
 Lighting.ClockTime=night and .5 or 13.5
 Lighting.GlobalShadows=true
 local target=night and {
  Brightness=1.7,Ambient=Color3.fromRGB(57,69,111),OutdoorAmbient=Color3.fromRGB(69,87,128),
  ExposureCompensation=.05,ColorShift_Top=Color3.fromRGB(20,35,66),
 } or {
  Brightness=2.4,Ambient=Color3.fromRGB(134,133,112),OutdoorAmbient=Color3.fromRGB(151,160,140),
  ExposureCompensation=0,ColorShift_Top=Color3.fromRGB(255,237,201),
 }
 TweenService:Create(Lighting,TweenInfo.new(.4),target):Play()
 atmosphere.Density=night and .25 or .2
 atmosphere.Offset=.1; atmosphere.Haze=night and 1.1 or .7; atmosphere.Glare=night and 0 or .08
 atmosphere.Color=night and Color3.fromRGB(115,143,194) or Color3.fromRGB(198,220,230)
 atmosphere.Decay=night and Color3.fromRGB(38,51,87) or Color3.fromRGB(136,158,134)
 for obj in pairs(tagged) do if obj.Parent then styleObject(obj) end end
end
root.DescendantAdded:Connect(function(obj) register(obj); if tagged[obj] then styleObject(obj) end end)
root.DescendantRemoving:Connect(function(obj) tagged[obj]=nil end)
local state=ReplicatedStorage:WaitForChild("NITG_WorldState",10)
if state then
 apply(state:GetAttribute("Phase") or "Day")
 state:GetAttributeChangedSignal("Phase"):Connect(function() apply(state:GetAttribute("Phase") or "Day") end)
else
 -- Static day preview when the phase mirror is absent.
 apply("Day")
 warn("No NITG_WorldState. Static Day preview; connect your phase system to apply().")
end
