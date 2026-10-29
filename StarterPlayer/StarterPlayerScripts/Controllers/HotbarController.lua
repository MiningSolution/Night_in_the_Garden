--[[
    HotbarController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/

    PURPOSE (feature 002, US5):
    The hotbar is built from the player's INVENTORY, not a fixed list. It holds the
    things a player uses on a plot — owned watering cans, the Harvest action, and
    every owned seed — in a stable order. Three slots are visible at once; L1/R1
    (PreviousSlot/NextSlot, bound by InputActions) cycle the equipped item through
    the whole list and shift the visible window so the equipped item stays in view.
    A newly bought seed appears in the first free slot (FR-012); if the list is
    longer than the window it is still reachable by cycling. When nothing changes
    the hotbar is not rebuilt (incremental).

    Server stays authoritative: equipping only sends EquipTool; the server validates
    ownership and decides outcomes (constitution I).

    DEPENDENCIES:
    - HUDControls.Hotbar (Slot1..Slot3 with SlotButton / ItemIcon / SelectionBorder)
    - InteractWithPlot, EquipTool RemoteEvents
    - StateManager (inventory source)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Utils = script.Parent.Parent.Utils
local WindowManager = require(Utils:WaitForChild("WindowManager"))
local StateManager = require(Utils:WaitForChild("StateManager"))

local HotbarController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDControls = playerGui:WaitForChild("HUDControls")
local hotbar
if HUDControls then
    hotbar = HUDControls:WaitForChild("Hotbar", 5)
end

local InteractWithPlot
local EquipTool
task.spawn(function()
    InteractWithPlot = ReplicatedStorage:WaitForChild("InteractWithPlot", 30)
    EquipTool = ReplicatedStorage:WaitForChild("EquipTool", 30)
    if InteractWithPlot then print("✅ InteractWithPlot RemoteEvent connected") end
    if EquipTool then print("✅ EquipTool RemoteEvent connected") end
end)

local ShopConfig = ReplicatedStorage:FindFirstChild("ShopConfig") and require(ReplicatedStorage.ShopConfig)
local Theme = require(ReplicatedStorage:WaitForChild("UITheme"))
local ItemEmoji = require(ReplicatedStorage:WaitForChild("ItemEmoji")) -- feature 005: single source of item emoji

-- State
local VISIBLE_SLOTS = 5 -- feature 005: five visible slots; trailing empties show a locked placeholder
local items = {}        -- ordered list of { serverTool, displayName, emoji }
local equippedIndex = 1 -- 1-based index into `items`
local pageStart = 1     -- index of the item shown in Slot1

-- Display helpers: item emoji comes from the shared ItemEmoji source (feature 005).
-- Stable seed order for the hotbar list.
local SEED_ORDER = {
    "carrot_seed", "wheat_seed", "tomato_seed", "pumpkin_seed",
    "moonflower_seed", "starberry_seed", "dreamroot_seed",
}

local function seedDisplayName(seedId)
    if ShopConfig and ShopConfig.buy.seeds[seedId] then
        return ShopConfig.buy.seeds[seedId].displayName
    end
    local base = seedId:gsub("_seed$", "")
    return base:sub(1, 1):upper() .. base:sub(2) .. " Seed"
end

-- US8: real icon from config if one is set, else "" (renderSlot falls back to emoji).
local function iconFor(serverTool)
    if not ShopConfig then return "" end
    local row = ShopConfig.buy.seeds[serverTool] or ShopConfig.buy.tools[serverTool] or ShopConfig.buy.items[serverTool]
    return (row and row.icon) or ""
end

-- Build the ordered hotbar list from an inventory dictionary.
local function buildItems(inv)
    inv = inv or {}
    local list = {}
    if (inv.basic_watering_can or 0) > 0 then
        list[#list + 1] = { serverTool = "basic_watering_can", displayName = "Watering Can", emoji = ItemEmoji.get("basic_watering_can"), icon = iconFor("basic_watering_can") }
    end
    if (inv.improved_watering_can or 0) > 0 then
        list[#list + 1] = { serverTool = "improved_watering_can", displayName = "Improved Watering Can", emoji = ItemEmoji.get("improved_watering_can"), icon = iconFor("improved_watering_can") }
    end
    -- Harvest is always available (needs no item).
    list[#list + 1] = { serverTool = "Harvest", displayName = "Harvest", emoji = ItemEmoji.get("Harvest"), icon = "" }
    for _, seedId in ipairs(SEED_ORDER) do
        if (inv[seedId] or 0) > 0 then
            local seedEmoji = ItemEmoji.get(seedId)
            list[#list + 1] = { serverTool = seedId, displayName = seedDisplayName(seedId), emoji = (seedEmoji ~= "" and seedEmoji) or "🌱", icon = iconFor(seedId) }
        end
    end
    return list
end

-- Equality check so we only re-render / re-equip when the list actually changes.
local function sameList(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i].serverTool ~= b[i].serverTool then return false end
    end
    return true
end

local function renderSlot(i)
    if not hotbar then return end
    local slot = hotbar:FindFirstChild("Slot" .. i)
    if not slot then return end
    local item = items[pageStart + i - 1]
    local itemIcon = slot:FindFirstChild("ItemIcon")
    local emojiLabel = itemIcon and itemIcon:FindFirstChild("EmojiLabel")
    local lockOverlay = slot:FindFirstChild("LockOverlay")
    if item then
        slot.Visible = true
        if lockOverlay then lockOverlay.Visible = false end
        -- US8: show the real icon when the item has one, else fall back to the emoji.
        if item.icon and item.icon ~= "" then
            if itemIcon then itemIcon.Image = item.icon end
            if emojiLabel then emojiLabel.Text = "" end
        else
            if itemIcon then itemIcon.Image = "rbxassetid://0" end
            if emojiLabel then emojiLabel.Text = item.emoji end
        end
    else
        -- Feature 005: no tool/seed for this slot yet — show the locked placeholder
        -- (e.g. the future lantern/net/shovel slots) and blank the icon.
        if lockOverlay then lockOverlay.Visible = true end
        if emojiLabel then emojiLabel.Text = "" end
        if itemIcon then itemIcon.Image = "rbxassetid://0" end
    end
end

local function UpdateSlotVisuals()
    if not hotbar then return end
    local equippedSlotPos = equippedIndex - pageStart + 1
    for i = 1, VISIBLE_SLOTS do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if slot then
            local selectionBorder = slot:FindFirstChild("SelectionBorder")
            local slotButton = slot:FindFirstChild("SlotButton")
            local selected = (i == equippedSlotPos)
            if selectionBorder then
                selectionBorder.Visible = selected
                selectionBorder.ImageTransparency = selected and 0 or 1
            end
            if slotButton then
                TweenService:Create(slotButton, TweenInfo.new(0.15), {
                    BackgroundColor3 = selected and Theme.Accent or Theme.Control,
                }):Play()
            end
        end
    end
end

local function render()
    for i = 1, VISIBLE_SLOTS do renderSlot(i) end
    UpdateSlotVisuals()
end

-- Sync the equipped item to the server and refresh highlight.
local function equipCurrent(notify)
    local item = items[equippedIndex]
    if not item then return end
    if EquipTool then
        pcall(function() EquipTool:FireServer(item.serverTool) end)
    end
    UpdateSlotVisuals()
    if notify then
        local ok, UIController = pcall(require, script.Parent:FindFirstChild("UIController"))
        if ok and UIController then
            UIController.ShowNotification("Equipped: " .. item.displayName, "info", 1.5)
        end
    end
end

-- Ensure the equipped item is within the visible window; page if needed.
local function ensureVisible()
    if equippedIndex < pageStart then
        pageStart = equippedIndex
    elseif equippedIndex > pageStart + VISIBLE_SLOTS - 1 then
        pageStart = equippedIndex - VISIBLE_SLOTS + 1
    end
    pageStart = math.max(1, math.min(pageStart, math.max(1, #items - VISIBLE_SLOTS + 1)))
end

--[[ Equip the item in a visible slot (1..VISIBLE_SLOTS). ]]
function HotbarController.EquipSlot(slotPos)
    local idx = pageStart + slotPos - 1
    if idx < 1 or idx > #items then return end
    equippedIndex = idx
    ensureVisible()
    render()
    equipCurrent(true)
end

--[[ Equip a hotbar item by its serverTool id (used by the Backpack Equip action).
     Returns false (and does nothing) when the item is not on the hotbar. ]]
function HotbarController.EquipByItemName(name)
    for idx, item in ipairs(items) do
        if item.serverTool == name then
            equippedIndex = idx
            ensureVisible()
            render()
            equipCurrent(true)
            return true
        end
    end
    return false
end

--[[ Cycle the equipped item through the whole list (L1/R1). ]]
local function cycle(dir)
    if #items == 0 then return end
    equippedIndex = equippedIndex + dir
    if equippedIndex < 1 then equippedIndex = #items end
    if equippedIndex > #items then equippedIndex = 1 end
    ensureVisible()
    render()
    equipCurrent(true)
end

function HotbarController.NextSlot() cycle(1) end
function HotbarController.PreviousSlot() cycle(-1) end

function HotbarController.GetEquippedTool()
    local item = items[equippedIndex]
    return item and item.serverTool or "basic_watering_can"
end

function HotbarController.GetEquippedToolInfo()
    return items[equippedIndex]
end

function HotbarController.GetAllSlots()
    return items
end

--[[ Rebuild the hotbar from an inventory snapshot (FR-012). Keeps the equipped
     item if it still exists; a newly bought seed lands in the first free slot. ]]
function HotbarController.RefreshFromInventory(inv)
    local newItems = buildItems(inv)
    if sameList(items, newItems) then
        return -- nothing changed; stay incremental
    end
    -- preserve the currently equipped serverTool across the rebuild if possible
    local prevTool = items[equippedIndex] and items[equippedIndex].serverTool
    items = newItems
    local newIdx = 1
    if prevTool then
        for i, it in ipairs(items) do
            if it.serverTool == prevTool then newIdx = i break end
        end
    end
    equippedIndex = math.max(1, math.min(newIdx, #items))
    ensureVisible()
    render()
    equipCurrent(false)
end

--[[ Use the equipped tool on a target plot. Server uses its own equipped state. ]]
function HotbarController.UseTool(target)
    local toolName = HotbarController.GetEquippedTool()
    if not target or not InteractWithPlot then return end
    if not target:IsA("Model") and not target:IsA("Part") then return end
    pcall(function() InteractWithPlot:FireServer(target, toolName) end)
    if hotbar then
        local slotPos = equippedIndex - pageStart + 1
        local slot = hotbar:FindFirstChild("Slot" .. slotPos)
        local itemIcon = slot and slot:FindFirstChild("ItemIcon")
        if itemIcon then
            local originalSize = itemIcon.Size
            TweenService:Create(itemIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
                Size = UDim2.new(originalSize.X.Scale * 1.2, 0, originalSize.Y.Scale * 1.2, 0),
            }):Play()
        end
    end
end

local function SetupSlotButtons()
    if not hotbar then return end
    for i = 1, VISIBLE_SLOTS do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        local slotButton = slot and slot:FindFirstChild("SlotButton")
        if slotButton and slotButton:IsA("GuiButton") then
            slotButton.MouseButton1Click:Connect(function()
                HotbarController.EquipSlot(i)
            end)
            slotButton.MouseEnter:Connect(function()
                if (pageStart + i - 1) ~= equippedIndex then
                    TweenService:Create(slotButton, TweenInfo.new(0.1), { BackgroundColor3 = Theme.ControlHover }):Play()
                end
            end)
            slotButton.MouseLeave:Connect(function()
                if (pageStart + i - 1) ~= equippedIndex then
                    TweenService:Create(slotButton, TweenInfo.new(0.1), { BackgroundColor3 = Theme.Control }):Play()
                end
            end)
        end
    end
end

local function SetupKeyboardShortcuts()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.One then
            HotbarController.EquipSlot(1)
        elseif input.KeyCode == Enum.KeyCode.Two then
            HotbarController.EquipSlot(2)
        elseif input.KeyCode == Enum.KeyCode.Three then
            HotbarController.EquipSlot(3)
        elseif input.KeyCode == Enum.KeyCode.Four then
            HotbarController.EquipSlot(4)
        elseif input.KeyCode == Enum.KeyCode.Five then
            HotbarController.EquipSlot(5)
        end
    end)
end

local function SetupMouseClickDetection()
    local Mouse = player:GetMouse()
    Mouse.Button1Down:Connect(function()
        -- R6/FR-008: never use a tool when a window is open or when the press lands
        -- on an Active GUI element, so taps on the UI do not also water/plant.
        if WindowManager.GetOpen() ~= nil then return end
        local inset = GuiService:GetGuiInset()
        local mp = UserInputService:GetMouseLocation()
        for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(mp.X - inset.X, mp.Y - inset.Y)) do
            if obj.Active then return end
        end
        local target = Mouse.Target
        if not target then return end
        local parent = target.Parent
        if parent and parent:IsA("Model") then
            local isPlot = parent:FindFirstChild("PlotMarker") or parent.Name:lower():find("plot") or parent:FindFirstChild("PlotData")
            if isPlot then
                HotbarController.UseTool(parent)
            end
        end
    end)
end

function HotbarController.Initialize()
    print("========================================")
    print("🎮 Initializing HotbarController (inventory-driven)...")
    print("========================================")
    if not hotbar then
        warn("⚠️ Hotbar not found - controller in limited mode")
    end

    SetupSlotButtons()
    SetupKeyboardShortcuts()
    SetupMouseClickDetection()

    -- Build from the current inventory, then keep it in sync (FR-012).
    HotbarController.RefreshFromInventory(StateManager.getInventory())
    StateManager.subscribe(function(state)
        HotbarController.RefreshFromInventory(state.player and state.player.inventory)
    end)

    print("✅ Hotbar built from inventory; L1/R1 cycle, [1][2][3] select")
    print("========================================")
    print("✨ HotbarController ready!")
    print("========================================")
end

HotbarController.Initialize()

return HotbarController
