--[[
    ShopController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/
    
    PURPOSE:
    Manages the shop UI including:
    - Loading shop data from server
    - Category navigation (Seeds, Tools, Items)
    - Item display with details
    - Buy/Sell functionality
    - Quantity selection
    - Loading states and error handling
    
    DEPENDENCIES:
    - ShopUI ScreenGui (with ShopFrame)
    - ShopConfig module (ReplicatedStorage)
    - RemoteFunctions: GetShopData, BuyItem, SellItem
    - UIController module
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debounce = require(script.Parent.Parent.Utils.Debounce)
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local ShopController = {}

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI elements with timeout
local shopUI = playerGui:WaitForChild("ShopUI", 10)
local shopFrame, leftPanel, rightPanel, loadingOverlay

if shopUI then
    shopFrame = shopUI:WaitForChild("ShopFrame", 5)
    if shopFrame then
        leftPanel = shopFrame:WaitForChild("LeftPanel", 5)
        rightPanel = shopFrame:WaitForChild("RightPanel", 5)
        loadingOverlay = shopFrame:WaitForChild("LoadingOverlay", 5)
    end
end

-- RemoteFunctions (wait for them to be created by server)
local GetShopDataFunc, BuyItemFunc, SellItemFunc

task.spawn(function()
    GetShopDataFunc = ReplicatedStorage:WaitForChild("GetShopData", 30)
    BuyItemFunc = ReplicatedStorage:WaitForChild("BuyItem", 30)
    SellItemFunc = ReplicatedStorage:WaitForChild("SellItem", 30)
    print("✅ Shop RemoteFunctions loaded")
end)

-- Load configurations
local ShopConfig = ReplicatedStorage:FindFirstChild("ShopConfig") and require(ReplicatedStorage.ShopConfig)

-- ShopConfig rows are { price = N }; older configs used a bare number. Accept both.
local function priceOf(row)
    if type(row) == "table" then return tonumber(row.price) or 0 end
    return tonumber(row) or 0
end

-- State
local shopData = nil
local selectedItem = nil
local selectedCategory = nil
local currentQuantity = 1
local itemListCache = {} -- Cache of created item buttons per category

-- Category configuration
local CATEGORIES = {
    {id = "seeds", display = "🌱 Seeds", icon = "🌱"},
    {id = "tools", display = "🔧 Tools", icon = "🔧"},
    {id = "items", display = "📦 Items", icon = "📦"}
}

--[[
    Show loading overlay
]]
local function ShowLoading()
    if loadingOverlay then
        loadingOverlay.Visible = true
    end
end

--[[
    Hide loading overlay
]]
local function HideLoading()
    if loadingOverlay then
        loadingOverlay.Visible = false
    end
end

--[[
    Format item name for display
    @param itemName (string) - Internal item name
    @return string - Formatted display name
]]
local function FormatItemName(itemName)
    local name = itemName:gsub("_", " ")
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return name
end

--[[
    Get item description
    @param category (string) - Item category
    @param itemName (string) - Item name
    @return string - Item description
]]
local function GetItemDescription(category, itemName)
    -- Try to get from PlantData
    local PlantData = ReplicatedStorage:FindFirstChild("PlantData") and require(ReplicatedStorage.PlantData)
    if PlantData then
        local plantId = itemName:gsub("_seed", ""):gsub("_crop", "")
        local plantInfo = PlantData[plantId]
        if plantInfo then
            return plantInfo.description or "No description available"
        end
    end
    
    -- Fallback descriptions by category and item type
    local descriptions = {
        seeds = {
            default = "Plant these seeds in your garden plots to grow valuable crops."
        },
        tools = {
            watering_can = "Essential tool for watering your plants.",
            lantern = "Illuminates the garden at night.",
            net = "Catch butterflies and night creatures.",
            default = "A useful tool for your gardening work."
        },
        items = {
            fertilizer = "Speeds up plant growth.",
            scarecrow = "Protects your crops from pests.",
            default = "A useful item for your garden."
        }
    }
    
    if descriptions[category] then
        -- Check for specific item
        for key, desc in pairs(descriptions[category]) do
            if itemName:lower():find(key) then
                return desc
            end
        end
        return descriptions[category].default
    end
    
    return "No description available"
end

--[[
    Load shop data from server
    Called when shop is opened
]]
function ShopController.LoadShopData()
    if not GetShopDataFunc then
        warn("⚠️ GetShopData RemoteFunction not available yet")
        
        -- Use ShopConfig as fallback
        if ShopConfig then
            shopData = ShopConfig
            ShopController.PopulateCategoryList()
            return
        end
        
        return
    end
    
    ShowLoading()
    
    print("🔄 Loading shop data from server...")
    
    local success, result = pcall(function()
        return GetShopDataFunc:InvokeServer()
    end)
    
    HideLoading()
    
    if success then
        if result and result.Success then
            shopData = result.Config or ShopConfig
            print("✅ Shop data loaded successfully")
            ShopController.PopulateCategoryList()
        else
            warn("⚠️ Server returned error:", result and result.Error or "Unknown error")
            
            -- Fallback to ShopConfig
            if ShopConfig then
                shopData = ShopConfig
                ShopController.PopulateCategoryList()
            end
        end
    else
        warn("⚠️ Failed to invoke GetShopData:", result)
        
        -- Fallback to ShopConfig
        if ShopConfig then
            shopData = ShopConfig
            ShopController.PopulateCategoryList()
        end
    end
end

--[[
    Populate left panel with category buttons
]]
function ShopController.PopulateCategoryList()
    if not leftPanel then
        warn("⚠️ LeftPanel not found")
        return
    end
    
    print("📋 Populating category list...")
    
    -- Clear existing category buttons
    for _, child in ipairs(leftPanel:GetChildren()) do
        if child:IsA("TextButton") and child.Name:match("CategoryBtn") then
            child:Destroy()
        end
    end
    
    -- Create category buttons
    for i, category in ipairs(CATEGORIES) do
        local button = Instance.new("TextButton")
        button.Name = category.id .. "CategoryBtn"
        button.Size = UDim2.new(1, -10, 0, 50)
        button.Position = UDim2.new(0, 5, 0, (i-1) * 55)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        button.BorderSizePixel = 0
        button.Text = category.display
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 18
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false
        button.Parent = leftPanel
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            if selectedCategory ~= category.id then
                TweenService:Create(button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(70, 70, 80)
                }):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            if selectedCategory ~= category.id then
                TweenService:Create(button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                }):Play()
            end
        end)
        
        -- Click handler
        button.MouseButton1Click:Connect(function()
            ShopController.SelectCategory(category.id)
            
            -- Update button states
            for _, btn in ipairs(leftPanel:GetChildren()) do
                if btn:IsA("TextButton") then
                    if btn == button then
                        btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                    end
                end
            end
        end)
    end
    
    print("✅ Created", #CATEGORIES, "category buttons")
    
    -- Auto-select first category
    if #CATEGORIES > 0 then
        ShopController.SelectCategory(CATEGORIES[1].id)
        
        -- Highlight first button
        local firstBtn = leftPanel:FindFirstChild(CATEGORIES[1].id .. "CategoryBtn")
        if firstBtn then
            firstBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        end
    end
end

--[[
    Select category and display items
    @param category (string) - Category ID
]]
function ShopController.SelectCategory(category)
    selectedCategory = category
    print("🏷️ Selected category:", category)
    
    if not shopData or not shopData.buy or not shopData.buy[category] then
        warn("⚠️ No items in category:", category)
        return
    end
    
    -- Get items in this category
    local items = shopData.buy[category]
    
    -- Convert to array and sort
    local itemArray = {}
    for itemName, price in pairs(items) do
        table.insert(itemArray, {name = itemName, price = priceOf(price)})
    end
    
    table.sort(itemArray, function(a, b)
        return a.price < b.price
    end)
    
    -- Display first item
    if #itemArray > 0 then
        ShopController.DisplayItem(category, itemArray[1].name)
    end
end

--[[
    Display item details in right panel
    @param category (string) - Item category
    @param itemName (string) - Item name
]]
function ShopController.DisplayItem(category, itemName)
    if not rightPanel then
        warn("⚠️ RightPanel not found")
        return
    end
    
    selectedItem = {category = category, name = itemName}
    currentQuantity = 1
    
    local price = priceOf(shopData and shopData.buy and shopData.buy[category] and shopData.buy[category][itemName])
    
    print(string.format("🛒 Displaying item: %s (Price: %d)", itemName, price))
    
    -- Update UI elements
    local itemIconDisplay = rightPanel:FindFirstChild("ItemIconDisplay")
    local itemNameLabel = rightPanel:FindFirstChild("ItemNameLabel")
    local itemDescriptionLabel = rightPanel:FindFirstChild("ItemDescriptionLabel")
    local priceLabel = rightPanel:FindFirstChild("PriceLabel")
    local buyButton = rightPanel:FindFirstChild("BuyButton")
    
    -- Item name
    if itemNameLabel then
        itemNameLabel.Text = FormatItemName(itemName)
    end
    
    -- Item description
    if itemDescriptionLabel then
        local description = GetItemDescription(category, itemName)
        itemDescriptionLabel.Text = description
    end
    
    -- Item icon
    if itemIconDisplay then
        itemIconDisplay.Image = "rbxassetid://0" -- Placeholder
        
        -- If no icon, show first letter
        if not itemIconDisplay:FindFirstChild("IconText") then
            local iconText = Instance.new("TextLabel")
            iconText.Name = "IconText"
            iconText.Size = UDim2.new(1, 0, 1, 0)
            iconText.BackgroundTransparency = 1
            iconText.TextColor3 = Color3.fromRGB(150, 150, 150)
            iconText.TextSize = 60
            iconText.Font = Enum.Font.GothamBold
            iconText.Parent = itemIconDisplay
        end
        
        local iconText = itemIconDisplay:FindFirstChild("IconText")
        if iconText then
            iconText.Text = FormatItemName(itemName):sub(1, 1)
        end
    end
    
    -- Price
    if priceLabel then
        priceLabel.Text = string.format("💰 Price: %d coins", price)
    end
    
    -- Buy button
    if buyButton then
        buyButton.Text = string.format("BUY FOR %d COINS", price * currentQuantity)
    end
    
    -- Update quantity display
    local quantityStepper = rightPanel:FindFirstChild("QuantityStepper")
    if quantityStepper then
        local quantityDisplay = quantityStepper:FindFirstChild("QuantityDisplay")
        if quantityDisplay then
            quantityDisplay.Text = tostring(currentQuantity)
        end
    end
end

--[[
    Update quantity
    @param delta (number) - Change in quantity (+1 or -1)
]]
function ShopController.UpdateQuantity(delta)
    -- P2-4: Use constant from Constants
    local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Constants"))
    currentQuantity = math.max(
        Constants.SHOP.MIN_PURCHASE_QUANTITY, 
        math.min(Constants.SHOP.CLIENT_MAX_QUANTITY_DISPLAY, currentQuantity + delta)
    )
    
    if not selectedItem then return end
    
    local price = (shopData and shopData.buy and shopData.buy[selectedItem.category] 
                   and shopData.buy[selectedItem.category][selectedItem.name])
    price = priceOf(price)
    
    -- Update UI
    local rightPanel = shopFrame and shopFrame:FindFirstChild("RightPanel")
    if rightPanel then
        local buyButton = rightPanel:FindFirstChild("BuyButton")
        if buyButton then
            buyButton.Text = string.format("BUY FOR %d COINS", price * currentQuantity)
        end
        
        local quantityStepper = rightPanel:FindFirstChild("QuantityStepper")
        if quantityStepper then
            local quantityDisplay = quantityStepper:FindFirstChild("QuantityDisplay")
            if quantityDisplay then
                quantityDisplay.Text = tostring(currentQuantity)
            end
        end
    end
end

--[[
    Buy selected item
    @param quantity (number) - Optional quantity override
]]
function ShopController.BuyItem(quantity)
    if not selectedItem then
        warn("⚠️ No item selected")
        return
    end
    
    if not BuyItemFunc then
        warn("⚠️ BuyItem RemoteFunction not available")
        return
    end
    
    quantity = quantity or currentQuantity
    
    ShowLoading()
    
    print(string.format("🛒 Attempting to buy %dx %s...", quantity, selectedItem.name))
    
    local success, result = pcall(function()
        return BuyItemFunc:InvokeServer(
            selectedItem.category,
            selectedItem.name,
            quantity
        )
    end)
    
    HideLoading()
    
    if success and result then
        if result.Success then
            print(string.format("✅ Purchase successful: %dx %s", result.Quantity or quantity, result.ItemName or selectedItem.name))
            
            -- Update UI with new balance
            local UIController = require(script.Parent.UIController)
            UIController.UpdateCurrency(result.NewBalance or 0, result.NewDreamSeeds or 0)
            UIController.ShowNotification(
                string.format("Purchased %dx %s!", quantity, FormatItemName(selectedItem.name)),
                "success"
            )
            
            -- Update inventory cache
            local InventoryController = require(script.Parent.InventoryController)
            if result.NewInventory then
                InventoryController.UpdateInventory(result.NewInventory)
            else
                InventoryController.AddItem(selectedItem.name, quantity)
            end
            
            -- Reset quantity
            currentQuantity = 1
            ShopController.DisplayItem(selectedItem.category, selectedItem.name)
        else
            -- Show error
            local errorMsg = result.Error or "Purchase failed"
            warn("❌ Purchase failed:", errorMsg)
            
            local UIController = require(script.Parent.UIController)
            UIController.ShowNotification(errorMsg, "error")
        end
    else
        -- Network error
        warn("❌ Network error:", result)
        
        local UIController = require(script.Parent.UIController)
        UIController.ShowNotification("Connection error. Please try again.", "error")
    end
end

--[[
    Sell item from inventory
    @param itemName (string) - Item to sell
    @param quantity (number) - Amount to sell (default: 1)
]]
function ShopController.SellItem(itemName, quantity)
    if not SellItemFunc then
        warn("⚠️ SellItem RemoteFunction not available")
        return
    end
    
    quantity = quantity or 1
    
    ShowLoading()
    
    print(string.format("💰 Attempting to sell %dx %s...", quantity, itemName))
    
    local success, result = pcall(function()
        return SellItemFunc:InvokeServer(itemName, quantity)
    end)
    
    HideLoading()
    
    if success and result then
        if result.Success then
            print(string.format("✅ Sale successful: %dx %s for %d coins", 
                result.Quantity or quantity, 
                result.ItemName or itemName,
                result.EarnedCoins or 0))
            
            -- Update UI
            local UIController = require(script.Parent.UIController)
            UIController.UpdateCurrency(result.NewBalance or 0, result.NewDreamSeeds or 0)
            UIController.ShowNotification(
                string.format("Sold %dx %s for %d coins!", quantity, FormatItemName(itemName), result.EarnedCoins or 0),
                "success"
            )
            
            -- Update inventory
            local InventoryController = require(script.Parent.InventoryController)
            if result.NewInventory then
                InventoryController.UpdateInventory(result.NewInventory)
            else
                InventoryController.RemoveItem(itemName, quantity)
            end
        else
            -- Show error
            local errorMsg = result.Error or "Sale failed"
            warn("❌ Sale failed:", errorMsg)
            
            local UIController = require(script.Parent.UIController)
            UIController.ShowNotification(errorMsg, "error")
        end
    else
        -- Network error
        warn("❌ Network error:", result)
        
        local UIController = require(script.Parent.UIController)
        UIController.ShowNotification("Connection error. Please try again.", "error")
    end
end

--[[
    Initialize shop controller
    Sets up button handlers
]]
function ShopController.Initialize()
    print("========================================")
    print("🏪 Initializing ShopController...")
    print("========================================")
    
    if not shopFrame then
        warn("⚠️ ShopFrame not found - controller in limited mode")
        return
    end
    
    -- Setup close button (P2-5: Debounced)
    local headerBar = shopFrame:FindFirstChild("HeaderBar")
    if headerBar then
        local closeButton = headerBar:FindFirstChild("CloseButton")
        if closeButton then
            local debouncedClose = Debounce.create(function()
                local UIController = require(script.Parent.UIController)
                UIController.ToggleShop()
            end, Constants.ANIMATION.FAST_TWEEN_DURATION)
            
            closeButton.MouseButton1Click:Connect(debouncedClose)
            print("✅ Close button configured (debounced)")
        end
    end
    
    -- Setup quantity stepper buttons (P2-5: Throttled)
    if rightPanel then
        local quantityStepper = rightPanel:FindFirstChild("QuantityStepper")
        if quantityStepper then
            local minusBtn = quantityStepper:FindFirstChild("MinusBtn")
            local plusBtn = quantityStepper:FindFirstChild("PlusBtn")
            
            -- Throttle quantity changes (max 10 per second)
            local throttledQuantityChange = Debounce.throttle(function(delta)
                ShopController.UpdateQuantity(delta)
            end, 10)
            
            if minusBtn then
                minusBtn.MouseButton1Click:Connect(function()
                    throttledQuantityChange(-1)
                end)
            end
            
            if plusBtn then
                plusBtn.MouseButton1Click:Connect(function()
                    throttledQuantityChange(1)
                end)
            end
            
            print("✅ Quantity stepper configured (throttled)")
        end
        
        -- Setup buy button (P2-5: Debounced)
        local buyButton = rightPanel:FindFirstChild("BuyButton")
        if buyButton then
            local debouncedBuy = Debounce.create(function()
                ShopController.BuyItem()
            end, 1.0) -- 1 second cooldown for purchases
            
            buyButton.MouseButton1Click:Connect(debouncedBuy)
            print("✅ Buy button configured (debounced)")
        end
    end
    
    print("========================================")
    print("✨ ShopController ready!")
    print("========================================")
end

-- Auto-initialize
if shopFrame then
    ShopController.Initialize()
end

return ShopController
