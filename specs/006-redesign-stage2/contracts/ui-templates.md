# Contract: UI Templates (Spirit Journal, Spirits tab, redesigned windows)

All GUI is static (builders → `build_models.py` → `StarterGui/*.model.json`), themed with `UITheme`
tokens + `Theme_<Prop>` attributes (both palettes), touch-first (≥44×44, safe area). Clone list items
from static templates; paint clones with `ThemeController.PaintInstant`. These follow the Stage-1
patterns in `specs/005-ui-redesign/contracts/ui-templates.md` (cards, header, rarity badge, detail panel).

## Spirit Journal — NEW `CreateSpiritJournalUI.luau` → `SpiritJournalUI`

A window registered with `WindowManager` (one-at-a-time), sized via `ResponsiveLayout` like the other
windows. Structure:

- `SpiritJournalUI` (ScreenGui) + `Backdrop`
- `JournalFrame`
  - `HeaderBar` (cosy-garden header gradient + title "Spirit Journal" + `CloseButton`)
  - `ProgressLabel` — overall "N / M discovered" (cosmetic; no reward this stage)
  - `EntryScroll` (ScrollingFrame) with a hidden `EntryTemplate` card:
    - rarity strip / `RarityBadge` (shared builder), `Icon` + `FallbackLetter`, `NameLabel`,
      `CountLabel` ("×N"), `FirstCaughtLabel`
    - **Discovered** card: name/rarity/count/first-caught revealed
    - **Undiscovered** card: silhouette/locked state — "???" name, no count (driven by the catalog entry
      having no collection record)

Controller `SpiritJournalController` (NEW, booted from `ClientMain`): on open, reads the player's
`SpiritCollection` from the `GetPlayerData` snapshot and the full set from `ReplicatedStorage/SpiritData`;
clones one card per catalog entry (discovered vs undiscovered); updates `ProgressLabel`. Opened by an
on-screen control (a Journal button — e.g. from the Backpack Spirits tab detail action and/or a HUD
entry); reachable by touch/keyboard/gamepad via `InputActions`.

## Spirits tab (Backpack) — EDIT `CreateInventoryUI.luau` + `InventoryController`

Replace the `SpiritsEmptyState` "coming soon" placeholder behaviour: when there is ≥1 caught spirit,
render the player's caught spirits as rarity-badged cards in `ItemGrid` (reuse the existing
`CardTemplate` + shared `RarityBadge`), consistent with the Seeds/Tools/Crops tabs. Keep an empty-state
message only when the collection is genuinely empty. The detail panel's Spirits action becomes **"Open
Journal"** (was a disabled placeholder), opening `SpiritJournalUI`.

## Redesigned windows (US4) — EDIT builders

Bring each to the cosy-garden header/card/button language + tokens, reusing Stage-1 templates; keep every
existing action/remote unchanged (re-skin only). Regenerate each model.

- `CreateSellUI.luau` → `SellUI`: cosy header, item rows as cards, themed Sell / Sell-all buttons.
- `CreateNotifications.luau` → `Notifications`: themed toast/banner styling consistent with the concept.
- `CreateDailyRewardUI.luau` → `DailyRewardUI`: 7-day streak as cosy-garden reward cards.
- `CreateQuestsUI.luau` → `QuestsUI`: quest rows as cards with progress + reward, themed Claim.

## Shared rules

- Use the shared `RarityBadge` builder/token map from Stage 1 (tier text + `Rarity<Tier>` colour).
- New colours ONLY from `UITheme` tokens; tag with `Theme_<Prop>` so `ThemeController` re-tints on phase.
- Regenerate `StarterGui/*.model.json` after each builder edit and commit (parity gate).
- Verify both palettes at phone-landscape; ≥44×44; content inside the safe area; clear of movement/jump
  zones.
