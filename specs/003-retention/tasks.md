---
description: "Task list for feature 003-retention"
---

# Tasks: Retention Loop — Daily Rewards, Quests, Night Events, Shop Restock, Onboarding (UI Plan, Phase 3)

**Input**: Design documents from `specs/003-retention/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [balance.md](./balance.md), [contracts/](./contracts/),
[quickstart.md](./quickstart.md)

**Tests**: TDD unit tests were NOT requested in the spec. One offline parity/pure-helper check
(`Tools/Tests/retention_config.spec.luau`) and the Studio playtests V0–V12 are included because they
are the plan's quality gate (constitution VI, SC-006/008).

**Organization**: grouped by user story in priority order (P1 → P2 → P3). Each story is independently
testable in Studio. Paths are repository-relative, following the Rojo layout in plan.md.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1–US5 from spec.md; Setup/Foundational/Polish carry no story label
- Every builder change is followed by regenerating `StarterGui/*.model.json`
  (`python3 Tools/StaticGui/build_models.py "$(command -v luau)"`) and committing the result (FR-015)
- **Standing rule**: playtest in Studio before every commit (no commit of untested code — constitution VI).
  Rojo does not sync `ServerScriptService`; deliver server-script changes to Studio manually before testing.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirm tooling and lock the retention numbers before any config is written.

- [x] T001 Verify `.specify/feature.json` points at `specs/003-retention` and that `rojo`/`luau` run; confirm the Phase-2 baseline is green (`luau Tools/Tests/*.spec.luau`; `build_models.py` leaves no diff)
- [x] T002 Finalize the numbers in `specs/003-retention/balance.md` (7-day reward table, quest pool + `QuestsPerDay`, `RestockIntervalSec`, per-item `ShopStock`, announce rarities/dedupe, night banner duration) — the written source transcribed into config next (FR-012)

**Checkpoint**: numbers agreed; config work can begin.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: the config, schema and migration that **every** user story reads.

**⚠️ CRITICAL**: no user-story work begins until this phase is complete.

- [x] T003 Create `ReplicatedStorage/RetentionConfig.lua` from `balance.md` (data-model.md "Config shapes"): `DailyRewards` (7 entries `{coins, seeds?}`), `QuestsPerDay = 3`, `Quests` pool (`{id, kind, target, coins?, seeds?, text}`, `kind ∈ {plant,harvest,sell,catch_spirit}`), `RestockIntervalSec = 300`, `ShopStock` (keyed by existing item ids; absent = unlimited), `AnnounceRarities = {Rare=true, Epic=true}`, `AnnounceDedupeSec = 5`, `NightBannerSeconds = 2.5`; plus pure helpers `DayIndex(now)`, `RestockWindow(now)`, `PickDailyQuests(dayIndex)` (no number duplicated elsewhere — II)
- [x] T004 [P] `ReplicatedStorage/DefaultData.lua`: bump `SchemaVersion = 3`; add `DailyReward = {StreakDay=0, LastClaimDay=0}`, `Quests = {Day=0, Progress={}, Claimed={}}`, `Onboarding = {Done=false, Step=0}` (additive; data-model.md "Persisted player data")
- [x] T005 `ServerScriptService/Services/PlayerDataManager.lua`: `Migrate` sets `SchemaVersion = 3`; reconcile fills the new fields on old saves without dropping any (II, FR-014); add accessors `GetDailyReward/SetDailyReward`, `GetQuestState`, `GetOnboarding/SetOnboardingDone` (operate on `M.Get(player)`)
- [x] T006 [P] Offline check `Tools/Tests/retention_config.spec.luau`: assert `RetentionConfig` equals `balance.md` (O1); invariants (O2) — 7 reward days & coins non-decreasing; `#Quests > QuestsPerDay`; every quest `target>0` and reward>0; `kind` in the fixed set; `RestockIntervalSec>0`; every `ShopStock` value>0 and its key resolves in `ShopConfig`/`PlantData`; pure helpers (O3) — `DayIndex`, `RestockWindow`, `PickDailyQuests` deterministic & distinct; run with `luau` (keep pure — no `game` global)

**Checkpoint**: config + schema + migration ready — user stories can proceed.

---

## Phase 3: User Story 1 - Daily login reward with a 7-day streak (Priority: P1) 🎯 MVP

**Goal**: a server-owned 7-day streak reward, claimable once per UTC day, that advances/resets/loops
and auto-opens on the first login of a day.

**Independent Test**: join, see the reward window auto-open, claim by tapping, balance rises by the
`balance.md` amount, and the day cannot be claimed again until the next UTC day (quickstart V2/V3).

- [x] T007 [US1] `ServerScriptService/Services/DailyRewardService.lua`: `GetState(player)` (StreakDay, LastClaimDay, `Claimable = DayIndex(now) > LastClaimDay`, `Today` = day a claim grants) and `Claim(player)` (grant iff Claimable; advance when `DayIndex == LastClaimDay+1 && StreakDay<7`, loop 7→1, reset to 1 on gap ≥ 2; set `LastClaimDay = DayIndex(now)`; credit via `PlayerData.AddCoins`/`AddDreamSeeds`) — all off `RetentionConfig.DayIndex(os.time())` (contracts/remotes.md; data-model.md invariants)
- [x] T008 [US1] `ServerScriptService/CreateRemotes.lua`: add `GetDailyReward`, `ClaimDailyReward` (RemoteFunctions)
- [x] T009 [US1] `ServerScriptService/RemoteHandlers.lua`: bind `GetDailyReward`/`ClaimDailyReward` with the standard pattern (pcall, `rate_ok`, fail closed on already-claimed/no-data, `AntiCheat` on abuse); `ClaimDailyReward` fires `UpdateCurrency` after crediting (contracts/remotes.md validation matrix)
- [x] T010 [P] [US1] `Tools/StaticGui/builders/CreateDailyRewardUI.luau`: build `DailyRewardUI` per contracts/gui-tree.md (`Header`/`StreakLabel`, `TrackRow` + hidden `DayTemplate` with `DayNumberLabel`/`CoinsLabel`/`SeedsLabel`/`State`, `ClaimButton`, `CloseButton`, backdrop); colours from `UITheme`; text ≥ 18/20; ≥ 44×44; safe area
- [x] T011 [US1] `Tools/StaticGui/builders/CreateHUDControls.luau`: add `RewardsButton` to the menu column (≥ 44×44, selection group, PC key hint / gamepad glyph) without overlapping hotbar or Roblox controls
- [x] T012 [US1] Regenerate models (`build_models.py`) and confirm only `DailyRewardUI.model.json` + `HUDControls.model.json` changed (FR-015)
- [x] T013 [US1] `StarterPlayer/StarterPlayerScripts/Controllers/DailyRewardController.lua`: render the track from `GetDailyReward`, highlight `Today`, enable/disable `ClaimButton` by `Claimable`, wire claim → `ClaimDailyReward` (update HUD coins via existing `UIController` tween), auto-open on first login of the day when `Claimable`; register with `WindowManager`; bind open/claim via `InputActions`
- [x] T014 [US1] `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`: boot `DailyRewardController`; wire `RewardsButton` to open the window
- [x] T015 [US1] Studio playtest V2 + V3 (phone/PC/gamepad): auto-open + claim once per day; streak advance on consecutive days, reset after a skip, loop after day 7 (day index stubbed); Output clean; reset any test-profile claim written to a live DataStore

**Checkpoint**: daily reward fully functional and independently testable.

---

## Phase 4: User Story 2 - Daily quests from gameplay (Priority: P2)

**Goal**: a deterministic daily quest set whose progress fills from real gameplay events and whose
rewards are claimable once, resetting each day.

**Independent Test**: open the Quests window, perform a tracked action, watch progress rise, claim a
completed quest once; confirm the set resets on the day boundary (quickstart V4/V5/V6).

- [ ] T016 [US2] `ServerScriptService/Services/QuestService.lua`: `EnsureDay(player)` (rebuild the set via `PickDailyQuests(DayIndex(now))` and reset `Progress`/`Claimed` when `Quests.Day` ≠ today), `GetQuests(player)`, `Track(player, kind, amount)` (increment matching-kind quests, clamp at target, fire `QuestUpdated`), `Claim(player, questId)` (grant once iff complete & unclaimed; `UpdateCurrency`) (data-model.md kind→event table; contracts/remotes.md)
- [ ] T017 [US2] `ServerScriptService/CreateRemotes.lua`: add `GetQuests`, `ClaimQuest` (RemoteFunctions) and `QuestUpdated` (RemoteEvent)
- [ ] T018 [US2] `ServerScriptService/RemoteHandlers.lua`: bind `GetQuests`/`ClaimQuest` (standard pattern, fail closed on out-of-set/incomplete/already-claimed); add `QuestService.Track(player, "sell", <crop count>)` after a successful `SellItem` and `SellAll`
- [ ] T019 [US2] `ServerScriptService/Services/PlotManager.lua`: call `QuestService.Track(player, "plant", 1)` on a successful plant and `QuestService.Track(player, "harvest", 1)` on a successful harvest (authoritative plot flow — R6)
- [ ] T020 [US2] `ServerScriptService/Services/Spirit/SpiritCollector.lua`: call `QuestService.Track(player, "catch_spirit", 1)` after a successful collect in `tryCollect`
- [ ] T021 [P] [US2] `Tools/StaticGui/builders/CreateQuestsUI.luau`: build `QuestsUI` per contracts/gui-tree.md (`Header`, `QuestScroll` + hidden `QuestRowTemplate` with objective/`ProgressLabel`/`ProgressBar`/`RewardLabel`/`ClaimButton`, `CloseButton`, backdrop); tokens; text/size/safe-area rules
- [ ] T022 [US2] `Tools/StaticGui/builders/CreateHUDControls.luau`: add `QuestsButton` to the menu column (≥ 44×44, selection group, hints)
- [ ] T023 [US2] Regenerate models and confirm only `QuestsUI.model.json` + `HUDControls.model.json` changed
- [ ] T024 [US2] `StarterPlayer/StarterPlayerScripts/Controllers/QuestController.lua`: render from `GetQuests`, update rows incrementally on `QuestUpdated`, wire `ClaimButton` → `ClaimQuest` (+ completion toast via `ToastQueue`/`UIController.ShowNotification`); register with `WindowManager`; bind via `InputActions`
- [ ] T025 [US2] `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`: boot `QuestController`; wire `QuestsButton` to open the window
- [ ] T026 [US2] Studio playtest V4+V5+V6 (phone/PC/gamepad): progress rises on plant/harvest/sell/spirit (window open and closed); claim once, second claim refused; day rollover resets the set; Output clean

**Checkpoint**: daily quests functional and independently testable.

---

## Phase 5: User Story 3 - Shop restock timer and limited stock (Priority: P2)

**Goal**: per-server limited stock that depletes on buy and refills on a time-derived shared schedule,
with a countdown and restock toast; the server never oversells.

**Independent Test**: open the shop, see per-item stock + a restock countdown, buy an item to 0 (then
it cannot be bought), and watch stock refill with a toast at the boundary (quickstart V7/V8).

- [ ] T027 [US3] `ServerScriptService/Services/ShopStockService.lua`: hold `currentWindow` + `remaining[itemId]`; `Refill()` (re-init from `RetentionConfig.ShopStock`, set window, broadcast `ShopRestocked(RestockAt, Stock)`), `TryReserve(itemId, qty)` (unlimited → true; else atomic check-and-decrement), `GetStock()` / `RestockAt()`; a 1 Hz tick (own loop or hook the `DayNightManager` cadence) detects the window boundary and calls `Refill` (R4/R5)
- [ ] T028 [US3] `ServerScriptService/CreateRemotes.lua`: add `ShopRestocked` (RemoteEvent, FireAllClients)
- [ ] T029 [US3] `ServerScriptService/RemoteHandlers.lua`: extend `GetShopData` to include `Stock`, `RestockAt`, `Interval`; in `BuyItem`, call `ShopStockService.TryReserve(itemId, quantity)` before `TrySpendCoins` and `fail("Out of stock")` on false (no coin spend, no grant); return the item's updated `Stock` (contracts/remotes.md)
- [ ] T030 [P] [US3] `Tools/StaticGui/builders/CreateShopUI.luau`: add `StockLabel` to `CardTemplate` and `RestockLabel` to the header (tokens; text/size rules)
- [ ] T031 [US3] Regenerate models and confirm only `ShopUI.model.json` changed
- [ ] T032 [US3] `StarterPlayer/StarterPlayerScripts/Controllers/ShopController.lua`: set each card's `StockLabel` from `GetShopData.Stock`, dim + disable Buy at 0 (in addition to the Phase-2 unaffordable dim), tick `RestockLabel` from `RestockAt` vs synced server time, and on `ShopRestocked` refill labels + reset the countdown + show a restock toast; update stock from the `BuyItem` response
- [ ] T033 [US3] Studio playtest V7+V8 (short interval): stock shown + countdown; buy to 0 → dimmed + server-refused; ×5 with 3 left → whole purchase rejected atomically; boundary → refill + toast; two clients share the countdown; direct out-of-stock `BuyItem` returns `Success=false` with no state change; Output clean

**Checkpoint**: shop restock functional and independently testable.

---

## Phase 6: User Story 4 - Night as an event (Priority: P3)

**Goal**: a brief nightfall banner on the Day→Night edge and a rate-limited server-wide announcement
when a Rare/Epic spirit appears.

**Independent Test**: watch a Day→Night→Day cycle (one banner at nightfall, none at sunrise) and force
a Rare/Epic spawn to see the announcement (quickstart V9/V10).

- [ ] T034 [US4] `ServerScriptService/CreateRemotes.lua`: add `ServerAnnounce` (RemoteEvent, FireAllClients)
- [ ] T035 [US4] `ServerScriptService/Services/Spirit/SpiritSpawner.lua`: when a spawned spirit's `rarity` is in `RetentionConfig.AnnounceRarities` (Rare/Epic), fire `ServerAnnounce("rare_spirit", displayName, rarity)` to all clients (R9)
- [ ] T036 [P] [US4] `Tools/StaticGui/builders/CreateNotifications.luau`: add hidden `NightBanner` (full-width, `BannerLabel`) and `AnnounceBanner`/`AnnounceLabel` to the `Notifications` ScreenGui (tokens incl. any new banner accent in `UITheme`; safe area; non-interactive)
- [ ] T037 [US4] Regenerate models and confirm only `Notifications.model.json` (+ `UITheme` if a token was added) changed
- [ ] T038 [US4] `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua`: on `DayNightUpdate`, track the last phase and show `NightBanner` for `NightBannerSeconds` only on the Day→Night edge (clear itself; non-blocking); on `ServerAnnounce`, show `AnnounceBanner` rate-limited by `AnnounceDedupeSec` (R8/R9)
- [ ] T039 [US4] Studio playtest V9+V10 (phone/PC): exactly one banner per nightfall, none at sunrise; Rare/Epic spawn announces, Common does not, bursts collapse readably; Output clean

**Checkpoint**: night event functional and independently testable.

---

## Phase 7: User Story 5 - First-session onboarding tutorial (Priority: P3)

**Goal**: a one-time, skippable guided plant → water → sell for new players that never blocks input and
never reappears once done.

**Independent Test**: fresh profile is guided through the steps and the tutorial never returns after
completion/skip; a done profile never sees it (quickstart V11).

- [ ] T040 [US5] `ServerScriptService/CreateRemotes.lua`: add `SetTutorialDone` (RemoteFunction); `ServerScriptService/RemoteHandlers.lua`: bind it (standard pattern) → `PlayerData.SetOnboardingDone(player)`
- [ ] T041 [P] [US5] `Tools/StaticGui/builders/CreateNotifications.luau`: add hidden `TutorialHint` (`Arrow` `ImageLabel` + `HintLabel` + `SkipButton`, ≥ 44×44) that never captures input over movement/menu/hotbar (tokens; safe area)
- [ ] T042 [US5] Regenerate models and confirm only `Notifications.model.json` changed
- [ ] T043 [US5] `StarterPlayer/StarterPlayerScripts/Controllers/TutorialController.lua`: run only when `Onboarding.Done` is false; step machine `go_to_plot → plant → water → sell` advancing on the same client-visible events (plot/inventory updates); `SkipButton` and completion call `SetTutorialDone`; position the hint per step; never block input
- [ ] T044 [US5] `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`: boot `TutorialController` (reads onboarding state from the player-data snapshot)
- [ ] T045 [US5] Studio playtest V11 (phone/PC/gamepad): fresh profile guided through plant→water→sell; rejoin shows nothing; skip persists; a done profile never sees it; hint never blocks controls; Output clean; reset the test-profile onboarding flag if written to a live DataStore

**Checkpoint**: onboarding functional and independently testable.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: documentation, parity and the full-feature validation pass.

- [ ] T046 [P] Update `README.md` with a Retention section (daily reward, quests, restock, night event, tutorial; controls for the new HUD buttons)
- [ ] T047 [P] Update `Docs/HANDOFF.md` to reflect Phase 3 merged state and Phase 4 (day/night palette) as next
- [ ] T048 Final parity: `build_models.py` leaves no diff; `luau Tools/Tests/*.spec.luau` all green (CI gate, SC-006/008)
- [ ] T049 Studio playtest V0+V1+V12 (boot clean; schema reconcile on an existing profile; input-agnostic + safe-area sweep of every new element on phone/PC/gamepad); reset or call out any live-DataStore test data in the PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup; **blocks all user stories** (config + schema + helpers).
- **User Stories (Phase 3–7)**: each depends only on Foundational; recommended order P1 → P2 → P3.
- **Polish (Phase 8)**: depends on the user stories being delivered.

### User Story Dependencies

- **US1 (Daily reward, P1)**: Foundational only. MVP.
- **US2 (Quests, P2)**: Foundational only. Hooks `Track` at plant/harvest/sell/spirit — one line each,
  independent of US1.
- **US3 (Restock, P2)**: Foundational + the Phase-2 shop/`BuyItem`; independent of US1/US2.
- **US4 (Night event, P3)**: Foundational + existing `DayNightUpdate`/`SpiritSpawner`; independent.
- **US5 (Tutorial, P3)**: Foundational + existing plant/water/sell flow; independent.

### Within Each User Story

- Service/config before remotes; remotes before controllers; builder before regenerate before
  controller wiring; **playtest before the commit** (constitution VI).

### Parallel Opportunities

- T004/T006 in Foundational; builder tasks marked [P] (T010, T021, T030, T036, T041) run alongside
  their story's server work (different files).
- After Foundational, the five stories are independent and could be split across sessions; here they
  land sequentially P1 → P3 as commits under the single Phase 3 PR.

---

## Parallel Example: User Story 1

```text
# Server and GUI builder in parallel (different files):
Task: "DailyRewardService in ServerScriptService/Services/DailyRewardService.lua" (T007)
Task: "CreateDailyRewardUI.luau builder in Tools/StaticGui/builders/" (T010)
# Then converge: remotes (T008/T009) → regenerate (T012) → controller (T013/T014) → playtest (T015)
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 Setup → Phase 2 Foundational (blocks everything) → Phase 3 US1.
2. **STOP and VALIDATE**: daily reward claim/streak in Studio (V2/V3).
3. This is the demonstrable retention MVP.

### Incremental Delivery

Foundational → US1 (reward) → US2 (quests) → US3 (restock) → US4 (night) → US5 (tutorial) → Polish.
Each story is a commit with its own clean Studio playtest; all land under the single Phase 3 PR to
`main` (constitution VII), the owner reviews and merges.

---

## Notes

- [P] = different files, no dependency on an incomplete task.
- [Story] maps a task to its user story for traceability.
- Regenerate `StarterGui/*.model.json` after every builder change and commit it (FR-015).
- Every new remote validates caller/types/ranges/ownership/cooldowns and fails closed (FR-013).
- Playtest in Studio before every commit; keep repo ↔ Studio in parity; reset or call out live test data.
