# Contract: Retention Remotes (server-authoritative)

**Feature**: `003-retention` | **Date**: 2026-10-29

Every remote is created in `ServerScriptService/CreateRemotes.lua` and bound in `RemoteHandlers.lua`,
following the existing pattern: `pcall` wrapper, `rate_ok(player, key)` (5 req/s), strict
type/range/ownership checks, `fail(msg)` closed on bad input, `AntiCheat.log` on suspicious input, and a
success payload `{ Success = true, ... }`. The client never sends reward amounts, quest progress, sell
totals or stock counts; the server reads them from `RetentionConfig`/profile (constitution I).

## New RemoteFunctions

### `GetDailyReward(player) → { Success, StreakDay, LastClaimDay, Claimable, Today, Rewards }`
Read-only. `Rewards` = `RetentionConfig.DailyRewards` (7 entries). `Claimable = DayIndex(now) >
LastClaimDay`. `Today` = the streak day that a claim now would grant (next on the track, or 1 on
reset/loop). Rejects: rate exceeded; data not loaded.

### `ClaimDailyReward(player) → { Success, StreakDay, Granted = {coins, seeds}, NewBalance }`
Grants the current day's reward **iff** `Claimable`; advances/resets/loops `StreakDay`, sets
`LastClaimDay = DayIndex(now)`, credits coins/seeds via `PlayerData.AddCoins`/`AddDreamSeeds`, fires
`UpdateCurrency`. Rejects (fail closed): already claimed today (`DayIndex ≤ LastClaimDay`); rate
exceeded; data not loaded. Idempotent within a day — a second call returns `Success=false, Error="Already
claimed"`.

### `GetQuests(player) → { Success, Day, Quests = { {id, kind, target, progress, reward, text, claimed} } }`
Ensures the player's set matches `DayIndex(now)` (rebuilds + resets progress/claims if the day rolled
over), then returns the day's quests with per-player `progress` and `claimed`. Rejects: rate exceeded;
data not loaded.

### `ClaimQuest(player, questId) → { Success, QuestId, Granted = {coins, seeds}, NewBalance }`
Validates `questId` is in the player's current day set, `Progress[id] ≥ target`, and `not Claimed[id]`;
grants the reward once, sets `Claimed[id] = true`, fires `UpdateCurrency`. Rejects (fail closed):
unknown/out-of-set id; not complete; already claimed; bad type; rate exceeded.

### `SetTutorialDone(player) → { Success }`
Sets `Onboarding.Done = true` (write-once-true). Accepts completion or skip. Rejects: rate exceeded;
data not loaded. Harmless if already done.

## Extended RemoteFunctions

### `GetShopData(player) → { Success, Config = { buy, sell }, PlayerCoins, Stock, RestockAt, Interval }`
**Adds** `Stock = { [itemId] = remaining }` for the current window (unlimited items omitted),
`RestockAt` (server `os.time()` of the next window boundary) and `Interval` (`RestockIntervalSec`). The
client computes the countdown from `RestockAt` minus its synced server time. Existing fields unchanged.

### `BuyItem(player, category, itemId, quantity) → { Success, ItemName, Quantity, NewBalance, NewInventory, Stock }`
**Change**: after quantity validation and before spending coins, call
`ShopStockService.TryReserve(itemId, quantity)`; on false, `fail("Out of stock")` with no coin spend and
no grant. On success, proceed as today and return the item's updated `Stock` (remaining, or `nil` if
unlimited). Unlimited items skip the reservation. All existing rejections unchanged.

## New server→client events

### `QuestUpdated` (RemoteEvent, `FireClient`)  (US2)
Fired by `QuestService.Track`/`ClaimQuest` with `(questId, progress, claimed)` so an open Quests window
updates without a refetch.

### `ShopRestocked` (RemoteEvent, `FireAllClients`)  (US3)
Fired by `ShopStockService` at a window boundary with `(RestockAt, Stock)`; the client refills stock
labels, resets the countdown and shows a restock toast.

### `ServerAnnounce` (RemoteEvent, `FireAllClients`)  (US4)
Fired by `SpiritSpawner` on a Rare/Epic spawn with `(kind, name, rarity)` (`kind = "rare_spirit"`); the
client shows a rate-limited server-wide announcement. Reserved for future event kinds.

## Nightfall (no new remote)

The Day→Night banner is driven entirely by the existing `DayNightUpdate(phase, progress)` event
(`DayNightManager`): the client shows the banner on the `Day → Night` edge and clears it on a timer
(R8). No server change.

## Validation matrix (fail closed — FR-013)

| Remote | Rejects when |
|---|---|
| `GetDailyReward` | rate exceeded; no data |
| `ClaimDailyReward` | already claimed today (`DayIndex ≤ LastClaimDay`); rate exceeded; no data |
| `GetQuests` | rate exceeded; no data |
| `ClaimQuest` | id not in today's set; not complete; already claimed; bad type; rate exceeded |
| `SetTutorialDone` | rate exceeded; no data |
| `BuyItem` (ext.) | **out of stock**; + all existing (price ≤ 0; not enough coins; bad qty/types; rate) |
| `GetShopData` (ext.) | rate exceeded; no data |

## Server authority notes

- Day index, streak transitions, quest-day rollover and stock windows are all computed from `os.time()`
  on the server; the client never sends a day, time or stock.
- Quest progress is incremented **only** from authoritative server events via `QuestService.Track`
  (plant/harvest in `PlotManager`, sell in `RemoteHandlers`, catch in `SpiritCollector`) — never from a
  client report (R6).
- Shop stock lives only on the server; `TryReserve` is a single check-and-decrement (atomic under
  single-threaded Luau), so concurrent buys on one server cannot oversell (R5).
