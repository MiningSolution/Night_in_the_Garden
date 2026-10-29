# Contract: Reused Remotes (Stage 2 adds NO new remotes)

This feature adds **no new RemoteEvents/RemoteFunctions** (Constitution I + the project's reuse gate).
Every server-authoritative action goes through a remote/path that already exists in
`ServerScriptService/CreateRemotes.lua`. Below is exactly what each story reuses and the invariants.

## Reused for US1 (tools)

| Remote / path | Type | Use | Invariant |
|---------------|------|-----|-----------|
| `BuyItem` | RF `(category, itemId, qty)` | Buy lantern/net/shovel from the shop Tools tab | client sends only (category,itemId,qty); server charges from `ShopConfig` |
| `EquipTool` | RE `(serverTool)` | Equip a tool to a hotbar slot | client sends only the tool identity; `InventoryService.SetEquipped` validates ownership |
| `InteractWithPlot` | RE `(plotModel, toolName)` | **Shovel** clears a plot | server ignores the sent toolName and uses `InventoryService.GetEquipped`; validates state/range/cooldown |

## Reused for US2 (capture + creatures)

| Remote / path | Type | Use | Invariant |
|---------------|------|-----|-----------|
| spirit `ProximityPrompt` ("CollectPrompt") | server event | Capture a `net` spirit / collect a `proximity` wisp | on-screen button on touch; server branches by the spirit type's `captureMethod` and (for `net`) checks equipped net + rolls catchChance |
| `CollectSpirit` | RF `(spiritId)` | Alternate client-invoked entry to the same `tryCollect` (available, used only if a non-prompt path is needed) | server revalidates everything; never trusts the client |
| `ServerAnnounce` | RE `(kind, name, rarity)` | "✨ A <rarity> <name> appeared!" on a notable spawn | rate-limited; reuses the existing feedback path (feature 003) |
| `SpiritCollected` | RE S→C `(name, rarity, amount)` | Catch/collect feedback toast | server-sent only |
| `UpdateCurrency` | RE S→C | Reflect first-catch bonus / wisp reward | server-sent only |

## Reused for US3 (collection + Journal)

| Remote / path | Type | Use | Invariant |
|---------------|------|-----|-----------|
| `GetPlayerData` | RF → snapshot | Journal + Spirits tab read the player's `SpiritCollection` | snapshot EXTENDED with `SpiritCollection` (a new field on the existing payload, not a new remote) |

The full known spirit set (for undiscovered Journal entries) is read client-side from
`ReplicatedStorage/SpiritData.lua` (static catalog metadata, not live state).

## Reused for US4 (window redesign)

No remote changes. `SellItem`/`SellAll`/`ToggleFavourite` (Sell), `GetDailyReward`/`ClaimDailyReward`
(Daily-Gift), `GetQuests`/`ClaimQuest` (Quests) and the Notifications layer keep their current
signatures and behaviour; only the GUI structure/theme changes.

## Gate

If any story appears to need a new remote or a new server-trusted computation, STOP and revisit the plan
— the design above is specifically structured to avoid it.
