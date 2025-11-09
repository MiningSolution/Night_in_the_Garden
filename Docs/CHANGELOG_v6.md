# Night in the Garden — v6

## P0 / P1 fixes applied
- **Security & Validation**
  - Per-player rate limiting on RemoteFunction calls (GetPlayerData, GetShopData, BuyItem, SellItem)
  - Strict input validation for shop quantities and prices
  - Valid PlotId whitelist + distance check in PlotManager
- **Data & Persistence**
  - ProfileService wiring with environment-based store name via GameSettings
- **Growth & Visualization**
  - Server pushes `TimeRemaining` with PlotStateChanged during growth
  - Harvest flow includes temporary `Harvesting` state for better client FX
- **Protocol**
  - Shop returns snapshots via RemoteFunction (no duplicate FireClient)

## Next
- Admin QA helpers (optional)
- Extended logs/metrics and unified ok()/fail() helpers across modules
