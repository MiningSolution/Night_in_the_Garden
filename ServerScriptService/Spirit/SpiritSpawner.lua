-- SpiritSpawner.lua
-- P2-1: Handles spirit spawning logic

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local Config = require(script.Parent.SpiritConfig)
local Types = require(script.Parent.SpiritTypes)

local M = {}

local GRID_SIZE = 50
local spatialGrid = {}

M.activeSpirits = {} -- [id] = {model, type, spawnedAt}
local spiritFolder = nil

--[[
    Ensure spirit folder exists in workspace
]]
local function ensureFolder()
    if not spiritFolder or not spiritFolder.Parent then
        local f = Instance.new("Folder")
        f.Name = "SpiritFolder"
        f.Parent = workspace
        spiritFolder = f
    end
    return spiritFolder
end

--[[
    Get random position near any player
    @return Vector3 - Random position
]]
local function getRandomXZ(center, radius)
    local ang = math.random() * math.pi * 2
    local r = math.random() * radius
    local yOffset = math.random(-5, 15) -- Add vertical variety
    return Vector3.new(
        center.X + math.cos(ang) * r, 
        center.Y + yOffset, 
        center.Z + math.sin(ang) * r
    )
end

--[[
    Get position of any random player
    @return Vector3 - Player position or default
]]
local function getAnyPlayerPosition()
    local list = Players:GetPlayers()
    if #list == 0 then 
        return Vector3.new(0, 5, 0) 
    end
    
    local p = list[math.random(1, #list)]
    local char = p.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then 
        return hrp.Position 
    end
    
    return Vector3.new(0, 5, 0)
end

--[[
    Clamp Y position to valid range
    @param pos (Vector3) - Position
    @return Vector3 - Clamped position
]]
local function clampY(pos)
    local y = math.clamp(pos.Y, Config.MinY, Config.MaxY)
    return Vector3.new(pos.X, y, pos.Z)
end

-- P2-2: Get grid key from position
local function getGridKey(position)
    local x = math.floor(position.X / GRID_SIZE)
    local z = math.floor(position.Z / GRID_SIZE)
    return string.format("%d,%d", x, z)
end

-- P2-2: Add spirit to spatial grid
local function addToGrid(spiritId, position)
    local key = getGridKey(position)
    if not spatialGrid[key] then
        spatialGrid[key] = {}
    end
    table.insert(spatialGrid[key], spiritId)
end

-- P2-2: Remove spirit from spatial grid
local function removeFromGrid(spiritId, position)
    local key = getGridKey(position)
    if not spatialGrid[key] then return end
    
    for i, id in ipairs(spatialGrid[key]) do
        if id == spiritId then
            table.remove(spatialGrid[key], i)
            break
        end
    end
    
    -- Clean up empty grid cells
    if #spatialGrid[key] == 0 then
        spatialGrid[key] = nil
    end
end

--[[
    Check if position is too close to existing spirits (P2-2: Optimized with spatial grid)
    @param pos (Vector3) - Position to check
    @param minDistance (number) - Minimum distance required
    @return boolean - True if too close
]]
function M.isPositionOccupied(pos, minDistance)
    minDistance = minDistance or 15
    local key = getGridKey(pos)
    
    -- Check current cell
    if spatialGrid[key] then
        for _, spiritId in ipairs(spatialGrid[key]) do
            local spirit = M.activeSpirits[spiritId]
            if spirit and spirit.model:FindFirstChild("Orb") then
                local dist = (spirit.model.Orb.Position - pos).Magnitude
                if dist < minDistance then
                    return true
                end
            end
        end
    end
    
    -- Check adjacent cells (3x3 grid)
    local x = math.floor(pos.X / GRID_SIZE)
    local z = math.floor(pos.Z / GRID_SIZE)
    
    for dx = -1, 1 do
        for dz = -1, 1 do
            if dx ~= 0 or dz ~= 0 then -- Skip center (already checked)
                local adjKey = string.format("%d,%d", x + dx, z + dz)
                if spatialGrid[adjKey] then
                    for _, spiritId in ipairs(spatialGrid[adjKey]) do
                        local spirit = M.activeSpirits[spiritId]
                        if spirit and spirit.model:FindFirstChild("Orb") then
                            local dist = (spirit.model.Orb.Position - pos).Magnitude
                            if dist < minDistance then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    return false
end

--[[
    Build spirit model with visual effects
    @param spiritType (table) - Spirit type data
    @return Model, ProximityPrompt - Created model and prompt
]]
local function buildSpiritModel(spiritType)
    local mdl = Instance.new("Model")
    mdl.Name = spiritType.displayName

    local orb = Instance.new("Part")
    orb.Name = "Orb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(1.6, 1.6, 1.6)
    orb.Anchored = true
    orb.CanCollide = false
    orb.Color = Config.GetColor(spiritType.rarity)
    orb.Material = Enum.Material.Neon
    orb.Parent = mdl

    local a = Instance.new("Attachment")
    a.Name = "FX"
    a.Parent = orb

    -- Gentle sparkle particle effect
    local particle = Instance.new("ParticleEmitter")
    particle.Rate = 6
    particle.Lifetime = NumberRange.new(0.6, 1.1)
    particle.Speed = NumberRange.new(0.2, 0.8)
    particle.Size = NumberSequence.new({ 
        NumberSequenceKeypoint.new(0, 0.15), 
        NumberSequenceKeypoint.new(1, 0) 
    })
    particle.LightEmission = 0.7
    particle.Parent = a

    -- ProximityPrompt (server-owned)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CollectPrompt"
    prompt.ActionText = "Soothe Spirit"
    prompt.ObjectText = spiritType.displayName .. " (" .. spiritType.rarity .. ")"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0.35
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.UIOffset = Vector2.new(0, 50)
    prompt.Parent = orb

    mdl.PrimaryPart = orb
    return mdl, prompt
end

--[[
    Spawn one spirit
    @param onCollectCallback (function) - Callback when spirit is collected
    @return string - Spirit ID or nil if failed
]]
function M.spawnOne(onCollectCallback)
    ensureFolder()

    -- Check max active limit
    local count = 0
    for _ in pairs(M.activeSpirits) do 
        count = count + 1 
    end
    
    if count >= Config.MaxActive then 
        return nil 
    end

    local spiritType = Types.ChooseRandom()
    local id = HttpService:GenerateGUID(false)

    -- Spawn near any player with anti-clustering
    local center = getAnyPlayerPosition()
    local pos = clampY(getRandomXZ(center, Config.SpawnRadius))
    
    -- P2-4: Use constant from Constants
    local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Constants"))
    
    -- Retry if too close to existing spirits
    local attempts = 0
    while M.isPositionOccupied(pos, Constants.SPIRIT.MIN_SPAWN_DISTANCE) and attempts < Constants.SPIRIT.SPAWN_ATTEMPTS do
        pos = clampY(getRandomXZ(center, Config.SpawnRadius))
        attempts = attempts + 1
    end
    
    if attempts >= Constants.SPIRIT.SPAWN_ATTEMPTS then
        warn("[SpiritSpawner] Failed to find free spawn position after 5 attempts")
        return nil
    end

    local model, prompt = buildSpiritModel(spiritType)
    model:SetPrimaryPartCFrame(CFrame.new(pos))
    model.Parent = spiritFolder

    M.activeSpirits[id] = { 
        model = model, 
        spawnedAt = tick(), 
        type = spiritType 
    }
    
    -- P2-2: Add to spatial grid
    if model:FindFirstChild("Orb") then
        addToGrid(id, model.Orb.Position)
    end

    -- Handle prompt on server
    if onCollectCallback then
        prompt.Triggered:Connect(function(player)
            onCollectCallback(player, id, model, spiritType)
        end)
    end

    -- TTL cleanup
    Debris:AddItem(model, Config.DespawnAfterSec)

    print(string.format("[SpiritSpawner] Spawned %s @ (%.1f, %.1f, %.1f)", 
        spiritType.id, pos.X, pos.Y, pos.Z))
    
    return id
end

--[[
    Check if can spawn more spirits
    @return boolean - True if can spawn
]]
function M.canSpawn()
    local count = 0
    for _ in pairs(M.activeSpirits) do 
        count = count + 1 
    end
    return count < Config.MaxActive
end

--[[
    Remove spirit from active list (P2-2: Also removes from spatial grid)
    @param id (string) - Spirit ID
]]
function M.removeSpirit(id)
    local spirit = M.activeSpirits[id]
    if spirit and spirit.model:FindFirstChild("Orb") then
        -- P2-2: Remove from spatial grid
        removeFromGrid(id, spirit.model.Orb.Position)
    end
    M.activeSpirits[id] = nil
end

--[[
    Cleanup all spirits (P2-2: Also clears spatial grid)
]]
function M.cleanupAll()
    for id, rec in pairs(M.activeSpirits) do
        if rec.model then
            rec.model:Destroy()
        end
        M.activeSpirits[id] = nil
    end
    
    -- P2-2: Clear spatial grid
    spatialGrid = {}
end

--[[
    Get active spirit by ID
    @param id (string) - Spirit ID
    @return table - Spirit data or nil
]]
function M.getSpirit(id)
    return M.activeSpirits[id]
end

return M

