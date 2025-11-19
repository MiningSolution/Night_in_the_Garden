-- InventoryService.lua
-- Server-side inventory and equipped tool tracking
-- Prevents clients from using tools they don't own

local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))

local M = {}

-- Track equipped tools per player
local equippedTools = {} -- [player] = toolName

--[[
    Set equipped tool for player (called when player equips tool)
    @param player (Player) - The player
    @param toolName (string) - Tool name to equip
    @return boolean - Success status
]]
function M.SetEquipped(player, toolName)
    if not player or not player.Parent then
        return false
    end
    
    if type(toolName) ~= "string" then
        return false
    end
    
    -- Validate player has this tool/item
    -- For tools like watering cans, check if they exist in inventory
    -- For seeds, check if they exist in inventory
    if toolName:match("_seed$") then
        -- It's a seed - check if player has it
        if not PlayerData.HasItem(player, toolName, 1) then
            warn(string.format("[InventoryService] %s tried to equip seed they don't have: %s", player.Name, toolName))
            return false
        end
    elseif toolName == "basic_watering_can" or toolName == "improved_watering_can" then
        -- Watering cans - check if player has them
        if not PlayerData.HasItem(player, toolName, 1) then
            warn(string.format("[InventoryService] %s tried to equip tool they don't have: %s", player.Name, toolName))
            return false
        end
    elseif toolName == "Harvest" then
        -- Harvest is always available (no item needed)
        -- Allow it
    else
        -- Unknown tool type - validate it exists in inventory
        if not PlayerData.HasItem(player, toolName, 1) then
            warn(string.format("[InventoryService] %s tried to equip unknown tool: %s", player.Name, toolName))
            return false
        end
    end
    
    equippedTools[player] = toolName
    return true
end

--[[
    Get currently equipped tool for player
    @param player (Player) - The player
    @return string - Tool name (defaults to basic_watering_can if none equipped)
]]
function M.GetEquipped(player)
    if not player or not player.Parent then
        return "basic_watering_can"
    end
    
    return equippedTools[player] or "basic_watering_can"
end

--[[
    Clear equipped tool when player leaves
]]
local Players = game:GetService("Players")
Players.PlayerRemoving:Connect(function(player)
    equippedTools[player] = nil
end)

return M

