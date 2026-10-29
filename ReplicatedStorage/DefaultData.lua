-- DefaultData.lua
-- Default player profile. ProfileService:Reconcile() deep-fills any field missing
-- from a loaded profile against this table, so adding fields here is backward
-- compatible with existing saves (constitution II: reconcile, never drop).
-- SchemaVersion 2 (feature 002): adds Favourites, per-plot GrowthSeconds, and
-- inventory keys for the night plants / Dreamroot / items.
-- SchemaVersion 3 (feature 003): adds DailyReward, Quests and Onboarding for the
-- retention loop. All additive; reconcile fills them into existing profiles.
-- SchemaVersion 4 (feature 006): adds SpiritCollection (per-player caught-spirit record)
-- and Stats.TotalSpiritsCollected. Additive; reconcile backfills existing profiles.
return {
    SchemaVersion = 4,
    Currency = { Coins = 50, DreamSeeds = 0 },
    Inventory = {
        -- seeds
        carrot_seed = 3, tomato_seed = 0, wheat_seed = 0, pumpkin_seed = 0,
        moonflower_seed = 0, starberry_seed = 0, dreamroot_seed = 0,
        -- tools
        basic_watering_can = 1, improved_watering_can = 0,
        -- feature 006 (US1): real slot 3–5 tools (owned via the shop; reconcile backfills at 0)
        lantern = 0, net = 0, shovel = 0,
        -- items
        fertilizer = 0, dream_dust = 0,
        -- crops (harvested, sellable)
        carrot_crop = 0, tomato_crop = 0, wheat_crop = 0, pumpkin_crop = 0,
        moonflower_crop = 0, starberry_crop = 0, dreamroot_crop = 0,
    },
    -- Per-player set of itemIds excluded from "Sell all" (FR-004). itemId -> true.
    Favourites = {},
    -- Daily login reward streak (feature 003, FR-001). StreakDay 0 = never claimed;
    -- LastClaimDay is a UTC day index (os.time()//86400); 0 = never.
    DailyReward = { StreakDay = 0, LastClaimDay = 0 },
    -- Daily quests (feature 003, FR-003/004). Day = the UTC day index the set/progress
    -- belong to (0 = no set yet); Progress[questId] = count; Claimed[questId] = true.
    Quests = { Day = 0, Progress = {}, Claimed = {} },
    -- First-session onboarding (feature 003, FR-011). Done is write-once-true; Step is
    -- the active step (0 = not started, 1..4 while running).
    Onboarding = { Done = false, Step = 0 },
    Plots = {
        Plot1 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, GrowthSeconds=0, IsWatered=false },
        Plot2 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, GrowthSeconds=0, IsWatered=false },
        Plot3 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, GrowthSeconds=0, IsWatered=false },
    },
    -- Per-player spirit collection (feature 006, US3). [spiritTypeId] = { Count, FirstCaughtAt }.
    -- Absent / FirstCaughtAt == 0 means undiscovered. The Journal reads this against SpiritData.
    SpiritCollection = {},
    Stats = { Level=1, XP=0, TotalHarvests=0, TotalEarnings=0, PlayTimeSeconds=0, TotalSpiritsCollected=0 },
    Settings = { MusicEnabled=true, SFXEnabled=true, UIScale=1.0 },
    LastLogin = 0, TotalLogins = 0, CreatedAt = 0
}
