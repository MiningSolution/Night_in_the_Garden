-- EventHandlers.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientDataCache = require(script.Parent:WaitForChild("ClientDataCache"))
local UIController = require(script.Parent.Controllers:WaitForChild("UIController"))
local InventoryController = require(script.Parent.Controllers:WaitForChild("InventoryController"))
local PlotVisualizer = require(script.Parent:WaitForChild("PlotVisualizer"))

local DayNightUpdate = ReplicatedStorage:WaitForChild("DayNightUpdate", 30)
local UpdateCurrency = ReplicatedStorage:WaitForChild("UpdateCurrency", 30)
local UpdateInventory = ReplicatedStorage:WaitForChild("UpdateInventory", 30)
local PlotStateChanged = ReplicatedStorage:WaitForChild("PlotStateChanged", 30)
local PlotStateUpdated = ReplicatedStorage:WaitForChild("PlotStateUpdated", 30)

if DayNightUpdate then
    DayNightUpdate.OnClientEvent:Connect(function(phase, progress)
        if UIController and UIController.UpdateDayNight then
            UIController.UpdateDayNight(phase, progress)
        end
    end)
end

if UpdateCurrency then
    UpdateCurrency.OnClientEvent:Connect(function(currencyType, newValue)
        ClientDataCache.UpdateCurrency(currencyType, newValue)
    end)
end

if UpdateInventory then
    UpdateInventory.OnClientEvent:Connect(function(newInventory)
        ClientDataCache.UpdateInventory(newInventory)
    end)
end

if PlotStateChanged then
    PlotStateChanged.OnClientEvent:Connect(function(plotId, plotData)
        ClientDataCache.UpdatePlot(plotId, plotData)
        PlotVisualizer.UpdatePlot(plotId, plotData)
    end)
end

if PlotStateUpdated then
    PlotStateUpdated.OnClientEvent:Connect(function(updateData)
        if type(updateData) ~= "table" then return end
        if updateData.Snapshot and updateData.Snapshot.Plots then
            for plotId, plotData in pairs(updateData.Snapshot.Plots) do
                ClientDataCache.UpdatePlot(plotId, plotData)
                PlotVisualizer.UpdatePlot(plotId, plotData)
            end
        end
    end)
end

print("✅ EventHandlers initialized")
