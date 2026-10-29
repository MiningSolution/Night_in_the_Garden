# Handoff — 2026-10-29

State at the end of Phase 3 (retention). Owner: Ruslan.

## Where we are

| Item | State |
|---|---|
| UI research + 4-phase UI plan | Done — Claude Doc https://claude.ai/artifact/DWPfqvikPcMnzLTXWz7qk6 |
| Constitution v1.0.0 | `.specify/memory/constitution.md` |
| Phase 1 — mobile UI access (`001-mobile-ui-access`) | Merged to `main` (PR #6) |
| Phase 2 — buy–sell economy (`002-buy-sell-economy`) | Merged to `main` (PR #7) |
| CI workflow (Luau tests + static GUI parity) | On `main` (PR #8) |
| Phase 3 — retention (`003-retention`) | **PR open to `main`** (owner reviews/merges) |
| Phase 4 — day/night palette switching | **Next** |

## Phase 3 summary (what shipped on `003-retention`)

Five retention features, all server-authoritative, numbers single-sourced in
`ReplicatedStorage/RetentionConfig.lua` (balance in `specs/003-retention/balance.md`, checked by
`Tools/Tests/retention_config.spec.luau`). `DefaultData` SchemaVersion 2 → 3 (adds `DailyReward`,
`Quests`, `Onboarding`; reconciled into old profiles).

1. **Daily reward** — 7-day streak keyed to the UTC day index; `DailyRewardService`,
   `DailyRewardUI`, `DailyRewardController`; HUD Rewards button (`R` / D-pad up); auto-opens on first
   login of a day.
2. **Daily quests** — deterministic daily set from a pool; `QuestService` tracks plant/harvest/sell/
   catch via `QuestService.Track` hooked at `PlotManager`, `RemoteHandlers` (sell), `SpiritCollector`;
   `QuestsUI`, `QuestController`; HUD Quests button (`Q` / D-pad down).
3. **Shop restock** — `ShopStockService` (per-server stock, time-derived window, `ShopRestocked`
   broadcast); `GetShopData` returns Stock/RestockAt/Interval; `BuyItem` reserves stock and fails
   closed; `ShopUI` stock badge + restock countdown.
4. **Night event** — nightfall banner on the day→night edge (reuses `DayNightUpdate`); rare/epic
   spirit → `ServerAnnounce` (FireAllClients), rate-limited client banner. New `UITheme.BannerNight`.
5. **Onboarding** — `TutorialController` guides plant→water→sell once; persists via `SetTutorialDone`;
   `GetPlayerData` now returns `Onboarding`.

Also fixes a pre-existing watering bug: the growth loop sent `Growing` only transiently, so the stored
`plot.State` stayed `Planted` and watering (which requires `Growing`) never worked.
`PlantGrowthService` now persists `State = "Growing"` during growth (planting still rejects non-empty
plots; harvest still needs `ReadyToHarvest`).

## Verified in Studio (via MCP)

Offline specs green; schema reconcile fills the new fields (mock ProfileService) and preserves
coins/favourites. Per story: daily-reward claim/advance/reset/loop + once-per-day; quest GetQuests
deterministic set + claim fail-closed + a real plant runs the Track hook; shop stock decrement +
atomic out-of-stock reject + schedule; rare-spirit announce + de-dupe + spawner hook; onboarding
shows → advances plant→water→sell → persists → does not reshow. No new Output errors.

**Owner device-emulator pass still needed** (the MCP can't drive it): phone-landscape + gamepad visual
sweep of every new element (safe area, ≥44×44, text sizes), the live 2.5s nightfall banner, the
restock-at-boundary refill/toast, and the live SellController→tutorial-complete chain. See
`specs/003-retention/quickstart.md` V0–V12.

## Test data written to the owner's test profile during verification

Reset or ignore as you like (minor): daily reward claimed once (streak day 1, +25 coins; claimable
again next UTC day); a few plots planted/harvested and a couple of carrot seeds spent / crops gained;
`Onboarding.Done = true` (so the tutorial will not reshow for this profile — test onboarding on an alt
account, or clear that field to see it again).

## Environment notes (unchanged)

- Rojo does NOT sync `ServerScriptService` to Studio — server-script changes are delivered to Studio
  manually (this phase used the Studio MCP's multi_edit to mirror them). `StarterPlayer` / `StarterGui`
  / `ReplicatedStorage` sync via Rojo.
- `execute_luau` via the MCP runs in a separate VM from the running game, so required singletons
  (e.g. `PlayerDataManager.Profiles`) are not shared; drive the real server through RemoteFunctions
  from the client datamodel instead.
- Synthetic MCP clicks do NOT fire `GuiButton.Activated`; verify button wiring through remotes/direct
  calls, or leave the click to the owner's pass.
- Static GUI generator needs the Luau CLI; `python3 Tools/StaticGui/build_models.py "$(command -v luau)"`.
- CI (`.github/workflows/ci.yml`) runs the offline Luau specs + static GUI parity on PRs to `main`.

## Next: Phase 4 (visual style)

Day/night palette switching per constitution principle V: a light palette for day, the current dark
palette for night, switched on the `DayNightUpdate` phase change. Mock the key screens in both
palettes first, migrate remaining hard-coded colours to `UITheme` tokens, add press/purchase sounds
and window-open animations.
