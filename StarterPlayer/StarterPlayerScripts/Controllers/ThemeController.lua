--[[
    ThemeController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/

    PURPOSE:
    Applies the active day/night colour palette (UITheme.Palettes) to the static
    GUI at runtime, so the GUI never has to be regenerated to change phase.

    BINDING:
    The static GUI builders bake theme-tag attributes onto instances:
      - Theme_<Property> = "<Token>"   (e.g. Theme_BackgroundColor3 = "Control")
      - UIStroke:   Theme_Color = "<Token>"
      - UIGradient: Theme_GradientTop / Theme_GradientBottom = "<Token>"

    PAINTING:
      - Paint / PaintInstant: instant, used on join and for fresh clones (no flash)
      - Repaint: tweened, used only when the phase actually changes
    No per-frame work: the tree walk runs on Initialize and on a real phase change.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StateManager = require(script.Parent.Parent.Utils:WaitForChild("StateManager"))
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))

local ThemeController = {}

local SCREEN_GUIS = {
    "HUD", "HUDControls", "ShopUI", "InventoryUI",
    "SellUI", "Notifications", "DailyRewardUI", "QuestsUI",
}
local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PREFIX = "Theme_"

local player = Players.LocalPlayer
local currentPhase = UITheme.DefaultPhase
local lastSeenPhase = nil
local screenGuis = {} -- ScreenGuis found so far (name -> instance)

local function resolve(token)
    if type(token) ~= "string" then return nil end
    return UITheme.Resolve(token, currentPhase)
end

-- Apply one instance's theme attributes. animated = tween Color3s, else set.
local function applyInstance(inst, animated)
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if not ok or not attrs then return end

    local tweenGoals = nil

    local function set(prop, color)
        if animated then
            tweenGoals = tweenGoals or {}
            tweenGoals[prop] = color
        else
            pcall(function() inst[prop] = color end)
        end
    end

    local gradTop, gradBottom = nil, nil
    for name, token in pairs(attrs) do
        if string.sub(name, 1, #PREFIX) == PREFIX then
            local prop = string.sub(name, #PREFIX + 1)
            if prop == "GradientTop" then
                gradTop = resolve(token)
            elseif prop == "GradientBottom" then
                gradBottom = resolve(token)
            else
                local color = resolve(token)
                if color then set(prop, color) end
            end
        end
    end

    if tweenGoals then
        pcall(function() TweenService:Create(inst, TWEEN_INFO, tweenGoals):Play() end)
    end

    -- TweenService cannot tween a ColorSequence, so gradients are set immediately.
    if gradTop and gradBottom and inst:IsA("UIGradient") then
        pcall(function() inst.Color = ColorSequence.new(gradTop, gradBottom) end)
    end
end

local function walk(root, animated)
    if not root then return end
    applyInstance(root, animated)
    for _, d in ipairs(root:GetDescendants()) do
        applyInstance(d, animated)
    end
end

function ThemeController.CurrentPhase()
    return currentPhase
end

function ThemeController.Current()
    return UITheme.Palettes[currentPhase]
end

function ThemeController.PaintInstant(inst)
    if inst then applyInstance(inst, false) end
end

function ThemeController.Paint(root)
    walk(root, false)
end

function ThemeController.Repaint(phase)
    if phase ~= nil and UITheme.Palettes[phase] then
        currentPhase = phase
    end
    for _, gui in pairs(screenGuis) do
        walk(gui, true)
    end
end

function ThemeController.Initialize()
    local phase = StateManager.getDayNight()
    if not (phase and UITheme.Palettes[phase]) then
        phase = UITheme.DefaultPhase
    end
    currentPhase = phase
    lastSeenPhase = phase

    local playerGui = player:WaitForChild("PlayerGui")
    for _, name in ipairs(SCREEN_GUIS) do
        local gui = playerGui:WaitForChild(name, 10)
        if gui then
            screenGuis[name] = gui
            walk(gui, false)
        else
            warn("⚠️ ThemeController: ScreenGui not found: " .. name)
        end
    end

    local event = ReplicatedStorage:WaitForChild("DayNightUpdate", 10)
    if event then
        event.OnClientEvent:Connect(function(newPhase, _progress)
            if newPhase == lastSeenPhase or not UITheme.Palettes[newPhase] then return end
            lastSeenPhase = newPhase
            ThemeController.Repaint(newPhase)
        end)
    else
        warn("⚠️ ThemeController: DayNightUpdate not found")
    end
end

return ThemeController
