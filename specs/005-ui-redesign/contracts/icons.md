# Contract: Icon Asset Manifest (licence audit)

Filled during implementation (R7 / FR-021). Each sourced image is free for commercial use; record its
id and source so the licence is auditable. The game reads only the asset id (written into the
single-source icon field); this table is documentation.

| itemId | field | assetId (`rbxassetid://…`) | source | licence |
|--------|-------|-----------------------------|--------|---------|
| carrot | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| wheat | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| tomato | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| pumpkin | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| moonflower | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| starberry | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| dreamroot | seedIcon / cropIcon | _TBD_ | _TBD_ | commercial-OK |
| basic_watering_can | icon | _TBD_ | _TBD_ | commercial-OK |
| improved_watering_can | icon | _TBD_ | _TBD_ | commercial-OK |
| fertilizer | icon | _TBD_ | _TBD_ | commercial-OK |
| dream_dust | icon | _TBD_ | _TBD_ | commercial-OK |

Notes:
- Prefer one consistent pack (e.g. Kenney CC0) so the set reads as one style (concept rule 2).
- Any field left `""` still renders the existing letter/emoji fallback (FR-020) — acceptable if no good
  match is found for an item this stage.
