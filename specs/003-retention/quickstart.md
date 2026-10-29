# Quickstart / Validation Guide: Retention Loop (Phase 3)

**Feature**: `003-retention` | **Date**: 2026-10-29

Runnable checks that prove the feature end-to-end. Offline checks run from the repo; the V-checks are
Studio playtests (constitution VI) at a **phone landscape** resolution in the device emulator, then PC
and gamepad emulation. References: [spec.md](./spec.md), [balance.md](./balance.md),
[data-model.md](./data-model.md), [contracts/](./contracts/).

## Prerequisites

- `rojo` and `luau` available; `rojo serve default.project.json` syncing to Studio. Note: Rojo does
  **not** sync `ServerScriptService` — deliver server-script changes to Studio manually (serve the repo
  over `python3 -m http.server`, set `HttpService.HttpEnabled = true` in Edit, set each ModuleScript/
  Script `.Source` from the fetched files) before playtesting server changes.
- After any builder edit, regenerate models:
  ```bash
  python3 Tools/StaticGui/build_models.py "$(command -v luau)"
  ```
- Studio Output open; DataStore API access may be off (mock profile) — must not corrupt live data.
- For time-based checks, temporarily shorten `RetentionConfig.RestockIntervalSec` (e.g. 30) and, for
  day-boundary checks, stub `RetentionConfig.DayIndex`/the server clock in a scratch script — revert
  before commit.

## Offline checks

- **O1 — Config parity (SC-006)**: `Tools/Tests/retention_config.spec.luau` asserts every number in
  `balance.md` equals the value in `RetentionConfig` (reward table × 7, quest pool, restock interval,
  per-item stock) and that no number is duplicated elsewhere.
- **O2 — Invariants**: 7 reward days, coins non-decreasing; `#Quests > QuestsPerDay`; every quest
  `target > 0` and reward > 0; `kind ∈ {plant,harvest,sell,catch_spirit}`; `RestockIntervalSec > 0`;
  every `ShopStock` value > 0 and its key resolves to a known item in `ShopConfig`/`PlantData`.
- **O3 — Pure helpers**: `DayIndex(now)` is `now//86400`; `RestockWindow(now)` is `now//interval`;
  `PickDailyQuests(d)` returns `QuestsPerDay` distinct pool entries, is deterministic for a given `d`,
  and the same `d` yields the same set (shared-across-servers property).
- **O4 — Model regeneration (SC-008)**: `build_models.py` runs clean and `StarterGui/*.model.json`
  (incl. new `DailyRewardUI`, `QuestsUI`) regenerate with no diff beyond intended changes.

## Studio playtest checks

- **V0 — Boot clean (SC-008)**: join; Output shows no new errors/warnings from project scripts.
  Pre-existing Phase 1/2 warnings are not regressions.
- **V1 — Schema reconcile (FR-014)**: load an existing Phase-2 profile; confirm `DailyReward`, `Quests`
  and `Onboarding` are filled by reconcile, `SchemaVersion == 3`, and coins/inventory/plots/favourites
  are unchanged.
- **V2 — Daily reward claim on phone (US1, SC-001)**: first login of the day auto-opens
  `DailyRewardUI`; the current day is highlighted and claimable. Tap `ClaimButton` → balance rises by
  the `balance.md` amount for the day; the day shows claimed and the button disables. Reopen via the HUD
  **Rewards** button → still claimed, no second grant.
- **V3 — Streak advance / reset / loop (US1, SC-001)**: with the day index stubbed, claim on
  consecutive days → `StreakDay` increments and the next (larger) reward is shown; skip a day → next
  claim resets to day 1; claim past day 7 → loops to day 1. No double-claim within a day.
- **V4 — Quests render + progress (US2, SC-002)**: open `QuestsUI` via the HUD **Quests** button → the
  day's three quests show with objective, progress and reward. Perform a tracked action (plant a seed) →
  the matching quest's progress rises (via `QuestUpdated`) with the window open and when reopened after
  acting with it closed.
- **V5 — Quest claim once (US2, SC-002)**: complete a quest → `ClaimButton` enables; claim → reward
  granted, toast shown, quest marked claimed; claiming again is refused (no extra reward).
- **V6 — Quest day rollover (US2, SC-002)**: advance the day index → reopening `QuestsUI` shows a fresh
  set with progress reset; the previous day's unclaimed progress does not carry over.
- **V7 — Shop restock + stock (US3, SC-003)**: with a short interval, open the shop → stocked cards show
  remaining stock and the header shows a restock countdown. Buy a stocked item until it hits 0 → the
  card dims and Buy is refused server-side (no coins spent). Buy ×5 with 3 left → whole purchase rejected
  with an "out of stock" message (atomic). At the window boundary → stock refills, countdown resets, a
  restock toast fires. On a second client the countdown matches (shared schedule).
- **V8 — Out-of-stock authority (US3, FR-006/013)**: attempt to buy an out-of-stock item by calling the
  `BuyItem` remote directly (synthetic clicks don't fire `Activated`) → server returns
  `Success=false, Error="Out of stock"`; balance and inventory unchanged.
- **V9 — Nightfall banner (US4, SC-004)**: watch a full Day→Night→Day cycle → exactly one nightfall
  banner appears on nightfall (non-blocking, clears itself) and none on sunrise.
- **V10 — Rare-spirit announcement (US4, SC-004)**: force a Rare/Epic spirit to spawn (e.g. temporarily
  weight `SpiritTypes` or call the spawner) → a server-wide announcement appears; Common spawns produce
  none; several rare spawns within 5 s collapse to a readable single announcement.
- **V11 — Onboarding once (US5, SC-005)**: with a fresh profile, join → the tutorial points to a plot
  and advances through plant → water → sell as each action is done; finish → rejoin shows no tutorial.
  Skip mid-way → persists done. A profile with `Onboarding.Done = true` never sees it. The hint never
  blocks movement, the menu column or the hotbar.
- **V12 — Input-agnostic + safe area (SC-007)**: on phone landscape, PC and gamepad emulation, confirm
  every new element (reward window + claim, quests window + claim, HUD Rewards/Quests buttons, shop
  stock/countdown, nightfall banner, announcement, tutorial hint) is inside the safe area, ≥ 44×44 where
  tappable, body ≥ 18 / titles & buttons ≥ 20, and reachable by touch, key and gamepad.

## Parity & cleanup

- Regenerate models and confirm repo ↔ Studio parity (scripts + GUI) before commit (FR-015, SC-008).
- Revert any temporary config/time stubs used for V3/V6/V7/V10.
- Reset or call out in the PR any test data written to a live DataStore (e.g. a claimed reward or quest
  progress on the owner's test profile).
