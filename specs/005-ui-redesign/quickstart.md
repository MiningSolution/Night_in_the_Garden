# Quickstart: Validate the Cosy-Garden UI Redesign (Stage 1)

How to prove the feature works. Two layers: offline (fast, CI-equivalent) and Studio (the Constitution
VI gate), in both palettes at phone-landscape.

## Prerequisites

- Luau CLI available (`command -v luau`).
- Roblox Studio open on the project, Rojo live-syncing (Studio MCP instance "🌙 Ночь в саду").

## 1. Offline gates (run after every builder/config edit)

```bash
# Regenerate the static GUI from the builders and refresh fingerprints
python3 Tools/StaticGui/build_models.py "$(command -v luau)"

# Run the offline specs (must all pass)
for f in Tools/Tests/*.spec.luau; do luau "$f"; done
```

Expected:
- `build_models.py` regenerates `StarterGui/{HUD,HUDControls,ShopUI,InventoryUI}.model.json` and prints
  a fingerprint per root; the committed `.model.json` match the builders (git diff shows only intended
  structure changes).
- `theme.spec.luau` green (Day/Night parity, contrast ≥4.5 body / ≥3.0 display, rarity distinguishable)
  — palette values unchanged by this feature.
- `responsive_layout.spec.luau` green **with the updated 5-slot hotbar expectations**.
- `economy_config.spec.luau` / `retention_config.spec.luau` green (unaffected).

## 2. Studio playtest (both palettes, phone-landscape)

Force the phase in the Studio command bar / `execute_luau` to check each palette:

```lua
game:GetService("ReplicatedStorage"):WaitForChild("DayNightUpdate"):FireAllClients("Day", 0.3)
-- then later
game:GetService("ReplicatedStorage"):WaitForChild("DayNightUpdate"):FireAllClients("Night", 0.7)
```

### HUD (US1)
- Top-centre nav shows SEEDS / GARDEN / SELL; left column shows BAG / QUESTS / GIFTS; top-left shows
  coins + **Dream Seeds**; top-right pill shows phase (+ time if cadence allows); right shows one quest
  card; bottom-centre shows five slots (3–5 locked).
- SEEDS opens the Shop on the Seeds tab; GARDEN teleports to the garden; SELL teleports to the stall
  then opens Sell; BAG/QUESTS/GIFTS open their windows (touch + key).
- Flip Day↔Night: every HUD element keeps position/size/order; colours cross-fade; nothing equips
  (SC-002).

### Seed Shop (US2)
- Cards show picture, name, rarity badge (tier text + colour), price, stock. Pick ×1/×5/×10 → Buy: coins
  and stock update in place. Sold-out, can't-afford and exceeds-stock each disable Buy with a distinct
  reason (SC-003). A failed buy keeps the window open and the selection. Fresh cards match the active
  palette (painted clones) — open the shop while in Day and confirm cards are Day-tinted.

### Backpack (US3)
- Grid of cards with rarity badges + favourite marks; tabs All/Seeds/Tools/Crops/Spirits filter
  strictly; Spirits shows the "coming soon" placeholder. Select an item → detail panel shows it with
  the right action. Equip a seed and a tool → each becomes the selected tool on the HUD strip (SC-004).
  Cards match the active palette.

### Icons (US4)
- Items with a filled icon field show a picture in shop + backpack + hotbar (SC-005). Temporarily blank
  one field, regenerate, and confirm the letter/emoji fallback still renders (no broken image).

### Output
- Studio Output shows no new errors/warnings from project scripts during the above (SC-006).

## 3. Done criteria (maps to Success Criteria)

- [ ] Reviewer judges all three screens match the concept in both palettes (SC-001).
- [ ] 0 HUD elements move/resize across a phase flip (SC-002).
- [ ] Buy allowed/blocked correctly in all three blocking cases, reasons distinguishable (SC-003).
- [ ] Equip from Backpack equips the seed and the tool (SC-004).
- [ ] Filled-icon items show pictures; blanked field falls back cleanly (SC-005).
- [ ] Offline specs + static-GUI parity green; clean Studio playtest (SC-006).
- [ ] Phone-landscape readable in both palettes, no clipped text (SC-007).
