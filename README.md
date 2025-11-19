# Night in the Garden — v6

This bundle contains client + server with ProfileService persistence,
Plot visualization pipeline, and security/validation hardening.

## Structure
- StarterGui (UI creation scripts)
- StarterPlayer/StarterPlayerScripts
- ReplicatedStorage
- ServerScriptService
  - Services (core server modules, including Spirit system and `ProfileServiceLoader.lua`)
- Workspace
- Docs

📁 UI Scripts to place in StarterGui or StarterPlayerScripts
1) Must be LocalScripts in StarterGui

- CreateHUD.lua — создаёт HUD (валюта, хотбар, верхняя панель)
- CreateShopUI.lua — генерирует окно магазина
- CreateInventoryUI.lua — генерирует окно инвентаря (пропущенный ранее, теперь добавлен)

2) Must be LocalScripts in StarterPlayerScripts/Controllers

- UIController.lua
- HotbarController.lua
- InventoryController.lua
- ShopController.lua

3) Must be LocalScripts in StarterPlayerScripts/Utils

- ClientDataCache.lua
- Debounce.lua
- StateManager.lua
- PlotVisualizer.lua
- PlotInteraction.lua
- EventHandlers.lua

## Getting Started
1. Insert this tree into Roblox Studio (or copy scripts manually).
2. Ensure **ProfileService** module is present under `ServerScriptService/ProfileService`.
3. Create Plot1..Plot3 models in Workspace (see previous instructions), or run your plot creation command.
4. Play in Studio with API Services enabled (Game Settings → Security).

## Notes
- Shop is single-source-of-truth via `ReplicatedStorage/ShopConfig.lua`
- Player data template in `ReplicatedStorage/DefaultData.lua`
- Environment store name controlled by `ReplicatedStorage/GameSettings.lua`
