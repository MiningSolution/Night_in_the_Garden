local M = {
    Environment = "dev", -- dev | prod
    DataStores = {
        dev = "PlayerData_dev",
        prod = "PlayerData_prod",
    },

    -- Длительность дня и ночи (в секундах)
    DayLengthSec = 300,
    NightLengthSec = 180,

    -- 🌙 Spirit System configuration
    SpiritSettings = {
        MaxActive = 8,                    -- максимум активных духов одновременно
        SpawnIntervalSec = 6,             -- интервал спавна духов
        DespawnAfterSec = 90,             -- время жизни духа (в секундах)
        SpawnRadius = 60,                 -- радиус спавна вокруг игрока
        -- feature 006 (US1): фонарь приманивает духов — игрок с фонарём чаще выбирается
        -- якорем спавна (LanternAnchorWeight), и духи спавнятся в меньшем радиусе вокруг
        -- него (LanternSpawnRadius). Значения из specs/006-redesign-stage2/balance.md.
        LanternSpawnRadius = 20,          -- радиус спавна вокруг игрока с фонарём (< SpawnRadius)
        LanternAnchorWeight = 3,          -- во сколько раз игрок с фонарём вероятнее как якорь
        MinY = -5,                        -- минимальная высота спавна
        MaxY = 50,                        -- максимальная высота спавна
        PlayerCollectCooldownSec = 1.0,   -- задержка между сборами у игрока
        CollectDistance = 10,             -- расстояние для сбора духа (в studs)
        RewardMin = 1,                    -- минимальное количество DreamSeeds за сбор
        RewardMax = 3,                    -- максимальное количество DreamSeeds
        Colors = {
            Common    = Color3.fromRGB(160, 200, 255),
            Uncommon  = Color3.fromRGB(120, 220, 140), -- feature 006: Moonmoth tier
            Rare      = Color3.fromRGB(180, 120, 255),
            Epic      = Color3.fromRGB(255, 200, 120),
            Legendary = Color3.fromRGB(255, 220, 120),
        },
    },
    
    -- 🌱 Plot System configuration
    PlotSettings = {
        InteractionDistance = 25,         -- максимальное расстояние для взаимодействия с грядкой (в studs)
    },
}

-- Имя стора для ProfileService (dev/prod)
function M.ProfileStoreName()
    return M.DataStores[M.Environment] or M.DataStores.dev
end

return M
