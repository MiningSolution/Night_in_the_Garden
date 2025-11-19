-- AntiCheatLogger.lua
-- P1-5: System for tracking suspicious player actions
-- Logs events for analysis and can auto-kick for exploits

local HttpService = game:GetService("HttpService")

local M = {}

-- Log levels
M.LOG_LEVELS = {
    INFO = 1,
    SUSPICIOUS = 2,
    EXPLOIT = 3,
    BAN = 4
}

-- In-memory log buffer (could be extended to send to external service)
-- P2-4: Use constant from Constants
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Constants"))
local logs = {} -- Array of log entries
local MAX_LOG_BUFFER = Constants.ANTICHEAT.MAX_LOG_BUFFER

--[[
    Log suspicious event
    @param player (Player) - The player
    @param level (number) - Log level (1=INFO, 2=SUSPICIOUS, 3=EXPLOIT, 4=BAN)
    @param event (string) - Event name (e.g., "INVALID_TOOL", "DISTANCE_EXPLOIT")
    @param details (table) - Additional details about the event
]]
function M.log(player, level, event, details)
    if not player or not player.Parent then
        return
    end
    
    details = details or {}
    
    local entry = {
        timestamp = os.time(),
        tickTime = tick(),
        userId = player.UserId,
        username = player.Name,
        level = level,
        event = event,
        details = details
    }
    
    table.insert(logs, entry)
    
    -- Trim buffer if too large
    if #logs > MAX_LOG_BUFFER then
        table.remove(logs, 1)
    end
    
    -- Get level name for logging
    local levelName = ""
    for name, val in pairs(M.LOG_LEVELS) do
        if val == level then 
            levelName = name 
            break 
        end
    end
    
    -- Print to console with appropriate severity
    if level >= M.LOG_LEVELS.EXPLOIT then
        warn(string.format("[ANTICHEAT][%s] %s (%d): %s - %s", 
            levelName, player.Name, player.UserId, event, 
            HttpService:JSONEncode(details)))
    else
        print(string.format("[ANTICHEAT][%s] %s (%d): %s - %s", 
            levelName, player.Name, player.UserId, event, 
            HttpService:JSONEncode(details)))
    end
    
    -- Auto-kick for exploit level
    if level >= M.LOG_LEVELS.EXPLOIT then
        M.handleExploit(player, event, details)
    end
    
    -- TODO: Send to analytics/webhook if configured
    -- M.sendToAnalytics(entry)
end

--[[
    Handle detected exploit
    @param player (Player) - The player
    @param event (string) - Event name
    @param details (table) - Event details
]]
function M.handleExploit(player, event, details)
    -- Log the ban
    M.log(player, M.LOG_LEVELS.BAN, "AUTO_KICK", {
        reason = event,
        details = details
    })
    
    -- Kick player with message
    local kickMessage = string.format("Exploit detected: %s. Please contact support if this is an error.", event)
    player:Kick(kickMessage)
end

--[[
    Get logs for a specific player
    @param userId (number) - User ID
    @param limit (number) - Max number of logs to return (default: 50)
    @return table - Array of log entries
]]
function M.getPlayerLogs(userId, limit)
    limit = limit or 50
    local playerLogs = {}
    
    -- Search from newest to oldest
    for i = #logs, 1, -1 do
        if logs[i].userId == userId then
            table.insert(playerLogs, logs[i])
            if #playerLogs >= limit then 
                break 
            end
        end
    end
    
    return playerLogs
end

--[[
    Get all logs (for admin/debugging)
    @param limit (number) - Max number of logs to return
    @return table - Array of log entries
]]
function M.getAllLogs(limit)
    limit = limit or 100
    local result = {}
    
    local startIdx = math.max(1, #logs - limit + 1)
    for i = startIdx, #logs do
        table.insert(result, logs[i])
    end
    
    return result
end

--[[
    Get logs by event type
    @param eventName (string) - Event name to filter by
    @param limit (number) - Max number of logs to return
    @return table - Array of log entries
]]
function M.getLogsByEvent(eventName, limit)
    limit = limit or 50
    local result = {}
    
    for i = #logs, 1, -1 do
        if logs[i].event == eventName then
            table.insert(result, logs[i])
            if #result >= limit then
                break
            end
        end
    end
    
    return result
end

--[[
    Get logs by level
    @param minLevel (number) - Minimum log level
    @param limit (number) - Max number of logs to return
    @return table - Array of log entries
]]
function M.getLogsByLevel(minLevel, limit)
    limit = limit or 50
    local result = {}
    
    for i = #logs, 1, -1 do
        if logs[i].level >= minLevel then
            table.insert(result, logs[i])
            if #result >= limit then
                break
            end
        end
    end
    
    return result
end

return M

