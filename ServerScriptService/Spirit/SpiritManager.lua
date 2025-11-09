-- SpiritManager.lua
-- P2-1: Main coordinator for Spirit system
-- Uses modular architecture with SpiritSpawner, SpiritCollector, etc.

local Spawner = require(script.Parent.SpiritSpawner)
local Collector = require(script.Parent.SpiritCollector)
local Config = require(script.Parent.SpiritConfig)

local M = {}

local isNight = false
local running = false
local spawnThread = nil

--[[
    Handle spirit collection callback
    @param player (Player) - The player
    @param spiritId (string) - Spirit ID
    @param spirit (Model) - Spirit model
    @param spiritType (table) - Spirit type data
]]
local function onCollect(player, spiritId, spirit, spiritType)
    local isActive = function(id)
        return Spawner.getSpirit(id) ~= nil
    end
    
    local removeSpirit = function(id)
        Spawner.removeSpirit(id)
    end
    
    Collector.tryCollect(player, spiritId, spirit, spiritType, isActive, removeSpirit)
end

--[[
    Start spirit spawning system
]]
function M.Start()
    if running then
        warn("[SpiritManager] Already running!")
        return false
    end
    
    running = true
    print("[SpiritManager] Starting spirit system...")
    
    spawnThread = task.spawn(function()
        while running do
            if isNight and Spawner.canSpawn() then
                Spawner.spawnOne(onCollect)
            end
            task.wait(Config.SpawnIntervalSec)
        end
        print("[SpiritManager] Stopped.")
    end)
    
    return true
end

--[[
    Stop spirit spawning system
]]
function M.Stop()
    if not running then
        return
    end
    
    print("[SpiritManager] Stopping spirit system...")
    running = false
    
    if spawnThread then
        task.cancel(spawnThread)
        spawnThread = nil
    end
    
    Spawner.cleanupAll()
    print("[SpiritManager] Cleanup complete.")
end

--[[
    Set day/night phase
    @param nightTime (boolean) - True if night, false if day
]]
function M.SetPhaseNight(nightTime)
    isNight = nightTime and true or false
    
    if isNight then
        M.Start()
    else
        M.Stop()
    end
end

--[[
    Admin helper: Spawn one spirit manually
    @param typeId (string?) - Optional spirit type ID
]]
function M.SpawnOnce(typeId)
    local spiritType = nil
    
    if typeId then
        local Types = require(script.Parent.SpiritTypes)
        spiritType = Types.FindById(typeId)
    end
    
    if spiritType then
        -- Temporarily override chooser
        local Types = require(script.Parent.SpiritTypes)
        local originalChoose = Types.ChooseRandom
        Types.ChooseRandom = function() return spiritType end
        
        Spawner.spawnOne(onCollect)
        
        Types.ChooseRandom = originalChoose
    else
        Spawner.spawnOne(onCollect)
    end
end

-- Cleanup on game close
game:BindToClose(function()
    M.Stop()
end)

return M

