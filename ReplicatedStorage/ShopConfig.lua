-- ShopConfig.lua (single source of truth for the shop / economy numbers)
--
-- Seeds and crops are DERIVED from PlantData (constitution II: no number is
-- duplicated). Tools and items are not plants, so their definitions live here.
-- The derived `buy.seeds` and `sell` rows carry rarity/displayName/icon so the
-- shop cards (US3) and the sell window (US1) can render without re-deriving.
--
-- The helper functions are dropped when this table is sent through GetShopData
-- (only `buy` and `sell` data cross the wire); server and client code that needs
-- a helper requires this module directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlantData = require(ReplicatedStorage:WaitForChild("PlantData"))

local ShopConfig = {}

-- Non-plant definitions (tools, items). Prices/rarity live here once.
ShopConfig.buy = {
    seeds = {}, -- filled from PlantData below
    tools = {
        basic_watering_can    = { price = 0,  rarity = "Common", displayName = "Basic Watering Can",    icon = "" },
        improved_watering_can = { price = 50, rarity = "Rare",   displayName = "Improved Watering Can", icon = "" },
        -- feature 006 (Stage 2, US1): real slot 3–5 tools. Prices from specs/006-redesign-stage2/balance.md.
        shovel  = { price = 60,  rarity = "Common",   displayName = "Shovel",  icon = "" },
        lantern = { price = 120, rarity = "Uncommon", displayName = "Lantern", icon = "" },
        net     = { price = 200, rarity = "Rare",     displayName = "Net",     icon = "" },
    },
    items = {
        fertilizer = { price = 15, rarity = "Uncommon", displayName = "Fertilizer", icon = "" },
        dream_dust = { price = 40, rarity = "Epic",     displayName = "Dream Dust",  icon = "" },
    },
}

ShopConfig.sell = {} -- filled from PlantData below (crops only — FR-001)

-- rarity lookup for every known itemId (seeds, crops, tools, items)
local rarityById = {}

for base, def in pairs(PlantData) do
    local seedId = base .. "_seed"
    local cropId = base .. "_crop"
    ShopConfig.buy.seeds[seedId] = {
        price = def.seedPrice, rarity = def.rarity,
        displayName = def.displayName .. " Seed", icon = def.seedIcon or "",
    }
    ShopConfig.sell[cropId] = {
        price = def.sellValue, rarity = def.rarity,
        displayName = def.displayName, icon = def.cropIcon or "",
    }
    rarityById[seedId] = def.rarity
    rarityById[cropId] = def.rarity
end
for _, category in ipairs({ "tools", "items" }) do
    for itemId, row in pairs(ShopConfig.buy[category]) do
        rarityById[itemId] = row.rarity
    end
end

local function priceOf(row)
    if type(row) == "table" then return tonumber(row.price) or 0 end
    return tonumber(row) or 0
end

-- Buy price for an item in a category ("seeds"/"tools"/"items"). 0 = not purchasable.
function ShopConfig.GetBuyPrice(category, itemId)
    local cat = ShopConfig.buy[category]
    return cat and priceOf(cat[itemId]) or 0
end

-- Sell price for an item. The sell table is flat by cropId; `category` is accepted
-- for call-site compatibility but ignored.
function ShopConfig.GetSellPrice(_, itemId)
    if itemId == nil then return 0 end
    return priceOf(ShopConfig.sell[itemId])
end

-- Only crops are in the sell table, so this is the crops-only sellability gate (FR-001).
function ShopConfig.CanSell(itemId)
    local row = ShopConfig.sell[itemId]
    return row ~= nil and priceOf(row) > 0
end

function ShopConfig.GetRarity(itemId)
    return rarityById[itemId] or "Common"
end

-- Accepts a base id ("moonflower") or a seed/crop id ("moonflower_seed").
function ShopConfig.IsNightPlant(id)
    if type(id) ~= "string" then return false end
    local base = id:gsub("_seed$", ""):gsub("_crop$", "")
    local def = PlantData[base]
    return def ~= nil and def.dayNight == "night"
end

-- Returns an array of { id, price, rarity, displayName, icon } for a buy category.
function ShopConfig.GetCategoryItems(category)
    local out = {}
    local cat = ShopConfig.buy[category]
    if cat then
        for id, row in pairs(cat) do
            out[#out + 1] = {
                id = id, price = row.price, rarity = row.rarity,
                displayName = row.displayName, icon = row.icon,
            }
        end
    end
    return out
end

return ShopConfig
