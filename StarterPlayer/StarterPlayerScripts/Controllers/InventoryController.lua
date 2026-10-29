--[[
    InventoryController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/

    PURPOSE (feature 005, US3 - redesigned Backpack):
    - Card grid cloned from the static InventoryUI.ItemGrid.CardTemplate (never built in code)
    - Five category tabs: All / Seeds / Tools / Crops / Spirits (Spirits = placeholder)
    - Detail panel for the selected card with one context action by category:
        Equip (Seeds/Tools) -> HotbarController.EquipByItemName (existing EquipTool path)
        Go to sell (Crops)  -> teleport to the stall + open the Sell window
        View journal (Spirits) -> disabled placeholder this stage
    - Favourite toggle for sellable crops via the existing ToggleFavourite RemoteFunction
    - Every clone is painted through ThemeController (R9) so the grid follows day/night

    DEPENDENCIES:
    - InventoryUI ScreenGui (static GUI, see Tools/StaticGui/builders/CreateInventoryUI.luau)
    - PlantData / ShopConfig modules (ReplicatedStorage)
    - StateManager (inventory), ThemeController, HotbarController, WindowManager
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

-- Static GUI (P2-3) is cloned into PlayerGui when the character first spawns,
-- which can take longer than any fixed timeout on a slow join: wait for it.
local inventoryUI = playerGui:WaitForChild("InventoryUI")
local inventoryFrame, itemGrid, tooltipFrame, cardTemplate, detailPanel, spiritsEmpty

if inventoryUI then
    inventoryFrame = inventoryUI:WaitForChild("InventoryFrame", 5)
    if inventoryFrame then
        itemGrid = inventoryFrame:WaitForChild("ItemGrid", 5)
        detailPanel = inventoryFrame:FindFirstChild("DetailPanel")
        spiritsEmpty = inventoryFrame:FindFirstChild("SpiritsEmptyState")
        cardTemplate = itemGrid and itemGrid:FindFirstChild("CardTemplate")
        -- TooltipFrame sits directly under InventoryUI (sibling of InventoryFrame)
        tooltipFrame = inventoryUI:FindFirstChild("TooltipFrame") or inventoryFrame:FindFirstChild("TooltipFrame")
    end
end

-- Load configurations
local PlantData = ReplicatedStorage:FindFirstChild("PlantData") and require(ReplicatedStorage.PlantData)
local ShopConfig = ReplicatedStorage:FindFirstChild("ShopConfig") and require(ReplicatedStorage.ShopConfig)
local ItemEmoji = require(ReplicatedStorage:WaitForChild("ItemEmoji")) -- feature 005: emoji icon fallback

-- Optional collaborators (lazy + pcall so load order / a missing module is safe)
local function getThemeController()
    local m = script.Parent:FindFirstChild("ThemeController")
    if not m then return nil end
    local ok, tc = pcall(require, m)
    return ok and tc or nil
end

local function getHotbarController()
    local m = script.Parent:FindFirstChild("HotbarController")
    if not m then return nil end
    local ok, hc = pcall(require, m)
    return ok and hc or nil
end

local function notify(text, kind)
    local m = script.Parent:FindFirstChild("UIController")
    if not m then return end
    local ok, UIController = pcall(require, m)
    if ok and UIController and UIController.ShowNotification then
        UIController.ShowNotification(text, kind or "info", 2)
    end
end

-- Paint a single instance or subtree with the active palette (R9).
local function paint(inst)
    local tc = getThemeController()
    if tc then
        tc.Paint(inst) -- walks the subtree including inst itself
    end
end

-- State
local TAB_NAMES = { "All", "Seeds", "Tools", "Crops", "Spirits" }
local currentTab = "All"
local cachedInventory = {} -- P1-2: synced from StateManager
local selectedItem = nil -- itemName of the selected card
local favourites = {} -- [itemId] = true (server-owned set; mirrored from GetPlayerData/ToggleFavourite)

-- Item categories
local SEED_KEYWORDS = {"seed", "carrot", "tomato", "wheat", "pumpkin", "moonflower", "starberry"}
local TOOL_KEYWORDS = {"watering_can", "lantern", "net", "scarecrow"}

local function matchesAny(itemName, keywords)
    local lowerName = itemName:lower()
    for _, keyword in ipairs(keywords) do
        if lowerName:find(keyword) then
            return true
        end
    end
    return false
end

--[[ Grown crops: id ends in "_crop" or is a sellable crop in ShopConfig.sell
     (only crops are sellable - ShopConfig.CanSell). Checked BEFORE seeds because
     crop ids contain plant names that are also seed keywords (e.g. carrot_crop). ]]
local function IsCrop(itemName)
    if itemName:sub(-5) == "_crop" then return true end
    return ShopConfig ~= nil and ShopConfig.CanSell ~= nil and ShopConfig.CanSell(itemName) == true
end

local function IsSeed(itemName)
    if IsCrop(itemName) then return false end
    return itemName:sub(-5) == "_seed" or matchesAny(itemName, SEED_KEYWORDS)
end

local function IsTool(itemName)
    if IsCrop(itemName) or itemName:sub(-5) == "_seed" then return false end
    return matchesAny(itemName, TOOL_KEYWORDS)
end

--[[ Category of an item: "Seeds" | "Tools" | "Crops" | "Items" (other consumables,
     shown only under All). Spirits have no items yet (FR-017). ]]
local function CategoryOf(itemName)
    if IsCrop(itemName) then return "Crops" end
    if IsSeed(itemName) then return "Seeds" end
    if IsTool(itemName) then return "Tools" end
    return "Items"
end

local function RarityOf(itemName)
    local tier = ShopConfig and ShopConfig.GetRarity and ShopConfig.GetRarity(itemName) or "Common"
    if tier ~= "Common" and tier ~= "Uncommon" and tier ~= "Rare" and tier ~= "Epic" and tier ~= "Legendary" then
        tier = "Common"
    end
    return tier
end

--[[
    Get item display data (name, icon, description)
    @param itemName (string) - Internal item name
    @return table with displayName, icon, description, sellValue
]]
local function GetItemDisplayData(itemName)
    -- Try to get from PlantData first
    if PlantData then
        local plantId = itemName:gsub("_seed", ""):gsub("_crop", "")
        local plantInfo = PlantData[plantId]

        if plantInfo then
            local iconId = plantInfo.icon
            if itemName:sub(-5) == "_seed" then
                iconId = plantInfo.seedIcon or iconId
            elseif itemName:sub(-5) == "_crop" then
                iconId = plantInfo.cropIcon or iconId
            end
            local suffix = itemName:sub(-5) == "_seed" and " Seed" or ""
            return {
                displayName = (plantInfo.displayName or itemName) .. suffix,
                icon = iconId or "",
                description = plantInfo.description or "No description available",
                sellValue = plantInfo.sellValue or 0
            }
        end
    end

    -- Tools / items defined in ShopConfig.buy
    if ShopConfig and ShopConfig.buy then
        for _, category in ipairs({ "tools", "items" }) do
            local row = ShopConfig.buy[category] and ShopConfig.buy[category][itemName]
            if row then
                return {
                    displayName = row.displayName or itemName,
                    icon = row.icon or "",
                    description = "A useful item for your garden",
                    sellValue = 0
                }
            end
        end
    end

    -- Fallback: Generate from item name
    local displayName = itemName:gsub("_", " ")
    displayName = displayName:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)

    return {
        displayName = displayName,
        icon = "",
        description = "A useful item for your garden",
        sellValue = 0
    }
end

local function hasIcon(iconId)
    return type(iconId) == "string" and iconId ~= "" and iconId ~= "rbxassetid://0" and iconId ~= "rbxassetid://placeholder"
end

-- Fill an ImageLabel + its FallbackLetter child from an icon id / display name.
local function applyIcon(iconLabel, iconId, displayName, itemId)
    if not iconLabel then return end
    local fallback = iconLabel:FindFirstChild("FallbackLetter")
    if hasIcon(iconId) then
        iconLabel.Image = iconId
        if fallback then fallback.Visible = false end
    else
        iconLabel.Image = ""
        if fallback then
            -- Feature 005 (US4 interim): item emoji when there is no image icon,
            -- else the first letter of the name.
            local emoji = itemId and ItemEmoji.get(itemId) or ""
            fallback.Text = (emoji ~= "" and emoji) or displayName:sub(1, 1):upper()
            fallback.Visible = true
        end
    end
end

--[[ Selection ring: tag the card stroke with the Accent/Outline token and repaint
     it so it stays theme-driven. ]]
local function setCardSelected(card, selected)
    local stroke = card:FindFirstChildOfClass("UIStroke")
    if not stroke then return end
    stroke:SetAttribute("Theme_Color", selected and "Accent" or "Outline")
    local tc = getThemeController()
    if tc then tc.PaintInstant(stroke) end
end

-- Show/hide the favourite star on crop cards.
local function updateFavouriteMark(card, itemName)
    local mark = card:FindFirstChild("FavouriteMark")
    if mark then
        mark.Visible = favourites[itemName] == true
    end
end

--[[
    Update an existing card in place (P1-4: incremental)
    @param card (Frame) - clone of CardTemplate
]]
local function UpdateCard(card, itemName, quantity)
    local itemData = GetItemDisplayData(itemName)
    local nameLabel = card:FindFirstChild("NameLabel")
    if nameLabel then nameLabel.Text = itemData.displayName end
    local qtyLabel = card:FindFirstChild("QtyLabel")
    if qtyLabel then
        qtyLabel.Text = "x" .. quantity
        qtyLabel.Visible = quantity > 1
    end
    updateFavouriteMark(card, itemName)
end

local RefreshDetail -- forward declaration

local function SelectItem(itemName)
    selectedItem = itemName
    if itemGrid then
        for _, child in ipairs(itemGrid:GetChildren()) do
            local name = child:GetAttribute("ItemName")
            if name then
                setCardSelected(child, name == itemName)
            end
        end
    end
    RefreshDetail()
end

--[[
    Create one card by cloning the static CardTemplate (never built in code).
    @return Frame
]]
function InventoryController.CreateCard(itemName, quantity)
    local itemData = GetItemDisplayData(itemName)
    local card = cardTemplate:Clone()
    card.Name = "Card_" .. itemName -- GridLayout sorts by Name
    card.Visible = true
    card:SetAttribute("ItemName", itemName)
    card.Parent = itemGrid

    applyIcon(card:FindFirstChild("Icon"), itemData.icon, itemData.displayName, itemName)

    -- Rarity badge: tier colour via the Theme_ token (repaints on day/night) + tier text
    -- so rarity is never colour-only (FR-025).
    local tier = RarityOf(itemName)
    local badge = card:FindFirstChild("RarityBadge", true)
    if badge then
        badge:SetAttribute("Theme_BackgroundColor3", "Rarity" .. tier)
        local badgeText = badge:FindFirstChild("BadgeText")
        if badgeText then badgeText.Text = string.upper(tier) end
    end

    UpdateCard(card, itemName, quantity)

    -- Paint the whole clone with the active palette (R9); then the selection state.
    paint(card)
    setCardSelected(card, itemName == selectedItem)

    local button = card:FindFirstChild("SlotButton")
    if button then
        button.MouseEnter:Connect(function()
            InventoryController.ShowTooltip(itemName, card)
        end)
        button.MouseLeave:Connect(function()
            InventoryController.HideTooltip()
        end)
        button.Activated:Connect(function()
            SelectItem(itemName)
        end)
    end

    return card
end

--[[
    Refresh inventory grid based on current tab
    P1-4: incremental create/update/destroy keyed on the ItemName attribute
]]
function InventoryController.RefreshGrid()
    if not itemGrid or not cardTemplate then
        warn("⚠️ ItemGrid / CardTemplate not found in InventoryUI")
        return
    end

    local isSpirits = currentTab == "Spirits"
    if spiritsEmpty then spiritsEmpty.Visible = isSpirits end
    itemGrid.Visible = not isSpirits

    -- Filter items by current tab (Spirits shows no items this stage)
    local displayItems = {}
    if not isSpirits then
        for itemName, quantity in pairs(cachedInventory) do
            if quantity > 0 and (currentTab == "All" or CategoryOf(itemName) == currentTab) then
                table.insert(displayItems, {name = itemName, qty = quantity})
            end
        end
    end

    table.sort(displayItems, function(a, b)
        return a.name < b.name
    end)

    -- Existing cards keyed on the stored item name
    local existing = {}
    for _, child in ipairs(itemGrid:GetChildren()) do
        local itemNameAttr = child:GetAttribute("ItemName")
        if itemNameAttr then
            existing[itemNameAttr] = child
        end
    end

    local used = {}
    for _, item in ipairs(displayItems) do
        local card = existing[item.name]
        if card then
            UpdateCard(card, item.name, item.qty)
        else
            InventoryController.CreateCard(item.name, item.qty)
        end
        used[item.name] = true
    end

    for itemName, card in pairs(existing) do
        if not used[itemName] then
            card:Destroy()
        end
    end

    -- Drop the selection when its card is no longer in the current view
    if selectedItem and not used[selectedItem] then
        selectedItem = nil
    end
    RefreshDetail()
end

-- Back-compat name for the previous code-built slot API.
InventoryController.CreateSlot = InventoryController.CreateCard

--[[ Detail panel ]]

local function setActionButton(button, text, enabled)
    button.Text = text
    button.Active = enabled
    button.AutoButtonColor = false
    button:SetAttribute("Theme_BackgroundColor3", enabled and "Positive" or "Control")
    button:SetAttribute("Theme_TextColor3", enabled and "TextOnAccent" or "TextMuted")
    local tc = getThemeController()
    if tc then tc.PaintInstant(button) end
end

function RefreshDetail()
    if not detailPanel then return end
    local selIcon = detailPanel:FindFirstChild("SelectedIcon")
    local selName = detailPanel:FindFirstChild("SelectedName")
    local selDesc = detailPanel:FindFirstChild("SelectedDescription")
    local favToggle = detailPanel:FindFirstChild("FavouriteToggle")
    local actionButton = detailPanel:FindFirstChild("ActionButton")

    local qty = selectedItem and cachedInventory[selectedItem] or 0
    if not selectedItem or qty <= 0 then
        selectedItem = nil
        if selIcon then applyIcon(selIcon, "", "?") end
        if selName then selName.Text = (currentTab == "Spirits") and "Spirits" or "Select an item" end
        if selDesc then
            selDesc.Text = (currentTab == "Spirits") and "The spirit journal is coming soon." or "Tap an item to see details."
        end
        if favToggle then favToggle.Visible = false end
        if actionButton then
            if currentTab == "Spirits" then
                actionButton.Visible = true
                setActionButton(actionButton, "View journal", false) -- placeholder (FR-018)
            else
                actionButton.Visible = false
            end
        end
        return
    end

    local itemData = GetItemDisplayData(selectedItem)
    local category = CategoryOf(selectedItem)
    if selIcon then applyIcon(selIcon, itemData.icon, itemData.displayName, selectedItem) end
    if selName then selName.Text = string.format("%s  x%d", itemData.displayName, qty) end
    if selDesc then selDesc.Text = string.upper(RarityOf(selectedItem)) .. " - " .. itemData.description end

    -- Favourites only exist for sellable crops (the server rejects anything else).
    if favToggle then
        favToggle.Visible = category == "Crops"
        favToggle.Text = favourites[selectedItem] and "★" or "☆"
    end

    if actionButton then
        if category == "Seeds" or category == "Tools" then
            actionButton.Visible = true
            setActionButton(actionButton, "Equip", true)
        elseif category == "Crops" then
            actionButton.Visible = true
            setActionButton(actionButton, "Go to sell", true)
        else
            actionButton.Visible = false -- other consumables have no action yet
        end
    end
end

-- Mirror the server-owned favourites set (read-only fetch through GetPlayerData).
function InventoryController.LoadFavourites()
    task.spawn(function()
        local fn = ReplicatedStorage:FindFirstChild("GetPlayerData")
        if not fn then return end
        local ok, result = pcall(function() return fn:InvokeServer() end)
        if ok and type(result) == "table" and result.Success then
            favourites = result.Favourites or {}
            if itemGrid then
                for _, child in ipairs(itemGrid:GetChildren()) do
                    local name = child:GetAttribute("ItemName")
                    if name then updateFavouriteMark(child, name) end
                end
            end
            RefreshDetail()
        end
    end)
end

local actionBusy = false
local function onActionClicked()
    if not selectedItem or actionBusy then return end
    local itemName = selectedItem
    local category = CategoryOf(itemName)

    if category == "Seeds" or category == "Tools" then
        -- Equip through the hotbar so the HUD strip shows it selected (EquipTool path).
        local hotbar = getHotbarController()
        local equipped = hotbar and hotbar.EquipByItemName and hotbar.EquipByItemName(itemName)
        if not equipped then
            notify("That item isn't on your hotbar", "info")
        end
    elseif category == "Crops" then
        -- Same flow as the SELL nav button: go to the stall, then open the Sell window.
        actionBusy = true
        task.spawn(function()
            local RequestTeleport = ReplicatedStorage:FindFirstChild("RequestTeleport")
            local ok = RequestTeleport ~= nil and pcall(function() RequestTeleport:InvokeServer("stall") end)
            if ok then
                local wm = script.Parent.Parent.Utils:FindFirstChild("WindowManager")
                if wm then require(wm).Open("Sell") end
            end
            actionBusy = false
        end)
    end
end

local function onFavouriteClicked()
    if not selectedItem or CategoryOf(selectedItem) ~= "Crops" then return end
    local itemName = selectedItem
    task.spawn(function()
        local fn = ReplicatedStorage:FindFirstChild("ToggleFavourite")
        if not fn then return end
        local ok, result = pcall(function() return fn:InvokeServer(itemName) end)
        if ok and type(result) == "table" and result.Success then
            favourites = result.Favourites or favourites
            favourites[itemName] = result.IsFavourite or nil
            if itemGrid then
                for _, child in ipairs(itemGrid:GetChildren()) do
                    local name = child:GetAttribute("ItemName")
                    if name then updateFavouriteMark(child, name) end
                end
            end
            RefreshDetail()
        end
    end)
end

--[[
    Show tooltip for an item
    @param itemName (string) - Name of the item
    @param parentSlot (Frame) - The card frame to position tooltip near
]]
function InventoryController.ShowTooltip(itemName, parentSlot)
    if not tooltipFrame then
        return
    end

    local itemData = GetItemDisplayData(itemName)
    local quantity = cachedInventory[itemName] or 0

    -- Get sell price
    local sellPrice = 0
    if ShopConfig then
        sellPrice = ShopConfig.GetSellPrice("crops", itemName)
        if sellPrice == 0 then
            sellPrice = ShopConfig.GetSellPrice("items", itemName)
        end
        if sellPrice == 0 then
            sellPrice = ShopConfig.GetSellPrice("night_resources", itemName)
        end
    end

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

        local category = CategoryOf(itemName)
        if category == "Seeds" then
            statsText = statsText .. "\n🌱 Type: Seed"
        elseif category == "Tools" then
            statsText = statsText .. "\n🔧 Type: Tool"
        elseif category == "Crops" then
            statsText = statsText .. "\n🥕 Type: Crop"
        else
            statsText = statsText .. "\n📦 Type: Item"
        end

        statsLabel.Text = statsText
    end

    -- Position tooltip above the card
    local slotPosition = parentSlot.AbsolutePosition
    local slotSize = parentSlot.AbsoluteSize

    local tooltipX = slotPosition.X + slotSize.X / 2
    local tooltipY = slotPosition.Y - 10

    tooltipFrame.Position = UDim2.new(0, tooltipX, 0, tooltipY)
    tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)

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

    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween = TweenService:Create(tooltipFrame, tweenInfo, {
        Size = UDim2.new(0, 0, 0, 0)
    })
    tween:Play()

    tween.Completed:Connect(function()
        tooltipFrame.Visible = false
    end)
end

-- Highlight the active tab with theme tokens (retints on day/night, FR-022).
local function paintTabs(activeTab)
    local tabContainer = inventoryFrame and inventoryFrame:FindFirstChild("TabContainer")
    if not tabContainer then return end
    local tc = getThemeController()
    for _, name in ipairs(TAB_NAMES) do
        local tab = tabContainer:FindFirstChild(name .. "Tab")
        if tab then
            local active = name == activeTab
            tab:SetAttribute("Theme_BackgroundColor3", active and "Accent" or "Control")
            tab:SetAttribute("Theme_TextColor3", active and "TextOnAccent" or "TextPrimary")
            if tc then tc.PaintInstant(tab) end
        end
    end
end

--[[
    Switch inventory tab
    @param tabName (string) - "All" | "Seeds" | "Tools" | "Crops" | "Spirits"
]]
function InventoryController.SwitchTab(tabName)
    if not table.find(TAB_NAMES, tabName) then
        warn("⚠️ Invalid tab name:", tabName)
        return
    end

    currentTab = tabName
    paintTabs(currentTab)
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
    print("📦 Initializing InventoryController...")

    if not inventoryFrame then
        warn("⚠️ InventoryFrame not found - controller in limited mode")
        return
    end

    -- P1-2: Subscribe to StateManager changes
    StateManager.subscribe(function(state, oldState, action)
        if action.type == "UPDATE_INVENTORY" or action.type == "APPLY_SNAPSHOT" then
            local newInventory = state.player.inventory or {}
            InventoryController.UpdateInventory(newInventory)
        end
    end)

    -- Load initial inventory from StateManager
    cachedInventory = StateManager.getInventory()

    -- Tab buttons (P2-5: Debounced)
    local tabContainer = inventoryFrame:FindFirstChild("TabContainer")
    if tabContainer then
        local debouncedSwitchTab = Debounce.create(function(tabName)
            InventoryController.SwitchTab(tabName)
        end, Constants.ANIMATION.FAST_TWEEN_DURATION)

        for _, name in ipairs(TAB_NAMES) do
            local tab = tabContainer:FindFirstChild(name .. "Tab")
            if tab then
                tab.Activated:Connect(function()
                    debouncedSwitchTab(name)
                end)
            end
        end
    end

    -- Detail panel buttons
    if detailPanel then
        local actionButton = detailPanel:FindFirstChild("ActionButton")
        if actionButton then
            actionButton.Activated:Connect(onActionClicked)
        end
        local favToggle = detailPanel:FindFirstChild("FavouriteToggle")
        if favToggle then
            favToggle.Activated:Connect(onFavouriteClicked)
        end
    end

    -- Close button (P2-5: Debounced)
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

    paintTabs(currentTab)
    InventoryController.LoadFavourites()
    InventoryController.RefreshGrid()

    print("✨ InventoryController ready!")
end

-- Auto-initialize
if inventoryFrame then
    InventoryController.Initialize()
end

return InventoryController
