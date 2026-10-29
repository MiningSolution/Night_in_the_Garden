# Implementation Plan: Retention Loop — Daily Rewards, Quests, Night Events, Shop Restock, Onboarding (UI Plan, Phase 3)

**Branch**: `003-retention` | **Date**: 2026-10-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-retention/spec.md`

## Summary

Add the retention loop on top of the Phase 2 economy. Five independently testable slices:

1. **Daily reward (P1)** — a server-owned 7-day streak keyed off the UTC day (`os.time() ÷ 86400`).
   A new `DailyRewardService` decides claimability, advances/resets/loops the streak and grants the
   day's coins/DreamSeeds through the existing `PlayerData.AddCoins`/`AddDreamSeeds`. A new
   `DailyRewardUI` (static) shows the 7-day track; a HUD **Rewards** button opens it and the client
   auto-opens it on first login of the day. Remotes `GetDailyReward` / `ClaimDailyReward`.
2. **Daily quests (P2)** — a new `QuestService` picks the day's set deterministically from a fixed
   pool by day index (same for everyone), counts progress from events the server already handles
   (plant, harvest, sell, spirit-catch) via a single `QuestService.Track(player, kind, n)` call added
   at those points, and grants a per-quest reward once. A new `QuestsUI` (static) + HUD **Quests**
   button; remotes `GetQuests` / `ClaimQuest` and a `QuestUpdated` push event; a completion toast.
3. **Shop restock (P2)** — a new `ShopStockService` keeps per-server remaining stock per item and a
   time-derived window (`window = os.time() ÷ interval`); it refills at each boundary and broadcasts
   `ShopRestocked` (toast). `GetShopData` is extended with `Stock`, `RestockAt` and `Interval`;
   `BuyItem` reserves stock atomically and fails closed when out. The shop card shows remaining stock
   and the window shows a countdown computed client-side from `RestockAt` (server time).
4. **Night event (P3)** — the client shows a brief nightfall banner on the Day→Night transition it
   already receives via `DayNightUpdate` (no new remote). `SpiritSpawner` fires a new broadcast
   `ServerAnnounce` (FireAllClients) when a **Rare/Epic** spirit spawns; the client shows a server-wide
   announcement, rate-limited.
5. **Onboarding (P3)** — a client `TutorialController` reads a persisted `Onboarding.Done` flag and,
   for new players only, guides plant → water → sell one step at a time off the same events, then
   persists completion via `SetTutorialDone`. Static arrow/hint elements; skippable; never blocks input.

All numbers (reward table, quest pool + targets/rewards, restock interval + per-item stock) live once
in a new `ReplicatedStorage/RetentionConfig.lua`, written first in [balance.md](./balance.md) and
checked by a new offline Luau test. Everything stays server-authoritative (I), config-single-source
(II), static-GUI through the builders (III), mobile-first/input-agnostic (IV) and theme-token only (V);
day/night palette switching remains Phase 4.

## Technical Context

**Language/Version**: Luau (Roblox client + server); Python 3 for the GUI generator driver

**Primary Dependencies**: Roblox services — `Players`, `ContextActionService`, `UserInputService`,
`GuiService`, `TweenService`, `StarterGui`, `Workspace`; Rojo 7.x; vendored ProfileService; existing
server services (`PlayerDataManager`, `InventoryService`, `PlotManager`, `PlantGrowthService`,
`DayNightManager`, `SpiritManager`/`SpiritSpawner`/`SpiritCollector`, `AntiCheatLogger`) and client
modules (`StateManager`, `ClientDataCache`, `UIController`, `ToastQueue`, `WindowManager`,
`ResponsiveLayout`, `InputActions`, controllers) from Phases 1–2

**Storage**: ProfileService profiles. `DefaultData` SchemaVersion 2 → **3**: adds `DailyReward`,
`Quests`, `Onboarding`; reconciled on load, never dropped (II). Shop stock is **not** persisted
(per-server, time-derived); it is reconstructed on load from the current window.

**Testing**: a new offline Luau check `Tools/Tests/retention_config.spec.luau` (reward table, quest
pool, restock interval and stock parity with `balance.md`, plus pure helpers — day index, window math,
deterministic quest pick — exercised without the `game` global); `build_models.py` regeneration
parity; Studio playtests V0–V12 on phone, PC and gamepad emulation (see [quickstart.md](./quickstart.md))

**Target Platform**: Roblox — phones/tablets (landscape), PC; console via gamepad emulation (console
publishing out of scope)

**Project Type**: Roblox game, Rojo-synced repository (client + server + static GUI)

**Performance Goals**: no per-frame work for hidden UI; the restock-window check and countdown are a
1 Hz tick (reuse the existing `DayNightManager` cadence, not RenderStepped); toasts/announcements and
quest/reward rows are cloned from static templates and updated incrementally, not rebuilt

**Constraints**: text ≥ 18 body / ≥ 20 titles & buttons; tap targets ≥ 44×44; inside
`CoreUISafeInsets`; shared action layer for touch/keyboard/gamepad; no Escape; server fails closed on
every reward/quest/stock action; StreamingEnabled on (wait for streamed parts)

**Scale/Scope**: 1 new config module (`RetentionConfig`) + `DefaultData` schema bump; 3 new server
services (`DailyRewardService`, `QuestService`, `ShopStockService`); ~5 new remotes + `GetShopData`/
`BuyItem` extended + 2 new broadcast events; `SpiritSpawner`/`SpiritCollector` and the plant/harvest/
sell call sites get a one-line `QuestService.Track`/announce hook; 2 new ScreenGuis (`DailyRewardUI`,
`QuestsUI`) + changes to `HUDControls` (Rewards/Quests buttons), `ShopUI` (stock + countdown) and a
`Notifications`/HUD overlay for the nightfall banner + announcement + tutorial hints; ~3 new builders +
3 changed; ~3 new controllers (`DailyRewardController`, `QuestController`, `TutorialController`) + 2
changed (`ShopController`, `UIController`); 5 user stories across P1–P3.

All unknowns are resolved in [research.md](./research.md) R1–R12. Two items carry a Studio
verification step rather than an open question: the restock window crossing a real boundary
(R4, quickstart V7) and the Day→Night banner firing exactly once per transition (R8, quickstart V9).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Server-authoritative | Daily-reward claimability/streak, quest progress and completion, and shop stock are decided and stored on the server from its own clock; the client sends only `GetDailyReward`/`ClaimDailyReward`/`GetQuests`/`ClaimQuest`/`SetTutorialDone` requests and renders. Every new remote reuses the hardened `RemoteHandlers` pattern (pcall, `rate_ok` 5 req/s, strict type/range/ownership checks, `fail` closed, `AntiCheat.log`). No client can grant itself coins, seeds, progress or stock; `BuyItem` reserves stock server-side and fails closed. | ✅ |
| II. Single source of truth | All new numbers (7-day reward table, quest pool with targets/rewards, restock interval, per-item stock) live once in `RetentionConfig`, written first in `balance.md`; stock keys reference existing `ShopConfig`/`PlantData` ids (no duplicated item lists); controllers and builders read config or a server snapshot, never hard-code numbers. New colours are `UITheme` tokens. | ✅ |
| III. Rojo / static GUI | `DailyRewardUI`, `QuestsUI`, the nightfall banner, the announcement line, the tutorial hints, the shop stock/countdown and the HUD Rewards/Quests buttons are built by `Tools/StaticGui/builders/*.luau` into `StarterGui/*.model.json`; controllers clone templates and attach behaviour only; models regenerated and committed. World/placement changes (if any) mirrored in the same PR. | ✅ |
| IV. Mobile-first, input-agnostic | Reward/quest windows, claim buttons, HUD buttons, banner and tutorial hints are touch-first, ≥ 44×44, inside the safe area, bound through `InputActions` with gamepad selection groups and PC key hints; the tutorial never blocks movement, the menu column or the hotbar. | ✅ |
| V. Theme tokens | New/changed UI reads `UITheme` tokens; any new token (e.g. a banner/announcement accent) is added to the current dark palette. Day/night **palette switching** itself stays Phase 4; this feature only reacts to the phase to time the banner, it does not restyle palettes. | ✅ |
| VI. Verified in Studio | Quickstart V0–V12 on phone/PC/gamepad; offline config parity + pure-helper checks; ProfileService tolerates a mock DataStore; schema reconcile verified on an existing profile; test DataStore writes reset or called out in the PR; no new script errors/warnings at merge. | ✅ |
| VII. Simplicity, small PR | Scope is split by priority into independently testable user stories, each its own commit with its own clean playtest, landing as the single Phase 3 PR to `main` (matching Phases 1–2). Reuse over new infrastructure: existing `ToastQueue`, `UIController` coin tween, `RemoteHandlers` pattern, `DayNightManager` tick and phase, `WindowManager`/`InputActions`. Three new server services are each a thin, single-responsibility module; no speculative abstraction. | ✅ |

**Gate result (pre-research)**: pass. **Re-check after Phase 1 design**: pass — the design adds only
what the spec requires (one config module, three single-responsibility services, five remotes + two
broadcasts, two ScreenGuis, three controllers); each addition maps to a principle (II config, I
remotes/services, III GUI, IV/V UI) and none violates one. No Complexity Tracking entries.

## Project Structure

### Documentation (this feature)

```text
specs/003-retention/
├── spec.md              # /speckit-specify + /speckit-clarify
├── plan.md              # this file
├── balance.md           # Phase 1 — retention numbers (written first, source for config)
├── research.md          # Phase 0 — R1–R12
├── data-model.md        # Phase 1 — entities, schema bump, state transitions
├── quickstart.md        # Phase 1 — validation V0–V12
├── contracts/
│   ├── remotes.md       # server remote contracts (reward/quest/stock/announce/tutorial)
│   └── gui-tree.md      # static GUI names/templates the controllers rely on
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
ReplicatedStorage/
├── RetentionConfig.lua              # NEW: reward table, quest pool, restock interval+stock, helpers
├── DefaultData.lua                  # SchemaVersion 2→3: DailyReward, Quests, Onboarding
├── UITheme.lua                      # + banner/announcement accent token(s) (dark palette)
└── Constants.lua                    # (reuse NOTIFICATION_*, ANIMATION tweens)
ServerScriptService/
├── CreateRemotes.lua                # + GetDailyReward, ClaimDailyReward, GetQuests, ClaimQuest,
│                                    #   SetTutorialDone, QuestUpdated, ShopRestocked, ServerAnnounce
├── RemoteHandlers.lua               # bind new RFs; extend GetShopData (Stock/RestockAt/Interval);
│                                    #   BuyItem reserves stock; SellItem/SellAll → QuestService.Track
└── Services/
    ├── DailyRewardService.lua       # NEW: streak day/claim logic off os.time()//86400
    ├── QuestService.lua             # NEW: day set, Track(player,kind,n), claim, QuestUpdated push
    ├── ShopStockService.lua         # NEW: per-server remaining stock, window math, refill broadcast
    ├── PlayerDataManager.lua        # Migrate 2→3; reward/quest/onboarding accessors; reconcile
    ├── PlotManager.lua              # + QuestService.Track on plant / harvest
    └── Spirit/
        ├── SpiritCollector.lua      # + QuestService.Track("catch_spirit") on successful collect
        └── SpiritSpawner.lua        # + ServerAnnounce on Rare/Epic spawn (night event)
StarterGui/
├── DailyRewardUI.model.json         # NEW (7-day track + DayTemplate)
├── QuestsUI.model.json              # NEW (quest list + QuestRowTemplate)
├── HUDControls.model.json           # regenerated (Rewards + Quests buttons)
├── ShopUI.model.json                # regenerated (per-card stock label + restock countdown)
└── Notifications.model.json         # regenerated (nightfall banner + announcement + tutorial hint templates)
StarterPlayer/StarterPlayerScripts/
├── ClientMain.client.lua            # boot the 3 new controllers
├── Controllers/
│   ├── DailyRewardController.lua     # NEW: render track, claim, auto-open on first login of day
│   ├── QuestController.lua           # NEW: render quests, progress, claim; QuestUpdated listener
│   ├── TutorialController.lua        # NEW: step machine over plant→water→sell; skip; persist
│   ├── ShopController.lua            # + remaining-stock per card, restock countdown, out-of-stock dim
│   └── UIController.lua              # nightfall banner + server announcement via ToastQueue/overlay
└── Utils/
    └── ToastQueue.lua               # reuse for completion toasts / announcements (banner may be its own)
Tools/
├── StaticGui/builders/
│   ├── CreateDailyRewardUI.luau      # NEW
│   ├── CreateQuestsUI.luau           # NEW
│   ├── CreateHUDControls.luau        # + Rewards/Quests buttons
│   ├── CreateShopUI.luau             # + stock label + countdown
│   └── CreateNotifications.luau      # + banner/announcement/tutorial-hint templates
└── Tests/
    └── retention_config.spec.luau    # NEW: config/balance parity + pure helper checks
```

**Structure Decision**: keep the existing Rojo layout (III) and the Phase 1–2 pattern — stateful
helpers in `Utils/`, screen logic in `Controllers/`, static GUI in builders, server logic in
single-responsibility `Services/`. New client logic is three controllers; new server logic is three
services plus thin hooks at existing event sites. Everything else extends existing files.

## Implementation notes (input for /speckit-tasks)

Suggested order, each step independently playtestable; one commit per step, all under the single
Phase 3 PR (VII).

1. **Foundation / config**: write `balance.md`; create `RetentionConfig` (reward table, quest pool +
   `QuestsPerDay`, restock interval + per-item stock, helpers: `DayIndex(now)`, `RestockWindow(now)`,
   `PickDailyQuests(dayIndex)`); `DefaultData` SchemaVersion 2→3 (`DailyReward`, `Quests`,
   `Onboarding`) + `PlayerDataManager.Migrate`; offline `retention_config.spec.luau`.
2. **Daily reward (US1, P1)**: `DailyRewardService` (claim/advance/reset/loop off `DayIndex`);
   `PlayerData` reward accessors; `GetDailyReward`/`ClaimDailyReward` remotes; `CreateDailyRewardUI` +
   `DailyRewardController` (render track, claim, auto-open first login of day); HUD **Rewards** button;
   regenerate.
3. **Daily quests (US2, P2)**: `QuestService` (day set, `Track`, claim, `QuestUpdated`); hook
   `Track` at plant/harvest (`PlotManager`), sell (`RemoteHandlers`), spirit-catch (`SpiritCollector`);
   `GetQuests`/`ClaimQuest` remotes; `CreateQuestsUI` + `QuestController`; HUD **Quests** button;
   completion toast; regenerate.
4. **Shop restock (US3, P2)**: `ShopStockService` (remaining per item, window refill, `ShopRestocked`
   broadcast + 1 Hz boundary tick); extend `GetShopData` (`Stock`/`RestockAt`/`Interval`); `BuyItem`
   reserves stock atomically, fails closed; `ShopController` stock label + out-of-stock dim + countdown;
   restock toast; regenerate.
5. **Night event (US4, P3)**: client nightfall banner on Day→Night from `DayNightUpdate`;
   `ServerAnnounce` broadcast fired by `SpiritSpawner` on Rare/Epic spawn; `UIController` renders the
   banner + rate-limited announcement; builder templates; regenerate.
6. **Onboarding (US5, P3)**: `Onboarding` accessors + `SetTutorialDone` remote; `TutorialController`
   step machine (plant → water → sell) off existing events, skippable, persisted; static hint elements;
   regenerate.
7. **Polish**: README retention section; parity; quickstart V0–V12 on phone/PC/gamepad; reset/call out
   any test DataStore writes.

## Complexity Tracking

No constitution violations to justify. The phase is large but is delivered as prioritized,
independently testable slices under one small-scoped PR (VII) and reuses existing infrastructure
(toast queue, coin tween, remote-handler pattern, day/night tick) rather than adding abstraction.
