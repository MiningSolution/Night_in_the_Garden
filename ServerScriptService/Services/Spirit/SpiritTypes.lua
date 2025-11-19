-- SpiritTypes.lua
-- P2-1: Spirit type definitions with weights for random spawn

local M = {}

-- Types of spirits (weights for random spawn)
M.Types = {
    { 
        id = "wisp_common", 
        displayName = "Wisp", 
        rarity = "Common", 
        weight = 70, 
        reward = 0 -- 0 means use config range
    },
    { 
        id = "wisp_rare", 
        displayName = "Bright Wisp", 
        rarity = "Rare", 
        weight = 25, 
        reward = 0 
    },
    { 
        id = "wisp_epic", 
        displayName = "Ancient Wisp", 
        rarity = "Epic", 
        weight = 5, 
        reward = 0 
    },
}

--[[
    Choose a random spirit type based on weights
    @return table - Selected spirit type
]]
function M.ChooseRandom()
    local total = 0
    for _, t in ipairs(M.Types) do 
        total = total + (t.weight or 1) 
    end
    
    local roll = math.random(1, total)
    local acc = 0
    
    for _, t in ipairs(M.Types) do
        acc = acc + (t.weight or 1)
        if roll <= acc then 
            return t 
        end
    end
    
    -- Fallback to first type
    return M.Types[1]
end

--[[
    Find spirit type by ID
    @param typeId (string) - Spirit type ID
    @return table - Spirit type or nil
]]
function M.FindById(typeId)
    for _, t in ipairs(M.Types) do
        if t.id == typeId then
            return t
        end
    end
    return nil
end

return M

