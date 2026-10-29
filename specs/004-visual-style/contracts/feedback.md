# Contract — Feedback (sounds + window-open animation)

Client-only. No remote, no server change. Sound asset ids are owner-supplied.

## `ReplicatedStorage/UISound.lua` (single source)

```lua
return {
    Press    = "",   -- owner-supplied rbxassetid://… ; "" = silent
    Purchase = "",   -- owner-supplied rbxassetid://… ; "" = silent
    Volume   = 0.5,  -- one volume for all UI sounds (0..1)
}
```

- An empty/`nil`/invalid id MUST play nothing and raise no error (the controller wraps play in
  `pcall` and skips an empty id).
- Volume applies to every UI sound. No other volumes exist for UI.

## `SoundController` (client)

| Member | Behaviour |
|---|---|
| `Press()` | Play `UISound.Press` at `Volume`. Rate-limited: ignore if called within ~60 ms of the last press (FR-018). No-op on empty id or sound-off. |
| `Purchase()` | Play `UISound.Purchase` at `Volume`. No-op on empty id or sound-off. |
| (internal) | One reusable `Sound` parented under `SoundService`; `SoundId` swapped per play; never yields the caller; never blocks or alters the triggering action (FR-016). |

- **Sound-off rule**: UI sounds honour the project's single sound setting. If the game's sound is off
  (muted master `SoundGroup` / the project's sound flag), `Press`/`Purchase` are no-ops (FR-017).
- The controller is required lazily and cached by its callers (same pattern as `ToastQueue` in
  `UIController`), so no hard load-order dependency.

## Who plays what

| Control | Sound | Where wired |
|---|---|---|
| Menu buttons (Shop, Inventory, Rewards, Quests) | Press | `UIController` (owns these `Activated`) |
| Teleport buttons (Shop, Garden, Stall) | Press | `UIController` (TeleportRow) |
| Window close (X) / backdrop tap / gamepad B | Press | `WindowManager` close path |
| Tabs (shop/inventory categories) | Press | the owning controller's tab wiring |
| Buy ×1/×5/×10 | Press on activation | `ShopController` |
| **Buy success (server-confirmed)** | **Purchase** | `ShopController`, only on the success branch of the `BuyItem` response (I) |
| Sell / Sell-all / favourite / confirm | Press | `SellController` |
| Claim (daily reward / quest) | Press | `DailyRewardController` / `QuestController` |

- Press rides existing `Activated` connections — no new bindings, so touch/mouse/gamepad all trigger
  it. Synthetic Studio-MCP clicks do not fire `Activated` (known), so the owner verifies audibly.
- Purchase MUST NOT play on a rejected/failed buy (FR-014): it sits strictly inside the success branch.

## Window-open animation

| Member | Behaviour |
|---|---|
| `GuiEffects.openWindow(frame)` | On open: set `frame` to a slightly smaller scale (~0.92 of its target) and raised `GroupTransparency`/`BackgroundTransparency`, then tween to full size + opaque over ~0.18 s, `Quad`/`Out`. The frame stays interactive throughout; only visuals animate (FR-015). Idempotent and safe to call each open. |
| `WindowManager.Open(name)` | After showing the frame (existing logic unchanged), call `GuiEffects.openWindow(frame)`. The one-window-at-a-time, backdrop and selection logic are untouched. |

- No close animation is required by the spec; closing stays instant (keeps the one-window switch
  snappy). A close fade MAY be added later but is out of scope here.
- The animation duration lives once in `GuiEffects`; the colour-retint duration lives once in
  `ThemeController` (II).
