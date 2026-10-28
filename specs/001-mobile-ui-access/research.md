# Research: Mobile UI Access (001)

Phase 0 of `/speckit-plan`. R1–R2 were collected on 2026-10-28 when comparing the spec with
Grow a Garden and Roblox guidance; R3–R11 resolve the remaining technical unknowns from the plan's
Technical Context. Every item: Decision / Rationale / Alternatives considered.

## R1. Disable the default Roblox backpack

- **Decision**: turn off the CoreGui Backpack on the client at startup
  (`StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)` in `ClientMain`); the game's
  own hotbar is the only tool bar.
- **Rationale**: while the CoreGui Backpack is enabled, `ButtonL1`/`ButtonR1` cannot be bound
  through ContextActionService, which FR-013a needs for hotbar cycling
  ([DevForum](https://devforum.roblox.com/t/binding-keycode-buttonl1buttonr1-through-contextactionservice-not-possible-with-backpack-coregui/21767)).
  The repo has no `SetCoreGuiEnabled` call today, so the default backpack is still on. The game
  uses no Roblox `Tool` instances (tools are equipped through the `EquipTool` remote), so
  nothing is lost by hiding it.
- **Alternatives considered**: other hotbar buttons (D-pad) — rejected, the D-pad is reserved for
  highlight navigation inside windows (FR-013a).

## R2. Window layout: Scale-fitted frame, Offset content

- **Decision**: the size and position of each window, the menu column and the hotbar are
  computed in code from the ScreenGui's absolute size and the input mode (R4), and applied as
  Offset values whenever the viewport or input mode changes. Rows, buttons and text inside use
  fixed Offset sizes; content that can exceed the window lives in `ScrollingFrame`s with
  `AutomaticCanvasSize`.
- **Rationale**: Roblox normalises Offset and TextSize to about 160 dpi, so Offset content keeps
  a constant physical size on every device; layouts built entirely on Scale become unreadably
  small on phones and break across aspect ratios
  ([DevForum, UI scaling best practices](https://devforum.roblox.com/t/specific-details-about-ui-scaling-best-practices/3888004)).
  The window rule in FR-004 ("85% of the free height above the hotbar on phones, at most 60% of
  screen height on tablet/PC, same proportions, between the menu column and the right edge")
  depends on the hotbar position, which itself depends on the input mode — a small pure function
  expresses that more simply and testably than nested constraints. Console guidelines also call
  for size limits and scrolling frames
  ([Roblox Docs](https://create.roblox.com/docs/production/publishing/console-guidelines)).
- **Alternatives considered**: pure Scale + `UIAspectRatioConstraint` + `UISizeConstraint` +
  `TextScaled` (original Phase 1 wording) — rejected: Scale cannot express "above the hotbar",
  and `TextScaled` shrinks text below the 18/20 minimum on phones. `UIScale` on the whole window —
  rejected for the same reason (scales text below the minimum).

## R3. Reference geometry and window proportions

- **Decision**: one layout module `ResponsiveLayout` with these constants (Offset units):
  - Menu column: buttons 56×56, gap 8, left margin 12, capacity 4 buttons (248 tall); vertically
    centred in the space below the currency display.
  - Hotbar, touch mode: 3 slots 64×64, gap 8 (208×64), bottom margin 12, horizontally centred in
    the gap between the thumbstick zone and the jump button (R5). Hotbar, keyboard/gamepad mode:
    unchanged from today (340×110, bottom-centre, 20 from the bottom).
  - Windows: free area = from the menu column's right edge + 12 to the right edge − 12, and from
    the top + 8 to the hotbar's top − 8. Height cap = 85% of the free height on phones; on
    tablet/PC `min(85% of free height, 60% of ScreenGui height)`. Size = largest rectangle with the
    window's aspect ratio inside (free width, height cap), then capped at the window's max size,
    centred in the free area.
  - Shop: aspect 1.85, max 960×520. Inventory: aspect 1.4, max 700×500.
  - Phone vs tablet/PC: phone when the viewport's shorter side ≤ 500 — the same threshold Roblox
    uses to size its own touch controls.
- **Worked numbers** (ScreenGui height = viewport − 36 top bar; to be confirmed in the emulator):

  | Screen | Mode | Hotbar | Shop window | Inventory window |
  |---|---|---|---|---|
  | 844×390 phone | touch | 208×64, x 439–647 | 412×223 | 312×223 |
  | 667×375 phone | touch | 208×64, x 315–523 | 388×210 | 294×210 |
  | 1024×768 tablet | touch | 208×64, x 528–736 | 813×439 | 615×439 |
  | 1920×1080 PC | keyboard | 340×110 (today) | 960×519 | 700×500 |
  | 2560×1080 PC | keyboard | 340×110 (today) | 960×519 | 700×500 |

- **Rationale**: on a landscape phone height is the scarce dimension; the old 800×550 (1.45)
  proportion would give a 223-tall shop only 323 wide, too narrow for a category list plus item
  details. 1.85 gives 412 wide on the phone and still a sensible 960×519 on PC. The aspect is the
  same on every device, as FR-004 / User Story 2 require.
- **Alternatives considered**: keep 1.45 — rejected (too narrow on phones); a different aspect per
  device — rejected by the spec (same proportions everywhere); full-width panels on phones —
  rejected in clarification Q4.

## R4. Input mode detection

- **Decision**: `InputActions` keeps a current mode `Touch | KeyboardMouse | Gamepad`, derived
  from `UserInputService:GetLastInputType()` at start and updated on `LastInputTypeChanged`
  (`Touch` → Touch; `Keyboard`, `MouseButton*`, `MouseMovement`, `MouseWheel` → KeyboardMouse;
  `Gamepad1..8` → Gamepad; other types keep the previous mode). If the last input type is
  unknown at start, `TouchEnabled and not KeyboardEnabled` means Touch, otherwise KeyboardMouse.
  A `ModeChanged` signal re-applies hints and layout.
- **Rationale**: Roblox and the mobile-button guide recommend the last input type over
  `TouchEnabled`, which is also true on touchscreen laptops
  ([DevForum, mobile buttons](https://devforum.roblox.com/t/the-correct-way-to-design-mobile-buttons/2494558)).
  Prompts must follow the active input method
  ([Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design)).
- **Alternatives considered**: `TouchEnabled`/`GamepadEnabled` flags — rejected (do not change
  when the player switches input mid-session, SC/US5-3).

## R5. Where Roblox's touch controls are

- **Decision**: avoid two zones on touch:
  - Jump button: read the live `PlayerGui.TouchGui.TouchControlFrame.JumpButton` absolute rect
    when it exists; otherwise use Roblox's formula — screens whose shorter side ≤ 500: 70×70 at
    `(1, −95, 1, −90)`; larger: 120×120 at `(1, −170, 1, −210)`.
  - Thumbstick zone: the bottom-left area, taken as the left 40% of the viewport width and the
    lower two thirds of its height (Roblox's dynamic thumbstick area).
  The hotbar goes between them; the menu column sits at the far-left edge, which overlaps the
  edge of the thumbstick zone (accepted, see risk below).
- **Rationale**: the jump-button formula comes from Roblox's touch script as quoted on the
  DevForum ([mobile buttons](https://devforum.roblox.com/t/the-correct-way-to-design-mobile-buttons/2494558),
  [jump button placement](https://devforum.roblox.com/t/figuring-out-where-the-jump-button-placement/3915124));
  reading the live button follows any future Roblox change.
- **Risk**: the thumbstick-zone size is taken from Roblox's player scripts, not from a public
  doc — verify it in the emulator (quickstart step Q4). A touch that starts on a GUI button does
  not start the thumbstick, so the menu column at the edge does not block movement; Pet Simulator
  99 uses the same left-edge column. If the emulator shows conflicts, move the column above the
  zone (y < 1/3 of the screen) — a constant change.
- **Alternatives considered**: move the column to the top like Grow a Garden's teleport buttons —
  rejected for now: the top centre is taken by the day/night indicator and the top-left by
  currency and the Roblox menu; revisit in Phase 2 when teleport buttons arrive.

## R6. Taps on the backdrop must not reach the world

- **Decision**: tool use in `HotbarController` (today `Mouse.Button1Down`) ignores a press when a
  window is open or when `PlayerGui:GetGuiObjectsAtPosition(x, y)` contains an `Active` GUI
  object. The backdrop is a full-screen `TextButton` (no text, `AutoButtonColor = false`), so it
  is `Active` and also sinks the press for other input listeners.
- **Rationale**: `PlayerMouse.Button1Down` fires even when the press is on a GUI element, so
  without a guard a tap on the backdrop (or a hotbar slot) over a plot would also water or plant
  it, breaking FR-008.
- **Alternatives considered**: switch tool use to `UserInputService.InputBegan` with
  `gameProcessed` — also valid, but a bigger change to the plot-click path; can follow later.

## R7. Single-window state and layering

- **Decision**: a small `WindowManager` (client util) owns the open window (`nil | "Shop" |
  "Inventory"`): `Open(name)` closes the other first, `Toggle(name)`, `Close()`. Opening and
  closing are immediate (`ScreenGui.Enabled`), so repeated presses cannot leave a half state
  (FR-017, SC-006). `UIController.ToggleShop/ToggleInventory/CloseAllUIs/GetUIState` keep their
  signatures and delegate to it, so existing callers keep working. Layering via `DisplayOrder`:
  `HUD` (currency, day/night) 0, `InventoryUI`/`ShopUI` 5, new `HUDControls` (menu column +
  hotbar) 10, so the column and hotbar stay above the backdrop (clarification Q3).
- **Rationale**: one state variable replaces the two booleans that toggle each other today;
  moving the hotbar and menu column into their own ScreenGui is the only way to keep them above
  a window's backdrop while currency and the day/night indicator stay underneath.
- **Alternatives considered**: keep everything in `HUD` above the windows — rejected: the
  day/night indicator would draw over the shop window on phones.

## R8. Gamepad navigation and the B button

- **Decision**: window frames set `SelectionGroup = true` with `SelectionBehavior*` = `Stop`, so
  D-pad/stick navigation stays inside the open window; buttons inside are `Selectable`. On open
  in Gamepad mode `GuiService.SelectedObject` is set to the window's default button (shop: first
  category; inventory: Seeds tab); on close it is restored to what it was before (normally
  `nil`). A presses the highlighted button (built-in). `CloseWindow` is bound to `ButtonB` only
  while a window is open, at `ContextActionPriority.High`, and unbound on close so B keeps its
  default behaviour otherwise. As a fallback, if `SelectedObject` becomes `nil` while a window is
  open in Gamepad mode (Roblox's own B handling), the window closes too.
- **Rationale**: baseline console controls are directions, select and back, and every element
  must be reachable with them
  ([Console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines));
  A accepts and B cancels
  ([Gamepad input](https://create.roblox.com/docs/input/gamepad)).
- **Risk**: whether a CAS binding on B fires before Roblox clears the GUI selection must be
  checked with the Studio controller emulator (quickstart Q6); the fallback covers either order.

## R9. Gamepad glyphs and key labels

- **Decision**: each menu button and each hotbar end carries two hint elements from the static
  GUI: `KeyHint` (TextLabel, e.g. "B", "I", "1"–"3") and `PadHint` (ImageLabel). `InputActions`
  shows `KeyHint` in KeyboardMouse mode, `PadHint` in Gamepad mode (image from
  `UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonY)` etc., which returns the right
  Xbox/PlayStation glyph), neither in Touch mode.
- **Rationale**: Roblox provides these images as drop-in glyphs
  ([Console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines)).
- **Alternatives considered**: own glyph images — rejected, no assets yet (icons are Phase 2).

## R10. Theme tokens for new and changed elements

- **Decision**: add `ReplicatedStorage/UITheme.lua` with named colour tokens holding today's dark
  palette (Surface, SurfaceRaised, Header, Control, ControlHover, Accent, Danger, TextPrimary,
  TextMuted, Backdrop + BackdropTransparency). Builders read colours for new and changed
  elements from it; `build_models.py` loads `UITheme.lua` and exposes it to the builders as a
  global, and in Studio builders `require` the module. Phase 4 adds the day palette and runtime
  switching.
- **Rationale**: constitution principle V requires new or changed UI to use theme tokens rather
  than hard-coded colours; this keeps one source for the colours without starting Phase 4.
- **Alternatives considered**: keep literal colours and record a deviation — rejected, the cost
  of a token module is small and it is needed in Phase 4 anyway.

## R11. Landscape lock and safe area

- **Decision**: set `StarterGui.ScreenOrientation = LandscapeSensor` in `default.project.json`
  (`$properties`) and in Studio. Set `ScreenInsets = CoreUISafeInsets` explicitly on `HUD`,
  `HUDControls`, `InventoryUI`, `ShopUI` (it is the default today, but explicit keeps it in the
  model files); `IgnoreGuiInset = false`.
- **Rationale**: `LandscapeSensor` keeps landscape and follows the device between the two
  landscape directions (User Story 6); `CoreUISafeInsets` keeps interactive UI clear of the Roblox
  top bar and device cut-outs
  ([On-screen UI containers](https://create.roblox.com/docs/ui/on-screen-containers)).
- **Alternatives considered**: `LandscapeLeft`/`LandscapeRight` — rejected, they lock one
  direction and ignore the device's rotation.

## R12. Testing approach

- **Decision**: (1) pure-logic unit tests for `ResponsiveLayout` run with the Luau CLI
  (`Tools/Tests/responsive_layout.spec.luau`), asserting the rules for all five reference
  screens: windows inside the free area, no overlap with menu column/hotbar/jump button/
  thumbstick zone, tap targets ≥ 44, height caps. (2) The static GUI generator's fingerprint
  parity between repo and Studio. (3) Studio playtests via Studio MCP plus the device emulator and
  controller emulator, as listed in `quickstart.md`.
- **Rationale**: there is no gameplay CI; the layout math is the part most likely to regress
  across screens and is easy to test offline. Constitution principle VI requires a clean Studio
  playtest.
- **Alternatives considered**: TestEZ inside Studio — more setup for the same coverage of pure
  math; can be added later.
