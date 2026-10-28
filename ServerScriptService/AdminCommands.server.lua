-- ServerScriptService/AdminCommands.lua
local Players = game:GetService("Players")
local Services = script.Parent:WaitForChild("Services")
local SpiritManager = require(Services:WaitForChild("Spirit"):WaitForChild("SpiritManager"))

local ADMINS = { -- укажи свои UserId
    1234567890,
}

local function isAdmin(p)
    for _, id in ipairs(ADMINS) do
        if p.UserId == id then return true end
    end
    return false
end

local function onCommand(player, message)
    if not isAdmin(player) then return end
    local cmd, arg = message:match("^/(%w+)%s*(.*)$")
    if cmd == "spawnspirit" then
        SpiritManager.SpawnOnce(arg ~= "" and arg or nil)
    elseif cmd == "cleanspirits" then
        SpiritManager.SetPhaseNight(false)
        SpiritManager.SetPhaseNight(true)
    end
end

-- Players.PlayerChatted needs the LocalUser capability and fails on the server;
-- Player.Chatted works per player.
local function hook(player)
    player.Chatted:Connect(function(message) onCommand(player, message) end)
end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do hook(p) end

print("[SPIRIT][ADMIN] commands ready: /spawnspirit [id], /cleanspirits")
