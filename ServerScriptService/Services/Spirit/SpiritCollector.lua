-- SpiritCollector.lua
-- P2-1: Handles spirit collection logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.SpiritConfig)
local PlayerData = require(script.Parent.Parent.PlayerDataManager)
-- feature 006 (US2): net gating + the single-source catch roll.
local InventoryService = require(script.Parent.Parent.InventoryService)
local SpiritData = require(ReplicatedStorage:WaitForChild("SpiritData"))

local M = {}

local cooldowns = {} -- [userId] = lastCollectTime

-- RemoteEvents
local UpdateCurrency = ReplicatedStorage:FindFirstChild("UpdateCurrency")
local SpiritCollected = ReplicatedStorage:WaitForChild("SpiritCollected", 5)

--[[
    Check if player can collect (cooldown check)
    @param player (Player) - The player
    @return boolean - True if can collect
]]
function M.canCollect(player)
    if not player or not player.Parent then
        return false
    end
    
    local now = tick()
    local lastTime = cooldowns[player.UserId]
    
    if not lastTime then
        return true
    end
    
    return (now - lastTime) >= Config.PlayerCollectCooldownSec
end

--[[
    Check if player is within collect distance
    @param player (Player) - The player
    @param part (BasePart) - Spirit orb part
    @return boolean - True if within distance
]]
function M.isWithinDistance(player, part)
    if not player or not part then
        return false
    end
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        return false
    end
    
    local distance = (hrp.Position - part.Position).Magnitude
    return distance <= Config.CollectDistance
end

--[[
    Calculate reward for spirit
    @param spiritType (table) - Spirit type data
    @return number - Reward amount
]]
function M.calculateReward(spiritType)
    if spiritType.reward and spiritType.reward > 0 then
        return spiritType.reward
    end
    
    local minR = math.max(0, Config.RewardMin)
    local maxR = math.max(minR, Config.RewardMax)
    return math.random(minR, maxR)
end

--[[
    Try to collect spirit
    @param player (Player) - The player
    @param spiritId (string) - Spirit ID
    @param spirit (Model) - Spirit model
    @param spiritType (table) - Spirit type data
    @param isSpiritActive (function) - Function to check if spirit is still active
    @param removeSpirit (function) - Function to remove spirit from active list
    @return boolean, number - Success status and reward amount
]]
function M.tryCollect(player, spiritId, spirit, spiritType, isSpiritActive, removeSpirit)
    -- Check if spirit is still active (race condition prevention)
    if not isSpiritActive(spiritId) then
        return false, 0
    end
    
    -- Cooldown check
    if not M.canCollect(player) then
        return false, 0
    end

    -- Distance check
    local orb = spirit:FindFirstChild("Orb")
    if not (orb and orb:IsA("BasePart")) then
        return false, 0
    end
    
    if not M.isWithinDistance(player, orb) then
        return false, 0
    end
    
    -- Double-check spirit is still active before processing
    if not isSpiritActive(spiritId) then
        return false, 0
    end

    -- feature 006 (US2): branch by capture method. Wisps keep proximity collection;
    -- the new flying creatures require the net and a server-rolled rarity chance.
    local method = spiritType.captureMethod or "proximity"
    local amount = 0

    if method == "net" then
        -- Must hold the net. No cooldown here — the player just isn't holding the tool.
        if InventoryService.GetEquipped(player) ~= "net" then
            if SpiritCollected then
                SpiritCollected:FireClient(player, spiritType.displayName, spiritType.rarity, 0, "needs_net")
            end
            return false, 0
        end
        -- An attempt is made (cooldown applies whether it lands or not, anti-spam).
        cooldowns[player.UserId] = tick()
        if not SpiritData.rollCatch(spiritType.catchChance, math.random()) then
            if SpiritCollected then
                SpiritCollected:FireClient(player, spiritType.displayName, spiritType.rarity, 0, "missed")
            end
            return false, 0 -- the creature may remain
        end
        -- Caught: a one-time discovery bonus on the FIRST catch of this type.
        local isFirst = PlayerData.RecordSpiritCaught and PlayerData.RecordSpiritCaught(player, spiritType.id)
        if isFirst and (spiritType.firstCatchBonus or 0) > 0 then
            amount = spiritType.firstCatchBonus
            local newBalance = PlayerData.AddDreamSeeds(player, amount)
            if UpdateCurrency then UpdateCurrency:FireClient(player, "DreamSeeds", newBalance or 0) end
        end
    else
        -- Proximity wisps: unchanged DreamSeeds reward + record the collection.
        amount = M.calculateReward(spiritType)
        local newBalance = PlayerData.AddDreamSeeds(player, amount)
        if UpdateCurrency then UpdateCurrency:FireClient(player, "DreamSeeds", newBalance or 0) end
        if PlayerData.RecordSpiritCaught then PlayerData.RecordSpiritCaught(player, spiritType.id) end
        cooldowns[player.UserId] = tick()
    end

    -- Client feedback for a successful catch/collect.
    if SpiritCollected then
        SpiritCollected:FireClient(player, spiritType.displayName, spiritType.rarity, amount, "caught")
    end

    if PlayerData.IncrementStat then
        PlayerData.IncrementStat(player, "TotalSpiritsCollected", 1)
    end

    -- feature 003 (US2): daily quest progress for catching spirits.
    local questOk, QuestService = pcall(require, script.Parent.Parent:WaitForChild("QuestService"))
    if questOk and QuestService then
        QuestService.Track(player, "catch_spirit", 1)
    end

    if removeSpirit then
        removeSpirit(spiritId)
    end
    spirit:Destroy()

    print(string.format("[SpiritCollector] %s caught %s (+%d DreamSeeds)",
        player.Name, spiritType.id, amount))

    return true, amount
end

--[[
    Cleanup cooldowns on player leave
]]
Players.PlayerRemoving:Connect(function(player)
    if cooldowns[player.UserId] then
        cooldowns[player.UserId] = nil
    end
end)

return M

