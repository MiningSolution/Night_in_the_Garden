--[[
    InventoryController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/
    
    PURPOSE:
    Manages the inventory UI including:
    - Inventory grid display with item slots
    - Item tooltips on hover
    - Tab switching (Seeds/Items)
    - Item slot creation and styling
    - Quantity badges
    - Integration with ClientDataCache
    
    DEPENDENCIES:
    - InventoryUI ScreenGui (with InventoryFrame)
    - PlantData module (ReplicatedStorage)
    - ShopConfig module (ReplicatedStorage)
    - ClientDataCache module
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StateManager = require(script.Parent.Parent.Utils:WaitForChild("StateManager"))
local Debounce = require(script.Parent.Parent.Utils.Debounce)
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local InventoryController = {}

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI elements with timeout
local inventoryUI = playerGui:WaitForChild("InventoryUI", 10)
local inventoryFrame, itemGrid, tooltipFrame

if inventoryUI then
    inventoryFrame = inventoryUI:WaitForChild("InventoryFrame", 5)
    if inventoryFrame then
        itemGrid = inventoryFrame:WaitForChild("ItemGrid", 5)
        tooltipFrame = inventoryFrame:WaitForChild("TooltipFrame", 5)
    end
end

-- Load configurations
local PlantData = ReplicatedStorage:FindFirstChild("PlantData") and require(ReplicatedStorage.PlantData)
local ShopConfig = ReplicatedStorage:FindFirstChild("ShopConfig") and require(ReplicatedStorage.ShopConfig)

-- State
local currentTab = "Seeds" -- "Seeds" or "Items"
local cachedInventory = {} -- P1-2: Will be synced from StateManager

-- Item categories
local SEED_KEYWORDS = {"seed", "carrot", "tomato", "wheat", "pumpkin", "moonflower", "starberry"}
local TOOL_KEYWORDS = {"watering_can", "lantern", "net", "scarecrow"}

--[[
    Check if item is a seed
    @param itemName (string) - Name of the item
    @return boolean
]]
local function IsSeed(itemName)
    local lowerName = itemName:lower()
    for _, keyword in ipairs(SEED_KEYWORDS) do
        if lowerName:find(keyword) then
            return true
        end
    end
    return false
end

--[[
    Check if item is a tool
    @param itemName (string) - Name of the item
    @return boolean
]]
local function IsTool(itemName)
    local lowerName = itemName:lower()
    for _, keyword in ipairs(TOOL_KEYWORDS) do
        if lowerName:find(keyword) then
            return true
        end
    end
    return false
end

--[[
    Get item display data (name, icon, description)
    @param itemName (string) - Internal item name
    @return table with displayName, icon, description
]]
local function GetItemDisplayData(itemName)
    -- Try to get from PlantData first
    if PlantData then
        local plantId = itemName:gsub("_seed", ""):gsub("_crop", "")
        local plantInfo = PlantData[plantId]
        
        if plantInfo then
            return {
                displayName = plantInfo.displayName or itemName,
                icon = plantInfo.icon or "rbxassetid://0",
                description = plantInfo.description or "No description available",
                sellValue = plantInfo.sellValue or 0
            }
        end
    end
    
    -- Fallback: Generate from item name
    local displayName = itemName:gsub("_", " ")
    displayName = displayName:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    
    return {
        displayName = displayName,
        icon = "rbxassetid://0",
        description = "A useful item for your garden",
        sellValue = 0
    }
end

--[[
    Update existing slot instead of recreating (P1-4: Performance optimization)
    @param slot (Frame) - Existing slot frame
    @param itemName (string) - Item name
    @param quantity (number) - Item quantity
]]
local function UpdateSlot(slot, itemName, quantity)
    -- Update quantity badge
    local qtyBadge = slot:FindFirstChild("QuantityBadge")
    
    if quantity > 1 then
        if not qtyBadge then
            -- Create badge if needed
            qtyBadge = Instance.new("Frame")
            qtyBadge.Name = "QuantityBadge"
            qtyBadge.Size = UDim2.new(0, 35, 0, 18)
            qtyBadge.Position = UDim2.new(1, -3, 1, -3)
            qtyBadge.AnchorPoint = Vector2.new(1, 1)
            qtyBadge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            qtyBadge.BackgroundTransparency = 0.4
            qtyBadge.BorderSizePixel = 0
            qtyBadge.Parent = slot
            
            local badgeCorner = Instance.new("UICorner")
            badgeCorner.CornerRadius = UDim.new(0, 4)
            badgeCorner.Parent = qtyBadge
            
            local qtyLabel = Instance.new("TextLabel")
            qtyLabel.Size = UDim2.new(1, 0, 1, 0)
            qtyLabel.BackgroundTransparency = 1
            qtyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            qtyLabel.TextSize = 12
            qtyLabel.Font = Enum.Font.GothamBold
            qtyLabel.Parent = qtyBadge
        end
        
        local qtyLabel = qtyBadge:FindFirstChild("TextLabel")
        if qtyLabel then
            qtyLabel.Text = "×" .. quantity
        end
    else
        -- Remove badge if quantity is 1 or less
        if qtyBadge then
            qtyBadge:Destroy()
        end
    end
    
    -- Update item name if changed
    local nameLabel = slot:FindFirstChild("ItemName")
    if nameLabel then
        local itemData = GetItemDisplayData(itemName)
        nameLabel.Text = itemData.displayName
    end
end

--[[
    Refresh inventory grid based on current tab
    P1-4: Optimized to use incremental updates instead of full recreation
]]
function InventoryController.RefreshGrid()
    if not itemGrid then
        warn("⚠️ ItemGrid not found in InventoryUI")
        return
    end
    
    print("🔄 Refreshing inventory grid (incremental, Tab: " .. currentTab .. ")...")
    
    -- Filter items by current tab
    local displayItems = {}
    
    for itemName, quantity in pairs(cachedInventory) do
        if quantity > 0 then
            if currentTab == "Seeds" and IsSeed(itemName) then
                table.insert(displayItems, {name = itemName, qty = quantity})
            elseif currentTab == "Items" and not IsSeed(itemName) then
                table.insert(displayItems, {name = itemName, qty = quantity})
            end
        end
    end
    
    -- Sort items alphabetically
    table.sort(displayItems, function(a, b)
        return a.name < b.name
    end)
    
    -- P1-4: Get existing slots (incremental update)
    local existingSlots = {}
    for _, child in ipairs(itemGrid:GetChildren()) do
        if child:IsA("Frame") and child.Name == "ItemSlot" then
            local itemNameAttr = child:GetAttribute("ItemName")
            if itemNameAttr then
                existingSlots[itemNameAttr] = child
            end
        end
    end
    
    -- P1-4: Update/create slots incrementally
    local usedSlots = {}
    
    for i, item in ipairs(displayItems) do
        local existingSlot = existingSlots[item.name]
        
        if existingSlot then
            -- Update existing slot
            UpdateSlot(existingSlot, item.name, item.qty)
            usedSlots[item.name] = true
        else
            -- Create new slot
            local slot = InventoryController.CreateSlot(item.name, item.qty)
            slot:SetAttribute("ItemName", item.name) -- Store item name for future lookups
            slot.Parent = itemGrid
            usedSlots[item.name] = true
        end
    end
    
    -- P1-4: Remove slots that are no longer needed
    for itemName, slot in pairs(existingSlots) do
        if not usedSlots[itemName] then
            slot:Destroy()
        end
    end
    
    print(string.format("✅ Grid refreshed: %d items displayed (incremental update)", #displayItems))
end

--[[
    Create inventory slot UI element
    @param itemName (string) - Name of the item
    @param quantity (number) - Quantity of the item
    @return Frame - The created slot
]]
function InventoryController.CreateSlot(itemName, quantity)
    local itemData = GetItemDisplayData(itemName)
    
    -- Main slot frame
    local slot = Instance.new("Frame")
    slot.Name = "ItemSlot"
    slot.Size = UDim2.new(0, 100, 0, 100)
    slot.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    slot.BorderSizePixel = 0
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = slot
    
    -- Item icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "ItemIcon"
    icon.Size = UDim2.new(0, 70, 0, 70)
    icon.Position = UDim2.new(0.5, 0, 0.4, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = itemData.icon
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = slot
    
    -- If no icon available, show first letter
    if itemData.icon == "rbxassetid://0" or itemData.icon == "rbxassetid://placeholder" then
        icon.Image = ""
        
        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.Text = itemData.displayName:sub(1, 1):upper()
        iconText.TextColor3 = Color3.fromRGB(150, 150, 150)
        iconText.TextSize = 40
        iconText.Font = Enum.Font.GothamBold
        iconText.Parent = icon
    end
    
    -- Item name label (bottom of slot)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0.5, 0, 1, -22)
    nameLabel.AnchorPoint = Vector2.new(0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemData.displayName
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextScaled = true
    nameLabel.TextWrapped = true
    nameLabel.Parent = slot
    
    -- Quantity badge (bottom-right corner)
    if quantity > 1 then
        local badge = Instance.new("Frame")
        badge.Name = "QuantityBadge"
        badge.Size = UDim2.new(0, 35, 0, 18)
        badge.Position = UDim2.new(1, -3, 1, -3)
        badge.AnchorPoint = Vector2.new(1, 1)
        badge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        badge.BackgroundTransparency = 0.4
        badge.BorderSizePixel = 0
        badge.Parent = slot
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = badge
        
        local qtyLabel = Instance.new("TextLabel")
        qtyLabel.Size = UDim2.new(1, 0, 1, 0)
        qtyLabel.BackgroundTransparency = 1
        qtyLabel.Text = "×" .. quantity
        qtyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        qtyLabel.TextSize = 12
        qtyLabel.Font = Enum.Font.GothamBold
        qtyLabel.Parent = badge
    end
    
    -- Hover effect frame
    local hoverFrame = Instance.new("Frame")
    hoverFrame.Name = "HoverHighlight"
    hoverFrame.Size = UDim2.new(1, 0, 1, 0)
    hoverFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hoverFrame.BackgroundTransparency = 1
    hoverFrame.BorderSizePixel = 0
    hoverFrame.ZIndex = 2
    hoverFrame.Parent = slot
    
    local hoverCorner = Instance.new("UICorner")
    hoverCorner.CornerRadius = UDim.new(0, 8)
    hoverCorner.Parent = hoverFrame
    
    -- Interactive button (for hover detection)
    local button = Instance.new("TextButton")
    button.Name = "SlotButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 3
    button.Parent = slot
    
    -- Hover events
    button.MouseEnter:Connect(function()
        InventoryController.ShowTooltip(itemName, slot)
        
        -- Highlight effect
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(hoverFrame, tweenInfo, {
            BackgroundTransparency = 0.85
        }):Play()
        TweenService:Create(slot, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        InventoryController.HideTooltip()
        
        -- Remove highlight
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(hoverFrame, tweenInfo, {
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(slot, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
    
    -- Click event (for future use - equip, use, etc.)
    button.MouseButton1Click:Connect(function()
        print("🖱️ Clicked item:", itemData.displayName)
        -- TODO: Implement item actions (equip, use, sell)
    end)
    
    return slot
end

--[[
    Show tooltip for an item
    @param itemName (string) - Name of the item
    @param parentSlot (Frame) - The slot frame to position tooltip near
]]
function InventoryController.ShowTooltip(itemName, parentSlot)
    if not tooltipFrame then
        warn("⚠️ TooltipFrame not found")
        return
    end
    
    local itemData = GetItemDisplayData(itemName)
    local quantity = cachedInventory[itemName] or 0
    
    -- Get sell price
    local sellPrice = 0
    if ShopConfig then
        -- Try different categories
        sellPrice = ShopConfig.GetSellPrice("crops", itemName)
        if sellPrice == 0 then
            sellPrice = ShopConfig.GetSellPrice("items", itemName)
        end
        if sellPrice == 0 then
            sellPrice = ShopConfig.GetSellPrice("night_resources", itemName)
        end
    end
    
    -- Update tooltip content
    local titleLabel = tooltipFrame:FindFirstChild("TooltipTitle")
    local descLabel = tooltipFrame:FindFirstChild("TooltipDescription")
    local statsLabel = tooltipFrame:FindFirstChild("TooltipStats")
    
    if titleLabel then
        titleLabel.Text = itemData.displayName
    end
    
    if descLabel then
        descLabel.Text = itemData.description
    end
    
    if statsLabel then
        local statsText = string.format("Quantity: %d", quantity)
        
        if sellPrice > 0 then
            statsText = statsText .. string.format("\n💰 Sell Value: %d coins", sellPrice)
        end
        
        -- Add item type
        if IsSeed(itemName) then
            statsText = statsText .. "\n🌱 Type: Seed"
        elseif IsTool(itemName) then
            statsText = statsText .. "\n🔧 Type: Tool"
        else
            statsText = statsText .. "\n📦 Type: Item"
        end
        
        statsLabel.Text = statsText
    end
    
    -- Position tooltip near slot
    local slotPosition = parentSlot.AbsolutePosition
    local slotSize = parentSlot.AbsoluteSize
    
    -- Calculate position (above the slot)
    local tooltipX = slotPosition.X + slotSize.X / 2
    local tooltipY = slotPosition.Y - 10
    
    tooltipFrame.Position = UDim2.new(0, tooltipX, 0, tooltipY)
    tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
    
    -- Animate in
    tooltipFrame.Visible = true
    tooltipFrame.Size = UDim2.new(0, 0, 0, 0)
    
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(tooltipFrame, tweenInfo, {
        Size = UDim2.new(0, 250, 0, 120)
    }):Play()
end

--[[
    Hide tooltip
]]
function InventoryController.HideTooltip()
    if not tooltipFrame then return end
    
    -- Animate out
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween = TweenService:Create(tooltipFrame, tweenInfo, {
        Size = UDim2.new(0, 0, 0, 0)
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        tooltipFrame.Visible = false
    end)
end

--[[
    Switch inventory tab
    @param tabName (string) - "Seeds" or "Items"
]]
function InventoryController.SwitchTab(tabName)
    if tabName ~= "Seeds" and tabName ~= "Items" then
        warn("⚠️ Invalid tab name:", tabName)
        return
    end
    
    currentTab = tabName
    print("📑 Switched to tab:", currentTab)
    InventoryController.RefreshGrid()
end

--[[
    Update cached inventory data (P1-2: Uses StateManager)
    @param newInventory (table) - New inventory data from server
]]
function InventoryController.UpdateInventory(newInventory)
    if type(newInventory) ~= "table" then
        warn("⚠️ Invalid inventory data received")
        return
    end
    
    cachedInventory = newInventory
    
    -- Count items (dictionary-style table)
    local itemCount = 0
    for _ in pairs(newInventory) do itemCount = itemCount + 1 end
    
    print("💾 Inventory cache updated:", itemCount, "items")
    
    -- Refresh display if inventory is open
    if inventoryUI and inventoryUI.Enabled then
        InventoryController.RefreshGrid()
    end
end

--[[
    Get current cached inventory
    @return table - Current inventory
]]
function InventoryController.GetInventory()
    return cachedInventory
end

--[[
    Add item to cached inventory
    @param itemName (string) - Item to add
    @param quantity (number) - Amount to add (default: 1)
]]
function InventoryController.AddItem(itemName, quantity)
    quantity = quantity or 1
    cachedInventory[itemName] = (cachedInventory[itemName] or 0) + quantity
    
    print(string.format("➕ Added %dx %s to inventory", quantity, itemName))
    
    if inventoryUI and inventoryUI.Enabled then
        InventoryController.RefreshGrid()
    end
end

--[[
    Remove item from cached inventory
    @param itemName (string) - Item to remove
    @param quantity (number) - Amount to remove (default: 1)
    @return boolean - Success status
]]
function InventoryController.RemoveItem(itemName, quantity)
    quantity = quantity or 1
    
    local current = cachedInventory[itemName] or 0
    if current < quantity then
        warn(string.format("⚠️ Not enough %s (have %d, need %d)", itemName, current, quantity))
        return false
    end
    
    cachedInventory[itemName] = current - quantity
    
    if cachedInventory[itemName] <= 0 then
        cachedInventory[itemName] = nil
    end
    
    print(string.format("➖ Removed %dx %s from inventory", quantity, itemName))
    
    if inventoryUI and inventoryUI.Enabled then
        InventoryController.RefreshGrid()
    end
    
    return true
end

--[[
    Initialize inventory controller
    Sets up tab buttons, connections, and StateManager subscription
]]
function InventoryController.Initialize()
    print("========================================")
    print("📦 Initializing InventoryController...")
    print("========================================")
    
    if not inventoryFrame then
        warn("⚠️ InventoryFrame not found - controller in limited mode")
        return
    end
    
    -- P1-2: Subscribe to StateManager changes
    StateManager.subscribe(function(state, oldState, action)
        -- Handle inventory updates
        if action.type == "UPDATE_INVENTORY" or action.type == "APPLY_SNAPSHOT" then
            local newInventory = state.player.inventory or {}
            InventoryController.UpdateInventory(newInventory)
        end
    end)
    
    -- Load initial inventory from StateManager
    cachedInventory = StateManager.getInventory()
    
    -- Setup tab buttons (P2-5: Debounced)
    local tabContainer = inventoryFrame:FindFirstChild("TabContainer")
    if tabContainer then
        local seedsTab = tabContainer:FindFirstChild("SeedsTab")
        local itemsTab = tabContainer:FindFirstChild("ItemsTab")
        
        local debouncedSwitchTab = Debounce.create(function(tabName)
            InventoryController.SwitchTab(tabName)
        end, Constants.ANIMATION.FAST_TWEEN_DURATION)
        
        if seedsTab then
            seedsTab.MouseButton1Click:Connect(function()
                debouncedSwitchTab("Seeds")
            end)
        end
        
        if itemsTab then
            itemsTab.MouseButton1Click:Connect(function()
                debouncedSwitchTab("Items")
            end)
        end
    end
    
    -- Setup close button (P2-5: Debounced)
    local headerBar = inventoryFrame:FindFirstChild("HeaderBar")
    if headerBar then
        local closeButton = headerBar:FindFirstChild("CloseButton")
        if closeButton then
            local debouncedClose = Debounce.create(function()
                local UIController = require(script.Parent.UIController)
                UIController.ToggleInventory()
            end, Constants.ANIMATION.FAST_TWEEN_DURATION)
            
            closeButton.MouseButton1Click:Connect(debouncedClose)
        end
    end
    
    -- Initial grid refresh
    InventoryController.RefreshGrid()
    
    -- Count items
    local itemCount = 0
    for _ in pairs(cachedInventory) do itemCount = itemCount + 1 end
    
    print("✅ Tab buttons configured")
    print("✅ Close button configured")
    print("✅ StateManager subscription active")
    print(string.format("📊 Cached items: %d", itemCount))
    print("========================================")
    print("✨ InventoryController ready!")
    print("========================================")
end

-- Auto-initialize
if inventoryFrame then
    InventoryController.Initialize()
end

return InventoryController
