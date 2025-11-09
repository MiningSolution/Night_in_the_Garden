-- ServerScriptService/SpiritManager.lua
-- Night-only Spirit spawner with safe server-side rewards (DreamSeeds)
-- VERSION: 1.1 (Fixed syntax error + added client feedback)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))

-- RemoteEvent for async currency updates (kept by design)
local UpdateCurrency = ReplicatedStorage:FindFirstChild("UpdateCurrency")
local SpiritCollected = ReplicatedStorage:WaitForChild("SpiritCollected", 5) -- NEW: Client feedback

local M = {}

-- =========================
-- Config (from GameSettings)
-- =========================
local SpiritCfg = GameSettings.SpiritSettings or {
    MaxActive = 8,
    SpawnIntervalSec = 6,
    DespawnAfterSec = 90,
    SpawnRadius = 60,
    MinY = -5,
    MaxY = 50,
    PlayerCollectCooldownSec = 1.0,
    RewardMin = 1,
    RewardMax = 3,
    Colors = {
        Common = Color3.fromRGB(160, 200, 255),
        Rare   = Color3.fromRGB(180, 120, 255),
        Epic   = Color3.fromRGB(255, 200, 120),
    }
}

-- Types of spirits (weights for random spawn)
local SpiritTypes = {
    { id = "wisp_common", displayName = "Wisp", rarity = "Common", weight = 70, reward = 0 },
    { id = "wisp_rare",   displayName = "Bright Wisp", rarity = "Rare",   weight = 25, reward = 0 },
    { id = "wisp_epic",   displayName = "Ancient Wisp",rarity = "Epic",   weight = 5,  reward = 0 },
}

-- Runtime state
local isNight = false
local running = false
local active = {}               -- [id] = { model = Model, spawnedAt = tick(), type=table }
local lastCollect = {}          -- [player.UserId] = timestamp (cooldown)
local spawnHeartbeatConn = nil
local spiritFolder : Folder

-- =========================
-- Utils
-- =========================
local function getSpiritColor(rarity)
    return (SpiritCfg.Colors and SpiritCfg.Colors[rarity]) or Color3.fromRGB(160, 200, 255)
end

local function ensureFolder()
    if not spiritFolder or not spiritFolder.Parent then
        local f = Instance.new("Folder")
        f.Name = "SpiritFolder"
        f.Parent = workspace
        spiritFolder = f
    end
    return spiritFolder
end

local function chooseSpiritType()
    local total = 0
    for _, t in ipairs(SpiritTypes) do total += (t.weight or 1) end
    local roll = math.random(1, total)
    local acc = 0
    for _, t in ipairs(SpiritTypes) do
        acc += (t.weight or 1)
        if roll <= acc then return t end
    end
    return SpiritTypes[1]
end

local function getRandomXZ(center: Vector3, radius: number)
    local ang = math.random() * math.pi * 2
    local r = math.random() * radius
    local yOffset = math.random(-5, 15) -- Add vertical variety
    return Vector3.new(
        center.X + math.cos(ang)*r, 
        center.Y + yOffset, 
        center.Z + math.sin(ang)*r
    )
end

local function getAnyPlayerPosition()
    local list = Players:GetPlayers()
    if #list == 0 then return Vector3.new(0, 5, 0) end
    local p = list[math.random(1, #list)]
    local char = p.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    return Vector3.new(0, 5, 0)
end

local function clampY(pos: Vector3)
    local y = math.clamp(pos.Y, SpiritCfg.MinY or -5, SpiritCfg.MaxY or 50)
    return Vector3.new(pos.X, y, pos.Z)
end

local function withinCollectDistance(player: Player, part: BasePart)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (hrp and part) then return false end
    local distance = SpiritCfg.CollectDistance or 10
    return (hrp.Position - part.Position).Magnitude <= distance
end

local function canCollect(player: Player)
    local now = time()
    local t = lastCollect[player.UserId]
    if not t then return true end
    return (now - t) >= (SpiritCfg.PlayerCollectCooldownSec or 1.0)
end

local function markCollected(player: Player)
    lastCollect[player.UserId] = time()
end

local function calcReward(spiritType)
    if spiritType.reward and spiritType.reward > 0 then
        return spiritType.reward
    end
    local minR = math.max(0, SpiritCfg.RewardMin or 1)
    local maxR = math.max(minR, SpiritCfg.RewardMax or 3)
    return math.random(minR, maxR)
end

-- Anti-clustering: prevent spawning too close to existing spirits
local function tooCloseToExisting(pos)
    for _, rec in pairs(active) do
        if rec.model and rec.model:FindFirstChild("Orb") then
            local orbPos = rec.model.Orb.Position
            if (orbPos - pos).Magnitude < 15 then
                return true
            end
        end
    end
    return false
end

-- =========================
-- Spawn / Collect / Cleanup
-- =========================
local function buildSpiritModel(spiritType)
    local mdl = Instance.new("Model")
    mdl.Name = spiritType.displayName

    local orb = Instance.new("Part")
    orb.Name = "Orb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(1.6, 1.6, 1.6)
    orb.Anchored = true
    orb.CanCollide = false
    orb.Color = getSpiritColor(spiritType.rarity)
    orb.Material = Enum.Material.Neon
    orb.Parent = mdl

    local a = Instance.new("Attachment")
    a.Name = "FX"
    a.Parent = orb

    -- Gentle sparkle
    local particle = Instance.new("ParticleEmitter")
    particle.Rate = 6
    particle.Lifetime = NumberRange.new(0.6, 1.1)
    particle.Speed = NumberRange.new(0.2, 0.8)
    particle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) })
    particle.LightEmission = 0.7
    particle.Parent = a

    -- ProximityPrompt (server-owned)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CollectPrompt"
    prompt.ActionText = "Soothe Spirit"
    prompt.ObjectText = spiritType.displayName .. " (" .. spiritType.rarity .. ")" -- Show rarity
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0.35
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.UIOffset = Vector2.new(0, 50) -- Raise UI above spirit
    prompt.Parent = orb

    mdl.PrimaryPart = orb
    return mdl, prompt
end

local function onCollect(player: Player, spiritId: string, spirit: Model, sType)
    -- Check if spirit is still active (race condition prevention)
    if not active[spiritId] then return end
    
    -- Cooldown
    if not canCollect(player) then return end

    -- Anti-spoof: distance check
    local orb = spirit:FindFirstChild("Orb")
    if not (orb and orb:IsA("BasePart")) then return end
    if not withinCollectDistance(player, orb) then return end
    
    -- Double-check spirit is still active before processing
    if not active[spiritId] then return end

    -- Reward
    local amount = calcReward(sType)
    local newBalance = PlayerData.AddDreamSeeds(player, amount)

    -- Update currency (async)
    if UpdateCurrency then
        UpdateCurrency:FireClient(player, "DreamSeeds", newBalance or 0)
    end

    -- NEW: Client feedback with spirit type and amount
    if SpiritCollected then
        SpiritCollected:FireClient(player, sType.displayName, sType.rarity, amount)
    end

    -- Stats (optional)
    if PlayerData.IncrementStat then
        PlayerData.IncrementStat(player, "TotalSpiritsCollected", 1)
    end

    markCollected(player)

    -- Cleanup instance
    if active[spiritId] then active[spiritId] = nil end
    spirit:Destroy()

    print(string.format("[SPIRIT] %s collected %s (+%d DreamSeeds)", player.Name, sType.id, amount))
end

local function spawnOnce()
    if not isNight then return end
    ensureFolder()

    -- Cap by MaxActive
    local count = 0
    for _ in pairs(active) do count += 1 end
    if count >= (SpiritCfg.MaxActive or 8) then return end

    local spiritType = chooseSpiritType()
    local id = HttpService:GenerateGUID(false)

    -- Spawn near any player with anti-clustering
    local center = getAnyPlayerPosition()
    local pos = clampY(getRandomXZ(center, SpiritCfg.SpawnRadius or 60))
    
    -- Retry if too close to existing spirits
    local attempts = 0
    while tooCloseToExisting(pos) and attempts < 5 do
        pos = clampY(getRandomXZ(center, SpiritCfg.SpawnRadius or 60))
        attempts += 1
    end

    local model, prompt = buildSpiritModel(spiritType)
    model:SetPrimaryPartCFrame(CFrame.new(pos))
    model.Parent = spiritFolder

    active[id] = { model = model, spawnedAt = time(), type = spiritType }

    -- Handle prompt on server
    prompt.Triggered:Connect(function(player)
        onCollect(player, id, model, spiritType)
    end)

    -- TTL cleanup
    Debris:AddItem(model, SpiritCfg.DespawnAfterSec or 90)

    print(string.format("[SPIRIT] spawn %s @ (%.1f, %.1f, %.1f)", spiritType.id, pos.X, pos.Y, pos.Z))
end

local function cleanupAll()
    for id, rec in pairs(active) do
        if rec.model then
            rec.model:Destroy()
        end
        active[id] = nil
    end
end

-- =========================
-- Public API
-- =========================
function M.Start()
    if running then return end
    running = true
    print("[SPIRIT] Start")

    -- spawn loop (lightweight interval via task.spawn)
    task.spawn(function()
        while running do
            if isNight then
                spawnOnce()
            end
            task.wait(SpiritCfg.SpawnIntervalSec or 6)
        end
    end)
end

function M.Stop()
    if not running then return end
    running = false
    cleanupAll()
    print("[SPIRIT] Stop (cleanup)")
end

-- Called by DayNightManager
function M.SetPhaseNight(onNight: boolean)
    isNight = onNight and true or false
    if isNight then
        M.Start()
    else
        M.Stop()
    end
end

-- Admin helper (optional)
function M.SpawnOnce(typeId: string?)
    local t = nil
    if typeId then
        for _, s in ipairs(SpiritTypes) do
            if s.id == typeId then t = s break end
        end
    end
    -- If a specific type provided and found, override chooser temporarily
    if t then
        local old = chooseSpiritType
        chooseSpiritType = function() return t end
        spawnOnce()
        chooseSpiritType = old
    else
        spawnOnce()
    end  -- ✅ FIXED: Added missing "end"
end

-- Clean up cooldowns on player leave
Players.PlayerRemoving:Connect(function(player)
    if lastCollect[player.UserId] then
        lastCollect[player.UserId] = nil
    end
end)

return M