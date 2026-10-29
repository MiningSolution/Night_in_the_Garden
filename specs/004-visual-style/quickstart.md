# Quickstart — Visual Style (Phase 4) validation

How to prove the feature end-to-end. Offline checks run in CI; V-scenarios are the Studio playtest
(constitution VI). Device-emulator passes (phone landscape + gamepad) are the owner's manual step.

## Prerequisites

- `luau` and `rojo` on PATH; repo synced to Studio via `rojo serve`.
- Remember: Rojo syncs `StarterGui`/`StarterPlayer`/`ReplicatedStorage`; it does **not** sync
  `ServerScriptService` (no server change this phase, so nothing to mirror).
- Day/night cycle lengths are short enough in `GameSettings` to watch a phase flip, or force a phase
  from the command bar (see V3).

## Offline (CI) — must be green before merge

```bash
# 1. Palette + contrast + token parity test
luau Tools/Tests/theme.spec.luau

# 2. Regenerate the static GUI and confirm it matches the committed models (incl. the new attributes)
python3 Tools/StaticGui/build_models.py "$(command -v luau)"
git diff --quiet -- StarterGui && echo "static GUI in sync" || echo "OUT OF SYNC — commit regenerated models"

# 3. Full offline suite (as CI runs it)
for f in Tools/Tests/*.spec.luau; do echo "== $f =="; luau "$f"; done
```

Expected: `theme.spec.luau` passes (both palettes complete, all `Color3`, default = Night, flat
back-compat equals Night, every contrast pair ≥ 4.5:1 in both palettes); `StarterGui` diff clean; the
existing `economy_config` / `responsive_layout` / `retention_config` specs still pass.

## Studio playtest (V0–V9)

- **V0 — Baseline / no regression**: Play. HUD, shop, inventory, sell, daily-reward, quests,
  notifications all look exactly as before at **night** (Night is the baked default). No new Output
  errors or warnings.
- **V1 — Attributes round-trip (gates everything)**: In Studio, select a themed element in
  `StarterGui` (e.g. `HUDControls.MenuButtons.ShopButton`) and confirm it has the baked attribute
  `Theme_BackgroundColor3 = "Control"` (Properties → Attributes, or `inspect_instance` via MCP). If
  attributes are absent, Rojo did not carry them → switch to the `ThemeBindings` fallback (research R2)
  before continuing.
- **V2 — Day look**: Force the Day phase (V3). Every key screen shifts to the warm light palette; text,
  currency and rarity colours are readable; no element is left dark.
- **V3 — Forcing a phase** (helper): from the command bar, fire the client event the controller listens
  to, e.g. `game.ReplicatedStorage.DayNightUpdate:FireClient(game.Players.YourName, "Day", 0)` — or wait
  for the real cycle to flip. (The server broadcasts `("Day"/"Night", progress)` each second.)
- **V4 — Live switch is smooth**: With a window open, let the phase flip Day↔Night. The HUD and the
  open window **ease** from one palette to the other (a short colour tween), with no single-frame flash
  and nothing stuck in the old palette. Flip back and confirm it returns.
- **V5 — Paint on open (closed during switch)**: Change phase while all windows are closed, then open
  shop/inventory/sell/daily/quests. Each opens already in the current palette — no wrong-palette flash.
- **V6 — Dynamic elements**: After a phase change, trigger a toast, open the shop (cloned cards), open
  sell (cloned rows), and sell a crop (floating "+N coins"). Each new element appears in the current
  palette.
- **V7 — Join mid-cycle**: Stop/Play so the character respawns partway through a phase. The HUD shows
  the correct palette from the first moment; no persistent wrong-palette element.
- **V8 — Window-open animation**: Open each window. It eases open (scale + fade, ~0.18 s) and is fully
  interactive immediately. Closing stays instant.
- **V9 — Sounds**: With owner-supplied ids set in `UISound.lua`, tap a main button → short press sound;
  complete a purchase → distinct purchase sound; a rejected buy (can't afford) → **no** purchase sound.
  With the game sound off → no UI sound. With ids left empty → silent, no errors. (Synthetic MCP clicks
  don't fire `Activated`, so press/purchase sounds are verified by a real tap/click — owner's pass.)

## Owner device-emulator pass (manual, after merge-ready)

In the Studio device emulator at **phone landscape**: sweep every key screen in **both** palettes for
contrast and legibility (body text, currency, rarity swatches, muted labels), confirm the live switch
reads well on a phone, and confirm the window-open animation and sounds feel right. Gamepad: confirm
press sound still fires via gamepad activation.

## Notes / known constraints

- No persistence change (SchemaVersion stays 3); no DataStore writes during this playtest.
- The retint runs only on a Day↔Night change, not per frame; equal-phase ticks are no-ops.
- If `theme.spec.luau` flags a Day contrast pair under 4.5:1, deepen that Day token until it passes;
  the proposed Day RGBs in `contracts/theme-tokens.md` are a starting point locked by the mock-up.
