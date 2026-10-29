# Handoff — 2026-10-29

State after Feature 006 (cosy-garden redesign, Stage 2) merged. Owner: Ruslan.

## Where we are

| Item | State |
|---|---|
| UI research + 4-phase UI plan | Done — Claude Doc https://claude.ai/artifact/DWPfqvikPcMnzLTXWz7qk6 |
| Constitution v1.0.0 | `.specify/memory/constitution.md` |
| Phase 1 — mobile UI access (`001-mobile-ui-access`) | Merged to `main` (PR #6) |
| Phase 2 — buy–sell economy (`002-buy-sell-economy`) | Merged to `main` (PR #7) |
| CI workflow (Luau tests + static GUI parity) | On `main` (PR #8) |
| Phase 3 — retention (`003-retention`) | Merged to `main` (PR #9) |
| Phase 4 — visual style / day–night theme engine (`004-visual-style`) | Merged to `main` |
| Feature 005 — cosy-garden UI redesign, Stage 1 (`005-ui-redesign`) | Merged to `main` (PR #10) |
| FR-007 — contextual day Harvest hint (closes 005 gap G1) | Merged to `main` (PR #11) |
| Feature 006 — cosy-garden redesign, Stage 2 (`006-redesign-stage2`) | Merged to `main` (US1 #13, US2 #14, US3 #17, US4 #16) |
| Next | No feature in flight — see "What's next" below |

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
- Synthetic MCP input now exercises real wiring: `user_mouse_input` on a button's `instance_path`
  fires `GuiButton.Activated`, and `user_keyboard_input` reaches `UserInputService` handlers (both
  verified end-to-end in the Feature 005 FR-007 pass — a clicked hint and the F key each harvested).
- `DayNightManager.currentPhase` IS shared by `execute_luau` in the Server datamodel (setting it made
  the 1 Hz broadcaster emit the new phase), unlike client PlayerScripts singletons; still prefer
  remotes for player-scoped state (`PlayerDataManager.Snapshot` returned nil from a fresh require).
- Static GUI generator needs the Luau CLI; `python3 Tools/StaticGui/build_models.py "$(command -v luau)"`.
- CI (`.github/workflows/ci.yml`) runs the offline Luau specs + static GUI parity on PRs to `main`.

## Phase 4 summary (shipped on `004-visual-style`, merged)

Day/night palette switching per constitution principle V. `ReplicatedStorage/UITheme.lua` holds two
palettes (Day "cosy garden" / Night "moonlit") plus structural style tokens; the static GUI builders
bake the Night colours and tag each themed property with a `Theme_<Prop> = "<Token>"` attribute.
`Controllers/ThemeController.lua` repaints every tagged instance on the `DayNightUpdate` phase change
(tweened), with no model regeneration. `theme.spec.luau` enforces token parity across both palettes.

## Feature 005 summary (shipped on `005-ui-redesign`, PR #10 + PR #11, merged)

Cosy-garden UI redesign, **Stage 1** — the HUD, Seed Shop and Backpack rebuilt on the theme engine,
all server-authoritative with no new remotes (contracts/reused-remotes.md).

1. **HUD (US1)** — top-centre SEEDS / GARDEN / SELL nav, left BAG / QUESTS / GIFTS column, top-right
   day/night pill with countdown, single current-quest card, bottom-centre five-slot tool strip
   (slots 3–5 are locked "coming soon" placeholders this stage).
2. **Seed Shop (US2)** — large image cards with rarity badges, ×1/×5/×10 quantity + Buy, three
   Seeds/Tools/Special tabs; opening via SEEDS preselects Seeds.
3. **Backpack (US3)** — multi-column rarity-badged card grid, detail panel with a context action,
   working Equip (`HotbarController.EquipByItemName`), five tabs incl. a Spirits placeholder.
4. **Item icons (US4)** — shared emoji/icon source (`ReplicatedStorage/ItemEmoji.lua`) across shop,
   backpack and hotbar with a letter/emoji fallback.
5. **FR-007 — day Harvest hint (PR #11, closes gap G1)** — `HUD.HarvestHint` (static GUI, themed,
   hidden by default) + `Controllers/HarvestHintController.lua`. By day, near a ready plot, a themed
   hint appears bottom-centre; an on-screen **tap** (primary) or the **F** key harvests the nearest
   ready plot via the existing `InteractWithPlot` path. Hidden at night, out of range, or with a
   window open. (F, not E, so it never clashes with the seller stall's E ProximityPrompt.)

Studio-verified (MCP) in Day and Night, both palettes: hint show/tap-harvest/hide, proximity
re-show, night hide, F harvest next to the stall. No new Output errors.

## Feature 006 summary (cosy-garden redesign Stage 2, `006-redesign-stage2`, merged)

Builds the systems deferred from Stage 1's Out of Scope, as four independently shipped PRs. Server-
authoritative, **no new remotes**; `DefaultData` SchemaVersion 3 → 4 (adds `SpiritCollection` +
`Stats.TotalSpiritsCollected`; reconciled into old profiles). Balance in
`specs/006-redesign-stage2/balance.md`, catalog checked by `Tools/Tests/spirit_config.spec.luau`.

1. **US1 — real hotbar tools (PR #13)**: `lantern` / `net` / `shovel` added to `ShopConfig.buy.tools`
   (bought in the shop Tools tab), fill hotbar slots 3–5 via `HotbarController`. Shovel clears a
   non-ready plant to Empty (rejects a ReadyToHarvest crop) through `PlotManager`/`InteractWithPlot`.
   Lantern biases the night spawn tick (`SpiritSpawner`) toward the equipped player.
2. **US2 — net capture (PR #14)**: new `SpiritData.lua` single-source catalog (read by the server +
   the client Journal); Moonmoth / Moth-Spirit spawn at night; `SpiritCollector` branches by
   `captureMethod` — wisps keep proximity collection, flying creatures need the net and a server-rolled
   per-rarity catch chance, with a one-time first-catch discovery bonus. Reuses the existing spirit
   `ProximityPrompt` + `ServerAnnounce` "appeared" banner.
3. **US3 — Spirit Journal (PR #17)**: `SpiritJournalUI` builder + `SpiritJournalController` (lists every
   catalog type, discovered vs undiscovered, with progress); Backpack Spirits tab shows caught spirits
   as cards + an "Open Journal" action. Reads the collection from the existing `GetPlayerData` snapshot.
4. **US4 — window re-skin (PR #16)**: Sell / Quests / Daily-Gift / Notifications rebuilt on theme
   tokens (`Theme_<Prop>`) so they retint on day/night; cosy-garden gradient headers / cards / buttons;
   element names unchanged (controllers untouched).

## Deferred to a later stage (NOT in Feature 006 — spec "scope ceiling")

Trading, new currencies, a world/map redesign, and anything else beyond the four Stage-2 stories.

## What's next

No feature is in flight. The remaining open item on Stage 2 is the owner's **device-emulator visual
pass** (phone-landscape + gamepad, both palettes) plus the runtime checks the MCP couldn't exercise on
the test profile — the lantern spawn boost, a successful net capture + first-catch bonus, the Journal's
discovered entries, and the full both-palette sweep of the four re-skinned windows. See
`specs/006-redesign-stage2/quickstart.md`.
