--[[
    ShopController.lua — reworked for feature 002, User Story 3.

    Populates the shop as a grid of cards (cloned from ShopUI.CardsScroll.CardTemplate):
    each card shows icon, name, price and a rarity colour, with x1/x5/x10 quantity
    buttons; cards the player cannot afford at the chosen quantity are dimmed and not
    buyable. Seeds / Tools / Items are chosen with the tab row. Buying is
    server-authoritative (BuyItem); this controller only renders and requests.

    Public entry points used elsewhere: LoadShopData (called by UIController onOpen),
    Initialize (boot).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debounce = require(script.Parent.Parent.Utils.Debounce)
local GuiEffects = require(script.Parent.Parent.Utils:WaitForChild("GuiEffects"))

local ShopController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local shopUI = playerGui:WaitForChild("ShopUI")
local shopFrame = shopUI and shopUI:WaitForChild("ShopFrame", 5)
local tabContainer = shopFrame and shopFrame:WaitForChild("TabContainer", 5)
local cardsScroll = shopFrame and shopFrame:WaitForChild("CardsScroll", 5)
local cardTemplate = cardsScroll and cardsScroll:WaitForChild("CardTemplate", 5)
local loadingOverlay = shopFrame and shopFrame:WaitForChild("LoadingOverlay", 5)

local ShopConfig = ReplicatedStorage:FindFirstChild("ShopConfig") and require(ReplicatedStorage.ShopConfig)
local Theme = require(ReplicatedStorage:WaitForChild("UITheme"))

local RARITY_TOKEN = {
    Common = Theme.RarityCommon, Uncommon = Theme.RarityUncommon,
    Rare = Theme.RarityRare, Epic = Theme.RarityEpic, Legendary = Theme.RarityLegendary,
}

local GetShopDataFunc, BuyItemFunc
task.spawn(function()
    GetShopDataFunc = ReplicatedStorage:WaitForChild("GetShopData", 30)
    BuyItemFunc = ReplicatedStorage:WaitForChild("BuyItem", 30)
    print("✅ Shop RemoteFunctions loaded")
end)

-- State
local shopData = nil
local playerCoins = 0
local selectedCategory = "seeds"
local cardQty = {}   -- [itemId] = chosen quantity (1/5/10)
local cardRefs = {}  -- [itemId] = { card=, price=, buyBtn= } for re-dimming

local TAB_IDS = { seeds = "seedsTab", tools = "toolsTab", items = "itemsTab" }

local function priceOf(row)
    if type(row) == "table" then return tonumber(row.price) or 0 end
    return tonumber(row) or 0
end

local function formatName(itemId)
    local name = itemId:gsub("_", " ")
    name = name:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b:lower() end)
    return name
end

local function ShowLoading() if loadingOverlay then loadingOverlay.Visible = true end end
local function HideLoading() if loadingOverlay then loadingOverlay.Visible = false end end

-- Dim / undim a single card based on affordability at its current quantity.
local function applyAfford(itemId)
    local ref = cardRefs[itemId]
    if not ref then return end
    local qty = cardQty[itemId] or 1
    local affordable = (ref.price * qty) <= playerCoins
    ref.card.BackgroundTransparency = affordable and 0 or 0.55
    ref.buyBtn.BackgroundColor3 = affordable and Theme.Accent or Theme.Control
    ref.buyBtn.AutoButtonColor = affordable
    ref.buyBtn.Active = affordable
    ref.buyBtn.Text = affordable and ("BUY " .. (ref.price * qty)) or "Can't afford"
    ref.affordable = affordable
end

local function applyAffordAll()
    for itemId in pairs(cardRefs) do applyAfford(itemId) end
end

-- Highlight the selected quantity button on a card.
local function highlightQty(card, qty)
    for _, n in ipairs({ { "QtyX1", 1 }, { "QtyX5", 5 }, { "QtyX10", 10 } }) do
        local btn = card:FindFirstChild(n[1], true)
        if btn then
            btn.BackgroundColor3 = (n[2] == qty) and Theme.Accent or Theme.Control
        end
    end
end

-- Buy an item at its chosen quantity (server-authoritative).
function ShopController.Buy(category, itemId)
    if not BuyItemFunc then return end
    local ref = cardRefs[itemId]
    if ref and ref.affordable == false then return end -- dimmed: not buyable (FR-009)
    local qty = cardQty[itemId] or 1

    ShowLoading()
    local ok, result = pcall(function()
        return BuyItemFunc:InvokeServer(category, itemId, qty)
    end)
    HideLoading()

    local UIController = require(script.Parent.UIController)
    if ok and result and result.Success then
        UIController.UpdateCurrency(result.NewBalance or 0, 0)
        UIController.ShowNotification(string.format("Purchased %dx %s", qty, formatName(itemId)), "success")
        local InventoryController = require(script.Parent.InventoryController)
        if result.NewInventory then InventoryController.UpdateInventory(result.NewInventory) end
        playerCoins = result.NewBalance or playerCoins
        applyAffordAll() -- coins changed: re-evaluate every card (FR-009)
    elseif ok and result then
        UIController.ShowNotification(result.Error or "Purchase failed", "error")
    else
        UIController.ShowNotification("Connection error. Please try again.", "error")
    end
end

-- Build one card for an item.
local function makeCard(category, itemId, row, order)
    local price = priceOf(row)
    local rarity = (type(row) == "table" and row.rarity) or (ShopConfig and ShopConfig.GetRarity(itemId)) or "Common"
    local displayName = (type(row) == "table" and row.displayName) or formatName(itemId)
    local iconId = (type(row) == "table" and row.icon) or ""

    local card = cardTemplate:Clone()
    card.Name = "Card_" .. itemId
    card.Visible = true
    card.LayoutOrder = order
    card:FindFirstChild("RarityStrip").BackgroundColor3 = RARITY_TOKEN[rarity] or Theme.RarityCommon
    card:FindFirstChild("NameLabel").Text = displayName
    card:FindFirstChild("PriceLabel").Text = "💰 " .. price

    local icon = card:FindFirstChild("Icon")
    local fallback = icon and icon:FindFirstChild("FallbackLetter")
    if iconId ~= "" then
        icon.Image = iconId
        if fallback then fallback.Visible = false end
    else
        icon.Image = ""
        if fallback then fallback.Visible = true; fallback.Text = displayName:sub(1, 1):upper() end
    end

    cardQty[itemId] = 1
    local buyBtn = card:FindFirstChild("BuyButton")
    cardRefs[itemId] = { card = card, price = price, buyBtn = buyBtn }

    -- quantity buttons
    for _, spec in ipairs({ { "QtyX1", 1 }, { "QtyX5", 5 }, { "QtyX10", 10 } }) do
        local qbtn = card:FindFirstChild(spec[1])
        if qbtn then
            qbtn.Activated:Connect(function()
                cardQty[itemId] = spec[2]
                highlightQty(card, spec[2])
                applyAfford(itemId)
            end)
        end
    end
    highlightQty(card, 1)

    -- buy button (debounced to avoid double purchase)
    if buyBtn then
        local debouncedBuy = Debounce.create(function()
            ShopController.Buy(category, itemId)
        end, 0.6)
        buyBtn.Activated:Connect(debouncedBuy)
    end

    applyAfford(itemId)
    card.Parent = cardsScroll
end

-- Clear previously built cards (keep the template + layout + padding).
local function clearCards()
    for _, c in ipairs(cardsScroll:GetChildren()) do
        if c:IsA("Frame") and c.Name ~= "CardTemplate" then c:Destroy() end
    end
    cardRefs = {}
    cardQty = {}
end

function ShopController.SelectCategory(category)
    selectedCategory = category
    -- tab highlight
    for cat, tabName in pairs(TAB_IDS) do
        local tab = tabContainer:FindFirstChild(tabName)
        if tab then tab.BackgroundColor3 = (cat == category) and Theme.Accent or Theme.Control end
    end
    clearCards()
    if not shopData or not shopData.buy or not shopData.buy[category] then return end

    -- sort items by price for a stable, readable order
    local arr = {}
    for itemId, row in pairs(shopData.buy[category]) do
        arr[#arr + 1] = { id = itemId, row = row, price = priceOf(row) }
    end
    table.sort(arr, function(a, b) return a.price < b.price end)
    for i, entry in ipairs(arr) do
        makeCard(category, entry.id, entry.row, i)
    end
end

function ShopController.LoadShopData()
    if not GetShopDataFunc then
        if ShopConfig then shopData = { buy = ShopConfig.buy, sell = ShopConfig.sell } end
        ShopController.SelectCategory(selectedCategory)
        return
    end
    ShowLoading()
    local ok, result = pcall(function() return GetShopDataFunc:InvokeServer() end)
    HideLoading()
    if ok and result and result.Success then
        shopData = result.Config or { buy = ShopConfig.buy, sell = ShopConfig.sell }
        playerCoins = result.PlayerCoins or playerCoins
    elseif ShopConfig then
        shopData = { buy = ShopConfig.buy, sell = ShopConfig.sell }
    end
    ShopController.SelectCategory(selectedCategory)
end

function ShopController.Initialize()
    print("========================================")
    print("🏪 Initializing ShopController (card grid)...")
    print("========================================")
    if not shopFrame then
        warn("⚠️ ShopFrame not found - controller in limited mode")
        return
    end

    -- close button
    local closeButton = shopFrame:FindFirstChild("HeaderBar") and shopFrame.HeaderBar:FindFirstChild("CloseButton")
    if closeButton then
        closeButton.Activated:Connect(function()
            require(script.Parent.UIController).ToggleShop()
        end)
        GuiEffects.hoverColor(closeButton, Theme.Danger, Color3.fromRGB(230, 110, 110))
    end

    -- category tabs
    for cat, tabName in pairs(TAB_IDS) do
        local tab = tabContainer and tabContainer:FindFirstChild(tabName)
        if tab then
            tab.Activated:Connect(function() ShopController.SelectCategory(cat) end)
        end
    end

    print("✅ Shop tabs + card grid ready")
    print("========================================")
    print("✨ ShopController ready!")
    print("========================================")
end

if shopFrame then
    ShopController.Initialize()
end

return ShopController
