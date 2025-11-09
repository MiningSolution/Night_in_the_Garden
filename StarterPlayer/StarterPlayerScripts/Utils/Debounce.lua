-- Debounce.lua
-- P2-5: Utility for debouncing and throttling function calls
-- Prevents spam clicks and excessive function calls

local Debounce = {}

--[[
    Create debounced version of function
    @param func (function) - Function to debounce
    @param cooldown (number) - Cooldown in seconds (default: 0.5)
    @return function - Debounced function
]]
function Debounce.create(func, cooldown)
    cooldown = cooldown or 0.5
    local lastCall = 0
    
    return function(...)
        local now = tick()
        if now - lastCall < cooldown then
            warn("⏱️ Debounce: Action on cooldown")
            return false
        end
        
        lastCall = now
        func(...)
        return true
    end
end

--[[
    Create throttled version (limits calls per second)
    @param func (function) - Function to throttle
    @param maxCallsPerSecond (number) - Maximum calls per second (default: 2)
    @return function - Throttled function
]]
function Debounce.throttle(func, maxCallsPerSecond)
    maxCallsPerSecond = maxCallsPerSecond or 2
    local calls = {}
    
    return function(...)
        local now = tick()
        
        -- Remove old calls (older than 1 second)
        for i = #calls, 1, -1 do
            if now - calls[i] > 1 then
                table.remove(calls, i)
            end
        end
        
        -- Check limit
        if #calls >= maxCallsPerSecond then
            warn("⏱️ Throttle: Too many calls")
            return false
        end
        
        table.insert(calls, now)
        func(...)
        return true
    end
end

--[[
    Create per-player debounce (useful for UI buttons)
    @param func (function) - Function to debounce
    @param cooldown (number) - Cooldown in seconds
    @return function - Debounced function that accepts player as first arg
]]
function Debounce.perPlayer(func, cooldown)
    cooldown = cooldown or 0.5
    local lastCalls = {} -- [player] = timestamp
    
    return function(player, ...)
        if not player then
            return func(...)
        end
        
        local now = tick()
        local lastCall = lastCalls[player]
        
        if lastCall and (now - lastCall) < cooldown then
            return false
        end
        
        lastCalls[player] = now
        func(player, ...)
        return true
    end
end

return Debounce

