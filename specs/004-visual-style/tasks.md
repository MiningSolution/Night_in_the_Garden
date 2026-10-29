---

description: "Task list for Visual Style — Day/Night Design System (Phase 4)"
---

# Tasks: Visual Style — Day/Night Design System (Phase 4)

**Input**: Design documents from `specs/004-visual-style/`

**Prerequisites**: plan.md, spec.md, research.md (R1–R10), data-model.md, contracts/theme-tokens.md,
contracts/feedback.md, quickstart.md (V0–V9)

**Tests**: One offline Luau test is in scope (`theme.spec.luau`, palette/contrast parity) — it is part
of the project's quality gate, so it is listed as a foundational task, not TDD-first.

**Organization**: by user story (US1 P1 live switch, US2 P2 readable/consistent, US3 P3 feedback).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- Paths are repository-relative. This is a Roblox client + static-GUI change (no server module).

---

## Phase 1: Setup (Blocking gate)

**Purpose**: Lock the visual design before any themed-UI code (FR-019, owner-confirmed blocking).

- [X] T001 Produce mock-ups of all seven key screens in **both** palettes; present to the owner and get
  approval. **DONE (2026-10-29)**: owner approved `Garden_UI_Day_Night_v2.html` + handoff ("такой стиль
  очень красивый, основывайся на нём"). Approved palette + design-language tokens transcribed into
  `contracts/theme-tokens.md`. Scope locked: re-skin existing screens in both palettes; night is
  re-skinned too (indigo). Out of scope: HUD relayout, 2nd currency, Spirit Journal.

**Checkpoint**: ✅ Owner approved the look; both palettes' RGBs + style tokens are locked.

---

## Phase 2: Foundational (Blocking prerequisites for all stories)

**Purpose**: The single colour source and the build→runtime binding mechanism everything depends on.

- [X] T002 [P] Extend `Tools/StaticGui/GuiRecorder.luau` to record `obj:SetAttribute(name, value)` into
  the node (`attributes`/`attrKeys`; mirror to `real:SetAttribute` in Studio mode), emit an
  `attributes` map in `R.toModel`, and include attributes in `R.fingerprint`. **DONE.**
- [X] T003 Restructure `ReplicatedStorage/UITheme.lua` into `Palettes.Day` + `Palettes.Night` (both
  re-skinned per `contracts/theme-tokens.md`: Night = indigo "moonlit", Day = warm "garden"; tokens
  incl. `Accent`/`AccentDeep`/`Positive`/`Sell`/`TextOnBright`/`Outline`/`OutlineDeep`/`HeaderTop`/
  `HeaderBottom`), plus `DefaultPhase = "Night"`, `Resolve(token, phase)`, `UITheme.Style` (corner
  radius, outline thickness, shadow offset, display/body font), and flat back-compat fields = Night
  (+ legacy `Header`/`BannerNight`/`BackdropTransparency`). **DONE.**
- [X] T004 Extend `Tools/StaticGui/build_models.luau` `encode()` to emit the `attributes` key **after
  `properties`, before `children`**. **DONE.**
- [ ] T005 [P] Add `Tools/Tests/theme.spec.luau`: Day/Night define the same token key set; every colour
  token is a `Color3`; `DefaultPhase == "Night"`; flat fields equal `Palettes.Night`; `UITheme.Style`
  present; every contrast pair in `contracts/theme-tokens.md` is ≥ 4.5:1 in **both** palettes and
  rarity hues are mutually distinguishable (pure WCAG math, no `game` global) (depends on T003).
  → **Engine agent B.**

**Checkpoint**: `luau Tools/Tests/theme.spec.luau` passes; the generator carries attributes (T002/T004
verified by regenerating and re-running the offline suite during consolidation).

---

## Phase 3: User Story 1 — The interface follows the time of day (Priority: P1) 🎯 MVP

**Goal**: The whole UI shifts to the Day palette by day and the Night palette by night, switching
smoothly on `DayNightUpdate`, over the static GUI, with dynamic elements and joiners painted correctly.

**Independent Test**: quickstart V2–V7 — force Day/Night and confirm every key screen retint smoothly
with no flash and nothing left in the old palette; closed windows open in the right palette; toasts/
cards/rows/float coins and a mid-cycle joiner are all painted to the current phase.

- [ ] T006 [US1] Add a local `themeBind(obj, prop, token)` helper (bakes the Night colour AND tags
  `Theme_<prop>=token`) and apply the approved **design language** in
  `Tools/StaticGui/builders/CreateHUDControls.luau`: tag every themed colour, add `UICorner`
  (`UITheme.Style.CornerRadius`), `UIStroke` (tagged `Theme_Color = "Outline"`/`"OutlineDeep"`,
  thickness from Style), a bottom-shadow frame, `UIGradient` on headers/primary buttons (tagged
  `Theme_GradientTop`/`Theme_GradientBottom`), and the display/body fonts; regenerate and commit
  `StarterGui/HUDControls.model.json` (depends on T002, T003, T004).
- [ ] T007 [US1] Verify in Studio (quickstart V1) that the baked `Theme_*` attribute round-trips onto
  the live instance (Properties → Attributes / `inspect_instance`). **Gate**: if attributes are absent,
  implement the `ThemeBindings.lua` fallback from research R2 before continuing (depends on T006).
- [ ] T008 [US1] Apply the same design-language re-skin + tags to the other builders, regenerate and
  commit their models. **PR1**: `CreateHUD`, `CreateShopUI`, `CreateInventoryUI`. **PR2**:
  `CreateSellUI`, `CreateNotifications`, `CreateDailyRewardUI`, `CreateQuestsUI` → `StarterGui/*.model.json`
  (depends on T007).
- [ ] T009 [US1] Create `StarterPlayer/StarterPlayerScripts/Controllers/ThemeController.lua`: subscribe
  to `DayNightUpdate`; hold `currentPhase`; on a Day↔Night change run one `Repaint(phase)` that tweens
  each `Theme_<Prop>` colour attribute across the known ScreenGuis to `UITheme.Resolve(token, phase)`
  (~0.4 s, Quad/Out), **including `UIStroke` (`Theme_Color`) and rebuilding `UIGradient` `ColorSequence`s
  from `Theme_GradientTop`/`Theme_GradientBottom`**; `PaintInstant(inst)`/`Paint(root)` apply the current
  palette without a tween; `Current()`/`CurrentPhase()`; `Initialize()` paints the known GUIs on join
  (FR-005/006/007/009) (depends on T003). → **Engine agent A.**
- [ ] T010 [US1] Boot `ThemeController` from the client bootstrap (`EventHandlers.client.lua` /
  `ClientMain`) after the GUIs exist, so paint-on-join runs before the first `DayNightUpdate`; the
  existing `DayNightUpdate` handler also forwards the phase to `ThemeController` (depends on T009).
  → **Engine agent A** (same file ownership).
- [ ] T011 [US1] Paint runtime-created elements to the current phase (FR-008): `Utils/ToastQueue.lua`
  (each shown toast), `Controllers/ShopController.lua` (cloned cards), `Controllers/SellController.lua`
  (cloned rows), `Controllers/DailyRewardController.lua` + `Controllers/QuestController.lua` (cloned
  rows), and `Controllers/UIController.lua` `FloatCoins` (read `ThemeController.Current().Coins`)
  (depends on T009).

**Checkpoint**: Live day/night palette switch works end-to-end (MVP). Studio V0–V7 pass, no new errors.

---

## Phase 4: User Story 2 — Every screen stays readable and consistent (Priority: P2)

**Goal**: Both palettes are legible on a phone, rarity/semantic hues stay distinguishable, and no
hard-coded theme colour remains on any touched screen.

**Independent Test**: `theme.spec.luau` green (contrast pairs ≥ 4.5:1 both palettes); a phone-landscape
sweep of each screen in both palettes reads clearly; a search of the touched screens finds no literal
theme `Color3`.

- [ ] T012 [US2] Confirm/adjust the `UITheme.Day` token values so every contrast pair passes
  `theme.spec.luau` (deepen Day text/currency/accents as needed); keep rarity hues mutually
  distinguishable; re-run the test green (edits in `ReplicatedStorage/UITheme.lua`) (depends on T005).
- [ ] T013 [US2] Migrate remaining hard-coded theme colours on touched screens to tokens (FR-012, R9):
  in `Controllers/UIController.lua` move the day/night indicator's sun/moon marker colours to
  single-source constants (sun gold / moon blue are phase-identity markers, kept palette-independent in
  `UITheme.Style`, not literals in the controller); fold hint-chip backgrounds into the `Backdrop`/
  surface tokens; leave genuine non-theme tints (e.g. coin-float text stroke) and note them. Regenerate
  and commit the affected `StarterGui/*.model.json` (depends on T003, T008).
- [ ] T014 [US2] Studio phone-landscape check (quickstart V2 + owner pass prep): each key screen in both
  palettes — body text, currency, muted labels and the five rarity swatches read clearly; record any
  token that needs a nudge and fix in T012 (depends on T012, T013).

**Checkpoint**: Both palettes are readable and fully tokenised; US1 + US2 both hold.

---

## Phase 5: User Story 3 — Actions feel tactile (Priority: P3)

**Goal**: Press sound on main buttons, a distinct purchase sound on a confirmed buy, and a window-open
animation — none blocking the action, all honouring the sound setting.

**Independent Test**: quickstart V8–V9 — windows ease open and are instantly interactive; a tap plays
the press sound and a confirmed buy the purchase sound (rejected buy does not); sound-off and empty
ids are silent with no errors.

- [ ] T015 [P] [US3] Add `ReplicatedStorage/UISound.lua` = `{ Press = "", Purchase = "", Volume = 0.5 }`
  (owner-supplied ids; empty = silent) per `contracts/feedback.md`. → **Engine agent C.**
- [ ] T016 [US3] Create `StarterPlayer/StarterPlayerScripts/Controllers/SoundController.lua`:
  `Press()` (rate-limited ~60 ms) and `Purchase()`, one reusable `Sound` under `SoundService`, volume
  from `UISound`, no-op on empty/invalid id (`pcall`) and when the game sound is off; never yields the
  caller (depends on T015). → **Engine agent C.**
- [ ] T017 [P] [US3] Add `GuiEffects.openWindow(frame)` (scale ~0.92→1 + fade, ~0.18 s, Quad/Out,
  interactive throughout) in `StarterPlayer/StarterPlayerScripts/Utils/GuiEffects.lua` and call it from
  `WindowManager.Open` after the frame is shown (`StarterPlayer/StarterPlayerScripts/Utils/WindowManager.lua`),
  leaving the one-window/backdrop/selection logic unchanged (FR-015). → **Engine agent D.**
- [ ] T018 [US3] Wire feedback: press sound on `Activated` for the menu + teleport buttons
  (`UIController`), window close/backdrop (`WindowManager`), tabs and buy/sell/claim buttons (their
  controllers); **purchase** sound only on the server-confirmed success branch of `BuyItem` in
  `Controllers/ShopController.lua` (FR-013/014/016/017/018) (depends on T016).

**Checkpoint**: All three stories hold; feedback never blocks or mis-fires.

---

## Phase 6: Polish & Cross-Cutting

- [ ] T019 [P] Update `README.md` (new "Phase 4: visual style" section — two palettes, runtime switch,
  token attributes, sounds/animation) and `Docs/HANDOFF.md` (Phase 4 state + owner device-emulator
  pass referencing quickstart V0–V9).
- [ ] T020 Run the full offline suite as CI does (`for f in Tools/Tests/*.spec.luau; do luau "$f"; done`)
  and the static-GUI parity (`python3 Tools/StaticGui/build_models.py "$(command -v luau)"` then
  `git diff --quiet -- StarterGui`); fix any drift.
- [ ] T021 Final Studio playtest of quickstart V0–V9 with no new Output errors; confirm Studio ⇄ repo
  parity; note any owner-only device-emulator/gamepad items in the PR.

---

## Dependencies & Execution Order

- **Phase 1 (gate)** blocks everything visual: T001 must be approved before T003 (Day values) and any
  Phase 3+ themed code.
- **Phase 2** blocks the stories: T002→T004 (generator), T003→T005 (palette+test), all before US1.
- **US1 (Phase 3)** is the MVP and depends only on Phase 2. T006→T007 (round-trip gate)→T008; T009→T010;
  T009→T011.
- **US2 (Phase 4)** refines colours/migration; depends on T003/T005 (test) and T008 (tagged builders).
- **US3 (Phase 5)** is independent of US1/US2 and can proceed any time after Phase 1 (it adds sound +
  animation, touching different files); listed last by priority.
- **Polish (Phase 6)** after the desired stories.

### Within a story

- Tag a builder → regenerate → commit the model (never hand-edit `.model.json`).
- `ThemeController` before the paint-on-clone wiring and before `ClientMain` boot order matters.

### Parallel opportunities

- T002 (generator) ∥ T003 (palette) — different files.
- T005 (test) ∥ later once T003 lands.
- T015 (UISound) ∥ T017 (GuiEffects/WindowManager) — different files.
- T019 (docs) ∥ the final validation tasks.

## Parallel Example: Phase 2

```bash
# Independent foundational files:
Task: "Extend GuiRecorder.luau to record/emit attributes (T002)"
Task: "Restructure UITheme.lua into two palettes + resolver (T003)"
# then, dependent:
Task: "theme.spec.luau contrast/parity test (T005, after T003)"
Task: "build_models.luau encode attributes (T004, after T002)"
```

## Engine fan-out (4 Sonnet subagents, owner-requested)

The foundational code modules are file-disjoint and run in parallel (one Sonnet subagent each), then
the parent consolidates (regenerate models, run the offline suite, reconcile) and verifies in Studio:

- **Agent A** — `ThemeController.lua` (T009) + bootstrap wiring (T010).
- **Agent B** — `Tools/Tests/theme.spec.luau` (T005).
- **Agent C** — `ReplicatedStorage/UISound.lua` (T015) + `SoundController.lua` (T016).
- **Agent D** — `GuiEffects.openWindow` + `WindowManager.Open` wiring (T017).

(`UITheme.lua`, `GuiRecorder.luau`, `build_models.luau` are already done by the parent; agents must not
touch them, the builders, `StarterGui/*.model.json`, or git.)

## Implementation Strategy

- **MVP = US1**: Setup gate (T001) → Foundational (T002–T005) → US1 (T006–T011) → validate V0–V7. The
  live day/night palette switch is the headline and the hardest piece; prove it first.
- **Incremental**: add US2 (readability/migration) → re-validate; add US3 (feedback) → validate V8–V9.
- Commit per user story after a clean Studio playtest; land as one Phase 4 PR to `main` (matching
  Phases 1–3). Regenerate `StarterGui/*.model.json` and keep the offline suite green before each commit.

## Notes

- No server module, no remote, no persistence change (SchemaVersion stays 3); no DataStore writes.
- Rojo does not sync `ServerScriptService` (irrelevant here — client/GUI only); it does sync
  `StarterGui`/`StarterPlayer`/`ReplicatedStorage`.
- Synthetic MCP clicks don't fire `Activated`, so press/purchase sounds are verified by a real tap/
  click in the owner's pass; the rest is MCP-verifiable.
