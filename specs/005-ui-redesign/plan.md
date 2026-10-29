# Implementation Plan: Cosy-Garden UI Redesign (Stage 1 — Core Screens)

**Branch**: `claude/ui-redesign-e141d3` | **Date**: 2026-10-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/005-ui-redesign/spec.md`

## Summary

Re-skin and relay out the three core screens (HUD, Seed Shop, Backpack) to the owner-approved
cosy-garden concept, reusing every existing gameplay system and the day/night theme engine already on
this branch. No new server-trusted computation is added: buy, sell, equip, teleport and currency all go
through existing remotes. The work is: (1) relayout the HUD (top-centre SEEDS/GARDEN/SELL nav, left
BAG/QUESTS/GIFTS column, top-left coins + Dream Seeds, top-right phase+timer pill, one current-quest
card, a 5-slot tool strip with slots 3–5 as locked placeholders) through the static builders +
`ResponsiveLayout`; (2) redesign the Seed Shop with big image cards, rarity badges, unified x1/x5/x10 +
one Buy, and sold-out / not-enough-coins / not-enough-stock disabled states; (3) redesign the Backpack
as a grid of rarity-badged cards with a detail panel and a working Equip (replacing the current TODO)
plus an empty Spirits-tab placeholder; (4) fill the single-source item icon fields with free/CC0 images
and paint cloned list items via `ThemeController.Paint` (the current gap). All themed via existing
`UITheme` tokens + `Theme_<Prop>` attributes; static GUI regenerated and committed; offline tests +
static-GUI parity kept green; verified in Studio in both palettes at phone-landscape.

## Technical Context

**Language/Version**: Luau (Roblox), synced via Rojo 7.x.

**Primary Dependencies**: Existing `UITheme` / `ThemeController` theme engine; existing controllers
(`UIController`, `ShopController`, `InventoryController`, `HotbarController`, `SellController`,
`QuestController`, `DailyRewardController`, `SoundController`); `WindowManager`, `ResponsiveLayout`,
`InputActions`; config modules `PlantData`, `ShopConfig`, `Constants`, `GameSettings`; static-GUI
builders in `Tools/StaticGui/builders/` + `build_models.py`.

**Storage**: N/A for this feature — player data (coins, DreamSeeds, inventory, favourites) is owned by
existing server services/ProfileService and only presented here. Icon asset ids are stored in the
existing config modules' icon fields.

**Testing**: Offline Luau unit specs under `Tools/Tests/*.spec.luau` (incl. `theme.spec`) + the
static-GUI parity check (regenerate `StarterGui/*.model.json` and compare); Studio MCP playtest for the
Constitution VI gate.

**Target Platform**: Roblox client, mobile-first (phone landscape), input-agnostic (touch / mouse+kb /
gamepad) per Constitution IV.

**Project Type**: Roblox game (single project; Rojo layout is canonical).

**Performance Goals**: No per-frame work for hidden UI; reuse/pool cloned list items; update lists
incrementally; theme re-tint is event-driven on `DayNightUpdate` (no polling).

**Constraints**: Colours only from theme tokens (V); static GUI only, no runtime screen construction
(III); every presented action already server-validated (I); touch targets ≥44×44 and content inside
the safe area (IV).

**Scale/Scope**: 3 screens re-skinned + relaid out; ~4 builders + ~5 controllers touched; item icon
fields filled across the existing item catalog. No new screens, no new persisted data.

## Constitution Check

*GATE: must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | How this plan complies |
|-----------|--------|------------------------|
| I. Server-Authoritative | PASS | No new client computation. Buy/sell/equip/teleport/currency all reuse existing server-validated remotes; the client only renders and requests. Disabled states are UX hints — the server still revalidates every buy/equip. |
| II. Single Source of Truth | PASS | Prices, stock, rarity tiers and growth come from `PlantData`/`ShopConfig`; icons fill the existing single-source icon fields. No balance numbers duplicated in builders/controllers. Display label "Dream Seeds" is UI text, not a config value. |
| III. Rojo / Static GUI | PASS | All screen structure stays in builders → regenerated `StarterGui/*.model.json`, committed. Controllers only attach behaviour and clone from static templates; no whole-screen runtime construction. |
| IV. Mobile-First, Input-Agnostic | PASS | Geometry via `ResponsiveLayout` (Scale/aspect, safe area), not fixed windows; actions reachable by on-screen controls with ≥44×44 targets; key labels (1–5, nav) are shortcuts via `InputActions`, not the only path; selection/focus preserved for gamepad. |
| V. Theme Tokens | PASS | All new/changed colours come from `UITheme` tokens, tagged with `Theme_<Prop>` so `ThemeController` re-tints on phase switch; cloned cards painted via `ThemeController.Paint` (closes the current gap). Both palettes checked for readability. |
| VI. Verified in Studio | PASS | Studio MCP playtest in both palettes at phone-landscape before merge; Output checked for new errors; repo/Studio parity via regenerated models. |
| VII. Simplicity / Small PRs | PASS | Reuse-only, no new systems; spirit/capture/new-tool work is explicitly Out of Scope (deferred). Feature may land as a small PR (or a short series) per screen; see Project Structure. |

**Initial gate: PASS** (no violations → Complexity Tracking not required).

## Project Structure

### Documentation (this feature)

```text
specs/005-ui-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (presented entities / view models)
├── quickstart.md        # Phase 1 output (Studio + offline validation guide)
├── contracts/           # Phase 1 output (reused-remote + UI-template contracts)
├── checklists/
│   └── requirements.md   # spec quality checklist (done)
└── tasks.md             # /speckit-tasks output (not created here)
```

### Source Code (repository root — concrete paths touched)

```text
Tools/StaticGui/builders/
├── CreateHUD.luau            # currency pills (coins + Dream Seeds), phase+timer pill, quest card
├── CreateHUDControls.luau    # top-centre SEEDS/GARDEN/SELL nav, left BAG/QUESTS/GIFTS, 5-slot hotbar
├── CreateShopUI.luau         # big image cards, rarity badge, x1/x5/x10, Buy, Seeds/Tools/Special tabs
└── CreateInventoryUI.luau    # grid cards + rarity badge + favourite, detail panel, 5 tabs
Tools/StaticGui/build_models.py        # regenerate StarterGui/*.model.json (run, don't edit unless needed)

StarterPlayer/StarterPlayerScripts/Utils/
├── ResponsiveLayout.lua      # HUD nav/column/hotbar(→5)/quest-card/phase-pill geometry
├── WindowManager.lua         # window open w/ preselected tab (Shop→Seeds)
└── InputActions.lua          # key labels for nav + 1–5 slots

StarterPlayer/StarterPlayerScripts/Controllers/
├── UIController.lua           # nav wiring (SELL = teleport-then-open), currency incl. Dream Seeds, quest card, phase pill
├── ShopController.lua         # image cards, rarity badges, qty, disabled reasons, Paint clones, preselect Seeds
├── InventoryController.lua    # grid, tab filter incl. Spirits placeholder, detail panel, Equip wiring, Paint clones
├── HotbarController.lua       # 5 slots, slots 3–5 locked placeholders, reflect equipped tool
└── (SellController / QuestController reused; SELL teleport path)

ReplicatedStorage/
├── PlantData.lua             # fill icon/seedIcon/cropIcon fields
└── ShopConfig.lua            # fill icon fields; rarity read-only

StarterGui/*.model.json        # regenerated from builders, committed
Tools/Tests/*.spec.luau        # kept green (theme.spec + parity); add/adjust as needed
```

**Structure Decision**: Single Roblox project, Rojo-canonical. This feature edits existing builders and
controllers in place and regenerates the static GUI; it introduces no new top-level modules beyond small
helpers if a shared component (e.g. a rarity-badge helper) proves worth extracting — any such extraction
will be justified against Constitution VII in Complexity Tracking.

## Design Approach

Confirmed against the code (see [research.md](./research.md) reuse map, [data-model.md](./data-model.md)
view models, [contracts/](./contracts/)). Work, by user story:

- **US1 HUD** — In `CreateHUDControls.luau`: add a top-centre `PrimaryNav` (SEEDS/GARDEN/SELL),
  reduce `MenuButtons` to BAG/QUESTS/GIFTS (remove ShopButton), grow `Hotbar` to five slots with
  locked 3–5. In `CreateHUD.luau`: restyle `DayNightIndicator` into the pill + migrate its RGB to
  tokens (+ optional `TimeLeftLabel`), relabel `DreamSeedsLabel` to "Dream Seeds", add a `QuestCard`.
  In `UIController`: wire the new nav (SELL = teleport `stall` then `Open("Sell")`), wire the missing
  QUESTS/GIFTS touch actions, feed the quest card + countdown, extend `applyLayout` to five slots. In
  `ResponsiveLayout`: `HOTBAR_SLOTS`→5 + desktop W/H + nav/quest-pill geometry. In `InputActions`:
  nav hints + slots 1–5. `HotbarController`: `VISIBLE_SLOTS` + keys 4/5 + locked slots.
- **US2 Shop** — `CreateShopUI.luau`: enlarge `CardTemplate`, replace `RarityStrip` with a
  `RarityBadge` (tier text + colour), relabel the third tab "Special". `ShopController`: preselect
  Seeds via a controller entry point, keep the three distinct afford/stock reasons, **paint each
  cloned card** (`ThemeController.PaintInstant`).
- **US3 Backpack** (largest) — `CreateInventoryUI.luau`: add five tabs, a `CardTemplate`, a
  `DetailPanel`, a Spirits `SpiritsEmptyState`. `InventoryController`: clone+paint cards, filter five
  categories, drive the detail panel + context action, wire Equip through `HotbarController` →
  `EquipTool`. This also migrates the currently un-themed inventory to tokens.
- **US4 Icons** — fill `PlantData.seedIcon/cropIcon` + `ShopConfig` tool/item `icon` with free/CC0
  catalog assets; record them in `contracts/icons.md`; keep the letter/emoji fallbacks.

Cross-cutting: regenerate `StarterGui/*.model.json` after every builder edit; keep `theme.spec` green
(no palette value changes); update `responsive_layout.spec` for five slots; no new remotes.

**PR strategy (VII)**: deliver as a short series rather than one large PR — PR-A = US1 HUD (+ shared
RarityBadge helper if extracted), PR-B = US2 Shop, PR-C = US3 Backpack, with US4 icons folded into the
PR that first surfaces each item. `/speckit-tasks` orders tasks by this slicing so each PR is
independently testable (the spec's user stories are independently shippable MVP slices).

## Post-Design Constitution Re-Check

Re-evaluated after Phase 1 — still **PASS** on I–VII. One item to watch: the countdown number (R3)
needs a single-source phase-duration constant; if none exists it is added to config (II), never
hard-coded, or the number is deferred and the pill shows phase + progress only. No new remotes or
client-trusted computation were introduced (I). No new persisted entities (II). All structure stays in
builders (III). No principle requires a Complexity Tracking justification.

## Complexity Tracking

> No constitution violations identified; no entries required. Any shared-component extraction added
> during implementation will be recorded here with its justification.
