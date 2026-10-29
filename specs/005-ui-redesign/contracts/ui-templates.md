# Contract: Static-GUI Templates & Instance Names

The controllers depend on exact instance names in the builders (Constitution III: controllers attach
behaviour and clone from static templates). This lists the names each screen MUST expose after the
redesign so controller wiring and the static-GUI fingerprint stay in lockstep. **New / renamed names
are marked.** Builders are regenerated with `build_models.py`; `StarterGui/*.model.json` committed.

## HUD (`CreateHUD.luau`, ScreenGui `HUD`, DisplayOrder 0)

- `CurrencyDisplay.CoinsLabel` — coins (token `Coins`). *(exists)*
- `CurrencyDisplay.DreamSeedsLabel` — second currency, **display label "Dream Seeds"** (token `Dream`).
  *(exists; relabel text)*
- `DayNightIndicator.PhaseLabel`, `DayNightIndicator.ProgressBarContainer.ProgressBar` — phase pill;
  **migrate RGB → theme tokens**; optional **`TimeLeftLabel`** (new) for the countdown. *(restyle)*
- **`QuestCard`** (new) — `TitleLabel`, `ProgressLabel`, `RewardLabel`; themed; tap opens Quests.

## HUDControls (`CreateHUDControls.luau`, ScreenGui `HUDControls`, DisplayOrder 10)

- **`PrimaryNav`** (new, top-centre) — `SeedsButton`, `GardenButton`, `SellButton` (labels SEEDS /
  GARDEN / SELL), each ≥44×44, themed, with `KeyHint`/`PadHint` where applicable. Replaces the
  top-right `TeleportRow`.
- `MenuButtons` (left column) — reduced to **`InventoryButton` (BAG), `QuestsButton` (QUESTS),
  `RewardsButton` (GIFTS)**; `ShopButton` removed (moved to PrimaryNav). Keep `KeyHint`/`PadHint`.
- `Hotbar` — **five** slots `Slot1..Slot5` (was 3). Each: `SlotButton`, `ItemIcon/EmojiLabel`,
  `SelectionBorder`, `KeybindHint` (1–5); slots 3–5 carry a **`LockOverlay`** (new) and are inert.
  `PadHintLeft`/`PadHintRight` kept.

## ShopUI (`CreateShopUI.luau`, ScreenGui `ShopUI`, DisplayOrder 5)

- `ShopFrame.HeaderBar` (`TitleLabel`, `CloseButton`, `RestockLabel`); `TabContainer` with `seedsTab`,
  `toolsTab`, `itemsTab` (**relabel itemsTab text → "Special"**, id unchanged); `CardsScroll`.
- `CardsScroll.CardTemplate` (Visible=false) — big image card: `Icon` (+`FallbackLetter`), `NameLabel`,
  **`RarityBadge`** (new: `BadgeText` tier label + rarity colour, replacing the bare `RarityStrip`),
  `PriceLabel` (token `Coins`), `StockLabel`, `QtyRow.{QtyX1,QtyX5,QtyX10}`, `BuyButton`.
- Controller clones `CardTemplate` and MUST call `ThemeController.PaintInstant(clone)` (R9).

## InventoryUI (`CreateInventoryUI.luau`, ScreenGui `InventoryUI`, DisplayOrder 5)

- `InventoryFrame.HeaderBar` (`TitleLabel`, `CloseButton`).
- `TabContainer` — **five tabs** (new set): `AllTab`, `SeedsTab`, `ToolsTab`, `CropsTab`, `SpiritsTab`.
- `ItemGrid` (ScrollingFrame + UIGridLayout) + **`CardTemplate`** (new, Visible=false): `Icon`
  (+`FallbackLetter`), `NameLabel`, **`RarityBadge`** (`BadgeText` + colour), `QtyLabel`,
  `FavouriteMark`.
- **`DetailPanel`** (new) — `SelectedIcon`, `SelectedName`, `SelectedDescription`, `FavouriteToggle`,
  `ActionButton` (text swaps Equip / Go to sell / View journal by category).
- **`SpiritsEmptyState`** (new) — "coming soon" placeholder shown when the Spirits tab is active.
- Controller clones `CardTemplate` and MUST call `ThemeController.PaintInstant(clone)` (R9); it replaces
  the current code-built slots.

## Theming rule (all templates)

Every colour on every new/renamed instance comes from a `UITheme` token and is tagged `Theme_<Prop>`
(`Theme_Color` on UIStroke; `Theme_GradientTop`/`Theme_GradientBottom` on UIGradient) so
`ThemeController` re-tints it on `DayNightUpdate`. No raw RGB for themed surfaces/text (V). Key chips
(KeyHint/KeybindHint dark chips) stay neutral as today.
