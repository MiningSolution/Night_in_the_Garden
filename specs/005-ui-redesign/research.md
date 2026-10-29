# Phase 0 Research: Cosy-Garden UI Redesign (Stage 1)

All decisions reuse existing systems (Constitution I/II/III). Each entry: Decision → Rationale →
Alternatives. The reuse map (confirmed by reading the code) is summarised under "Reuse map" at the end.

## R1 — Top-centre SEEDS / GARDEN / SELL navigation

**Decision**: Build a new top-centre nav bar in `CreateHUDControls.luau` with three buttons SEEDS /
GARDEN / SELL. Wire in `UIController`: SEEDS → `WindowManager.Toggle("Shop")` (preselect Seeds, R5);
GARDEN → `RequestTeleport:InvokeServer("garden")`; SELL → `RequestTeleport:InvokeServer("stall")` then,
on success, `WindowManager.Open("Sell")`. The existing `TeleportRow` (TeleportShop/Garden/Stall,
top-right) is removed/repurposed — its shop/garden/stall `RequestTeleport` calls move into the new nav.

**Rationale**: The concept leads with a single top-centre primary nav; today the nav is split between a
left `MenuButtons` column and a top-right `TeleportRow`. Consolidating keeps one clear action set and
reuses the same remotes (`RequestTeleport` targets `shop/garden/stall` already exist).

**Alternatives**: Keep TeleportRow and only restyle — rejected, does not match the concept's single
primary nav. Make SELL open the Sell window without teleporting — rejected per clarify (SELL teleports
to the stall first so it works from anywhere, and the stall's 14-stud range watch stays satisfied).

## R2 — Left BAG / QUESTS / GIFTS column

**Decision**: Keep the left `MenuButtons` column but reduce it to three buttons relabelled BAG /
QUESTS / GIFTS (drop the Shop button, now in the top nav). BAG → Toggle("Inventory"); QUESTS → open
the Quests window; GIFTS → open the Daily-Reward window. **Wire QUESTS and GIFTS `.Activated` in
`UIController`** (today only Shop + Inventory are touch-wired; Rewards/Quests are keyboard-only — a
confirmed gap). Keep the existing `R`/`Q` key labels and gamepad glyphs via `InputActions`.

**Rationale**: Reuses the existing window toggles and the already-built buttons/key bindings; only the
missing touch wiring and the labels change. "Gifts" is the concept's label for the daily reward.

**Alternatives**: New buttons from scratch — rejected (buttons, key binds and hints already exist).

## R3 — Top-right phase + timer pill

**Decision**: Restyle the existing `HUD.DayNightIndicator` (PhaseLabel + ProgressBar) into the concept's
pill and **migrate its hard-coded RGB to theme tokens** (currently un-themed — a V gap). Phase text and
the fill bar are driven by the existing `UpdateDayNight(phase, progress)` on the `DayNightUpdate`
event. For the numeric "time remaining": the event payload is `(phase, progress 0–1)` with **no
deadline**, so derive `remaining = (1 − progress) × phaseDuration`, where `phaseDuration` is read from a
single-source day/night duration constant in config (II). Refresh the number on each `DayNightUpdate`
tick; **do not start an independent per-frame client clock** (FR-004). Confirm in Studio that the event
cadence makes the number useful; if ticks are too coarse, fall back to phase + progress bar only (still
matches the concept's pill shape) and treat the live countdown as a follow-up.

**Rationale**: Reuses the only phase channel the game has; keeps the client non-authoritative; avoids a
second day/night loop. Reading the duration from config keeps II.

**Alternatives**: Add an `endTime` field to `DayNightUpdate` (server change) — deferred; only adopt if
Studio shows the progress-derived number drifts. Client-side `os.clock` countdown — rejected (FR-004).

## R4 — One current-quest card on the HUD

**Decision**: Add a single `QuestCard` frame to `CreateHUD.luau` (background ScreenGui), themed, showing
one current goal + its progress, fed by the existing quest data the `QuestController` already holds
(subscribe to the same quest state; show the first incomplete quest). It is display-only; tapping it
opens the full Quests window (reuse the QUESTS action).

**Rationale**: The concept shows one goal on the HUD, not the whole list; the quest data already exists
client-side. Keeps it a presentation layer over existing state.

**Alternatives**: Full quest list on the HUD — rejected (concept shows one; clutters the free centre).

## R5 — Shop: preselect Seeds, image cards, rarity badge, disabled reasons, paint clones

**Decision**: Reuse `CardTemplate` + `ShopController.makeCard` cloning. Changes: (a) add an optional
preselect so opening from SEEDS shows the Seeds tab — extend `WindowManager.Open`/`Toggle` to accept an
optional opaque `openArg` passed to `onOpen`, OR add `ShopController.OpenOnTab("seeds")` the nav calls
before Toggle; choose the smaller diff (a dedicated controller entry point, no WindowManager signature
change, is preferred). (b) Enlarge the card to a "big image card" in the builder (Icon dominant, name,
rarity badge, price, stock). (c) Replace the plain `RarityStrip` with a **rarity badge** that shows the
tier **text** (COMMON/…/LEGENDARY) + the rarity colour from `UITheme.Rarity*` tokens (FR-025). (d) Keep
the three distinct disabled reasons `applyAfford` already produces (Out of stock / Can't afford /
BUY n). (e) **Call `ThemeController.PaintInstant` on each cloned card** (or `Paint` on the card root) so
fresh cards match the active palette — the confirmed paint gap. Tabs: keep seedsTab/toolsTab/itemsTab;
relabel the third "Special" (the concept's Seeds/Tools/Special) while the underlying category id stays.

**Rationale**: The template and buy/stock/afford logic already exist and are server-validated; the work
is visual + the paint fix + a preselect entry point. Rarity text+colour satisfies "never colour alone".

**Alternatives**: New shop window — rejected (III, reuse). Change `BuyItem`/`GetShopData` — not needed.

## R6 — Backpack: biggest reskin (new template + tabs + detail panel + Equip)

**Decision**: This is the heaviest item — today the inventory builder has only SeedsTab/ItemsTab, **no
card template, no detail panel (only a hover tooltip), Equip is a TODO, and the controller is entirely
un-themed (hard-coded RGB)**. Work:
- Builder (`CreateInventoryUI.luau`): add the five tabs All / Seeds / Tools / Crops / Spirits; add a
  themed **`CardTemplate`** (icon, name, rarity badge, quantity, favourite mark) cloned per item; add a
  **detail panel** (selected item, description, favourite toggle, one context-action button) replacing
  the hover-only tooltip as the primary action surface (the tooltip may remain for hover).
- Controller (`InventoryController.lua`): clone `CardTemplate` instead of building slots in code;
  **paint each clone** via `ThemeController.PaintInstant`; filter by the five categories (All = all;
  Spirits = empty "coming soon" placeholder this stage, FR-017); drive the detail panel on selection;
  set the context action by category — Equip (Seeds/Tools), Go to sell (Crops), View journal (Spirits,
  disabled/placeholder this stage).
- **Equip wiring** (replaces the TODO print): on Equip, equip the selected seed/tool via the existing
  path — `HotbarController` owns the hotbar + sends `EquipTool:FireServer(serverTool)`. The Backpack
  calls a `HotbarController` entry point (e.g. `EquipByItemName(name)` / select the matching slot) so
  the equipped tool shows as selected on the HUD strip. No new remote.

**Rationale**: The concept's Backpack is a grid + detail panel with a working Equip; the current screen
is far from it and un-themed, so this story is genuinely the largest. Still reuse: data from
`StateManager`, metadata from `PlantData`, equip via `EquipTool`/`HotbarController`.

**Alternatives**: Keep code-built slots and only recolour — rejected (no template breaks III's
"clone from static template", and no detail panel/Equip fails FR-018/019). New equip remote — rejected
(`EquipTool` exists).

## R7 — Icons: fill single-source fields with free/CC0 images

**Decision**: Fill `PlantData.seedIcon` / `PlantData.cropIcon` (per plant) and `ShopConfig` tool/item
`icon` fields (seeds/sell derive from PlantData automatically). Source consistent free/commercial-OK
images via the Studio catalog (`search_asset`/`insert_asset`, prefer free Decals/Images; licence must
be commercial-OK — Kenney CC0 or equivalent). Record each asset id + source in a small
`contracts/icons.md` manifest for licence audit (FR-021). The letter/emoji fallback stays in all four
renderers for any still-empty field (FR-020).

**Rationale**: The plumbing (single-source fields + four fallbacks) already exists; filling fields is
low-risk and the owner chose "find free packs". Keeping a manifest satisfies the licence-audit
requirement.

**Alternatives**: `generate_texture` / ViewportFrame of 3D models — kept as a fallback for items with no
good catalog match; heavier, used selectively. Emoji as final art — rejected by the concept.

## R8 — Hotbar 3 → 5 slots (slots 3–5 locked placeholders)

**Decision**: Expand the tool strip to five slots, with slots 3–5 rendered locked/"coming soon" and
inert (FR-006, clarify). Touch every place that hard-codes 3 (confirmed list): `CreateHUDControls`
slot loop + `defaultEmojis` + hotbar default width; `ResponsiveLayout.HOTBAR_SLOTS` (+ desktop W/H
re-tuned for 5); `UIController.applyLayout` slot loop; `HotbarController.VISIBLE_SLOTS` + number-key
binds (add 4/5) — but only the real tools (watering can, seeds) are functional; slots 3–5 show a lock
and never equip. Update `responsive_layout.spec.luau` hotbar expectations to the new geometry.

**Rationale**: The concept's strip is five slots; the real tool set is smaller, so extra slots are
visual placeholders (approved in clarify). Centralising the slot count where possible reduces the
hard-coded 3s.

**Alternatives**: Keep 3 slots — rejected by clarify. Build real lantern/net/shovel tools now —
rejected (Out of Scope; needs new server tools).

## R9 — Paint-on-clone pattern (close the theme gap)

**Decision**: Standardise: after cloning any list/grid/card template and parenting it, call
`ThemeController.PaintInstant(clone)` (single instance) or `ThemeController.Paint(cardRoot)` (subtree)
so every `Theme_<Prop>`-tagged descendant takes the active palette, and the clone is then repainted on
future `DayNightUpdate`s like the static tree. Apply in ShopController (cards) and InventoryController
(cards) and the quest card if cloned.

**Rationale**: Confirmed gap — fresh clones keep the baked Night palette and are not repainted on a Day
phase. `ThemeController` already exposes `Paint`/`PaintInstant` for exactly this.

**Alternatives**: Manually set colours per clone from `UITheme.Resolve(token, phase)` — rejected
(duplicates ThemeController, misses the next phase switch).

## R10 — Keep offline tests + static-GUI parity green

**Decision**: After every builder edit, re-run `python3 Tools/StaticGui/build_models.py "$(command -v
luau)"` to regenerate `StarterGui/*.model.json` and refresh fingerprints; keep `theme.spec`
(parity/contrast/rarity-distance) green by only using existing tokens (no palette value changes needed
this feature); update `responsive_layout.spec` for the 5-slot hotbar; `economy_config.spec` is
unaffected (icons are strings, not balance numbers). Commit the regenerated models (III).

**Rationale**: These are the project's only automated gates; the feature is a reskin, so palettes stay
and only geometry/structure fingerprints change.

**Alternatives**: Skip regeneration — rejected (III parity).

## Reuse map (confirmed from code)

| Need | File | Symbol / remote | Note |
|------|------|-----------------|------|
| Currency labels | `CreateHUD.luau` | `CurrencyDisplay.CoinsLabel`/`DreamSeedsLabel` | themed (Coins/Dream); `UIController.UpdateCurrency(coins, dreamSeeds, animate)` |
| Phase pill | `CreateHUD.luau` | `DayNightIndicator.PhaseLabel`/`ProgressBarContainer.ProgressBar` | un-themed RGB → migrate; `UpdateDayNight(phase, progress)` on `DayNightUpdate(phase, progress)` |
| Nav remotes | `RemoteHandlers.lua` | `RequestTeleport` (RF) targets `shop/garden/stall` | SELL = teleport `stall` then `WindowManager.Open("Sell")` |
| Window open | `WindowManager.lua` | `Open/Toggle(name)` (no tab arg) | add a controller-side preselect entry point, not a signature change |
| Menu wiring | `UIController.lua` | ShopButton/InventoryButton wired; **Rewards/Quests NOT touch-wired** | wire QUESTS + GIFTS `.Activated` |
| Shop cards | `CreateShopUI.luau` / `ShopController.lua` | `CardTemplate` (Icon/FallbackLetter/NameLabel/PriceLabel/RarityStrip/QtyRow{QtyX1/5/10}/BuyButton/StockLabel); `GetShopData`/`BuyItem` (RF); `applyAfford` reasons | **no Paint on clones** → fix |
| Inventory | `CreateInventoryUI.luau` / `InventoryController.lua` | only SeedsTab/ItemsTab, no template, no detail panel, Equip = TODO, un-themed | biggest reskin |
| Equip | `HotbarController.lua` | `EquipTool` (RE) via `equipCurrent()`; `VISIBLE_SLOTS=3` | add entry point for Backpack Equip; 3→5 slots |
| Icons | `PlantData.lua` / `ShopConfig.lua` | `seedIcon`/`cropIcon` (plants), `icon` (tools/items); `rarity`/`rarityById`/`GetRarity` | all icon fields `""`; 4 letter-fallback sites |
| Theme | `UITheme.lua` / `ThemeController.lua` | tokens incl. Rarity*/Coins/Dream/HeaderTop/HeaderBottom; `Style`; `Paint(root)`/`PaintInstant(inst)` | all needed tokens exist |
| Tests | `Tools/Tests/*.spec.luau` + `Tools/StaticGui/build_models.py` | theme/economy/responsive/retention specs + fingerprint parity | update responsive spec for 5 slots |
