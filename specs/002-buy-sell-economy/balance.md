# Balance Document: Buy–Sell Economy (Phase 2)

**Feature**: `002-buy-sell-economy` | **Date**: 2026-10-29 | **Status**: PROPOSED

The single written source for the economy numbers (FR-006). These values are transcribed verbatim
into `ReplicatedStorage/PlantData.lua` and `ReplicatedStorage/ShopConfig.lua`; nothing here may be
duplicated or contradicted in controllers, GUI text or builders (constitution II). Numbers below are
a **proposed starting balance** — review and finalize during `/speckit-implement`; whatever is in
config at merge MUST match this file (SC-003).

Starting coins (`DefaultData`): **50**. Night phase length **180s**, day **300s** (`GameSettings`).

## Seeds → Crops (plantable)

| Seed (buy) | Buy ¢ | Rarity | Grows | Phase | → Crop | Sell ¢ | Margin ¢ |
|---|---:|---|---:|---|---|---:|---:|
| carrot_seed | 5 | Common | 120s | any | carrot_crop | 8 | +3 |
| wheat_seed | 6 | Common | 150s | any | wheat_crop | 10 | +4 |
| tomato_seed | 8 | Uncommon | 180s | any | tomato_crop | 14 | +6 |
| pumpkin_seed | 12 | Uncommon | 240s | any | pumpkin_crop | 21 | +9 |
| moonflower_seed | 20 | Rare | 200s (night) | **night** | moonflower_crop | 38 | +18 |
| starberry_seed | 28 | Epic | 210s (night) | **night** | starberry_crop | 55 | +27 |
| dreamroot_seed | 60 | Legendary | 300s (night) | **night** | dreamroot_crop | 130 | +70 |

Notes: night seeds advance growth only during the night phase (FR-007), so wall-clock time to ripen
is longer than `growTime` when days intervene; sell value is a normal value (not boosted).
**Dreamroot** is the premium night plant (Legendary).

## Tools (buy)

| Tool | Buy ¢ | Rarity | Notes |
|---|---:|---|---|
| basic_watering_can | 0 | Common | Starting tool (owned by default) |
| improved_watering_can | 50 | Rare | Faster/stronger watering (behaviour unchanged this phase) |

## Items (buy) — non-plant consumables

| Item | Buy ¢ | Rarity | Notes |
|---|---:|---|---|
| fertilizer | 15 | Uncommon | Placeholder Items-category content (effect out of scope this phase) |
| dream_dust | 40 | Epic | Placeholder premium item; populates Items category (FR-010) |

Tools and items are **not sellable** (FR-001): they have no `sellValue`.

## Rarity tiers → theme tokens (FR-008/018, R10)

| Tier | Token (`UITheme`) | Intended dark-palette colour (finalize in impl) |
|---|---|---|
| Common | `RarityCommon` | neutral grey |
| Uncommon | `RarityUncommon` | green |
| Rare | `RarityRare` | blue |
| Epic | `RarityEpic` | purple |
| Legendary | `RarityLegendary` | gold |

## Invariants (checked by SC-002/003)

- Every crop's `sellValue` is strictly less than its seed's `buyPrice` + a positive margin shown
  above, so the loop is profitable but not trivially so.
- No value appears in more than one place in config (helpers derive, not duplicate).
- Only crops have `sellValue > 0`.
