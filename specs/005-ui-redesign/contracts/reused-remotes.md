# Contract: Reused Remotes (no new remotes in Stage 1)

This feature adds **no new RemoteEvents/RemoteFunctions**. It reuses the existing ones unchanged; the
server remains the authority (Constitution I). Listed here so the plan/tasks reference exact names and
the review confirms no new server surface was introduced.

| Remote | Kind | Call site (client) | Args | Reply / effect | Used by |
|--------|------|---------------------|------|----------------|---------|
| `RequestTeleport` | RemoteFunction | `UIController` nav | `targetId ∈ {"shop","garden","stall"}` | server moves player; rate-limited | GARDEN, SELL (stall) |
| `GetShopData` | RemoteFunction | `ShopController.LoadShopData` | — | `{Success, Config, PlayerCoins, Stock, RestockAt, Interval}` | Shop cards/stock |
| `BuyItem` | RemoteFunction | `ShopController.Buy` | `(category, itemId, qty)` | `{Success, NewBalance, NewInventory, Stock, Error}` | Shop buy |
| `EquipTool` | RemoteEvent | `HotbarController.equipCurrent` | `(serverTool)` | server equips | Backpack Equip, hotbar |
| `ToggleFavourite` | RemoteFunction | Backpack detail favourite | `(itemName)` | server flips favourite | favourite mark |
| `SellItem` / `SellAll` | RemoteFunction | SellController (reused) | per existing | per existing | SELL window |
| `DayNightUpdate` | RemoteEvent (S→C) | `EventHandlers`, `ThemeController`, UIController | `(phase, progress)` | phase pill + theme repaint | PhasePill, theme |
| `UpdateCurrency` | RemoteEvent (S→C) | StateManager → `UIController.UpdateCurrency` | `(coins, dreamSeeds, …)` | HUD currencies | coins + Dream Seeds |
| `UpdateInventory` | RemoteEvent (S→C) | StateManager → InventoryController | inventory snapshot | Backpack grid | inventory cards |

## Invariants the UI MUST preserve (Constitution I)

- The client sends only `(category, itemId, qty)` to `BuyItem`; it MUST NOT send a computed total price.
  The disabled "Can't afford / exceeds stock" states are **UX hints only**; the server revalidates and
  may still reject (window stays open, selection preserved — FR-013).
- Equip sends only the item/tool identity to `EquipTool`; no client-side grant of tools.
- Favourite state is flipped through `ToggleFavourite`; the UI reflects the server's result.
- The phase/timer pill is derived from `DayNightUpdate`; the client runs no independent day/night clock
  (FR-004).

## New UI entry points (client-side only, no server change)

These are **client controller functions** the redesign adds to wire reused remotes to the new layout —
not remotes:

- `ShopController.OpenOnTab(tabId)` (or an `openArg` passed through `WindowManager.onOpen`) — preselect
  the Seeds tab when opened from the SEEDS nav (R5). Smaller-diff option chosen in tasks.
- `HotbarController.EquipByItemName(itemName)` (or select-matching-slot) — lets the Backpack Equip
  action equip through the existing `EquipTool` path (R6).
- `UIController` wiring of QUESTS and GIFTS `.Activated` (the confirmed touch-wiring gap, R2).
