# Feature Specification: Buy–Sell Economy Loop and Shop Content (UI Plan, Phase 2)

**Feature Branch**: `002-buy-sell-economy`

**Created**: 2026-10-29

**Status**: Draft

**Input**: User description: "Phase 2 of the UI plan — the buy–sell economy loop and
shop content: restore the full plant and shop data plus night plants and Dreamroot; sell
harvested crops at a stall like Grow a Garden (seller, 'Sell' prompt, sell window with 'Sell
all', total and protected favourites); teleport buttons to shop/garden/stall; toast
notifications; the shop shown as a card list with rarity, ×1/×5/×10 and dimmed unaffordable
items across Seeds/Tools/Items; floating '+N coins' on sell and harvest; real item icons; and a
hotbar filled from the player's inventory. Server stays authoritative; night/day palette
switching is Phase 4."

## Clarifications

### Session 2026-10-29

- Q: How does a player protect an item from "Sell all", and can a protected item still be sold one at a time? → A: A star toggle on the item; favourited items are excluded from "Sell all" but can still be sold individually with a confirmation.
- Q: How do night plants (including Dreamroot) behave? → A: They grow only during the night phase (growth pauses during the day); sell value is normal.
- Q: Which set of rarity tiers do the cards and balance use? → A: Five tiers — Common / Uncommon / Rare / Epic / Legendary.
- Q: What can be sold at the stall? → A: Only harvested crops; seeds and tools are not sellable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sell harvested crops for coins (Priority: P1)

A player who has harvested crops walks to the seller's stall, opens the sell window, and sells
items for coins — one item, or everything at once with "Sell all" — while items they marked as
favourite are never sold. Without this the economy is half-open: players can buy and grow but
cannot turn a harvest back into coins, so the core loop (buy → plant → grow → **sell** → buy
more) never closes.

**Why this priority**: it completes the economy loop and is the single biggest missing piece;
everything else in this phase enriches a loop that only works once selling exists.

**Independent Test**: on a landscape phone, harvest a crop, open the stall by its on-screen
"Sell" control, sell one item and then "Sell all", and confirm the coin balance rises by the
shown total and favourited items remain.

**Acceptance Scenarios**:

1. **Given** a player standing at the stall with sellable items, **When** they trigger the
   "Sell" control (on-screen button on touch/gamepad, or the key prompt on PC), **Then** the
   sell window opens showing their sellable items and each item's sell value.
2. **Given** the sell window is open, **When** the player sells one item, **Then** the server
   adds that item's sell value to their coins, the item count drops, and the shown total and
   balance update.
3. **Given** the sell window is open with several sellable items, **When** the player taps "Sell
   all", **Then** every non-favourite sellable item is sold in one action and the coins gained
   equals the sum of their sell values.
4. **Given** an item marked as a favourite, **When** the player uses "Sell all", **Then** that
   item is not sold and stays in the inventory.
5. **Given** a player away from the stall, **When** they are not within its range, **Then** the
   "Sell" control is not offered and selling is not possible.

---

### User Story 2 - Real, balanced economy numbers (Priority: P1)

Buying, growing and selling use a complete, balanced set of values — prices, growth times, sell
values, rarity and the new night plants and Dreamroot — defined once and trusted by the server.
The numbers are written down in a balance document first, then put into the configuration.

**Why this priority**: selling and the richer shop are meaningless without real values; a single
balanced source is what makes the loop fair and the server-authoritative checks correct.

**Independent Test**: review the balance document, then in a playtest confirm the shop prices,
growth times and sell values shown and charged match it, including at least one night plant and
Dreamroot.

**Acceptance Scenarios**:

1. **Given** the balance document, **When** the shop and sell windows show prices and sell
   values, **Then** they match the document for every item.
2. **Given** a seed bought from the shop, **When** it is planted and grown, **Then** its growth
   time and yield match the document.
3. **Given** a night plant (including Dreamroot), **When** the player inspects or grows it,
   **Then** it behaves per the document (e.g. tied to the night phase) and sells for its stated
   value.
4. **Given** the configuration, **When** any price, time or value is read, **Then** it comes from
   one place and is never duplicated or contradicted elsewhere.

---

### User Story 3 - Browse and buy from a full shop (Priority: P2)

The shop shows its items as a grid of cards, each with its price and a colour for its rarity, and
×1 / ×5 / ×10 quantity buttons; items the player cannot afford are dimmed. All three categories —
Seeds, Tools and Items — have content, not just Seeds.

**Why this priority**: Phase 1 shop opens and buys a single item at a time with a text detail
pane; the card list makes browsing and buying across a real catalogue usable, but the loop
already works without it.

**Independent Test**: open the shop on a phone, switch between Seeds, Tools and Items, see cards
with prices and rarity colours, buy ×5 of an affordable item, and confirm an unaffordable item's
card is dimmed and cannot be bought.

**Acceptance Scenarios**:

1. **Given** the shop is open on any category, **When** it displays, **Then** each item is a card
   showing its price and a rarity colour, and the grid scrolls when the items overflow.
2. **Given** an item the player can afford, **When** they pick ×1, ×5 or ×10 and buy, **Then**
   the server charges the correct total and adds that quantity to the inventory.
3. **Given** an item the player cannot afford at the chosen quantity, **When** the card shows,
   **Then** it is dimmed and its buy action is unavailable.
4. **Given** the Tools and Items categories, **When** opened, **Then** they show their items (not
   empty).

---

### User Story 4 - Clear feedback through toasts (Priority: P2)

Important events — a purchase, an error, a crop ready to harvest, a spirit caught — show as brief
on-screen toast messages that stack and clear on their own, instead of only printing to the
developer console.

**Why this priority**: players need to know an action succeeded or failed; today this feedback is
a console stub invisible to players. It is P2 because the actions themselves work without it.

**Independent Test**: buy an item and see a success toast; attempt an unaffordable purchase and
see an error toast; let a crop become ready and see its toast — each appears, is readable on a
phone, and disappears after a few seconds.

**Acceptance Scenarios**:

1. **Given** a successful purchase, **When** it completes, **Then** a success toast appears and
   clears after a few seconds.
2. **Given** a failed action (e.g. not enough coins), **When** it is rejected, **Then** an error
   toast explains why.
3. **Given** several events in quick succession, **When** their toasts appear, **Then** they
   queue/stack without overlapping and each is readable.
4. **Given** any toast, **When** it is shown, **Then** it stays inside the safe area and above the
   windows, and does not block the menu column or hotbar.

---

### User Story 5 - Bought seeds are usable from the hotbar (Priority: P2)

When a player buys a seed, it becomes available in the hotbar: it appears in the first free slot,
built from the player's inventory rather than a fixed list.

**Why this priority**: buying a seed that cannot be selected to plant breaks the loop; it is P2
because the three default tools already cover the first-run experience.

**Independent Test**: buy a new seed type, look at the hotbar, and confirm it occupies a free
slot and can be selected and planted.

**Acceptance Scenarios**:

1. **Given** a player buys a seed type not already in the hotbar, **When** the purchase
   completes, **Then** it appears in the first free hotbar slot.
2. **Given** a seed in a hotbar slot, **When** the player selects that slot and uses it on an
   empty plot, **Then** that seed is planted.
3. **Given** the hotbar reflects the inventory, **When** items change, **Then** the hotbar stays
   consistent with what the player owns.

---

### User Story 6 - Quick travel between key places (Priority: P3)

Teleport buttons let the player jump to the shop, to their own garden, and to the stall from an
on-screen row of buttons, like the three top buttons in Grow a Garden.

**Why this priority**: convenience that speeds the loop on larger maps; the loop works by walking
without it.

**Independent Test**: tap each teleport button and confirm the character moves to the shop, the
garden and the stall respectively.

**Acceptance Scenarios**:

1. **Given** the HUD, **When** the player taps a teleport button, **Then** the character is moved
   to that destination.
2. **Given** the teleport buttons, **When** shown on each platform, **Then** they are touch-
   reachable (≥ 44×44), keyboard/gamepad operable, and do not overlap the existing menu column,
   hotbar or Roblox controls.

---

### User Story 7 - Visible reward feedback (Priority: P3)

Selling shows a floating "+N coins" above the player and the coin counter animates up, so gains
are felt immediately. (Harvesting yields a crop, not coins, so it shows no coin float.)

**Why this priority**: game feel; the numbers are already correct without it.

**Independent Test**: sell at the stall and see "+N coins" rise and fade above the player while
the coin total animates to the new value.

**Acceptance Scenarios**:

1. **Given** a sale that grants coins, **When** it completes, **Then** a "+N coins" label appears
   above the player and fades, and the HUD coin counter animates to the new total.

---

### User Story 8 - Item icons instead of placeholders (Priority: P3)

Items, seeds and tools show real icons in the shop, inventory and hotbar instead of the current
placeholder emojis.

**Why this priority**: visual polish; everything is identifiable by name/emoji without it.

**Independent Test**: open the shop, inventory and hotbar and confirm items show their icons, with
a sensible fallback where an icon is missing.

**Acceptance Scenarios**:

1. **Given** an item with an icon, **When** shown in the shop, inventory or hotbar, **Then** its
   icon is displayed.
2. **Given** an item without an icon yet, **When** shown, **Then** a consistent fallback (e.g. its
   emoji or first letter) is shown instead of a broken image.

### Edge Cases

- The player opens the sell window with nothing sellable: the window shows an empty state and
  "Sell all" does nothing.
- "Sell all" with every item favourited: nothing is sold and a message explains why.
- The player buys more than a slot/stack allows or more than they can afford: the server rejects
  it and an error toast explains.
- The player leaves the stall's range while the sell window is open: the window closes or the
  sell action is blocked (no selling from out of range).
- A sale while a crop-ready or spirit toast is showing: the "+N coins" float and the toasts both
  show without overlapping illegibly.
- The hotbar is full when a new seed is bought: the seed stays in the inventory and is not forced
  into a slot; the player can swap it in.
- A spirit is caught while a window is open: its toast still appears above the window.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST let a player sell harvested crops for coins at the seller's stall,
  both individually and all at once via "Sell all". Seeds and tools are not sellable.
- **FR-002**: The stall MUST be reachable on every platform: an on-screen "Sell" control on touch
  and gamepad and a key prompt on PC, offered only while the player is within the stall's range.
- **FR-003**: The sell window MUST show the player's sellable items, each item's sell value, and a
  running total of coins the current selection/▪all would grant.
- **FR-004**: The player MUST be able to mark items as favourites with a star toggle; favourited
  items MUST never be sold by "Sell all", but MAY still be sold individually after an explicit
  confirmation.
- **FR-005**: Selling MUST be validated and applied on the server; the client MUST NOT decide sell
  values, coin totals or inventory changes.
- **FR-006**: The project MUST define the full set of economy values — prices, growth times, sell
  values, rarity, and the night plants and Dreamroot — in the single configuration source, with a
  balance document stating the numbers; the shop, grow and sell flows MUST read from it and MUST
  NOT duplicate the numbers elsewhere.
- **FR-007**: Night plants (including Dreamroot) MUST grow only during the night phase (growth
  pauses during the day) and sell for a normal value, as stated in the balance document.
- **FR-008**: The shop MUST present items as a scrolling grid of cards; each card MUST show the
  item's price and a rarity indicator (a colour) for one of five tiers — Common, Uncommon, Rare,
  Epic, Legendary — and offer ×1, ×5 and ×10 quantity choices.
- **FR-009**: A shop card the player cannot afford at the chosen quantity MUST be shown as
  unavailable (dimmed) and MUST NOT complete a purchase.
- **FR-010**: The Seeds, Tools and Items shop categories MUST all contain their items.
- **FR-011**: The game MUST show transient on-screen toast notifications for purchase success,
  action errors, crop-ready and spirit-caught events; toasts MUST queue without overlapping, clear
  automatically, stay in the safe area and above open windows, and not block the menu column or
  hotbar.
- **FR-012**: The hotbar MUST be built from the player's inventory; a newly bought seed MUST appear
  in the first free hotbar slot and be selectable and plantable.
- **FR-013**: The HUD MUST offer teleport controls to the shop, the player's garden and the stall,
  each ≥ 44×44 and operable by touch, keyboard/mouse and gamepad, without overlapping the existing
  menu column, hotbar or Roblox controls.
- **FR-014**: On a coin-granting sale, the game MUST show a floating "+N coins" label above the
  player and animate the HUD coin counter to the new total. Harvesting yields a crop (not coins),
  so it shows no coin float.
- **FR-015**: Items, seeds and tools MUST show real icons in the shop, inventory and hotbar, with a
  consistent fallback when an icon is missing.
- **FR-016**: All new and changed GUI MUST be stored in the repository's static GUI definitions and
  their generators, and regenerated, so the repository and Studio stay identical.
- **FR-017**: All new UI MUST be mobile-first and input-agnostic (touch, keyboard/mouse, gamepad),
  inside the safe area, with tap targets ≥ 44×44 and readable text (body ≥ 18, titles/buttons ≥
  20), consistent with Phase 1.
- **FR-018**: New and changed UI colours MUST come from the shared theme tokens; no new hard-coded
  theme colours. Day/night palette switching itself is out of scope (Phase 4).
- **FR-019**: This feature MUST NOT weaken server authority: every economy action (buy, sell,
  teleport effects on state, inventory) is validated server-side and fails closed on invalid input.

### Key Entities

- **Plant / item definition**: name, category (seed/tool/item/crop), rarity, buy price, sell value,
  growth time, day/night affinity, icon. Night plants and Dreamroot are entries here.
- **Shop catalogue**: the buyable items per category with their prices and rarity, read from the
  single config.
- **Sell session**: the set of sellable items offered at the stall, the current total, and the
  "Sell all" action; respects the favourites set.
- **Favourites**: the per-player set of items excluded from "Sell all".
- **Toast**: a transient message with a type (success/error/info/event), text and lifetime; shown
  through a queue.
- **Hotbar slot**: a view of an inventory item the player can select and use; filled from the
  inventory.
- **Teleport target**: a named destination (shop, garden, stall) the player can jump to.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can complete the full loop on a phone using only taps — buy a seed, plant
  it, harvest it, sell the crop at the stall, and buy again — with the coin balance correct at each
  step (100% of steps succeed, no keyboard).
- **SC-002**: "Sell all" sells every non-favourite sellable item in one action and the coins gained
  equals the sum of their sell values; favourited items are never sold (0 favourites sold across
  tests).
- **SC-003**: Every price, growth time and sell value shown or charged matches the balance document
  (0 mismatches), and no value is duplicated in more than one place in the config.
- **SC-004**: The shop shows Seeds, Tools and Items as cards with rarity colours and ×1/×5/×10, and
  unaffordable items are dimmed and unbuyable (0 unaffordable purchases succeed).
- **SC-005**: Purchase, error, crop-ready and spirit-caught events each produce a readable toast
  that clears on its own; with several events in 2 seconds, no toasts overlap illegibly.
- **SC-006**: A seed bought while a hotbar slot is free is selectable and plantable from the hotbar
  without a reload.
- **SC-007**: At the Phase 1 reference screens, every new element (stall control, sell window, shop
  cards, toasts, teleport buttons) is inside the safe area, ≥ 44×44 where tappable, with body text
  ≥ 18 and titles/buttons ≥ 20 (0 issues).
- **SC-008**: A Studio playtest of the buy, sell, teleport and feedback flows on phone, PC and
  gamepad emulation produces 0 new errors or warnings from the game's scripts.

## Assumptions

- Sellable items are harvested crops only; seeds and tools are not sellable (clarified). The
  balance document states each crop's sell value.
- Favourites are marked per item with a star toggle; favourited items are excluded from "Sell
  all" but can still be sold individually after a confirmation (clarified).
- Rarity uses five fixed tiers — Common, Uncommon, Rare, Epic, Legendary — with theme-token
  colours (clarified).
- Night plants (including Dreamroot) grow only during the night phase on the existing day/night
  cycle (growth pauses during the day) and sell for a normal value; no new growth mechanic beyond
  what the config expresses (clarified). Dreamroot is a premium night plant.
- The stall is a fixed location in the world with a seller; "within range" uses the engine's
  proximity interaction. Teleport destinations are fixed points (shop, the player's garden, stall).
- Restock timers and limited stock are NOT in this phase (later phase); the shop sells without
  stock limits here.
- Existing remotes for buying/selling are reused and hardened as needed; no change to how data is
  persisted beyond new config fields, which stay backward-compatible with saved profiles.
- Icons may ship as they become available; a fallback (emoji/first letter) covers any item still
  missing an icon, so the feature does not block on art.
