# Feature Specification: Cosy-Garden Redesign — Stage 2

**Feature Branch**: `006-redesign-stage2`

**Created**: 2026-10-29

**Status**: Draft

**Input**: User description: "Cosy-garden UI redesign — Stage 2: build the systems deferred from Feature 005's 'Out of Scope' — real tools behind hotbar slots 3–5 (lantern / net / shovel), per-player spirit collection + Spirits tab + Spirit Journal, new Moonmoth / Moth-Spirit creatures + night 'X appeared!' announcement + a Capture action with the net, and a full cosy-garden redesign of the Sell / Notifications / Daily-Gift / Quests windows."

## Overview

Feature 005 shipped the cosy-garden look for the HUD, Seed Shop and Backpack, but intentionally
deferred the systems that need new server behaviour. This feature builds those deferred systems. It is
delivered as four independently shippable user stories (one small PR each, per the constitution), so
any one of them can land and be played without the others.

The whole feature keeps the project rules: server decides and validates every outcome (I), numbers and
content live once in `ReplicatedStorage` config (II), GUI is static and generated from builders (III),
every action is reachable by touch and bound through the shared action layer (IV), colours come from
the day/night theme tokens in both palettes (V), and each story is verified in Studio before merge (VI).

## Clarifications

### Session 2026-10-29

- Q: What should the lantern do? → A: A night-time light radius around the player that reveals/attracts nearby spirits (feeds the net-capture loop).
- Q: What should the shovel do? → A: Clear a plant from a plot and reset it to Empty (remove a withered/unwanted crop); no early-dig partial yield.
- Q: How do the net capture and the existing proximity collection relate? → A: Net is required only for the new flying creatures (Moonmoth / Moth-Spirit); existing wisps keep proximity collection unchanged.
- Q: Does the Spirit Journal grant gameplay rewards? → A: No — it is a cosmetic catalogue this stage (shows progress only).
- Q: How are the three tools (lantern / net / shovel) acquired? → A: Bought in the shop's Tools tab for coins, like the existing tools (prices single-sourced in ShopConfig).
- Q: How is a net capture's success decided? → A: Chance-based by the spirit's rarity — the server rolls (rarer = lower catch chance).
- Q: What does the lantern's "attract" do specifically? → A: It increases the night spirit spawn rate within a radius around the player (more targets where you stand).
- Q: Does catching give a reward beyond the collection entry? → A: The first catch of each spirit type grants a one-time bonus (coins / dream seeds); repeat catches only increment the count.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Real tools behind the hotbar (lantern / net / shovel) (Priority: P1)

Today hotbar slots 3–5 show a locked "coming soon" placeholder and do nothing. This story turns them
into three real, ownable tools that the player can equip and use on the world, like the watering can
and Harvest already work.

**Why this priority**: The empty slots are a visible promise on every player's HUD; filling them is the
most-asked-for Stage-2 payoff, and the **net** is a prerequisite for the capture story (US2). It is the
foundation the other spirit stories build on.

**Independent Test**: Own and equip each of the three tools from the hotbar, use each on a valid target,
and confirm the server-decided effect happens (and invalid use is rejected). Deliverable even if US2–US4
never ship: three working tools replacing dead slots.

**Acceptance Scenarios**:

1. **Given** the player owns the lantern/net/shovel, **When** they look at the hotbar, **Then** slots
   3–5 show those tools (icon + name + 1–5 key label on PC) instead of the locked placeholder, and each
   is equippable by tap, number key and gamepad cycle.
2. **Given** a tool the player does **not** own, **When** they view that slot, **Then** it still reads as
   locked/unowned and tapping it equips nothing (no error, no server change).
3. **Given** the player has the **shovel** equipped, **When** they use it on a plot that holds a plant
   (e.g. a withered or unwanted crop), **Then** the server clears that plant and resets the plot to
   Empty, and the plot updates from the server's confirmed response; using it on an already-empty plot
   is rejected cleanly.
4. **Given** it is night and the player has the **lantern** equipped, **When** they use/hold it, **Then**
   the server raises the spirit spawn rate within a radius around the player (more spirits appear where
   they stand, feeding the capture loop in US2); by day it has no spirit effect.
5. **Given** the player has the **net** equipped and a capturable spirit is in range, **When** they use
   it, **Then** the capture attempt is sent to the server (the capture outcome is specified in US2).
6. **Given** the day↔night phase switches, **When** the hotbar repaints, **Then** the three new tools
   keep their slot, size and order and only their colours cross-fade (no tool equipped/unequipped by the
   switch).

---

### User Story 2 - Spirit capture: net, new night creatures, and the "appeared" announcement (Priority: P2)

This story makes spirits something the player actively **catches** at night with the net, adds new
creature types to catch, and announces notable ones server-wide.

**Why this priority**: It turns the net from an item into a gameplay loop and gives night its headline
activity; it depends on the net existing (US1) and feeds the journal (US3).

**Independent Test**: At night, a Moonmoth/Moth-Spirit appears, the "X appeared!" banner shows, the
player equips the net and captures it, and the server records the catch (reward/inventory per the
clarified rules). Testable without US3's journal screen (catch confirmation + inventory is enough).

**Acceptance Scenarios**:

1. **Given** it is night, **When** a new Moonmoth / Moth-Spirit spawns, **Then** it is visible in the
   world and (for notable rarities) a rate-limited, server-wide "✨ A <rarity> <name> appeared!" banner
   is shown, reusing the existing announcement layer.
2. **Given** a capturable spirit is within range and the player has the net equipped, **When** they use
   the net (tap the on-screen prompt / press the bound key), **Then** the server validates range,
   ownership and cooldown and rolls a catch chance based on the spirit's rarity (rarer = lower chance);
   on a successful roll the spirit is removed from the world and the catch is recorded for that player,
   and on a failed roll the attempt ends with on-screen feedback and the spirit may remain.
3. **Given** a capture is attempted out of range, on cooldown, or on a non-capturable target, **Then**
   the server rejects it (fail closed) and nothing is recorded.
4. **Given** both the existing proximity collection and the new net capture exist, **When** the player
   encounters a spirit, **Then** the rule is: the existing wisp spirits keep today's proximity
   collection unchanged, and only the new flying creatures (Moonmoth / Moth-Spirit) require the net —
   a wisp is never net-only and a flying creature is never collected by walking into it.
5. **Given** the **first** successful catch of a given spirit type, **When** the server confirms it,
   **Then** a one-time discovery bonus (coins / dream seeds) is applied server-side and the currency
   updates from the confirmed response; a repeat catch of an already-discovered type only increments its
   count and grants no currency.

---

### User Story 3 - Spirit collection data, Spirits tab, and the Spirit Journal (Priority: P3)

This story gives the player a record of what they have caught: real contents for the Backpack Spirits
tab (today a placeholder) and a dedicated Spirit Journal screen.

**Why this priority**: It is the reward/retention layer on top of capture; valuable but playable only
once there is something to collect (US2), so it follows them.

**Independent Test**: Catch a few spirits, open the Spirits tab and the Spirit Journal, and confirm the
caught spirits show as collected (with counts/first-caught), uncaught ones show as undiscovered, and the
data survives a rejoin.

**Acceptance Scenarios**:

1. **Given** the player has caught spirits, **When** they open the Backpack **Spirits** tab, **Then** it
   lists their caught spirits as rarity-badged cards (not the "coming soon" placeholder), consistent with
   the Stage-1 Backpack cards.
2. **Given** the player opens the **Spirit Journal**, **When** it loads, **Then** it shows every known
   spirit type: caught ones revealed (name, rarity, count, first-caught), uncaught ones as a locked /
   "undiscovered" entry, with overall collection progress.
3. **Given** the player rejoins, **When** their data loads, **Then** their collection is intact
   (persisted and reconciled into existing profiles without dropping other fields).
4. **Given** the Journal is open, **When** the day↔night phase switches, **Then** it stays in place and
   only cross-fades colours, readable in both palettes.
5. **Given** a collection milestone is reached, **When** the player views the Journal, **Then** the
   Journal reflects progress (e.g. "7 / 12 discovered") but grants no gameplay reward this stage — it is
   a cosmetic catalogue; milestone rewards are a possible later addition, not built here.

---

### User Story 4 - Cosy-garden redesign of the remaining windows (Priority: P3)

Bring the Sell, Notifications, Daily-Gift (Daily Reward) and Quests windows up to the cosy-garden
concept. Today they only get re-tinted by the theme engine; their layout is pre-redesign.

**Why this priority**: Visual consistency and polish; independent of the spirit systems and of each
other, so it can ship last (or in parallel) as small per-window PRs.

**Independent Test**: Open each of the four windows in both palettes at phone-landscape and confirm it
matches the cosy-garden concept (same card/header/button language as the redesigned Shop/Backpack),
with all existing actions still working through the existing remotes.

**Acceptance Scenarios**:

1. **Given** any of the four windows, **When** it is opened, **Then** it uses the cosy-garden header,
   card and button language and the theme tokens, matching the redesigned Shop/Backpack.
2. **Given** a redesigned window, **When** the player performs its existing actions (sell / claim reward
   / claim quest / dismiss notification), **Then** the action still works through the existing server
   path with no new remotes and no behaviour change.
3. **Given** any redesigned window at phone-landscape in both palettes, **Then** all labels and values
   are readable, touch targets are ≥44×44, and content stays inside the safe area and clear of the
   movement/jump zones.

---

### Edge Cases

- A tool the player sells or loses while it is equipped: the hotbar must fall back cleanly to an owned
  tool, and using the unowned tool must be rejected server-side.
- Two players try to capture the same spirit at once: the server must award it to at most one (fail the
  loser closed), never duplicate it.
- A spirit despawns (day breaks, or it times out) mid-capture: the attempt must resolve as a clean
  rejection, not an error.
- Opening the Spirit Journal before any catch: shows an all-undiscovered state, not an empty/broken
  screen.
- A profile from before this feature (no collection data): loads with an empty collection, never a load
  failure (schema reconcile).
- Phone-landscape with the on-screen net/shovel prompt visible: it must not overlap the hotbar, jump or
  movement controls.

## Requirements *(mandatory)*

### Functional Requirements

**Tools (US1)**

- **FR-001**: The three tools (lantern, net, shovel) MUST be ownable items defined once in the
  `ReplicatedStorage` config modules (ids, display names, icons, coin price), bought from the shop's
  **Tools** tab for coins like the existing tools, with prices single-sourced in `ShopConfig` and no
  numbers duplicated in controllers or builders.
- **FR-002**: Owned tools MUST appear in hotbar slots 3–5 as normal equippable tools (icon, name, 1–5
  key label on PC, on-screen tap, gamepad cycle); unowned tool slots MUST remain in the locked/unowned
  state and equip nothing when tapped.
- **FR-003**: Each tool's effect MUST be decided and validated entirely on the server (caller,
  argument types, target state, ownership, range, cooldown), failing closed on invalid use; the client
  only sends the request and renders the confirmed result.
- **FR-004**: Tool use MUST go through the existing interaction remote(s); this feature MUST NOT add a
  new server-trusted computation path or a duplicate of an existing one.

**Capture & creatures (US2)**

- **FR-005**: The game MUST support new night creature types (Moonmoth / Moth-Spirit) defined once in
  config, that spawn at night and are visible in the world.
- **FR-006**: The player MUST be able to capture a capturable spirit with the net via an on-screen
  control (not keyboard-only); the server MUST validate the attempt and decide success by rolling a
  per-rarity catch chance (single-sourced in config), recording a successful catch against that player
  and resolving a failed roll cleanly.
- **FR-007**: On a notable spawn, the game MUST show a rate-limited, server-wide "appeared" announcement
  reusing the existing announcement layer (no new broadcast remote).
- **FR-008**: The first catch of each spirit type MUST grant a one-time discovery bonus (coins / dream
  seeds, single-sourced in config) applied server-side; repeat catches MUST only increment the type's
  count and grant no currency. All currency changes reflect to the client only from the server's
  confirmed response.
- **FR-009**: Collection method MUST follow a single rule by spirit type: existing wisp spirits keep
  proximity collection unchanged; the new flying creatures (Moonmoth / Moth-Spirit) are capturable only
  with the net. The net capture MUST NOT change how wisps are collected.

**Collection & Journal (US3)**

- **FR-010**: The game MUST persist a per-player spirit collection (which spirits caught, count,
  first-caught), stored in the player data template and reconciled into existing profiles without
  dropping fields.
- **FR-011**: The Backpack **Spirits** tab MUST show the player's caught spirits as rarity-badged cards
  consistent with the Stage-1 Backpack, replacing the placeholder.
- **FR-012**: A **Spirit Journal** screen MUST show all known spirit types — caught ones revealed with
  their details, uncaught ones as undiscovered — plus overall collection progress, reachable from the
  HUD/Backpack by an on-screen control.
- **FR-013**: Collection data MUST be read by the client only from server-provided data (no client-kept
  authoritative collection); the client renders it.

**Window redesign (US4)**

- **FR-014**: The Sell, Notifications, Daily-Gift (Daily Reward) and Quests windows MUST be rebuilt in
  the static GUI builders to the cosy-garden concept (header/card/button language + theme tokens),
  keeping all existing actions working through the existing remotes with no behaviour change.
- **FR-015**: Each redesigned window MUST regenerate its `StarterGui/*.model.json` from its builder and
  keep repo/Studio parity.

**Cross-cutting (all stories)**

- **FR-016**: Every new or changed screen MUST be static GUI generated from `Tools/StaticGui/builders/`
  via `build_models.py`; controllers attach behaviour and clone templates, never build whole screens at
  runtime.
- **FR-017**: All new UI MUST be fully usable by touch (every action on an on-screen control, ≥44×44,
  inside the safe area), bound through the shared action layer so touch/mouse/keyboard/gamepad share the
  action; keyboard keys are shortcuts only and Roblox-reserved keys are not used.
- **FR-018**: All new/changed UI colours MUST come from the day/night theme tokens and stay readable in
  both palettes; no theme colours hard-coded.
- **FR-019**: Each story MUST be verified in Studio (both palettes, phone-landscape) with no new Output
  errors before merge, and ship as its own small PR.

### Key Entities *(include if feature involves data)*

- **Tool**: an ownable, equippable item (lantern / net / shovel) with an id, display name, icon, and a
  server-defined effect and eligible-target rule. Relates to the hotbar (slots 3–5) and to the player's
  inventory (ownership).
- **Spirit type**: a creature definition (id, display name, rarity tier, where/when it appears, how it
  is collected/captured, and — for net-captured types — a per-rarity catch chance and a first-catch
  discovery bonus). Includes existing wisp types and the new Moonmoth / Moth-Spirit.
- **Spirit collection record**: per-player data — for each spirit type, whether caught, how many, and
  first-caught — the source of truth for the Spirits tab and the Journal. Belongs to the persisted
  player profile.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can own, equip and successfully use all three tools (lantern, net, shovel) from
  the hotbar, and each produces its server-confirmed effect; no hotbar slot shows a dead "coming soon"
  placeholder for an owned tool.
- **SC-002**: At night a player can find a spirit, equip the net and capture it entirely through
  on-screen controls (no keyboard required), and sees the catch confirmed within one interaction.
- **SC-003**: 100% of captures and tool effects are server-decided: a client that sends an invalid or
  out-of-range request causes no state change (verified by rejection + no inventory/collection change).
- **SC-004**: After catching spirits and rejoining, the player's Spirit Journal and Spirits tab show the
  same collection (counts and discovered/undiscovered states persist across sessions).
- **SC-005**: All four redesigned windows match the cosy-garden concept and remain fully functional via
  their existing actions, readable in both day and night palettes at phone-landscape.
- **SC-006**: Every story passes a Studio playtest at phone-landscape in both palettes with no new
  Output errors, and all offline specs + static-GUI parity stay green.

## Assumptions

- **Delivery**: this feature is one spec delivered as four small, independently shippable PRs (one per
  user story, or finer), consistent with Feature 005's US-per-PR approach and constitution VII.
- **Reused infrastructure**: no new RemoteEvents/RemoteFunctions — tool use goes through the existing
  interaction remote, capture through the existing spirit/interaction path, and the "appeared" banner
  through the existing `ServerAnnounce` layer (confirmed during planning against a reused-remotes list).
- **Spirit source**: the game already spawns server-only wisp spirits and has a proximity collection;
  this feature extends that system rather than replacing the spawner.
- **Config homes**: tool/creature/collection content lives in the existing `ReplicatedStorage` config
  modules (e.g. `ShopConfig`/`Constants`/`PlantData`-style modules and `DefaultData` for the new
  persisted collection), with balance numbers single-sourced.
- **Theme**: both palettes already exist (Feature 004); new UI only consumes tokens, so no palette
  values change.
- **Tool acquisition**: the three tools are bought from the shop's Tools tab for coins, like the
  existing tools (prices in `ShopConfig`); no new economy system. Exact price values are a balance
  detail for planning.
- **Scope ceiling**: this is Stage 2 of the redesign; anything not in these four stories (e.g. trading,
  new currencies, a world/map redesign) is out of scope.

### Resolved design decisions (owner, 2026-10-29)

- **Lantern** = a night-time light radius around the player that raises the spirit spawn rate nearby,
  feeding the net-capture loop (not a passive buff, not a placed object).
- **Shovel** = clears a plant from a plot and resets it to Empty (remove a withered/unwanted crop); it
  does not dig up a growing crop for partial yield this stage.
- **Capture rule** = the net is required only for the new flying creatures (Moonmoth / Moth-Spirit);
  existing wisp spirits keep today's proximity collection, unchanged.
- **Capture success** = chance-based, rolled by the server from the spirit's rarity (rarer = lower
  chance); a failed roll ends the attempt cleanly.
- **Tool acquisition** = the lantern / net / shovel are bought in the shop's Tools tab for coins.
- **Catch reward** = the first catch of each type grants a one-time discovery bonus (coins / dream
  seeds); repeats only increment the count.
- **Spirit Journal** = a cosmetic catalogue this stage (shows progress, grants no gameplay reward);
  milestone rewards are a possible later feature, deliberately not built here.
