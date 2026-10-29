# Contract: Economy Remotes (server-authoritative)

**Feature**: `002-buy-sell-economy` | **Date**: 2026-10-29

Every remote is created in `ServerScriptService/CreateRemotes.lua` and bound in
`RemoteHandlers.lua`, following the existing pattern: `pcall` wrapper, `rate_ok(player, key)`
(5 req/s), strict type/ownership checks, `fail(msg)` closed on bad input, `AntiCheat.log` on
suspicious input, and a success payload `{ Success = true, ... }`. The client NEVER sends prices,
sell values or totals; the server reads them from `ShopConfig`/`PlantData` (constitution I).

## Existing (reused, hardened)

### `BuyItem(player, category, itemId, quantity) → RemoteFunction`
Unchanged shape. Validates quantity (`validateQuantity`), reads `buyPrice` from config, spends coins,
adds item. Returns `{ Success, ItemName, Quantity, NewBalance, NewInventory }`. Now also valid for
the Tools and Items categories (FR-010).

### `SellItem(player, itemId, quantity) → RemoteFunction`
**Change**: reject unless the item's `category == "crop"` (FR-001); seeds/tools return
`{ Success=false, Error="Item cannot be sold" }`. A favourited crop MAY be sold here (the client
gated it behind a confirm). Returns `{ Success, ItemName, Quantity, TotalEarned, NewBalance,
NewInventory }` (unchanged).

### `GetShopData(player) → RemoteFunction`
Returns `{ Success, Config = { buy, sell }, PlayerCoins }`. `Config` now carries the full
seeds/tools/items buy catalogue and the crop sell table (data only; helpers stripped).

## New

### `SellAll(player) → RemoteFunction`  (US1, FR-001/004)
Server iterates the player's inventory, selects stacks whose definition is `category == "crop"`,
**excludes any itemId in `Favourites`**, computes `Σ sellValue × count`, consumes them, credits coins,
all atomically. Returns:
```
{ Success = true, SoldCount = <items sold>, TotalEarned = <coins>,
  NewBalance = <coins>, NewInventory = <snapshot>, SkippedFavourites = <n> }
```
Empty/all-favourite case: `Success = true, SoldCount = 0, TotalEarned = 0` (UI shows the empty/"all
protected" message — edge cases). Rejects closed on any inconsistency.

### `ToggleFavourite(player, itemId) → RemoteFunction`  (FR-004)
Validates `itemId` is a known sellable crop and owned-or-knowable; flips membership in the profile
`Favourites` set. Returns `{ Success = true, ItemId, IsFavourite = <bool>, Favourites = <set> }`.

### `RequestTeleport(player, targetId) → RemoteFunction`  (US6, FR-013/019)
Validates `targetId ∈ { "shop", "garden", "stall" }` and rate-limits; moves the caller's
`HumanoidRootPart` to the matching world anchor. Returns `{ Success = true, Target = targetId }` or
`fail` on unknown target / missing character.

## Stall interaction (US1, FR-002)

The seller's stall uses a Roblox **ProximityPrompt** (`E`/hold on PC; the engine surfaces an
on-screen button on touch and a gamepad button) placed on the seller model, with its trigger range =
the stall range. Triggering it (server-side `Triggered` or a thin client→`OpenSellWindow` path) opens
the sell window; selling itself always goes through `SellItem`/`SellAll` above. When the player leaves
range, the prompt hides and the sell window closes / sell is blocked (edge case).

## Server → client events (reused)

`UpdateCurrency`, `UpdateInventory`, `PlotStateChanged` (carries `ReadyToHarvest`), `SpiritCollected`
drive the toast and "+N coins" feedback (US4/US7); no new event is required, though an optional
`CoinsGained(amount, worldPosition)` event MAY be added if the harvest "+N" needs a server-authored
position.

## Validation matrix (fail closed — FR-005/019)

| Remote | Rejects when |
|---|---|
| `SellItem` | not a crop; not owned in qty; bad types; rate exceeded |
| `SellAll` | — (no-op if nothing sellable); rate exceeded |
| `ToggleFavourite` | unknown/non-crop itemId; bad type; rate exceeded |
| `RequestTeleport` | targetId not in the fixed set; no character; rate exceeded |
| `BuyItem` | price ≤ 0; not enough coins; bad qty/types; rate exceeded |
