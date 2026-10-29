--[[
    CreateSpiritJournalUI.lua
    Location: StarterGui (generated into StarterGui/SpiritJournalUI.model.json) — feature 006, US3

    Builds the SpiritJournalUI ScreenGui: a single-window modal listing EVERY known
    spirit type (from ReplicatedStorage/SpiritData). SpiritJournalController clones
    EntryTemplate per catalog entry and fills it from the player's SpiritCollection
    (discovered = details; undiscovered = locked "???"). Cosy-garden look, themed via
    bind/strokeOf + Theme_<Prop> so it works in both palettes (constitution V) and
    repaints on the day/night switch. Static GUI, cloned template (constitution III).
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SpiritJournalUI") then
    print("⚠️ SpiritJournalUI already exists, skipping creation")
    return
end

print("🎨 Creating SpiritJournalUI...")

local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))
local Style = Theme.Style

local function bind(obj, prop, token)
    obj[prop] = Theme[token]
    obj:SetAttribute("Theme_" .. prop, token)
end
local function strokeOf(parent, token, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or Style.OutlineThickness
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = Theme[token]
    s:SetAttribute("Theme_Color", token)
    s.Parent = parent
    return s
end
local function gradientOf(parent, topToken, botToken)
    parent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new(Theme[topToken], Theme[botToken])
    g:SetAttribute("Theme_GradientTop", topToken)
    g:SetAttribute("Theme_GradientBottom", botToken)
    g.Parent = parent
    return g
end
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or Style.CornerRadius)
    c.Parent = parent
    return c
end
local function label(parent, name, text, size, token, font)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.BackgroundTransparency = 1
    l.Text = text
    bind(l, "TextColor3", token)
    l.TextSize = size
    l.Font = font or Style.BodyFont
    l.Parent = parent
    return l
end

local SpiritJournalUI = Instance.new("ScreenGui")
SpiritJournalUI.Name = "SpiritJournalUI"
SpiritJournalUI.ResetOnSpawn = false
SpiritJournalUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SpiritJournalUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
SpiritJournalUI.IgnoreGuiInset = false
SpiritJournalUI.Enabled = false
SpiritJournalUI.Parent = playerGui

local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
bind(Backdrop, "BackgroundColor3", "Backdrop")
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = SpiritJournalUI

local JournalFrame = Instance.new("Frame")
JournalFrame.Name = "JournalFrame"
JournalFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
JournalFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
JournalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bind(JournalFrame, "BackgroundColor3", "Surface")
JournalFrame.BorderSizePixel = 0
JournalFrame.SelectionGroup = true
JournalFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
JournalFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
JournalFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
JournalFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
JournalFrame.Parent = SpiritJournalUI
corner(JournalFrame)
strokeOf(JournalFrame, "OutlineDeep", Style.WindowOutlineThickness)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(620, 520)
sizeConstraint.MinSize = Vector2.new(320, 280)
sizeConstraint.Parent = JournalFrame

--[[ HEADER ]]
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = JournalFrame
gradientOf(HeaderBar, "HeaderTop", "HeaderBottom")
corner(HeaderBar)

local TitleLabel = label(HeaderBar, "TitleLabel", "🔮 SPIRIT JOURNAL", 24, "TextOnHeader", Style.DisplayFont)
TitleLabel.Size = UDim2.new(1, -220, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Collection progress ("N / M discovered") — filled by the controller.
local ProgressLabel = label(HeaderBar, "ProgressLabel", "0 / 0 discovered", 18, "TextOnHeader", Style.DisplayFont)
ProgressLabel.Size = UDim2.new(0, 150, 1, 0)
ProgressLabel.Position = UDim2.new(1, -64, 0, 0)
ProgressLabel.AnchorPoint = Vector2.new(1, 0)
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Right

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 44, 0, 44)
CloseButton.Position = UDim2.new(1, -54, 0.5, 0)
CloseButton.AnchorPoint = Vector2.new(0, 0.5)
bind(CloseButton, "BackgroundColor3", "Danger")
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
bind(CloseButton, "TextColor3", "TextOnAccent")
CloseButton.TextSize = 24
CloseButton.Font = Style.DisplayFont
CloseButton.AutoButtonColor = false
CloseButton.Parent = HeaderBar
corner(CloseButton)

--[[ ENTRY GRID ]]
local EntryScroll = Instance.new("ScrollingFrame")
EntryScroll.Name = "EntryScroll"
EntryScroll.Size = UDim2.new(1, -40, 1, -70)
EntryScroll.Position = UDim2.new(0, 20, 0, 60)
bind(EntryScroll, "BackgroundColor3", "SurfaceRaised")
EntryScroll.BackgroundTransparency = 0.5
EntryScroll.BorderSizePixel = 0
EntryScroll.ScrollBarThickness = 8
bind(EntryScroll, "ScrollBarImageColor3", "Control")
EntryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
EntryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
EntryScroll.Parent = JournalFrame
corner(EntryScroll, 8)

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0, 120, 0, 140)
GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GridLayout.Parent = EntryScroll

local GridPadding = Instance.new("UIPadding")
GridPadding.PaddingTop = UDim.new(0, 10)
GridPadding.PaddingBottom = UDim.new(0, 10)
GridPadding.PaddingLeft = UDim.new(0, 10)
GridPadding.PaddingRight = UDim.new(0, 10)
GridPadding.Parent = EntryScroll

--[[ ENTRY TEMPLATE (hidden; the controller clones + fills it per spirit type) ]]
local Entry = Instance.new("Frame")
Entry.Name = "EntryTemplate"
Entry.Size = UDim2.new(0, 120, 0, 140)
bind(Entry, "BackgroundColor3", "SurfaceRaised")
Entry.BorderSizePixel = 0
Entry.Visible = false
Entry.Parent = EntryScroll
corner(Entry)
strokeOf(Entry, "Outline")

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 52, 0, 52)
Icon.Position = UDim2.new(0.5, 0, 0, 8)
Icon.AnchorPoint = Vector2.new(0.5, 0)
Icon.BackgroundTransparency = 1
Icon.Image = ""
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = Entry
local Fallback = label(Icon, "FallbackLetter", "?", 34, "TextMuted", Style.DisplayFont)
Fallback.Size = UDim2.new(1, 0, 1, 0)

local NameLabel = label(Entry, "NameLabel", "???", 16, "TextPrimary", Style.DisplayFont)
NameLabel.Size = UDim2.new(1, -8, 0, 20)
NameLabel.Position = UDim2.new(0, 4, 0, 62)
NameLabel.TextTruncate = Enum.TextTruncate.AtEnd

local CountLabel = label(Entry, "CountLabel", "", 14, "TextMuted", Style.BodyFont)
CountLabel.Size = UDim2.new(1, -8, 0, 18)
CountLabel.Position = UDim2.new(0, 4, 0, 82)

local FirstCaughtLabel = label(Entry, "FirstCaughtLabel", "", 12, "TextMuted", Style.BodyFont)
FirstCaughtLabel.Size = UDim2.new(1, -8, 0, 16)
FirstCaughtLabel.Position = UDim2.new(0, 4, 0, 100)

-- Rarity badge (same pattern as the Backpack card): tier colour via Theme_ token + tier text.
local badge = Instance.new("Frame")
badge.Name = "RarityBadge"
badge.Size = UDim2.new(0, 108, 0, 20)
bind(badge, "BackgroundColor3", "RarityCommon")
badge.BorderSizePixel = 0
badge.Position = UDim2.new(0.5, 0, 1, -6)
badge.AnchorPoint = Vector2.new(0.5, 1)
badge.Parent = Entry
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = badge
strokeOf(badge, "OutlineDeep", 2)
local badgeText = label(badge, "BadgeText", "COMMON", 12, "TextOnAccent", Style.DisplayFont)
badgeText.Size = UDim2.new(1, 0, 1, 0)

--[[ EMPTY STATE (no spirit types at all — defensive) ]]
local EmptyState = label(JournalFrame, "EmptyState", "No spirits known yet.", 18, "TextMuted", Style.BodyFont)
EmptyState.Size = UDim2.new(1, -40, 0, 40)
EmptyState.Position = UDim2.new(0, 20, 0, 70)
EmptyState.TextWrapped = true
EmptyState.Visible = false

print("✅ SpiritJournalUI created successfully!")
