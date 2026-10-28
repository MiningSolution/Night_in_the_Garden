---
description: "Task list for Mobile UI Access (001) implementation"
---

# Tasks: Mobile UI Access (UI Plan, Phase 1)

**Input**: Design documents from `/specs/001-mobile-ui-access/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Only one test artifact is requested by the feature (the offline `ResponsiveLayout`
unit tests, plan + research R12). No per-story TDD tests are generated. Studio playtests are in
the Polish phase via quickstart.md.

**Organization**: Tasks are grouped by user story. User stories are ordered by priority, and
within the P1 group they follow the plan's "Implementation notes" build order
(US1 → US3 → US2), because US3's close controls and US2's layout both build on the US1 window
wiring.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Exact file paths are included in each description

## Path Conventions

Roblox game, Rojo-synced repository (constitution III). Paths are repository-root relative:
`ReplicatedStorage/`, `StarterGui/`, `StarterPlayer/StarterPlayerScripts/`, `Tools/`.
All GUI changes go through `Tools/StaticGui/builders/*.luau` and are regenerated into
`StarterGui/*.model.json`; controllers only set runtime size/position/visibility/hints.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project configuration and the one new top-level path.

- [X] T001 Set `StarterGui.ScreenOrientation = LandscapeSensor` in `default.project.json` by changing the `"StarterGui": { "$path": "StarterGui" }` entry to `{ "$path": "StarterGui", "$properties": { "ScreenOrientation": "LandscapeSensor" } }` (R11, FR-012)
- [X] T002 [P] Create the `Tools/Tests/` directory for offline Luau tests (new top-level test path per plan Structure Decision)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The theme, layout math, input layer and window state that every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Create theme token module `ReplicatedStorage/UITheme.lua` holding the current dark palette as named tokens: `Surface`, `SurfaceRaised`, `Header`, `Control`, `ControlHover`, `Accent`, `Danger`, `TextPrimary`, `TextMuted`, `Backdrop`, and `BackdropTransparency` (R10)
- [X] T004 Update `Tools/StaticGui/build_models.py` to load `ReplicatedStorage/UITheme.lua` and expose it to the builders as a global `UI_THEME` (R10) — depends on T003
- [X] T005 [P] Create pure layout module `StarterPlayer/StarterPlayerScripts/Utils/ResponsiveLayout.lua` implementing `compute(LayoutInput) -> LayoutResult` (data-model.md) with no Roblox services, using the R3 constants: menu buttons `56×56`, gap `8`, left margin `12`, capacity `4`; touch hotbar `3 × 64×64`, gap `8`, bottom margin `12`; keyboard/gamepad hotbar `340×110`; `isPhone = min(viewport.w, viewport.h) <= 500`; window height cap `0.85 × freeArea.h` (phone) or `min(0.85 × freeArea.h, 0.6 × gui.h)` (tablet/PC). Expose the per-window `aspect`/`maxSize` as an exported `WINDOWS` table (Shop `aspect 1.85` / `max 960×520`, Inventory `aspect 1.4` / `max 700×500`) that is the single source for both `compute` and `WindowManager.Register` (T014, constitution II)
- [X] T006 [P] Create offline unit tests `Tools/Tests/responsive_layout.spec.luau` asserting the data-model invariants for the five reference screens (`844×390`, `667×375`, `1024×768`, `1920×1080`, `2560×1080`): every window rect ⊂ `freeArea` ⊂ ScreenGui rect; `window ∩ menuColumn = ∅` and `window ∩ hotbar = ∅`; in Touch mode `hotbar ∩ jump = ∅` and `hotbar ∩ thumbstickZone = ∅`; `window.h ≤` the cap; `width/height = aspect (±1 px)` and `≤ maxSize`; menu button and touch hotbar slot `≥ 44×44` — depends on T005
- [X] T007 [P] Create `StarterPlayer/StarterPlayerScripts/Utils/InputActions.lua` with input-mode detection only: a current mode `Touch | KeyboardMouse | Gamepad` from `UserInputService:GetLastInputType()` + `LastInputTypeChanged` (`Touch`→Touch; `Keyboard`/`MouseButton1-3`/`MouseMovement`/`MouseWheel`→KeyboardMouse; `Gamepad1..8`→Gamepad; other types keep the previous mode), initial fallback `TouchEnabled and not KeyboardEnabled`→Touch else KeyboardMouse; expose `Init()`, `GetMode()`, and a `ModeChanged(newMode, oldMode)` signal that fires only on a real change (R4, data-model.md)
- [X] T008 [P] Create `StarterPlayer/StarterPlayerScripts/Utils/WindowManager.lua` single-window state: one `openWindow: nil | name` variable and `Register(name, spec)`, `Open(name)`, `Toggle(name)`, `Close()`, `GetOpen()`, `Changed(openName?, previousName?)` signal; `Open` closes any other window first; open/close are immediate via `ScreenGui.Enabled` so repeated presses cannot leave a half-open or doubled state (FR-003, FR-017, SC-006)
- [X] T009 In `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` disable the CoreGui Backpack with `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)` (R1, so L1/R1 can be bound) and initialise `InputActions.Init()` and the `WindowManager` — depends on T007, T008

**Checkpoint**: theme, layout math + passing tests, input-mode detection and window state exist; user stories can begin.

---

## Phase 3: User Story 1 - Open the shop and inventory on a phone (Priority: P1) 🎯 MVP

**Goal**: A phone player sees a Shop and Inventory menu column and opens/switches each window by tapping.

**Independent Test**: In the device emulator at landscape phone (~844×390), start Play and open the shop and the inventory using only taps; tapping the open window's button closes it.

- [X] T010 [US1] Create new builder `Tools/StaticGui/builders/CreateHUDControls.luau` producing the `HUDControls` ScreenGui (`DisplayOrder 10`, `ResetOnSpawn false`, `ScreenInsets CoreUISafeInsets`, `IgnoreGuiInset false`, `ZIndexBehavior Sibling`): a `MenuButtons` frame with a vertical `UIListLayout` (gap 8) containing `ShopButton` and `InventoryButton` (TextButton `56×56` ≥44×44, emoji label, `Selectable=false`, each with a `KeyHint` TextLabel at `TextSize 18` and a `PadHint` ImageLabel `24×24`); and the `Hotbar` frame moved out of HUD with `Slot1..3` (each `SlotButton`, `ItemIcon › EmojiLabel`, `SelectionBorder`, `KeybindHint` at `TextSize 18`). Colours from `UI_THEME` (contracts/gui-tree.md) — depends on T004
- [X] T011 [US1] Update `Tools/StaticGui/builders/CreateHUD.luau` to remove the `Hotbar` (now in HUDControls), keep `CurrencyDisplay` and `DayNightIndicator`, and set `ScreenInsets = CoreUISafeInsets` explicitly (contracts/gui-tree.md, R11)
- [X] T012 [US1] Regenerate static models by running `python3 Tools/StaticGui/build_models.py "$(command -v luau)"`, producing the new `StarterGui/HUDControls.model.json` and the regenerated `StarterGui/HUD.model.json` — depends on T010, T011
- [X] T013 [US1] In `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua` wire `HUDControls.MenuButtons.ShopButton.Activated` and `InventoryButton.Activated` to `WindowManager.Toggle("Shop")` / `Toggle("Inventory")`, and make `ToggleShop`, `ToggleInventory`, `CloseAllUIs`, `GetUIState` keep their signatures but delegate to `WindowManager` (contracts/input-actions.md) — depends on T008, T012
- [X] T014 [US1] Register the Shop and Inventory windows with `WindowManager` (in `UIController.lua` or `ClientMain.client.lua`) using the `Window` spec from data-model.md: `gui = ShopUI/InventoryUI`, `frame = ShopFrame/InventoryFrame`, `closeButton`, `onOpen = ShopController.LoadShopData` / `InventoryController.RefreshGrid`. The window `aspect`/`maxSize` MUST NOT be re-typed here: read them from the single source — the `WINDOWS` constants in `ResponsiveLayout` (Shop `1.85` / `960×520`, Inventory `1.4` / `700×500`) — so the layout math and the window registry never diverge (constitution II) — depends on T005, T008, T013
- [X] T015 [US1] In `StarterPlayer/StarterPlayerScripts/Utils/InputActions.lua` add and bind the `always`-scope actions `ToggleShop` (keyboard `B`, gamepad `ButtonX`) and `ToggleInventory` (keyboard `I`, gamepad `ButtonY`) via `BindActionAtPriority(name, handler, false, ContextActionPriority.High.Value, ...)`, handlers calling `WindowManager.Toggle`, returning `Sink`; shortcuts must not fire while a chat TextBox has focus (FR-014) — depends on T007, T008, T014

**Checkpoint**: MVP — phone players can open, switch and close the shop and inventory by tapping; PC keys I/B still toggle.

---

## Phase 4: User Story 3 - Close windows without a keyboard (Priority: P1)

**Goal**: Every open window can be closed by X, by tapping the dimmed backdrop, and by gamepad B; nothing depends on Esc.

**Independent Test**: On a touch device open each window and close it with X and by tapping the backdrop (which must not act on the world); repeat the B close with a gamepad.

- [X] T016 [US3] Update `Tools/StaticGui/builders/CreateShopUI.luau` and `Tools/StaticGui/builders/CreateInventoryUI.luau` to add a full-screen `Backdrop` TextButton under the frame (`Text ""`, `AutoButtonColor false`, colour `Theme.Backdrop`, transparency `Theme.BackdropTransparency`), ensure the `HeaderBar.CloseButton` is `≥ 44×44`, and set `ScreenInsets = CoreUISafeInsets` and `IgnoreGuiInset = false` explicitly on both the `ShopUI` and `InventoryUI` ScreenGuis (contracts/gui-tree.md, FR-007, FR-008, FR-011, R11)
- [X] T017 [US3] Regenerate models: `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` → updated `StarterGui/ShopUI.model.json` and `StarterGui/InventoryUI.model.json` — depends on T016
- [X] T018 [US3] In `StarterPlayer/StarterPlayerScripts/Utils/WindowManager.lua` connect each registered window's `CloseButton.Activated` and `Backdrop.Activated` to `Close()`; the backdrop being an `Active` TextButton must sink the press so it does not reach the game world (FR-008) — depends on T008, T017
- [X] T019 [US3] In `StarterPlayer/StarterPlayerScripts/Utils/InputActions.lua` add the `windowOpen`-scope action `CloseWindow` (gamepad `ButtonB`) and the `BindWindowActions()` / `UnbindWindowActions()` helpers called by `WindowManager` on open/close, so `ButtonB` keeps its default behaviour while no window is open (contracts/input-actions.md, R8) — depends on T007, T008
- [X] T020 [US3] Remove the Escape handler from `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua` so no game action depends on Esc (FR-009) — depends on T013

**Checkpoint**: windows close three ways without a keyboard; Esc only opens the Roblox menu.

---

## Phase 5: User Story 2 - Windows fit every supported screen (Priority: P1)

**Goal**: Shop and inventory fit fully inside the safe area on phone, tablet and PC, with readable text and scrolling content.

**Independent Test**: Open each window at the five SC-002 reference screens; every element is visible inside the safe area, body text ≥ 18, titles/buttons ≥ 20, nothing clipped.

- [X] T021 [US2] In `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua` apply `ResponsiveLayout.compute` results as Offset size/position for `MenuButtons`, `Hotbar` and the open window, recomputing only on `Camera.ViewportSize`/ScreenGui `AbsoluteSize` change and on `InputActions.ModeChanged` — never per frame (R2, SC-006) — depends on T005, T013
- [ ] T022 [US2] Update `Tools/StaticGui/builders/CreateShopUI.luau`: wrap the item detail in a `RightPanel.Details` ScrollingFrame (`ItemIconDisplay`, `ItemNameLabel`, `ItemDescriptionLabel` ≥ 18, `PriceLabel`), add a fixed-bottom `RightPanel.Footer` frame (`QuantityStepper`, `BuyButton`), make `LoadingOverlay` cover only the body below `HeaderBar`, and raise all text to body ≥ 18 / titles & buttons ≥ 20 with no `TextScaled` (contracts/gui-tree.md, FR-005, FR-006)
- [X] T023 [US2] Update `Tools/StaticGui/builders/CreateInventoryUI.luau`: make `ItemGrid` a ScrollingFrame with `AutomaticCanvasSize = Y` + `UIGridLayout`, keep `TabContainer` (`SeedsTab`, `ItemsTab`) and `TooltipFrame` (`TooltipTitle` ≥ 20, `TooltipDescription` ≥ 18), and raise all text to ≥ 18 / ≥ 20 (contracts/gui-tree.md, FR-005, FR-006)
- [X] T024 [US2] Regenerate models: `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` → updated `StarterGui/ShopUI.model.json` and `StarterGui/InventoryUI.model.json` — depends on T022, T023
- [X] T025 [US2] In `StarterPlayer/StarterPlayerScripts/Controllers/ShopController.lua` set runtime text sizes to ≥ 18 body / ≥ 20 titles & buttons (raise today's 15) and keep the loading overlay below the header (contracts/gui-tree.md) — depends on T024
- [X] T026 [US2] In `StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.lua` set runtime item text sizes to ≥ 18 (raise today's 12/13/14) in `RefreshGrid` (contracts/gui-tree.md, FR-005) — depends on T024

**Checkpoint**: all P1 stories complete — windows open, fit every reference screen, and close without a keyboard.

---

## Phase 6: User Story 4 - Hotbar clear of the touch controls (Priority: P2)

**Goal**: On touch, the hotbar sits between the thumbstick and jump button with every slot tappable; PC hotbar unchanged.

**Independent Test**: On a landscape phone move with the thumbstick and jump while tapping each hotbar slot — no slot is covered and no tap moves or jumps the character.

- [ ] T027 [US4] In `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua` build the `LayoutInput.jump` rect by reading the live `PlayerGui.TouchGui.TouchControlFrame.JumpButton` absolute rect, falling back to the R5 formula (≤500 shorter side: `70×70` at `(1,-95,1,-90)`; larger: `120×120` at `(1,-170,1,-210)`), and the thumbstick zone (left 40% width, lower two-thirds height), so the touch hotbar is placed between them while the keyboard/gamepad hotbar stays at today's `340×110` bottom-centre (R5, FR-010, SC-004) — depends on T021
- [ ] T028 [US4] In `StarterPlayer/StarterPlayerScripts/Controllers/HotbarController.lua` apply the computed touch hotbar size/position from `ResponsiveLayout`, read the hotbar from `HUDControls` (not `HUD`), and add the click guard: ignore a tool-use press when a window is open or when `PlayerGui:GetGuiObjectsAtPosition(x, y)` contains an `Active` GUI object (R6, FR-008) — depends on T027

**Checkpoint**: touch hotbar never overlaps the Roblox controls and its taps never reach the world.

---

## Phase 7: User Story 5 - Same actions on keyboard, touch and gamepad (Priority: P2)

**Goal**: Every Phase 1 action works on all three inputs; menu buttons show key labels on PC, gamepad glyphs on gamepad, nothing on touch; gamepad highlight navigation works inside windows.

**Independent Test**: With only a gamepad (emulated), open the inventory with Y, switch to the shop with X, move the highlight with the D-pad, press Buy with A, close with B, and select hotbar slots with L1/R1 (wrapping); switching inputs updates the hints.

- [ ] T029 [US5] In `Tools/StaticGui/builders/CreateHUDControls.luau` complete the hints: confirm the menu-button `KeyHint` text ("B" for Shop, "I" for Inventory) and `PadHint` images, and add `Hotbar.PadHintLeft` (L1) and `Hotbar.PadHintRight` (R1) ImageLabels plus per-slot `KeybindHint` "1"–"3" (contracts/input-actions.md hints table, R9) — depends on T010
- [ ] T030 [US5] Regenerate the HUDControls model: `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` → updated `StarterGui/HUDControls.model.json` — depends on T029
- [ ] T031 [US5] In `StarterPlayer/StarterPlayerScripts/Utils/InputActions.lua` add the `always`-scope actions `HotbarPrev` (gamepad `ButtonL1`) and `HotbarNext` (gamepad `ButtonR1`) and the hint logic: on `ModeChanged` show `KeyHint` in KeyboardMouse, `PadHint` from `UserInputService:GetImageForKeyCode(keyCode)` in Gamepad, and neither in Touch (contracts/input-actions.md, R9) — depends on T015, T030
- [ ] T032 [US5] In `StarterPlayer/StarterPlayerScripts/Controllers/HotbarController.lua` add `PreviousSlot()` / `NextSlot()` selecting the previous/next of slots 1–3 with wrap-around at the ends (FR-013a) — depends on T028
- [ ] T033 [US5] In `Tools/StaticGui/builders/CreateShopUI.luau` and `CreateInventoryUI.luau` set `ShopFrame`/`InventoryFrame` `SelectionGroup = true` and `SelectionBehaviorUp/Down/Left/Right = Stop`, mark inner buttons `Selectable`, and designate the default selection (Shop: first category; Inventory: `SeedsTab`), then regenerate models with `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` (contracts/gui-tree.md, R8) — depends on T024
- [ ] T034 [US5] In `StarterPlayer/StarterPlayerScripts/Utils/WindowManager.lua` add gamepad selection: on open in Gamepad mode remember `GuiService.SelectedObject` and set it to the window's `defaultSelection`; on close restore the remembered selection; add the fallback that closes the window if `SelectedObject` becomes `nil` while a window is open in Gamepad mode (R8, FR-016) — depends on T018, T019, T033
- [ ] T035 [US5] In `StarterPlayer/StarterPlayerScripts/Controllers/ShopController.lua` and `InventoryController.lua` expose the default-selected object (Shop first category, Inventory `SeedsTab`) for `WindowManager` to select on open (contracts/input-actions.md) — depends on T025, T026, T034

**Checkpoint**: all actions reachable from keyboard, touch and gamepad; hints follow the active input; console can be enabled later without rework.

---

## Phase 8: User Story 6 - Phone stays in landscape (Priority: P3)

**Goal**: Rotating the phone keeps the game in landscape and flips between the two landscape directions.

**Independent Test**: On the emulator (or a real phone), rotate to portrait and back — the game stays in landscape.

- [ ] T036 [US6] Confirm `StarterGui.ScreenOrientation = LandscapeSensor` is applied from `default.project.json` (T001) and set the same in Studio, then playtest a portrait↔landscape rotation staying in landscape (FR-012, quickstart V7) — depends on T001

**Checkpoint**: orientation is locked to landscape on device.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Docs, offline + Studio verification, parity, and the constitution's no-data-change guarantee.

- [ ] T037 [P] Update the controls section of `README.md`: touch menu buttons, PC keys (B shop, I inventory, 1–3 hotbar), gamepad (Y inventory, X shop, L1/R1 hotbar, B close, A confirm)
- [ ] T038 Run quickstart V0 offline checks: `luau Tools/Tests/responsive_layout.spec.luau` (all specs pass), `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` (one fingerprint per ScreenGui: HUD, HUDControls, InventoryUI, ShopUI), and `git status --short StarterGui/` (expected: no changes — models already regenerated) — depends on all builder/regenerate and T006 tasks
- [ ] T039 Run quickstart V1 repo↔Studio parity through Studio MCP (normalized script-source hashes + `GuiRecorder` fingerprints); confirm every script and ScreenGui matches and `StarterGui.ScreenOrientation` is `LandscapeSensor`
- [ ] T040 Run quickstart V2–V8 Studio playtests via Studio MCP with the device and controller emulators: V2 touch flow (SC-001), V3 five reference screens with 0 clipped/undersized/overlap issues (SC-002/SC-003), V4 touch controls clear — verify the R5 thumbstick-zone size (SC-004), V5 PC keyboard/mouse (FR-014), V6 gamepad — verify the R8 B-vs-selection order (SC-005), V7 orientation, V8 robustness and 0 new Output errors (SC-006, SC-007) — depends on all implementation tasks
- [ ] T041 Review the branch diff to confirm FR-019: no change to remotes, handlers, prices, inventory contents or saved player data — UI reach and display only (constitution I)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies — start immediately.
- **Foundational (Phase 2)**: depends on Setup — BLOCKS all user stories.
- **User Stories (Phases 3–8)**: all depend on Foundational.
  - P1 group runs in the plan order US1 → US3 → US2 (US3 and US2 build on the US1 window wiring).
  - US4 and US5 (P2) depend on US2's layout apply (T021) being in place; US6 (P3) depends only on Setup T001.
- **Polish (Phase 9)**: depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Foundational only — the MVP.
- **US3 (P1)**: builds on US1 (window registration/wiring); adds backdrop, X and gamepad-B closing.
- **US2 (P1)**: builds on US1 (T021 applies layout to the open window); independently testable at the reference screens.
- **US4 (P2)**: builds on US2's layout apply (T021/T027); independently testable on touch.
- **US5 (P2)**: builds on US1/US3/US4 (actions, window state, hotbar cycling); independently testable with a gamepad.
- **US6 (P3)**: independent — the setting lands in T001; this story only verifies it.

### Within Each User Story

- Builder edits → regenerate models → controller/util wiring that reads the regenerated names.
- The same builder file (`CreateShopUI.luau`, `CreateInventoryUI.luau`) is touched by US3 (backdrop), US2 (layout/scroll/text) and US5 (SelectionGroup); those edits are sequential, each followed by its own regenerate.

### Parallel Opportunities

- **Setup**: T002 [P] alongside T001.
- **Foundational**: T003, T005, T007, T008 are all [P] (different new files); T004 waits on T003, T006 waits on T005, T009 waits on T007+T008.
- **US1**: T010 and T011 edit different builder files and can be written in parallel before the single regenerate T012.
- **Polish**: T037 [P] (README) alongside the verification tasks.
- Once Foundational is done, with multiple people US4 and US5 can proceed in parallel with US2 as long as they coordinate on the shared builder files and T021.

---

## Parallel Example: Foundational (Phase 2)

```text
# These four new modules have no dependency on each other — write together:
Task T003: Create ReplicatedStorage/UITheme.lua (theme tokens)
Task T005: Create StarterPlayer/StarterPlayerScripts/Utils/ResponsiveLayout.lua (pure layout)
Task T007: Create StarterPlayer/StarterPlayerScripts/Utils/InputActions.lua (mode detection)
Task T008: Create StarterPlayer/StarterPlayerScripts/Utils/WindowManager.lua (single-window state)
```

## Parallel Example: User Story 1

```text
# Different builder files, one regenerate afterward:
Task T010: Create Tools/StaticGui/builders/CreateHUDControls.luau
Task T011: Update Tools/StaticGui/builders/CreateHUD.luau (remove Hotbar)
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational) — the critical blocking base.
2. Complete Phase 3 (US1).
3. **STOP and VALIDATE**: in the landscape-phone emulator, open and switch the shop and inventory by taps (quickstart V2 steps 1–2); PC I/B still toggle.
4. This is a demoable MVP: phone players can reach the shop and inventory.

### Incremental Delivery

1. Setup + Foundational → base ready (`ResponsiveLayout` tests green, backpack off, landscape set).
2. + US1 → open/switch windows (MVP).
3. + US3 → close by X / backdrop / gamepad B, Esc dropped.
4. + US2 → windows fit all five reference screens with readable text — all P1 done.
5. + US4 → touch hotbar clear of the thumbstick and jump button.
6. + US5 → full keyboard/touch/gamepad parity with hints and glyphs.
7. + US6 → landscape lock verified on device.
8. Polish → README, offline checks, parity, Studio playtests V2–V8, FR-019 review.

### Notes

- [P] = different files, no dependency on an incomplete task.
- Commit after each task or logical group; regenerate models in the same commit as the builder change that drove them, so repo and Studio stay identical (FR-018, constitution III).
- After US1/US3, after US2, and before each Studio session, re-run V0 offline checks so `git status StarterGui/` stays clean.
- Two items carry a Studio verification instead of a resolved decision: the thumbstick-zone size (R5, quickstart V4) and the gamepad-B-vs-selection order (R8, quickstart V6) — the fallback in T034 covers either order.
