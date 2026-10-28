# Contract: Static GUI tree

The instance names and properties the controllers rely on. Generated from
`Tools/StaticGui/builders/*.luau` into `StarterGui/*.model.json` (constitution III). Sizes and
positions marked *runtime* are set by `ResponsiveLayout` (see
[research.md › R3](../research.md)); the values stored in the model are the 1920×1080 defaults.

Every ScreenGui: `ResetOnSpawn = false`, `ScreenInsets = CoreUISafeInsets`,
`IgnoreGuiInset = false`, `ZIndexBehavior = Sibling`.

```text
StarterGui                              ScreenOrientation = LandscapeSensor
├── HUD                     DisplayOrder 0   (unchanged content)
│   ├── CurrencyDisplay                      CoinsLabel, DreamSeedsLabel
│   └── DayNightIndicator                    PhaseLabel, ProgressBarContainer › ProgressBar
│
├── HUDControls             DisplayOrder 10  NEW — stays above window backdrops
│   ├── MenuButtons         Frame, runtime position, UIListLayout (vertical, gap 8)
│   │   ├── ShopButton      TextButton 56×56, emoji label, Selectable = false
│   │   │   ├── KeyHint     TextLabel "B", TextSize 18
│   │   │   └── PadHint     ImageLabel 24×24
│   │   └── InventoryButton TextButton 56×56, same children, KeyHint "I"
│   └── Hotbar              MOVED from HUD; runtime position and slot size
│       ├── Slot1..3        Frame › SlotButton, ItemIcon › EmojiLabel, SelectionBorder,
│       │                   KeybindHint (TextSize 18)
│       ├── PadHintLeft     ImageLabel (L1)  NEW
│       └── PadHintRight    ImageLabel (R1)  NEW
│
├── InventoryUI             DisplayOrder 5, Enabled = false
│   ├── Backdrop            TextButton NEW, full screen, Text "", AutoButtonColor false,
│   │                       colour Theme.Backdrop, transparency Theme.BackdropTransparency
│   ├── InventoryFrame      runtime size/position; SelectionGroup = true, SelectionBehavior* = Stop
│   │   ├── HeaderBar › TitleLabel (TextSize ≥ 20), CloseButton (≥ 44×44)
│   │   ├── TabContainer › SeedsTab, ItemsTab (Selectable; SeedsTab = default selection)
│   │   └── ItemGrid        ScrollingFrame, AutomaticCanvasSize = Y, UIGridLayout
│   └── TooltipFrame        TooltipTitle (≥ 20), TooltipDescription (≥ 18)
│
└── ShopUI                  DisplayOrder 5, Enabled = false
    ├── Backdrop            TextButton NEW, as above
    └── ShopFrame           runtime size/position; SelectionGroup = true, SelectionBehavior* = Stop
        ├── HeaderBar › TitleLabel (≥ 20), CloseButton (≥ 44×44)
        ├── LeftPanel       ScrollingFrame (categories; first category = default selection)
        ├── RightPanel
        │   ├── Details     ScrollingFrame NEW wrapper: ItemIconDisplay, ItemNameLabel,
        │   │               ItemDescriptionLabel (≥ 18), PriceLabel
        │   └── Footer      Frame NEW, fixed at the bottom: QuantityStepper, BuyButton
        └── LoadingOverlay  covers the body below HeaderBar only, so CloseButton stays usable
```

Rules:
- All text: body ≥ 18, titles and button labels ≥ 20 (FR-005); no `TextScaled` in windows.
  Today's sizes below that (HUD 16; inventory 13/14 and runtime 12; shop 15; UIController 16)
  are raised.
- Colours of new and changed elements come from `ReplicatedStorage/UITheme` tokens (R10).
- Controllers look elements up by these names; renaming one is a contract change.
- `HotbarController` and `UIController` read the hotbar from `HUDControls`, not `HUD`.
