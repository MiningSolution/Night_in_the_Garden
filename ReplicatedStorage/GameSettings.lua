-- GameSettings.lua
local M = {
    Environment = "dev", -- dev | prod
    DataStores = {
        dev = "PlayerData_dev",
        prod = "PlayerData_prod",
    },
    DayLengthSec = 300,
    NightLengthSec = 180,
}
function M.ProfileStoreName()
    return M.DataStores[M.Environment] or M.DataStores.dev
end
return M
