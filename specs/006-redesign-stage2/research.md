# Phase 0 Research: Cosy-Garden Redesign — Stage 2

All decisions reuse the existing systems found in the codebase (spirit system under
`ServerScriptService/Services/Spirit/`, hotbar, theme engine, ProfileService). No new remotes.

## R1 — Net capture path (reuse, no new remote)

**Decision**: Capture of the new flying creatures goes through the **existing spirit `ProximityPrompt`**
path, gated by the equipped net. Each spirit model already carries a `ProximityPrompt` ("CollectPrompt",
E / ButtonX, a touch button on mobile) whose `Triggered` runs `SpiritManager.onCollect →
SpiritCollector.tryCollect`. `tryCollect` branches by the spirit type's `captureMethod`:
`proximity` (wisps) behaves exactly as today; `net` (flying creatures) first checks
`InventoryService.GetEquipped(player) == "net"` and rejects otherwise ("Need a net"), then rolls the
per-rarity catch chance.

**Rationale**: It is already on-screen and input-agnostic, already server-authoritative, and needs no
new remote (reuse-remotes gate). The `CollectSpirit` RemoteFunction already exists as an equivalent
client-invoked entry to the same `tryCollect` if a non-prompt path is ever needed — but the prompt is
sufficient and consistent with wisps.

**Alternatives considered**: (a) `HotbarController.UseTool` → `InteractWithPlot` — rejected, that remote
targets plot Models, not spirits. (b) A new `CaptureSpirit` remote — rejected, violates the no-new-remote
gate; `tryCollect` already does the job.

## R2 — Capture success model (chance by rarity, server-rolled, testable)

**Decision**: On a net capture, the server rolls success against a per-rarity `catchChance` (0–1) defined
in the spirit catalog. The roll is a **pure function** `rollCatch(chance, rng) -> boolean` so it is unit-
testable offline with an injected RNG (default `Random.new()` in game). On success → record + reward; on
failure → clean rejection, spirit may remain, cooldown still applies (anti-spam).

**Rationale**: Makes rarity meaningful (owner decision), stays server-authoritative, and the pure roll
keeps Constitution VI/offline-testability. Wisps keep deterministic proximity collection (no roll).

**Alternatives**: deterministic capture (simpler, rejected by owner — no catch challenge); pity counter
(more state, deferred).

## R3 — Lantern effect (bias the existing spawn tick)

**Decision**: The lantern is an **equipped** tool (no active use needed). In the existing
`SpiritSpawner.spawnOne` tick (runs only at night via `SpiritManager`), when choosing the spawn-anchor
player, players with the net-less... correction: players with the **lantern** equipped
(`InventoryService.GetEquipped(player) == "lantern"`) are preferred as the anchor and spirits spawn
within a smaller `LanternSpawnRadius` around them (config), raising the effective spawn rate where they
stand. No change to the loop cadence or `MaxActive` is required for the MVP.

**Rationale**: Reuses the existing spawn loop (no new per-frame work, Constitution performance), is fully
server-side, and is a small, tunable change. "More spirits where you stand" matches the owner's "attract"
answer.

**Alternatives**: a placed world lamp object (more scope, rejected by clarify); reducing
`SpawnIntervalSec` globally while any lantern is equipped (coarser, can over-spawn — deferred as a tuning
knob, not built).

## R4 — Shovel (new branch in PlotManager)

**Decision**: The shovel is a plot tool. Add a branch in `PlotManager.HandleInteraction`: when the
server-equipped tool is `"shovel"` and the plot holds a plant (any non-Empty state), reset the plot to
`Empty` (clear PlantId/progress/watered), fire `PlotStateChanged`/`PlotStateUpdated`, and return no
yield; using it on an already-empty plot fails cleanly ("Nothing to clear"). It reuses
`HotbarController.UseTool` → `InteractWithPlot` exactly like Harvest/watering.

**Rationale**: Mirrors the existing Harvest branch; server-authoritative; no new remote. Matches the
owner's "clear a plant → Empty" answer (no early-dig partial yield this stage).

**Alternatives**: early-dig for partial yield (rejected by clarify); a confirm step before clearing a
`ReadyToHarvest` crop (deferred as UX polish — not required, the hint/HUD already nudges harvesting).

## R5 — Tools as shop items + hotbar entries (reuse)

**Decision**: Add `lantern`, `net`, `shovel` to `ShopConfig.buy.tools` (price, rarity, displayName,
icon) — bought in the shop Tools tab for coins like `improved_watering_can`. `InventoryService.SetEquipped`
already allows any **owned** tool (its `else` branch checks `HasItem`), so no server allow-list edit is
needed. Extend `HotbarController.buildItems` to append each owned tool so it fills slots 3–5 (today it
adds watering cans, Harvest, then seeds). `ItemEmoji` gets glyphs for the three tools.

**Rationale**: Pure reuse of the economy + hotbar; single-source prices; the locked placeholder already
renders for unowned slots, so nothing extra is needed for the "unowned" state.

**Alternatives**: free/starter tools or quest unlocks (rejected by clarify — shop purchase).

## R6 — Spirit collection persistence (additive schema bump)

**Decision**: Add `SpiritCollection = {}` to `DefaultData` (keyed by spirit type id →
`{ Count = 0, FirstCaughtAt = 0 }`) and bump `SchemaVersion` 3 → 4. `PlayerDataManager` already runs
`profile:Reconcile()` (backfills the new field into old saves) then `Migrate` (stamps the version), so the
change is additive and safe. Add a `PlayerDataManager.RecordSpiritCaught(player, typeId) -> isFirst`
helper and include `SpiritCollection` in `PlayerDataManager.Snapshot`. Also declare the already-runtime
`Stats.TotalSpiritsCollected` in `DefaultData`.

**Rationale**: Follows the project's established schema-reconcile pattern (feature 003 did the same 2→3);
no data loss; the Journal reads collection from the existing `GetPlayerData` snapshot — no new remote.

**Alternatives**: a separate DataStore for the collection (rejected — ProfileService profile is the home,
reconcile handles it).

## R7 — Client-readable spirit catalog (new single-source module)

**Decision**: Introduce `ReplicatedStorage/SpiritData.lua` as the single source for spirit-type metadata
(id, displayName, rarity, weight, catchChance, firstCatchBonus, captureMethod). The server
`Services/Spirit/SpiritTypes.lua` reads/re-exports it (keeping its `ChooseRandom`/`FindById` helpers);
the client Spirit Journal reads it directly to render **undiscovered** entries (the full known set) while
showing only the player's caught ones as revealed.

**Rationale**: The Journal must show every known spirit type, including ones not yet caught, so the
catalog metadata must be client-readable. Putting it in `ReplicatedStorage` keeps a single source
(Constitution II) and avoids the client trusting gameplay outcomes — catch results still come only from
the server. Catch chance / first-catch bonus are metadata, not live state, so exposing them is safe.

**Alternatives**: server sends the whole catalog in the snapshot (works but duplicates the catalog on the
wire every sync, and the client still needs names for undiscovered entries — a static RS module is
simpler and cache-friendly); keep the catalog server-only and hide undiscovered entries (worse Journal
UX, rejected).

## R8 — New window redesign (US4) is UI-only reuse

**Decision**: Rebuild `SellUI`, `Notifications`, `DailyRewardUI`, `QuestsUI` in their builders to the
cosy-garden header/card/button language + theme tokens, cloning the Stage-1 patterns
(`contracts/ui-templates.md` from 005). Controllers keep their existing remote calls unchanged — no
behaviour change, no new remotes. Regenerate each `StarterGui/*.model.json`.

**Rationale**: Pure re-skin/relayout; the theme engine + existing controllers already drive these
windows; this only updates structure/tokens. Each window is an independent small PR.

**Alternatives**: none needed (scoped re-skin).

## Resolved unknowns

All Technical Context items are resolved; no `NEEDS CLARIFICATION` remain (the spec's Clarifications
section already fixed the gameplay decisions, and the findings above fix the implementation approach).
