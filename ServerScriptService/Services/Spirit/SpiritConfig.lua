-- SpiritConfig.lua
-- P2-1: Configuration module for Spirit system
-- Centralized configuration loaded from GameSettings

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))

local M = {}

-- Load config from GameSettings or use defaults
local SpiritCfg = GameSettings.SpiritSettings or {
    MaxActive = 8,
    SpawnIntervalSec = 6,
    DespawnAfterSec = 90,
    SpawnRadius = 60,
    LanternSpawnRadius = 20,
    LanternAnchorWeight = 3,
    MinY = -5,
    MaxY = 50,
    PlayerCollectCooldownSec = 1.0,
    CollectDistance = 10,
    RewardMin = 1,
    RewardMax = 3,
    Colors = {
        Common = Color3.fromRGB(160, 200, 255),
        Uncommon = Color3.fromRGB(120, 220, 140),
        Rare = Color3.fromRGB(180, 120, 255),
        Epic = Color3.fromRGB(255, 200, 120),
        Legendary = Color3.fromRGB(255, 220, 120),
    }
}

-- Export config values
M.MaxActive = SpiritCfg.MaxActive
M.SpawnIntervalSec = SpiritCfg.SpawnIntervalSec
M.DespawnAfterSec = SpiritCfg.DespawnAfterSec
M.SpawnRadius = SpiritCfg.SpawnRadius
-- feature 006 (US1): lantern draws spirits to the equipped player.
M.LanternSpawnRadius = SpiritCfg.LanternSpawnRadius or 20
M.LanternAnchorWeight = SpiritCfg.LanternAnchorWeight or 3
M.MinY = SpiritCfg.MinY
M.MaxY = SpiritCfg.MaxY
M.PlayerCollectCooldownSec = SpiritCfg.PlayerCollectCooldownSec
M.CollectDistance = SpiritCfg.CollectDistance
M.RewardMin = SpiritCfg.RewardMin
M.RewardMax = SpiritCfg.RewardMax
M.Colors = SpiritCfg.Colors

-- Helper function to get color by rarity
function M.GetColor(rarity)
    return M.Colors[rarity] or Color3.fromRGB(160, 200, 255)
end

return M

