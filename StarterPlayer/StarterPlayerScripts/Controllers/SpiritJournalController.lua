--[[
    SpiritJournalController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/
    Feature 006, US3 (FR-012/FR-013).

    Drives the SpiritJournalUI (built by Tools/StaticGui/builders/CreateSpiritJournalUI.luau):
    a catalogue of EVERY known spirit type. On open it reads the player's SpiritCollection
    from the server (GetPlayerData snapshot) and the full type set from the single-source
    ReplicatedStorage/SpiritData, then clones EntryTemplate per type — discovered entries show
    their name/rarity/count/first-caught, undiscovered ones show a locked "???" — and sets the
    "N / M discovered" progress. The client only renders; the collection is server-owned (I).

    This stage the Journal is a cosmetic catalogue (no reward for completion).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Utils = script.Parent.Parent:WaitForChild("Utils")
local WindowManager = require(Utils:WaitForChild("WindowManager"))
local SpiritData = require(ReplicatedStorage:WaitForChild("SpiritData"))
local ItemEmoji = require(ReplicatedStorage:WaitForChild("ItemEmoji"))

local SpiritJournalController = {}

-- UI references (resolved in Init)
local JournalUI, JournalFrame, EntryScroll, EntryTemplate, ProgressLabel, EmptyState, CloseButton, Backdrop

-- Lazily required so load order is safe.
local function getThemeController()
    local ok, tc = pcall(require, script.Parent:FindFirstChild("ThemeController"))
    return ok and tc or nil
end

local function paint(inst)
    local tc = getThemeController()
    if tc and tc.PaintInstant then tc.PaintInstant(inst) end
end

-- Pull the player's SpiritCollection from the server snapshot (read-only).
local function fetchCollection()
    local fn = ReplicatedStorage:FindFirstChild("GetPlayerData")
    if not fn then return {} end
    local ok, result = pcall(function() return fn:InvokeServer() end)
    if ok and type(result) == "table" and result.Success then
        return result.SpiritCollection or {}
    end
    return {}
end

local function clearEntries()
    for _, child in ipairs(EntryScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EntryTemplate" then
            child:Destroy()
        end
    end
end

local function makeEntry(index, spiritType, record)
    local discovered = record and (record.FirstCaughtAt or 0) > 0

    local entry = EntryTemplate:Clone()
    entry.Name = "Entry_" .. spiritType.id
    entry.LayoutOrder = index
    entry.Visible = true

    local icon = entry:FindFirstChild("Icon")
    local fallback = icon and icon:FindFirstChild("FallbackLetter")
    local nameLabel = entry:FindFirstChild("NameLabel")
    local countLabel = entry:FindFirstChild("CountLabel")
    local firstLabel = entry:FindFirstChild("FirstCaughtLabel")
    local badge = entry:FindFirstChild("RarityBadge")
    local badgeText = badge and badge:FindFirstChild("BadgeText")

    if discovered then
        local glyph = ItemEmoji.get(spiritType.id)
        if fallback then
            fallback.Text = (glyph ~= "" and glyph) or (spiritType.displayName:sub(1, 1):upper())
        end
        if nameLabel then nameLabel.Text = spiritType.displayName end
        if countLabel then countLabel.Text = "×" .. tostring(record.Count or 1) end
        if firstLabel then
            firstLabel.Text = "First: " .. os.date("%b %d", record.FirstCaughtAt)
        end
        if badge then badge:SetAttribute("Theme_BackgroundColor3", "Rarity" .. spiritType.rarity) end
        if badgeText then badgeText.Text = string.upper(spiritType.rarity) end
    else
        -- Undiscovered: locked silhouette.
        if fallback then fallback.Text = "?" end
        if nameLabel then nameLabel.Text = "???" end
        if countLabel then countLabel.Text = "Undiscovered" end
        if firstLabel then firstLabel.Text = "" end
        if badge then badge:SetAttribute("Theme_BackgroundColor3", "Control") end
        if badgeText then badgeText.Text = "???" end
        entry.BackgroundTransparency = 0.35
    end

    entry.Parent = EntryScroll
    paint(entry) -- apply the active palette to the clone (incl. the badge tier colour)
    return discovered
end

--[[ Rebuild the Journal from the current collection + the full catalog. ]]
function SpiritJournalController.Render()
    if not JournalUI then return end
    clearEntries()

    local collection = fetchCollection()
    local total = 0
    local discoveredCount = 0
    for i, spiritType in ipairs(SpiritData.Types) do
        total += 1
        if makeEntry(i, spiritType, collection[spiritType.id]) then
            discoveredCount += 1
        end
    end

    if ProgressLabel then
        ProgressLabel.Text = string.format("%d / %d discovered", discoveredCount, total)
    end
    if EmptyState then EmptyState.Visible = total == 0 end
    EntryScroll.Visible = total > 0
end

--[[ Open the Journal (used by the Backpack Spirits tab action / a HUD entry). ]]
function SpiritJournalController.Open()
    WindowManager.Open("SpiritJournal")
end

function SpiritJournalController.Init()
    JournalUI = playerGui:WaitForChild("SpiritJournalUI")
    JournalFrame = JournalUI:WaitForChild("JournalFrame")
    EntryScroll = JournalFrame:WaitForChild("EntryScroll")
    EntryTemplate = EntryScroll:WaitForChild("EntryTemplate")
    ProgressLabel = JournalFrame:WaitForChild("HeaderBar"):WaitForChild("ProgressLabel")
    EmptyState = JournalFrame:FindFirstChild("EmptyState")
    CloseButton = JournalFrame:WaitForChild("HeaderBar"):WaitForChild("CloseButton")
    Backdrop = JournalUI:WaitForChild("Backdrop")

    WindowManager.Register("SpiritJournal", {
        gui = JournalUI,
        frame = JournalFrame,
        backdrop = Backdrop,
        closeButton = CloseButton,
        onOpen = function() SpiritJournalController.Render() end,
    })

    CloseButton.Activated:Connect(function() WindowManager.Close() end)

    print("✅ SpiritJournalController ready (FR-012)")
end

SpiritJournalController.Init()

return SpiritJournalController
