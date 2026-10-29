# Implementation Plan: Cosy-Garden Redesign — Stage 2

**Branch**: `006-redesign-stage2` | **Date**: 2026-10-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/006-redesign-stage2/spec.md`

## Summary

Build the four systems deferred from Feature 005's Out of Scope, as four independently shippable user
stories. Everything extends systems that already exist (a server-driven spirit system in
`ServerScriptService/Services/Spirit/`, the hotbar, the theme engine, ProfileService persistence) and
adds **no new remotes**: the three tools equip through the existing `EquipTool` and act through the
existing `InteractWithPlot` / spirit `ProximityPrompt` paths; the "appeared" banner reuses
`ServerAnnounce`; the Journal reads its data from the existing `GetPlayerData` snapshot (extended with a
new field). The work: (1) make hotbar slots 3–5 the real lantern/net/shovel tools (bought in the shop
Tools tab); (2) add the Moonmoth/Moth-Spirit night creatures and net capture (server rolls a per-rarity
catch chance; lantern raises nearby night spawns); (3) persist a per-player spirit collection and build
the Spirits tab + a new Spirit Journal screen; (4) redesign the Sell / Notifications / Daily-Gift /
Quests windows to the cosy-garden concept. Server stays authoritative, config stays single-sourced, GUI
stays static (builders + `build_models.py`), colours come from theme tokens in both palettes, and each
story is Studio-verified before merge.

## Technical Context

**Language/Version**: Luau (Roblox), synced via Rojo 7.x.

**Primary Dependencies**: Existing spirit system `ServerScriptService/Services/Spirit/` (`SpiritManager`,
`SpiritSpawner`, `SpiritCollector`, `SpiritConfig`, `SpiritTypes`); `PlotManager`, `InventoryService`,
`PlayerDataManager` (ProfileService), `DayNightManager`, `QuestService`; config modules `ShopConfig`,
`PlantData`, `Constants`, `GameSettings`, `DefaultData`, `RetentionConfig`, `ItemEmoji`, `UITheme`;
client controllers (`HotbarController`, `InventoryController`, `UIController`, `ThemeController`,
`WindowManager`, `InputActions`, `ResponsiveLayout`); static-GUI builders + `build_models.py`.

**Storage**: ProfileService player profile (`DefaultData`). This feature adds one new top-level field,
`SpiritCollection`, and bumps `SchemaVersion` 3 → 4 (reconcile backfills existing profiles).

**Testing**: Offline Luau unit specs under `Tools/Tests/*.spec.luau` (add a spirit-catalog/catch-chance
spec as a pure function) + static-GUI parity (regenerate + diff `StarterGui/*.model.json`); Studio MCP
playtest for the Constitution VI gate.

**Target Platform**: Roblox client, mobile-first (phone landscape), input-agnostic (touch / mouse+kb /
gamepad) per Constitution IV.

**Project Type**: Roblox game (single project; Rojo layout is canonical).

**Performance Goals**: Reuse the existing spirit spawn loop (event-driven on night, no new per-frame
work); pool/clone Journal and Spirits cards; no per-frame work for hidden UI; lantern spawn bias is
computed in the existing spawn tick, not per frame.

**Constraints**: No new remotes (reuse-remotes gate); server validates every tool/capture/shovel action
(I); numbers single-sourced (II); static GUI only (III); touch targets ≥44×44, safe area (IV); theme
tokens only, both palettes (V).

**Scale/Scope**: ~2 new config entries area (3 tools in ShopConfig, 2 new spirit types + catch
data), 1 new persisted field, ~6 server modules touched, 1 new client controller + 1 new builder
(Spirit Journal), 5 builders redesigned/extended (InventoryUI Spirits tab + 4 windows), ~3 client
controllers touched.

## Constitution Check

*GATE: must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | How this plan complies |
|-----------|--------|------------------------|
| I. Server-Authoritative | PASS | Tool effects, net capture (incl. the catch-chance roll), the shovel plot-clear and all rewards are decided and validated on the server (equipped-tool, range, cooldown, ownership, target state); the client only equips, requests and renders. The Journal renders server-provided collection data; the client keeps no authoritative collection. |
| II. Single Source of Truth | PASS | Tool prices in `ShopConfig.buy.tools`; spirit types + rarity + weight + catch chance + first-catch bonus in a single catalog; spawn/lantern tunables in `GameSettings.SpiritSettings` / `Constants.SPIRIT`; collection shape in `DefaultData`. No numbers duplicated in controllers/builders. |
| III. Rojo / Static GUI | PASS | New `SpiritJournalUI` and the Spirits-tab cards + the 4 redesigned windows are built in `Tools/StaticGui/builders/` → regenerated `StarterGui/*.model.json`, committed. Controllers clone templates and attach behaviour; no runtime screen construction. |
| IV. Mobile-First, Input-Agnostic | PASS | Net capture uses the spirit's on-screen `ProximityPrompt` (a touch button, with E/ButtonX as shortcuts); tools equip by tap/number/cycle; the Journal opens from an on-screen control; ≥44×44, inside the safe area via `ResponsiveLayout`/`CoreUISafeInsets`. |
| V. Theme Tokens | PASS | The Spirit Journal, Spirits cards and 4 redesigned windows use `UITheme` tokens + `Theme_<Prop>` so `ThemeController` re-tints on phase switch; both palettes checked for readability; remaining hard-coded window colours migrated as the windows are touched. |
| VI. Verified in Studio | PASS | Each story is Studio-MCP playtested in both palettes at phone-landscape (spawn a night creature, capture with the net, shovel a plot, open the Journal, exercise each redesigned window), Output checked, repo/Studio parity via regenerated models. Test DreamSeeds/collection written to the test profile are called out. |
| VII. Simplicity / Small PRs | PASS | Four user stories ship as four (or finer) small PRs; the work extends the existing spirit system rather than replacing it, and adds no remotes. The one new persisted field is additive (reconcile). No speculative abstraction. |

**Initial gate: PASS** — no violations, Complexity Tracking not required.

**Post-Design re-check (after Phase 1): PASS.** The design confirms every gate holds: no new remotes
(contracts/reused-remotes.md), all tool/capture/shovel outcomes server-rolled and validated, numbers
single-sourced (ShopConfig / SpiritData / GameSettings / DefaultData), all screens static via builders,
capture reachable by the on-screen ProximityPrompt, theme tokens in both palettes, additive schema bump
(reconcile). The one new module (`ReplicatedStorage/SpiritData.lua`) is a single-source catalog, not an
added abstraction layer — it exists so the Journal can list undiscovered types without client-trusted
state (research R7). No deviations to track.

## Project Structure

### Documentation (this feature)

```text
specs/006-redesign-stage2/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── reused-remotes.md     # the remotes/paths reused (no new remotes)
│   ├── spirit-and-tools.md   # spirit catalog + tool-definition shapes
│   └── ui-templates.md       # Spirit Journal + Spirits-tab + window templates
├── checklists/
│   └── requirements.md  # spec quality checklist (from /speckit-specify)
└── tasks.md             # /speckit-tasks output (NOT created here)
```

### Source Code (repository root)

```text
ReplicatedStorage/
├── SpiritData.lua          # NEW single-source spirit catalog (ids, display, rarity, weight,
│                           #   catchChance, firstCatchBonus, captureMethod) — read by server + client journal
├── ShopConfig.lua          # EDIT buy.tools += lantern / net / shovel (price, rarity, displayName, icon)
├── DefaultData.lua         # EDIT SchemaVersion 3→4; add SpiritCollection = {}; declare Stats.TotalSpiritsCollected
├── GameSettings.lua        # EDIT SpiritSettings += lantern spawn tunables (radius, boost)
├── Constants.lua           # EDIT SPIRIT structural caps if needed
└── ItemEmoji.lua           # EDIT glyphs for lantern / net / shovel + new creatures

ServerScriptService/Services/
├── Spirit/SpiritTypes.lua  # EDIT to read ReplicatedStorage/SpiritData (single source) or re-export it
├── Spirit/SpiritSpawner.lua    # EDIT build flying-creature models; lantern-biased spawn anchor/radius
├── Spirit/SpiritCollector.lua  # EDIT net-capture branch (chance roll), record collection, first-catch bonus
├── Spirit/SpiritManager.lua    # EDIT lantern awareness in the spawn tick
├── PlotManager.lua         # EDIT add shovel branch (clear plant → Empty)
├── InventoryService.lua    # (new tools already validated via HasItem; confirm)
└── PlayerDataManager.lua   # EDIT Snapshot includes SpiritCollection; add RecordSpiritCaught API

StarterPlayer/StarterPlayerScripts/
├── Controllers/SpiritJournalController.lua   # NEW opens/renders the Journal from snapshot + catalog
├── Controllers/InventoryController.lua       # EDIT Spirits tab real cards (replace placeholder)
├── Controllers/HotbarController.lua          # EDIT buildItems adds owned lantern/net/shovel
├── Controllers/UIController.lua              # EDIT wire a Journal open control (if HUD/Backpack entry)
└── ClientMain.client.lua                     # EDIT boot SpiritJournalController

Tools/StaticGui/builders/
├── CreateSpiritJournalUI.luau   # NEW → StarterGui/SpiritJournalUI.model.json
├── CreateInventoryUI.luau       # EDIT Spirits tab cards + detail action
├── CreateSellUI.luau            # EDIT US4 redesign
├── CreateNotifications.luau     # EDIT US4 redesign
├── CreateDailyRewardUI.luau     # EDIT US4 redesign
└── CreateQuestsUI.luau          # EDIT US4 redesign

Tools/Tests/
└── spirit_config.spec.luau      # NEW offline spec: catalog parity + catch-chance roll is a pure function
```

**Structure Decision**: Single Roblox project; the Rojo layout is canonical. New server behaviour lives
in the existing `Services/Spirit/` and `Services/` modules; the one new client controller follows the
existing controller/boot pattern; every screen stays in a builder. The only structural addition is
`ReplicatedStorage/SpiritData.lua` — a client-readable single-source spirit catalog so the Journal can
show undiscovered entries without the client trusting gameplay data (see research.md).

## Complexity Tracking

> No Constitution violations — not required.
