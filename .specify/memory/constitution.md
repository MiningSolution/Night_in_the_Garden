# Night in the Garden Constitution

## Core Principles

### I. Server-Authoritative Game State

- Every change to economy (coins, DreamSeeds), inventory, plots, plants and spirits MUST be decided
  and validated on the server (`ServerScriptService/Services`, `RemoteHandlers`).
- The client MUST only render state and send requests through the remotes created by
  `CreateRemotes`; it MUST NOT compute prices, rewards, growth progress or outcomes that the server
  trusts.
- Every remote handler MUST validate the caller, argument types and ranges, ownership and cooldowns,
  and MUST fail closed (reject and log) on invalid input. Suspicious requests are recorded by the
  anti-cheat logging.

Rationale: client-side calculations were the project's critical vulnerabilities (P0/P1); anything a
client can change, an exploiter can change.

### II. Single Source of Truth for Config

- Balance and content data MUST live once, in `ReplicatedStorage` config modules: `PlantData`,
  `ShopConfig`, `Constants`, `DefaultData`, `GameSettings`.
- Server and client MUST read these modules (or data the server sends from them); numbers such as
  prices, growth times, stock sizes or restock intervals MUST NOT be duplicated in controllers, GUI
  text or builders.
- Changing the shape of persisted player data MUST update `DefaultData` and keep existing profiles
  loadable (reconcile, never drop fields silently).

Rationale: one place to tune balance; no drift between what the shop shows and what the server
charges.

### III. Rojo Layout Is Canonical (Static GUI)

- The repository MUST mirror Studio exactly through the Rojo layout in `default.project.json`; the
  file suffix decides the class (`.server.lua` Script, `.client.lua` LocalScript, `.lua`
  ModuleScript, `.model.json` instances).
- GUI MUST be static: ScreenGuis live in `StarterGui/*.model.json`, generated from the builders in
  `Tools/StaticGui/builders/` (`build_models.py`). Controllers attach behaviour; they MUST NOT
  construct whole screens at runtime. Small dynamic items (list rows, toasts) are cloned from
  templates that exist in the static GUI.
- A change made directly in Studio MUST be mirrored in the repo (and its builder) in the same PR.

Rationale: P2-3 removed runtime GUI construction; the repo is the reviewable, diffable truth.

### IV. Mobile-First, Input-Agnostic UI

- The first target is a phone in landscape orientation. Every feature MUST be fully usable by touch:
  each action reachable through an on-screen control, touch targets at least 44×44 px, sizes based
  on Scale/aspect-ratio constraints rather than fixed pixel windows, and content kept inside the
  safe area (`ScreenInsets = CoreUISafeInsets`).
- Input MUST go through a shared action layer (ContextActionService-style named actions) so the same
  action can be bound to touch, mouse/keyboard and gamepad. Keyboard keys are shortcuts, never the
  only way; Roblox-reserved keys (e.g. Esc) MUST NOT be used.
- New UI MUST be designed so PC and console (gamepad, PlayStation) support can be added by adding
  bindings and selection/focus navigation, without rewriting the screen.

Rationale: most Roblox players are on phones; PC and console are planned next and must not require a
second UI.

### V. Day/Night Visual Identity via Theme Tokens

- UI colours MUST come from shared theme tokens with a light palette for day and a dark palette for
  night; the active palette follows the game's day/night phase.
- New or changed UI MUST NOT hard-code colours that belong to the theme; existing hard-coded GUI is
  migrated to tokens as screens are touched.
- Both palettes MUST keep text and icons readable (sufficient contrast) on a phone screen.

Rationale: day/night is the game's identity (spirits come out at night); tokens keep both looks
consistent and cheap to change.

### VI. Verified in Studio Before Merge

- Every change MUST be playtested in Roblox Studio (via Studio MCP or manually) before merge: the
  affected flows are exercised, and the Output shows no new errors or warnings from project scripts.
- Studio and repo MUST be in parity at merge time (scripts and GUI match).
- Persistence uses ProfileService; code MUST tolerate a missing or mock DataStore (Studio with API
  access off) and MUST NOT corrupt real data while testing. Test data written to a live DataStore is
  reset or called out in the PR.
- UI changes MUST be checked at a phone landscape resolution in the device emulator, not only at
  desktop size.

Rationale: Roblox has no CI for gameplay here; a clean playtest is the quality gate.

### VII. Simplicity and Small, Prioritized Changes

- Work follows priorities: P0 security, then P1 architecture, P2 performance/UX, P3 polish.
- Each feature or phase lands as a small PR to `main` with a clear scope; unrelated refactors go in
  their own PR.
- Prefer the simplest solution that satisfies the spec (YAGNI); extra abstraction MUST be justified
  in the plan's Complexity Tracking.

Rationale: small reviewed steps keep a multi-AI, multi-session project understandable.

## Technical Constraints

- Platform: Roblox, Luau; sync via Rojo 7.x; persistence via vendored ProfileService.
- Client architecture: `ClientMain` boots controllers (`UIController`, `HotbarController`,
  `InventoryController`, `ShopController`, ...); state lives in `StateManager` /
  `ClientDataCache`. New client features follow this controller pattern.
- Performance: no per-frame work for hidden UI; reuse instances (pooling) for frequently spawned
  objects; update UI incrementally rather than rebuilding lists.
- StreamingEnabled is on: client code MUST wait for streamed parts instead of assuming they exist.
- Third-party code is vendored with its licence in `ThirdParty/`.

## Development Workflow & Quality Gates

- Features go through Spec Kit: `/speckit-specify` → (`/speckit-clarify`) → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`; specs live in `specs/NNN-<name>/`.
- Each plan's Constitution Check MUST confirm principles I–VII or justify deviations.
- PR checklist: server validation for new remotes (I); no duplicated config numbers (II); repo/Studio
  parity and regenerated `StarterGui/*.model.json` (III); touch path and phone landscape check (IV);
  theme tokens used (V); clean Studio playtest (VI); scoped change (VII).
- PRs to `main` are reviewed before merge by the project owner.

## Governance

- This constitution supersedes other practice docs in the repo; where they conflict, it wins.
- Amendments are made with `/speckit-constitution` in a PR that states the reason and the version
  bump. Versioning is semantic: MAJOR for removing or redefining a principle, MINOR for a new
  principle or materially expanded guidance, PATCH for clarifications.
- Compliance is checked in every plan (Constitution Check) and every PR review; unjustified
  violations block merge.

**Version**: 1.0.0 | **Ratified**: 2026-10-28 | **Last Amended**: 2026-10-28
