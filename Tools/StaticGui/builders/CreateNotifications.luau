--[[
    CreateNotifications.lua
    Location: StarterGui (as LocalScript) — feature 002, US4. Re-skinned feature 006 (US4).

    Builds the Notifications ScreenGui: an always-on-top layer for toast messages plus the
    event banners (NightBanner, AnnounceBanner) and the first-session TutorialHint.
    ToastQueue clones the hidden ToastTemplate per message (constitution III). Element
    names/structure are unchanged so ToastQueue / UIController / TutorialController keep
    working; themed colours are tagged with Theme_<Prop> so ThemeController retints them on
    day/night (V). The toast Bar colour is owned by ToastQueue (per message type), and the
    NightBanner keeps its fixed night-event colour; both stay untagged on purpose.
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
local Style = Theme.Style

local function bind(obj, prop, token)
    obj[prop] = Theme[token]
    obj:SetAttribute("Theme_" .. prop, token)
end
local function strokeOf(parent, token, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or Style.OutlineThickness
    s.Color = Theme[token]
    s:SetAttribute("Theme_Color", token)
    s.Parent = parent
    return s
end
local function roundCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or Style.CornerRadius)
    c.Parent = parent
    return c
end

local Notifications = Instance.new("ScreenGui")
Notifications.Name = "Notifications"
Notifications.ResetOnSpawn = false
Notifications.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Notifications.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
Notifications.IgnoreGuiInset = false
Notifications.DisplayOrder = 100 -- above the windows (FR-011)
Notifications.Enabled = true
Notifications.Parent = playerGui

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
bind(Toast, "BackgroundColor3", "Surface")
Toast.BackgroundTransparency = 0.05
Toast.BorderSizePixel = 0
Toast.Visible = false
Toast.Parent = ToastContainer
roundCorner(Toast, 10)
strokeOf(Toast, "Outline")

-- Coloured accent bar on the left; ToastQueue sets its colour by message type (untagged).
local Bar = Instance.new("Frame")
Bar.Name = "Bar"
Bar.Size = UDim2.new(0, 6, 1, -12)
Bar.Position = UDim2.new(0, 6, 0, 6)
Bar.BackgroundColor3 = Theme.Accent
Bar.BorderSizePixel = 0
Bar.Parent = Toast
roundCorner(Bar, 3)

local Icon = Instance.new("TextLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 32, 0, 32)
Icon.Position = UDim2.new(0, 18, 0.5, 0)
Icon.AnchorPoint = Vector2.new(0, 0.5)
Icon.BackgroundTransparency = 1
Icon.Text = "ℹ️"
Icon.TextSize = 22
Icon.Font = Style.DisplayFont
Icon.Parent = Toast

local MessageLabel = Instance.new("TextLabel")
MessageLabel.Name = "MessageLabel"
MessageLabel.Size = UDim2.new(1, -70, 1, -12)
MessageLabel.Position = UDim2.new(0, 58, 0, 6)
MessageLabel.BackgroundTransparency = 1
MessageLabel.Text = "Notification"
bind(MessageLabel, "TextColor3", "TextPrimary")
MessageLabel.TextSize = 18
MessageLabel.Font = Style.DisplayFont
MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
MessageLabel.TextYAlignment = Enum.TextYAlignment.Center
MessageLabel.TextWrapped = true
MessageLabel.Parent = Toast

-- ── Event banners (feature 003, US4) ───────────────────────────────────────────
local NightBanner = Instance.new("Frame")
NightBanner.Name = "NightBanner"
NightBanner.AnchorPoint = Vector2.new(0.5, 0)
NightBanner.Position = UDim2.new(0.5, 0, 0.16, 0)
NightBanner.Size = UDim2.new(0.8, 0, 0, 60)
NightBanner.BackgroundColor3 = Theme.BannerNight -- fixed night-event colour (not per-palette)
NightBanner.BackgroundTransparency = 0.05
NightBanner.BorderSizePixel = 0
NightBanner.Visible = false
NightBanner.Parent = Notifications

local nbMax = Instance.new("UISizeConstraint")
nbMax.MaxSize = Vector2.new(560, 60)
nbMax.Parent = NightBanner
roundCorner(NightBanner, 10)

local BannerLabel = Instance.new("TextLabel")
BannerLabel.Name = "BannerLabel"
BannerLabel.Size = UDim2.new(1, -24, 1, 0)
BannerLabel.Position = UDim2.new(0, 12, 0, 0)
BannerLabel.BackgroundTransparency = 1
BannerLabel.Text = "🌙 Night falls — spirits awaken"
bind(BannerLabel, "TextColor3", "TextOnHeader") -- light in both palettes (readable on the dark banner)
BannerLabel.TextSize = 24
BannerLabel.Font = Style.DisplayFont
BannerLabel.TextScaled = false
BannerLabel.TextWrapped = true
BannerLabel.Parent = NightBanner

local AnnounceBanner = Instance.new("Frame")
AnnounceBanner.Name = "AnnounceBanner"
AnnounceBanner.AnchorPoint = Vector2.new(0.5, 0)
AnnounceBanner.Position = UDim2.new(0.5, 0, 0.3, 0)
AnnounceBanner.Size = UDim2.new(0.72, 0, 0, 48)
bind(AnnounceBanner, "BackgroundColor3", "Surface")
AnnounceBanner.BackgroundTransparency = 0.05
AnnounceBanner.BorderSizePixel = 0
AnnounceBanner.Visible = false
AnnounceBanner.Parent = Notifications

local abMax = Instance.new("UISizeConstraint")
abMax.MaxSize = Vector2.new(520, 48)
abMax.Parent = AnnounceBanner
roundCorner(AnnounceBanner, 10)
strokeOf(AnnounceBanner, "RarityEpic", 2)

local AnnounceLabel = Instance.new("TextLabel")
AnnounceLabel.Name = "AnnounceLabel"
AnnounceLabel.Size = UDim2.new(1, -24, 1, 0)
AnnounceLabel.Position = UDim2.new(0, 12, 0, 0)
AnnounceLabel.BackgroundTransparency = 1
AnnounceLabel.Text = "✨ A rare spirit has appeared!"
bind(AnnounceLabel, "TextColor3", "TextPrimary")
AnnounceLabel.TextSize = 20
AnnounceLabel.Font = Style.DisplayFont
AnnounceLabel.TextWrapped = true
AnnounceLabel.Parent = AnnounceBanner

-- ── First-session tutorial hint (feature 003, US5) ─────────────────────────────
local TutorialHint = Instance.new("Frame")
TutorialHint.Name = "TutorialHint"
TutorialHint.AnchorPoint = Vector2.new(0.5, 0)
TutorialHint.Position = UDim2.new(0.5, 0, 0.42, 0)
TutorialHint.Size = UDim2.new(0.6, 0, 0, 72)
bind(TutorialHint, "BackgroundColor3", "Surface")
TutorialHint.BackgroundTransparency = 0.05
TutorialHint.BorderSizePixel = 0
TutorialHint.Visible = false
TutorialHint.Parent = Notifications

local thMax = Instance.new("UISizeConstraint")
thMax.MaxSize = Vector2.new(460, 72)
thMax.Parent = TutorialHint
roundCorner(TutorialHint, 10)
strokeOf(TutorialHint, "Accent", 2)

local Arrow = Instance.new("TextLabel")
Arrow.Name = "Arrow"
Arrow.Size = UDim2.new(0, 40, 1, 0)
Arrow.Position = UDim2.new(0, 8, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "👉"
Arrow.TextSize = 28
Arrow.Font = Style.DisplayFont
Arrow.Parent = TutorialHint

local HintLabel = Instance.new("TextLabel")
HintLabel.Name = "HintLabel"
HintLabel.Size = UDim2.new(1, -140, 1, -12)
HintLabel.Position = UDim2.new(0, 54, 0, 6)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "Welcome! Plant a seed on a plot."
bind(HintLabel, "TextColor3", "TextPrimary")
HintLabel.TextSize = 18
HintLabel.Font = Style.DisplayFont
HintLabel.TextXAlignment = Enum.TextXAlignment.Left
HintLabel.TextWrapped = true
HintLabel.Parent = TutorialHint

local SkipButton = Instance.new("TextButton")
SkipButton.Name = "SkipButton"
SkipButton.Size = UDim2.new(0, 76, 0, 44)
SkipButton.Position = UDim2.new(1, -84, 0.5, 0)
SkipButton.AnchorPoint = Vector2.new(0, 0.5)
bind(SkipButton, "BackgroundColor3", "Control")
SkipButton.BorderSizePixel = 0
SkipButton.Text = "Skip"
bind(SkipButton, "TextColor3", "TextPrimary")
SkipButton.TextSize = 18
SkipButton.Font = Style.DisplayFont
SkipButton.AutoButtonColor = true
SkipButton.Parent = TutorialHint
roundCorner(SkipButton, 8)

print("✅ Notifications created successfully!")
