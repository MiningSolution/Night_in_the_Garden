-- ServerScriptService/AdminCommands.lua
local Players = game:GetService("Players")
local SpiritManager = require(script.Parent:WaitForChild("SpiritManager"))

local ADMINS = { -- укажи свои UserId
    1234567890,
}

local function isAdmin(p)
    for _, id in ipairs(ADMINS) do
        if p.UserId == id then return true end
    end
    return false
end

Players.PlayerChatted:Connect(function(player, message)
    if not isAdmin(player) then return end
    local cmd, arg = message:match("^/(%w+)%s*(.*)$")
    if cmd == "spawnspirit" then
        SpiritManager.SpawnOnce(arg ~= "" and arg or nil)
    elseif cmd == "cleanspirits" then
        SpiritManager.SetPhaseNight(false)
        SpiritManager.SetPhaseNight(true)
    end
end)

print("[SPIRIT][ADMIN] commands ready: /spawnspirit [id], /cleanspirits")