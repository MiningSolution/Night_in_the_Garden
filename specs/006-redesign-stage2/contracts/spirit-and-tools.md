# Contract: Spirit Catalog + Tool Definitions

Single-source shapes the implementation must follow. Exact numbers (prices, chances, bonuses) are
balance values chosen during `/speckit-tasks`/implementation; the shapes below are the contract.

## Spirit catalog — `ReplicatedStorage/SpiritData.lua` (NEW, single source)

Read by the server `Services/Spirit/SpiritTypes.lua` (which keeps `ChooseRandom`/`FindById`) and by the
client Spirit Journal. Each entry:

```lua
{
  id = "moonmoth",              -- stable key, matches the spawned model's SpiritId
  displayName = "Moonmoth",
  rarity = "Rare",             -- known tier (badge colour + chance tier)
  weight = 20,                  -- weighted spawn pick (existing mechanism)
  captureMethod = "net",       -- "proximity" (wisps) | "net" (new flying creatures)
  catchChance = 0.5,           -- net only: P(success) per attempt, 0..1 (rarer = lower)
  firstCatchBonus = 25,        -- one-time discovery reward (0 = none)
  reward = 0,                  -- proximity per-collect DreamSeeds (0 = SpiritConfig range); wisps only
}
```

Rules:
- Existing wisp entries keep `captureMethod="proximity"` and behave exactly as today (no chance, their
  existing reward path). Do not change wisp collection.
- New entries (`moonmoth`, `moth_spirit`) use `captureMethod="net"`, a `catchChance` in (0,1], and a
  `firstCatchBonus` > 0.
- `rollCatch(chance, rng)` is a pure function (inject `rng`; default `Random.new()`), offline-testable.

## Server capture branch — `Services/Spirit/SpiritCollector.lua`

`tryCollect(player, spiritId, spirit, spiritType, isActive, removeSpirit)`:
1. Validate active + per-player cooldown + distance (existing).
2. Branch by `spiritType.captureMethod`:
   - `"proximity"` → existing behaviour (reward via `AddDreamSeeds`, feedback), **then** record collection.
   - `"net"` → require `InventoryService.GetEquipped(player) == "net"` (else fail "Need a net");
     `success = rollCatch(spiritType.catchChance, rng)`; on failure return `(false, 0)` (cooldown still
     set, spirit may remain); on success continue.
3. On success: `isFirst = PlayerDataManager.RecordSpiritCaught(player, spiritType.id)`; if `isFirst` and
   `firstCatchBonus > 0` award it server-side (coins/DreamSeeds) and fire `UpdateCurrency`; fire
   `SpiritCollected`; `QuestService.Track(player, "catch_spirit", 1)`; `IncrementStat`; remove the spirit.

## Server spawn / lantern — `Services/Spirit/SpiritSpawner.lua` + `SpiritManager.lua`

- `buildSpiritModel` handles the new flying-creature visuals (reuse the Orb/particle/prompt pattern; a
  distinct look/colour per rarity via `SpiritConfig.GetColor`).
- Lantern bias: when selecting the spawn-anchor player in `spawnOne`, prefer players with
  `InventoryService.GetEquipped(player) == "lantern"` and spawn within `GameSettings.SpiritSettings.LanternSpawnRadius`
  around them; otherwise the existing `SpawnRadius`. Night-gating via `SpiritManager.SetPhaseNight`
  is unchanged.

## Shovel branch — `ServerScriptService/Services/PlotManager.lua`

In `HandleInteraction`, add after the Harvest branch:
```
if toolName == "shovel" then
  if plot.State == "Empty" then return fail("Nothing to clear") end
  if plot.State == "ReadyToHarvest" then return fail("Harvest it first") end  -- protect the ripe crop
  -- else Planted/Growing/Withered: reset State=Empty, PlantId=nil, GrowthProgress=0, GrowthSeconds=0, IsWatered=false
  -- fire PlotStateChanged + PlotStateUpdated; return ok({Action="Cleared", PlotId=plotId})
end
```
No yield is granted; a ReadyToHarvest plot is rejected (the player harvests instead). `"shovel"` is an owned tool, so `InventoryService.SetEquipped`'s `else`/HasItem
branch already permits equipping it (no allow-list edit).

## Tool definitions — `ReplicatedStorage/ShopConfig.lua` → `buy.tools`

```lua
lantern = { price = <coins>, rarity = "Uncommon", displayName = "Lantern", icon = "" },
net     = { price = <coins>, rarity = "Rare",     displayName = "Net",     icon = "" },
shovel  = { price = <coins>, rarity = "Common",   displayName = "Shovel",  icon = "" },
```
`ItemEmoji.lua` gets fallback glyphs for `lantern`/`net`/`shovel` and the new creatures.
`HotbarController.buildItems` appends each owned tool (after the watering cans + Harvest, before/after
seeds per the existing stable order) so they fill slots 3–5.

## Player data — `ReplicatedStorage/DefaultData.lua` + `PlayerDataManager.lua`

- `SchemaVersion = 4`; add `SpiritCollection = {}` and `Stats.TotalSpiritsCollected = 0`.
- `PlayerDataManager`: add `RecordSpiritCaught(player, typeId) -> isFirst`; include `SpiritCollection`
  in `Snapshot`. Reconcile backfills; `Migrate` stamps the version (non-additive transforms, if any,
  go there).
