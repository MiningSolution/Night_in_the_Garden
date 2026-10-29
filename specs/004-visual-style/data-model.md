# Data Model — Visual Style (Phase 4)

This phase adds **no persisted data** and **no remote payload**. The "entities" below are in-memory
client structures and the shared colour/sound vocabulary. `DefaultData` SchemaVersion stays **3**.

## Palette

A named, complete set of colour roles for one day/night phase. Exactly two exist.

| Field | Type | Notes |
|---|---|---|
| (token key) | `Color3` | One entry per token role (see Token vocabulary). Both palettes define the **same** key set (enforced by `theme.spec.luau`). |

- **Day** — warm "garden" light (approved v2; exact RGBs in the contract).
- **Night** — deep indigo "moonlit" dark (re-skinned, approved v2; NOT the old flat grey).

## Token vocabulary (roles)

The single shared vocabulary used by builders (baked) and the runtime switch (attributes). Full
per-palette values live in [contracts/theme-tokens.md](./contracts/theme-tokens.md).

Surfaces: `Surface`, `SurfaceRaised` · Controls: `Control`, `ControlHover` · Semantic: `Accent`,
`AccentDeep`, `Positive`, `Sell`, `Danger` · Text: `TextPrimary`, `TextMuted`, `TextOnBright` ·
Currency: `Coins` · Rarity: `RarityCommon`, `RarityUncommon`, `RarityRare`, `RarityEpic`,
`RarityLegendary` · Backdrop: `Backdrop` · Structural (the "juicy" look): `Outline` (card stroke),
`OutlineDeep` (window stroke), `HeaderTop`/`HeaderBottom` (header gradient stops). Legacy aliases kept
for un-re-skinned screens: `Header`, `BannerNight`, numeric `BackdropTransparency`. Non-colour **style
constants** live in `UITheme.Style` (corner radius, outline thickness, shadow offset, display/body
font) — single source, not per-palette.

## UITheme module (resolver)

`ReplicatedStorage/UITheme.lua` after restructuring:

| Member | Type | Purpose |
|---|---|---|
| `Palettes.Day` / `Palettes.Night` | Palette | The two palettes. |
| `DefaultPhase` | string | `"Night"` — the palette baked into the static GUI. |
| `Resolve(token, phase)` | `(string, string) -> Color3` | `(Palettes[phase] or Night)[token]`; nil for an unknown token. |
| `Style` | table | Non-colour style constants: `CornerRadius`, `OutlineThickness`, `WindowOutlineThickness`, `ButtonShadowOffset`, `DisplayFont`, `BodyFont`, `BackdropTransparency`. |
| `<Token>` (flat) | `Color3` | Back-compat: each Night token exposed flat, so existing `UI_THEME.Surface` / `Theme.Coins` readers are unchanged. |

## Themed element binding (attribute)

Baked into each static GUI element by the builders, read at runtime.

| Field | Type | Notes |
|---|---|---|
| attribute name | string | `Theme_<PropertyName>`, e.g. `Theme_BackgroundColor3`, `Theme_TextColor3`, `Theme_ImageColor3`. |
| attribute value | string | A token key from the vocabulary, e.g. `"Control"`. |

- One element may carry several (`Theme_BackgroundColor3` + `Theme_TextColor3`).
- Runtime rule: for each `Theme_<Prop>` attribute, `inst[Prop]` is driven by `Resolve(value, phase)`.
- Cloned templates inherit their attributes, so a clone is themed by one `PaintInstant(clone)` call.

## Active phase (transient client state)

| Field | Type | Notes |
|---|---|---|
| `currentPhase` | `"Day"` \| `"Night"` | Held by `ThemeController`; initialised from `StateManager.getDayNight()`, updated on each `DayNightUpdate` where the phase value actually changes. Not persisted. |

**Transitions**: `Day → Night` and `Night → Day` each trigger one `Repaint` (tweened). A
`"Transition"`/unknown phase value does not repaint (keeps the last concrete palette). Equal-phase
ticks are no-ops.

## UI sound set (config)

`ReplicatedStorage/UISound.lua`:

| Field | Type | Notes |
|---|---|---|
| `Press` | string (asset id) | Owner-supplied; `""` → silent. |
| `Purchase` | string (asset id) | Owner-supplied; `""` → silent. |
| `Volume` | number | One volume for all UI sounds. |

`SoundController` state: one reusable `Sound`, a `lastPressAt` timestamp for rate-limiting, and a mute
check tied to the project's single sound setting.

## Relationships

- `Palette` keys ⟷ `Token vocabulary` (both palettes cover the whole vocabulary — parity-tested).
- `Themed element binding.value` ∈ `Token vocabulary` (an attribute names a token).
- `ThemeController` reads `UITheme` (palettes/resolver) + `DayNightUpdate` (phase) + the baked
  attributes; it writes only `Color3` properties of existing instances.
- `SoundController` reads `UISound`; it is triggered by button `Activated` (press) and by
  `ShopController`'s server-confirmed buy (purchase).
- No entity here is read or written by the server; none is persisted.
