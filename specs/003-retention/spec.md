# Feature Specification: Retention Loop — Daily Rewards, Quests, Night Events, Shop Restock, Onboarding (UI Plan, Phase 3)

**Feature Branch**: `003-retention`

**Created**: 2026-10-29

**Status**: Draft

**Input**: User description: "Phase 3 of the UI plan — Retention. Mechanics that give players a reason to
come back and to keep playing in the first session, on top of the Phase 1 mobile-access UI and the
Phase 2 buy–sell economy: (1) a daily login reward with a 7-day streak; (2) daily quests tracked from
gameplay events; (3) night as an event — a nightfall banner and a server-wide rare-spirit announcement;
(4) a shop restock timer with limited per-item stock, rotation derived from server time so every server
agrees; (5) a first-5-minutes tutorial that guides plant → water → sell once. Server stays
authoritative; all balance numbers live once in config with a balance document; GUI stays static;
mobile-first and input-agnostic; theme tokens only. Day/night palette switching is Phase 4."

## Clarifications

### Session 2026-10-29

- Q: How is a "day" defined for the daily reward and quest reset, so it is deterministic across servers? → A: A UTC calendar day from the server clock (`os.time() ÷ 86400`); claimable once per UTC day, and a gap of two or more day indices between claims resets the streak to day one.
- Q: When a purchase asks for more than the item's remaining stock (e.g. ×5 with 3 left), does the server fill what is available or reject the whole purchase? → A: Reject the whole purchase atomically — no coins spent, no items granted — and show an "out of stock" message; the client never completes an oversell.
- Q: How many daily quests are shown and how is the set chosen? → A: Three quests per day, chosen deterministically from a fixed pool by the day index, so every player on every server sees the same set that day (no per-player randomness to persist); the count is a config value.
- Q: Which spirit rarity triggers the server-wide announcement? → A: Rare and Epic tiers (the existing `SpiritTypes` tiers above Common); Common spirits never announce.
- Q: Is shop stock shared globally across servers or per-server? → A: Per-server depletion with a global, time-derived restock schedule — players on one server share a stock pool that refills at each window boundary; the countdown is identical on all servers, but remaining counts are not synchronised across servers.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Daily login reward with a 7-day streak (Priority: P1)

A player who returns to the game on a new day is offered a daily reward. A window shows a 7-day streak
track with each day's reward; the player claims the current day's reward once, and the streak advances.
Coming back the next day advances to the next day on the track; skipping a day resets the streak to day
one. After day seven the track loops. The window is reachable at any time from a "Rewards" button in the
HUD menu column, and it prompts automatically on the first login of a day.

**Why this priority**: a daily reward with an escalating streak is the single strongest reason to come
back the next day, and the whole phase is about retention; it also stands entirely on its own.

**Independent Test**: on a landscape phone, join the game, see the reward window prompt on first login,
claim the day's reward by tapping, and confirm the coin/seed balance rises by the shown amount and the
day cannot be claimed again until the next day.

**Acceptance Scenarios**:

1. **Given** a player's first login of a day with an unclaimed reward, **When** they join, **Then** the
   daily-reward window opens automatically showing the 7-day track with the current day highlighted and
   claimable.
2. **Given** the reward window open on a claimable day, **When** the player claims, **Then** the server
   grants that day's reward, the balance updates, the day shows as claimed, and the claim control is
   disabled until the next day.
3. **Given** a player who already claimed today, **When** they reopen the window (via the HUD Rewards
   button), **Then** today shows as claimed and no reward can be taken again until the next day.
4. **Given** a player who last claimed yesterday, **When** they claim today, **Then** the streak advances
   by one day and the next day's (larger) reward is shown as next.
5. **Given** a player who missed one or more days, **When** they return and claim, **Then** the streak
   resets to day one and the day-one reward is granted.
6. **Given** a player who has claimed all seven days, **When** they claim the next day, **Then** the
   track loops back to day one.

---

### User Story 2 - Daily quests from gameplay (Priority: P2)

A player opens a Quests window from the HUD menu column and sees a small set of objectives for the day —
for example "plant 5 seeds", "sell 3 crops", "catch a spirit at night". As they play, progress fills
automatically from what they do. Completing a quest lets them claim its reward, and a toast confirms it.
Quests reset to a fresh set each day.

**Why this priority**: quests turn a single session into a set of short goals and give the daily reward
something to do between logins; the loop already works without them, so they come after the reward.

**Independent Test**: open the Quests window on a phone, perform a tracked action (plant a seed), watch
the matching quest's progress rise, complete it, claim the reward, and confirm the balance rises and the
quest shows as claimed; confirm the set is the same for the whole day.

**Acceptance Scenarios**:

1. **Given** the Quests window, **When** it opens, **Then** it shows the day's quests, each with its
   objective text, current progress toward its target, and its reward.
2. **Given** an in-progress quest, **When** the player performs the tracked action (plant, harvest, sell,
   catch a spirit), **Then** the server increases that quest's progress and the window reflects it.
3. **Given** a quest whose progress reached its target, **When** the player claims it, **Then** the
   server grants the reward once, the quest shows as claimed, and a toast confirms completion.
4. **Given** a claimed or completed quest, **When** the player tries to claim again, **Then** the server
   refuses and no extra reward is granted.
5. **Given** the day rolls over, **When** the player next opens the window, **Then** a fresh set of
   quests is shown with progress reset.

---

### User Story 3 - Shop restock timer and limited stock (Priority: P2)

The shop sells a limited quantity of each stocked item. As players buy, the remaining stock drops, and
when it runs out that item cannot be bought until the next restock. The shop window shows a countdown to
the next restock; when the timer elapses, stock refills and a toast announces the restock. The restock
schedule is derived from time so every server shows the same countdown.

**Why this priority**: a restock timer is a recurring reason to come back ("the shop refreshes soon")
and makes scarce items feel valuable; it builds directly on the Phase 2 shop and buying, so it is a
natural P2 after the reward.

**Independent Test**: open the shop on a phone, see a remaining-stock figure on stocked items and a
restock countdown; buy a stocked item until it is out and confirm it can no longer be bought; wait for
(or fast-forward) the restock and confirm stock refills, the countdown resets, and a toast fires.

**Acceptance Scenarios**:

1. **Given** the shop is open, **When** it displays a stocked item, **Then** the card shows the remaining
   stock and the window shows a countdown to the next restock.
2. **Given** a stocked item with remaining stock, **When** a player buys some, **Then** the server
   decrements the remaining stock by the amount bought and the shown stock updates.
3. **Given** an item whose stock is exhausted, **When** the player tries to buy it, **Then** the server
   refuses the purchase (no coins spent, no item granted) and the card shows it as out of stock.
4. **Given** the restock interval elapses, **When** the next window begins, **Then** every stocked item
   refills to its configured stock, the countdown resets, and a restock toast is shown.
5. **Given** two servers at the same moment, **When** each shows the restock countdown, **Then** both
   show the same time remaining (schedule derived from time, not per-server randomness).

---

### User Story 4 - Night as an event (Priority: P3)

When the world flips from day to night, a brief banner announces nightfall across the screen, marking
the time when spirits come out. While it is night, if a rare spirit appears, everyone on the server sees
an announcement so they can rush to catch it.

**Why this priority**: it dramatizes the game's signature day/night identity and creates a shared moment
on the server, but the game is fully playable without it, so it is polish-tier.

**Independent Test**: in a playtest, let the cycle reach night and confirm a nightfall banner appears
briefly and clears on its own; force a rare/epic spirit to spawn and confirm a server-wide announcement
appears for the player.

**Acceptance Scenarios**:

1. **Given** the day/night cycle, **When** it transitions from day to night, **Then** a full-width,
   time-limited banner announces nightfall and then clears on its own without blocking input.
2. **Given** it is night, **When** a rare (or rarer) spirit appears, **Then** a server-wide announcement
   is shown to players on that server.
3. **Given** the transition from night to day, **When** it occurs, **Then** no nightfall banner is shown
   (the banner is for nightfall only), and any night-only announcement state is cleared.

---

### User Story 5 - First-session onboarding tutorial (Priority: P3)

A brand-new player is guided through the core loop the first time they play: a hint points them to a
plot, then walks them through planting a seed, watering it, and selling the harvested crop — one step at
a time, each step clearing as it is done. Once finished (or skipped), the tutorial never shows again for
that player.

**Why this priority**: it addresses early churn by teaching the loop, but it depends on the loop the
earlier stories exercise and benefits returning players least, so it is P3.

**Independent Test**: with a fresh profile, join and confirm the tutorial points to a plot and advances
through plant → water → sell as each action is performed; finish it and rejoin to confirm it does not
show again; on a profile that already finished it, confirm it never appears.

**Acceptance Scenarios**:

1. **Given** a new player who has not completed onboarding, **When** they join, **Then** a guided hint
   directs them to a plot as the first step.
2. **Given** the tutorial on a given step, **When** the player performs that step's action (plant, then
   water, then sell), **Then** the tutorial advances to the next step and marks the step done.
3. **Given** the player completes the final step or chooses to skip, **When** that happens, **Then** the
   tutorial closes and is recorded as done so it does not appear on future logins.
4. **Given** a player whose profile already has onboarding marked done, **When** they join, **Then** no
   tutorial is shown.

### Edge Cases

- A player claims the daily reward, keeps playing past the day boundary without rejoining, then claims
  again: the server decides claimability from its own clock, so a second claim is only allowed once a new
  day has actually begun.
- Two sessions / rejoin on the same day: the reward is claimable at most once per day; a re-login the
  same day shows today as already claimed.
- The server restarts between restock windows: stock is restored to the correct level for the current
  time window on load (schedule is time-derived, not lost with the process).
- A purchase requests more than the remaining stock: the server rejects the whole purchase atomically
  (no coins spent, no items granted) and the card shows the item as out of (or low on) stock; it never
  sells more than the remaining stock and never charges for items not granted.
- A quest's tracked action happens while its window is closed: progress still accrues on the server and
  is visible when the window is next opened.
- The day rolls over while a quest window is open: unclaimed progress for the old day does not carry into
  the new day's fresh quests.
- A rare spirit appears repeatedly in quick succession: announcements do not spam (they are rate-limited
  or de-duplicated) so the screen stays readable.
- A returning (non-new) player never sees the tutorial, and the tutorial never blocks the controls a
  player needs (movement, menu buttons).
- All new UI must coexist with open windows and toasts from Phase 2 without overlapping illegibly or
  blocking the menu column, hotbar or Roblox controls.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST offer a daily login reward on a 7-day streak track: a player may claim the
  current day's reward once per day; claiming advances the streak by one day; missing a day resets the
  streak to day one; after day seven the track loops. Claimability and the current day MUST be decided by
  the server from its own clock, using a UTC calendar day (`os.time() ÷ 86400`): a reward is claimable at
  most once per UTC day, and a gap of two or more day indices between claims resets the streak to day one.
- **FR-002**: The daily-reward window MUST open automatically on the first login of a day with an
  unclaimed reward, and MUST also be openable at any time from a "Rewards" control in the HUD menu
  column; the claim control MUST be reachable by touch, keyboard/mouse and gamepad.
- **FR-003**: The game MUST provide a set of daily quests, each with an objective, a target, current
  progress and a reward, shown in a Quests window openable from a "Quests" control in the HUD menu
  column; quests MUST reset to a fresh set each day. The day's set (a config-sized count, assumed three)
  MUST be chosen deterministically from a fixed pool by the day index, so every player on every server
  sees the same set that day.
- **FR-004**: Quest progress MUST be tracked and validated on the server from existing gameplay events
  (planting, harvesting, selling, spirit collection); the client MUST NOT decide progress or completion.
- **FR-005**: A completed quest's reward MUST be claimable exactly once; the server MUST grant it and
  MUST refuse a second claim, and a toast MUST confirm completion.
- **FR-006**: The shop MUST enforce a limited stock per stocked item: buying decrements remaining stock,
  and a purchase that exceeds the remaining stock MUST be rejected whole (atomic — no coins spent, no
  items granted, an "out of stock" message shown); the server MUST never oversell or charge for items not
  granted.
- **FR-007**: Shop stock MUST refill on a fixed restock interval whose schedule is derived from time (the
  active window = time ÷ interval), so all servers agree on the restock moment and countdown without
  cross-server messaging; on a restock, stocked items refill to their configured stock. Remaining stock
  within a window is per-server (players on one server share a stock pool); it is not synchronised across
  servers.
- **FR-008**: The shop window MUST show the remaining stock on stocked items and a countdown to the next
  restock, and MUST show a toast when a restock occurs.
- **FR-009**: The game MUST show a brief, non-blocking nightfall banner when the day/night cycle
  transitions from day to night, and MUST clear it automatically.
- **FR-010**: When a Rare or Epic spirit appears (the `SpiritTypes` tiers above Common), the game MUST
  show a server-wide announcement to players on that server; Common spirits MUST NOT announce, and
  announcements MUST NOT spam the screen (rate-limited or de-duplicated).
- **FR-011**: The game MUST guide a new player through the core loop once — plant → water → sell — one
  step at a time, advancing on the matching gameplay event, and MUST record completion so the tutorial
  does not appear on future logins; a player MUST be able to skip it, and it MUST never block movement,
  the menu column or the hotbar.
- **FR-012**: All balance numbers introduced by this feature — daily-reward amounts per streak day, quest
  objectives/targets/rewards, the restock interval and per-item stock — MUST live once in the
  `ReplicatedStorage` configuration source, with a balance document stating them; no number may be
  duplicated in controllers, GUI text or builders.
- **FR-013**: Every new remote (claim reward, claim quest, read reward/quest/stock state, any restock or
  announcement event) MUST validate the caller, argument types and ranges, ownership and cooldowns, and
  MUST fail closed (reject and log) on invalid input; no client may grant itself coins, seeds, progress
  or stock.
- **FR-014**: New persisted player data (streak/last-claim, quest day and progress/claims, onboarding
  done) MUST extend `DefaultData` and stay backward-compatible with existing saved profiles (reconcile,
  never drop fields); the schema version MUST be bumped when the shape changes.
- **FR-015**: All new and changed GUI (daily-reward window, Quests window, nightfall banner, shop stock
  and countdown, tutorial hints, HUD Rewards/Quests buttons) MUST be defined in the repository's static
  GUI definitions and their builders and regenerated, so the repository and Studio stay identical;
  controllers MUST only attach behaviour, not build whole screens at runtime.
- **FR-016**: All new UI MUST be mobile-first and input-agnostic (touch, keyboard/mouse, gamepad) through
  the shared action layer, inside the safe area, with tap targets ≥ 44×44 and readable text (body ≥ 18,
  titles/buttons ≥ 20), consistent with Phases 1–2.
- **FR-017**: New and changed UI colours MUST come from the shared theme tokens; no new hard-coded theme
  colours. Day/night palette switching itself is out of scope (Phase 4).
- **FR-018**: Each of the five stories MUST be independently playtestable in Roblox Studio with no new
  errors or warnings from the game's scripts, on a phone-landscape resolution as well as desktop.

### Key Entities *(include if feature involves data)*

- **Daily reward state (per player)**: the current streak day (1–7) and the day the reward was last
  claimed (a day index from the server clock); drives claimability and streak reset/loop.
- **Daily reward table**: the reward (coins and/or DreamSeeds) for each of the seven streak days; a
  single config entry, read by server and client.
- **Quest definition**: an objective type (plant / harvest / sell / catch-spirit), a target count, reward
  and display text; the day's active set is chosen from a fixed pool.
- **Quest state (per player)**: the day the set belongs to, per-quest progress counts, and which quests
  have been claimed; resets each day.
- **Shop stock**: per stocked item, the configured stock size and the remaining stock for the current
  restock window (per server); plus the restock interval that defines the shared schedule.
- **Restock window**: the active time window number derived from the server clock and the interval; its
  boundary is when stock refills and the countdown resets.
- **Announcement**: a transient, server-wide (per-server) message with a type (nightfall, rare spirit)
  and text, shown to all players on the server.
- **Onboarding state (per player)**: whether the first-session tutorial has been completed, and which
  step is active while it runs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can claim the daily reward using only taps on a phone; the reward is granted at
  most once per day, the streak advances on consecutive days and resets after a missed day, with the coin
  and seed balance correct at each step (0 double-claims across tests).
- **SC-002**: Every daily quest's progress reflects the matching gameplay action within one action of it
  happening, a completed quest can be claimed exactly once, and quests reset on the day boundary (0
  double-claims, 0 stale quests after rollover).
- **SC-003**: The shop never sells more of an item than its remaining stock, out-of-stock items cannot be
  bought, and stock refills on schedule; two servers checked at the same moment show the same restock
  countdown (0 overselling events, 0 schedule mismatches).
- **SC-004**: A nightfall banner appears on every day→night transition and clears on its own, and a
  server-wide announcement appears for rare-or-rarer spirits without spamming the screen (readable with
  several spirit events in a few seconds).
- **SC-005**: A fresh player is guided through plant → water → sell once and the tutorial never reappears
  after completion or skip; a player with onboarding already done never sees it (0 reappearances).
- **SC-006**: Every balance number added by this feature (reward amounts, quest targets/rewards, restock
  interval, per-item stock) matches the balance document and appears in exactly one place in the config
  (0 mismatches, 0 duplicated numbers), verified by an offline check where it can be expressed purely.
- **SC-007**: Every new element (reward window, quests window, nightfall banner, shop stock/countdown,
  tutorial hints, HUD buttons) is inside the safe area, ≥ 44×44 where tappable, with body text ≥ 18 and
  titles/buttons ≥ 20 at the phone-landscape reference resolution (0 issues).
- **SC-008**: A Studio playtest of all five flows on phone, PC and gamepad emulation produces 0 new
  errors or warnings from the game's scripts, and the repository and Studio stay in parity (scripts and
  regenerated GUI match).

## Assumptions

- **Day boundary**: a "day" is a UTC calendar day derived from the server clock (`os.time() ÷ 86400`), so
  claimability and quest resets are deterministic and consistent across servers without extra state. A
  missed day is a gap of more than one day index between claims.
- **Reward contents**: the 7-day track grants escalating coins with DreamSeeds on milestone days; exact
  amounts are set in the balance document and may be tuned there without code changes.
- **Quest set selection**: the day's quests are chosen deterministically from a fixed pool by the day
  index (so all players share the day's set and no per-player randomness needs persisting); 3 quests per
  day is the assumed set size, adjustable in config.
- **Quest tracking**: progress is derived from events the server already handles (plant, harvest, sell,
  spirit collect); no new gameplay mechanic is added, only counting and rewarding.
- **Restock model (Grow a Garden-like)**: the restock *schedule* is global (time-derived), but the
  *remaining stock* within a window is per-server — players on one server share a stock pool that refills
  at each window boundary; cross-server stock is explicitly not synchronised. Items may be configured as
  unlimited (no stock cap), e.g. the free starter watering can.
- **Rare-spirit threshold**: "rare or rarer" means the spirit system's Rare and Epic tiers (not Common);
  the existing `SpiritTypes` tiers are reused, not redefined.
- **Night banner**: brief (a couple of seconds) and non-interactive; it uses existing `DayNightUpdate`
  phase transitions and does not change the day/night timing.
- **Tutorial scope**: client-guided hints over existing gameplay; it reads the persisted onboarding flag,
  advances on the same events quests use, and is skippable. It does not add new tutorial-only gameplay.
- **Persistence**: changes are additive fields in `DefaultData` with a schema-version bump; existing
  profiles reconcile cleanly (coins/inventory/plots unchanged). Test data written to a live DataStore in
  Studio is reset or called out in the PR.
- **Icons/art**: any new icons follow the Phase 2 fallback convention (emoji/first letter) so the feature
  does not block on art.
- **Watering fix (incidental)**: the onboarding "water" step requires watering to work, but a
  pre-existing bug left the stored plot state as `"Planted"` throughout growth (the `"Growing"` state
  was only ever sent transiently), so watering could never succeed. This feature persists the
  `"Growing"` state during growth to unblock it; planting and harvest gates are unchanged.
- **Out of scope**: day/night palette/theme switching (Phase 4); any paid/Robux reward; cross-server
  global stock; leaderboards or social features beyond the per-server announcement.
