--[[
    DailyRewardController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/ (ModuleScript) — feature 003, US1

    Renders the 7-day streak track in DailyRewardUI from the server state, fills each
    day's reward from RetentionConfig (constitution II: numbers come from config, not
    from baked GUI text), claims via ClaimDailyReward, and auto-opens the window on the
    first login of the day. The server decides claimability and the streak; this
    controller only reads and requests (constitution I). Opens from the HUD Rewards
    button (touch) or the R / D-pad-up action (InputActions).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RetentionConfig = require(ReplicatedStorage:WaitForChild("RetentionConfig"))
local Utils = script.Parent.Parent:WaitForChild("Utils")
local WindowManager = require(Utils:WaitForChild("WindowManager"))

local DailyRewardController = {}

local DailyRewardUI = playerGui:WaitForChild("DailyRewardUI")
local RewardFrame = DailyRewardUI:WaitForChild("RewardFrame")
local HeaderBar = RewardFrame:WaitForChild("HeaderBar")
local StreakLabel = HeaderBar:WaitForChild("StreakLabel")
local TrackRow = RewardFrame:WaitForChild("TrackRow")
local ClaimButton = RewardFrame:WaitForChild("ClaimButton")
local Theme = require(ReplicatedStorage:WaitForChild("UITheme"))

local GetDailyReward = ReplicatedStorage:WaitForChild("GetDailyReward")
local ClaimDailyReward = ReplicatedStorage:WaitForChild("ClaimDailyReward")

local function uiController()
    local ok, mod = pcall(require, script.Parent:WaitForChild("UIController", 5))
    return ok and mod or nil
end

-- Fill the static reward amounts once from config (constitution II).
local function fillRewardAmounts()
    for i = 1, 7 do
        local cell = TrackRow:FindFirstChild("Day" .. i)
        local reward = RetentionConfig.DailyRewards[i]
        if cell and reward then
            local coinsLabel = cell:FindFirstChild("CoinsLabel")
            local seedsLabel = cell:FindFirstChild("SeedsLabel")
            if coinsLabel then coinsLabel.Text = "💰 " .. tostring(reward.coins or 0) end
            if seedsLabel then
                local seeds = tonumber(reward.seeds) or 0
                seedsLabel.Visible = seeds > 0
                seedsLabel.Text = seeds > 0 and ("🌙 " .. seeds) or ""
            end
        end
    end
end

-- Apply server state to the track + claim button.
local function render(state)
    if not state then return end
    StreakLabel.Text = string.format("Day %d / 7", state.StreakDay or 0)

    for i = 1, 7 do
        local cell = TrackRow:FindFirstChild("Day" .. i)
        if cell then
            local stroke = cell:FindFirstChild("TodayStroke")
            local check = cell:FindFirstChild("ClaimedCheck")
            -- "today" = the day a claim now would grant (highlighted + claimable).
            if stroke then stroke.Enabled = (i == state.Today) end
            -- A day is shown claimed when it is <= the current StreakDay and today
            -- is already claimed (not Claimable), i.e. this day has been collected.
            if check then
                local claimed = (not state.Claimable) and i <= (state.StreakDay or 0)
                check.Visible = claimed
            end
        end
    end

    if state.Claimable then
        ClaimButton.Text = "CLAIM"
        ClaimButton.BackgroundColor3 = Theme.Accent
        ClaimButton.AutoButtonColor = true
        ClaimButton.Active = true
        ClaimButton.Selectable = true
    else
        ClaimButton.Text = "COME BACK TOMORROW"
        ClaimButton.BackgroundColor3 = Theme.Control
        ClaimButton.AutoButtonColor = false
        ClaimButton.Active = false
        ClaimButton.Selectable = false
    end
end

local lastState = nil

function DailyRewardController.Refresh()
    local ok, res = pcall(function() return GetDailyReward:InvokeServer() end)
    if ok and type(res) == "table" and res.Success then
        lastState = res
        render(res)
    else
        warn("⚠️ DailyRewardController: GetDailyReward failed:", ok and (res and res.Error) or res)
    end
end

local function onClaim()
    if lastState and not lastState.Claimable then return end
    local ok, res = pcall(function() return ClaimDailyReward:InvokeServer() end)
    if ok and type(res) == "table" and res.Success then
        local ui = uiController()
        local msg = "Daily reward: +" .. (res.Granted and res.Granted.coins or 0) .. " coins"
        if res.Granted and (res.Granted.seeds or 0) > 0 then
            msg = msg .. ", +" .. res.Granted.seeds .. " dream seeds"
        end
        if ui then ui.ShowNotification(msg, "success", 3) end
        DailyRewardController.Refresh()
    else
        local ui = uiController()
        local why = (type(res) == "table" and res.Error) or "Try again"
        if ui then ui.ShowNotification("Can't claim: " .. tostring(why), "error", 3) end
    end
end

function DailyRewardController.Initialize()
    fillRewardAmounts()

    WindowManager.Register("Rewards", {
        gui = DailyRewardUI,
        frame = RewardFrame,
        backdrop = DailyRewardUI:FindFirstChild("Backdrop"),
        closeButton = HeaderBar:FindFirstChild("CloseButton"),
        defaultSelection = function() return ClaimButton end,
        onOpen = function() DailyRewardController.Refresh() end,
    })

    -- Close (X) delegates to WindowManager (backdrop + gamepad B handled there).
    local closeButton = HeaderBar:FindFirstChild("CloseButton")
    if closeButton then
        closeButton.Activated:Connect(function() WindowManager.Close() end)
    end

    ClaimButton.Activated:Connect(onClaim)

    -- HUD Rewards button (touch path); keyboard/gamepad go through InputActions.
    local hudControls = playerGui:FindFirstChild("HUDControls")
    local menuButtons = hudControls and hudControls:FindFirstChild("MenuButtons")
    local rewardsButton = menuButtons and menuButtons:FindFirstChild("RewardsButton")
    if rewardsButton then
        rewardsButton.Activated:Connect(function() WindowManager.Toggle("Rewards") end)
    end

    -- Auto-open on the first login of the day (when a reward is claimable).
    task.spawn(function()
        DailyRewardController.Refresh()
        if lastState and lastState.Claimable then
            WindowManager.Open("Rewards")
        end
    end)

    print("✅ DailyRewardController ready")
end

DailyRewardController.Initialize()

return DailyRewardController
