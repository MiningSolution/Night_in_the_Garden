--[[
    ClientMain (LocalScript)
    Location: StarterPlayer/StarterPlayerScripts/ClientMain

    Client entry point. The controllers are ModuleScripts that initialize
    themselves when first required, but nothing required them at startup,
    so the hotbar, keyboard shortcuts and shop never came up.
    This script boots them in dependency order.

    Other client entry points (LocalScripts) that run on their own:
      (the GUI itself is static: StarterGui/HUD, InventoryUI, ShopUI)
      - Utils/EventHandlers   (server → client events; requires ClientDataCache, PlotVisualizer)
      - Utils/PlotInteraction (hover effects on plots)
]]

local StarterPlayerScripts = script.Parent
local Utils = StarterPlayerScripts:WaitForChild("Utils")
local Controllers = StarterPlayerScripts:WaitForChild("Controllers")

-- Feature 001: turn off the default Roblox backpack so the game's own hotbar is
-- the only tool bar and L1/R1 can be bound through ContextActionService (R1).
-- The game uses no Roblox Tool instances, so nothing is lost by hiding it.
local StarterGui = game:GetService("StarterGui")
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function boot(folder, name)
    local module = folder:WaitForChild(name, 10)
    if not module then
        warn(string.format("⚠️ ClientMain: %s.%s not found", folder.Name, name))
        return nil
    end
    local ok, result = pcall(require, module)
    if not ok then
        warn(string.format("❌ ClientMain: failed to load %s.%s: %s", folder.Name, name, tostring(result)))
        return nil
    end
    return result
end

-- State first: everything else reads from it
boot(Utils, "StateManager")
boot(Utils, "ClientDataCache") -- starts the initial GetPlayerData sync

-- Controllers (each one self-initializes on require)
boot(Controllers, "UIController")
boot(Controllers, "HotbarController")
boot(Controllers, "InventoryController")
boot(Controllers, "ShopController")
boot(Controllers, "SellController") -- feature 002: sell window at the seller stall
boot(Controllers, "DailyRewardController") -- feature 003: daily login reward (US1)
boot(Controllers, "QuestController") -- feature 003: daily quests (US2)

-- Feature 001: the shared action layer (keyboard/touch/gamepad). Init after the
-- controllers so the windows are registered before any action can toggle them.
local InputActions = boot(Utils, "InputActions")
if InputActions then
    InputActions.Init()
end

print("✅ ClientMain: client controllers loaded")
