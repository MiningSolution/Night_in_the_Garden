# Data Model — Retention (Phase 3)

**Feature**: `003-retention` | **Date**: 2026-10-29

Covers the persisted profile additions (schema 2 → 3), the server-only runtime state (shop stock), and
the config shapes. Numbers live in [balance.md](./balance.md); shapes live here.

## Persisted player data (`DefaultData`, SchemaVersion 3)

Additive only; `ProfileService:Reconcile()` deep-fills these into existing profiles, nothing is dropped
(constitution II, FR-014). `PlayerDataManager.Migrate` sets `SchemaVersion = 3`.

```lua
DailyReward = {
    StreakDay   = 0,   -- 0 = never claimed; else 1..7, the last claimed day on the track
    LastClaimDay = 0,  -- UTC day index (os.time()//86400) of the last claim; 0 = never
},
Quests = {
    Day      = 0,      -- UTC day index the current set/progress belong to; 0 = no set yet
    Progress = {},     -- [questId] = count (clamped at the quest's target)
    Claimed  = {},     -- [questId] = true once its reward was granted
},
Onboarding = {
    Done = false,      -- true once the tutorial is completed or skipped (show-once gate)
    Step = 0,          -- reserved for a future mid-tutorial resume; NOT persisted today
                       -- (the tutorial restarts at step 1 on rejoin). Only `Done` is the
                       -- show-once gate. `PlayerDataManager.SetOnboardingStep` exists but
                       -- is unused until step-resume is added.
},
```

### Invariants

- `DailyReward.StreakDay ∈ {0..7}`; `LastClaimDay ≥ 0`.
- A reward is claimable iff `DayIndex(now) > LastClaimDay`. On claim: if `DayIndex(now) == LastClaimDay +
  1` and `StreakDay < 7` → `StreakDay += 1`; if `StreakDay == 7` → loops to `1`; if the gap ≥ 2 →
  `StreakDay = 1`. Then `LastClaimDay = DayIndex(now)`.
- `Quests.Progress`/`Claimed` are only valid for `Quests.Day == DayIndex(now)`; when the day index
  advances the server rebuilds the set and resets both (old progress does not carry over).
- A quest reward is grantable iff `Progress[id] ≥ target` and `not Claimed[id]`; granting sets
  `Claimed[id] = true` (grant exactly once).
- `Onboarding.Done` is write-once-true; never reset by this feature.

## Server-only runtime state (not persisted)

### Shop stock (`ShopStockService`, per server)

```lua
currentWindow = <number>            -- math.floor(os.time()/RestockIntervalSec)
remaining     = { [itemId] = n }    -- items absent here or absent from config = unlimited
```

- On a window change (1 Hz tick or any access): `currentWindow = window(now)`; `remaining` re-initialised
  from `RetentionConfig.ShopStock`; broadcast `ShopRestocked`.
- `TryReserve(itemId, qty)`: unlimited → true; else atomically `remaining[itemId] ≥ qty` → decrement &
  true, otherwise false. Never persisted (reconstructed from the window on server start — R4/R11).

## Config shapes (`RetentionConfig`, ReplicatedStorage)

```lua
RetentionConfig.DailyRewards = { {coins=25}, {coins=40}, {coins=60}, {coins=90, seeds=1},
                                 {coins=120}, {coins=160, seeds=2}, {coins=250, seeds=5} } -- 7 entries
RetentionConfig.QuestsPerDay = 3
RetentionConfig.Quests = {   -- fixed pool (array); #pool > QuestsPerDay
    { id="plant_5",  kind="plant",        target=5,  coins=30, text="Plant 5 seeds" },
    { id="harvest_3",kind="harvest",      target=3,  coins=40, text="Harvest 3 crops" },
    { id="sell_5",   kind="sell",         target=5,  coins=50, text="Sell 5 crops" },
    { id="catch_3",  kind="catch_spirit", target=3,  seeds=3,  text="Catch 3 spirits at night" },
    { id="plant_10", kind="plant",        target=10, coins=60, text="Plant 10 seeds" },
    { id="sell_10",  kind="sell",         target=10, coins=90, text="Sell 10 crops" },
}
RetentionConfig.RestockIntervalSec = 300
RetentionConfig.ShopStock = { carrot_seed=20, wheat_seed=20, tomato_seed=12, pumpkin_seed=10,
    moonflower_seed=6, starberry_seed=4, dreamroot_seed=2, improved_watering_can=3,
    fertilizer=10, dream_dust=5 }  -- items absent = unlimited
RetentionConfig.AnnounceRarities = { Rare=true, Epic=true }  -- Common never announces
RetentionConfig.AnnounceDedupeSec = 5
RetentionConfig.NightBannerSeconds = 2.5

-- Pure helpers (unit-tested offline):
function RetentionConfig.DayIndex(now)        return math.floor(now / 86400) end
function RetentionConfig.RestockWindow(now)   return math.floor(now / RetentionConfig.RestockIntervalSec) end
function RetentionConfig.PickDailyQuests(dayIndex)  -- returns QuestsPerDay pool entries, deterministic
    local out, n = {}, #RetentionConfig.Quests
    for i = 0, RetentionConfig.QuestsPerDay - 1 do out[#out+1] = RetentionConfig.Quests[((dayIndex + i) % n) + 1] end
    return out
end
```

### `kind` → authoritative event (quest tracking, R6)

| kind | Incremented at | By |
|---|---|---|
| `plant` | `PlotManager` plant flow | +1 per seed planted |
| `harvest` | `PlotManager` harvest flow | +1 per crop harvested |
| `sell` | `RemoteHandlers` `SellItem`/`SellAll` (after success) | + crop count sold |
| `catch_spirit` | `SpiritCollector.tryCollect` (after success) | +1 per spirit collected |

## Entities (spec → model)

| Spec entity | Where it lives |
|---|---|
| Daily reward state (per player) | `DailyReward` in profile |
| Daily reward table | `RetentionConfig.DailyRewards` |
| Quest definition | `RetentionConfig.Quests` pool entry |
| Quest state (per player) | `Quests` in profile |
| Shop stock | `ShopStockService.remaining` + `RetentionConfig.ShopStock` |
| Restock window | `ShopStockService.currentWindow` + `RestockIntervalSec` (`RestockAt` derived) |
| Announcement | transient `ServerAnnounce` payload (not stored) |
| Onboarding state (per player) | `Onboarding` in profile |
