# Contract: Input actions

The complete action set for Phase 1. `InputActions` binds every row through
`ContextActionService:BindActionAtPriority(name, handler, false, Enum.ContextActionPriority.High.Value, ...)`
(High is above the camera's own key bindings, which is why I already uses it today).
On-screen touch buttons are the static GUI buttons below, not CAS-generated buttons.

| Action | Keyboard | Gamepad | Touch / mouse | Scope | Handler |
|---|---|---|---|---|---|
| `ToggleInventory` | I | Y | `HUDControls.MenuButtons.InventoryButton` | always | `WindowManager.Toggle("Inventory")` |
| `ToggleShop` | B | X | `HUDControls.MenuButtons.ShopButton` | always | `WindowManager.Toggle("Shop")` |
| `CloseWindow` | — | B | `CloseButton` in the window header; `Backdrop` | windowOpen | `WindowManager.Close()` |
| `HotbarSlot1..3` | 1, 2, 3 | — | `HUDControls.Hotbar.SlotN.SlotButton` | always | `HotbarController.EquipSlot(N)` |
| `HotbarPrev` | — | L1 | — | always | `HotbarController.PreviousSlot()` |
| `HotbarNext` | — | R1 | — | always | `HotbarController.NextSlot()` |
| navigate in window | — | D-pad, left stick | — | built-in GUI selection | `SelectionGroup` on the window frame |
| press highlighted | — | A | — | built-in | GUI button `Activated` |

Notes:
- Escape, Start, Select, both thumbsticks and R2 keep Roblox's default behaviour; no game action
  depends on Escape (FR-009). The existing Escape handler in `UIController` is removed.
- `CloseWindow` on B is bound only while a window is open, so outside windows B is untouched.
- ContextActionService does not run actions while a TextBox (chat) has focus (FR-014).
- Touch and mouse buttons use `Activated`, which also fires for gamepad A on a highlighted
  button.

## Hints per input mode

| Element | KeyboardMouse | Gamepad | Touch |
|---|---|---|---|
| `ShopButton.KeyHint` | "B" | hidden | hidden |
| `ShopButton.PadHint` | hidden | glyph `ButtonX` | hidden |
| `InventoryButton.KeyHint` | "I" | hidden | hidden |
| `InventoryButton.PadHint` | hidden | glyph `ButtonY` | hidden |
| `Hotbar.SlotN.KeybindHint` | "1"–"3" | hidden | hidden |
| `Hotbar.PadHintLeft` / `PadHintRight` | hidden | glyphs `ButtonL1` / `ButtonR1` | hidden |

Glyph images come from `UserInputService:GetImageForKeyCode(keyCode)`.

## Module API (client)

```text
InputActions.Init()                         -- detect mode, bind "always" actions
InputActions.GetMode() -> InputMode
InputActions.ModeChanged : signal(newMode, oldMode)
InputActions.BindWindowActions()            -- called by WindowManager on open
InputActions.UnbindWindowActions()          -- called by WindowManager on close

WindowManager.Register(name, windowSpec)    -- see data-model.md › Window
WindowManager.Toggle(name)
WindowManager.Open(name)
WindowManager.Close()
WindowManager.GetOpen() -> name?
WindowManager.Changed : signal(openName?, previousName?)

UIController.ToggleInventory() / ToggleShop() / CloseAllUIs() / GetUIState()
                                            -- unchanged signatures, delegate to WindowManager
```
