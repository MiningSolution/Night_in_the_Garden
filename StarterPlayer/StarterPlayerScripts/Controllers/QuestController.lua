--[[
    QuestController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/ (ModuleScript) — feature 003, US2

    Renders the day's quests in QuestsUI from the server, updates a row's progress
    incrementally on QuestUpdated, and claims via ClaimQuest. The server owns progress
    and completion (constitution I); this controller only renders and requests. Opens
    from the HUD Quests button (touch) or the Q / D-pad-down action (InputActions).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Utils = script.Parent.Parent:WaitForChild("Utils")
local WindowManager = require(Utils:WaitForChild("WindowManager"))
local Theme = require(ReplicatedStorage:WaitForChild("UITheme"))

local QuestController = {}

local QuestsUI = playerGui:WaitForChild("QuestsUI")
local QuestsFrame = QuestsUI:WaitForChild("QuestsFrame")
local HeaderBar = QuestsFrame:WaitForChild("HeaderBar")
local QuestScroll = QuestsFrame:WaitForChild("QuestScroll")
local RowTemplate = QuestScroll:WaitForChild("QuestRowTemplate")
local EmptyState = QuestsFrame:WaitForChild("EmptyState")

local GetQuests = ReplicatedStorage:WaitForChild("GetQuests")
local ClaimQuest = ReplicatedStorage:WaitForChild("ClaimQuest")
local QuestUpdated = ReplicatedStorage:WaitForChild("QuestUpdated")

local function uiController()
    local ok, mod = pcall(require, script.Parent:WaitForChild("UIController", 5))
    return ok and mod or nil
end

-- id -> { row, target, claimed } for incremental QuestUpdated handling.
local rows = {}

local function rewardText(reward)
    local parts = {}
    if reward and (reward.coins or 0) > 0 then parts[#parts + 1] = "💰 " .. reward.coins end
    if reward and (reward.seeds or 0) > 0 then parts[#parts + 1] = "🌙 " .. reward.seeds end
    return table.concat(parts, "   ")
end

local function applyRowState(entry, progress, claimed)
    local row = entry.row
    local target = entry.target
    progress = math.min(target, progress or 0)
    entry.claimed = claimed
    local progressLabel = row:FindFirstChild("ProgressBarBG") and row.ProgressBarBG:FindFirstChild("ProgressLabel")
    local bar = row:FindFirstChild("ProgressBarBG") and row.ProgressBarBG:FindFirstChild("ProgressBar")
    local claimButton = row:FindFirstChild("ClaimButton")
    if progressLabel then progressLabel.Text = string.format("%d / %d", progress, target) end
    if bar then bar.Size = UDim2.new(target > 0 and (progress / target) or 0, 0, 1, 0) end
    if claimButton then
        local complete = progress >= target
        if claimed then
            claimButton.Text = "CLAIMED"
            claimButton.BackgroundColor3 = Theme.Control
            claimButton.AutoButtonColor = false
            claimButton.Active = false
            claimButton.Selectable = false
        elseif complete then
            claimButton.Text = "CLAIM"
            claimButton.BackgroundColor3 = Theme.Accent
            claimButton.AutoButtonColor = true
            claimButton.Active = true
            claimButton.Selectable = true
        else
            claimButton.Text = "CLAIM"
            claimButton.BackgroundColor3 = Theme.Control
            claimButton.AutoButtonColor = false
            claimButton.Active = false
            claimButton.Selectable = false
        end
    end
end

local function onClaim(questId, entry)
    if entry.claimed or (entry.progress or 0) < entry.target then return end
    local ok, res = pcall(function() return ClaimQuest:InvokeServer(questId) end)
    local ui = uiController()
    if ok and type(res) == "table" and res.Success then
        if ui then
            local msg = "Quest complete!  +" .. (res.Granted and res.Granted.coins or 0) .. " coins"
            if res.Granted and (res.Granted.seeds or 0) > 0 then msg = msg .. ", +" .. res.Granted.seeds .. " seeds" end
            ui.ShowNotification(msg, "success", 3)
        end
        applyRowState(entry, entry.target, true)
    else
        local why = (type(res) == "table" and res.Error) or "Try again"
        if ui then ui.ShowNotification("Can't claim: " .. tostring(why), "error", 3) end
    end
end

local function clearRows()
    for _, child in ipairs(QuestScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "QuestRowTemplate" then
            child:Destroy()
        end
    end
    rows = {}
end

function QuestController.Refresh()
    local ok, res = pcall(function() return GetQuests:InvokeServer() end)
    if not (ok and type(res) == "table" and res.Success) then
        warn("⚠️ QuestController: GetQuests failed:", ok and (res and res.Error) or res)
        return
    end
    clearRows()
    local quests = res.Quests or {}
    EmptyState.Visible = #quests == 0
    for i, q in ipairs(quests) do
        local row = RowTemplate:Clone()
        row.Name = "Quest_" .. q.id
        row.LayoutOrder = i
        row.Visible = true
        local objective = row:FindFirstChild("ObjectiveLabel")
        local reward = row:FindFirstChild("RewardLabel")
        if objective then objective.Text = q.text or q.id end
        if reward then reward.Text = rewardText(q.reward) end
        row.Parent = QuestScroll

        local entry = { row = row, target = q.target, claimed = q.claimed, progress = q.progress }
        rows[q.id] = entry
        applyRowState(entry, q.progress, q.claimed)

        local claimButton = row:FindFirstChild("ClaimButton")
        if claimButton then
            claimButton.Activated:Connect(function() onClaim(q.id, entry) end)
        end
    end
end

function QuestController.Initialize()
    WindowManager.Register("Quests", {
        gui = QuestsUI,
        frame = QuestsFrame,
        backdrop = QuestsUI:FindFirstChild("Backdrop"),
        closeButton = HeaderBar:FindFirstChild("CloseButton"),
        defaultSelection = function()
            local first = QuestScroll:FindFirstChildWhichIsA("Frame")
            return (first and first.Name ~= "QuestRowTemplate" and first:FindFirstChild("ClaimButton")) or nil
        end,
        onOpen = function() QuestController.Refresh() end,
    })

    local closeButton = HeaderBar:FindFirstChild("CloseButton")
    if closeButton then
        closeButton.Activated:Connect(function() WindowManager.Close() end)
    end

    -- Incremental progress/claim updates from the server.
    QuestUpdated.OnClientEvent:Connect(function(questId, progress, claimed)
        local entry = rows[questId]
        if entry then
            entry.progress = progress
            applyRowState(entry, progress, claimed)
        end
    end)

    -- HUD Quests button (touch); keyboard/gamepad go through InputActions.
    local hudControls = playerGui:FindFirstChild("HUDControls")
    local menuButtons = hudControls and hudControls:FindFirstChild("MenuButtons")
    local questsButton = menuButtons and menuButtons:FindFirstChild("QuestsButton")
    if questsButton then
        questsButton.Activated:Connect(function() WindowManager.Toggle("Quests") end)
    end

    print("✅ QuestController ready")
end

QuestController.Initialize()

return QuestController
