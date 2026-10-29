# Research — Visual Style (Phase 4)

Decisions that resolve every unknown in the plan's Technical Context. Each: Decision · Rationale ·
Alternatives considered.

## R1. Palette structure in `UITheme.lua` (single source for both palettes)

**Decision**: Restructure `UITheme.lua` to hold two complete palettes behind one module, keeping the
current flat API as a back-compat shim:

```lua
local function c(r,g,b) return Color3.fromRGB(r,g,b) end
local Night = { Surface=c(17,31,59), ..., HeaderTop=c(21,55,104), HeaderBottom=c(11,31,66) } -- indigo "moonlit" (v2)
local Day   = { Surface=c(255,243,213), ..., HeaderTop=c(35,107,41) }                        -- warm "garden" (v2)
local UITheme = {}
for k, v in pairs(Night) do UITheme[k] = v end          -- flat keys = Night (back-compat)
UITheme.Header, UITheme.BannerNight, UITheme.BackdropTransparency = Night.HeaderTop, c(40,50,92), 0.5 -- legacy aliases
UITheme.Palettes = { Day = Day, Night = Night }
UITheme.DefaultPhase = "Night"
UITheme.Style = { CornerRadius=12, OutlineThickness=2.5, WindowOutlineThickness=3.5, ButtonShadowOffset=4,
                  DisplayFont=Enum.Font.FredokaOne, BodyFont=Enum.Font.Gotham, BackdropTransparency=0.5 }
function UITheme.Resolve(token, phase) return (UITheme.Palettes[phase] or Night)[token] end
return UITheme
```

**Rationale**: Both palettes live once (II), plus the non-colour style constants (single source for
corner radius, outline thickness, shadow offset, fonts). Every existing reader keeps working: builders
do `UI_THEME.Surface` and controllers do `Theme.Coins` — both now resolve to the flat (Night) value,
so screens not yet re-skinned still render. Unlike the earlier draft, **Night is re-skinned** (indigo,
per the approved v2 look), so the static GUI *does* regenerate with a large, intentional colour diff;
legacy aliases (`Header`, `BannerNight`, `BackdropTransparency`) keep un-re-skinned screens coherent in
the new night palette. New runtime code uses `Resolve(token, phase)` and `UITheme.Style`.

**Alternatives**: (a) Two separate modules `DayTheme`/`NightTheme` — splits the vocabulary, risks key
drift, breaks the `UI_THEME` global the generator injects. (b) Keep flat + a parallel `DayOverrides`
table — asymmetric, easy to forget a key. Rejected: one symmetric `Palettes` table with a parity test
(R8) is simplest and safest.

## R2. Carrying the token binding from build time to runtime — **attribute tags** (the crux)

**Decision**: Builders tag each themed property of each element with a Roblox **attribute**
`Theme_<PropertyName> = "<TokenName>"` (e.g. `Theme_BackgroundColor3 = "Control"`,
`Theme_TextColor3 = "TextPrimary"`, `Theme_ImageColor3 = "Accent"`). A 3-line local helper in each
builder bakes the default colour **and** sets the attribute:

```lua
local function themeBind(obj, prop, token) obj[prop] = Theme[token]; obj:SetAttribute("Theme_"..prop, token) end
```

The generator is extended (R7) to record `SetAttribute` and emit an `attributes` map into each
`.model.json` node. At runtime `ThemeController` walks `root:GetDescendants()`, and for each attribute
whose name starts `Theme_`, tweens `inst[prop]` to `UITheme.Resolve(token, phase)`.

**Rationale**: The binding is **co-located** with the element and expressed only in the single token
vocabulary (II/V); the runtime switch is one generic loop with zero per-element code; nothing is
duplicated. Rojo delivers the attributes with the static GUI, so the repo stays the source (III).

**Verification-first**: Rojo 7.7.1's application of baked attributes in Studio is confirmed as the
**first implement step** (quickstart V1) before anything is built on it.

**Fallback (documented)**: if Rojo does not carry the attributes into Studio, fall back to a single
`ThemeBindings.lua` map (ScreenGui → element-name-path → {prop → token}) that `ThemeController`
applies — same runtime loop, binding sourced from one module instead of attributes. Chosen only if V1
fails; it is more code and drifts on renames, so it is the fallback, not the default.

**Alternatives**: runtime bindings map as primary (R2 fallback — rejected for II/V + drift);
regenerate models per phase (rejected by III + FR-006); hijack `Name`/a string property (rejected —
`Name` is used for lookups).

## R3. Live switch — when and how to retint

**Decision**: `ThemeController` subscribes to `DayNightUpdate(phase, progress)` (already fired ~1 Hz by
`DayNightManager`). It keeps `currentPhase`; when `phase` is `"Day"`/`"Night"` and **differs** from
`currentPhase`, it runs one `Repaint(phase)` pass and updates `currentPhase`. `Repaint` walks the known
ScreenGuis' descendants and, per `Theme_*` attribute, starts a `TweenService` colour tween
(`~0.4 s`, `Quad`/`Out`) to the new palette value. Equal-phase ticks do nothing.

**Rationale**: Phase changes are infrequent, so a once-per-change walk is cheap (no per-frame work, VI
performance). Tweening `Color3` gives the "smooth, no flash" requirement (FR-005, SC-002). Reusing the
existing event means no new remote and no new cadence (VII).

**Alternatives**: per-frame interpolation across the whole `progress` (rejected — needless per-frame
cost, and the spec wants the switch *on the change*, not a continuous crossfade over the whole phase);
`RunService.Heartbeat` polling of the phase (rejected — `DayNightUpdate` already pushes it).

## R4. Dynamic elements (toasts, cloned rows/cards, floating coins) and join

**Decision**: Two helpers on `ThemeController`: `PaintInstant(inst)` applies the current palette with
**no** tween (for a just-created element, so it never flashes), and `Paint(root)` does the same for a
subtree. Static templates carry the `Theme_*` attributes, so a clone is painted by one
`PaintInstant(clone)` call at the creation site (ToastQueue show, Shop/Sell/Daily/Quest row+card
clone). Code that colours by hand (`UIController.FloatCoins`) reads `ThemeController.Current().Coins`.
On join, `ThemeController.Initialize()` paints the known GUIs to the initial phase from
`StateManager.getDayNight()` before the first `DayNightUpdate`, so the HUD shows correctly from the
first frame (FR-009).

**Rationale**: Covers FR-008/009 with the same attribute vocabulary; a clone inherits its template's
tags for free. One instant paint at creation avoids a wrong-palette frame.

**Alternatives**: a global `DescendantAdded` listener that auto-paints every new instance (rejected —
fires for non-themed instances too and is harder to reason about than an explicit paint at the few
known clone sites).

## R5. Day palette — "warm garden" direction and contrast (owner-confirmed)

**Decision**: Day = warm, low-saturation parchment/cream surfaces with warm **dark** text and soft
green/gold accents; Night = deep indigo/navy "moonlit" surfaces with light text and blue/gold accents
(re-skinned — NOT the old flat grey). Both palettes' exact RGBs are locked by the **approved v2
mock-up** (gate, FR-019, now satisfied) and transcribed into `contracts/theme-tokens.md` → `UITheme`.
Both palettes are designed to **WCAG-AA 4.5:1** for body text and currency on their own surface,
verified by the offline contrast
test (R8) and a Studio phone-landscape check. Rarity tiers keep their hue identity in both palettes,
re-tuned for lightness so they stay distinguishable on a light surface (e.g. Common grey darkens on
cream; Legendary gold deepens so it reads on cream).

**Rationale**: Matches the cozy farming/garden genre and the owner's choice; the contrast bar is
objective and testable (SC-003, FR-010/011).

**Alternatives**: neutral light / sky-blue (owner rejected). A single "auto-lighten the night palette"
transform (rejected — produces muddy, low-contrast colours and no real design control).

## R6. Feedback — sounds and window-open animation

**Decision**:
- `UISound.lua`: `{ Press = "", Purchase = "", Volume = 0.5 }` (ids owner-supplied; empty = silent).
- `SoundController`: one reusable `Sound` under `SoundService`; `Press()` is rate-limited (ignore
  re-trigger within ~60 ms) and re-plays cleanly; `Purchase()` plays the distinct id. Both no-op on an
  empty/invalid id (wrapped in `pcall`), and no-op when the game sound setting is off
  (`SoundService.RespectFilteringEnabled` is unrelated — use a single `UISound`-level mute check tied
  to the project's sound setting / `GuiService` or a muted master `SoundGroup`). Volume from `UISound`.
- **Press** rides existing `Activated` connections on the main buttons (menu, teleport, tabs, buy,
  sell, claim, close), added where each controller owns the button. **Purchase** is played by
  `ShopController` only on the server-confirmed success path of `BuyItem` (I).
- **Window-open animation**: `GuiEffects.openWindow(frame)` sets the frame to ~0.92 scale + higher
  transparency, then tweens to full over ~0.18 s ease-out; called from `WindowManager.Open` after the
  frame is shown. The window is interactive throughout; the tween only affects visuals (FR-015).

**Rationale**: One sound source (II); server-gated success sound (I); feedback never blocks the action
(FR-016) and degrades silently (missing asset). Reuses `TweenService`/`GuiEffects` (VII).

**Alternatives**: a `Sound` per button (rejected — many instances, no central volume/mute); animating
on `Visible` via a property listener (rejected — the open path is explicit in `WindowManager`, simpler
to hook there).

## R7. Generator extension for attributes (`GuiRecorder` + `build_models.luau`)

**Decision**: In `GuiRecorder.new`, the proxy handles `obj:SetAttribute(name, value)` by recording
into `node.attrs`/`node.attrKeys` (and `real:SetAttribute` in Studio mode); `toModel` emits
`m.attributes = { name = value }`; `R.fingerprint` includes attributes so Studio parity holds. In
`build_models.luau`, `encode()` learns the `attributes` key, placed **after `properties`, before
`children`**, emitting each attribute value in Rojo's implicit form (our values are strings:
`"attributes": { "Theme_BackgroundColor3": "Control" }`).

**Rationale**: Smallest change that makes the attribute tags round-trip deterministically; the CI
parity check (`build_models.py` then `git diff StarterGui`) then guarantees committed models match the
builders.

**Alternatives**: hand-edit `.model.json` to add attributes (rejected — breaks the generator-is-source
rule III and CI parity). A post-process script (rejected — a second tool to keep in sync).

## R8. Offline test for palettes and contrast

**Decision**: `Tools/Tests/theme.spec.luau` (same harness as the other specs, no `game` global — it
stubs `Color3.fromRGB`): asserts (1) `Day` and `Night` define the **same** set of token keys;
(2) every token value is a `Color3`; (3) `Default == "Night"` and the flat back-compat fields equal
`Get("Night")`; (4) for each (foreground, background) pair listed in `contracts/theme-tokens.md`, the
WCAG relative-luminance contrast ratio is ≥ 4.5 in **both** palettes. Wired into CI's existing
`Tools/Tests/*.spec.luau` loop.

**Rationale**: Turns FR-002/010/011 and SC-003 into an automated gate, matching the project's
config-parity test style. Catches a missing token or a low-contrast Day colour before Studio.

**Alternatives**: visual-only check in Studio (rejected — not reproducible in CI; contrast math is
cheap and deterministic).

## R9. Which colours become tokens (migration scope)

**Decision**: On every touched screen, migrate hard-coded theme colours to tokens: the day/night
**indicator** phase colours in `UIController` (yellow `255,200,50` → `PhaseDay`, blue `100,150,255` →
`PhaseNight`), the small semi-transparent **black scrims** on key/keybind hints (`Color3.new(0,0,0)` →
a `Scrim` token with its transparency kept as-is), and any remaining literal `Color3` in builders.
Genuinely non-theme colours (e.g. a texture tint that must stay fixed) are left and noted. The coin
`TextStrokeColor3 = black` on floats stays (an outline, not a surface) — documented, not a violation.

**Rationale**: Satisfies FR-012/SC-001 ("no hard-coded theme colour on touched screens") while not
over-tokenising incidental outlines.

**Alternatives**: migrate literally every `Color3` including outlines (rejected — adds tokens with no
palette meaning; YAGNI, VII).

## R10. No server or persistence change

**Decision**: The feature consumes `DayNightUpdate` and the existing `BuyItem` success path only. No
new remote, no `DefaultData` schema bump (stays SchemaVersion 3), no DataStore writes.

**Rationale**: Visual/feedback only; keeps the PR small (VII) and avoids any persistence risk (VI).

**Alternatives**: persist a per-player "reduce motion"/"mute UI" preference (rejected for this phase —
not requested; the game's existing sound setting is honoured and motion is kept short; revisitable).
