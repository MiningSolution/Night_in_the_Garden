-- EventHandlers.lua
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ClientDataCache = require(script.Parent:WaitForChild("ClientDataCache"))
local PlotVisualizer = require(script.Parent:WaitForChild("PlotVisualizer"))

local DayNightUpdate = RS:WaitForChild("DayNightUpdate")
local UpdateCurrency = RS:WaitForChild("UpdateCurrency", 1) -- kept for future use
local UpdateInventory = RS:WaitForChild("UpdateInventory", 1)
local PlotStateChanged = RS:WaitForChild("PlotStateChanged")
local PlotStateUpdated = RS:WaitForChild("PlotStateUpdated")

-- Day/Night
DayNightUpdate.OnClientEvent:Connect(function(phase, progress)
    if ClientDataCache.UpdateDayNight then
        ClientDataCache.UpdateDayNight(phase, progress)
    end
end)

-- Plot updates
PlotStateChanged.OnClientEvent:Connect(function(plotId, plotData)
    if type(plotId)~="string" or type(plotData)~="table" then return end
    if ClientDataCache.UpdatePlot then
        ClientDataCache.UpdatePlot(plotId, plotData)
    end
    if PlotVisualizer.UpdatePlot then
        PlotVisualizer.UpdatePlot(plotId, plotData)
    end
end)

PlotStateUpdated.OnClientEvent:Connect(function(payload)
    if type(payload)~="table" then return end
    local snap = payload.Snapshot
    if snap then
        if ClientDataCache.ApplySnapshot then
            ClientDataCache.ApplySnapshot(snap)
        else
            -- fallback: naive replace
            if ClientDataCache.SetAll then ClientDataCache.SetAll(snap) end
        end
        -- also update all plots visuals quickly
        if snap.Plots then
            for pid, pdata in pairs(snap.Plots) do
                if PlotVisualizer.UpdatePlot then PlotVisualizer.UpdatePlot(pid, pdata) end
            end
        end
    end
end)

print("[EventHandlers] Ready on client")
