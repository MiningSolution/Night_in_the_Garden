# Data Model — Visual Style (Phase 4)

This phase adds **no persisted data** and **no remote payload**. The "entities" below are in-memory
client structures and the shared colour/sound vocabulary. `DefaultData` SchemaVersion stays **3**.

## Palette

A named, complete set of colour roles for one day/night phase. Exactly two exist.

| Field | Type | Notes |
|---|---|---|
| (token key) | `Color3` | One entry per token role (see Token vocabulary). Both palettes define the **same** key set (enforced by `theme.spec.luau`). |

- **Day** — warm "garden" light (owner-confirmed; exact RGBs locked by the mock-up).
- **Night** — today's dark palette, values unchanged.

## Token vocabulary (roles)

The single shared vocabulary used by builders (baked) and the runtime switch (attributes). Full
per-palette values live in [contracts/theme-tokens.md](./contracts/theme-tokens.md).

Surfaces: `Surface`, `SurfaceRaised`, `Header` · Controls: `Control`, `ControlHover` · Semantic:
`Accent`, `Danger` · Text: `TextPrimary`, `TextMuted` · Currency: `Coins` · Rarity:
`RarityCommon`, `RarityUncommon`, `RarityRare`, `RarityEpic`, `RarityLegendary` · Backdrop:
`Backdrop` (+ the existing numeric `BackdropTransparency`, not a palette colour) · Banners:
`BannerNight` · **New in Phase 4**: `PhaseDay`, `PhaseNight` (day/night indicator colours, migrated
out of `UIController`), `Scrim` (the small semi-transparent black hint backgrounds).

## UITheme module (resolver)

`ReplicatedStorage/UITheme.lua` after restructuring:

| Member | Type | Purpose |
|---|---|---|
| `Palettes.Day` / `Palettes.Night` | Palette | The two palettes. |
| `Default` | string | `"Night"` — the palette baked into the static GUI. |
| `Get(phase)` | `(string) -> Palette` | The palette for a phase; falls back to `Default` for unknown/transition. |
| `Resolve(token, phase)` | `(string, string) -> Color3` | `Get(phase)[token]`. |
| `<Token>` (flat) | `Color3` | Back-compat: each default-palette token exposed flat, so existing `UI_THEME.Surface` / `Theme.Coins` readers are unchanged. |

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
