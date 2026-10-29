# Night in the Garden — v6

Roblox farming game: client + server with ProfileService persistence,
plot visualization pipeline, spirit system and security/validation hardening.

## Structure

The repo follows the [Rojo](https://rojo.space) layout (`default.project.json`).
The file suffix decides the script class, so classes are never lost on import:

| Suffix | Roblox class |
| --- | --- |
| `.server.lua` | Script |
| `.client.lua` | LocalScript |
| `.lua` | ModuleScript (name = file name without `.lua`) |
| `.model.json` | instances (static GUI) |

```
ReplicatedStorage/            shared config modules (PlantData, ShopConfig, Constants, ...)
ServerScriptService/
  Init.server.lua             server entry point
  AdminCommands.server.lua
  CreateRemotes.lua           RemoteEvents/Functions (required by Init)
  RemoteHandlers.lua          remote handlers (required by Init)
  ProfileService.lua          vendored, Apache 2.0 (ThirdParty/)
  Services/                   PlayerDataManager, PlotManager, PlantGrowthService,
                              DayNightManager, StallService (seller stall),
                              DailyRewardService, QuestService, ShopStockService, ...
    Spirit/                   spirit system
StarterGui/                   static GUI: HUD, HUDControls, InventoryUI, ShopUI,
                              SellUI, Notifications, DailyRewardUI, QuestsUI (.model.json)
StarterPlayer/StarterPlayerScripts/
  ClientMain.client.lua       client entry point, boots the controllers
  Controllers/                UIController, HotbarController, InventoryController,
                              ShopController, SellController, DailyRewardController,
                              QuestController, TutorialController
  Utils/                      StateManager, ClientDataCache, PlotVisualizer, GuiEffects, Debounce,
                              InputActions, WindowManager, ResponsiveLayout, ToastQueue,
                              EventHandlers.client.lua, PlotInteraction.client.lua
ReplicatedStorage/UITheme.lua colour tokens for the UI (dark palette; day palette is Phase 4)
Tools/StaticGui/              generator for StarterGui/*.model.json (see below)
Workspace/                    create Plot1..Plot3 here (Model + PlotBase part + PlotMarker BoolValue)
Docs/
```

## Getting started

1. Sync with Rojo (`rojo serve`) or copy scripts manually. When copying by hand,
   create each script with the class from the table above and drop `.lua` /
   `.server` / `.client` from the name.
2. Create Plot1..Plot3 models in Workspace.
3. Play in Studio. With API access off, ProfileService uses a mock DataStore;
   with it on (Game Settings → Security), Studio data is saved for real.

## Static GUI (P2-3)

The GUI is static: `StarterGui/*.model.json`, cloned into PlayerGui on spawn.
Hover colors, tab highlighting and the loading spinner live in the controllers
(`Utils/GuiEffects.lua`).

The models are generated from the original builder scripts in
`Tools/StaticGui/builders/`. To change the GUI, either edit it in Studio and
mirror the change in the builder, or edit the builder and regenerate:

```
python3 Tools/StaticGui/build_models.py /path/to/luau
```

## Controls (Phase 1: mobile UI access)

The game is playable on a landscape phone, PC and (via gamepad) console. Every
action goes through one shared action layer (`Utils/InputActions.lua`), so the
on-screen menu buttons (Shop, Inventory) show on every platform, and a window
can always be opened and closed without a keyboard.

| Action | Touch | Keyboard / mouse | Gamepad |
| --- | --- | --- | --- |
| Open / toggle Shop | tap the Shop button | `B` | `X` |
| Open / toggle Inventory | tap the Inventory button | `I` | `Y` |
| Close the open window | tap `X` or the dimmed backdrop | tap `X` / backdrop | `B` |
| Select hotbar slot | tap the slot | `1` `2` `3` | `L1` / `R1` (prev / next, wraps) |
| Move inside a window | tap | mouse | D-pad / left stick |
| Confirm in a window | tap | click | `A` |

- The menu buttons show the key label on PC and the matching gamepad glyph on a
  gamepad; neither on touch. Only one window is open at a time.
- `Esc` is left to the Roblox menu — no game action depends on it.
- The phone is locked to landscape (`StarterGui.ScreenOrientation = LandscapeSensor`),
  and the default Roblox backpack is turned off so `L1`/`R1` can be bound.
- Window size, the menu column and the touch hotbar position come from
  `Utils/ResponsiveLayout.lua` (unit-tested in `Tools/Tests/`); colours come from
  `ReplicatedStorage/UITheme.lua`.

## Phase 2: buy–sell economy

The economy loop is closed: **buy → plant → grow → sell → buy more**. All economy
actions are validated on the server (`RemoteHandlers.lua`); the client only renders
and requests. Balance numbers live once in `ReplicatedStorage/PlantData.lua` and
`ReplicatedStorage/ShopConfig.lua`, written first in
[`specs/002-buy-sell-economy/balance.md`](specs/002-buy-sell-economy/balance.md) and
checked by `Tools/Tests/economy_config.spec.luau`.

- **Shop** (`ShopController` + `ShopUI`): a scrolling grid of cards per category
  (Seeds / Tools / Items). Each card shows a rarity colour (Common → Legendary
  tokens in `UITheme`), price and ×1 / ×5 / ×10 quantity buttons; a card the player
  cannot afford at the chosen quantity is dimmed and not buyable.
- **Selling** (`SellController` + `SellUI`): a seller's stall (`StallService`) with a
  "Sell" `ProximityPrompt`. The sell window lists harvested **crops** (only crops are
  sellable), each with its value and a star **favourite** toggle, a running "Sell all"
  total, individual sale, and "Sell all" (which never sells favourites; a favourite can
  still be sold individually after a confirm).
- **Night plants**: Moonflower, Starberry and **Dreamroot** grow only during the night
  phase (growth pauses during the day); see `PlantGrowthService` + `DayNightManager`.
- **Teleport** (`HUDControls.TeleportRow`): shop / garden / stall quick-travel buttons,
  performed server-side (`RequestTeleport`, fails closed on an unknown target).
- **Toasts** (`ToastQueue` + `Notifications`): queued on-screen messages for purchase,
  error, crop-ready and spirit-caught, above the windows and clear of the HUD.
- **Reward feedback**: a floating "+N coins" on a sale plus the animated coin counter.
- **Hotbar** is built from the player's inventory (owned tools + Harvest + owned seeds);
  a bought seed joins the list and the HUD coin counter / toasts reflect the change.
- Item **icons** come from the config `icon` fields with a consistent emoji / first-letter
  fallback where an icon is not set yet.

Day / night palette switching is Phase 4 (the dark palette is used throughout for now).

### Economy controls

| Action | Touch | Keyboard / mouse | Gamepad |
| --- | --- | --- | --- |
| Open the sell window | tap the stall's on-screen "Sell" button | `E` prompt at the stall | on-screen prompt button |
| Teleport (shop / garden / stall) | tap a teleport button | click a teleport button | select + `A` |
| Pick buy quantity (×1 / ×5 / ×10) | tap | click | select + `A` |

## Phase 3: retention

Mechanics that bring players back and teach the loop. All reward / quest / stock state is
server-authoritative; the numbers live once in `ReplicatedStorage/RetentionConfig.lua`, written first
in [`specs/003-retention/balance.md`](specs/003-retention/balance.md) and checked by
`Tools/Tests/retention_config.spec.luau`. `DefaultData` is SchemaVersion 3 (adds `DailyReward`,
`Quests`, `Onboarding`; reconciled into existing profiles).

- **Daily reward** (`DailyRewardService` + `DailyRewardUI` + `DailyRewardController`): a 7-day streak,
  claimable once per UTC day; the streak advances on consecutive days, resets after a missed day and
  loops after day 7. The window auto-opens on the first login of a day and also opens from the HUD
  **Rewards** button.
- **Daily quests** (`QuestService` + `QuestsUI` + `QuestController`): three per-day objectives chosen
  deterministically from the config pool by the day index (same for everyone), tracked from real
  events (plant / harvest / sell / catch a spirit) and claimed once; a completion toast confirms.
- **Shop restock** (`ShopStockService`): each stocked item has a limited, per-server stock that
  refills on a time-derived window (identical countdown on every server); the shop shows the remaining
  stock and a restock countdown, and `BuyItem` fails closed when out of stock (never oversells).
- **Night as an event**: a brief nightfall banner on the day→night transition, and a rate-limited,
  server-wide announcement when a Rare or Epic spirit appears (`SpiritSpawner` → `ServerAnnounce`).
- **Onboarding** (`TutorialController`): a one-time, skippable guide through plant → water → sell for
  new players; completion persists (`SetTutorialDone`) so it shows once.

### Retention controls

| Action | Touch | Keyboard / mouse | Gamepad |
| --- | --- | --- | --- |
| Open / toggle Daily Reward | tap the Rewards button | `R` | D-pad up |
| Open / toggle Quests | tap the Quests button | `Q` | D-pad down |
| Claim a reward / quest | tap Claim | click Claim | select + `A` |

## Phase 4: day/night theme engine

Two palettes — Day ("cosy garden") and Night ("moonlit") — live in
`ReplicatedStorage/UITheme.lua` with the structural style tokens. The static GUI builders bake the
Night colours and tag each themed property with a `Theme_<Prop> = "<Token>"` attribute;
`Controllers/ThemeController.lua` cross-fades every tagged instance to the active palette on the
`DayNightUpdate` phase change — no model regeneration. `Tools/Tests/theme.spec.luau` enforces that
every token exists in both palettes.

## Feature 005: cosy-garden UI redesign (Stage 1)

The HUD, Seed Shop and Backpack rebuilt on the theme engine, server-authoritative with no new
remotes.

- **HUD**: top-centre SEEDS / GARDEN / SELL nav, left BAG / QUESTS / GIFTS column, top-right day/night
  pill with countdown, a single current-quest card, and a bottom-centre five-slot tool strip (slots
  3–5 are locked "coming soon" placeholders this stage).
- **Seed Shop**: large image cards with rarity badges, an ×1 / ×5 / ×10 quantity selector + Buy, and
  Seeds / Tools / Special tabs (SEEDS preselects Seeds).
- **Backpack**: a rarity-badged card grid with a detail panel and working Equip, five tabs incl. a
  Spirits placeholder.
- **Item icons**: a shared emoji/icon source (`ReplicatedStorage/ItemEmoji.lua`) across shop,
  backpack and hotbar, with a letter/emoji fallback.
- **Harvest hint (FR-007)**: by day, near a ready plot, a themed `HUD.HarvestHint` appears
  bottom-centre; `Controllers/HarvestHintController.lua` harvests the nearest ready plot on an
  on-screen tap or the `F` key (via the existing `InteractWithPlot` path). Hidden at night, out of
  range, or with a window open.

The items Stage 1 deferred (the real tools, spirit collection + Journal, new creatures + net capture,
and the window re-skin) all shipped in **Feature 006 (Stage 2)** — see below.

### Redesign controls

| Action | Touch | Keyboard / mouse | Gamepad |
| --- | --- | --- | --- |
| Open Seed Shop | tap SEEDS | `B` | button X |
| Teleport to garden / stall | tap GARDEN / SELL | click GARDEN / SELL | select + `A` |
| Open Backpack / Quests / Gifts | tap BAG / QUESTS / GIFTS | `I` / `Q` / `R` | Y / D-pad down / D-pad up |
| Select tool slot 1–5 | tap the slot | `1`–`5` | L1 / R1 to cycle |
| Harvest a ready plot (by day) | tap the Harvest hint | `F` (or click the plot) | tap the hint |

## Feature 006: cosy-garden redesign (Stage 2)

The systems deferred from Stage 1, server-authoritative with no new remotes. `DefaultData` is
SchemaVersion 4 (adds `SpiritCollection`); balance in `specs/006-redesign-stage2/balance.md`, catalog
checked by `Tools/Tests/spirit_config.spec.luau`.

- **Real tools (slots 3–5)**: `lantern` / `net` / `shovel` are bought in the shop Tools tab and fill
  the hotbar. The **shovel** clears a non-ready plant from a plot (rejects a ready crop); the
  **lantern** raises the night spirit spawn rate around the equipped player; the **net** catches the
  new flying creatures.
- **Spirit capture**: new **Moonmoth / Moth-Spirit** spawn at night (catalog in
  `ReplicatedStorage/SpiritData.lua`). Existing wisps still collect by walking up (proximity); the new
  creatures need the net, and the server rolls a per-rarity catch chance. The first catch of each type
  pays a one-time Dream-Seeds discovery bonus. Notable spawns reuse the existing "appeared" banner.
- **Spirit Journal**: a catalogue screen (`SpiritJournalUI`) listing every known spirit — caught ones
  revealed (name / rarity / count / first-caught), uncaught ones as a locked "???", with overall
  progress. Opened from the Backpack **Spirits** tab, which also shows caught spirits as cards.
- **Window re-skin**: the Sell / Quests / Daily-Gift / Notifications windows are rebuilt on theme
  tokens so they retint on the day/night switch, matching the cosy-garden concept (no behaviour change).

Collection is read from the existing `GetPlayerData` snapshot; the Journal uses `SpiritData` for the
full set. Deferred beyond Stage 2 (spec "scope ceiling"): trading, new currencies, a world/map redesign.

## Notes
- Shop is single-source-of-truth via `ReplicatedStorage/ShopConfig.lua`
- Player data template in `ReplicatedStorage/DefaultData.lua`
- Environment store name controlled by `ReplicatedStorage/GameSettings.lua`
