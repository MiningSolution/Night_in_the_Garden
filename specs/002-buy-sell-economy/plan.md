# Implementation Plan: Buy–Sell Economy Loop and Shop Content (UI Plan, Phase 2)

**Branch**: `002-buy-sell-economy` | **Date**: 2026-10-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-buy-sell-economy/spec.md`

## Summary

Close the economy loop (buy → plant → grow → **sell** → buy more) and fill out the shop. A seller's
stall with a ProximityPrompt opens a new `SellUI` with per-item sell values, a running total,
"Sell all", and a server-owned **favourites** set (star toggle) that "Sell all" never touches but an
individual sale can, after a confirm. The full economy numbers — prices, growth times, sell values,
rarity, the night plants and **Dreamroot** — are written in [balance.md](./balance.md) first, then
restored into the single config (`PlantData`, `ShopConfig`); night plants grow only during the night
phase via a per-plot growth accumulator gated by `DayNightManager.GetPhase()`. The shop becomes a
scrolling **card grid** (rarity colour, ×1/×5/×10, dimmed-when-unaffordable) across Seeds/Tools/Items.
A separate always-on-top `Notifications` ScreenGui gives queued **toasts** (purchase, error,
crop-ready, spirit-caught) through `UIController.ShowNotification`. The hotbar is built from the
player's **inventory** (a bought seed takes the first free slot). A **teleport row** (shop/garden/
stall) joins the HUD control GUI, performed server-side. Selling and harvesting show a floating
"+N coins" and animate the coin counter. Placeholder emojis give way to **real icons** with a
fallback. All economy actions stay server-validated (I), all numbers live once in config (II), all
GUI goes through the builders and regenerated models (III), everything is mobile-first and
input-agnostic (IV), colours come from theme tokens incl. new rarity tokens (V), and every flow is
verified in Studio (VI). Day/night palette switching remains Phase 4.

## Technical Context

**Language/Version**: Luau (Roblox client + server); Python 3 for the GUI generator driver

**Primary Dependencies**: Roblox services — ProximityPromptService, ContextActionService,
UserInputService, GuiService, TweenService, StarterGui; Rojo 7.x; vendored ProfileService; existing
services (`PlayerDataManager`, `InventoryService`, `PlotManager`, `PlantGrowthService`,
`DayNightManager`) and client modules (`StateManager`, `ClientDataCache`, controllers, `InputActions`,
`WindowManager`, `ResponsiveLayout`, `PlotVisualizer`) from Phase 1

**Storage**: ProfileService profiles. `DefaultData` SchemaVersion → 2: adds `Favourites`, per-plot
`GrowthSeconds`, inventory entries for new items; reconciled on load, never dropped (II)

**Testing**: offline config-parity + definition-integrity checks in `Tools/Tests/` (extends the
Phase 1 Luau test); `build_models.py` regeneration parity; Studio playtests V0–V10 on phone, PC and
gamepad emulation (see [quickstart.md](./quickstart.md))

**Target Platform**: Roblox — phones/tablets (landscape), PC; console via gamepad emulation (console
publishing out of scope)

**Project Type**: Roblox game, Rojo-synced repository (client + server + static GUI)

**Performance Goals**: no per-frame work for hidden UI; toasts and shop cards are cloned from static
templates and pooled; growth stays on the existing 1 Hz loop; UI updated incrementally, not rebuilt

**Constraints**: text ≥ 18 body / ≥ 20 titles & buttons; tap targets ≥ 44×44; inside
`CoreUISafeInsets`; shared action layer for touch/keyboard/gamepad; no Escape; server fails closed on
invalid economy input; StreamingEnabled on (wait for streamed parts, e.g. stall/anchors)

**Scale/Scope**: 2 config modules restored/extended; 1 theme module extended (5 rarity tokens);
~4 new/changed remotes (`SellAll`, `ToggleFavourite`, `RequestTeleport`; `SellItem` hardened);
~3 server services touched (`PlantGrowthService`, `DayNightManager`, `PlayerDataManager`/handlers);
2 new ScreenGuis (`SellUI`, `Notifications`) + 2 changed (`ShopUI`, `HUDControls`); ~5 builders;
~5 controllers touched + 1 new (`SellController`) + 1 client util (`ToastQueue`); world anchors +
stall/seller model; 8 user stories across P1–P3

All unknowns are resolved in [research.md](./research.md) R1–R13. Two items carry a Studio
verification step instead of an open question: night-growth accrual across a full day→night cycle
(R3, quickstart V2) and teleport-anchor placement (R8, quickstart V6).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Server-authoritative | Buy/sell/sell-all/favourite/teleport all validated server-side; prices, sell values, totals and the protected set are read/decided on the server; client sends only requests. New remotes reuse the hardened `RemoteHandlers` pattern (rate limit, type/ownership checks, fail closed, anti-cheat log). | ✅ |
| II. Single source of truth | All numbers live once in `PlantData`/`ShopConfig`, written first in `balance.md`; `ShopConfig` derives from `PlantData`; controllers/builders read config or the server snapshot, never duplicate numbers. Rarity colours are tokens in `UITheme`. | ✅ |
| III. Rojo / static GUI | New `SellUI`, `Notifications`, the shop card grid, the teleport row and all templates are built by the builders into `StarterGui/*.model.json`; controllers clone templates and attach behaviour only; models regenerated and committed. | ✅ |
| IV. Mobile-first, input-agnostic | Stall control (ProximityPrompt → on-screen button on touch/gamepad, key on PC), sell window, shop cards, toasts and teleport row are touch-first, ≥ 44×44, inside the safe area, bound through `InputActions` with selection groups for gamepad. | ✅ |
| V. Theme tokens | New/changed UI (cards, rarity strips, toasts, sell window, teleport row) reads `UITheme`; five rarity tokens added to the current dark palette. Day palette + switching are Phase 4. | ✅ |
| VI. Verified in Studio | Quickstart V0–V10 on phone/PC/gamepad; offline parity checks; ProfileService tolerates mock DataStore; no new script errors at merge. | ✅ |
| VII. Simplicity, small PR | Scope is large but split by priority into independently testable user stories; delivered as **prioritized PRs** (see below), reuse over new infrastructure (existing coin tween, `PlotVisualizer` label, hotbar paging, handler pattern). No unjustified abstraction. | ✅ |

**Gate result (pre-research)**: pass. **Re-check after Phase 1 design**: pass — the design adds only
what the spec requires (two ScreenGuis, three remotes, a growth accumulator, rarity tokens); each
addition maps to a principle (III GUI, I remotes, FR-007 growth, V tokens) and none violates one.
PR strategy keeps VII: land **P1 first** (US1 selling + US2 balance/config), then **P2**
(US3 cards, US4 toasts, US5 hotbar), then **P3** (US6 teleport, US7 feedback, US8 icons), each a small
reviewed PR to `main` with its own clean playtest. No Complexity Tracking entries.

## Project Structure

### Documentation (this feature)

```text
specs/002-buy-sell-economy/
├── spec.md              # /speckit-specify + /speckit-clarify
├── plan.md              # this file
├── balance.md           # Phase 1 — economy numbers (written first, source for config)
├── research.md          # Phase 0 — R1–R13
├── data-model.md        # Phase 1 — entities
├── quickstart.md        # Phase 1 — validation V0–V10
├── contracts/
│   ├── remotes.md       # server remote contracts (buy/sell/sell-all/favourite/teleport)
│   └── gui-tree.md       # static GUI names/templates the controllers rely on
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
ReplicatedStorage/
├── PlantData.lua                     # RESTORE/EXTEND: full definitions + night plants + Dreamroot
├── ShopConfig.lua                    # RESTORE/EXTEND: buy seeds/tools/items, sell crops, helpers
├── UITheme.lua                       # + five rarity colour tokens (dark palette)
├── DefaultData.lua                   # SchemaVersion→2: Favourites, GrowthSeconds, new inventory keys
└── Constants.lua                     # (reuse NOTIFICATION_*, ANIMATION tweens)
ServerScriptService/
├── CreateRemotes.lua                 # + SellAll, ToggleFavourite, RequestTeleport
├── RemoteHandlers.lua                # bind new remotes; harden SellItem to crops-only
└── Services/
    ├── PlantGrowthService.lua        # phase-gated growth accumulator (FR-007)
    ├── DayNightManager.lua           # + module-level phase + GetPhase()
    └── PlayerDataManager.lua         # reconcile Favourites/GrowthSeconds; favourite + sell-all helpers
StarterGui/
├── ShopUI.model.json                 # regenerated (card grid + template)
├── HUDControls.model.json            # regenerated (teleport row)
├── SellUI.model.json                 # NEW
└── Notifications.model.json          # NEW
StarterPlayer/StarterPlayerScripts/
├── Controllers/
│   ├── ShopController.lua            # card grid population, dim, ×1/×5/×10
│   ├── InventoryController.lua       # star toggle, icons/fallback
│   ├── SellController.lua            # NEW: sell window, rows, total, Sell all, confirm
│   ├── HotbarController.lua          # inventory-driven slots, first-free on buy
│   └── UIController.lua              # ShowNotification→toast queue; teleport row layout; +N coins
└── Utils/
    ├── ToastQueue.lua                # NEW: pooled toast queue (or a UIController section)
    └── PlotVisualizer.lua            # reuse world-label for floating "+N coins"
Tools/
├── StaticGui/builders/
│   ├── CreateShopUI.luau             # card grid + CardTemplate
│   ├── CreateHUDControls.luau        # TeleportRow
│   ├── CreateSellUI.luau             # NEW
│   └── CreateNotifications.luau      # NEW
└── Tests/
    └── economy_config.spec.luau      # NEW: config/balance parity + definition integrity (O1/O2)
world (Studio place + repo mirror):
└── Seller stall model + ProximityPrompt; teleport anchor parts (shop/garden/stall)
```

**Structure Decision**: the existing Rojo layout (constitution III) and the Phase 1 controller
pattern (stateful helpers in `Utils/`, screen logic in `Controllers/`, static GUI in builders). New
client logic is one new controller (`SellController`) and one util (`ToastQueue`); everything else
extends existing files. World objects (stall, anchors) are mirrored in the repo in the same PR (III).

## Implementation notes (input for /speckit-tasks)

Suggested order, each step independently playtestable; grouped into the prioritized PRs above.

1. **Foundation / config (US2, P1)**: write `balance.md` numbers; restore/extend `PlantData` +
   `ShopConfig` (categories, rarity, sell values, night plants, Dreamroot, icons, helpers); add rarity
   tokens to `UITheme`; `DayNightManager.GetPhase()`; phase-gated growth accumulator in
   `PlantGrowthService`; `DefaultData` SchemaVersion→2 + reconcile; offline parity/integrity checks.
2. **Selling (US1, P1)**: `PlayerDataManager` favourite + sell-all helpers; `SellAll`,
   `ToggleFavourite` remotes + harden `SellItem` to crops-only; seller stall model + ProximityPrompt;
   `CreateSellUI.luau` + `SellController` (rows, per-item value, running total, Sell all, star toggle,
   confirm-on-favourite individual sale, out-of-range close); regenerate models.
3. **Shop cards (US3, P2)**: `CreateShopUI.luau` card grid + `CardTemplate`; `ShopController` grid
   population, rarity colour, ×1/×5/×10, dim-when-unaffordable; Tools/Items populated; regenerate.
4. **Toasts (US4, P2)**: `CreateNotifications.luau` + `ToastTemplate`; `ToastQueue`; re-point
   `UIController.ShowNotification`; raise toasts on buy/sell/ready/spirit; regenerate.
5. **Hotbar from inventory (US5, P2)**: `HotbarController` inventory-driven slots + first-free-on-buy
   + overflow via existing paging.
6. **Teleport (US6, P3)**: `RequestTeleport` remote + world anchors; `TeleportRow` in
   `CreateHUDControls.luau`; `UIController` layout + `InputActions` binding; regenerate.
7. **Reward feedback (US7, P3)**: floating "+N coins" via `PlotVisualizer`; reuse
   `UIController.UpdateCurrency` tween on sell/harvest.
8. **Icons (US8, P3)**: fill `icon` fields; generalise fallback across shop/inventory/hotbar.
9. **Polish**: README economy/controls section; parity; quickstart V0–V10 on phone/PC/gamepad.

## Complexity Tracking

No constitution violations to justify. The phase is large but is delivered as prioritized small PRs
(VII) and reuses existing infrastructure rather than adding abstraction.
