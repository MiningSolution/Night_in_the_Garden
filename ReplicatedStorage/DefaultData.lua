-- DefaultData.lua
return {
    SchemaVersion = 1,
    Currency = { Coins = 50, DreamSeeds = 0 },
    Inventory = {
        carrot_seed = 3, tomato_seed = 0, wheat_seed = 0, pumpkin_seed = 0,
        basic_watering_can = 1, improved_watering_can = 0,
        carrot_crop = 0, tomato_crop = 0, wheat_crop = 0, pumpkin_crop = 0,
    },
    Plots = {
        Plot1 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false },
        Plot2 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false },
        Plot3 = { State="Empty", PlantId=nil, PlantedAt=0, LastWatered=0, GrowthProgress=0, IsWatered=false },
    },
    Stats = { Level=1, XP=0, TotalHarvests=0, TotalEarnings=0, PlayTimeSeconds=0 },
    Settings = { MusicEnabled=true, SFXEnabled=true, UIScale=1.0 },
    LastLogin = 0, TotalLogins = 0, CreatedAt = 0
}
