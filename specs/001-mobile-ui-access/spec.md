# Feature Specification: Mobile UI Access (UI Plan, Phase 1)

**Feature Branch**: `001-mobile-ui-access`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Phase 1 of the UI plan: make Night in the Garden fully playable on a phone in landscape orientation, with PC and console input designed in. Today the inventory and shop open only with keyboard keys I and B, so phone and console players cannot open them; the shop (800x550 px) and inventory (600x500 px) are fixed-pixel windows that do not fit a landscape phone (~844x390); windows can only be closed by key (Esc is reserved by Roblox); the hotbar can overlap the thumbstick and jump button. Scope: (1) a vertical column of on-screen menu buttons at the left-centre of the HUD — Shop and Inventory now, room for Rewards and Quests later — touch targets at least 44x44; (2) shop and inventory windows sized by Scale with aspect-ratio and size limits, scaled text with min/max sizes, fitting landscape phone, tablet and PC; (3) phone locked to landscape; (4) close a window with an X button, by tapping the dimmed backdrop, and with gamepad B; (5) hotbar does not overlap the thumbstick or jump button on touch devices (smaller slots, raised row); (6) HUD, InventoryUI and ShopUI stay inside the Roblox safe area; (7) every action works from keyboard, touch and gamepad through one shared action layer: on-screen buttons shown on touch devices, key hints on PC, gamepad selection navigation between buttons so console can be enabled without rework; (8) static GUI models and their builders updated so the repo stays the source of truth. Out of scope: selling, notifications/toasts, shop card list, theming/palettes, new icons (later phases)."

## Clarifications

### Session 2026-10-28

- Q: Should the on-screen menu buttons also be shown on PC, or only keys I/B there? → A: Shown on
  every platform; on PC each button carries a small key label (B, I), on gamepad a gamepad-button
  glyph.
- Q: Which gamepad buttons open the shop and inventory and select hotbar slots? → A: Y opens the
  shop, X opens the inventory, L1/R1 select the previous/next hotbar slot; B closes windows.
- Q: While a window is open, do the menu column and hotbar stay usable above the dimmed
  backdrop? → A: Yes, both stay above the backdrop and work; a tap anywhere else closes the
  window.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open the shop and inventory on a phone (Priority: P1)

A player on a phone in landscape orientation sees two menu buttons, Shop and Inventory, in a
column at the left-centre of the screen. Tapping one opens that window; tapping the other
switches to it. Without this the phone player cannot buy seeds or see what they own, so the
core loop (buy → plant → grow) is blocked for most of the audience.

**Why this priority**: it removes the blocker for the majority of players; everything else in
this phase only matters once the windows can be opened at all.

**Independent Test**: in the device emulator set to a landscape phone, start a playtest and open
the shop and the inventory using only taps. Delivers value on its own: phone players can buy and
browse.

**Acceptance Scenarios**:

1. **Given** a player on a touch device with no window open, **When** they tap the Shop button,
   **Then** the shop window opens.
2. **Given** the shop window is open, **When** the player taps the Inventory button, **Then** the
   shop closes and the inventory opens.
3. **Given** a window is open, **When** the player taps the button of that same window, **Then**
   the window closes.
4. **Given** a player on PC, **When** they press I or B, **Then** the inventory or shop toggles as
   before.

---

### User Story 2 - Windows fit every supported screen (Priority: P1)

The shop and inventory windows fit fully on a landscape phone, a tablet and a PC monitor: no part
of a window (title, close button, contents, action buttons) is cut off or hidden behind the
Roblox top bar, chat or the device notch, and text stays readable.

**Why this priority**: opening a window that does not fit is as blocking as not opening it; on a
landscape phone the current windows are taller than the screen.

**Independent Test**: open each window at the reference resolutions listed in SC-002 and check
that every element is visible and readable.

**Acceptance Scenarios**:

1. **Given** a landscape phone screen about 844×390, **When** the shop or inventory is open,
   **Then** the whole window, including its close button, is visible inside the safe area.
2. **Given** a large PC monitor, **When** a window is open, **Then** it does not grow beyond a
   comfortable maximum size and keeps its proportions.
3. **Given** any supported screen, **When** a window is open, **Then** all text is at least the
   minimum readable size and does not overflow its box.

---

### User Story 3 - Close windows without a keyboard (Priority: P1)

A player closes an open window with the X button, by tapping the dimmed area around the window,
or with the gamepad B button. No step requires the Esc key, which belongs to the Roblox menu.

**Why this priority**: a window that cannot be closed on a phone traps the player.

**Independent Test**: open each window on a touch device and close it each way; repeat with a
gamepad.

**Acceptance Scenarios**:

1. **Given** a window is open, **When** the player taps X, **Then** the window closes.
2. **Given** a window is open, **When** the player taps the dimmed backdrop (not the window,
   menu column or hotbar), **Then** the window closes and the tap does not act on the game world.
3. **Given** a window is open and a gamepad is in use, **When** the player presses the gamepad B
   button, **Then** the window closes.
4. **Given** a window is open, **When** the player presses Esc, **Then** the Roblox menu behaves
   as normal and the game does not depend on that key.

---

### User Story 4 - Hotbar clear of the touch controls (Priority: P2)

On a touch device the hotbar sits where the thumbstick (bottom-left) and jump button
(bottom-right) do not cover it, and every hotbar slot can be tapped.

**Why this priority**: the player can already reach the shop and inventory after P1 stories, but
an overlapped hotbar makes tools and seeds hard to select while moving.

**Independent Test**: on a landscape phone, move with the thumbstick and jump while tapping each
hotbar slot; no slot is covered and no tap triggers movement or jump.

**Acceptance Scenarios**:

1. **Given** a touch device, **When** the HUD is shown, **Then** no hotbar slot overlaps the
   thumbstick area or the jump button.
2. **Given** a PC, **When** the HUD is shown, **Then** the hotbar keeps its current position and
   the 1–3 keys still select slots.

---

### User Story 5 - Same actions on keyboard, touch and gamepad (Priority: P2)

Every Phase 1 action — open shop, open inventory, close window, select hotbar slot, move between
buttons inside a window — works on keyboard/mouse, touch and gamepad. The on-screen menu buttons
are shown on every platform; on PC they carry key labels (B, I) and the hotbar slots show 1–3;
with a gamepad they carry gamepad-button glyphs, and a highlight can be moved between buttons and
pressed.

**Why this priority**: console support is planned next; building the input this way now avoids
rewriting the screens later. It is P2 because the phone fix (P1) delivers value without it.

**Independent Test**: with only a gamepad connected (emulated in Studio), open the shop, move the
highlight to a buy button, press it, close the shop, open the inventory and select a hotbar slot.

**Acceptance Scenarios**:

1. **Given** a gamepad is the active input, **When** a window opens, **Then** a button inside it
   is highlighted and the D-pad/thumbstick moves the highlight between buttons in a predictable
   order.
2. **Given** a gamepad is the active input and no window is open, **When** the player presses Y
   or X, **Then** the shop or the inventory opens; **When** they press L1 or R1, **Then** the
   previous or next hotbar slot is selected (wrapping around at the ends).
3. **Given** the player switches from touch to keyboard (or back) during a session, **When** the
   switch happens, **Then** the key labels or gamepad glyphs on the controls update to the new
   input; the menu buttons stay visible.
4. **Given** a player on PC, **When** the HUD is shown, **Then** the menu buttons are visible,
   clickable and labelled with their keys (B for Shop, I for Inventory).

---

### User Story 6 - Phone stays in landscape (Priority: P3)

When the player rotates the phone, the game stays in landscape and flips between the two
landscape directions; it never switches to portrait.

**Why this priority**: Phase 1 layouts are designed for landscape only; portrait would show a
broken layout. Lower priority because most players hold the phone in landscape already.

**Independent Test**: on a real phone or the emulator, rotate the device to portrait and back.

**Acceptance Scenarios**:

1. **Given** a phone in landscape, **When** the player rotates it to portrait, **Then** the game
   stays in landscape.

### Edge Cases

- The player opens a window while the character is moving: taps on the window and backdrop never
  reach the game world, while the Roblox thumbstick keeps working (the backdrop blocks world taps,
  not Roblox's own controls).
- Both a window and the shop's loading overlay are visible: the close controls still work.
- The player presses a menu key while typing in chat: nothing opens.
- A window is open and the player taps a hotbar slot: the slot is selected, the window stays open.
- A gamepad is disconnected while a window is open: the window stays usable by touch or mouse.
- Very small screens (older phones, ~667×375 landscape): windows still fit, text may hit its
  minimum size, and contents scroll instead of being cut off.
- Very wide screens (ultrawide PC, 21:9): windows stay centred at their maximum size.
- Additional menu buttons (Rewards, Quests) are added in later phases: the column has room for at
  least four buttons on a landscape phone without overlapping the hotbar or Roblox controls.
- The player taps the menu button rapidly: the window toggles cleanly without getting stuck
  half-open or opening twice.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The HUD MUST show a vertical column of menu buttons at the left-centre of the screen
  with Shop and Inventory; the layout MUST leave room for at least two more buttons (Rewards,
  Quests) without redesign.
- **FR-002**: Each menu button MUST be at least 44×44 points on every supported screen and show an
  icon or label identifying it.
- **FR-003**: Tapping or clicking a menu button MUST toggle its window; opening one window MUST
  close any other open window (only one window open at a time).
- **FR-004**: The shop and inventory windows MUST scale with the screen, keep their proportions,
  stay between a minimum and maximum size, and fit fully inside the safe area at every reference
  resolution in SC-002.
- **FR-005**: Text in the windows, menu buttons and hotbar MUST scale with the screen while staying
  between a minimum readable size and a maximum size; text MUST NOT overflow its element.
- **FR-006**: When contents are longer than the window (e.g. many inventory items), the window MUST
  scroll instead of cutting content off.
- **FR-007**: Every window MUST have a close (X) button of at least 44×44 points.
- **FR-008**: While a window is open, a dimmed backdrop MUST cover the rest of the screen except
  the menu-button column and the hotbar, which stay above it, undimmed and usable (switching
  windows, selecting a slot). Tapping or clicking the backdrop MUST close the window and MUST NOT
  act on the game world. The open window MUST NOT overlap the menu-button column or the hotbar.
- **FR-009**: The gamepad B button MUST close the open window. No game function MUST depend on
  the Esc key.
- **FR-010**: On touch devices the hotbar MUST NOT overlap the thumbstick area or the jump button;
  on PC the hotbar MUST keep its current layout.
- **FR-011**: All game GUI (HUD, inventory, shop) MUST stay inside the Roblox safe area: not under
  the top bar, notch or system areas.
- **FR-012**: On phones and tablets the game MUST stay in landscape orientation.
- **FR-013**: Each Phase 1 action (open shop, open inventory, close window, select hotbar slot 1–3,
  move between and press buttons in a window) MUST be defined once and be triggerable from
  keyboard/mouse, touch and gamepad.
- **FR-013a**: Gamepad bindings MUST be: Y — toggle shop, X — toggle inventory, L1/R1 — previous/
  next hotbar slot (wrapping), B — close the open window, D-pad/left stick — move the highlight
  inside a window, A — press the highlighted button. Buttons Roblox reserves (Start, Select, and
  A/thumbsticks/R2 outside windows) MUST keep their default behaviour.
- **FR-014**: Existing keyboard shortcuts MUST keep working: I (inventory), B (shop), 1–3 (hotbar);
  shortcuts MUST NOT trigger while the player is typing in chat or another text box.
- **FR-015**: The on-screen menu buttons MUST be visible on every platform (touch, keyboard/mouse,
  gamepad). The game MUST detect the player's current input type and update during the session:
  on keyboard/mouse each menu button shows a small key label (B, I); on gamepad it shows the
  matching gamepad-button glyph and highlight navigation is enabled; on touch no key labels are
  shown.
- **FR-016**: With a gamepad, opening a window MUST highlight a default button inside it, and
  directional input MUST move the highlight between that window's buttons in a predictable order;
  closing the window MUST return the highlight to where it was (or clear it).
- **FR-017**: Rapid repeated presses of an open/close control MUST NOT leave a window in a broken
  or doubled state.
- **FR-018**: All GUI changes MUST be stored in the repository's static GUI definitions and their
  generators, so the repository and Studio stay identical.
- **FR-019**: This feature MUST NOT change gameplay rules, prices, inventory contents or saved
  player data; it only changes how the UI is reached and displayed.

### Key Entities

- **Menu action**: a named player intent (open shop, open inventory, close window, select hotbar
  slot N, navigate, confirm). Has bindings for keyboard, touch and gamepad and a hint label per
  input type.
- **Window**: a full-screen-overlay panel (shop, inventory; later rewards, quests) with a title,
  close button, backdrop, size limits and a default gamepad-highlighted button. At most one is open.
- **Input mode**: the player's current input type (touch, keyboard/mouse, gamepad); decides which
  key labels or gamepad glyphs are shown on the always-visible controls.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a landscape phone, a player can open the shop, buy an item, close the shop, open
  the inventory and close it using only taps — 100% of these steps succeed with no keyboard.
- **SC-002**: At each reference screen — phone landscape 844×390, small phone landscape 667×375,
  tablet landscape 1024×768, PC 1920×1080, ultrawide 2560×1080 — every element of the HUD, shop
  and inventory is fully visible inside the safe area and no text is clipped (0 issues).
- **SC-003**: Every tap target added or changed in this phase is at least 44×44 points at the
  phone reference resolution.
- **SC-004**: On a touch device, 0 hotbar slots overlap the thumbstick or jump button.
- **SC-005**: With only a gamepad, a player completes the SC-001 flow plus selecting a hotbar slot
  without touching mouse, keyboard or screen.
- **SC-006**: A window opens or closes within 0.3 seconds of the player's input, on every input
  type.
- **SC-007**: A Studio playtest of these flows on phone and PC emulation produces 0 new errors or
  warnings from the game's scripts.

## Assumptions

- Roblox's own controls (thumbstick, jump button, top bar, chat) keep their default positions;
  the layout reserves space around them rather than moving them.
- "Tablet" is handled like a large phone: landscape only, touch input, same layout scaled up.
- Gamepad support is built and tested with Studio's gamepad emulation; enabling the game for
  console platforms (and console certification) is a later step outside this phase.
- Opening a window does not pause the game or block character movement via the thumbstick.
- Existing window contents (shop rows, inventory tabs and items, tooltip) stay as they are;
  only their sizing, opening and closing change. The shop card list and selling come in Phase 2.
- Current placeholder icons stay; menu buttons may use text labels until Phase 2 icons arrive.
- Colours stay as they are now; day/night theme tokens come in Phase 4.
