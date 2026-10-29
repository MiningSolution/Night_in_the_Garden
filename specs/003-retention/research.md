# Phase 0 Research — Retention Loop (Phase 3)

**Feature**: `003-retention` | **Date**: 2026-10-29

All decisions below resolve the Technical Context and the spec's clarified assumptions. Each is a
*Decision / Rationale / Alternatives* triple. Two items (R4, R8) carry a Studio verification instead of
an open question.

## R1 — Day boundary for daily reward and quest reset

**Decision**: a "day" is the integer UTC day index `math.floor(os.time() / 86400)`. The reward is
claimable at most once per day index; the streak advances when the new index is exactly `last + 1`,
resets to day 1 when the gap is ≥ 2, and the current index is stored as `LastClaimDay`. Quest sets key
off the same index.

**Rationale**: `os.time()` is server wall-clock UTC and identical across servers, so claimability and
the shared quest set are deterministic with no cross-server state. Integer-day math makes "same day",
"next day" and "missed a day" trivial and testable offline (pure function).

**Alternatives considered**: per-player "24h since last claim" timers (drift, harder to reason about,
not shared across servers); `os.date` local time (server-timezone dependent, non-deterministic across
regions). Rejected.

## R2 — Daily-reward table shape and streak loop

**Decision**: a fixed 7-entry array in `RetentionConfig.DailyRewards`, each `{ coins = n, seeds = m }`
(seeds optional, on milestone days). `StreakDay` runs 1–7; after claiming day 7 the next claim loops to
day 1. Rewards are non-decreasing across the week (validated by the offline test). Amounts live only in
config + `balance.md`.

**Rationale**: an array indexed by streak day is the simplest single source; the shop/UI render it
directly. Non-decreasing keeps the "come back for a bigger reward" incentive.

**Alternatives considered**: infinite escalating curve (unbounded balance risk, no natural loop);
server-random daily reward (not reproducible, harder to show a "track"). Rejected.

## R3 — Quest pool and deterministic daily selection

**Decision**: `RetentionConfig.Quests` is a fixed pool of definitions `{ id, kind, target, coins,
seeds?, text }` where `kind ∈ { plant, harvest, sell, catch_spirit }`. `QuestsPerDay` (= 3) quests are
chosen per day by `PickDailyQuests(dayIndex)`: `pool[((dayIndex + i) % #pool) + 1]` for `i = 0..perDay-1`
(pool size > perDay, ids unique per day). Progress and claims are per-player; the chosen set is shared
by all players that day and needs no persistence of the selection itself — only the day it belongs to.

**Rationale**: deterministic rotation gives everyone the same daily set with zero stored RNG state and
is a pure, testable function. `kind` maps 1:1 onto events the server already raises.

**Alternatives considered**: per-player random selection (needs persisted seed/set, diverges across
re-logins); server-seeded shuffle broadcast (cross-server messaging). Rejected.

## R4 — Shop restock: time-derived schedule, per-server stock

**Decision**: `window = math.floor(os.time() / RestockIntervalSec)`; `RestockAt = (window + 1) *
RestockIntervalSec`. `ShopStockService` holds `remaining[itemId]` for the current window per server,
initialised to `RetentionConfig.ShopStock[itemId]` (items absent from the table are **unlimited**).
When the window advances (detected on a 1 Hz tick and on any access), stock refills and `ShopRestocked`
is broadcast (toast). The countdown is computed on the client from `RestockAt` and the server time it
was handed, not stored per client. Remaining counts are per-server (shared by players on one server);
only the *schedule* is global.

**Rationale**: this is the Grow a Garden model the owner's plan specified — synchronized restock timing
without synchronized inventory, so no MessagingService/cross-server coordination. Window math is pure
and testable.

**Studio verification**: V7 sets a short interval in config and confirms stock refills and the toast
fires exactly at the boundary, and that the countdown matches on two clients.

**Alternatives considered**: MemoryStore/MessagingService shared stock (cross-server complexity, out of
scope); persisting stock to each profile (wrong granularity — stock is server/world state, not player
state). Rejected.

## R5 — Atomic stock reservation on purchase

**Decision**: `BuyItem` calls `ShopStockService.TryReserve(itemId, qty)` **before** spending coins;
it atomically checks `remaining ≥ qty` and decrements, returning false if not. On false, `BuyItem`
fails closed (`"Out of stock"`) with no coin spend and no item grant. Unlimited items skip the check.
The buy response returns the updated remaining so the card updates without a refetch.

**Rationale**: matches the clarified "reject the whole purchase atomically" decision and the existing
fail-closed `BuyItem` flow (coins are only spent after validation). Keeps overselling impossible even
with concurrent buys on one server (single-threaded Luau; the check-and-decrement is one step).

**Alternatives considered**: partial fill up to remaining (complicates the ×1/×5/×10 affordability math
and the client's dim logic; the spec clarified against it). Rejected.

## R6 — Quest progress hook points

**Decision**: a single `QuestService.Track(player, kind, amount)` is called server-side where each
tracked event is already handled: **plant** and **harvest** in `PlotManager` (the authoritative plot
flow), **sell** in `RemoteHandlers` `SellItem`/`SellAll` (after a successful sale, by crop count), and
**catch_spirit** in `SpiritCollector.tryCollect` after a successful collect. `Track` increments only
quests of that `kind` for the player's current day set, clamps at target, and pushes `QuestUpdated`.

**Rationale**: these are the only authoritative sites for those events, so progress cannot be spoofed
from the client (I). One narrow function keeps the services decoupled — the hook is one line each.

**Alternatives considered**: client reports progress (violates I); polling inventory deltas (fragile,
double-counts). Rejected.

## R7 — New remotes and events

**Decision**: add RemoteFunctions `GetDailyReward`, `ClaimDailyReward`, `GetQuests`, `ClaimQuest`,
`SetTutorialDone`; extend `GetShopData` with `Stock`/`RestockAt`/`Interval` and `BuyItem` with stock
reservation; add server→client RemoteEvents `QuestUpdated` (FireClient — progress/claim push),
`ShopRestocked` (FireAllClients — refill toast + new stock), `ServerAnnounce` (FireAllClients — rare
spirit / event banner). Nightfall uses the existing `DayNightUpdate`; no remote is added for it. All are
created in `CreateRemotes.lua` and bound in `RemoteHandlers.lua` with the standard pattern.

**Rationale**: reuses the one creation+binding convention; broadcasts (`FireAllClients`) are the
natural fit for server-wide announcements and the shared restock moment; per-client pushes for
per-player quest state.

**Alternatives considered**: folding everything into `GetPlayerData` (bloats one call, no push for
restock/announce); a generic "event bus" remote (over-abstraction, VII). Rejected.

## R8 — Nightfall banner fires once per transition

**Decision**: the client tracks the last phase seen from `DayNightUpdate`; it shows the banner only on
a transition from `Day` to `Night` (edge, not level), and clears it on a timer (~2–3 s, non-blocking).
Night→Day shows nothing and clears any night-only announcement state.

**Rationale**: `DayNightUpdate` fires every second with `(phase, progress)`; an edge check avoids a
banner every tick. No server change needed — the server already flips phase in `DayNightManager`.

**Studio verification**: V9 watches a full Day→Night→Day cycle and confirms exactly one banner per
nightfall and none on sunrise.

**Alternatives considered**: a dedicated server `NightStarted` event (redundant with `DayNightUpdate`).
Rejected.

## R9 — Rare-spirit announcement threshold and anti-spam

**Decision**: `SpiritSpawner` fires `ServerAnnounce("rare_spirit", displayName, rarity)` when it spawns
a spirit whose `rarity` is `Rare` or `Epic` (the `SpiritTypes` tiers above `Common`). The client
de-duplicates/rate-limits announcements (ignore a new one within ~5 s of the last, or collapse to a
count) so rapid spawns stay readable.

**Rationale**: reuses the existing weighted `SpiritTypes` tiers (Common 70 / Rare 25 / Epic 5) without
redefining them; Epic is already rare, so announcements are naturally infrequent, and the client guard
covers bursts.

**Alternatives considered**: announce every spirit (spam); a server-side cooldown (fine too, but the
client guard also protects against multiple servers' unrelated UI and is simpler). Rejected — client
guard chosen; a server cooldown may be added if playtest shows spam.

## R10 — Onboarding persistence and step machine

**Decision**: `Onboarding = { Done = false, Step = 0 }` in the profile. `TutorialController` runs only
when `Done` is false: step 1 hint → plot, step 2 → plant (advance on the plant event), step 3 → water,
step 4 → sell; a Skip control and completion both call `SetTutorialDone` (sets `Done = true`). The
controller listens to the same client-visible state changes the quest events produce (inventory/plot
updates) to advance. Hints are static elements shown/hidden by the controller; they never capture input
over movement/menu/hotbar.

**Rationale**: a persisted boolean is the minimal "show once" state; `Step` lets a mid-tutorial rejoin
resume, but completion is the only thing that must persist. Reusing existing client state keeps it
decoupled from gameplay code.

**Alternatives considered**: server-driven tutorial state machine (overkill; tutorial is pure
presentation); no persistence / show every join (fails SC-005). Rejected.

## R11 — DefaultData schema bump and reconcile

**Decision**: bump `DefaultData.SchemaVersion` 2 → 3 and add `DailyReward = { StreakDay = 0,
LastClaimDay = 0 }`, `Quests = { Day = 0, Progress = {}, Claimed = {} }`, `Onboarding = { Done = false,
Step = 0 }`. `ProfileService:Reconcile()` deep-fills these into existing profiles;
`PlayerDataManager.Migrate` sets `SchemaVersion = 3` (no field drops). `StreakDay = 0` / `Day = 0` are
sentinels meaning "never claimed / no set yet", so a reconciled Phase-2 profile behaves as a fresh
retention state without special-casing.

**Rationale**: additive-only, backward-compatible (II, FR-014); existing coins/inventory/plots/
favourites untouched. Sentinels avoid a nil-vs-zero branch.

**Alternatives considered**: a separate DataStore for retention (splits the player record, complicates
atomicity). Rejected.

## R12 — Config module boundary and offline test

**Decision**: one new `ReplicatedStorage/RetentionConfig.lua` holds the reward table, quest pool +
`QuestsPerDay`, restock interval + `ShopStock` (keyed by existing item ids), the rare-spirit tiers, and
pure helpers (`DayIndex`, `RestockWindow`, `PickDailyQuests`). `balance.md` states every number;
`Tools/Tests/retention_config.spec.luau` checks the config against `balance.md` and invariants
(7 reward days, non-decreasing, pool size > `QuestsPerDay`, targets/rewards > 0, interval > 0, stock > 0,
stock keys resolve in `ShopConfig`/`PlantData`) and exercises the pure helpers (day index, window math,
deterministic pick) without the `game` global.

**Rationale**: mirrors the Phase 2 `economy_config.spec.luau` gate (SC-006). Keeping helpers pure makes
the hardest logic (date/window/rotation) unit-testable offline in CI; the stateful services are covered
by Studio playtests.

**Alternatives considered**: numbers spread across each service (violates II); requiring `game` in the
test (can't run under the Luau CLI / CI). Rejected.
