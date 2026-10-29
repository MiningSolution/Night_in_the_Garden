-- SpiritTypes.lua
-- P2-1: Spirit type definitions with weights for random spawn.
-- feature 006 (Stage 2): the catalog now lives in ReplicatedStorage/SpiritData (single
-- source shared with the client Journal). This module keeps the server-side spawn helpers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpiritData = require(ReplicatedStorage:WaitForChild("SpiritData"))

local M = {}

-- Read the type list from the single-source catalog.
M.Types = SpiritData.Types

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
    return SpiritData.FindById(typeId)
end

return M
