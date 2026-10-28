# Handoff — 2026-10-28

State of the work at the move from a Claude cloud session to Claude Code. Owner: Ruslan.

## Where we are

| Item | State |
|---|---|
| P2-3 Static GUI migration | Done, merged to `main` (PR #5, `a990a53`) |
| UI research + 4-phase UI plan | Done — Claude Doc https://claude.ai/artifact/DWPfqvikPcMnzLTXWz7qk6 |
| Spec Kit setup | Done on branch `speckit-setup` (skills in `.claude/skills/speckit-*`, `.specify/`) |
| Constitution v1.0.0 | Done, `.specify/memory/constitution.md` |
| Phase 1 spec `001-mobile-ui-access` | Done + clarified (5 Q&A) |
| Phase 1 plan | Done: `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` |
| Phase 1 tasks | **Next: `/speckit-tasks`** |
| Phase 1 implementation | Not started |

Branches (all pushed): `speckit-setup` (3 commits on `main`) → `001-mobile-ui-access`
(8 more commits on top). No PR opened yet; either open one PR from `001-mobile-ui-access`
(contains the setup) or merge `speckit-setup` first.

## Next steps

1. `git checkout 001-mobile-ui-access`
2. `/speckit-tasks` — the plan's "Implementation notes" give the order: foundation →
   US1/US3 → US2 → US4 → US5 → US6 → polish.
3. Optional `/speckit-analyze` (consistency of spec/plan/tasks).
4. `/speckit-implement`, playtesting each user story in Studio; validate with
   `specs/001-mobile-ui-access/quickstart.md` V0–V8.
5. PR to `main`.

## Decisions to keep (Phase 1)

- Menu buttons (Shop, Inventory) on every platform, left-centre column; key labels on PC, glyphs
  on gamepad.
- Gamepad: **Y = inventory, X = shop** (as in Grow a Garden), L1/R1 = hotbar prev/next, B = close.
- Menu column and hotbar stay usable above the window backdrop → new `HUDControls` ScreenGui
  (DisplayOrder 10) above `InventoryUI`/`ShopUI` (5) above `HUD` (0).
- Window size: phone ≤ 85% of the free height above the hotbar; tablet/PC ≤ 60% of screen height;
  shop aspect 1.85 (max 960×520), inventory 1.4 (max 700×500).
- Text ≥ 18 body, ≥ 20 titles/buttons (Roblox units). Offset content inside Scale-fitted frames.
- Disable CoreGui Backpack (otherwise L1/R1 can't be bound). Landscape lock `LandscapeSensor`.
- Colours of new/changed UI from `ReplicatedStorage/UITheme` (current dark palette).
- Phases 2–4 decisions (selling stall like Grow a Garden, restock timer + limited stock, full
  PlantData/ShopConfig + night plants + Dreamroot, day/night palettes) are in the Claude Doc.

## To verify in Studio during Phase 1

- Thumbstick-zone size (research R5, quickstart V4).
- Whether a ContextActionService binding on gamepad B fires before Roblox clears GUI selection
  (R8, V6); the plan closes the window in either case.

## Environment notes

- Spec Kit was laid out by hand from `github/spec-kit@c2354fa` (the cloud session could not run
  external installers or scripts). Locally, `.specify/scripts/bash/*.sh` can run normally; if
  you install `specify-cli`, `specify init --here --integration claude` should produce the same
  files.
- Static GUI generator needs the Luau CLI (`luau`); Rojo 7.7.x for sync.
- Repo ↔ Studio parity check used in P2-3: normalized script sources hashed with
  `h = (h*31 + byte) % 2147483647`, GUI compared by `GuiRecorder` fingerprints
  (`Tools/StaticGui/GuiRecorder.luau`).
- Studio MCP: studio id changes per Studio session — list studios first.

## Loose ends (not requested yet)

- Test data written to the real DataStore while testing: 40 coins, a carrot on Plot1.
- `AdminCommands.server.lua` still has a placeholder admin UserId; the owner's Roblox UserId is
  9874819879.
- Studio backup of the pre-P2-3 state: `ServerStorage/_Backup_2026-10-28` (can be deleted).
