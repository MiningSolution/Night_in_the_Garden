-- ShopConfig.lua (single source of truth for economy)
return {
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
