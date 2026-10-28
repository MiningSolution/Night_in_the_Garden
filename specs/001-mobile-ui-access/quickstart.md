# Quickstart: validating Mobile UI Access (001)

How to prove the feature works end to end. Layout rules: [research.md › R3](./research.md);
names: [contracts/gui-tree.md](./contracts/gui-tree.md); bindings:
[contracts/input-actions.md](./contracts/input-actions.md).

## Prerequisites

- Branch `001-mobile-ui-access` checked out; Luau CLI available (`luau --version`).
- Roblox Studio with the place open and Studio MCP connected; Studio synced to the branch
  (Rojo `rojo serve`, or the MCP sync used for P2-3) — repo/Studio parity is step V1.
- In Studio: Test › Device emulator and Test › Controller emulator available.

## V0. Offline checks (no Studio)

```bash
luau Tools/Tests/responsive_layout.spec.luau      # layout invariants, 5 reference screens
python3 Tools/StaticGui/build_models.py "$(command -v luau)"
git status --short StarterGui/                     # expected: no changes (models are up to date)
```

Expected: all specs pass; the generator prints one fingerprint per ScreenGui (HUD, HUDControls,
InventoryUI, ShopUI) and leaves `StarterGui/` unchanged.

## V1. Repo ↔ Studio parity

Run the P2-3 parity check (script hashes + GUI fingerprints) through Studio MCP.
Expected: every script and every ScreenGui matches; `StarterGui.ScreenOrientation` is
`LandscapeSensor`.

## V2. Phone flow by touch (SC-001, US1, US3)

Device emulator: a phone in landscape at about 844×390. Start Play.

1. Menu column at the left-centre shows Shop and Inventory; no key labels.
2. Tap Shop → shop opens. Tap Inventory → shop closes, inventory opens. Tap Inventory → closes.
3. Open the shop, buy one item, close with X. Open the inventory, close by tapping the dimmed
   area. Open again and tap a hotbar slot → slot selected, window stays open.
4. With a window open, tap the backdrop over a plot → window closes, the plot is not watered
   or planted.

Expected: every step works with taps only.

## V3. Reference screens (SC-002, SC-003, US2)

Repeat at 844×390, 667×375, 1024×768, 1920×1080, 2560×1080 (custom emulator sizes are fine).
For each, open each window and take a screen capture. Then run a Studio MCP check that walks
`PlayerGui` and reports, for visible GuiObjects: any text with `TextFits == false`, body text
under 18 or title/button text under 20, any button smaller than 44×44, any window rect outside
the ScreenGui or overlapping `MenuButtons`/`Hotbar`.

Expected: 0 issues at every size; window sizes match the R3 table within a few pixels.

## V4. Touch controls clear (SC-004, US4)

On the phone and tablet sizes, during Play read
`PlayerGui.TouchGui.TouchControlFrame.JumpButton` and the thumbstick area and compare with
`HUDControls.Hotbar` rects. Move with the thumbstick and jump while tapping each slot.

Expected: no overlap; no slot tap moves or jumps the character.

## V5. PC keyboard and mouse (US1-4, US5-4, FR-014)

Desktop size, keyboard/mouse. Expected: menu buttons visible with "B" and "I" labels; B and I
toggle the windows; 1–3 select slots; typing B or I in chat opens nothing; Esc opens only the
Roblox menu.

## V6. Gamepad (SC-005, US5)

Controller emulator. Without touching mouse or keyboard:

1. Y opens the inventory (Seeds tab highlighted), X switches to the shop (first category
   highlighted), D-pad moves the highlight and stays inside the window, A presses Buy.
2. B closes the window; the highlight is cleared.
3. L1/R1 select previous/next hotbar slot, wrapping at the ends.
4. Menu buttons show Y/X glyphs; hotbar shows L1/R1 glyphs.

Then switch to mouse and back to touch: hints switch each time; menu buttons stay visible.

## V7. Orientation (US6)

On the emulator (or a real phone), rotate to portrait and back. Expected: the game stays in
landscape and flips between the two landscape directions.

## V8. Robustness and output (FR-017, SC-006, SC-007)

- Press B (or tap Shop) 10 times quickly → the shop ends closed or open, never stuck or doubled.
- A window opens within 0.3 s of the input.
- Output after V2–V7 shows no new errors or warnings from project scripts.
