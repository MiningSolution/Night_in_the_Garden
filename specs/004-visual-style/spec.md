# Feature Specification: Visual Style — Day/Night Design System

**Feature Branch**: `004-visual-style`

**Created**: 2026-10-29

**Status**: Draft

**Input**: User description: "Phase 4 — Visual style (day/night design system). A two-palette theme
system for all UI: a light palette for the day phase and the current dark palette for the night
phase, resolved from a single source by both the static GUI builders (at generate time) and the
runtime controllers (live switch). On the day/night phase change (the existing DayNightUpdate event),
token-driven UI elements retint smoothly from one palette to the other at runtime, without
regenerating the static GUI. Migrate remaining hard-coded UI colours to theme tokens as screens are
touched. Produce mock-ups of the key screens in both palettes before implementing. Add press and
purchase sounds and a window-open animation. Both palettes must keep text and icons readable on a
phone. Constitution principle V (day/night visual identity via theme tokens) is the driver."

## User Scenarios & Testing *(mandatory)*

The day/night cycle is the game's identity — spirits come out at night. Today the whole UI is dark
all the time, so that identity never reaches the interface. This feature makes the interface itself
follow the time of day, keeps every screen readable in both looks, and adds the small moments of
feedback (a sound, a window that eases open) that the genre's leaders use.

### User Story 1 - The interface follows the time of day (Priority: P1)

As a player, when the world turns from day to night (and back), I want the whole interface to shift
with it — a bright, light look during the day and the familiar dark, moonlit look at night — so the
game's day/night identity is felt everywhere I look, not just in the sky.

**Why this priority**: This is the headline of the phase and the point of constitution principle V.
Without it the phase delivers nothing visible. It is also the hardest piece (a live switch over a
static GUI), so it must be proven first.

**Independent Test**: Start at day and confirm every main screen (HUD, shop, inventory, sell,
daily-reward, quests, notifications/banners) shows the light look; let the phase flip to night (or
force it) and confirm the same screens ease over to the dark look with no abrupt flash and no element
left in the wrong palette; flip back and confirm it returns.

**Acceptance Scenarios**:

1. **Given** the game is in the day phase, **When** the player opens the shop, inventory, sell,
   daily-reward or quests window, **Then** that window and its contents are shown in the light
   palette.
2. **Given** a window is open during the day, **When** the phase changes to night, **Then** the open
   window and the HUD transition to the dark palette smoothly (an eased colour transition, not an
   instant jump) and complete shortly after the phase change.
3. **Given** the game is at night, **When** the phase changes to day, **Then** all themed elements
   transition back to the light palette.
4. **Given** the phase changes while a window is closed, **When** the player later opens that window,
   **Then** it is already in the correct palette for the current phase (no wrong-palette flash on
   open).
5. **Given** a toast, a cloned list row, a shop/sell card, or a floating "+N coins" is created after
   a phase change, **When** it appears, **Then** it is drawn in the palette for the current phase.

---

### User Story 2 - Every screen stays readable and consistent in both looks (Priority: P2)

As a player on a phone, I want text, numbers and icons to stay clearly readable whether the interface
is light or dark, and I want the colours to feel like one consistent system across every screen, so I
never squint at a low-contrast label or meet a leftover mismatched colour.

**Why this priority**: A two-palette system is only worth shipping if both palettes are legible and
coherent. This story is what turns "it changes colour" into "it looks designed". It depends on US1
existing but is tested separately (contrast + no stray colours).

**Independent Test**: On a phone-sized viewport, inspect each key screen in both palettes and confirm
body text, currency numbers, rarity colours and semantic colours (confirm/danger) are readable
against their backgrounds and consistent screen-to-screen; search the touched screens for any colour
that does not come from the shared token source.

**Acceptance Scenarios**:

1. **Given** any key screen in the day palette, **When** a player reads its body text and currency
   numbers on a phone, **Then** the text meets the project's readability bar against its background.
2. **Given** the same screen in the night palette, **When** the player reads it on a phone, **Then**
   it meets the same readability bar.
3. **Given** a shop or sell card for each rarity tier, **When** shown in either palette, **Then** the
   rarity colour is distinguishable from its neighbours and from the background in both palettes.
4. **Given** a screen that this phase has touched, **When** its colours are reviewed, **Then** every
   themed colour resolves from the shared token source and none is a one-off hard-coded value.

---

### User Story 3 - Actions feel tactile (Priority: P3)

As a player, I want a light press sound when I tap a main button, a distinct sound when a purchase
succeeds, and windows to ease open rather than pop in, so the interface feels responsive and
rewarding — like the genre's leaders (Steal a Brainrot's purchase sound, animated event banners).

**Why this priority**: Polish. It raises perceived quality and matches genre expectations, but the
game is fully playable without it, so it ships last and must never get in the way of the action it
accompanies.

**Independent Test**: Tap each main on-screen button and hear a press sound; complete a purchase and
hear the purchase sound; open each window and see it ease open; confirm none of these delays or blocks
the underlying action, and all respect the game's existing sound setting.

**Acceptance Scenarios**:

1. **Given** a main on-screen button (menu, teleport, tab, buy, sell, claim, close), **When** the
   player activates it, **Then** a short press sound plays promptly and the button's action still
   happens exactly as before.
2. **Given** a purchase request that the server confirms as successful, **When** the confirmation
   reaches the client, **Then** a distinct purchase sound plays; **and** a failed/rejected purchase
   does not play the success sound.
3. **Given** a window is opened, **When** it becomes visible, **Then** it eases open (a short
   open animation) and is fully interactive when the animation ends.
4. **Given** the player has game sound off (or the project's sound setting is off), **When** they
   press buttons or buy, **Then** no UI sound plays.

---

### Edge Cases

- **Phase change mid-transition**: the phase flips again before a colour transition finishes — the
  newest phase wins; no element is left stuck between palettes.
- **Join mid-cycle**: a player joining partway through day or night sees the correct palette from the
  first moment the HUD is shown, with no persistent wrong-palette element.
- **Dynamically created elements**: toasts, cloned list rows, shop/sell cards and the floating
  "+N coins" are created after load; each must adopt the current palette when it appears and follow
  later phase changes while it lives.
- **Elements that are only sometimes visible**: a hidden window still updates to the current palette
  so it is correct when next opened, without doing per-frame work while hidden.
- **Non-colour token misuse**: transparency, stroke and gradient that belong to the theme must switch
  with the palette too, not just solid background colours.
- **Rapid button taps**: repeated presses must not stack into a wall of overlapping sound.
- **Missing sound asset**: if a sound asset fails to load, the action still completes silently without
  error spam.
- **Reduced motion / performance**: the open animation and colour transition must be short and cheap
  enough not to stutter on a low-end phone.

## Clarifications

### Session 2026-10-29

- Q: What should the DAY (light) palette look like? → A: Warm garden — cream/parchment surfaces, soft
  green-and-gold accents, warm dark text (cozy "garden" daylight; night palette stays as it is now).
- Q: Which palette is baked into the static GUI by default (as it rests in the repo, before the
  runtime switch)? → A: Night/dark — keeps the repository look unchanged and the visual diff minimal;
  the day palette is applied at runtime.
- Q: Where do the press and purchase sounds come from? → A: The owner will supply the sound asset
  ids. The sound system is wired now (single config source, one volume), and until an id is provided
  that sound plays nothing (fails silently). The window-open animation does not depend on sound and
  proceeds.
- Q: Are the both-palette mock-ups a blocking step before code? → A: Yes — produce the mock-ups of
  all key screens in both palettes, show them to the owner, and wait for approval before writing any
  themed-UI code.

## Requirements *(mandatory)*

### Functional Requirements

**Palette system**

- **FR-001**: The UI MUST define two complete colour palettes — a light palette for the day phase and
  a dark palette for the night phase — covering every theme role in use (surfaces, headers, controls,
  control hover, accent/confirm, danger, primary text, muted text, currency, the five rarity tiers,
  backdrop, and event banners).
- **FR-002**: Both palettes MUST live in a single shared source of truth; a colour that belongs to the
  theme MUST NOT be duplicated or hard-coded in builders, GUI text or controllers.
- **FR-003**: The static GUI (generated once) MUST be produced from that single source, baked with a
  defined default palette, so the repository GUI has a known, consistent starting look.
- **FR-004**: The active palette MUST follow the game's day/night phase: the light palette during day,
  the dark palette during night.

**Live switching**

- **FR-005**: When the day/night phase changes, every themed UI element currently shown MUST retint
  from the old palette to the new one via a smooth, eased transition (not an instant jump), completing
  within a short, bounded time of the phase change.
- **FR-006**: The live switch MUST NOT require regenerating or re-cloning the static GUI; it retint
  the existing elements in place.
- **FR-007**: Themed elements that are hidden at the time of a phase change MUST be shown in the
  correct palette when next made visible, without per-frame work while hidden.
- **FR-008**: Elements created at runtime (toasts, cloned list rows, shop/sell cards, floating coin
  text, banners) MUST adopt the current phase's palette when created and MUST follow later phase
  changes while they exist.
- **FR-009**: A player joining partway through the cycle MUST see the correct palette as soon as the
  HUD is shown; any initial wrong-palette frame MUST not persist.

**Readability & consistency**

- **FR-010**: Both palettes MUST keep body text, currency numbers and icon/labels readable on a phone
  screen, meeting a stated contrast bar against their backgrounds.
- **FR-011**: Rarity and semantic colours (confirm/accent, danger, currency, the five rarity tiers)
  MUST remain distinguishable from each other and from the background in both palettes.
- **FR-012**: Remaining hard-coded UI colours on every screen this phase touches MUST be migrated to
  theme tokens; a touched screen MUST end with no theme colour hard-coded.

**Feedback — sound & animation**

- **FR-013**: Activating a main on-screen button (menu, teleport, tab, buy, sell, claim, close) MUST
  play a short press sound. The sound asset id is owner-supplied and read from a single config source;
  until an id is set, the press produces no sound (per FR-016) and the action is unaffected.
- **FR-014**: A purchase that the server confirms as successful MUST play a distinct purchase sound; a
  rejected or failed purchase MUST NOT play the success sound. The purchase sound asset id is
  owner-supplied via the same single config source.
- **FR-015**: Opening a window MUST play a short open animation; the window MUST be fully interactive
  by the time the animation ends.
- **FR-016**: UI sound and animation MUST NOT block, delay or change the outcome of the action they
  accompany, and MUST fail silently if a sound asset is unavailable.
- **FR-017**: UI sounds MUST respect the project's single sound/volume setting; with sound off, no UI
  sound plays. Sound volume/ids MUST come from a single source, not be scattered.
- **FR-018**: Rapid repeated activations MUST NOT stack into overlapping noise (press sound is
  rate-limited or re-triggered cleanly).

**Process deliverable**

- **FR-019**: Before the themed UI is implemented, mock-ups of the key screens (HUD, shop, inventory,
  sell stall, notifications/banners, daily reward, quests) in BOTH palettes MUST be produced and
  approved by the owner, to lock the look before code.

### Key Entities *(include if feature involves data)*

- **Palette**: a named complete set of colour roles for one phase (Day, Night). Each role (e.g.
  Surface, Header, Control, Accent, Danger, TextPrimary, TextMuted, Coins, Rarity×5, Backdrop, Banner)
  has one colour per palette.
- **Theme token**: a named colour role that a UI element binds to instead of a literal colour; it
  resolves to the matching colour in the active palette.
- **Themed element binding**: the association between a specific GUI element's property (background,
  text, stroke, transparency, gradient) and the theme token that drives it, used to retint it on a
  phase change.
- **Active phase**: the current day/night phase (Day or Night) that selects which palette is active;
  it is owned by the server's day/night cycle and already broadcast to clients.
- **UI sound set**: the small set of interface sounds (press, purchase) with their asset ids and a
  single volume, defined once.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On every key screen this phase touches, 100% of theme colours resolve from the shared
  token source — zero hard-coded theme colours remain on those screens.
- **SC-002**: After a day/night phase change, the visible UI finishes transitioning to the new palette
  within about 1 second, with no abrupt single-frame palette flash and no element left in the old
  palette.
- **SC-003**: In both palettes, body text and currency numbers meet a 4.5:1 contrast ratio against
  their background (WCAG AA for normal text) when checked at a phone landscape resolution.
- **SC-004**: Every main button press, every confirmed purchase, and every window open produces its
  intended feedback (sound and/or open animation) within 100 ms of the triggering action, and no
  feedback ever changes or delays the action's result.
- **SC-005**: Mock-ups of all seven key screens exist in both palettes and are approved by the owner
  before any themed-UI code is written.
- **SC-006**: A player who joins at any point in the day/night cycle sees the correct palette on the
  HUD within the first second and never retains a wrong-palette element.

## Assumptions

- **Phase source**: the day/night phase already exists and is broadcast to every client each second
  (the `DayNightUpdate` event from the existing day/night cycle); this feature consumes it and does
  not change the cycle's timing or server authority.
- **Day palette look**: warm "garden" daylight — cream/parchment surfaces, soft green-and-gold
  accents, warm dark text (confirmed with owner). The night palette keeps today's dark look.
- **Default baked palette**: the static GUI is baked with the night (dark) palette as its default
  (confirmed with owner), so the repository look is unchanged at rest and the day palette is applied
  at runtime.
- **Transition style**: the colour transition and window-open animation are short (well under ~1 s)
  and eased; precise durations are tuned in implementation and recorded as single-source values.
- **Contrast bar**: "readable" means WCAG AA (4.5:1) for normal text and clearly distinguishable
  rarity/semantic hues; this is the target both palettes are designed and checked against.
- **Scope of screens**: the key screens are the seven already in the game (HUD, shop, inventory, sell,
  notifications/banners, daily reward, quests); no new screens are added by this phase.
- **No gameplay/economy change**: this phase is visual and feedback only — it does not alter balance,
  server validation, persisted data or any remote contract.
- **Sounds**: the owner supplies the press/purchase sound asset ids (confirmed); a single volume and
  the asset ids live in one config source, and an unset id simply plays nothing. The window-open
  animation does not depend on sound. No new music or voice is in scope.
- **Mock-up gate**: the both-palette mock-ups are a blocking deliverable — the owner approves them
  before any themed-UI code is written (confirmed).
- **Reduced-motion**: a dedicated OS reduced-motion setting is not read; animations are kept short and
  cheap instead. This may be revisited later.
- **Server-side scripts**: no server change is expected beyond what already broadcasts the phase; the
  feature is client/GUI only.
