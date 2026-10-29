# Phase 1 Data Model: Buy–Sell Economy (Phase 2)

**Feature**: `002-buy-sell-economy` | **Date**: 2026-10-29

Entities from the spec's Key Entities, grounded in the config modules
(`ReplicatedStorage`), the profile (`DefaultData`) and the server services. All numbers live in
config (constitution II); this file describes **shape**, not values (values are in
[balance.md](./balance.md)).

## ItemDefinition (`PlantData`)

The single definition for every shop/inventory/plant entity. One table keyed by itemId.

| Field | Type | Notes |
|---|---|---|
| `displayName` | string | Shown in shop/inventory/hotbar |
| `category` | string | `"seed" | "tool" | "item" | "crop"` |
| `rarity` | string | `"Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"` |
| `buyPrice` | number | Coins to buy; `0`/absent = not purchasable (e.g. crops) |
| `sellValue` | number | Coins when sold; `>0` only for crops (FR-001) |
| `growthTimeSec` | number | Seeds/plants: time to ripen (accrued per R3) |
| `dayNight` | string | `"day" | "night" | "any"` — growth phase gate (FR-007) |
| `icon` | string | `rbxassetid://…` or `""` → fallback (FR-015) |
| `seedId` / `cropId` | string? | Link seed ↔ crop (plant → harvest → sell) |

**Rules**: a `crop` has `sellValue > 0`, `buyPrice` absent, and is the only sellable category
(FR-001). A `seed` has `buyPrice > 0`, `growthTimeSec`, `dayNight`, and a `cropId`. Night plants
(Moonflower, Starberry, **Dreamroot**) have `dayNight = "night"`. Validation: every `seedId`/`cropId`
referenced MUST resolve to a defined itemId (checked offline + at load).

## ShopCatalogue (`ShopConfig`)

Derived from `PlantData`; the buyable items per category and the sell table.

| Part | Shape | Notes |
|---|---|---|
| `buy.seeds` / `buy.tools` / `buy.items` | `{ [itemId] = { price } }` | All three categories populated (FR-010) |
| `sell` | `{ [cropId] = { price } }` | Crops only (FR-001) |
| Helpers | functions | `GetBuyPrice`, `GetSellPrice`, `CanSell`, `GetRarity`, `IsNightPlant`, `GetCategoryItems` |

Helper functions are stripped on the wire; `GetShopData` sends only `{ buy, sell }` data plus
`PlayerCoins` (as today).

## PlayerProfile additions (`DefaultData`, SchemaVersion → 2)

| Field | Type | Default | Notes |
|---|---|---|---|
| `Favourites` | `{ [itemId] = true }` | `{}` | Excluded from `SellAll` (FR-004); server-owned |
| `Inventory[newItems]` | number | `0` | New crops/seeds (night plants, Dreamroot) |
| `Plots[*].GrowthSeconds` | number | `0` | Phase-gated growth accumulator (R3/FR-007) |

Reconcile against `DefaultData` on load — add missing fields, never drop (constitution II).

## Plot (growth state) — change

Existing `Plots[plotId]` gains `GrowthSeconds`. Per tick (`PlantGrowthService`):
`GrowthSeconds += dt` **iff** the plant's `dayNight` allows the current `DayNightManager.GetPhase()`
(`"any"`/`"day"` always; `"night"` only at Night). `GrowthProgress = clamp(GrowthSeconds /
growthTimeSec, 0, 1)`; `>= 1` → `ReadyToHarvest`. `PlantedAt` retained for compatibility/telemetry.

## SellSession (transient, server-computed)

Not persisted. For `SellAll`: the set of the player's sellable crop stacks **minus favourites**, the
summed coin value, applied atomically. For the sell window UI: the client renders sellable stacks,
each item's `sellValue`, a running total of the current selection/all, and the star (favourite)
state from `Favourites`.

## Toast (transient, client)

| Field | Type | Notes |
|---|---|---|
| `type` | string | `success | error | info | event` → colour token |
| `text` | string | Message |
| `lifetime` | number | Seconds (default `Constants.UI.NOTIFICATION_DURATION`) |

Managed by a FIFO queue/stack; cloned from the static template; pooled.

## HotbarSlot (client view)

A view of an owned inventory item (tool/seed) the player can select and use (R7). Derived from the
inventory snapshot; not persisted. Overflow paged via existing Prev/Next.

## TeleportTarget

Fixed named destinations `{ shop, garden, stall }` → anchor parts in the world. Server validates the
id and performs the move (R8).
