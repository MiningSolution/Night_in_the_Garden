-- SpiritCollector.lua
-- P2-1: Handles spirit collection logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.SpiritConfig)
local PlayerData = require(script.Parent.Parent.PlayerDataManager)

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

    -- Calculate and give reward
    local amount = M.calculateReward(spiritType)
    local newBalance = PlayerData.AddDreamSeeds(player, amount)

    -- Update currency (async)
    if UpdateCurrency then
        UpdateCurrency:FireClient(player, "DreamSeeds", newBalance or 0)
    end

    -- Client feedback with spirit type and amount
    if SpiritCollected then
        SpiritCollected:FireClient(player, spiritType.displayName, spiritType.rarity, amount)
    end

    -- Stats (optional)
    if PlayerData.IncrementStat then
        PlayerData.IncrementStat(player, "TotalSpiritsCollected", 1)
    end

    -- Mark as collected (cooldown)
    cooldowns[player.UserId] = tick()

    -- Remove from active list
    if removeSpirit then
        removeSpirit(spiritId)
    end

    -- Cleanup instance
    spirit:Destroy()

    print(string.format("[SpiritCollector] %s collected %s (+%d DreamSeeds)", 
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

