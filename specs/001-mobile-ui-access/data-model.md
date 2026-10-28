# Data Model: Mobile UI Access (001)

Client-side only. Nothing here is persisted or sent to the server (FR-019); these are the
in-memory shapes the new client modules share. Interfaces are in [contracts/](./contracts/).

## InputMode

The player's current input type.

| Value | Set when the last input was | Shows |
|---|---|---|
| `Touch` | `Enum.UserInputType.Touch` | menu buttons and hotbar, no hints |
| `KeyboardMouse` | Keyboard, MouseButton1–3, MouseMovement, MouseWheel | key labels (`KeyHint`) |
| `Gamepad` | Gamepad1–Gamepad8 | gamepad glyphs (`PadHint`), highlight navigation |

- Initial value: from `GetLastInputType()`; if that gives none of the above,
  `TouchEnabled and not KeyboardEnabled` → `Touch`, else `KeyboardMouse`.
- Other input types (Accelerometer, TextInput, …) leave the mode unchanged.
- Transition: any value → any value; each change fires `InputActions.ModeChanged(newMode,
  oldMode)`; only a real change fires it (same mode twice is ignored).

## MenuAction

A named player intent, defined once and bound for all input types (FR-013).

| Field | Type | Notes |
|---|---|---|
| `name` | string | unique, `NightGarden_<Name>` when bound in ContextActionService |
| `keys` | `{Enum.KeyCode}` | keyboard bindings |
| `pad` | `{Enum.KeyCode}` | gamepad bindings |
| `keyLabel` | string? | text for `KeyHint` |
| `padGlyph` | `Enum.KeyCode`? | key whose image fills `PadHint` |
| `scope` | `"always" \| "windowOpen"` | `windowOpen` actions are bound only while a window is open |
| `handler` | `() -> ()` | runs on `UserInputState.Begin` only |

The action set for this feature is listed in [contracts/input-actions.md](./contracts/input-actions.md).

Validation rules:
- No action is bound to `Escape`, `ButtonStart`, `ButtonSelect` or `Thumbstick1/2` (reserved).
- `ButtonA` is never bound as an action; it activates the highlighted GUI button (built-in).
- Handlers return `Sink` so the camera (I = zoom) and other bindings do not also react.

## Window

A panel the player opens over the game (Shop, Inventory; later Rewards, Quests).

| Field | Type | Notes |
|---|---|---|
| `name` | `"Shop" \| "Inventory"` | key in `WindowManager` |
| `gui` | ScreenGui | `ShopUI`, `InventoryUI` |
| `frame` | Frame | `ShopFrame`, `InventoryFrame`; `SelectionGroup = true` |
| `backdrop` | TextButton | full-screen, under the frame |
| `closeButton` | TextButton | ≥ 44×44 |
| `defaultSelection` | GuiObject | highlighted on open in Gamepad mode |
| `aspect`, `maxSize` | number, Vector2 | Shop 1.85 / 960×520; Inventory 1.4 / 700×500 |
| `onOpen` | `() -> ()` | Shop: `ShopController.LoadShopData()`; Inventory: `InventoryController.RefreshGrid()` |

State (owned by `WindowManager`, one variable `openWindow: nil | name`):

```text
            Toggle(A) / Open(A)                 Toggle(B) / Open(B)
  [none] ─────────────────────▶ [A open] ───────────────────────▶ [B open]
     ▲                            │  (A closed first, then B opened, one frame)
     │  Close() / Toggle(A) /     │
     └──── backdrop / X / pad B ──┘
```

Rules:
- At most one window open (FR-003).
- Open/close are immediate (`gui.Enabled`), no waiting on tweens, so repeated presses cannot
  leave a half-open or doubled state (FR-017, SC-006).
- On open: `onOpen()`, bind `windowOpen` actions, and in Gamepad mode remember
  `GuiService.SelectedObject` and select `defaultSelection`.
- On close: unbind `windowOpen` actions, restore the remembered selection.
- Changing the input mode while a window is open re-applies hints and layout; switching to
  Gamepad selects `defaultSelection`.

## LayoutInput → LayoutResult (`ResponsiveLayout.compute`)

Pure function, no Roblox services; unit-tested offline.

**LayoutInput**

| Field | Type | Notes |
|---|---|---|
| `viewport` | `{w, h}` | camera viewport size |
| `gui` | `{x, y, w, h}` | ScreenGui absolute position and size (safe area) |
| `mode` | InputMode | |
| `jump` | `{x, y, w, h}?` | live jump button rect in viewport coordinates, if TouchGui exists |
| `windows` | `{[name]: {aspect, maxW, maxH}}` | |

**LayoutResult** (all rects in ScreenGui coordinates, Offset units)

| Field | Notes |
|---|---|
| `isPhone` | `min(viewport.w, viewport.h) <= 500` |
| `menuColumn` | rect of the 56×56×N column; `buttonSize` = 56 |
| `hotbar` | rect; `slotSize` = 64 (Touch) or 100 (other modes); `gap` |
| `freeArea` | rect available to windows |
| `windows[name]` | rect of each window, centred in `freeArea` |

Invariants (checked by the unit tests for each reference screen):
- every window rect ⊂ `freeArea` ⊂ ScreenGui rect;
- window ∩ menuColumn = ∅, window ∩ hotbar = ∅;
- Touch mode: hotbar ∩ jump = ∅ and hotbar ∩ thumbstick zone = ∅;
- window height ≤ 0.85 × freeArea.h (phone) or ≤ min(0.85 × freeArea.h, 0.6 × gui.h) (tablet/PC);
- window width / height = aspect (± 1 px) and ≤ maxSize;
- menu button and touch hotbar slot ≥ 44 × 44.
