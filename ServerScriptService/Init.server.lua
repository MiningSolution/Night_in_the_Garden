-- Services folder groups the runtime server modules
local Services = script.Parent:WaitForChild("Services")

require(script.Parent:WaitForChild("CreateRemotes"))
local PlayerData = require(Services:WaitForChild("PlayerDataManager"))
PlayerData.BindPlayerLifecycle()

require(script.Parent:WaitForChild("RemoteHandlers"))
require(Services:WaitForChild("PlantGrowthService"))
require(Services:WaitForChild("DayNightManager"))
require(Services:WaitForChild("StallService")) -- feature 002: seller stall + Sell prompt

print("[Init] Server initialized")
