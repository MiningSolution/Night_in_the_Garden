# Night in the Garden — v6

This bundle contains client + server with ProfileService persistence,
Plot visualization pipeline, and security/validation hardening.

## Structure
- StarterGui (UI creation scripts: `CreateHUD.lua`, `CreateShopUI.lua`)
- StarterPlayer/StarterPlayerScripts (client cache + visualization scripts)
- ReplicatedStorage
- ServerScriptService
  - Services (core server modules, including Spirit system)
- Workspace
- Docs

## Getting Started
1. Insert this tree into Roblox Studio (or copy scripts manually).
2. Ensure **ProfileService** module is present under `ServerScriptService/ProfileService`.
3. Create Plot1..Plot3 models in Workspace (see previous instructions), or run your plot creation command.
4. Play in Studio with API Services enabled (Game Settings → Security).

## Notes
- Shop is single-source-of-truth via `ReplicatedStorage/ShopConfig.lua`
- Player data template in `ReplicatedStorage/DefaultData.lua`
- Environment store name controlled by `ReplicatedStorage/GameSettings.lua`
