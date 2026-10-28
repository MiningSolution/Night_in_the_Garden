# Night in the Garden — v6

Roblox farming game: client + server with ProfileService persistence,
plot visualization pipeline, spirit system and security/validation hardening.

## Structure

The repo follows the [Rojo](https://rojo.space) layout (`default.project.json`).
The file suffix decides the script class, so classes are never lost on import:

| Suffix | Roblox class |
| --- | --- |
| `.server.lua` | Script |
| `.client.lua` | LocalScript |
| `.lua` | ModuleScript (name = file name without `.lua`) |
| `.model.json` | instances (static GUI) |

```
ReplicatedStorage/            shared config modules (PlantData, ShopConfig, Constants, ...)
ServerScriptService/
  Init.server.lua             server entry point
  AdminCommands.server.lua
  CreateRemotes.lua           RemoteEvents/Functions (required by Init)
  RemoteHandlers.lua          remote handlers (required by Init)
  ProfileService.lua          vendored, Apache 2.0 (ThirdParty/)
  Services/                   PlayerDataManager, PlotManager, PlantGrowthService, ...
    Spirit/                   spirit system
StarterGui/                   static GUI: HUD, InventoryUI, ShopUI (.model.json)
StarterPlayer/StarterPlayerScripts/
  ClientMain.client.lua       client entry point, boots the controllers
  Controllers/                UIController, HotbarController, InventoryController, ShopController
  Utils/                      StateManager, ClientDataCache, PlotVisualizer, GuiEffects, Debounce,
                              EventHandlers.client.lua, PlotInteraction.client.lua
Tools/StaticGui/              generator for StarterGui/*.model.json (see below)
Workspace/                    create Plot1..Plot3 here (Model + PlotBase part + PlotMarker BoolValue)
Docs/
```

## Getting started

1. Sync with Rojo (`rojo serve`) or copy scripts manually. When copying by hand,
   create each script with the class from the table above and drop `.lua` /
   `.server` / `.client` from the name.
2. Create Plot1..Plot3 models in Workspace.
3. Play in Studio. With API access off, ProfileService uses a mock DataStore;
   with it on (Game Settings → Security), Studio data is saved for real.

## Static GUI (P2-3)

The GUI is static: `StarterGui/*.model.json`, cloned into PlayerGui on spawn.
Hover colors, tab highlighting and the loading spinner live in the controllers
(`Utils/GuiEffects.lua`).

The models are generated from the original builder scripts in
`Tools/StaticGui/builders/`. To change the GUI, either edit it in Studio and
mirror the change in the builder, or edit the builder and regenerate:

```
python3 Tools/StaticGui/build_models.py /path/to/luau
```

## Notes
- Shop is single-source-of-truth via `ReplicatedStorage/ShopConfig.lua`
- Player data template in `ReplicatedStorage/DefaultData.lua`
- Environment store name controlled by `ReplicatedStorage/GameSettings.lua`
- Keys: `I` inventory (bound above the camera's I/O zoom), `B` shop, `1-3` hotbar
