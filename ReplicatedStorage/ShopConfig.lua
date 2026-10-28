-- ShopConfig.lua (single source of truth for economy)
-- Values unchanged; helper functions added because InventoryController calls
-- ShopConfig.GetSellPrice(category, itemId). Functions are dropped when this table
-- is sent through GetShopData, so clients that need them require this module directly.
local ShopConfig = {
    buy = {
        seeds = {
            carrot_seed = { price = 5 },
            tomato_seed = { price = 8 },
            wheat_seed  = { price = 6 },
            pumpkin_seed= { price = 12 },
        },
        tools = {
            basic_watering_can = { price = 0 },
            improved_watering_can = { price = 50 },
        }
    },
    sell = {
        carrot_crop = { price = 3 },
        tomato_crop = { price = 5 },
        wheat_crop  = { price = 4 },
        pumpkin_crop= { price = 9 },
    }
}

local function priceOf(row)
    if type(row) == "table" then return tonumber(row.price) or 0 end
    return tonumber(row) or 0
end

-- Buy price for an item in a category ("seeds", "tools", ...). 0 = not purchasable.
function ShopConfig.GetBuyPrice(category, itemId)
    local cat = ShopConfig.buy[category]
    return cat and priceOf(cat[itemId]) or 0
end

-- Sell price for an item. The sell table is flat, so category is accepted for
-- compatibility but only used if a nested category table exists.
function ShopConfig.GetSellPrice(category, itemId)
    local nested = ShopConfig.sell[category]
    if type(nested) == "table" and nested.price == nil and nested[itemId] ~= nil then
        return priceOf(nested[itemId])
    end
    return priceOf(ShopConfig.sell[itemId])
end

function ShopConfig.CanSell(itemId)
    return ShopConfig.GetSellPrice(nil, itemId) > 0
end

return ShopConfig
