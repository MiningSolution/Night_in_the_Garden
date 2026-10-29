# Phase 1 Data Model: Cosy-Garden Redesign — Stage 2

All data lives once in config / the player profile (Constitution II). The client never holds
authoritative gameplay data; it renders server-provided state.

## Tool (config)

Home: `ReplicatedStorage/ShopConfig.lua` → `buy.tools[<id>]` (same shape as existing tools).

| Field | Type | Notes |
|-------|------|-------|
| id (key) | string | `"lantern"`, `"net"`, `"shovel"` |
| price | number | coins; single-source here (balance value, set in planning) |
| rarity | string | `Common`/`Uncommon`/`Rare`/… (drives the shop card badge) |
| displayName | string | shown in shop / hotbar / backpack |
| icon | string | asset id or `""` (falls back to `ItemEmoji`) |

Ownership is an inventory count in the profile (`Inventory[<id>]`), like existing tools. Equipping is
server-validated by `InventoryService.SetEquipped` (owned-tool check). Behaviour by id:

- `shovel` — plot tool: clears a non-Empty plot to `Empty` (no yield). Via `InteractWithPlot`.
- `net` — spirit tool: required to capture `captureMethod = "net"` spirits (US2 roll). Via the spirit
  `ProximityPrompt`.
- `lantern` — equipped effect: while equipped at night, raises nearby spawn rate (R3). No active use.

## Spirit type (catalog)

Home (NEW single source): `ReplicatedStorage/SpiritData.lua` — array/dictionary of spirit types; the
server `Services/Spirit/SpiritTypes.lua` reads it; the client Journal reads it for the full known set.

| Field | Type | Notes |
|-------|------|-------|
| id (key) | string | e.g. `wisp_common`, `wisp_rare`, `wisp_epic`, `moonmoth`, `moth_spirit` |
| displayName | string | shown in feedback / Journal / Spirits cards |
| rarity | string | tier (also drives badge colour + catch chance tier) |
| weight | number | spawn weight for the weighted random pick (existing) |
| reward | number | per-collect DreamSeeds for proximity wisps (existing; 0 = config range) |
| captureMethod | enum | `"proximity"` (wisps, unchanged) or `"net"` (new flying creatures) |
| catchChance | number | 0–1, net types only; probability per attempt (rarer = lower) |
| firstCatchBonus | number | one-time discovery bonus (coins / dream seeds) on first catch; 0 = none |

Existing entries (`wisp_common/rare/epic`) keep `captureMethod="proximity"`, `catchChance`/`firstCatchBonus`
omitted or 0. New: `moonmoth`, `moth_spirit` with `captureMethod="net"`, a per-rarity `catchChance`, and a
`firstCatchBonus`.

Validation / rules:
- `captureMethod="net"` MUST have a `catchChance` in (0,1]; `proximity` MUST NOT be net-gated.
- `weight` > 0; rarity MUST be a known tier (so the badge/colour resolve).
- Server never trusts a client-sent type; the type comes from the spawned model's `SpiritId` → catalog.

## Spirit collection record (per-player, persisted)

Home: `ReplicatedStorage/DefaultData.lua` → new `SpiritCollection = {}`, `SchemaVersion` 3 → 4.

Shape: `SpiritCollection[<spiritTypeId>] = { Count = <int>, FirstCaughtAt = <unixTime> }`.

| Field | Type | Notes |
|-------|------|-------|
| Count | number | times this type has been caught/collected (≥1 once discovered) |
| FirstCaughtAt | number | unix time of first catch (0/absent = undiscovered) |

Rules & lifecycle:
- A type is **undiscovered** when it has no record (or `FirstCaughtAt = 0`); the Journal shows it locked.
- On a successful catch/collect, the server calls `RecordSpiritCaught(player, typeId)`: if no record,
  create `{Count=1, FirstCaughtAt=os.time()}` and return `isFirst=true`; else `Count += 1`,
  `isFirst=false`.
- `isFirst=true` AND the type's `firstCatchBonus > 0` → award the one-time bonus server-side (US2-AS5).
- Reconcile backfills `SpiritCollection = {}` into existing profiles (never drops other fields).
- Also declare `Stats.TotalSpiritsCollected` in DefaultData (already incremented at runtime).
- Exposed to the client via `PlayerDataManager.Snapshot` → `GetPlayerData` (no new remote).

## Relationships

- **Tool → hotbar**: owned tools (`Inventory`) populate hotbar slots 3–5 (`HotbarController`).
- **Tool(net) → Spirit capture**: `net` equipped gates `captureMethod="net"` spirits.
- **Tool(lantern) → spawner**: `lantern` equipped biases `SpiritSpawner` anchor/radius at night.
- **Spirit catch → collection**: every successful catch/collect updates the player's
  `SpiritCollection`; first catch of a `firstCatchBonus` type grants the bonus once.
- **Collection → Journal/Spirits tab**: the Journal and Backpack Spirits tab render the player's
  `SpiritCollection` against the full `SpiritData` catalog (discovered vs undiscovered).

## Config tunables (single-source)

- `GameSettings.SpiritSettings`: existing (MaxActive, SpawnIntervalSec, SpawnRadius, …) + new
  `LanternSpawnRadius` and any lantern spawn-bias knob.
- `Constants.SPIRIT`: structural caps (spawn attempts, min spawn distance) — reuse; add only if needed.
- Catch chances, weights, rewards, first-catch bonuses: in `SpiritData` (not duplicated elsewhere).
- Tool prices: in `ShopConfig.buy.tools`.
