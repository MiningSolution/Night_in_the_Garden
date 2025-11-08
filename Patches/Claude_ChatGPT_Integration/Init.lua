
local SSS=game:GetService("ServerScriptService")
require(SSS:WaitForChild("CreateRemotes"))
require(SSS:WaitForChild("PlayerDataManager")).BindPlayerLifecycle()
require(SSS:WaitForChild("DayNightManager"))
require(SSS:WaitForChild("PlantGrowthService"))
require(SSS:WaitForChild("RemoteHandlers"))
print("🌙 Night in the Garden — Server initialized (Claude ↔ ChatGPT integration)")
