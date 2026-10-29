--[[
    ToastQueue.lua
    Location: StarterPlayer/StarterPlayerScripts/Utils (ModuleScript)
    Feature 002, User Story 4.

    A small FIFO queue that shows toast messages in the Notifications ScreenGui
    (built by Tools/StaticGui/builders/CreateNotifications.luau). Toasts are cloned
    from the static ToastTemplate and pooled (constitution perf: reuse instances).
    At most MAX_VISIBLE show at once; the rest wait their turn. Each toast colours
    its accent bar + icon by type, auto-expires, and never overlaps (UIListLayout).

    UIController.ShowNotification delegates here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("UITheme"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local ToastQueue = {}

local MAX_VISIBLE = 4
local DEFAULT_DURATION = Constants.UI.NOTIFICATION_DURATION or 3

local TYPE_COLOR = {
    success = Theme.Accent,
    error = Theme.Danger,
    info = Constants.COLORS.INFO,
    warning = Constants.COLORS.WARNING,
    spirit = Constants.COLORS.SPIRIT,
    event = Constants.COLORS.INFO,
}
local TYPE_ICON = {
    success = "✅", error = "❌", info = "ℹ️",
    warning = "⚠️", spirit = "👻", event = "✨",
}

local player = Players.LocalPlayer
local container, template
local pool = {}
local activeCount = 0
local pending = {}
local orderCounter = 0

local function resolveUI()
    if container and template then return true end
    local gui = player:FindFirstChild("PlayerGui")
    local notifications = gui and gui:FindFirstChild("Notifications")
    container = notifications and notifications:FindFirstChild("ToastContainer")
    template = container and container:FindFirstChild("ToastTemplate")
    return container ~= nil and template ~= nil
end

local function acquire()
    local toast = table.remove(pool)
    if not toast then
        toast = template:Clone()
        toast.Name = "Toast"
    end
    return toast
end

local function release(toast)
    toast.Visible = false
    toast.Parent = nil
    pool[#pool + 1] = toast
    activeCount -= 1
    -- show the next queued toast, if any
    local nextEntry = table.remove(pending, 1)
    if nextEntry then
        ToastQueue.Show(nextEntry.message, nextEntry.messageType, nextEntry.duration)
    end
end

--[[ Show (or queue) a toast. ]]
function ToastQueue.Show(message, messageType, duration)
    if not resolveUI() then
        warn("[ToastQueue] Notifications GUI not ready; message:", message)
        return
    end
    messageType = messageType or "info"
    duration = duration or DEFAULT_DURATION

    if activeCount >= MAX_VISIBLE then
        pending[#pending + 1] = { message = message, messageType = messageType, duration = duration }
        return
    end
    activeCount += 1

    local toast = acquire()
    orderCounter += 1
    toast.LayoutOrder = orderCounter
    local bar = toast:FindFirstChild("Bar")
    local icon = toast:FindFirstChild("Icon")
    local label = toast:FindFirstChild("MessageLabel")
    if bar then bar.BackgroundColor3 = TYPE_COLOR[messageType] or TYPE_COLOR.info end
    if icon then icon.Text = TYPE_ICON[messageType] or TYPE_ICON.info end
    if label then label.Text = tostring(message) end

    -- fade in
    toast.BackgroundTransparency = 1
    if label then label.TextTransparency = 1 end
    if icon then icon.TextTransparency = 1 end
    toast.Visible = true
    toast.Parent = container
    TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
    if label then TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0 }):Play() end
    if icon then TweenService:Create(icon, TweenInfo.new(0.2), { TextTransparency = 0 }):Play() end

    task.delay(duration, function()
        -- fade out, then pool
        local tween = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
        if label then TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1 }):Play() end
        if icon then TweenService:Create(icon, TweenInfo.new(0.25), { TextTransparency = 1 }):Play() end
        tween:Play()
        tween.Completed:Connect(function()
            release(toast)
        end)
    end)
end

return ToastQueue
