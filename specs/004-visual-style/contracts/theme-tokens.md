# Contract — Theme tokens, palettes, and the attribute scheme

The single colour vocabulary both palettes implement, the attribute scheme the static GUI carries, and
the contrast pairs the offline test enforces. **Night** values are today's palette, unchanged. **Day**
values are the proposed "warm garden" starting point; they are **locked by the mock-up (FR-019) and
must pass the contrast test (R8)** before being written into `UITheme.Day`.

## Token set (both palettes MUST define every key — parity-tested)

| Token | Role | Night (RGB, current) | Day (RGB, proposed — warm garden) |
|---|---|---|---|
| `Surface` | panel / window background | 30, 30, 40 | 245, 238, 222 |
| `SurfaceRaised` | raised tiles (slots, cards) | 40, 40, 50 | 235, 226, 206 |
| `Header` | window header bars | 36, 36, 48 | 226, 214, 188 |
| `Control` | buttons at rest | 60, 60, 70 | 219, 205, 174 |
| `ControlHover` | button hover / focus | 70, 70, 80 | 232, 221, 196 |
| `Accent` | selection / confirm (green) | 80, 200, 120 | 64, 150, 74 |
| `Danger` | destructive / error (red) | 220, 80, 80 | 200, 60, 55 |
| `TextPrimary` | primary text | 255, 255, 255 | 45, 38, 28 |
| `TextMuted` | secondary text | 200, 200, 200 | 90, 82, 64 |
| `Coins` | currency gold (counter, float, prices) | 255, 220, 100 | 140, 94, 10 |
| `RarityCommon` | common tier | 170, 170, 180 | 110, 110, 120 |
| `RarityUncommon` | uncommon tier | 90, 200, 120 | 64, 150, 74 |
| `RarityRare` | rare tier | 80, 150, 240 | 40, 110, 200 |
| `RarityEpic` | epic tier | 170, 110, 240 | 130, 70, 190 |
| `RarityLegendary` | legendary tier | 240, 190, 70 | 190, 140, 30 |
| `Backdrop` | full-screen dim behind a window | 0, 0, 0 | 20, 16, 10 |
| `BannerNight` | nightfall banner background | 40, 50, 92 | 40, 50, 92 |
| `PhaseDay` | day/night indicator — day marker (**new**) | 255, 200, 50 | 255, 200, 50 |
| `PhaseNight` | day/night indicator — night marker (**new**) | 100, 150, 255 | 100, 150, 255 |
| `Scrim` | small hint backgrounds (key/keybind chips) (**new**) | 0, 0, 0 | 20, 16, 10 |

Non-palette companions (unchanged, not colours): `BackdropTransparency = 0.5` stays a numeric field.
The hint-chip transparency stays as each builder sets it; only the chip's `Color3` becomes `Scrim`.

## Attribute scheme (baked by builders, read at runtime)

- Attribute name: `Theme_<RobloxPropertyName>` — one per themed property.
- Attribute value: a token key from the set above (a string).
- Properties in scope: `BackgroundColor3`, `TextColor3`, `ImageColor3`. (Stroke colour, if any
  `UIStroke` is themed, uses `Theme_Color` on the `UIStroke`.)
- Examples: a menu button → `Theme_BackgroundColor3 = "Control"`, `Theme_TextColor3 = "TextPrimary"`;
  a rarity card → `Theme_BackgroundColor3 = "SurfaceRaised"`, a rarity swatch → `Theme_ImageColor3`
  or `Theme_BackgroundColor3 = "RarityRare"` (controllers set the specific rarity token per item; a
  per-item rarity colour set in code uses `ThemeController.Resolve`, not a static attribute).
- Runtime rule: for each `Theme_<Prop>` attribute on an instance, `inst[Prop] = Resolve(value, phase)`
  (tweened on a phase change, instant on creation/join).

## `.model.json` shape

Each node that carries tags gains an `attributes` object after `properties`:

```json
{
  "className": "TextButton",
  "properties": { "BackgroundColor3": [0.235, 0.235, 0.274], "TextColor3": [1, 1, 1], ... },
  "attributes": { "Theme_BackgroundColor3": "Control", "Theme_TextColor3": "TextPrimary" },
  "children": [ ... ]
}
```

The baked colour (`properties`) is the **Night/default** value; the attribute names the token. CI
parity (`build_models.py` ⇄ committed `StarterGui/`) covers both.

## Contrast pairs the offline test enforces (≥ 4.5:1 in BOTH palettes)

Relative-luminance contrast (WCAG 2.x). Each pair is (foreground token, background token):

1. `TextPrimary` on `Surface`
2. `TextPrimary` on `SurfaceRaised`
3. `TextPrimary` on `Header`
4. `TextPrimary` on `Control`
5. `TextPrimary` on `ControlHover`
6. `TextMuted` on `Surface`
7. `Coins` on `Surface`

Rarity tiers are checked for mutual distinguishability (each rarity's luminance differs from the
others' by a visible margin) rather than against a 4.5 bar, since they are accents, not body text. If
any Day value fails, adjust the Day token (darken text/currency, deepen the accent) until it passes —
the test is the gate, not these exact proposed RGBs.
