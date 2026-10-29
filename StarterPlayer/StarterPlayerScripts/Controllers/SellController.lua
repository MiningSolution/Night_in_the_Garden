--[[
    SellController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers (ModuleScript)
    Feature 002, User Story 1.

    Drives the SellUI (built by Tools/StaticGui/builders/CreateSellUI.luau):
      - opens when the player triggers the seller stall's ProximityPrompt
        (on-screen button on touch/gamepad, E on PC — the prompt provides these)
      - lists the player's sellable crops (server decides what is sellable),
        each with its sell value and a favourite (star) toggle
      - shows the running "Sell all" total (non-favourite crops)
      - SellOne -> SellItem (favourite crops require a confirm tap first, FR-004)
      - Sell all -> SellAll (server skips favourites)
      - closes if the player walks out of the stall's range

    Server is authoritative: this controller sends requests and renders the
    results; it never computes coins (constitution I).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Utils = script.Parent.Parent:WaitForChild("Utils")
local Controllers = script.Parent
local WindowManager = require(Utils:WaitForChild("WindowManager"))
local UIController = require(Controllers:WaitForChild("UIController"))
local InventoryController = require(Controllers:WaitForChild("InventoryController"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("UITheme"))

local SellItemFn = ReplicatedStorage:WaitForChild("SellItem")
local SellAllFn = ReplicatedStorage:WaitForChild("SellAll")
local ToggleFavouriteFn = ReplicatedStorage:WaitForChild("ToggleFavourite")
local GetPlayerDataFn = ReplicatedStorage:WaitForChild("GetPlayerData")

local SellController = {}

local RARITY_TOKEN = {
    Common = Theme.RarityCommon,
    Uncommon = Theme.RarityUncommon,
    Rare = Theme.RarityRare,
    Epic = Theme.RarityEpic,
    Legendary = Theme.RarityLegendary,
}

local STALL_RANGE = 14 -- studs; matches the ProximityPrompt's MaxActivationDistance + buffer

-- UI references (resolved in Init)
local SellUI, SellFrame, ItemsScroll, RowTemplate, TotalLabel, EmptyState, SellAllButton, CloseButton, Backdrop
local stallPart = nil
local rangeConn = nil

-- client-side mirror of the server's state, refreshed on open and after each action
local inventory = {}
local favourites = {}
local pendingConfirm = {} -- [itemId] = true when a favourite's Sell needs a 2nd tap

local function fetchData()
    local ok, result = pcall(function()
        return GetPlayerDataFn:InvokeServer()
    end)
    if ok and type(result) == "table" and result.Success then
        inventory = result.Inventory or {}
        favourites = result.Favourites or {}
        return true
    end
    return false
end

-- Remove previously cloned rows (everything except the hidden template).
local function clearRows()
    for _, child in ipairs(ItemsScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "SellRowTemplate" then
            child:Destroy()
        end
    end
end

local function applyIcon(row, iconId, displayName)
    local icon = row:FindFirstChild("Icon")
    local fallback = icon and icon:FindFirstChild("FallbackLetter")
    if not icon or not fallback then return end
    if iconId and iconId ~= "" then
        icon.Image = iconId
        fallback.Visible = false
    else
        icon.Image = ""
        fallback.Visible = true
        fallback.Text = (displayName or "?"):sub(1, 1):upper()
    end
end

local function makeRow(itemId, count)
    local sellRow = ShopConfig.sell[itemId]
    local value = ShopConfig.GetSellPrice(nil, itemId)
    local displayName = (sellRow and sellRow.displayName) or itemId
    local rarity = ShopConfig.GetRarity(itemId)

    local row = RowTemplate:Clone()
    row.Name = "Row_" .. itemId
    row.Visible = true
    row:FindFirstChild("RarityStrip").BackgroundColor3 = RARITY_TOKEN[rarity] or Theme.RarityCommon
    row:FindFirstChild("NameLabel").Text = displayName
    row:FindFirstChild("CountLabel").Text = "x" .. tostring(count)
    row:FindFirstChild("ValueLabel").Text = tostring(value) .. " ea"
    applyIcon(row, sellRow and sellRow.icon, displayName)

    local star = row:FindFirstChild("StarToggle")
    local sellBtn = row:FindFirstChild("SellOneButton")

    local function refreshStar()
        if favourites[itemId] then
            star.Text = "★"
            star.BackgroundColor3 = Theme.RarityLegendary
        else
            star.Text = "☆"
            star.BackgroundColor3 = Theme.Control
        end
    end
    refreshStar()

    star.Activated:Connect(function()
        local ok, result = pcall(function()
            return ToggleFavouriteFn:InvokeServer(itemId)
        end)
        if ok and type(result) == "table" and result.Success then
            favourites[itemId] = result.IsFavourite or nil
            pendingConfirm[itemId] = nil
            SellController.Render()
        end
    end)

    sellBtn.Activated:Connect(function()
        -- A favourited crop can still be sold individually, but only after a
        -- confirmation tap (FR-004).
        if favourites[itemId] and not pendingConfirm[itemId] then
            pendingConfirm[itemId] = true
            sellBtn.Text = "Confirm?"
            sellBtn.BackgroundColor3 = Theme.Danger
            return
        end
        pendingConfirm[itemId] = nil
        local ok, result = pcall(function()
            return SellItemFn:InvokeServer(itemId, 1)
        end)
        if ok and type(result) == "table" and result.Success then
            UIController.UpdateCurrency(result.NewBalance or 0, 0)
            UIController.ShowNotification(string.format("Sold 1 %s for %d coins", displayName, result.TotalEarned or 0), "success")
            if result.NewInventory then
                InventoryController.UpdateInventory(result.NewInventory)
                inventory = result.NewInventory
            end
            SellController.Render()
        elseif ok and type(result) == "table" then
            UIController.ShowNotification(result.Error or "Could not sell", "error")
        end
    end)

    row.Parent = ItemsScroll
    return value
end

-- Rebuild the rows from the current inventory + favourites, and update the total.
function SellController.Render()
    if not SellUI then return end
    clearRows()
    local total = 0
    local anySellable = false
    for itemId, count in pairs(inventory) do
        count = tonumber(count) or 0
        if count > 0 and ShopConfig.CanSell(itemId) then
            anySellable = true
            local value = makeRow(itemId, count)
            if not favourites[itemId] then
                total = total + value * count
            end
        end
    end
    EmptyState.Visible = not anySellable
    ItemsScroll.Visible = anySellable
    TotalLabel.Text = string.format("Sell all total: %d coins", total)
    SellAllButton.AutoButtonColor = anySellable
end

local function stopRangeWatch()
    if rangeConn then
        rangeConn:Disconnect()
        rangeConn = nil
    end
end

-- Close the window if the player leaves the stall's range (edge case).
local function startRangeWatch()
    stopRangeWatch()
    if not stallPart then return end
    rangeConn = RunService.Heartbeat:Connect(function()
        if WindowManager.GetOpen() ~= "Sell" then
            stopRangeWatch()
            return
        end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - stallPart.Position).Magnitude > STALL_RANGE then
            WindowManager.Close()
        end
    end)
end

local function onOpen()
    pendingConfirm = {}
    fetchData()
    SellController.Render()
    startRangeWatch()
end

-- Find the stall's ProximityPrompt (spawned by StallService) and open on trigger.
local function bindStall()
    task.spawn(function()
        local Workspace = game:GetService("Workspace")
        local stall = Workspace:WaitForChild("SellStall", 30)
        if not stall then
            warn("[SellController] SellStall not found in Workspace")
            return
        end
        stallPart = stall:IsA("Model") and (stall.PrimaryPart or stall:FindFirstChildWhichIsA("BasePart")) or stall
        local prompt = stall:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt then
            warn("[SellController] SellStall has no ProximityPrompt")
            return
        end
        prompt.Triggered:Connect(function(triggeringPlayer)
            if triggeringPlayer == player then
                WindowManager.Open("Sell")
            end
        end)
    end)
end

function SellController.Init()
    SellUI = playerGui:WaitForChild("SellUI")
    SellFrame = SellUI:WaitForChild("SellFrame")
    ItemsScroll = SellFrame:WaitForChild("ItemsScroll")
    RowTemplate = ItemsScroll:WaitForChild("SellRowTemplate")
    TotalLabel = SellFrame:WaitForChild("TotalLabel")
    EmptyState = SellFrame:WaitForChild("EmptyState")
    SellAllButton = SellFrame:WaitForChild("SellAllButton")
    CloseButton = SellFrame:WaitForChild("HeaderBar"):WaitForChild("CloseButton")
    Backdrop = SellUI:WaitForChild("Backdrop")

    -- single-window registration (one window open at a time, FR-003)
    WindowManager.Register("Sell", {
        gui = SellUI,
        frame = SellFrame,
        backdrop = Backdrop,
        closeButton = CloseButton,
        onOpen = onOpen,
        defaultSelection = function()
            return SellAllButton
        end,
    })

    CloseButton.Activated:Connect(function()
        WindowManager.Close()
    end)

    SellAllButton.Activated:Connect(function()
        local ok, result = pcall(function()
            return SellAllFn:InvokeServer()
        end)
        if ok and type(result) == "table" and result.Success then
            if (result.SoldCount or 0) > 0 then
                UIController.UpdateCurrency(result.NewBalance or 0, 0)
                UIController.ShowNotification(string.format("Sold %d crops for %d coins", result.SoldCount, result.TotalEarned or 0), "success")
                if result.NewInventory then
                    InventoryController.UpdateInventory(result.NewInventory)
                    inventory = result.NewInventory
                end
            elseif (result.SkippedFavourites or 0) > 0 then
                UIController.ShowNotification("All sellable crops are favourited (protected)", "info")
            else
                UIController.ShowNotification("Nothing to sell", "info")
            end
            SellController.Render()
        elseif ok and type(result) == "table" then
            UIController.ShowNotification(result.Error or "Could not sell", "error")
        end
    end)

    bindStall()
    print("✅ SellController initialized")
end

SellController.Init()

return SellController
