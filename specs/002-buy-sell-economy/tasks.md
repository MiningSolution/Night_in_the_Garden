---
description: "Task list for feature 002-buy-sell-economy"
---

# Tasks: Buy–Sell Economy Loop and Shop Content (UI Plan, Phase 2)

**Input**: Design documents from `specs/002-buy-sell-economy/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [balance.md](./balance.md), [contracts/](./contracts/),
[quickstart.md](./quickstart.md)

**Tests**: TDD unit tests were NOT requested in the spec, so no test-first tasks are generated.
One offline parity/integrity check (`Tools/Tests/economy_config.spec.luau`) and the Studio
playtests V0–V10 are included because they are the plan's quality gate (constitution VI, SC-003/008).

**Organization**: grouped by user story (priority order P1 → P2 → P3). Each story is independently
testable in Studio. Paths are repository-relative, following the Rojo layout in plan.md.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1–US8 from spec.md; Setup/Foundational/Polish carry no story label
- Every builder change is followed by regenerating `StarterGui/*.model.json`
  (`python3 Tools/StaticGui/build_models.py <luau>`) and committing the result (FR-016)
- **Standing rule**: playtest in Studio before every commit (no commit of untested code)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirm tooling and lock the economy numbers before any config is written.

- [x] T001 Verify `.specify/feature.json` points at `specs/002-buy-sell-economy` and that `rojo`/`luau` run (reuse Phase 1 setup; no new dependencies)
- [x] T002 Finalize the proposed numbers in `specs/002-buy-sell-economy/balance.md` (seeds/crops buy/sell/grow/phase/rarity, tools, items, Dreamroot) — this is the written source transcribed into config next (FR-006)

**Checkpoint**: numbers agreed; config work can begin.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: the config, schema and phase enablers that **every** user story reads.

**⚠️ CRITICAL**: no user-story work begins until this phase is complete.

- [x] T003 Restore/extend `ReplicatedStorage/PlantData.lua`: one definition per item (carrot, wheat, tomato, pumpkin, moonflower, starberry, **dreamroot** + their crops; watering cans; fertilizer, dream_dust) with fields `displayName, category ("seed"|"tool"|"item"|"crop"), rarity (Common|Uncommon|Rare|Epic|Legendary), buyPrice, sellValue, growthTimeSec, dayNight ("day"|"night"|"any"), icon, seedId/cropId`, values from `balance.md` (data-model.md > ItemDefinition)
- [x] T004 Extend `ReplicatedStorage/ShopConfig.lua`: derive `buy.seeds`/`buy.tools`/`buy.items` and the crop `sell` table from `PlantData`; keep `GetBuyPrice`/`GetSellPrice`/`CanSell`; add `GetRarity`, `IsNightPlant`, `GetCategoryItems(category)` (no number duplicated — II)
- [x] T005 [P] Add five rarity colour tokens to `ReplicatedStorage/UITheme.lua` (`RarityCommon/Uncommon/Rare/Epic/Legendary`, dark palette only — R10/FR-018)
- [x] T006 [P] `ReplicatedStorage/DefaultData.lua`: `SchemaVersion = 2`; add `Favourites = {}`, `Plots[*].GrowthSeconds = 0`, and inventory keys (default 0) for the new seeds/crops (moonflower, starberry, dreamroot) and items (fertilizer, dream_dust)
- [x] T007 `ServerScriptService/Services/PlayerDataManager.lua`: reconcile loaded profiles against `DefaultData` so old saves gain `Favourites`/`GrowthSeconds`/new keys without dropping fields (II; backward-compatible)
- [x] T008 `ServerScriptService/Services/DayNightManager.lua`: promote `phase` to module state and expose `DayNightManager.GetPhase()` → `"Day"|"Night"`

**Checkpoint**: config + schema + phase query ready — user stories can proceed.

---

## Phase 3: User Story 2 - Real, balanced economy numbers (Priority: P1)

**Goal**: buying/growing/selling use the single balanced config, including night plants that grow
only at night, matching the balance document.

**Independent Test**: review `balance.md`, then in a playtest confirm shop prices, growth times and
sell values match it, including a night plant and Dreamroot.

- [x] T009 [US2] `ServerScriptService/Services/PlantGrowthService.lua`: replace wall-clock progress with the per-plot accumulator — each tick add `dt` to `plot.GrowthSeconds` **only when** the plant's `dayNight` allows `DayNightManager.GetPhase()` (`any`/`day` always; `night` only at Night); `GrowthProgress = clamp(GrowthSeconds / growthTimeSec, 0, 1)`; `>= 1` → `ReadyToHarvest` (FR-007, R3)
- [x] T010 [P] [US2] Offline check `Tools/Tests/economy_config.spec.luau`: assert config equals `balance.md` (O1), only `category=="crop"` has `sellValue > 0`, no value duplicated across modules, every `seedId`/`cropId` resolves, every `rarity` is one of the five tiers, every `dayNight ∈ {day,night,any}` (O2); run with `luau`
- [x] T011 [US2] Studio playtest V2: shop and sell numbers match `balance.md`; plant a night seed (Moonflower/Dreamroot) → growth advances at night, pauses by day, ripens, sells for stated value; a day plant grows regardless of phase; Output clean

**Checkpoint**: the economy numbers are correct and single-sourced.

---

## Phase 4: User Story 1 - Sell harvested crops for coins (Priority: P1) 🎯 MVP

**Goal**: sell crops at the stall — one at a time or "Sell all" — with favourites protected; closes
the buy→plant→grow→sell→buy loop.

**Independent Test**: on a phone, harvest a crop, open the stall's on-screen "Sell" control, sell one
item then "Sell all", confirm the balance rises by the shown total and favourited items remain.

**Depends on**: Foundational + US2 (crop categories and sell values must exist in config).

- [x] T012 [US1] `ServerScriptService/Services/PlayerDataManager.lua`: add favourite helpers (`IsFavourite`/`ToggleFavourite`/`GetFavourites`) and a `SellAllCrops(player)` helper that iterates crop stacks, skips favourites, sums `sellValue × count`, consumes and credits coins atomically, returns counts/total (contracts/remotes.md)
- [x] T013 [US1] `ServerScriptService/CreateRemotes.lua`: create `SellAll` and `ToggleFavourite` RemoteFunctions
- [x] T014 [US1] `ServerScriptService/RemoteHandlers.lua`: bind `SellAll` and `ToggleFavourite` (rate limit, type/ownership checks, fail closed, anti-cheat log) and **harden `SellItem` to `category=="crop"` only** (seeds/tools rejected) (FR-001/004/005, contracts/remotes.md)
- [x] T015 [US1] Add the seller **stall model + ProximityPrompt** to the place and mirror it in the repo; trigger range = stall range; `Triggered` opens the sell window; hide/close when the player leaves range (FR-002, edge cases)
- [x] T016 [P] [US1] Builder `Tools/StaticGui/builders/CreateSellUI.luau`: build `SellUI` per contracts/gui-tree.md — window + backdrop + close, `Header` with `TitleLabel`+`TotalLabel`, `ItemsScroll` + hidden `SellRowTemplate` (Icon/FallbackLetter, Name, Count, Value, `StarToggle`, `SellOneButton`), `SellAllButton`, `EmptyState`; theme tokens; ≥44×44; text ≥18/20
- [x] T017 [US1] `StarterPlayer/StarterPlayerScripts/Controllers/SellController.lua` (new): populate rows from the inventory snapshot + `Favourites`; show per-item value and the running total; `StarToggle → ToggleFavourite`; `SellOneButton → SellItem` (if favourited, confirm first); `SellAllButton → SellAll`; register with `WindowManager`; close on out-of-range; gamepad selection group
- [x] T018 [US1] Regenerate `StarterGui/*.model.json` (`build_models.py`) and commit the new `SellUI.model.json`
- [x] T019 [US1] Studio playtest V1 + V10 (authority): phone sell loop, Sell all skips favourites, individual favourite sale after confirm, out-of-range blocked; forged non-crop sell / overspend rejected server-side; Output clean

**Checkpoint (MVP)**: Foundational + US2 + US1 = the closed economy loop with real numbers.

---

## Phase 5: User Story 3 - Browse and buy from a full shop (Priority: P2)

**Goal**: shop as a scrolling card grid with rarity, ×1/×5/×10 and dimmed-unaffordable, across
Seeds/Tools/Items.

**Independent Test**: open the shop on a phone, switch categories, see cards with price + rarity
colour, buy ×5 of an affordable item, and confirm an unaffordable card is dimmed and unbuyable.

- [ ] T020 [P] [US3] Builder `Tools/StaticGui/builders/CreateShopUI.luau`: replace the detail pane with `CardsScroll` (`ScrollingFrame` + `UIGridLayout`) and a hidden `CardTemplate` (Icon/FallbackLetter, Name, Price, `RarityStrip`, `QtyX1`/`QtyX5`/`QtyX10` selection group, `BuyButton`); keep the Seeds/Tools/Items tabs (contracts/gui-tree.md)
- [ ] T021 [US3] `StarterPlayer/StarterPlayerScripts/Controllers/ShopController.lua`: clone `CardTemplate` per `GetShopData` item; set rarity colour from `UITheme`; wire ×1/×5/×10; dim + disable buy when `price × qty > coins`; rebind on quantity/coin change; populate Tools and Items (FR-008/009/010)
- [ ] T022 [US3] Regenerate models and commit `ShopUI.model.json`
- [ ] T023 [US3] Studio playtest V3

**Checkpoint**: full browsable/buyable shop.

---

## Phase 6: User Story 4 - Clear feedback through toasts (Priority: P2)

**Goal**: queued on-screen toasts for purchase/error/crop-ready/spirit-caught.

**Independent Test**: buy → success toast; unaffordable → error toast; crop ready → toast; several in
2s stack without overlapping; each readable on a phone and auto-clears.

- [ ] T024 [P] [US4] Builder `Tools/StaticGui/builders/CreateNotifications.luau`: `Notifications` ScreenGui (high `DisplayOrder`, `ScreenInsets = CoreUISafeInsets`, `ResetOnSpawn=false`), `ToastContainer` (+`UIListLayout`), hidden `ToastTemplate` (Bar/Background by type, Icon, MessageLabel) (contracts/gui-tree.md)
- [ ] T025 [US4] `StarterPlayer/StarterPlayerScripts/Utils/ToastQueue.lua` (new): pooled FIFO queue — clone `ToastTemplate`, colour by type (`UITheme`/`Constants.COLORS`), auto-expire after `Constants.UI.NOTIFICATION_DURATION`, no overlap, stay in safe area / above windows / clear of menu column + hotbar (FR-011)
- [ ] T026 [US4] `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua`: re-point `ShowNotification` to `ToastQueue`; raise toasts on buy/sell results, `PlotStateChanged → ReadyToHarvest`, and `SpiritCollected`
- [ ] T027 [US4] Regenerate models and commit `Notifications.model.json`
- [ ] T028 [US4] Studio playtest V4

**Checkpoint**: player-visible feedback.

---

## Phase 7: User Story 5 - Bought seeds usable from the hotbar (Priority: P2)

**Goal**: hotbar built from inventory; a bought seed takes the first free slot.

**Independent Test**: buy a new seed type → it appears in a free slot and can be selected and planted.

- [ ] T029 [US5] `StarterPlayer/StarterPlayerScripts/Controllers/HotbarController.lua`: derive slot contents from the inventory snapshot (owned tools then owned seeds, stable order) on `UpdateInventory`/`GetPlayerData`; a newly bought seed fills the first free slot; overflow via the existing Prev/Next paging; hotbar full → seed stays in inventory (FR-012, R7, edge case)
- [ ] T030 [US5] Studio playtest V5

**Checkpoint**: bought seeds are plantable from the hotbar.

---

## Phase 8: User Story 6 - Quick travel between key places (Priority: P3)

**Goal**: teleport row (shop/garden/stall) performed server-side.

**Independent Test**: tap each teleport button → character moves to shop/garden/stall; buttons
≥44×44 and reachable on PC/gamepad.

- [ ] T031 [P] [US6] Add teleport **anchor parts** (shop/garden/stall) to the place and mirror in the repo
- [ ] T032 [US6] `ServerScriptService/CreateRemotes.lua` + `RemoteHandlers.lua`: add `RequestTeleport` RemoteFunction; validate `targetId ∈ {shop,garden,stall}`, rate-limit, move `HumanoidRootPart` to the anchor, fail closed (FR-013/019, contracts/remotes.md)
- [ ] T033 [P] [US6] Builder `Tools/StaticGui/builders/CreateHUDControls.luau`: add `TeleportRow` with `TeleportShop`/`TeleportGarden`/`TeleportStall` (≥44×44, selection group)
- [ ] T034 [US6] `StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua`: position `TeleportRow` via `ResponsiveLayout` (no overlap with menu column/hotbar/Roblox controls); bind each button through `InputActions` → `RequestTeleport`
- [ ] T035 [US6] Regenerate models and commit `HUDControls.model.json`
- [ ] T036 [US6] Studio playtest V6 (phone/PC/gamepad)

**Checkpoint**: fast travel works.

---

## Phase 9: User Story 7 - Visible reward feedback (Priority: P3)

**Goal**: floating "+N coins" on sell/harvest and an animated coin counter.

**Independent Test**: sell or harvest → "+N coins" rises and fades while the coin total animates.

- [ ] T037 [US7] Floating "+N coins": reuse the world-label pattern in `StarterPlayer/StarterPlayerScripts/Utils/PlotVisualizer.lua` above the harvested plot (and above the character on a sale), and reuse the `UIController.UpdateCurrency` tween for the counter (FR-014, R9)
- [ ] T038 [US7] Studio playtest V7

**Checkpoint**: gains are felt.

---

## Phase 10: User Story 8 - Item icons instead of placeholders (Priority: P3)

**Goal**: real icons in shop/inventory/hotbar with a consistent fallback.

**Independent Test**: open shop/inventory/hotbar → icons show; missing-icon items show the fallback.

- [ ] T039 [P] [US8] Fill `icon` fields in `ReplicatedStorage/PlantData.lua` for items whose assets are available (missing ones stay `""`)
- [ ] T040 [US8] Generalise icon rendering + fallback (first letter/emoji) across `ShopController` cards, `InventoryController`, and `HotbarController` so no broken image ever shows (FR-015, R11)
- [ ] T041 [US8] Studio playtest V8

**Checkpoint**: visual polish complete.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [ ] T042 [P] Update `README.md` with the economy loop, selling, teleport and toast controls
- [ ] T043 Repo/Studio parity: regenerate all models clean (O3) and confirm no stray diff
- [ ] T044 Full quickstart V0–V10 on phone, PC and gamepad emulation; record the clean playtest for the PR (SC-007/008)

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: first; T002 (balance numbers) precedes all config.
- **Foundational (Phase 2)**: after Setup; **blocks every user story** (config, schema, phase query).
- **US2 (Phase 3)**: after Foundational.
- **US1 (Phase 4)**: after Foundational **and US2** (needs crop categories + sell values).
- **US3, US4, US5 (Phases 5–7)**: after Foundational; independent of each other and of US1.
- **US6, US7 (Phases 8–9)**: after Foundational; independent.
- **US8 (Phase 10)**: after Foundational; its T040 edits `ShopController`/`HotbarController`/
  `InventoryController`, so run it **after US3 and US5** to avoid editing those files twice.
- **Polish (Phase 11)**: after all desired stories.

### Shared-file cautions (do NOT mark [P] across these)

- `UIController.lua`: US4 (T026), US6 (T034), US7 (T037) — sequence, don't parallelize.
- `ShopController.lua`: US3 (T021) then US8 (T040). `HotbarController.lua`: US5 (T029) then US8 (T040).
- `CreateRemotes.lua`/`RemoteHandlers.lua`: US1 (T013/T014) then US6 (T032) — sequence.
- Each regenerate-models task touches `StarterGui/*` — keep within its own story's PR.

### Parallel opportunities

- Foundational: T005 (UITheme) and T006 (DefaultData) in parallel; T003→T004 sequential (ShopConfig derives from PlantData).
- US2: T010 (offline test) parallel with T009 (growth service).
- US1: T016 (SellUI builder) parallel with T012/T013/T014 (server) before T017 wires them.
- Builders for different ScreenGuis (T020 Shop, T024 Notifications, T033 HUDControls) are independent files and may be written in parallel, but each story's controller + regenerate stay in that story.

---

## Implementation Strategy

### MVP (deliver first)

1. Phase 1 Setup → 2. Phase 2 Foundational → 3. Phase 3 **US2** → 4. Phase 4 **US1** →
   **STOP & VALIDATE**: the full buy→plant→grow→sell→buy loop works on a phone with correct numbers.
   Land as the **P1 PR** to `main`.

### Incremental delivery (prioritized PRs — constitution VII)

- **P1 PR**: Foundational + US2 + US1 (above).
- **P2 PR**: US3 (cards) + US4 (toasts) + US5 (hotbar), each validated independently.
- **P3 PR**: US6 (teleport) + US7 (feedback) + US8 (icons) + Polish.

Each story stops at its checkpoint for an independent Studio playtest; commit only after the
playtest passes (standing rule), regenerate and commit models with each builder change.
