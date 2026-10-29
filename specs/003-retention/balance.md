# Balance — Retention (Phase 3)

**Feature**: `003-retention` | **Date**: 2026-10-29

These numbers are the single source for `ReplicatedStorage/RetentionConfig.lua` (constitution II). The
offline test `Tools/Tests/retention_config.spec.luau` checks the config against this document; if a
number changes here, update the config and the test's expected table together. Context: players start
with 50 coins / 0 DreamSeeds; crop sell values run 8 (carrot) → 130 (dreamroot); seed prices 5 → 60
(see `specs/002-buy-sell-economy/balance.md`). `DayLengthSec = 300`, `NightLengthSec = 180`.

## Daily reward — 7-day streak

Coins are non-decreasing across the week; DreamSeeds appear on milestone days. After day 7 the track
loops to day 1.

| Streak day | Coins | DreamSeeds |
|---|---|---|
| 1 | 25 | 0 |
| 2 | 40 | 0 |
| 3 | 60 | 0 |
| 4 | 90 | 1 |
| 5 | 120 | 0 |
| 6 | 160 | 2 |
| 7 | 250 | 5 |

Rationale: day 1 ≈ five carrot sales, enough to re-seed; day 7 ≈ a Dreamroot seed plus premium
currency, a clear reason to keep the streak. Total week ≈ 745 coins + 8 DreamSeeds.

## Daily quests

`QuestsPerDay = 3`, chosen deterministically from the pool by day index (research R3). Pool size (6) is
greater than `QuestsPerDay`. `kind` matches a server event: `plant`, `harvest`, `sell`, `catch_spirit`.

| id | kind | target | Coins | DreamSeeds | Text |
|---|---|---|---|---|---|
| plant_5 | plant | 5 | 30 | 0 | Plant 5 seeds |
| harvest_3 | harvest | 3 | 40 | 0 | Harvest 3 crops |
| sell_5 | sell | 5 | 50 | 0 | Sell 5 crops |
| catch_3 | catch_spirit | 3 | 0 | 3 | Catch 3 spirits at night |
| plant_10 | plant | 10 | 60 | 0 | Plant 10 seeds |
| sell_10 | sell | 10 | 90 | 0 | Sell 10 crops |

Rationale: quest rewards (30–90 coins) sit between a single sale and the daily reward, so a day's three
quests ≈ one daily-reward tier. `catch_spirit` pays DreamSeeds to tie the night loop to premium
currency. Targets are reachable within one session.

## Shop restock

- **RestockIntervalSec = 300** (5 minutes — aligned with the day length and the Grow a Garden cadence).
- Stock is per item, per server, per window; it refills to the value below at each window boundary.
- Items **not** listed are unlimited (no stock cap) — notably the free `basic_watering_can`.

| itemId | Category | Stock per window |
|---|---|---|
| carrot_seed | seeds | 20 |
| wheat_seed | seeds | 20 |
| tomato_seed | seeds | 12 |
| pumpkin_seed | seeds | 10 |
| moonflower_seed | seeds | 6 |
| starberry_seed | seeds | 4 |
| dreamroot_seed | seeds | 2 |
| improved_watering_can | tools | 3 |
| fertilizer | items | 10 |
| dream_dust | items | 5 |

Rationale: rarer/more valuable items are scarcer per window, so a restock is worth returning for; common
seeds stay plentiful so the core loop never stalls. Every stock key must resolve to a known item in
`ShopConfig`/`PlantData` (checked by the offline test).

## Night event

- Rare-spirit announcement fires for spirit tiers **Rare** and **Epic** (from `SpiritTypes`:
  Common 70 / Rare 25 / Epic 5 weights); **Common** never announces.
- Client announcement de-dupe window: **5 s** (ignore a new announcement within 5 s of the last).
- Nightfall banner duration: **2.5 s**, non-blocking.

## Onboarding

- Steps, in order: `go_to_plot` → `plant` → `water` → `sell`. Advance on the matching event; Skip at any
  step. No rewards attached (kept separate from quests); completion persists (`Onboarding.Done = true`).
