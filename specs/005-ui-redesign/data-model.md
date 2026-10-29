# Phase 1 Data Model: Cosy-Garden UI Redesign (Stage 1)

This feature adds **no persisted entities and no new server-trusted data**. It defines *view models* —
the shape each screen reads from existing client state / config to render. Every field below already
exists in the game's data; the redesign only presents it. Authoritative data stays server-owned
(Constitution I); config numbers stay single-source (II).

## Existing data sources (read-only here)

- **`StateManager` / `ClientDataCache`** — player coins, DreamSeeds, inventory (item name → quantity),
  favourites, current day/night phase + progress, quest progress. Updated by remotes
  `UpdateCurrency`, `UpdateInventory`, `DayNightUpdate`, quest state. The UI subscribes; it never
  writes authoritative values.
- **`PlantData`** — per plant: display name, `rarity` (Common/Uncommon/Rare/Epic/Legendary), growth,
  `seedIcon`, `cropIcon`, dayNight flag, description metadata (`GetItemDisplayData`).
- **`ShopConfig`** — `buy.seeds` (derived from PlantData), `buy.tools`, `buy.items` (each with `icon`),
  `sell`; `GetRarity(itemId)`, `GetBuyPrice`, `GetSellPrice`, `rarityById`.
- **`UITheme`** — palette tokens + `Style`; `ThemeController` paints `Theme_<Prop>`-tagged instances.

## View models

### RarityTier (shared badge model)

| Field | Source | Notes |
|-------|--------|-------|
| `tierId` | `PlantData.rarity` / `ShopConfig.GetRarity(itemId)` | one of Common/Uncommon/Rare/Epic/Legendary |
| `tierText` | derived from `tierId` | UPPERCASE label shown on the badge (COMMON…LEGENDARY) |
| `tierColor` | `UITheme.Rarity<Tier>` token (per palette) | badge colour; tagged `Theme_<Prop>` so it re-tints |

Rule (FR-025): the badge shows **both** `tierText` and `tierColor`; rarity is never conveyed by colour
alone, and the badge colour is independent of the item's own icon colour.

### ShopItemCard (Seed Shop)

| Field | Source | Notes |
|-------|--------|-------|
| `itemId`, `category` | shop data (`GetShopData` / `ShopConfig`) | category ∈ seeds/tools/items(Special) |
| `displayName` | PlantData / ShopConfig | |
| `icon` | `seedIcon`/`cropIcon`/tool `icon` | letter fallback if `""` |
| `rarity` | RarityTier | badge |
| `price` | `GetBuyPrice` / shop data | gold, token `Coins` |
| `stock`, `soldOut` | shop data `Stock` | `soldOut` when stock 0 |
| `qty` | UI selection (×1/×5/×10) | exactly that quantity (FR-011) |
| `buyState` | derived | `enabled` / `out_of_stock` / `cant_afford` / `exceeds_stock` (distinct reasons, FR-012) |

Buy still goes through `BuyItem:InvokeServer(category, itemId, qty)`; the server revalidates and returns
`NewBalance`/`Stock`; the card updates in place (FR-013).

### InventoryItemCard (Backpack)

| Field | Source | Notes |
|-------|--------|-------|
| `itemName` | `StateManager.getInventory()` key | |
| `quantity` | inventory value | |
| `icon`, `displayName`, `description` | `PlantData.GetItemDisplayData` | letter fallback if `""` |
| `rarity` | RarityTier | badge |
| `category` | derived (IsSeed/IsTool/crop/spirit) | tab filter: All/Seeds/Tools/Crops/Spirits |
| `favourite` | favourites state (`ToggleFavourite` RF) | favourite mark on the card + detail toggle |
| `contextAction` | derived from `category` | Equip (Seeds/Tools) / Go to sell (Crops) / View journal (Spirits, placeholder) |

Equip performs `EquipTool:FireServer(serverTool)` via `HotbarController` (FR-019). Spirits tab shows an
empty "coming soon" placeholder (FR-017); no spirit items are enumerated this stage.

### PhasePill (HUD)

| Field | Source | Notes |
|-------|--------|-------|
| `phase` | `DayNightUpdate` arg 1 | "Day"/"Night"/"Transition" |
| `progress` | `DayNightUpdate` arg 2 (0–1) | drives the fill bar |
| `remainingText` | derived `(1−progress) × phaseDuration` | phaseDuration from single-source config; refreshed per tick, no client clock (R3). Falls back to blank if cadence too coarse |

### QuestCard (HUD)

| Field | Source | Notes |
|-------|--------|-------|
| `title`, `progressText`, `rewardText` | existing quest state (QuestController) | first incomplete quest only (FR-005) |
| `onTap` | QUESTS action | opens the full Quests window |

### ToolSlot (HUD hotbar strip, 5 slots)

| Field | Source | Notes |
|-------|--------|-------|
| `index` | 1–5 | key label 1–5 on PC |
| `tool` | `HotbarController` items (real tools only) | slots 1–2 real; 3–5 locked placeholder |
| `equipped` | `HotbarController.equippedIndex` | selection border |
| `locked` | `index > realToolCount` | shows lock; inert on tap (FR-006) |

### IconManifest (licence audit, not runtime)

A `contracts/icons.md` table: `itemId → assetId → source → licence`. Backs FR-021; not read by the game.
