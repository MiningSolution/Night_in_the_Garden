-- Init.lua
require(script.Parent:WaitForChild("CreateRemotes"))
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
PlayerData.BindPlayerLifecycle()

require(script.Parent:WaitForChild("RemoteHandlers"))
require(script.Parent:WaitForChild("PlantGrowthService"))
require(script.Parent:WaitForChild("DayNightManager"))

print("[Init] Server initialized")
