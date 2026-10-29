---
description: "Task list for Feature 006 — Cosy-Garden Redesign Stage 2"
---

# Tasks: Cosy-Garden Redesign — Stage 2

**Input**: Design documents from `specs/006-redesign-stage2/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: The project uses offline Luau unit specs + static-GUI parity as its quality gate (no app-level
TDD). One offline spec task is included (spirit catalog parity + the pure catch-roll); it is not a full
test suite.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1–US4 (user-story phases only)
- Each task names exact file path(s). Regenerate `StarterGui/*.model.json` after every builder edit
  (`python3 Tools/StaticGui/build_models.py "$(command -v luau)"`) and commit it (Constitution III).

---

## Phase 1: Setup (Shared Infrastructure)

> Numeric balance (tool prices, per-rarity catch chances, first-catch bonuses, lantern spawn radius) is
> single-sourced in [balance.md](./balance.md) (initial values to tune in Studio); the config tasks below
> take their numbers from there.

- [x] T001 Baseline: on branch `006-redesign-stage2`, run `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` and `for f in Tools/Tests/*.spec.luau; do luau "$f"; done`; confirm all specs pass and `StarterGui/*.model.json` is clean (git parity) before changes.
- [x] T002 [P] Add fallback glyphs for the new items in `ReplicatedStorage/ItemEmoji.lua`: `lantern` (🏮), `net` (🥅), `shovel` (⛏️/🪏), `moonmoth`, `moth_spirit` (shared by hotbar, shop, backpack and journal fallbacks).

---

## Phase 2: Foundational (Blocking Prerequisites for US2 & US3)

**Purpose**: the single-source spirit catalog + the persisted collection layer. **Blocks US2 and US3.**
US1 (tools) and US4 (window redesign) do NOT depend on this phase and may start in parallel with it.

- [x] T003 Create `ReplicatedStorage/SpiritData.lua` — the single-source spirit catalog (research R7, data-model.md). One entry per type with `{ id, displayName, rarity, weight, reward, captureMethod, catchChance, firstCatchBonus }`. Include existing `wisp_common`/`wisp_rare`/`wisp_epic` as `captureMethod="proximity"` (catchChance/firstCatchBonus = 0, keep current weights/reward) and new `moonmoth`, `moth_spirit` as `captureMethod="net"` with a per-rarity `catchChance` in (0,1] and `firstCatchBonus` > 0. Numeric values (weights, catchChance, firstCatchBonus) come from [balance.md](./balance.md). Rarity MUST be a known tier; weight > 0.
- [x] T004 Point `ServerScriptService/Services/Spirit/SpiritTypes.lua` at `ReplicatedStorage/SpiritData` (read/re-export the catalog; keep `ChooseRandom` weighted pick and `FindById`) so the server and client share one source.
- [x] T005 In `ReplicatedStorage/DefaultData.lua`: bump `SchemaVersion` 3 → 4; add top-level `SpiritCollection = {}` (keyed `[spiritTypeId] = { Count = 0, FirstCaughtAt = 0 }`) and declare `Stats.TotalSpiritsCollected = 0`.
- [x] T006 In `ServerScriptService/Services/PlayerDataManager.lua`: add `RecordSpiritCaught(player, typeId) -> isFirst` (create `{Count=1, FirstCaughtAt=os.time()}` + return true on first, else `Count += 1` + return false); include `SpiritCollection` in `Snapshot`; confirm `profile:Reconcile()` backfills the new field and `Migrate` stamps v4 (data-model.md rules).
- [x] T007 [P] Add `Tools/Tests/spirit_config.spec.luau` (offline): assert every `SpiritData` entry has the required fields, `captureMethod ∈ {proximity,net}`, net types have `catchChance ∈ (0,1]` and `firstCatchBonus > 0`, every rarity is a known tier, and the values match [balance.md](./balance.md) (catchChance ↔ rarity table, weights, bonuses); and test a pure `rollCatch(chance, rng)` (extract it to a shared, injectable-RNG function) returns deterministic results for a seeded RNG.

**Checkpoint**: catalog + collection layer ready — US2 and US3 can proceed.

---

## Phase 3: User Story 1 — Real tools (lantern / net / shovel) (Priority: P1) 🎯 MVP

**Goal**: slots 3–5 become real ownable tools bought in the shop; the shovel clears a plot; the lantern
raises nearby night spawns; all three equip by tap/key/cycle.

**Independent Test**: buy + equip each tool; shovel clears a plot to Empty (empty plot rejects); with the
lantern equipped at night more spirits spawn near the player; unowned slot stays locked. (quickstart §US1)

- [x] T008 [P] [US1] In `ReplicatedStorage/ShopConfig.lua` add to `buy.tools`: `lantern` (rarity Uncommon), `net` (rarity Rare), `shovel` (rarity Common), each `{ price=<coins from balance.md>, rarity, displayName, icon="" }` — the shop Tools tab + `GetCategoryItems` render them automatically.
- [x] T009 [P] [US1] In `ReplicatedStorage/GameSettings.lua` → `SpiritSettings`, add `LanternSpawnRadius` (< `SpawnRadius`, value from [balance.md](./balance.md)) and any lantern spawn-bias knob (single source for R3).
- [x] T010 [US1] In `ServerScriptService/Services/PlotManager.lua` `HandleInteraction`, add a `shovel` branch after Harvest: if `plot.State == "Empty"` → `fail("Nothing to clear")`; if `plot.State == "ReadyToHarvest"` → `fail("Harvest it first")` (protect the ripe crop, spec US1-AS3 / Edge Cases); else (Planted/Growing/Withered) reset `State=Empty, PlantId=nil, GrowthProgress=0, GrowthSeconds=0, IsWatered=false`, fire `PlotStateChanged` + `PlotStateUpdated`, return `ok({Action="Cleared", PlotId=plotId})`. No yield (contracts/spirit-and-tools.md).
- [x] T011 [US1] In `ServerScriptService/Services/InventoryService.lua` confirm `SetEquipped` permits the three owned tools via its `else`/`HasItem` branch; add explicit handling only if a tool must be equippable without ownership (none here).
- [x] T012 [US1] In `ServerScriptService/Services/Spirit/SpiritSpawner.lua` `spawnOne`, bias the spawn-anchor player toward those with `InventoryService.GetEquipped(player) == "lantern"` and spawn within `GameSettings.SpiritSettings.LanternSpawnRadius` around them (else the existing `SpawnRadius`); night-gating unchanged.
- [x] T013 [US1] In `StarterPlayer/StarterPlayerScripts/Controllers/HotbarController.lua` `buildItems`, append each owned `lantern`/`net`/`shovel` (icon via `iconFor`, emoji fallback via `ItemEmoji`) in a stable order **after the watering cans and Harvest** (before/after seeds — pick one fixed order and keep it), so they join the inventory-driven tool strip and are reachable in the visible 5 slots + by cycling; trailing empty slots keep the locked placeholder. The hotbar stays inventory-driven/cycling (no hard-pinned slot index) — see spec FR-002 / analyze I1.
- [x] T014 [US1] Regenerate `StarterGui/*.model.json`; run all `Tools/Tests/*.spec.luau`; commit changed config + any model diffs.
- [x] T015 [US1] Studio playtest (both palettes, phone-landscape): buy each tool in the shop Tools tab; equip from slots 3–5; shovel clears a planted/withered plot to Empty and rejects an empty plot; with the lantern equipped at night, more wisps spawn near the player; day↔night keeps slot order; no new Output errors.

**Checkpoint**: US1 shippable as PR-A (MVP).

---

## Phase 4: User Story 2 — Net capture, new creatures, announcement (Priority: P2)

**Goal**: new Moonmoth/Moth-Spirit spawn at night; the net captures them with a server-rolled per-rarity
chance; first catch of a type pays a one-time bonus; notable spawns announce; wisps unchanged.

**Independent Test**: at night a flying creature spawns + announces; net equipped → trigger its prompt →
server roll catches or misses; first catch pays a bonus, repeat only counts; no-net/out-of-range
rejected; wisps still collect by proximity. (quickstart §US2). **Depends on Phase 2.**

- [x] T016 [US2] In `ServerScriptService/Services/Spirit/SpiritSpawner.lua` `buildSpiritModel`, render the new flying-creature types (reuse the Orb/particle/`CollectPrompt` pattern; distinct colour/look per rarity via `SpiritConfig.GetColor`); ensure `Types.ChooseRandom` can pick them (weights from the catalog) at night.
- [x] T017 [US2] In `ServerScriptService/Services/Spirit/SpiritCollector.lua` `tryCollect`, branch on `spiritType.captureMethod`: `proximity` keeps current behaviour; `net` requires `InventoryService.GetEquipped(player) == "net"` (else `fail("Need a net")`) then `success = rollCatch(spiritType.catchChance, rng)` — on failure return `(false,0)` (cooldown set, spirit may remain).
- [x] T018 [US2] In `SpiritCollector.lua`, on any successful collect/capture call `PlayerDataManager.RecordSpiritCaught(player, spiritType.id)`; if `isFirst` and `firstCatchBonus > 0` award it server-side (coins/DreamSeeds) + fire `UpdateCurrency`; keep the existing wisp DreamSeeds reward for proximity types; for `net` repeats grant no currency (only the count). Fire `SpiritCollected`, `QuestService.Track(player,"catch_spirit",1)`, `IncrementStat("TotalSpiritsCollected",1)`.
- [x] T019 [US2] Confirm the "appeared" banner covers the new creatures: `SpiritSpawner` already fires `ServerAnnounce("rare_spirit", name, rarity)` for `RetentionConfig.AnnounceRarities[rarity]`; add the new creatures' rarities to `ReplicatedStorage/RetentionConfig.lua` `AnnounceRarities` if they should announce.
- [x] T020 [US2] Regenerate models (no GUI change expected) + run all specs (incl. `spirit_config.spec`); commit server/config changes.
- [x] T021 [US2] Studio playtest (both palettes): force night, spawn a Moonmoth/Moth (`SpiritManager.SpawnOnce`), see the announce banner; capture with the net (success + miss), verify first-catch bonus vs repeat-count, no-net/out-of-range rejection, and wisps still collect by proximity; no new Output errors.

**Checkpoint**: US2 shippable as PR-B.

---

## Phase 5: User Story 3 — Spirit collection UI: Spirits tab + Journal (Priority: P3)

**Goal**: the Backpack Spirits tab shows caught spirits as cards; a new Spirit Journal screen lists all
known types (discovered vs undiscovered) with progress; collection persists.

**Independent Test**: catch a few, open the Spirits tab (cards, not placeholder) and the Journal
(discovered revealed, uncaught locked, "N / M"), rejoin → collection intact. (quickstart §US3). **Depends
on Phase 2 (catalog + Snapshot) and US2 (catches recorded).**

- [x] T022 [P] [US3] Create `Tools/StaticGui/builders/CreateSpiritJournalUI.luau` → `SpiritJournalUI`: `Backdrop` + `JournalFrame` (cosy-garden `HeaderBar` + title + `CloseButton`), `ProgressLabel`, `EntryScroll` with a hidden `EntryTemplate` card (shared `RarityBadge`, `Icon`+`FallbackLetter`, `NameLabel`, `CountLabel`, `FirstCaughtLabel`); themed via `UITheme` tokens + `Theme_<Prop>` (contracts/ui-templates.md).
- [x] T023 [US3] Create `StarterPlayer/StarterPlayerScripts/Controllers/SpiritJournalController.lua`: register `SpiritJournalUI` with `WindowManager`; on open read `SpiritCollection` from the `GetPlayerData` snapshot + the full set from `ReplicatedStorage/SpiritData`; clone one `EntryTemplate` per catalog entry (discovered = details; undiscovered = locked "???"); set `ProgressLabel` "N / M discovered"; `ThemeController.PaintInstant` each clone.
- [x] T024 [US3] Boot the controller in `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` (after `InventoryController`); add `SpiritJournalUI` to `ThemeController.lua` `SCREEN_GUIS`; add a `ResponsiveLayout.WINDOWS.SpiritJournal` entry (aspect/maxW/maxH) and register its size in `WindowManager` like the other windows.
- [x] T025 [US3] In `Tools/StaticGui/builders/CreateInventoryUI.luau`, give the Spirits tab real content: reuse `CardTemplate` for caught spirits in `ItemGrid`; keep `SpiritsEmptyState` only for a genuinely empty collection; change the Spirits detail action to **"Open Journal"**.
- [x] T026 [US3] In `StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.lua`, render the Spirits tab from the snapshot `SpiritCollection` × `SpiritData` catalog (rarity-badged cards), show the empty state only when none caught, and wire the detail "Open Journal" action to open `SpiritJournalUI`.
- [x] T027 [US3] Regenerate `StarterGui/*.model.json` (new `SpiritJournalUI.model.json` + updated `InventoryUI.model.json`); run all specs; commit.
- [x] T028 [US3] Studio playtest (both palettes): catch spirits → Spirits tab shows cards; open the Journal (discovered vs undiscovered, progress count); rejoin → collection persists (reconcile on an alt/old profile shows empty state cleanly); day↔night cross-fades the Journal; no new Output errors.

**Checkpoint**: US3 shippable as PR-C.

---

## Phase 6: User Story 4 — Cosy-garden redesign of remaining windows (Priority: P3)

**Goal**: Sell / Notifications / Daily-Gift / Quests match the concept (header/card/button + tokens),
actions unchanged. Independent of US1–US3; each window is its own small PR. (quickstart §US4)

- [x] T029 [P] [US4] Redesign `Tools/StaticGui/builders/CreateSellUI.luau` → `SellUI` to the cosy-garden language (header, item rows as cards, themed Sell/Sell-all), tokens + `Theme_<Prop>`; regenerate `StarterGui/SellUI.model.json`; confirm `SellController` actions/remotes unchanged.
- [x] T030 [P] [US4] Redesign `Tools/StaticGui/builders/CreateQuestsUI.luau` → `QuestsUI` (quest rows as cards with progress + reward, themed Claim); regenerate; confirm `QuestController` unchanged.
- [x] T031 [P] [US4] Redesign `Tools/StaticGui/builders/CreateDailyRewardUI.luau` → `DailyRewardUI` (7-day streak as cosy reward cards); regenerate; confirm `DailyRewardController` unchanged.
- [x] T032 [P] [US4] Redesign `Tools/StaticGui/builders/CreateNotifications.luau` → `Notifications` (themed toast/banner styling); regenerate; confirm `ToastQueue`/notification behaviour unchanged.
- [x] T033 [US4] Run all specs + static-GUI parity after the four regenerations; commit the four model.json files.
- [x] T034 [US4] Studio playtest (both palettes, phone-landscape): open each of the four windows, exercise its actions (sell one / sell all / toggle favourite; claim daily; claim a quest; see a notification), ≥44×44 + safe area; no new Output errors.

**Checkpoint**: US4 shippable (one PR per window or one small PR for the set).

---

## Phase 7: Polish & Cross-Cutting

- [ ] T035 Full device-emulator pass (owner) at phone-landscape in both palettes across all new/changed surfaces: readability, ≥44×44, no clipped text (incl. a long/RU label), movement/jump zones clear, no new Output errors (SC-006).
- [x] T036 [P] Update `Docs/HANDOFF.md` and `README.md` with the Stage-2 state (tools, capture, journal, redesigned windows) and what remains deferred.
- [x] T037 Final regenerate + full `Tools/Tests/*.spec.luau` green + git parity of all `StarterGui/*.model.json`; confirm NO new remotes were added (contracts/reused-remotes.md).
- [ ] T038 Run `specs/006-redesign-stage2/quickstart.md` end-to-end and tick this tasks.md.

---

## Dependencies & Execution Order

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: after Setup; **blocks US2 and US3 only** (NOT US1/US4).
- **US1 (P1)**: after Setup; independent — can run alongside Phase 2. MVP.
- **US2 (P2)**: after Phase 2.
- **US3 (P3)**: after Phase 2 AND US2 (needs catches recorded); US3's T024 reads best after US1's 5-slot hotbar exists (already shipped in Stage 1).
- **US4 (P3)**: after Setup; fully independent of everything else.
- **Polish (Phase 7)**: after the desired stories land.

## Parallel Opportunities

- T002 (ItemEmoji) ∥ Phase 2 work; T007 (spec) ∥ T003–T006 where files differ.
- US1 (Phase 3) runs in parallel with Phase 2 (different files/stories).
- Within US1: T008 (ShopConfig) ∥ T009 (GameSettings) — different files.
- US4's T029–T032 are four different builder files → all [P].
- With capacity: US1, US4, and (after Phase 2) US2 can proceed in parallel; US3 follows US2.

## Implementation Strategy

- **MVP = US1** (tools): Setup → US1 → validate in Studio → PR-A.
- Then Foundational → **US2** (capture) → PR-B; **US3** (journal) → PR-C; **US4** (windows) → PR(s),
  independently. Each PR keeps offline specs + static-GUI parity green and is Studio-verified (VI).

## Notes

- No new RemoteEvents/RemoteFunctions (contracts/reused-remotes.md) — server stays the authority.
- Single-source numbers: tool prices in `ShopConfig`; catalog (weights/chances/bonuses) in `SpiritData`;
  spawn/lantern tunables in `GameSettings`/`Constants`; collection shape in `DefaultData`.
- Regenerate `StarterGui/*.model.json` after every builder edit and commit (Constitution III).
- Schema change is additive (3→4) — reconcile backfills; never drop existing fields.
