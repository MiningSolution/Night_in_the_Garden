# Implementation Plan: Mobile UI Access (UI Plan, Phase 1)

**Branch**: `001-mobile-ui-access` | **Date**: 2026-10-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-mobile-ui-access/spec.md`

## Summary

Make the game playable on a landscape phone, with PC and gamepad input designed in. A new
always-on-top `HUDControls` ScreenGui holds a left-edge menu column (Shop, Inventory) and the
hotbar, moved out of `HUD`. Shop and inventory get a dimmed backdrop, close by X, by tapping the
backdrop or with gamepad B, and allow one window at a time through a small `WindowManager`. One
`InputActions` module defines every action once and binds keyboard, touch and gamepad (Y = inventory, X = shop, L1/R1 =
hotbar, B = close), tracks the current input mode and swaps key labels and gamepad glyphs.
Window, column and hotbar geometry come from a pure `ResponsiveLayout` function (Scale-fitted
frames, Offset content, text ≥ 18/20), unit-tested offline for five reference screens. The phone
is locked to landscape, the default Roblox backpack is turned off so L1/R1 can be bound, and new
or changed colours come from a `UITheme` token module. All GUI changes go through the static GUI
builders, so the repository stays the source of truth.

## Technical Context

**Language/Version**: Luau (Roblox client); Python 3 for the GUI generator driver

**Primary Dependencies**: Roblox engine services — ContextActionService, UserInputService,
GuiService, StarterGui; Rojo 7.x layout; existing client modules (StateManager, controllers)

**Storage**: N/A — no persisted or server data changes (FR-019)

**Testing**: Luau CLI unit tests for `ResponsiveLayout` (`Tools/Tests/`); static GUI generator
+ fingerprint parity; Studio playtests via Studio MCP with device and controller emulators
(see [quickstart.md](./quickstart.md))

**Target Platform**: Roblox — phones and tablets (landscape only), PC; console via gamepad
emulation (console publishing is out of scope)

**Project Type**: Roblox game, Rojo-synced repository (client + server + static GUI)

**Performance Goals**: window opens/closes within 0.3 s (SC-006); layout recomputed only on
viewport size or input mode changes, never per frame

**Constraints**: text ≥ 18 body / ≥ 20 titles and buttons; tap targets ≥ 44×44; inside
`CoreUISafeInsets`; no Escape dependency; Roblox-reserved gamepad buttons untouched;
StreamingEnabled unaffected (UI only)

**Scale/Scope**: 4 ScreenGuis (1 new), 4 builders (3 updated, 1 new), 4 controllers touched,
4 new modules (`InputActions`, `WindowManager`, `ResponsiveLayout`, `UITheme`), 1 test file

All unknowns from the first draft (backpack vs L1/R1, sizing method, touch control geometry,
backdrop click-through, gamepad B behaviour, glyphs, theming) are resolved in
[research.md](./research.md) R1–R12. Two items carry a verification step instead of an
open question: the thumbstick-zone size (R5, quickstart V4) and the order of B handling vs GUI
selection (R8, quickstart V6).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Server-authoritative | No remotes, handlers or server state change; client only changes how UI opens and lays out. Buying still goes through the existing shop remote. | ✅ |
| II. Single source of truth | No balance numbers added. Layout constants live once in `ResponsiveLayout`; colours once in `UITheme`. | ✅ |
| III. Rojo / static GUI | New `HUDControls`, backdrops, footer and hint elements are built by the builders into `StarterGui/*.model.json`; at runtime controllers only set sizes, positions, visibility and hint images. `ScreenOrientation` set in `default.project.json` and Studio. | ✅ |
| IV. Mobile-first, input-agnostic | This feature implements the principle: touch path for every action, ≥ 44×44, safe area, one action layer for keyboard/touch/gamepad, gamepad navigation. Escape unused. | ✅ |
| V. Theme tokens | New/changed elements take colours from `ReplicatedStorage/UITheme` (current dark palette); day palette and switching are Phase 4. | ✅ |
| VI. Verified in Studio | Quickstart V0–V8 incl. phone-size emulator checks and parity; no data writes beyond existing shop purchases in testing. | ✅ |
| VII. Simplicity, small PR | One PR for Phase 1; new modules are small and single-purpose; computed layout is justified in R2 (simpler than nested constraints). Hotbar touch-control avoidance and theme module are the only additions beyond the spec's literal list, both required by spec/constitution. | ✅ |

**Gate result (pre-research)**: pass. **Re-check after Phase 1 design**: pass — the design added
`HUDControls` (needed for Q3 layering, R7) and the `UITheme` module (principle V); neither
violates a principle. No Complexity Tracking entries.

## Project Structure

### Documentation (this feature)

```text
specs/001-mobile-ui-access/
├── spec.md              # /speckit-specify + /speckit-clarify
├── plan.md              # this file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── input-actions.md # action set, bindings, hints, module API
│   └── gui-tree.md      # static GUI names/properties the controllers rely on
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
default.project.json                       # + StarterGui.$properties.ScreenOrientation
ReplicatedStorage/
└── UITheme.lua                            # NEW colour tokens (dark palette)
StarterGui/
├── HUD.model.json                         # regenerated (hotbar moved out)
├── HUDControls.model.json                 # NEW (menu column + hotbar)
├── InventoryUI.model.json                 # regenerated (backdrop, scroll, text sizes)
└── ShopUI.model.json                      # regenerated (backdrop, details scroll, footer)
StarterPlayer/StarterPlayerScripts/
├── ClientMain.client.lua                  # disable CoreGui Backpack; init InputActions, WindowManager
├── Controllers/
│   ├── UIController.lua                   # menu buttons, layout apply, delegate to WindowManager, drop Esc
│   ├── HotbarController.lua               # HUDControls path, actions instead of raw keys, click guard
│   ├── ShopController.lua                 # default selection, overlay below header
│   └── InventoryController.lua            # runtime text sizes ≥ 18, default selection
└── Utils/
    ├── InputActions.lua                   # NEW action layer + input mode + hints
    ├── WindowManager.lua                  # NEW single-window state, backdrop, gamepad selection
    └── ResponsiveLayout.lua               # NEW pure layout math
Tools/
├── StaticGui/
│   ├── build_models.py                    # inject UI_THEME for builders
│   ├── builders/CreateHUDControls.luau    # NEW (menu column + hotbar)
│   └── builders/CreateHUD.luau, CreateInventoryUI.luau, CreateShopUI.luau  # updated
└── Tests/
    └── responsive_layout.spec.luau        # NEW offline layout tests
README.md                                  # controls section (touch, keys, gamepad)
```

**Structure Decision**: the existing Rojo layout (constitution III). Client modules follow the
controller pattern: stateful helpers in `Utils/`, screen logic in `Controllers/`. The only new
top-level path is `Tools/Tests/` for offline Luau tests, next to the existing `Tools/StaticGui/`.

## Implementation notes (input for /speckit-tasks)

Suggested order, each step independently playtestable:

1. **Foundation**: `UITheme`, `ResponsiveLayout` + tests, `InputActions` (mode detection only),
   `WindowManager`; disable CoreGui Backpack; landscape lock.
2. **US1/US3 (P1)**: builders — `HUDControls` with menu column, hotbar moved, backdrops, close
   buttons ≥ 44; `UIController`/`WindowManager` wiring; remove Esc; regenerate models.
3. **US2 (P1)**: window layout apply, shop details scroll + footer, inventory grid scroll,
   text sizes ≥ 18/20 in builders and controllers, overlay below header.
4. **US4 (P2)**: touch hotbar size and position from jump button / thumbstick zone; click guard
   (R6).
5. **US5 (P2)**: full action table (keys, gamepad), hints and glyphs, selection groups and
   default selection, B close.
6. **US6 (P3)**: verify orientation on device (setting lands in step 1).
7. **Polish**: README controls, parity, quickstart V0–V8.

## Complexity Tracking

No constitution violations to justify.
