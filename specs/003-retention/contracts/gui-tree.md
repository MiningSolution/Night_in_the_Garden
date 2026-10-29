# Contract: Static GUI tree (names the controllers rely on)

**Feature**: `003-retention` | **Date**: 2026-10-29

All GUI is built by the builders in `Tools/StaticGui/builders/*.luau` and regenerated into
`StarterGui/*.model.json` via `build_models.py` (constitution III). Controllers only attach behaviour
and clone the templates named here; they MUST NOT construct whole screens at runtime. Colours come from
`UITheme` tokens (constitution V). All tappable elements ≥ 44×44, body text ≥ 18, titles/buttons ≥ 20,
inside `CoreUISafeInsets` (constitution IV). New windows register with `WindowManager` and bind their
open/claim actions through `InputActions` with gamepad selection groups.

## `DailyRewardUI` (new — `CreateDailyRewardUI.luau`)  (US1)

- `ScreenGui DailyRewardUI` (window, backdrop, `CloseButton`, single-window via `WindowManager`,
  `ResetOnSpawn = false`).
- `Header` with `TitleLabel` ("Daily Reward") and `StreakLabel` ("Day N / 7").
- `TrackScroll`/`TrackRow` (`Frame` + layout) holding seven `DayCell`s cloned from `DayTemplate`
  (hidden): `DayNumberLabel`, `CoinsLabel`, `SeedsLabel` (hidden when 0), `State` indicator
  (`locked` / `today` / `claimed` — colour from `UITheme`).
- `ClaimButton` (footer, ≥ 44×44). `DailyRewardController` renders from `GetDailyReward`, highlights
  `Today`, disables `ClaimButton` when not `Claimable`, wires it to `ClaimDailyReward`, and auto-opens
  the window on the first login of the day when `Claimable`.

## `QuestsUI` (new — `CreateQuestsUI.luau`)  (US2)

- `ScreenGui QuestsUI` (window, backdrop, `CloseButton`, single-window, `ResetOnSpawn = false`).
- `Header` with `TitleLabel` ("Daily Quests").
- `QuestScroll` (`ScrollingFrame`) + `QuestRowTemplate` (hidden): `TextLabel` (objective),
  `ProgressLabel` ("3 / 5"), `ProgressBar` (`Frame` fill), `RewardLabel`, `ClaimButton`
  (enabled only when complete and unclaimed).
- `QuestController` renders from `GetQuests`, listens to `QuestUpdated` to update a row's progress/claim
  state incrementally, and wires `ClaimButton → ClaimQuest`.

## `HUDControls` (extend — `CreateHUDControls.luau`)  (US1/US2)

- Keeps: menu column (`Shop`, `Inventory`, and the Phase 2 `TeleportRow`) and `Hotbar`.
- Adds to the menu column: `RewardsButton` and `QuestsButton` (`TextButton`/`ImageButton`, ≥ 44×44, in
  the selection group, key hints on PC, glyphs on gamepad). `UIController`/the new controllers bind them
  to open `DailyRewardUI` / `QuestsUI` through `InputActions`, without overlapping the hotbar or Roblox
  controls.

## `ShopUI` (extend — `CreateShopUI.luau`)  (US3)

- Keeps the Phase 2 card grid. Adds to `CardTemplate`: a `StockLabel` ("x12" / "Out of stock") and the
  out-of-stock dim state. Adds to the window header a `RestockLabel` ("Restock in m:ss").
- `ShopController` sets each card's `StockLabel` from `GetShopData.Stock`, dims + disables Buy when
  remaining is 0 (in addition to the Phase 2 unaffordable dim), ticks `RestockLabel` from `RestockAt`,
  and on `ShopRestocked` refills labels + resets the countdown.

## `Notifications` (extend — `CreateNotifications.luau`)  (US4/US5)

- Keeps the Phase 2 toast container/template. Adds (same `ScreenGui`, high `DisplayOrder`, safe area,
  `ResetOnSpawn = false`):
  - `NightBanner` (hidden `Frame`): full-width, `BannerLabel` ("Night falls — spirits awaken"), shown
    ~2.5 s non-blocking on the Day→Night edge.
  - `AnnounceBanner` (hidden `Frame`/toast variant): `AnnounceLabel` for the server-wide rare-spirit
    line, rate-limited.
  - `TutorialHint` (hidden `Frame`): `Arrow` (`ImageLabel`) + `HintLabel` + `SkipButton`; the controller
    positions/points it per step and never lets it capture input over movement/menu/hotbar.
- `UIController` shows `NightBanner`/`AnnounceBanner`; `TutorialController` drives `TutorialHint`.

## Regeneration

After any builder change: `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` and commit the
regenerated `StarterGui/*.model.json` so repo and Studio stay identical (FR-015). New ScreenGuis
(`DailyRewardUI`, `QuestsUI`) are picked up automatically by the mapped `StarterGui` path in
`default.project.json`.
