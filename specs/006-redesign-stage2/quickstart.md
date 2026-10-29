# Quickstart / Validation: Cosy-Garden Redesign — Stage 2

How to validate each user story end-to-end. Gameplay rules are in [spec.md](./spec.md); shapes in
[data-model.md](./data-model.md) and [contracts/](./contracts/). Run offline gates first, then the
Studio playtest (Constitution VI) at phone-landscape in BOTH palettes.

## Prerequisites

- Point Rojo at this worktree and connect in Studio (Disconnect→Connect) so the branch's scripts + GUI
  sync. Rojo does NOT sync `ServerScriptService` — mirror server-script changes into Studio (Studio MCP
  `multi_edit`) when testing server behaviour.
- `execute_luau` via the MCP runs in a separate VM from the running game: drive the real server through
  its modules in the Server datamodel where they are shared (e.g. `DayNightManager.currentPhase`),
  and read GUI/world state from instances; player-scoped singletons may not be shared — prefer forcing
  phase/spawn via the server services and observing via instances + console.

## Offline gates (every story)

```bash
# regenerate static GUI and check parity
python3 Tools/StaticGui/build_models.py "$(command -v luau)"
git status --porcelain StarterGui   # must be clean after commit of regenerated models

# run all offline specs (incl. the new spirit catalog/catch-roll spec)
for f in Tools/Tests/*.spec.luau; do luau "$f"; done
```

Expected: all specs pass; `StarterGui/*.model.json` regenerate with no unexpected diff.

## US1 — Tools (lantern / net / shovel)

1. Give the test profile coins; open the Seed Shop **Tools** tab → the three tools show as cards with
   price + rarity badge. Buy each.
2. Owned tools fill hotbar slots 3–5 (icon + name + 1–5 key on PC); an unowned slot stays locked and
   tapping it equips nothing.
3. Equip the **shovel**, click a plot that holds a plant → the plot resets to Empty (no crop granted);
   clicking an empty plot shows a clean reject (no error).
4. Switch day↔night (force via `DayNightManager`) → the three tools keep their slot/size/order and only
   their colours cross-fade.

Expected: SC-001 (all three usable, no dead owned slot). No new Output errors.

## US2 — Capture, creatures, announcement

1. Force night (`DayNightManager.currentPhase = "Night"`) so the spawn loop runs; confirm the new
   Moonmoth/Moth-Spirit types can spawn (optionally `SpiritManager.SpawnOnce("moonmoth")`).
2. On a notable spawn, the rate-limited "✨ A <rarity> <name> appeared!" banner shows (reuses
   `ServerAnnounce`).
3. Approach a flying creature WITHOUT the net equipped → its prompt rejects ("Need a net"). Equip the
   **net**, trigger the prompt → the server rolls the per-rarity chance: on success the creature is
   removed and a catch toast shows; on failure a clean "it got away" and the creature may remain.
4. First catch of a type → a one-time discovery bonus is applied (currency updates from the server);
   a repeat catch of the same type only increments the count (no currency).
5. Existing wisps still collect by walking into their prompt (proximity), unchanged.

Expected: SC-002 (capture fully on-screen), SC-003 (out-of-range / no-net / wrong-target all rejected
server-side, no state change).

## US3 — Collection, Spirits tab, Journal

1. After catching a few spirits, open the Backpack **Spirits** tab → caught spirits show as rarity-badged
   cards (not the "coming soon" placeholder).
2. Open the **Spirit Journal** (from the Spirits detail action / HUD) → every known type listed: caught
   revealed (name, rarity, count, first-caught), uncaught as locked "???"; header shows "N / M
   discovered".
3. Rejoin (stop/restart play) → the collection is intact (reconcile backfills on old profiles; no load
   error).
4. Switch day↔night with the Journal open → it stays put and only colours cross-fade; readable in both
   palettes.

Expected: SC-004 (collection persists across sessions), both-palette readability.

## US4 — Redesigned windows

1. Open Sell / Notifications / Daily-Gift / Quests → each matches the cosy-garden concept (header/card/
   button language + tokens), in both palettes at phone-landscape.
2. Exercise each window's existing actions (sell one / sell all / toggle favourite; claim daily reward;
   claim a quest; see a notification) → all still work through the existing remotes, unchanged behaviour.
3. Check ≥44×44 touch targets, safe-area, and clearance of the movement/jump zones.

Expected: SC-005 (redesigned + still functional), SC-006 (no new Output errors; offline + parity green).

## Test-data note (Constitution VI)

Catching spirits and buying tools writes to the test profile (DreamSeeds/coins spent, `SpiritCollection`
populated, `SchemaVersion` bumped to 4). Reset or call it out in the PR; test on an alt profile to see
the undiscovered/empty states.
