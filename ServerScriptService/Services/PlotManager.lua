-- PlotManager.lua
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerDataManager"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local AntiCheat = require(script.Parent:WaitForChild("AntiCheatLogger"))
local PlantData = require(RS:WaitForChild("PlantData"))
local GameSettings = require(RS:WaitForChild("GameSettings"))
local QuestService = require(script.Parent:WaitForChild("QuestService")) -- feature 003 (US2)

local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")

local M = {}

-- P1-3: Server-side cooldown tracking per player per plot
-- P2-4: Use constant from Constants
local Constants = require(RS:WaitForChild("Constants"))
local INTERACTION_COOLDOWN = Constants.PLOT.INTERACTION_COOLDOWN
local lastInteractions = {} -- [player] = { [plotId] = timestamp }

local VALID_PLOT_IDS = { "Plot1","Plot2","Plot3" }
local function isValidPlotId(id)
    for _,v in ipairs(VALID_PLOT_IDS) do if v==id then return true end end
    return false
end

-- P1-3: Check if interaction is on cooldown
local function checkCooldown(player, plotId)
    local now = tick()
    
    if not lastInteractions[player] then
        lastInteractions[player] = {}
    end
    
    local lastTime = lastInteractions[player][plotId]
    if lastTime and (now - lastTime) < INTERACTION_COOLDOWN then
        local remaining = INTERACTION_COOLDOWN - (now - lastTime)
        return false, string.format("Cooldown: %.1fs remaining", remaining)
    end
    
    lastInteractions[player][plotId] = now
    return true, nil
end

local function ok(payload) payload = payload or {}; payload.Success=true; return payload end
local function fail(msg) return {Success=false, Error=tostring(msg or "Unknown")} end

local function parseSeed(toolName)
    if type(toolName)~="string" then return nil end
    if toolName:match("_seed$") then
        return toolName:gsub("_seed$","")
    end
    return nil
end

function M.HandleInteraction(player, plotModel, clientToolName)
    if typeof(plotModel) ~= "Instance" then return fail("No target") end
    local plotId = plotModel.Name
    if not isValidPlotId(plotId) then return fail("Invalid plot: "..tostring(plotId)) end

    -- P1-3: Server-side cooldown check (prevents spam exploits)
    local cooldownOk, cooldownMsg = checkCooldown(player, plotId)
    if not cooldownOk then
        return fail(cooldownMsg)
    end

    -- SECURITY: Ignore clientToolName - use server state instead
    -- This prevents clients from sending fake tool names
    local toolName = InventoryService.GetEquipped(player)
    
    -- P1-5: Log if client sent different tool (potential exploit attempt)
    if clientToolName and type(clientToolName) == "string" and clientToolName ~= toolName then
        AntiCheat.log(player, AntiCheat.LOG_LEVELS.SUSPICIOUS, "INVALID_TOOL", {
            clientTool = clientToolName,
            serverTool = toolName,
            plot = plotId
        })
    end

    -- distance check
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local plotPos = plotModel:GetPivot().Position
        local maxDistance = (GameSettings.PlotSettings and GameSettings.PlotSettings.InteractionDistance) or 25
        local distance = (hrp.Position - plotPos).Magnitude
        
        if distance > maxDistance then
            -- P1-5: Log distance exploit attempt
            AntiCheat.log(player, AntiCheat.LOG_LEVELS.SUSPICIOUS, "DISTANCE_EXPLOIT", {
                distance = distance,
                maxAllowed = maxDistance,
                plot = plotId
            })
            return fail("Too far from plot")
        end
    end

    local data = PlayerData.Get(player); if not data then return fail("Data not loaded") end
    local plot = PlayerData.GetPlot(player, plotId)
    local seedPlant = parseSeed(toolName)

    -- Watering
    if toolName == "basic_watering_can" or toolName == "improved_watering_can" then
        if plot.State == "Growing" then
            plot.IsWatered = true
            plot.LastWatered = os.time()
            PlotStateChanged:FireClient(player, plotId, plot)
            return ok({Action="Watered"})
        else
            return fail("Nothing to water")
        end
    end

    -- Planting
    if seedPlant then
        local pid = seedPlant
        if not PlantData[pid] then return fail("Unknown plant") end
        if plot.State ~= "Empty" then return fail("Plot is not empty") end
        
        -- P0-3: Use atomic operation to prevent race conditions
        -- This combines check and consume in one step
        local success, err = PlayerData.TryConsumeItemAtomic(player, pid.."_seed", 1)
        if not success then 
            return fail(err or "No seeds") 
        end
        
        plot.State = "Planted"
        plot.PlantId = pid
        plot.PlantedAt = os.time()
        plot.GrowthProgress = 0
        plot.GrowthSeconds = 0 -- feature 002: phase-gated growth accumulator (FR-007)
        plot.IsWatered = false

        QuestService.Track(player, "plant", 1) -- feature 003 (US2)

        PlotStateChanged:FireClient(player, plotId, plot)
        local snap = PlayerData.Snapshot(player)
        PlotStateUpdated:FireClient(player, {PlotId=plotId, Success=true, Snapshot=snap})
        return ok({Action="Planted", PlotId=plotId})
    end

    -- Harvest
    if toolName == "Harvest" then
        if plot.State ~= "ReadyToHarvest" then return fail("Not ripe") end
        local crop = (plot.PlantId or "carrot").."_crop"
        PlayerData.AddItem(player, crop, 1)
        QuestService.Track(player, "harvest", 1) -- feature 003 (US2)

        -- Temporary harvest effect (non-blocking)
        PlotStateChanged:FireClient(player, plotId, {State="Harvesting", PlantId=plot.PlantId, GrowthProgress=1, IsWatered=false})
        task.spawn(function()
            task.wait(0.5)

            plot.State = "Empty"
            plot.PlantId = nil
            plot.GrowthProgress = 0
            plot.GrowthSeconds = 0
            plot.IsWatered = false

            PlotStateChanged:FireClient(player, plotId, plot)
            local snap = PlayerData.Snapshot(player)
            PlotStateUpdated:FireClient(player, {PlotId=plotId, Success=true, Snapshot=snap})
        end)
        return ok({Action="Harvested", PlotId=plotId})
    end

    return fail("Invalid action")
end

-- P1-3: Cleanup cooldowns on player leave
local Players = game:GetService("Players")
Players.PlayerRemoving:Connect(function(player)
    lastInteractions[player] = nil
end)

return M
