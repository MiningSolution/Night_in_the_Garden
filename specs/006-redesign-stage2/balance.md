# Balance: Cosy-Garden Redesign — Stage 2

Single source for the numeric values of Feature 006. These are **initial values to tune in Studio**
(Constitution VI); the config modules MUST take their numbers from here (Constitution II), and
`Tools/Tests/spirit_config.spec.luau` checks the catalog against the ranges below. Where a value depends
on an existing `GameSettings` number (e.g. `SpawnRadius`), confirm it in Studio before finalizing.

## Tool prices (coins) — `ShopConfig.buy.tools`

| Tool | id | price | rarity |
|------|------|------:|--------|
| Shovel | `shovel` | 60 | Common |
| Lantern | `lantern` | 120 | Uncommon |
| Net | `net` | 200 | Rare |

(Reference: `improved_watering_can` = 50. The net is the priciest — it gates the capture loop.)

## Catch chance by rarity — net capture (`SpiritData.catchChance`)

Probability of success per net attempt, by the spirit's rarity tier (rarer = lower). Per-type values
pull from this table; a type may override.

| Rarity | catchChance |
|--------|------------:|
| Common | 0.80 |
| Uncommon | 0.60 |
| Rare | 0.40 |
| Epic | 0.25 |
| Legendary | 0.15 |

## New spirit types — `ReplicatedStorage/SpiritData.lua`

Existing wisps are unchanged (`captureMethod="proximity"`, no catchChance/bonus): `wisp_common`
(weight 70), `wisp_rare` (25), `wisp_epic` (5). New night creatures (`captureMethod="net"`):

| id | displayName | rarity | weight | catchChance | firstCatchBonus |
|----|-------------|--------|-------:|------------:|----------------:|
| `moonmoth` | Moonmoth | Uncommon | 22 | 0.60 | 30 |
| `moth_spirit` | Moth-Spirit | Rare | 10 | 0.40 | 60 |

- `firstCatchBonus` is a one-time discovery reward in **Dream Seeds** (thematic with spirits), applied
  on the first catch of that type only; repeat catches of a `net` type grant no currency (count only).
- Weights join the existing wisp pool (total becomes 70+25+5+22+10 = 132 → Moonmoth ≈17%, Moth ≈8%).
  Spawning is night-only (unchanged gate).

## Lantern spawn bias — `GameSettings.SpiritSettings`

| Key | value | meaning |
|-----|------:|---------|
| `LanternSpawnRadius` | 20 | studs; spawn radius around a lantern-equipped player (should be < the existing `SpawnRadius` — confirm its value in GameSettings) |
| `LanternAnchorWeight` | 3 | a lantern-equipped player is this many times more likely to be chosen as the spawn anchor |

## Notes

- All values above are starting points; tune in the Studio playtest (spawn feel, catch difficulty,
  tool affordability) and keep this file in sync with the config modules.
- No balance number may be duplicated in controllers/builders (Constitution II) — they read config,
  config reads these values.
