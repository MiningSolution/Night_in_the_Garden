# Contract: Static GUI tree (names the controllers rely on)

**Feature**: `002-buy-sell-economy` | **Date**: 2026-10-29

All GUI is built by the builders in `Tools/StaticGui/builders/*.luau` and regenerated into
`StarterGui/*.model.json` via `build_models.py` (constitution III). Controllers only attach behaviour
and clone the templates named here; they MUST NOT construct whole screens at runtime. Colours come
from `UITheme` tokens (constitution V). All tappable elements ≥ 44×44, body text ≥ 18, titles/buttons
≥ 20, inside `CoreUISafeInsets` (constitution IV).

## `ShopUI` (rework — `CreateShopUI.luau`)  (US3)

- Keeps: `ScreenGui ShopUI`, header + close button, category tabs (`seedsCategoryBtn`,
  `toolsCategoryBtn`, `itemsCategoryBtn`), backdrop, loading overlay (Phase 1).
- Replaces the detail pane with:
  - `CardsScroll` (`ScrollingFrame`) containing a `UIGridLayout`.
  - `CardTemplate` (hidden `Frame`, `Visible = false`) cloned per item, with children:
    `Icon` (`ImageLabel`), `FallbackLetter` (`TextLabel`), `NameLabel`, `PriceLabel`,
    `RarityStrip` (`Frame`, colour set from `UITheme` rarity token), `QtyX1`/`QtyX5`/`QtyX10`
    (`TextButton`s, a selection group), `BuyButton`.
- `ShopController` clones `CardTemplate` into `CardsScroll` per `GetShopData` item, sets dim state
  (`price × qty > coins` → dimmed, buy disabled), and rebinds on qty/coin change.

## `SellUI` (new — `CreateSellUI.luau`)  (US1)

- `ScreenGui SellUI` (window, backdrop, close, registered with `WindowManager` as single-window).
- `Header` with `TitleLabel` ("Sell") and `TotalLabel` (running coin total).
- `ItemsScroll` (`ScrollingFrame`) + `SellRowTemplate` (hidden) with: `Icon`/`FallbackLetter`,
  `NameLabel`, `CountLabel`, `ValueLabel` (per-item sell value), `StarToggle` (`ImageButton`/`TextButton`
  favourite), `SellOneButton`.
- `SellAllButton` (footer), `EmptyState` (`TextLabel`, shown when nothing sellable / all favourite).
- `InventoryController`/a new `SellController` populates rows from the inventory snapshot + the
  `Favourites` set, shows per-item value and the running total, wires `StarToggle → ToggleFavourite`,
  `SellOneButton → SellItem` (favourite → confirm first), `SellAllButton → SellAll`.

## `HUDControls` (extend — `CreateHUDControls.luau`)  (US6)

- Keeps: menu column (`Shop`, `Inventory` buttons) and `Hotbar` (Phase 1).
- Adds: `TeleportRow` (`Frame`) with `TeleportShop`, `TeleportGarden`, `TeleportStall`
  (`TextButton`/`ImageButton`, ≥ 44×44, selection group). `UIController` positions the row from
  `ResponsiveLayout` (no overlap with menu column, hotbar, Roblox controls) and binds each to
  `RequestTeleport` through `InputActions`.

## `Notifications` (new — `CreateNotifications.luau`)  (US4)

- `ScreenGui Notifications`, high `DisplayOrder` (above windows), `ScreenInsets = CoreUISafeInsets`,
  `ResetOnSpawn = false`.
- `ToastContainer` (`Frame` + `UIListLayout`, top or bottom aligned, inside safe area).
- `ToastTemplate` (hidden) with `Bar`/`Background` (colour by type), `Icon`, `MessageLabel`.
- The client toast manager clones/pools `ToastTemplate`; `UIController.ShowNotification` enqueues.

## `Hotbar` (behaviour — `HotbarController`, US5)

No new named elements; `HotbarController` fills the existing slot frames from the inventory snapshot
and uses the existing Prev/Next paging for overflow.

## Floating "+N coins" (US7)

Reuses the world-label pattern in `Utils/PlotVisualizer.lua` (a `BillboardGui`/label above a plot);
no static ScreenGui element. The HUD coin counter animates via the existing
`UIController.UpdateCurrency` tween.

## Regeneration

After any builder change: `python3 Tools/StaticGui/build_models.py <luau>` and commit the regenerated
`StarterGui/*.model.json` so repo and Studio stay identical (FR-016). New ScreenGuis
(`SellUI`, `Notifications`) are added to `default.project.json` only if not already covered by the
`StarterGui` path mapping (the folder is mapped, so new `*.model.json` are picked up automatically).
