--[[
    CreateNotifications.lua
    Location: StarterGui (as LocalScript) — feature 002, User Story 4

    Builds the Notifications ScreenGui: a separate always-on-top layer for toast
    messages (purchase, error, crop-ready, spirit-caught). ToastQueue clones the
    hidden ToastTemplate per message (constitution III: a static template cloned at
    runtime). High DisplayOrder keeps toasts above the windows; the container is
    top-centre inside the safe area so it never blocks the menu column (left) or the
    hotbar (bottom). Colours from UITheme/Constants (V); body text >= 18 (IV).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("Notifications") then
    print("⚠️ Notifications already exists, skipping creation")
    return
end

print("🎨 Creating Notifications...")

local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))

local Notifications = Instance.new("ScreenGui")
Notifications.Name = "Notifications"
Notifications.ResetOnSpawn = false
Notifications.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Notifications.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
Notifications.IgnoreGuiInset = false
Notifications.DisplayOrder = 100 -- above the windows (FR-011)
Notifications.Enabled = true
Notifications.Parent = playerGui

-- Top-centre stack, clear of the left menu column and the bottom hotbar.
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.AnchorPoint = Vector2.new(0.5, 0)
ToastContainer.Position = UDim2.new(0.5, 0, 0, 12)
ToastContainer.Size = UDim2.new(0, 360, 1, -24)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = Notifications

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = ToastContainer

-- Hidden template cloned per toast by ToastQueue.
local Toast = Instance.new("Frame")
Toast.Name = "ToastTemplate"
Toast.Size = UDim2.new(1, 0, 0, 52)
Toast.AutomaticSize = Enum.AutomaticSize.Y
Toast.BackgroundColor3 = Theme.Surface
Toast.BackgroundTransparency = 0.05
Toast.BorderSizePixel = 0
Toast.Visible = false
Toast.Parent = ToastContainer

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = Toast

-- Coloured accent bar on the left; ToastQueue sets its colour by message type.
local Bar = Instance.new("Frame")
Bar.Name = "Bar"
Bar.Size = UDim2.new(0, 6, 1, -12)
Bar.Position = UDim2.new(0, 6, 0, 6)
Bar.BackgroundColor3 = Theme.Accent
Bar.BorderSizePixel = 0
Bar.Parent = Toast

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 3)
barCorner.Parent = Bar

local Icon = Instance.new("TextLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 32, 0, 32)
Icon.Position = UDim2.new(0, 18, 0.5, 0)
Icon.AnchorPoint = Vector2.new(0, 0.5)
Icon.BackgroundTransparency = 1
Icon.Text = "ℹ️"
Icon.TextSize = 22
Icon.Font = Enum.Font.GothamBold
Icon.Parent = Toast

local MessageLabel = Instance.new("TextLabel")
MessageLabel.Name = "MessageLabel"
MessageLabel.Size = UDim2.new(1, -70, 1, -12)
MessageLabel.Position = UDim2.new(0, 58, 0, 6)
MessageLabel.BackgroundTransparency = 1
MessageLabel.Text = "Notification"
MessageLabel.TextColor3 = Theme.TextPrimary
MessageLabel.TextSize = 18
MessageLabel.Font = Enum.Font.GothamMedium
MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
MessageLabel.TextYAlignment = Enum.TextYAlignment.Center
MessageLabel.TextWrapped = true
MessageLabel.Parent = Toast

print("✅ Notifications created successfully!")
