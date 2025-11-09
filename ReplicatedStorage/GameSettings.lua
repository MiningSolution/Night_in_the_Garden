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
        MinY = -5,                        -- минимальная высота спавна
        MaxY = 50,                        -- максимальная высота спавна
        PlayerCollectCooldownSec = 1.0,   -- задержка между сборами у игрока
        RewardMin = 1,                    -- минимальное количество DreamSeeds за сбор
        RewardMax = 3,                    -- максимальное количество DreamSeeds
        Colors = {
            Common = Color3.fromRGB(160, 200, 255),
            Rare   = Color3.fromRGB(180, 120, 255),
            Epic   = Color3.fromRGB(255, 200, 120),
        },
    },
}

-- Имя стора для ProfileService (dev/prod)
function M.ProfileStoreName()
    return M.DataStores[M.Environment] or M.DataStores.dev
end

return M
