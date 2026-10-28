--[[
    ClientMain (LocalScript)
    Location: StarterPlayer/StarterPlayerScripts/ClientMain

    Client entry point. The controllers are ModuleScripts that initialize
    themselves when first required, but nothing required them at startup,
    so the hotbar, keyboard shortcuts and shop never came up.
    This script boots them in dependency order.

    Other client entry points (LocalScripts) that run on their own:
      - StarterGui/CreateHUD, CreateInventoryUI, CreateShopUI  (build the GUI)
      - Utils/EventHandlers   (server → client events; requires ClientDataCache, PlotVisualizer)
      - Utils/PlotInteraction (hover effects on plots)
]]

local StarterPlayerScripts = script.Parent
local Utils = StarterPlayerScripts:WaitForChild("Utils")
local Controllers = StarterPlayerScripts:WaitForChild("Controllers")

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

print("✅ ClientMain: client controllers loaded")
