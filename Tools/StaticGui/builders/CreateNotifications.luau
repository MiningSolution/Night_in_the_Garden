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

-- ── Event banners (feature 003, US4) ───────────────────────────────────────────
-- Brief, non-interactive banners shown by UIController: NightBanner on the Day→Night
-- edge, AnnounceBanner for a server-wide rare-spirit sighting. Both hidden by default.

local NightBanner = Instance.new("Frame")
NightBanner.Name = "NightBanner"
NightBanner.AnchorPoint = Vector2.new(0.5, 0)
NightBanner.Position = UDim2.new(0.5, 0, 0.16, 0)
NightBanner.Size = UDim2.new(0.8, 0, 0, 60)
NightBanner.BackgroundColor3 = Theme.BannerNight
NightBanner.BackgroundTransparency = 0.05
NightBanner.BorderSizePixel = 0
NightBanner.Visible = false
NightBanner.Parent = Notifications

local nbMax = Instance.new("UISizeConstraint")
nbMax.MaxSize = Vector2.new(560, 60)
nbMax.Parent = NightBanner

local nbCorner = Instance.new("UICorner")
nbCorner.CornerRadius = UDim.new(0, 10)
nbCorner.Parent = NightBanner

local BannerLabel = Instance.new("TextLabel")
BannerLabel.Name = "BannerLabel"
BannerLabel.Size = UDim2.new(1, -24, 1, 0)
BannerLabel.Position = UDim2.new(0, 12, 0, 0)
BannerLabel.BackgroundTransparency = 1
BannerLabel.Text = "🌙 Night falls — spirits awaken"
BannerLabel.TextColor3 = Theme.TextPrimary
BannerLabel.TextSize = 24
BannerLabel.Font = Enum.Font.GothamBold
BannerLabel.TextScaled = false
BannerLabel.TextWrapped = true
BannerLabel.Parent = NightBanner

local AnnounceBanner = Instance.new("Frame")
AnnounceBanner.Name = "AnnounceBanner"
AnnounceBanner.AnchorPoint = Vector2.new(0.5, 0)
AnnounceBanner.Position = UDim2.new(0.5, 0, 0.3, 0)
AnnounceBanner.Size = UDim2.new(0.72, 0, 0, 48)
AnnounceBanner.BackgroundColor3 = Theme.Surface
AnnounceBanner.BackgroundTransparency = 0.05
AnnounceBanner.BorderSizePixel = 0
AnnounceBanner.Visible = false
AnnounceBanner.Parent = Notifications

local abMax = Instance.new("UISizeConstraint")
abMax.MaxSize = Vector2.new(520, 48)
abMax.Parent = AnnounceBanner

local abCorner = Instance.new("UICorner")
abCorner.CornerRadius = UDim.new(0, 10)
abCorner.Parent = AnnounceBanner

-- rarity accent stroke (reuses the Epic rarity token)
local abStroke = Instance.new("UIStroke")
abStroke.Color = Theme.RarityEpic
abStroke.Thickness = 2
abStroke.Parent = AnnounceBanner

local AnnounceLabel = Instance.new("TextLabel")
AnnounceLabel.Name = "AnnounceLabel"
AnnounceLabel.Size = UDim2.new(1, -24, 1, 0)
AnnounceLabel.Position = UDim2.new(0, 12, 0, 0)
AnnounceLabel.BackgroundTransparency = 1
AnnounceLabel.Text = "✨ A rare spirit has appeared!"
AnnounceLabel.TextColor3 = Theme.TextPrimary
AnnounceLabel.TextSize = 20
AnnounceLabel.Font = Enum.Font.GothamBold
AnnounceLabel.TextWrapped = true
AnnounceLabel.Parent = AnnounceBanner

-- ── First-session tutorial hint (feature 003, US5) ─────────────────────────────
-- A small, non-blocking hint panel: an arrow glyph, a step hint, and a Skip button.
-- TutorialController shows/advances it; it never covers the thumbstick, jump button,
-- menu column or hotbar, and only SkipButton is interactive.
local TutorialHint = Instance.new("Frame")
TutorialHint.Name = "TutorialHint"
TutorialHint.AnchorPoint = Vector2.new(0.5, 0)
TutorialHint.Position = UDim2.new(0.5, 0, 0.42, 0)
TutorialHint.Size = UDim2.new(0.6, 0, 0, 72)
TutorialHint.BackgroundColor3 = Theme.Surface
TutorialHint.BackgroundTransparency = 0.05
TutorialHint.BorderSizePixel = 0
TutorialHint.Visible = false
TutorialHint.Parent = Notifications

local thMax = Instance.new("UISizeConstraint")
thMax.MaxSize = Vector2.new(460, 72)
thMax.Parent = TutorialHint

local thCorner = Instance.new("UICorner")
thCorner.CornerRadius = UDim.new(0, 10)
thCorner.Parent = TutorialHint

local thStroke = Instance.new("UIStroke")
thStroke.Color = Theme.Accent
thStroke.Thickness = 2
thStroke.Parent = TutorialHint

local Arrow = Instance.new("TextLabel")
Arrow.Name = "Arrow"
Arrow.Size = UDim2.new(0, 40, 1, 0)
Arrow.Position = UDim2.new(0, 8, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "👉"
Arrow.TextSize = 28
Arrow.Font = Enum.Font.GothamBold
Arrow.Parent = TutorialHint

local HintLabel = Instance.new("TextLabel")
HintLabel.Name = "HintLabel"
HintLabel.Size = UDim2.new(1, -140, 1, -12)
HintLabel.Position = UDim2.new(0, 54, 0, 6)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "Welcome! Plant a seed on a plot."
HintLabel.TextColor3 = Theme.TextPrimary
HintLabel.TextSize = 18
HintLabel.Font = Enum.Font.GothamMedium
HintLabel.TextXAlignment = Enum.TextXAlignment.Left
HintLabel.TextWrapped = true
HintLabel.Parent = TutorialHint

local SkipButton = Instance.new("TextButton")
SkipButton.Name = "SkipButton"
SkipButton.Size = UDim2.new(0, 76, 0, 44)
SkipButton.Position = UDim2.new(1, -84, 0.5, 0)
SkipButton.AnchorPoint = Vector2.new(0, 0.5)
SkipButton.BackgroundColor3 = Theme.Control
SkipButton.BorderSizePixel = 0
SkipButton.Text = "Skip"
SkipButton.TextColor3 = Theme.TextPrimary
SkipButton.TextSize = 18
SkipButton.Font = Enum.Font.GothamBold
SkipButton.AutoButtonColor = true
SkipButton.Parent = TutorialHint

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 8)
skipCorner.Parent = SkipButton

print("✅ Notifications created successfully!")
