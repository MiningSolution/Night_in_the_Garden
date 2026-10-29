# Feature Specification: Cosy-Garden UI Redesign (Stage 1 — Core Screens)

**Feature Branch**: `claude/ui-redesign-e141d3`

**Created**: 2026-10-29

**Status**: Draft

**Input**: User description: "Redesign the game's UI to match the owner-approved 'cosy garden' concept (day HUD, night HUD, Seed Shop, Backpack). Stage 1: relaid-out HUD, redesigned Seed Shop, redesigned Inventory, filled item icons — reusing all existing gameplay systems and the day/night theme engine. New spirit/capture/tool systems deferred to a later stage."

## Context & Constraints

This feature **re-skins and relays out existing screens**; it does not add new gameplay systems. The
day/night theme engine (two palettes, `Theme_<Prop>` attributes, runtime re-tint on the
`DayNightUpdate` event) already exists and is the single colour source — this feature consumes it, it
does not rebuild it. Every economy/inventory/sell action already has a server-authoritative remote;
this feature changes only how those flows are presented and laid out, not what the server trusts.

The approved visual direction is the "cosy garden" concept: chunky rounded panels, thick dark
outlines, a small bottom shadow, gradient headers, bold rounded display font, rarity shown by both
text and colour, cream-green by day and indigo-moon by night. The centre of the screen stays clear
for the character and garden.

## Clarifications

### Session 2026-10-29

- Q: How should the five-slot tool strip be shown in Stage 1 when only watering-can and seed tools
  really exist? → A: Show all five slots as in the concept; slots 3–5 are visual placeholders rendered
  in a locked / "coming soon" state.
- Q: How should the HUD SELL action behave when the player is not near the sell stall? → A: SELL
  teleports the player to the stall (as GARDEN teleports to the garden), then opens the Sell window.
- Q: How should the second currency be labelled on the HUD? → A: Display it as "Dream Seeds" (the
  concept label); the currency's internal project name is not changed, only its display label.
- Q: What should the Backpack Spirits tab show in Stage 1 while the spirit system is deferred? → A: The
  Spirits tab is visible but shows an empty "coming soon" placeholder state.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Redesigned, relaid-out HUD in both palettes (Priority: P1)

As a player, I see a clear, game-like heads-up display that matches the cosy-garden look and keeps the
same layout whether it is day or night, so I always know where my money, actions and current goal are.

**Why this priority**: The HUD is on screen the whole session and frames every other action; it is the
most visible part of the redesign and the owner's concept leads with it.

**Independent Test**: Launch the game, observe the HUD by day and after a forced switch to night — the
nav, side buttons, currency, phase pill, quest card and tool strip are all present, readable, correctly
placed, and do not move or change size when the phase flips.

**Acceptance Scenarios**:

1. **Given** the game is running by day, **When** the HUD is shown, **Then** the top-left shows the
   coin balance and the second ("Dream Seeds") balance; the top-centre shows a primary navigation of
   three actions labelled **SEEDS / GARDEN / SELL**; the left edge shows a vertical column of three
   actions labelled **BAG / QUESTS / GIFTS**; the top-right shows a pill with the current phase and the
   time remaining until it ends; the right side shows a single current-quest card; the bottom-centre
   shows a strip of five tool slots numbered 1–5.
2. **Given** the HUD is shown, **When** the phase switches from day to night (or back), **Then** every
   HUD element keeps the same position, size and order, the colours cross-fade to the other palette,
   and no tool is equipped or inventory changed by the switch alone.
3. **Given** a player taps **SEEDS**, **Then** the Seed Shop opens with its Seeds tab already selected;
   **When** they tap **GARDEN**, **Then** they are teleported to the garden; **When** they tap **SELL**,
   **Then** the Sell flow for the stall opens.
4. **Given** a player taps **BAG / QUESTS / GIFTS**, **Then** the Backpack / Quests / Daily-Gift window
   opens respectively.
5. **Given** the player is near a harvestable plant by day, **Then** a contextual Harvest hint is shown
   on the HUD; the hint is reachable by an on-screen tap, not only by a keyboard key.
6. **Given** both palettes, **When** text and icons are viewed at phone-landscape size, **Then** all HUD
   labels and values are readable against their surfaces.

---

### User Story 2 - Redesigned Seed Shop with image cards and rarity (Priority: P1)

As a player, I browse a shop of large, attractive item cards that clearly show each item's picture,
name, rarity, price and remaining stock, pick a quantity, and buy — with the shop refusing purchases I
cannot make and telling me why.

**Why this priority**: Buying seeds is the core economic loop; the concept's shop is one of the four
approved frames and the current shop is plain.

**Independent Test**: Open the shop, select an item, try ×1 / ×5 / ×10 buys including a sold-out item
and an item the player cannot afford, and confirm the balance, stock and disabled states behave
correctly without reopening the window.

**Acceptance Scenarios**:

1. **Given** the shop is open, **When** an item is shown, **Then** its card shows a picture, name, a
   rarity badge whose text names the tier (COMMON/UNCOMMON/RARE/EPIC/LEGENDARY) and whose colour is the
   rarity colour, the gold price, and the remaining stock.
2. **Given** an item is selected, **When** the player chooses ×1 / ×5 / ×10 and confirms, **Then** the
   server is asked to buy exactly that quantity; on success the coin balance and the item's stock update
   in place.
3. **Given** an item is sold out, or the player lacks enough coins, or the requested quantity exceeds
   the remaining stock, **Then** the Buy control is disabled and the reason is distinguishable
   (sold-out vs. not-enough-coins vs. not-enough-stock).
4. **Given** a purchase fails, **Then** the window stays open and the current selection and quantity are
   preserved.
5. **Given** the shop has tabs **Seeds / Tools / Special**, **When** a tab is selected, **Then** only
   that tab's items are listed (Special may re-show a seed item as a special offer; item type and the
   special-offer filter are independent).
6. **Given** both palettes, **Then** shop cards, badges and the Buy button are themed and readable, and
   cloned item cards are tinted to match the active palette.

---

### User Story 3 - Redesigned Backpack (inventory) with grid, detail panel and working Equip (Priority: P2)

As a player, I open my Backpack as a grid of item cards with rarity badges and favourite marks, select
an item to see its details, and take the right action for it — including equipping a seed or tool so it
appears on my hotbar.

**Why this priority**: Inventory is the fourth approved frame and the Equip action is currently a TODO;
it depends on the HUD tool strip existing (US1) to be meaningful, so it follows the two P1 stories.

**Independent Test**: Open the Backpack, switch tabs, select items of different types, and confirm the
detail panel shows the correct context action and that Equip puts the item on the hotbar.

**Acceptance Scenarios**:

1. **Given** the Backpack is open, **When** items are shown, **Then** they appear as a multi-column grid
   of cards, each with an icon, name, rarity badge, quantity and a favourite mark when favourited.
2. **Given** the tabs **All / Seeds / Tools / Crops / Spirits**, **When** a tab is selected, **Then**
   only items of that category are listed (All shows everything; Seeds shows only seeds, etc.).
3. **Given** an item is selected, **Then** a detail area shows the selected item, its description, its
   favourite state, and a single context action appropriate to its type: Equip for Seeds/Tools,
   "Go to sell" for Crops, "View journal" for Spirits.
4. **Given** a seed or tool is selected, **When** the player taps Equip, **Then** the item is equipped
   (appears selected on the hotbar tool strip) via the existing equip request; the switch is reflected
   on the HUD.
5. **Given** both palettes, **Then** Backpack cards, badges and the detail panel are themed and
   readable, and cloned cards are tinted to match the active palette.

---

### User Story 4 - Consistent item icons (Priority: P2)

As a player, I see consistent, game-like pictures on seeds, crops and tools across the shop, backpack
and hotbar instead of placeholder letters.

**Why this priority**: Icons are called out in the concept as a key readability lift and the plumbing
already exists (single-source icon fields with a letter fallback), so it is a high-value, low-risk add.

**Independent Test**: Open the shop and backpack and confirm each item shows its picture; temporarily
blank an icon field and confirm the letter fallback still renders.

**Acceptance Scenarios**:

1. **Given** the item config has icon fields, **When** they are filled with image references, **Then**
   the shop, backpack and hotbar show those images for the matching items.
2. **Given** an icon field is empty, **Then** the renderer still shows the existing letter fallback (no
   broken image).
3. **Given** the sourced images, **Then** each is free for commercial use and recorded with its source
   so the licence is auditable.

---

### Edge Cases

- Phase switch fires while a window (shop/backpack) is open → the open window and its cloned cards
  re-tint to the new palette; the selection and quantity are not lost.
- A list is empty (no items in a tab) → the grid/list shows a readable empty state, not a blank panel.
- Long item names or localised (Russian/German) labels → labels wrap or truncate without overflowing
  the card; width budget is reserved.
- SELL is opened from the HUD but the player is not near the stall → the HUD SELL action teleports the
  player to the stall first, then opens the Sell window, so it never fails silently or opens a
  stall-only interaction out of range.
- Rarity colour vs. item colour clash (e.g. a purple plant with a gold Legendary badge) → the badge
  reads as rarity, not as the item's own colour.
- Night palette must not become unreadably dark; text stays light and item/spirit pictures stay bright.

## Requirements *(mandatory)*

### Functional Requirements

**HUD (US1)**

- **FR-001**: The HUD MUST present a top-centre primary navigation of exactly three actions labelled
  SEEDS, GARDEN and SELL, in that order. SEEDS reuses the existing shop-open action; GARDEN reuses the
  existing garden-teleport action; SELL MUST teleport the player to the sell stall (as GARDEN
  teleports to the garden) and then open the Sell window, so it works from anywhere on the HUD.
- **FR-002**: The HUD MUST present a left vertical column of three actions labelled BAG, QUESTS and
  GIFTS, reusing the existing inventory-open, quests-open and daily-reward-open actions (the
  daily-reward action is relabelled from "Rewards" to "Gifts").
- **FR-003**: The HUD MUST show the player's coin balance and the second currency balance at the
  top-left, updating from the existing currency updates. The second currency MUST be displayed with the
  label "Dream Seeds"; its internal project name MUST NOT be renamed (display label only).
- **FR-004**: The HUD MUST show a top-right pill with the current phase and the time remaining until the
  phase ends, derived from the shared day/night phase/deadline; the client MUST NOT run its own
  independent day/night clock.
- **FR-005**: The HUD MUST show a single current-quest card (one goal with its progress), not the whole
  quest list.
- **FR-006**: The HUD MUST show a bottom-centre strip of five tool slots with on-screen slot controls
  and 1–5 key labels on PC. Slots backed by a real tool (watering can, seeds) are interactive; slots
  3–5 MUST be rendered in a locked / "coming soon" placeholder state this stage (see Out of Scope) and
  MUST NOT equip anything when tapped.
- **FR-007**: By day, when a harvest action is available in context, the HUD MUST show a Harvest hint
  that is actionable by an on-screen tap (keyboard E remains a shortcut, not the only path).
- **FR-008**: All HUD elements MUST keep the same position, size and order across a day↔night phase
  switch; the switch MUST only change colours and MUST NOT equip a tool or change inventory.
- **FR-009**: HUD positions and sizes MUST be derived through the existing responsive-layout module
  (not hard-coded per window), and MUST stay inside the safe area and clear of the movement/jump
  control zones at phone-landscape size.

**Seed Shop (US2)**

- **FR-010**: Each shop item MUST be shown as a large card with its picture, name, rarity badge (tier
  text + rarity colour), gold price and remaining stock.
- **FR-011**: The shop MUST offer a single quantity selector of ×1 / ×5 / ×10 and one Buy control acting
  on the selected item; a chosen quantity MUST mean exactly that quantity (×10 when only 5 remain does
  not silently buy 5).
- **FR-012**: The Buy control MUST be disabled, with a distinguishable reason, when the item is sold
  out, when the player cannot afford the selected quantity, or when the selected quantity exceeds
  remaining stock.
- **FR-013**: On a successful buy the coin balance and the item's stock MUST update in place from the
  server's confirmed response; a failed buy MUST keep the window open and preserve the selection and
  quantity.
- **FR-014**: The shop MUST provide Seeds / Tools / Special tabs that filter the listing; item type and
  the special-offer filter are independent signals.
- **FR-015**: Opening the shop from the HUD SEEDS action MUST preselect the Seeds tab.

**Backpack (US3)**

- **FR-016**: The Backpack MUST show items as a multi-column grid of cards, each with icon, name, rarity
  badge, quantity and a favourite mark when favourited.
- **FR-017**: The Backpack MUST provide All / Seeds / Tools / Crops / Spirits tabs that filter strictly
  by category (All shows everything). The Spirits tab MUST be present but, this stage, MUST show an
  empty "coming soon" placeholder state rather than real spirit items.
- **FR-018**: Selecting an item MUST show a detail area with the item, its description, favourite state
  and one context action by type: Equip (Seeds/Tools), Go to sell (Crops), View journal (Spirits).
- **FR-019**: The Equip action MUST equip the selected seed/tool through the existing equip request so
  it becomes the selected tool on the HUD tool strip (this replaces the current Equip TODO).

**Icons (US4)**

- **FR-020**: The single-source item icon fields MUST be filled with image references for seeds, crops
  and tools, so the shop, backpack and hotbar render pictures; an empty field MUST still fall back to
  the existing letter renderer.
- **FR-021**: Every sourced image MUST be free for commercial use, and its source MUST be recorded for
  licence audit.

**Theming / structure (all stories)**

- **FR-022**: All new/changed UI colours MUST come from the existing theme tokens and be tagged with the
  `Theme_<Prop>` attributes so the runtime re-tints them on a phase switch; no theme colours may be
  hard-coded.
- **FR-023**: Controllers that clone list/grid items (shop cards, backpack cards, quest card) MUST tint
  each clone to the active palette on creation (close the current gap where clones are not painted).
- **FR-024**: Screens MUST remain static GUI generated by the builders and committed as regenerated
  model files; controllers MUST NOT construct whole screens at runtime.
- **FR-025**: Rarity MUST be conveyed by both the tier text and the rarity colour, never by colour
  alone, and MUST be read from the existing rarity data (no new rarity data introduced).

### Key Entities *(existing data this feature presents; no new persisted entities)*

- **Shop item**: an item offered for sale — picture, name, rarity tier, price, remaining stock, tab
  (Seeds/Tools/Special). Read from the existing shop config.
- **Inventory item**: an owned item — picture, name, rarity tier, quantity, category
  (Seed/Tool/Crop/Spirit), favourite flag. Read from the existing inventory/player data.
- **Rarity tier**: the existing Common/Uncommon/Rare/Epic/Legendary classification with its name text
  and its per-palette colour.
- **Phase**: the shared day/night phase and its deadline, presented by the HUD pill (owned by the
  existing day/night system).
- **Icon**: a per-item image reference stored in the existing single-source icon fields.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reviewer comparing the live game's HUD, Seed Shop and Backpack to the approved concept
  (both day and night) judges all three screens to match the approved direction.
- **SC-002**: All HUD elements stay in the same position and size across a day↔night switch (0 elements
  move or resize), verified in Studio in both palettes.
- **SC-003**: In the shop, buying is correctly allowed or blocked in 100% of the sold-out,
  not-enough-coins and not-enough-stock cases, with the blocking reason distinguishable each time.
- **SC-004**: Equip from the Backpack results in the selected seed/tool being the equipped hotbar tool
  in 100% of attempts for a seed and a tool.
- **SC-005**: Every item visible in the shop and backpack shows a picture (0 placeholder letters) for
  items whose icon field is filled, while a blanked field still renders without a broken image.
- **SC-006**: The offline test suite and the static-GUI parity check both pass (green) after
  regeneration, and a Studio playtest shows no new Output errors from project scripts.
- **SC-007**: At phone-landscape resolution, every label and value on the three screens is readable in
  both palettes (no clipped or overflowing text) by reviewer judgement.

## Out of Scope *(deferred to a later stage — explicitly NOT in this feature)*

These require new server-side systems and are intentionally deferred; the concept shows them but the
handoff flags them as not yet approved for build:

- Per-player **Spirit collection** data, the Spirits-tab contents beyond an empty/placeholder state, and
  any read remote for a spirit journal (the Spirits tab exists as a filter but shows a placeholder
  this stage).
- New **Moonmoth / Moth-Spirit** creature types (current spirits are server-only wisp types).
- The night **"X appeared!" capture announcement** and a **Capture** net-tool action (capture stays the
  existing proximity interaction).
- The real **lantern / net / shovel** tools behind hotbar slots 3–5 and any new tool behaviour; the
  five slots are a visual strip this stage, backed only by the tools that already exist.
- A standalone **Spirit Journal** screen (concept screen 08, flagged as a proposal).
- Changes to Sell, Notifications, Daily-Gift and Quests **windows** beyond what the shared theme engine
  already restyles and the single current-quest HUD card in US1 (their full redesign is a later stage).

## Assumptions

- The approved "cosy garden" visual direction and its palette/design-language tokens (already captured
  by the theme engine on this branch) are the source of truth for the look; this feature does not
  re-pick the style.
- The second currency keeps its existing project name internally; "Dream Seeds" is its display label in
  the concept. The currency's economy/name is not being changed.
- The five-slot tool strip is approved as a layout; only the two-plus already-real tools are
  functionally backed this stage, the rest are placeholders (see Out of Scope).
- Existing remotes and server validation for buy, sell, equip and currency are reused unchanged; this
  feature adds no new server-trusted computation.
- Rarity tiers, prices, stock and growth data come from the existing config modules; no balance numbers
  are introduced or duplicated.
- Item icons will be sourced as free/CC0 catalog images (or equivalent) and recorded; exact asset
  choice is an implementation detail resolved during the build.
- Studio is available for the required playtest verification in both palettes at phone-landscape size.

## Dependencies

- The day/night theme engine on this branch (two palettes, `Theme_<Prop>` attributes, runtime
  re-tint) — consumed, not modified.
- Existing controllers (HUD/menu, shop, inventory, sell, quests, daily-reward, hotbar) and their
  remotes.
- The responsive-layout module for HUD/window geometry.
- The static-GUI builder + regeneration pipeline and the offline test / parity checks.
