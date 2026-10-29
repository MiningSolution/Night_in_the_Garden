-- PlantData.lua
-- Single source of truth for plant / seed / crop definitions (constitution II).
--
-- Keyed by the base plant id stored in plot.PlantId (e.g. "carrot"). The buyable
-- seed is "<base>_seed" and the harvested, sellable crop is "<base>_crop".
-- ShopConfig DERIVES the seed buy rows and the crop sell rows from this table, so
-- no price or value is duplicated anywhere else (constitution II).
--
-- Numbers are transcribed from specs/002-buy-sell-economy/balance.md (feature 002).
--
-- Fields per plant:
--   displayName   string  shown in the shop / inventory / hotbar
--   rarity        string  "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
--   seedPrice     number  coins to buy one seed
--   sellValue     number  coins for one harvested crop
--   growthTimeSec number  growth seconds required to ripen (accrued per phase)
--   dayNight      string  "day" | "night" | "any" — the phase in which growth advances
--                         ("night" plants pause during the day, FR-007)
--   seedIcon      string  rbxassetid:// for the seed, "" => UI fallback (US8, later)
--   cropIcon      string  rbxassetid:// for the crop, "" => UI fallback (US8, later)

return {
    carrot = {
        displayName = "Carrot", rarity = "Common",
        seedPrice = 5, sellValue = 8, growthTimeSec = 120, dayNight = "any",
        seedIcon = "", cropIcon = "",
    },
    wheat = {
        displayName = "Wheat", rarity = "Common",
        seedPrice = 6, sellValue = 10, growthTimeSec = 150, dayNight = "any",
        seedIcon = "", cropIcon = "",
    },
    tomato = {
        displayName = "Tomato", rarity = "Uncommon",
        seedPrice = 8, sellValue = 14, growthTimeSec = 180, dayNight = "any",
        seedIcon = "", cropIcon = "",
    },
    pumpkin = {
        displayName = "Pumpkin", rarity = "Uncommon",
        seedPrice = 12, sellValue = 21, growthTimeSec = 240, dayNight = "any",
        seedIcon = "", cropIcon = "",
    },
    moonflower = {
        displayName = "Moonflower", rarity = "Rare",
        seedPrice = 20, sellValue = 38, growthTimeSec = 200, dayNight = "night",
        seedIcon = "", cropIcon = "",
    },
    starberry = {
        displayName = "Starberry", rarity = "Epic",
        seedPrice = 28, sellValue = 55, growthTimeSec = 210, dayNight = "night",
        seedIcon = "", cropIcon = "",
    },
    dreamroot = {
        displayName = "Dreamroot", rarity = "Legendary",
        seedPrice = 60, sellValue = 130, growthTimeSec = 300, dayNight = "night",
        seedIcon = "", cropIcon = "",
    },
}
