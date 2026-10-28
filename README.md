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
StarterGui/                   static GUI: HUD, HUDControls, InventoryUI, ShopUI (.model.json)
StarterPlayer/StarterPlayerScripts/
  ClientMain.client.lua       client entry point, boots the controllers
  Controllers/                UIController, HotbarController, InventoryController, ShopController
  Utils/                      StateManager, ClientDataCache, PlotVisualizer, GuiEffects, Debounce,
                              InputActions, WindowManager, ResponsiveLayout,
                              EventHandlers.client.lua, PlotInteraction.client.lua
ReplicatedStorage/UITheme.lua colour tokens for the UI (dark palette; day palette is Phase 4)
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

## Controls (Phase 1: mobile UI access)

The game is playable on a landscape phone, PC and (via gamepad) console. Every
action goes through one shared action layer (`Utils/InputActions.lua`), so the
on-screen menu buttons (Shop, Inventory) show on every platform, and a window
can always be opened and closed without a keyboard.

| Action | Touch | Keyboard / mouse | Gamepad |
| --- | --- | --- | --- |
| Open / toggle Shop | tap the Shop button | `B` | `X` |
| Open / toggle Inventory | tap the Inventory button | `I` | `Y` |
| Close the open window | tap `X` or the dimmed backdrop | tap `X` / backdrop | `B` |
| Select hotbar slot | tap the slot | `1` `2` `3` | `L1` / `R1` (prev / next, wraps) |
| Move inside a window | tap | mouse | D-pad / left stick |
| Confirm in a window | tap | click | `A` |

- The menu buttons show the key label on PC and the matching gamepad glyph on a
  gamepad; neither on touch. Only one window is open at a time.
- `Esc` is left to the Roblox menu — no game action depends on it.
- The phone is locked to landscape (`StarterGui.ScreenOrientation = LandscapeSensor`),
  and the default Roblox backpack is turned off so `L1`/`R1` can be bound.
- Window size, the menu column and the touch hotbar position come from
  `Utils/ResponsiveLayout.lua` (unit-tested in `Tools/Tests/`); colours come from
  `ReplicatedStorage/UITheme.lua`.

## Notes
- Shop is single-source-of-truth via `ReplicatedStorage/ShopConfig.lua`
- Player data template in `ReplicatedStorage/DefaultData.lua`
- Environment store name controlled by `ReplicatedStorage/GameSettings.lua`
