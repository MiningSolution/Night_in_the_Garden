--[[
    TutorialController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/ (ModuleScript) — feature 003, US5

    First-session onboarding: guides a new player through plant -> water -> sell, one
    step at a time, advancing on the matching gameplay event. It runs only when the
    persisted Onboarding.Done flag is false, is skippable, persists completion via
    SetTutorialDone (so it shows once, FR-011), and never blocks movement, the menu
    column or the hotbar (only the Skip button is interactive). Plant/water are
    detected from PlotStateChanged; sell is reported by SellController.NotifyAction.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GetPlayerData = ReplicatedStorage:WaitForChild("GetPlayerData")
local SetTutorialDone = ReplicatedStorage:WaitForChild("SetTutorialDone")
local PlotStateChanged = ReplicatedStorage:WaitForChild("PlotStateChanged")

local TutorialController = {}

-- plant -> water -> sell, in order (R10; the plan's arrow-to-plot flow).
local STEPS = {
    { kind = "plant", text = "👉 Equip a seed and tap a plot to plant it." },
    { kind = "water", text = "💧 Equip the watering can and water your plant." },
    { kind = "sell",  text = "💰 Harvest it when ripe, then sell it at the stall." },
}

local active = false
local current = 0
local hint, hintLabel

local function getHint()
    if hint and hint.Parent then return hint end
    local notifs = playerGui:FindFirstChild("Notifications")
    hint = notifs and notifs:FindFirstChild("TutorialHint")
    hintLabel = hint and hint:FindFirstChild("HintLabel")
    return hint
end

local function showStep(i)
    local h = getHint()
    if not h then return end
    local step = STEPS[i]
    if not step then return end
    if hintLabel then hintLabel.Text = step.text end
    h.Visible = true
end

local function finish()
    active = false
    local h = getHint()
    if h then h.Visible = false end
    pcall(function() SetTutorialDone:InvokeServer() end)
end

-- Called from the client event sites (PlotStateChanged here, sell via SellController).
function TutorialController.NotifyAction(kind)
    if not active then return end
    local step = STEPS[current]
    if step and step.kind == kind then
        current = current + 1
        if current > #STEPS then
            finish()
        else
            showStep(current)
        end
    end
end

function TutorialController.Initialize()
    -- Decide whether to run from the persisted onboarding flag (server-owned).
    local onboarding
    local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
    if ok and type(data) == "table" and data.Success then
        onboarding = data.Onboarding
    end
    if onboarding and onboarding.Done then
        print("✅ TutorialController: onboarding already done — not shown")
        return
    end

    active = true
    current = 1

    -- Skip ends the tutorial and persists completion.
    local h = getHint()
    local skip = h and h:FindFirstChild("SkipButton")
    if skip then
        skip.Activated:Connect(function() finish() end)
    end

    -- Plant / water detection from the authoritative plot updates.
    PlotStateChanged.OnClientEvent:Connect(function(_plotId, plot)
        if not active or type(plot) ~= "table" then return end
        if plot.State == "Planted" then
            TutorialController.NotifyAction("plant")
        elseif plot.IsWatered == true then
            TutorialController.NotifyAction("water")
        end
    end)

    showStep(current)
    print("✅ TutorialController ready (onboarding started)")
end

TutorialController.Initialize()

return TutorialController
