# Quickstart / Validation Guide: Buy–Sell Economy (Phase 2)

**Feature**: `002-buy-sell-economy` | **Date**: 2026-10-29

Runnable checks that prove the feature end-to-end. Offline checks run from the repo; the V-checks are
Studio playtests (constitution VI) at a **phone landscape** resolution in the device emulator, then
PC and gamepad emulation. References: [spec.md](./spec.md), [balance.md](./balance.md),
[data-model.md](./data-model.md), [contracts/](./contracts/).

## Prerequisites

- `rojo` and `luau` available (as in Phase 1); `rojo serve default.project.json` syncing to Studio.
- After any builder edit, regenerate models:
  ```bash
  python3 Tools/StaticGui/build_models.py "$(command -v luau)"
  ```
- Studio Output open; DataStore API access may be off (mock profile) — must not corrupt live data.

## Offline checks

- **O1 — Config parity (SC-003)**: a check (extend `Tools/Tests/`) asserts every number in
  `balance.md` equals the value in `PlantData`/`ShopConfig`, only crops have `sellValue > 0`, and no
  value is duplicated across modules.
- **O2 — Definition integrity**: every `seedId`/`cropId` resolves to a defined itemId; every item's
  `rarity` is one of the five tiers; every `dayNight ∈ {day,night,any}`.
- **O3 — Model regeneration**: `build_models.py` runs clean and `StarterGui/*.model.json` (incl.
  new `SellUI`, `Notifications`) regenerate with no diff beyond intended changes.

## Studio playtest checks

- **V0 — Boot clean**: join; Output shows no new errors/warnings from project scripts (SC-008).
  Existing pre-Phase-2 warnings (e.g. `Data not loaded` race, missing asset) are not regressions.
- **V1 — Sell loop on phone (US1, SC-001/002)**: harvest a crop, approach the stall, trigger the
  on-screen "Sell" control, sell one item (balance rises by its value), then "Sell all" (all
  non-favourite crops sold; coins = Σ values). Favourite a crop (star), "Sell all" again → it stays.
  Sell the favourited crop individually → confirm dialog → it sells. Leave range with the window open
  → window closes / sell blocked.
- **V2 — Balanced numbers incl. night plants (US2, SC-003)**: shop prices and sell values match
  `balance.md`. Plant a night seed (e.g. Moonflower/Dreamroot); confirm growth **advances at night and
  pauses during the day**, ripens, and sells for its stated value. A day plant grows regardless of
  phase.
- **V3 — Shop card grid (US3, SC-004)**: open the shop on a phone; Seeds, Tools and Items each show
  cards with price and rarity colour; the grid scrolls; buy ×5 of an affordable item (server charges
  5× price, inventory +5); an unaffordable item's card is dimmed and cannot buy.
- **V4 — Toasts (US4, SC-005)**: a purchase shows a success toast; an unaffordable purchase shows an
  error toast; a crop becoming ready shows a toast; fire several within 2s → they stack without
  overlapping, each readable, each auto-clears, none covers the menu column/hotbar, all inside the
  safe area.
- **V5 — Hotbar from inventory (US5, SC-006)**: buy a new seed type → it appears in the first free
  hotbar slot, is selectable and plantable without reload. Buy with the hotbar full → seed stays in
  inventory, swappable.
- **V6 — Teleport (US6)**: tap each teleport button → character moves to shop / garden / stall. On
  PC and gamepad the same buttons are reachable (keyboard focus / gamepad selection); buttons are
  ≥ 44×44 and don't overlap the menu column, hotbar or Roblox jump/thumbstick zones.
- **V7 — Reward feedback (US7)**: on harvest, a "+N coins" label floats above the plot and fades and
  the HUD coin counter animates up; on sell, the counter animates and a success toast shows.
- **V8 — Icons (US8)**: shop/inventory/hotbar show item icons where defined; items without an icon
  show the consistent fallback (first letter/emoji), never a broken image.
- **V9 — Input-agnostic + sizes (SC-007)**: at the Phase 1 reference screens every new element (stall
  control, sell window, shop cards, toasts, teleport row) is inside the safe area, ≥ 44×44 where
  tappable, body text ≥ 18, titles/buttons ≥ 20.
- **V10 — Server authority (FR-005/019)**: via the command bar, attempt a client-forged sell of a
  non-crop, a `SellAll` that "includes" a favourite, an overspend buy, and an unknown teleport target
  → each is rejected server-side and logged; no client-trusted price/total is honoured.

## Parity gate (constitution III/VI)

Repo and Studio match at merge: scripts synced, `StarterGui/*.model.json` regenerated and committed,
clean playtest recorded in the PR.
