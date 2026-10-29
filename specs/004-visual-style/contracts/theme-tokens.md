# Contract — Theme tokens, palettes, and the attribute scheme

The single colour/style vocabulary both palettes implement, the attribute scheme the static GUI
carries, and the contrast pairs the offline test enforces.

**Approved direction (FR-019 gate, 2026-10-29).** The owner approved the "cosy garden by day,
moonlit magic by night" direction and supplied `Garden_UI_Day_Night_v2.html` + handoff as the
reference. The values below are **transcribed from that handoff (§4)**; gaps it does not name are
**derived** from the direction and marked `(derived)` — they are confirmed by the contrast test (R8)
and the Studio mock-up pass, not re-chosen freely.

> **This re-skins night as well as adding day.** Night moves from the old flat grey to a deep
> indigo/navy. So the "V0 = identical at night" baseline from the earlier draft no longer holds; V0
> becomes "night looks like the approved night mock-up, no errors." The static-GUI diff is expected to
> be large (new colours + strokes + gradients + font on every screen).

## Core palette tokens (both palettes MUST define every key — parity-tested)

RGB values. Day / Night transcribed from handoff §4 where given.

| Token | Role | Day (RGB) | Night (RGB) | Source |
|---|---|---|---|---|
| `Surface` | panel / window background | 255, 243, 213 | 17, 31, 59 | §4 |
| `SurfaceRaised` | raised tiles / cards | 234, 219, 185 | 32, 51, 77 | §4 |
| `TextPrimary` | primary text | 48, 42, 28 | 245, 244, 233 | §4 |
| `TextMuted` | secondary text | 104, 91, 66 | 185, 201, 223 | §4 |
| `TextOnBright` | dark text on bright gold fills (coin pill) | 32, 28, 16 | 32, 28, 16 | §4 note (dark on bright) |
| `TextOnAccent` | light label on a primary (Accent) button | 245, 244, 233 | 245, 244, 233 | (derived; large-bold ≥3:1) |
| `TextOnHeader` | light title on the dark header gradient | 245, 244, 233 | 245, 244, 233 | (derived; large-bold ≥3:1) |
| `Control` | neutral / secondary button at rest | 219, 205, 174 | 42, 64, 96 | (derived) |
| `ControlHover` | neutral button hover / focus | 240, 229, 204 | 54, 80, 116 | (derived) |
| `Accent` | primary action / confirm / selection | 43, 146, 31 | 22, 107, 179 | §4 primary button (green day / blue night) |
| `AccentDeep` | primary-button gradient bottom + 3D shadow | 24, 102, 21 | 16, 69, 116 | §4 primary button |
| `Positive` | seed / garden "grow" semantic (always green) | 43, 146, 31 | 90, 200, 120 | §3 rule 4 (derived for night) |
| `Sell` | sell / stall action (always orange) | 196, 110, 30 | 214, 140, 60 | §3 rule 4 (derived) |
| `Danger` | destructive / error (red) | 200, 60, 55 | 224, 96, 96 | (derived) |
| `Coins` | currency gold (counter, float, prices) | 150, 100, 12 | 255, 218, 123 | (derived; night = §4 legendary gold) |
| `Backdrop` | full-screen dim behind a window | 20, 16, 10 | 4, 10, 22 | (derived) |

## Rarity tokens (per palette — handoff gives day/night text colours)

| Token | Day (RGB) | Night (RGB) | Source |
|---|---|---|---|
| `RarityCommon` | 110, 102, 86 | 150, 162, 182 | (derived) |
| `RarityUncommon` | 43, 146, 31 | 90, 200, 120 | (derived) |
| `RarityRare` | 16, 92, 166 | 143, 211, 255 | §4 |
| `RarityEpic` | 113, 49, 163 | 212, 173, 255 | §4 |
| `RarityLegendary` | 121, 80, 10 | 255, 218, 123 | §4 |

## Structural / design-language tokens (new this phase — the "juicy" look)

The approved look is not flat fills: panels and buttons carry a thick outline, a soft bottom shadow,
a top-to-bottom gradient, and a bold rounded display font. These are tokens too (single source), so a
phase switch retints them along with the flat colours.

| Token | Role | Day (RGB) | Night (RGB) | Source |
|---|---|---|---|---|
| `Outline` | card / tile stroke | 197, 178, 134 | 64, 94, 132 | §4 card outline |
| `OutlineDeep` | window / header stroke | 36, 69, 35 | 6, 23, 46 | §4 window outline |
| `HeaderTop` | header gradient top | 35, 107, 41 | 21, 55, 104 | §4 header |
| `HeaderBottom` | header gradient bottom | 18, 69, 28 | 11, 31, 66 | §4 header |

Non-colour style constants (single source, not per-palette):

```
OutlineThickness   = 2.5    -- UIStroke on cards; windows/headers use ~3.5
ButtonShadowOffset = 4      -- px the AccentDeep 3D shadow sits below a button
DisplayFont        = Enum.Font.FredokaOne  -- bold rounded display face (fallback GothamBold)
BodyFont           = Enum.Font.GothamMedium
CornerRadius       = 12     -- px, chunky rounded corners
BackdropTransparency = 0.5
```

## Attribute scheme (baked by builders, read at runtime)

- Attribute name: `Theme_<RobloxPropertyName>` — one per themed property.
- Attribute value: a token key from the sets above (a string).
- Properties in scope: `BackgroundColor3`, `TextColor3`, `ImageColor3`; a themed `UIStroke` uses
  `Theme_Color = "<token>"` on the stroke; a themed two-stop `UIGradient` uses
  `Theme_GradientTop` / `Theme_GradientBottom` on the gradient's parent (controller rebuilds the
  `ColorSequence` from the two tokens).
- Examples: a menu button → `Theme_BackgroundColor3 = "Control"`, `Theme_TextColor3 = "TextPrimary"`;
  a window header → `Theme_GradientTop = "HeaderTop"`, `Theme_GradientBottom = "HeaderBottom"`, its
  stroke → `Theme_Color = "OutlineDeep"`; a per-item rarity colour is set in code via
  `ThemeController.Resolve`, not a static attribute.
- Runtime rule: for each `Theme_<Prop>` attribute on an instance, `inst[Prop] = Resolve(value, phase)`
  (tweened on a phase change, instant on creation/join).

## `.model.json` shape

Each node that carries tags gains an `attributes` object after `properties`:

```json
{
  "className": "TextButton",
  "properties": { "BackgroundColor3": [0.169, 0.42, 0.702], "TextColor3": [0.961, 0.957, 0.914] },
  "attributes": { "Theme_BackgroundColor3": "Accent", "Theme_TextColor3": "TextPrimary" }
}
```

The baked colour (`properties`) is the **Night/default** value; the attribute names the token. CI
parity (`build_models.py` ⇄ committed `StarterGui/`) covers properties **and** attributes.

## Contrast pairs the offline test enforces (WCAG 2.x, BOTH palettes)

Relative-luminance contrast. Each pair is (foreground token, background token). Two tiers per WCAG AA:
**body/currency text ≥ 4.5:1**, **large bold display text (button labels, header titles) ≥ 3:1**.

Body / currency (≥ 4.5:1):

1. `TextPrimary` on `Surface`
2. `TextPrimary` on `SurfaceRaised`
3. `TextPrimary` on `Control`
4. `TextPrimary` on `ControlHover`
5. `TextMuted` on `Surface`
6. `Coins` on `Surface` (currency number)

Large bold display (≥ 3:1):

7. `TextOnAccent` on `Accent` (primary-button label)
8. `TextOnHeader` on `HeaderBottom` (header title, darkest gradient stop)
9. `TextOnHeader` on `HeaderTop` (header title, lightest gradient stop)

Header titles and button labels use the light `TextOnHeader` / `TextOnAccent` tokens (the header bar and
primary button are dark/saturated fills in both palettes), not `TextPrimary`.

Rarity tiers are checked for mutual distinguishability (each tier differs from the others by a squared
RGB-distance margin) rather than against a contrast bar, since they are accents, not body text. If any
value fails, deepen that token until it passes — the test is the gate, not the exact RGBs above.
