---
description: "Task list for the Cosy-Garden UI Redesign (Stage 1)"
---

# Tasks: Cosy-Garden UI Redesign (Stage 1 — Core Screens)

**Input**: Design documents from `specs/005-ui-redesign/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (all present)

**Tests**: No new test suites are requested (this is a reskin). Existing gates MUST stay green — the
offline specs (`Tools/Tests/*.spec.luau`) and the static-GUI fingerprint parity — so each story ends
with a regenerate + specs-green task, and `responsive_layout.spec.luau` is updated for the 5-slot
hotbar. Studio playtest is the Constitution VI gate.

**Organization**: by user story (US1 HUD → US2 Shop → US3 Backpack → US4 Icons), each independently
shippable as its own small PR (plan.md PR strategy).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- Paths are repo-relative to the worktree root.

---

## Phase 1: Setup (baseline)

**Purpose**: confirm a green baseline before changing anything.

- [ ] T001 Confirm the regenerate + test pipeline is green on the current branch: run
  `python3 Tools/StaticGui/build_models.py "$(command -v luau)"` then `for f in Tools/Tests/*.spec.luau; do luau "$f"; done`;
  record the baseline fingerprints (expect no git diff in `StarterGui/*.model.json`).
- [ ] T002 Read `GameSettings.lua` / `Constants.lua` to find a single-source day/night phase-duration
  value for the HUD countdown (R3); if none exists, note it so T013 adds one to config rather than
  hard-coding (Constitution II).

**Checkpoint**: baseline green, countdown data source known.

---

## Phase 2: Foundational (shared, blocks US2 + US3)

**Purpose**: the one thing Shop and Backpack share — a consistent rarity badge — plus the
paint-on-clone pattern both controllers rely on.

- [ ] T003 Add a shared rarity-badge builder helper + tier→UPPERCASE-text map, used by both the Shop
  and Backpack card templates, in a small builder-local module (e.g.
  `Tools/StaticGui/builders/_RarityBadge.luau` required by the builders, or a `makeRarityBadge(parent)`
  helper co-located and reused) — renders `BadgeText` (COMMON/UNCOMMON/RARE/EPIC/LEGENDARY) + a
  `Theme_BackgroundColor3 = "Rarity<Tier>"` surface; colour is independent of item colour (FR-025).
- [ ] T004 Confirm the paint-on-clone call site contract: `ThemeController.PaintInstant(clone)` after
  parenting each cloned card (R9); note it in both controllers' clone functions as the standard (no
  code yet, just the agreed call — applied in T024 and T034).

**Checkpoint**: rarity badge + paint pattern ready for both card screens.

---

## Phase 3: User Story 1 — Redesigned, relaid-out HUD (Priority: P1) 🎯 MVP

**Goal**: top-centre SEEDS/GARDEN/SELL nav, left BAG/QUESTS/GIFTS column, top-left coins + Dream Seeds,
top-right phase+timer pill, one quest card, a 5-slot tool strip (3–5 locked) — same layout in both
palettes.

**Independent Test**: quickstart.md §2 "HUD" — nav/column/currency/pill/quest/slots present, actions
work, phase flip keeps layout and only recolours.

### Builders (static GUI)

- [ ] T005 [US1] In `Tools/StaticGui/builders/CreateHUDControls.luau`, add a top-centre `PrimaryNav`
  frame with `SeedsButton`/`GardenButton`/`SellButton` (labels SEEDS/GARDEN/SELL, ≥44×44, themed via
  `bind`/`strokeOf`, `KeyHint`+`PadHint` slots) per `contracts/ui-templates.md`.
- [ ] T006 [US1] In `CreateHUDControls.luau`, reduce `MenuButtons` to `InventoryButton` (BAG),
  `QuestsButton` (QUESTS), `RewardsButton` (GIFTS) — remove `ShopButton`; update labels/glyphs; remove
  the old top-right `TeleportRow` (its actions move to PrimaryNav).
- [ ] T007 [US1] In `CreateHUDControls.luau`, grow `Hotbar` to five slots `Slot1..Slot5` (loop 1..5,
  5-entry `defaultEmojis`, wider default frame), add a `LockOverlay` child to slots 3–5, `KeybindHint`
  text 1–5.
- [ ] T008 [US1] In `Tools/StaticGui/builders/CreateHUD.luau`, restyle `DayNightIndicator` into the
  concept pill and migrate its hard-coded RGB (`PhaseLabel`, `ProgressBar`) to theme tokens with
  `Theme_<Prop>` attributes; add an optional `TimeLeftLabel`.
- [ ] T009 [US1] In `CreateHUD.luau`, relabel `DreamSeedsLabel` display text to "Dream Seeds" (keep
  token `Dream`; do not rename the currency internally, FR-003).
- [ ] T010 [US1] In `CreateHUD.luau`, add a themed `QuestCard` (TitleLabel/ProgressLabel/RewardLabel)
  on the right per `contracts/ui-templates.md`.

### Layout + input

- [ ] T011 [US1] In `StarterPlayer/StarterPlayerScripts/Utils/ResponsiveLayout.lua`, set
  `HOTBAR_SLOTS = 5` and re-tune `HOTBAR_DESKTOP_W`/`HOTBAR_DESKTOP_H` for five slots; add geometry for
  the top-centre nav and the phase pill / quest card positions (keep inside safe area, clear of
  movement/jump zones).
- [ ] T012 [US1] Update `Tools/Tests/responsive_layout.spec.luau` hotbar expectations for the 5-slot
  geometry (width math, 44×44 min, no overlap) so the spec passes.
- [ ] T013 [US1] In `StarterPlayer/StarterPlayerScripts/Utils/InputActions.lua`, add key/gamepad hints
  for the new nav buttons and extend `applyHints` slot loop to 1..5 (slots 4/5 hints only if a real
  tool; locked slots show the lock, not a key action).

### Controller wiring

- [ ] T014 [US1] In `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua`, wire
  `PrimaryNav.SeedsButton.Activated` → open Shop preselecting Seeds (calls the T023 entry point);
  `GardenButton` → `RequestTeleport:InvokeServer("garden")`; `SellButton` →
  `RequestTeleport:InvokeServer("stall")` then on success `WindowManager.Open("Sell")`.
- [ ] T015 [US1] In `UIController.lua`, wire the missing touch actions: `MenuButtons.QuestsButton` and
  `MenuButtons.RewardsButton` `.Activated` → their window toggles (confirmed gap, R2).
- [ ] T016 [US1] In `UIController.lua`, extend `applyLayout` to loop `Slot1..Slot5` and position/size
  all five; feed the phase pill countdown in `UpdateDayNight` using the T002/T013 duration
  (`remaining = (1-progress) × duration`), refreshed per `DayNightUpdate` tick, no client clock.
- [ ] T017 [US1] In `UIController.lua`, populate the `QuestCard` from existing quest state (first
  incomplete quest) and make a tap open the Quests window; subscribe to quest updates.
- [ ] T018 [US1] In `StarterPlayer/StarterPlayerScripts/Controllers/HotbarController.lua`, set
  `VISIBLE_SLOTS = 5`, bind number keys 4/5, and render slots 3–5 as locked placeholders that never
  equip (FR-006); keep slots 1–2 functional.

### Verify US1

- [ ] T019 [US1] Regenerate: `python3 Tools/StaticGui/build_models.py "$(command -v luau)"`; run all
  `Tools/Tests/*.spec.luau` green (esp. the updated responsive + unchanged theme); commit the
  regenerated `StarterGui/{HUD,HUDControls}.model.json`.
- [ ] T020 [US1] Studio playtest the HUD in Day and Night (force phase via `DayNightUpdate`): nav +
  column + currency + pill + quest card + 5 slots correct, actions work (touch + key), phase flip keeps
  layout/size (SC-002), no new Output errors; screenshot both palettes for the owner.

**Checkpoint**: HUD matches the concept in both palettes → PR-A.

---

## Phase 4: User Story 2 — Redesigned Seed Shop (Priority: P1)

**Goal**: big image cards with rarity badges, unified ×1/×5/×10 + one Buy, distinct disabled reasons,
painted clones, Seeds preselected from the nav.

**Independent Test**: quickstart.md §2 "Seed Shop".

- [ ] T021 [US2] In `Tools/StaticGui/builders/CreateShopUI.luau`, enlarge `CardTemplate` to a big image
  card (dominant `Icon`, `NameLabel`, `PriceLabel`, `StockLabel`) and replace the bare `RarityStrip`
  with the shared `RarityBadge` (T003); keep `QtyRow.{QtyX1,QtyX5,QtyX10}` and `BuyButton`.
- [ ] T022 [US2] In `CreateShopUI.luau`, relabel the third tab (`itemsTab`) display text to "Special"
  (keep the id `itemsTab`; item type vs. special-offer filter stay independent, FR-014).
- [ ] T023 [US2] In `StarterPlayer/StarterPlayerScripts/Controllers/ShopController.lua`, add an
  `OpenOnTab("seeds")` entry point (opens the window and selects the Seeds tab) for the SEEDS nav
  (FR-015); smallest diff, no `WindowManager` signature change.
- [ ] T024 [US2] In `ShopController.lua` `makeCard`, call `ThemeController.PaintInstant(card)` after
  parenting each cloned card so fresh cards take the active palette and repaint on phase change (R9).
- [ ] T025 [US2] In `ShopController.lua`, populate the `RarityBadge` (tier text + `Rarity<Tier>` token)
  from `ShopConfig.GetRarity(itemId)` for each card.
- [ ] T026 [US2] In `ShopController.lua`, verify the three disabled reasons remain distinct in
  `applyAfford`/`refreshStockLabel` (Out of stock / Can't afford / exceeds-stock) and that a chosen qty
  means exactly that qty (FR-011/012); a failed `BuyItem` keeps the window + selection (FR-013).
- [ ] T027 [US2] Regenerate + specs green; commit `StarterGui/ShopUI.model.json`.
- [ ] T028 [US2] Studio playtest the shop in Day and Night: cards/badges/prices/stock, ×1/×5/×10 buy
  updates in place, all three blocked cases, painted clones in Day; screenshot both palettes.

**Checkpoint**: Shop matches the concept → PR-B.

---

## Phase 5: User Story 3 — Redesigned Backpack (Priority: P2)

**Goal**: grid of rarity-badged cards + favourite marks, a detail panel with a context action, working
Equip, five tabs with a Spirits placeholder. (Largest story — also migrates the un-themed inventory.)

**Independent Test**: quickstart.md §2 "Backpack".

- [ ] T029 [US3] In `Tools/StaticGui/builders/CreateInventoryUI.luau`, replace `TabContainer` tabs with
  the five `AllTab/SeedsTab/ToolsTab/CropsTab/SpiritsTab` (themed).
- [ ] T030 [US3] In `CreateInventoryUI.luau`, add a themed `CardTemplate` (Icon+FallbackLetter,
  NameLabel, shared `RarityBadge`, QtyLabel, FavouriteMark) inside `ItemGrid` (Visible=false).
- [ ] T031 [US3] In `CreateInventoryUI.luau`, add a `DetailPanel` (SelectedIcon, SelectedName,
  SelectedDescription, FavouriteToggle, ActionButton) and a `SpiritsEmptyState` "coming soon"
  placeholder per `contracts/ui-templates.md`.
- [ ] T032 [US3] In `StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.lua`, replace
  the code-built slots with clones of `CardTemplate`; keep the incremental create/update/destroy keyed
  on the item name.
- [ ] T033 [US3] In `InventoryController.lua`, implement the five-category filter (All = all; Seeds via
  IsSeed; Tools via IsTool; Crops; Spirits = show `SpiritsEmptyState`, FR-017) via `SwitchTab`.
- [ ] T034 [US3] In `InventoryController.lua`, call `ThemeController.PaintInstant(card)` on each clone
  and migrate the remaining hard-coded RGB (slots + `paintTabs`) to `Theme_<Prop>` tokens (closes the
  un-themed-inventory gap, V).
- [ ] T035 [US3] In `InventoryController.lua`, drive the `DetailPanel` on card selection (icon, name,
  description via `PlantData.GetItemDisplayData`, favourite state via `ToggleFavourite`), and set
  `ActionButton` text/behaviour by category: Equip (Seeds/Tools), Go to sell (Crops), View journal
  (Spirits — disabled placeholder this stage) (FR-018).
- [ ] T036 [US3] Wire Equip: add `HotbarController.EquipByItemName(itemName)` (select the matching
  hotbar slot → existing `equipCurrent()` → `EquipTool:FireServer`), and call it from the Backpack
  Equip action so the equipped seed/tool shows selected on the HUD strip (FR-019; replaces the TODO).
- [ ] T037 [US3] Regenerate + specs green; commit `StarterGui/InventoryUI.model.json`.
- [ ] T038 [US3] Studio playtest the Backpack in Day and Night: grid + badges + favourite marks, five
  tabs filter, Spirits placeholder, detail panel actions, Equip a seed and a tool → selected on the HUD
  strip (SC-004); screenshot both palettes.

**Checkpoint**: Backpack matches the concept → PR-C.

---

## Phase 6: User Story 4 — Item icons (Priority: P2)

**Goal**: consistent free/CC0 pictures across shop, backpack and hotbar; letter fallback preserved.

**Independent Test**: quickstart.md §2 "Icons".

- [ ] T039 [US4] Source consistent free/commercial-OK item images via Studio (`search_asset` /
  `insert_asset`, prefer one pack e.g. Kenney CC0) for the 7 plants (seed + crop) and the tools; verify
  each licence is commercial-OK.
- [ ] T040 [US4] Fill `ReplicatedStorage/PlantData.lua` `seedIcon`/`cropIcon` and
  `ReplicatedStorage/ShopConfig.lua` tool/item `icon` fields with the asset ids (seeds/sell derive from
  PlantData automatically); keep any unfound item `""` (fallback).
- [ ] T041 [US4] Record every asset id + source + licence in `specs/005-ui-redesign/contracts/icons.md`.
- [ ] T042 [US4] Regenerate + specs green (`economy_config.spec` must stay green — icons are strings,
  not balance numbers); commit config + any model changes.
- [ ] T043 [US4] Studio check: items show pictures in shop + backpack + hotbar; blank one field,
  regenerate, confirm the letter/emoji fallback still renders (no broken image) (SC-005).

**Checkpoint**: icons wired, licences recorded.

---

## Phase 7: Polish & Cross-Cutting

- [ ] T044 Full Studio playtest of all three screens in both palettes at phone-landscape (device
  emulator): readability, no clipped/overflowing text incl. a long/RU label (SC-007), movement/jump
  zones unobstructed (IV), no new Output errors (SC-006).
- [ ] T045 [P] Update `Docs/HANDOFF.md` and `README.md` with the Stage-1 redesign state and what is
  deferred (spirits/capture/new tools).
- [ ] T046 Final regenerate + full `Tools/Tests/*.spec.luau` green + git parity of all
  `StarterGui/*.model.json`; confirm no new remotes were added (contracts/reused-remotes.md).
- [ ] T047 Open the PR(s) per the plan's PR strategy (PR-A HUD, PR-B Shop, PR-C Backpack; US4 folded in)
  to `main`; owner reviews/merges and does the device-emulator visual pass.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** → **Foundational (Phase 2)** → user stories.
- **US1 (P1)** is the MVP and is independent. **US2 (P1)** and **US3 (P2)** both depend only on Phase 2
  (rarity badge + paint pattern); they are independent of each other and can be done in either order /
  parallel. **US3's Equip (T036)** reads best after **US1's 5-slot hotbar (T018)** exists, so if US3 is
  done before US1, the equipped-slot visual check moves to when US1 lands.
- **US4 (P2)** is independent; it visibly pays off inside whichever of US2/US3 renders an item first, so
  it can run alongside them or right after.
- **Polish (Phase 7)** last.

### Within each story

Builders → regenerate → controller wiring → regenerate + specs → Studio playtest. Commit after each
task or logical group; regenerate after every builder edit.

### Parallel opportunities

- T005/T006/T007 (HUDControls) are the same file → sequential; T008/T009/T010 (CreateHUD) same file →
  sequential; but the two builder files can be worked in parallel [P].
- Across stories: US2 and US4, or US3 and US4, can proceed in parallel (different files), given Phase 2
  is done.

---

## Implementation Strategy

**MVP = US1 (HUD).** Ship Setup + Foundational + US1 → validate in Studio (both palettes) → PR-A. Then
add US2 (PR-B), US3 (PR-C), folding US4 icons into whichever surfaces each item first. Each PR is small,
independently testable, and keeps the offline + parity gates green.

## Notes

- No new RemoteEvents/RemoteFunctions (contracts/reused-remotes.md) — the server stays the authority.
- No palette value changes → `theme.spec` stays green without edits; only `responsive_layout.spec` is
  updated (5 slots).
- Regenerate `StarterGui/*.model.json` after every builder edit and commit it (Constitution III).
- Deferred (NOT in these tasks): spirit collection/data, Moonmoth, capture announcement + net tool,
  real lantern/net/shovel tools, Spirit Journal screen (spec Out of Scope).
