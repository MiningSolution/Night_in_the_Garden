# Implementation Plan: Visual Style — Day/Night Design System (UI Plan, Phase 4)

**Branch**: `004-visual-style` | **Date**: 2026-10-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/004-visual-style/spec.md`

## Summary

Give the interface the game's day/night identity (constitution principle V). Three independently
testable slices:

1. **Two-palette theme + live switch (P1)** — restructure `ReplicatedStorage/UITheme.lua` from a flat
   dark palette into two complete palettes (**Day** = warm "garden" light, **Night** = deep "moonlit"
   indigo — both re-skinned per the approved v2 look), plus non-colour **style constants** (corner
   radius, outline thickness, shadow offset, display/body font), behind one module that resolves a
   token to a colour for a given phase. The **static GUI stays baked with the Night palette** (the game
   starts in Day, so the client applies Day on the first tick), so builders keep reading one source.
   Builders additionally **tag** each themed property of each element with a Roblox **attribute** naming
   its token (`Theme_<PropertyName> = "<Token>"`; a `UIStroke` uses `Theme_Color`, a `UIGradient` uses
   `Theme_GradientTop`/`Theme_GradientBottom`), emitted into the `.model.json` by a small generator
   extension. At runtime a new `ThemeController` listens to the existing `DayNightUpdate` event and, on
   a Day↔Night change, walks the tagged elements and **tweens** each tagged colour (rebuilding gradient
   `ColorSequence`s) to the active palette — no model regeneration, no re-clone (FR-005/006).
   Dynamically created elements (toasts, cloned rows, shop/sell cards, floating coins) are painted to
   the current phase on creation (FR-008). A player joining mid-cycle is painted as the HUD appears
   (FR-009).
2. **Readable, consistent, fully tokenised screens (P2)** — define the Day palette for WCAG-AA
   contrast on a phone, give both palettes distinguishable rarity/semantic hues (FR-010/011), and
   migrate every remaining hard-coded theme colour on the touched screens to tokens (FR-012). The
   day/night **indicator**'s own phase colours (currently hard-coded yellow/blue) become tokens too.
3. **Tactile feedback (P3)** — a single `UISound` config (owner-supplied press/purchase asset ids, one
   volume) played by a new `SoundController`: a short **press** sound on main-button activation
   (FR-013), a distinct **purchase** sound when the server confirms a buy (FR-014); an unset id plays
   nothing (FR-016). A **window-open animation** (scale + fade ease-in) added to the window open path
   in `WindowManager`/`GuiEffects` (FR-015). None of it blocks or delays the action; all respect the
   game sound setting (FR-016/017) and rapid taps don't stack (FR-018).

**Blocking gate (FR-019)**: before any themed-UI code, produce mock-ups of the seven key screens (HUD,
shop, inventory, sell, notifications/banners, daily reward, quests) in **both** palettes and get the
owner's approval. The mock-up locks the Day palette's exact colours, which then seed `UITheme.Day`.

Nothing here touches gameplay, economy, server validation, persisted data or any remote contract — it
is client/GUI only. Server authority (I) is untouched; config stays single-source (II); the GUI stays
static through the builders (III); the UI stays mobile-first/input-agnostic (IV); theme tokens drive
every colour (V).

## Technical Context

**Language/Version**: Luau (Roblox client); Python 3 for the GUI generator driver. No server Luau
changes expected (the phase is already broadcast).

**Primary Dependencies**: Roblox services — `TweenService`, `SoundService`, `RunService`, `Players`,
`StarterGui`; GUI instances `UIStroke`/`UIGradient`/`UICorner` (the "juicy" outline/gradient/rounded
look) baked by the builders and retinted by `ThemeController`; Rojo 7.7.1; existing client modules (`UIController`, `WindowManager`, `GuiEffects`,
`ToastQueue`, `StateManager`, `ClientDataCache`, the per-screen controllers) and the existing
`DayNightUpdate` RemoteEvent fired each second by `DayNightManager`.

**Storage**: none. No ProfileService schema change (`DefaultData` SchemaVersion stays **3**). The
active phase is transient client state derived from `DayNightUpdate`; nothing new is persisted.

**Testing**: a new offline Luau check `Tools/Tests/theme.spec.luau` — both palettes define the same
complete set of token keys, every token is a `Color3`, the baked default is `Night`, the
back-compat flat accessors equal the default palette, and the WCAG-AA contrast pairs listed in
`contracts/theme-tokens.md` meet 4.5:1 (pure math, no `game` global). Plus `build_models.py`
regeneration parity (CI diffs `StarterGui/`), and Studio playtests V0–V9 (see
[quickstart.md](./quickstart.md)).

**Target Platform**: Roblox — phones/tablets (landscape) first, PC; console via gamepad emulation.

**Project Type**: Roblox game, Rojo-synced repository (client + static GUI).

**Performance Goals**: no per-frame theming. The retint runs only on a Day↔Night **change** (roughly
once per phase length), walking ~8 ScreenGuis once and starting short tweens; the per-second
`DayNightUpdate` is a cheap equality check when the phase is unchanged. Window-open and colour tweens
are < ~0.4 s and eased. Dynamic elements are painted once at creation.

**Constraints**: both palettes keep body text and currency at ≥ 4.5:1 contrast on a phone; feedback
must never block/delay/alter an action and must fail silently on a missing sound asset; sounds honour
the single volume/setting; the static-GUI parity (generator ⇄ committed `.model.json`) must stay green;
StreamingEnabled is on (wait for GUIs).

**Scale/Scope**: `UITheme.lua` restructured (two palettes + resolver + style constants + back-compat) —
the single source for colour and style; 1 new config `ReplicatedStorage/UISound.lua`; 2 new client
modules (`ThemeController`, `SoundController`); small edits to `WindowManager`/`GuiEffects` (open
animation), `UIController` (tokenise the day/night indicator; paint-on-join; FloatCoins reads active
palette), `ToastQueue` and the per-screen controllers (paint dynamic clones, play purchase sound); all
8 builders gain token **attribute tags** plus the approved **design language** (UIStroke outline +
bottom-shadow frame, UIGradient on headers/buttons, UICorner, display/body font) — PR1 re-skins HUD/
HUDControls/Shop/Inventory, PR2 the rest; a small `GuiRecorder`/`build_models.luau` extension to
record and emit attributes; 1 new offline test. 3 user stories across P1–P3. Mock-up gate already
approved. All unknowns resolved in [research.md](./research.md) R1–R10.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Server-authoritative | Pure client/GUI feature. No remote is added or changed; no economy, inventory, plot or spirit state is computed on the client. The purchase sound is triggered **only** by the server's existing success confirmation of `BuyItem` (the client does not decide success); the day/night phase that drives the palette is owned and broadcast by the server (`DayNightManager`). | ✅ |
| II. Single source of truth | Both palettes live once in `UITheme.lua`; every element resolves colour from a token, never a duplicated literal (FR-002). Sound asset ids and the one volume live once in `UISound.lua` (FR-017). Tween durations live once (in `ThemeController`/`GuiEffects`). Token **names** are the single vocabulary shared by builders (baked) and the runtime switch (attributes). No numbers duplicated. | ✅ |
| III. Rojo / static GUI | The GUI stays static: builders write `StarterGui/*.model.json`; the new token attributes are **baked by the builders** and regenerated/committed (CI parity). `ThemeController` only retint existing instances and paints clones of existing static templates; it builds no screens at runtime. The `GuiRecorder`/generator extension keeps the repo the diffable source. | ✅ |
| IV. Mobile-first, input-agnostic | No layout or input change. Both palettes are designed and checked at phone landscape for ≥ 4.5:1 contrast and ≥ distinguishable rarity hues (FR-010/011). Press sound rides the existing `Activated` bindings (touch/mouse/gamepad alike); feedback never blocks input (FR-016). | ✅ |
| V. Day/Night visual identity via tokens | This **is** principle V: a light day palette and a dark night palette as shared tokens, the active palette following the day/night phase, remaining hard-coded colours migrated to tokens, and both palettes kept readable on a phone. | ✅ |
| VI. Verified in Studio | Studio playtest of the live switch, paint-on-open, paint-on-join, dynamic-clone paint, both-palette contrast at phone landscape, press/purchase sound and window-open animation (quickstart V0–V9), with no new Output errors; generator parity + the new offline contrast/token test green in CI; no DataStore writes (no persistence change). | ✅ |
| VII. Simplicity, small PR | Reuse over new infrastructure: the existing `DayNightUpdate` tick/phase, `TweenService`, `WindowManager` open path, `GuiEffects`, `Activated` bindings and `ToastQueue`. The retint is one generic attribute-driven walk (no per-element bespoke code). Two thin single-responsibility client modules (`ThemeController`, `SoundController`) and one small, contained generator extension. Scope split by priority into independently testable stories, each its own commit with a clean playtest, landing as one Phase 4 PR to `main`. | ✅ |

**Gate result (pre-research)**: pass. **Re-check after Phase 1 design**: pass — the design adds only
what the spec needs (two palettes + resolver, token attributes + a small generator extension, two
client modules, one sound config, an open animation) and each addition maps to a principle (II/V
tokens & config, III static GUI + generator, V/IV readable palettes, I server-triggered purchase
sound). The one piece of real complexity — carrying the token binding from build time to runtime — is
justified below and has a documented fallback, so no unjustified violation. One Complexity Tracking
entry (the attribute-tag mechanism).

## Project Structure

### Documentation (this feature)

```text
specs/004-visual-style/
├── spec.md              # /speckit-specify + /speckit-clarify
├── plan.md              # this file
├── research.md          # Phase 0 — R1–R10
├── data-model.md        # Phase 1 — palette/token/binding entities, no persisted schema change
├── quickstart.md        # Phase 1 — validation V0–V9
├── contracts/
│   ├── theme-tokens.md  # the token vocabulary, both palettes' roles, contrast pairs, attribute scheme
│   └── feedback.md      # UISound config shape + which controls play which sound + open-animation contract
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
ReplicatedStorage/
├── UITheme.lua                         # RESTRUCTURED: Palettes.Day + Palettes.Night (complete token
│                                       #   sets), Default = "Night", Resolve(token, phase), Get(phase),
│                                       #   and back-compat flat fields (= default palette) so existing
│                                       #   builders/controllers keep working. Single colour source (II/V).
└── UISound.lua                         # NEW: { Press, Purchase } asset ids + one Volume (owner fills ids;
                                        #   unset id → silent). Single sound source (II).

StarterPlayer/StarterPlayerScripts/
├── Controllers/
│   ├── ThemeController.lua             # NEW: subscribes to DayNightUpdate; on Day↔Night change tweens
│   │                                   #   every Theme_<Prop> attribute to the active palette across the
│   │                                   #   known ScreenGuis; Paint(root)/PaintInstant(inst) for clones +
│   │                                   #   join; Current()/CurrentPhase() for code that colours by hand.
│   ├── SoundController.lua             # NEW: Press()/Purchase(); reads UISound; one reusable Sound;
│   │                                   #   rate-limits press; fails silent on empty/invalid id; honours
│   │                                   #   the game sound setting.
│   ├── UIController.lua                # CHANGED: tokenise the day/night indicator colours; call
│   │                                   #   ThemeController paint on init (join); FloatCoins uses the
│   │                                   #   active palette's Coins; wire press sound where it owns buttons.
│   ├── ShopController.lua              # CHANGED: paint cloned shop cards to the current phase; play the
│   │                                   #   purchase sound on a server-confirmed buy.
│   ├── SellController.lua              # CHANGED: paint cloned sell rows; press sound on sell/confirm.
│   └── (Daily/Quest/Inventory/Hotbar)  # CHANGED where they clone rows/cards or own buttons: paint clones,
│                                       #   play press sound.
└── Utils/
    ├── WindowManager.lua               # CHANGED: play the window-open animation on Open (+ press sound
    │                                   #   on close/X where it owns those); unchanged close/one-window logic.
    ├── GuiEffects.lua                  # CHANGED: add openWindow(frame) ease-in (scale + fade) helper.
    └── ToastQueue.lua                  # CHANGED: paint each pooled toast to the current phase on show.

Tools/StaticGui/
├── GuiRecorder.luau                    # CHANGED: record obj:SetAttribute(name,value) into the node;
│                                       #   emit node attributes in toModel; include them in fingerprint.
├── build_models.luau                   # CHANGED: encode() emits the "attributes" map (after properties).
└── builders/*.luau (all 8)             # CHANGED: a local themeBind(obj,prop,token) bakes the default
                                        #   (Night) colour AND tags Theme_<prop>=token; applied to every
                                        #   themed property incl. UIStroke (Theme_Color) and UIGradient
                                        #   (Theme_GradientTop/Bottom). Plus the approved design language:
                                        #   UIStroke outline + bottom-shadow frame, UIGradient on headers/
                                        #   buttons, UICorner, display/body font. Migrate hard-coded colours.

StarterGui/*.model.json                 # REGENERATED: now carry the Theme_<Prop> attributes (committed).

Tools/Tests/
└── theme.spec.luau                     # NEW: palette completeness/parity, Color3 types, default = Night,
                                        #   back-compat equality, WCAG-AA contrast pairs.
```

**Structure Decision**: Roblox client + static GUI (no new server module). The one architectural
decision — how a build-time token binding reaches the runtime switch — is the attribute-tag mechanism
in R2, justified in Complexity Tracking.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Extend the static-GUI generator (`GuiRecorder` + `build_models.luau`) to record/emit Roblox **attributes**, and tag every themed property in all 8 builders. | The static GUI is generated once and baked with one palette (III + owner's choice). The runtime switch must know, per element, which token drives which property. Baking that binding **into the element as an attribute** keeps it co-located with the element and resolved from the single token vocabulary (II/V), so the runtime walk is one generic loop. | A separate runtime "bindings map" module (element-name-path → {prop→token}) needs no generator change, but duplicates the GUI structure in a second place that drifts on every rename and re-adds a second source of truth — worse for II/V and more code overall. Regenerating the models per phase is ruled out by III (static GUI) and FR-006. The generator change is small, contained and covered by the existing parity check; the map remains the **documented fallback** (R2) if Rojo 7.7.1 does not carry the attributes in Studio (verified first in implement). |

All unknowns are resolved in [research.md](./research.md) R1–R10. Two items carry a Studio
verification step rather than an open question: that Rojo 7.7.1 applies the baked attributes in Studio
(R2, quickstart V1) and that the live retint reads smooth with no wrong-palette element (R3,
quickstart V2–V4).
