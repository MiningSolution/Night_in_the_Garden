-- ShopStockService.lua
-- Per-server limited shop stock with a time-derived restock schedule (feature 003,
-- US3/FR-006/007). The restock window is RestockWindow(os.time()) so every server
-- agrees on the moment and countdown with no cross-server messaging; remaining stock
-- within a window is per-server. Items absent from RetentionConfig.ShopStock are
-- unlimited. Nothing here is persisted — on server start the stock is reconstructed
-- for the current window (constitution I: stock is world state, decided on the server).

local RS = game:GetService("ReplicatedStorage")
local RetentionConfig = require(RS:WaitForChild("RetentionConfig"))
local ShopRestocked = RS:WaitForChild("ShopRestocked")

local M = {}

local remaining = {}       -- [itemId] = count (only for limited items)
local currentWindow = nil  -- the window number `remaining` was filled for

-- Fill remaining to the configured caps for a window (no broadcast).
local function fill(window)
    currentWindow = window
    remaining = {}
    for itemId, cap in pairs(RetentionConfig.ShopStock) do
        remaining[itemId] = cap
    end
end

-- Initialise for the current window at load (no broadcast on server start).
fill(RetentionConfig.RestockWindow(os.time()))

-- A snapshot of remaining stock for limited items (client display).
function M.GetStock()
    local snap = {}
    for id, n in pairs(remaining) do snap[id] = n end
    return snap
end

-- Server os.time() when the current window ends / the next begins.
function M.RestockAt()
    return RetentionConfig.RestockAt(os.time())
end

function M.Interval()
    return RetentionConfig.RestockIntervalSec
end

-- Remaining for one item; nil means unlimited.
function M.Remaining(itemId)
    if RetentionConfig.ShopStock[itemId] == nil then return nil end
    return remaining[itemId] or 0
end

-- Atomically reserve `qty` of an item: unlimited -> always true; limited -> true and
-- decrement only if enough remain, else false (fail closed, no oversell — R5).
function M.TryReserve(itemId, qty)
    if RetentionConfig.ShopStock[itemId] == nil then return true end -- unlimited
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    local have = remaining[itemId] or 0
    if have < qty then return false end
    remaining[itemId] = have - qty
    return true
end

-- Give back a reservation (e.g. the coin spend failed after reserving). Clamped to
-- the configured cap so a release can never push remaining above the window's stock.
function M.Release(itemId, qty)
    if RetentionConfig.ShopStock[itemId] == nil then return end
    qty = math.max(0, math.floor(tonumber(qty) or 0))
    local cap = RetentionConfig.ShopStock[itemId]
    remaining[itemId] = math.min(cap, (remaining[itemId] or 0) + qty)
end

-- 1 Hz boundary tick: when the window advances, refill and broadcast ShopRestocked.
-- The tick is the single place that advances the window, so a read never silently
-- consumes a restock without the broadcast firing.
task.spawn(function()
    while true do
        task.wait(1)
        local w = RetentionConfig.RestockWindow(os.time())
        if w ~= currentWindow then
            fill(w)
            ShopRestocked:FireAllClients(M.RestockAt(), M.GetStock())
            print("[ShopStock] Restocked (window " .. tostring(w) .. ")")
        end
    end
end)

return M
