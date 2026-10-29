# Phase 0 Research: Buy–Sell Economy Loop and Shop Content (Phase 2)

**Feature**: `002-buy-sell-economy` | **Date**: 2026-10-29

This resolves the unknowns in the plan's Technical Context. Each decision is grounded
in the existing code (`ServerScriptService`, `ReplicatedStorage`, the controllers and the
static GUI builders) and the constitution (I server-authoritative, II single config, III
static GUI, IV mobile-first/input-agnostic, V theme tokens, VI verified in Studio, VII small).

## R1 — Selling scope, individual sale, and "Sell all" (US1; FR-001/003/004/005)

**Decision**: Keep the existing `SellItem(player, itemId, quantity)` RemoteFunction for a single
(individual) sale and add a new `SellAll(player)` RemoteFunction for the bulk action. Restrict both
to **crops** (items whose definition has `category = "crop"`); seeds and tools are rejected. The
**favourites** set is server-owned and persisted; `SellAll` iterates the player's sellable crop
stacks, **skips favourited items**, sums coin value, consumes them and credits coins in one
server operation. An individual `SellItem` of a favourited crop is allowed (the client shows a
confirmation first; the server does not need to know about the confirm — it just sells one).

**Rationale**: Constitution I — the server must decide what is sold and for how much; a
client-supplied favourites list would be exploitable. Reusing `SellItem` for the confirm-gated
individual sale keeps the single-item path unchanged.

**Alternatives rejected**: (a) client sends the favourites list to `SellAll` — rejected, client
cannot be trusted with what is protected; (b) one overloaded remote with a "mode" flag — rejected,
two small validated functions are clearer and each is independently rate-limited.

## R2 — Favourites storage and toggle (FR-004; constitution I/II)

**Decision**: Add a per-player `Favourites` set to the profile (`DefaultData.Favourites = {}`,
keyed by itemId → true) and a `ToggleFavourite(player, itemId)` RemoteFunction that validates the
caller, the type, and that the item is a known sellable crop, then flips membership and returns the
new set. The client (`InventoryController`) renders a star toggle per sellable item reflecting this
set.

**Rationale**: Favourites gate a server action (`SellAll`), so they must live on the server.
Storing them in the profile makes them persist and keeps `SellAll` validation self-contained.

**Alternatives rejected**: client-only favourites — rejected, `SellAll` runs on the server and
must honour them.

## R3 — Night-plant growth tied to the night phase (US2; FR-007)

**Decision**: Growth stops being pure wall-clock. Add a per-plot accumulator `GrowthSeconds`
(reconciled into existing plots, default 0). `PlantGrowthService` runs at 1 Hz as today, but each
tick it adds the elapsed second to `GrowthSeconds` **only when the plant is allowed to grow in the
current phase**: a plant definition carries `dayNight = "day" | "night" | "any"`; a `night` plant
(Moonflower, Starberry, Dreamroot) advances only while the current phase is Night, a `day`/`any`
plant advances always. Progress = `GrowthSeconds / growthTimeSec`. The current phase is read from
`DayNightManager.GetPhase()`.

**Supporting change**: `DayNightManager` currently keeps `phase` as a local inside `Start()`.
Promote it to module state and expose `DayNightManager.GetPhase()` (returns "Day"/"Night").

**Rationale**: The day/night schedule is dynamic (lengths in `GameSettings`), so night-grown time
cannot be derived from two timestamps; an accumulator advanced per tick by phase is the simplest
correct model and fits the existing 1 Hz loop.

**Alternatives rejected**: (a) compute night seconds from `PlantedAt` + the schedule — rejected,
brittle if lengths change mid-grow; (b) a separate night-growth coroutine — rejected, duplicates
the existing loop.

## R4 — Single config source and the balance document (US2; FR-006; constitution II)

**Decision**: Restore and extend the two config modules as the single source of truth:
- `ReplicatedStorage/PlantData.lua` — every plant/crop/seed/tool/item definition with
  `displayName, category ("seed"|"tool"|"item"|"crop"), rarity, buyPrice, sellValue, growthTimeSec,
  dayNight, icon, cropId/seedId` links.
- `ReplicatedStorage/ShopConfig.lua` — derives the buy catalogue (seeds/tools/items) and the sell
  table **from** `PlantData` (or references it), keeping the existing helper API
  (`GetBuyPrice`, `GetSellPrice`, `CanSell`) and adding `GetRarity`, `IsNightPlant`,
  `GetCategoryItems(category)`.

The numbers are written first in `specs/002-buy-sell-economy/balance.md` and then transcribed into
the config; no number is duplicated in controllers, GUI text or builders (they read config or the
server snapshot).

**Rationale**: Constitution II. `PlantData`/`ShopConfig` are the named config modules; the server
already reads `ShopConfig` in `RemoteHandlers`. Deriving sell/buy from `PlantData` avoids drift
between a plant's definition and its shop rows.

**Alternatives rejected**: numbers inline in builders/controllers — rejected by II.

## R5 — Shop as a scrolling card grid (US3; FR-008/009/010; constitution III)

**Decision**: Replace the Shop's right-hand "detail pane" with a **scrolling grid of cards**
(`UIGridLayout` in a `ScrollingFrame`), keeping the Seeds/Tools/Items category tabs. A single hidden
**card template** lives in the static `ShopUI` GUI; `ShopController` clones it per item (constitution
III: small dynamic items cloned from a static template, never whole screens built at runtime). Each
card shows icon, name, price, a rarity colour strip, and a ×1 / ×5 / ×10 segmented selector; the buy
button charges the chosen quantity. A card is **dimmed and non-buyable** when `price × quantity >
coins`; dimming recomputes when the quantity or the coin balance changes.

**Rationale**: Constitution III and IV. Cloning a static template keeps the repo canonical and
supports gamepad selection groups. Grid + scroll matches the Phase 1 responsive approach.

**Alternatives rejected**: building each card fully in Lua at runtime — rejected by III; a virtualized
list — rejected as over-engineering (YAGNI, VII) for the current small catalogue.

## R6 — Toast notifications (US4; FR-011; constitution III/IV)

**Decision**: Add a new always-on-top ScreenGui `Notifications` (`DisplayOrder` above windows,
`ScreenInsets = CoreUISafeInsets`) built by a new builder `CreateNotifications.luau` →
`StarterGui/Notifications.model.json`. It contains a vertical container and a hidden **toast
template**. A client toast manager (new `Utils/ToastQueue.lua`, or a section of `UIController`)
maintains a queue/stack: toasts are cloned from the template (pooled, constitution perf), shown with
type colour (success/error/info/event from `UITheme`/`Constants.COLORS`), auto-expire after
`Constants.UI.NOTIFICATION_DURATION`, and never overlap. `UIController.ShowNotification` is
re-pointed from its current single-frame stub to this queue. Toasts are raised on buy/sell results,
on `PlotStateChanged → ReadyToHarvest`, and on `SpiritCollected`.

**Rationale**: FR-011 needs stacking, auto-clear, safe-area and above-window placement — a separate
high-`DisplayOrder` ScreenGui with a pooled template is the standard Roblox pattern and keeps it
clear of the menu column/hotbar.

**Alternatives rejected**: reusing the existing single notification frame in `HUD` — rejected, it
is one-at-a-time and lives below windows.

## R7 — Hotbar built from inventory (US5; FR-012)

**Decision**: `HotbarController` stops using a fixed default tool list and instead derives its slot
contents from the inventory snapshot (`UpdateInventory` / `GetPlayerData`): owned tools first
(watering cans, Harvest action), then owned seeds, in a stable order. A newly bought seed appears in
the **first free slot**. Overflow beyond the visible slot count is handled by the **existing Prev/Next
paging** already in `HotbarController`. If no slot/page is free the seed stays in the inventory only
(edge case) and can be swapped in. The visible slot count stays at the Phase 1 value (no
`ResponsiveLayout` geometry change).

**Rationale**: FR-012 + constitution IV/VII. Reusing the existing paging avoids changing Phase 1
hotbar geometry and keeps the change small.

**Alternatives rejected**: expanding the slot row / adding a second row — rejected, changes Phase 1
responsive math for little gain (VII); forcing a bought seed into a full hotbar — rejected by the
spec edge case.

## R8 — Teleport buttons (US6; FR-013/019; constitution I/IV)

**Decision**: Add a horizontal **teleport row** (Shop / Garden / Stall) to the `HUDControls` ScreenGui,
with geometry from `ResponsiveLayout` (≥ 44×44, inside safe area, no overlap with the menu column,
hotbar, or the Roblox jump/thumbstick zones — reuse the Phase 1 free-area math). Teleport is
**server-performed**: a `RequestTeleport(player, targetId)` remote validates `targetId ∈ {shop,
garden, stall}`, rate-limits, and moves the character's `HumanoidRootPart` to a named anchor part in
the world. The action is bound through the shared `InputActions` layer so touch, keyboard and gamepad
all reach it.

**Rationale**: FR-019 lists teleport among server-validated actions; performing the move on the
server to fixed anchors prevents arbitrary client teleports. Putting the row in `HUDControls`
(the always-on-top Phase 1 control GUI) keeps it above windows and consistent.

**Alternatives rejected**: pure client-side `CFrame` set — rejected by I/FR-019; a new ScreenGui for
the row — rejected, `HUDControls` already hosts the menu column and hotbar.

## R9 — Floating "+N coins" and counter animation (US7; FR-014)

**Decision**: Reuse the existing coin-counter tween in `UIController.UpdateCurrency` (already animates
the HUD coin value) for the counter rise. For the floating label, reuse the world-space label pattern
in `PlotVisualizer` (which already renders a progress bar above a plot): on **harvest**, spawn a
"+N coins" `BillboardGui`/label above the harvested plot that rises and fades. For a **sale** (which
happens at the stall, not a plot), show the counter animation + a success toast, and float the
"+N coins" above the player character as the fallback anchor.

**Rationale**: FR-014 + constitution VII — reusing `UpdateCurrency` and the `PlotVisualizer` label
pattern avoids new animation infrastructure. The sale has no single plot, so the character is the
natural anchor.

**Alternatives rejected**: a brand-new tween system — rejected (VII).

## R10 — Rarity colours as theme tokens (FR-008/018; constitution V)

**Decision**: Add five rarity colour tokens to `ReplicatedStorage/UITheme.lua`
(`RarityCommon, RarityUncommon, RarityRare, RarityEpic, RarityLegendary`) in the current dark/night
palette only; cards and item rows read the token by rarity. Day-palette rarity values and runtime
switching are Phase 4.

**Rationale**: Constitution V forbids new hard-coded theme colours; the five tiers are theme content.

**Alternatives rejected**: hard-coded card colours — rejected by V.

## R11 — Real icons with fallback (US8; FR-015)

**Decision**: Each definition in `PlantData` carries an `icon` field (a `rbxassetid://…` or empty).
The shop cards, inventory grid and hotbar read this field. The existing first-letter/emoji fallback
in `InventoryController` is generalised so any item without an icon shows a consistent fallback;
no flow blocks on missing art (assumption). Icons may be filled in as they become available.

**Rationale**: FR-015 + the existing fallback already present in `InventoryController`.

## R12 — Persistence & backward compatibility (constitution I/II/VI)

**Decision**: Bump `DefaultData.SchemaVersion` to 2 and add `Favourites = {}`, per-plot
`GrowthSeconds = 0`, and inventory entries (default 0) for the new crops/seeds (night plants,
Dreamroot). `PlayerDataManager`/ProfileService reconciles saved profiles against `DefaultData`
(add missing fields, never drop) so existing saves keep loading. Studio testing tolerates a
missing/mock DataStore (API access off) and must not corrupt live data.

**Rationale**: Constitution II (reconcile, never drop) and VI (safe testing).

## R13 — Server-side validation of the new remotes (FR-005/019)

**Decision**: `SellAll`, `ToggleFavourite` and `RequestTeleport` follow the existing
`RemoteHandlers` pattern: `pcall` wrapper, `rate_ok` per method, strict type/ownership checks,
`fail()` closed on bad input, `AntiCheat.log` for suspicious calls, and a snapshot returned to the
client. Buy/sell values are read from config on the server; the client never sends prices or totals.

**Rationale**: Constitution I; mirrors the hardened Phase-1-era handlers already in the file.

---

**All Technical Context unknowns resolved.** Two items carry a Studio verification step rather than
an open question: the exact night-growth accrual across a full day→night cycle (R3, quickstart V2)
and teleport-anchor placement in the test place (R8, quickstart V6).
