--[[
    CreateShopUI.lua
    Location: StarterGui (as LocalScript)
    
    PURPOSE:
    Programmatically creates the Shop UI including:
    - Header bar with title and close button
    - Left panel for category selection
    - Right panel for item details and purchase
    - Quantity stepper
    - Loading overlay
    
    INSTALLATION:
    1. Place this script in StarterGui as a LocalScript
    2. Run the game once - ShopUI will be created automatically
    3. You can disable this script after creation if desired
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Check if ShopUI already exists
if playerGui:FindFirstChild("ShopUI") then
    print("⚠️ ShopUI already exists, skipping creation")
    return
end

print("🎨 Creating ShopUI...")

-- Theme tokens: offline the generator sets the global UI_THEME; in Studio the
-- module is required directly.
local Theme = UI_THEME or require(game:GetService("ReplicatedStorage"):WaitForChild("UITheme"))

-- Create main ScreenGui
local ShopUI = Instance.new("ScreenGui")
ShopUI.Name = "ShopUI"
ShopUI.ResetOnSpawn = false
ShopUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ShopUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
ShopUI.IgnoreGuiInset = false
ShopUI.Enabled = false -- Hidden by default, opened with 'B' key
ShopUI.Parent = playerGui

-- Full-screen dim backdrop (US3): tapping it closes the window and the Active
-- TextButton keeps the tap from reaching the game world (FR-008). Parented
-- before ShopFrame so it renders behind it.
local Backdrop = Instance.new("TextButton")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.Position = UDim2.new(0, 0, 0, 0)
Backdrop.BackgroundColor3 = Theme.Backdrop
Backdrop.BackgroundTransparency = Theme.BackdropTransparency
Backdrop.BorderSizePixel = 0
Backdrop.AutoButtonColor = false
Backdrop.Text = ""
Backdrop.ZIndex = 0
Backdrop.Parent = ShopUI

--[[
    MAIN SHOP FRAME
    Centered modal window (larger than inventory)
]]
local ShopFrame = Instance.new("Frame")
ShopFrame.Name = "ShopFrame"
ShopFrame.Size = UDim2.new(0, 800, 0, 550)
ShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
ShopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ShopFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
ShopFrame.BorderSizePixel = 0
-- US5 (R8): keep gamepad selection navigation inside the open window.
ShopFrame.SelectionGroup = true
ShopFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
ShopFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
ShopFrame.Parent = ShopUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = ShopFrame

-- Drop shadow
local frameShadow = Instance.new("ImageLabel")
frameShadow.Name = "Shadow"
frameShadow.Size = UDim2.new(1, 30, 1, 30)
frameShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
frameShadow.AnchorPoint = Vector2.new(0.5, 0.5)
frameShadow.BackgroundTransparency = 1
frameShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
frameShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
frameShadow.ImageTransparency = 0.7
frameShadow.ScaleType = Enum.ScaleType.Slice
frameShadow.SliceCenter = Rect.new(8, 8, 8, 8)
frameShadow.ZIndex = -1
frameShadow.Parent = ShopFrame

--[[
    HEADER BAR
]]
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = ShopFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = HeaderBar

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 12)
headerCover.Position = UDim2.new(0, 0, 1, -12)
headerCover.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
headerCover.BorderSizePixel = 0
headerCover.Parent = HeaderBar

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🏪 SHOP"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 24
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 44, 0, 44) -- >= 44x44 (FR-007)
CloseButton.Position = UDim2.new(1, -54, 0.5, 0)
CloseButton.AnchorPoint = Vector2.new(0, 0.5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 24
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = false
CloseButton.Parent = HeaderBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
end)

--[[
    LEFT PANEL
    Category list (Seeds, Tools, Items)
]]
local LeftPanel = Instance.new("ScrollingFrame")
LeftPanel.Name = "LeftPanel"
LeftPanel.Size = UDim2.new(0, 200, 1, -70)
LeftPanel.Position = UDim2.new(0, 15, 0, 60)
LeftPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
LeftPanel.BorderSizePixel = 0
LeftPanel.ScrollBarThickness = 6
LeftPanel.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
LeftPanel.Parent = ShopFrame

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 8)
leftCorner.Parent = LeftPanel

-- List layout for categories
local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 5)
ListLayout.Parent = LeftPanel

local LeftPadding = Instance.new("UIPadding")
LeftPadding.PaddingTop = UDim.new(0, 10)
LeftPadding.PaddingBottom = UDim.new(0, 10)
LeftPadding.PaddingLeft = UDim.new(0, 5)
LeftPadding.PaddingRight = UDim.new(0, 5)
LeftPadding.Parent = LeftPanel

--[[
    RIGHT PANEL
    Item details and purchase interface
]]
local RightPanel = Instance.new("Frame")
RightPanel.Name = "RightPanel"
RightPanel.Size = UDim2.new(1, -235, 1, -70)
RightPanel.Position = UDim2.new(0, 225, 0, 60)
RightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = ShopFrame

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 8)
rightCorner.Parent = RightPanel

local RightPadding = Instance.new("UIPadding")
RightPadding.PaddingTop = UDim.new(0, 20)
RightPadding.PaddingBottom = UDim.new(0, 20)
RightPadding.PaddingLeft = UDim.new(0, 20)
RightPadding.PaddingRight = UDim.new(0, 20)
RightPadding.Parent = RightPanel

-- US2 (FR-006): item detail scrolls when taller than the panel; the quantity
-- stepper and buy button stay pinned in a Footer that never scrolls.
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 120)
Footer.Position = UDim2.new(0, 0, 1, -120)
Footer.BackgroundTransparency = 1
Footer.Parent = RightPanel

local Details = Instance.new("ScrollingFrame")
Details.Name = "Details"
Details.Size = UDim2.new(1, 0, 1, -130)
Details.Position = UDim2.new(0, 0, 0, 0)
Details.BackgroundTransparency = 1
Details.BorderSizePixel = 0
Details.ScrollBarThickness = 6
Details.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
Details.CanvasSize = UDim2.new(0, 0, 0, 0)
Details.AutomaticCanvasSize = Enum.AutomaticSize.Y
Details.Parent = RightPanel

-- Item icon display
local ItemIconDisplay = Instance.new("ImageLabel")
ItemIconDisplay.Name = "ItemIconDisplay"
ItemIconDisplay.Size = UDim2.new(0, 120, 0, 120)
ItemIconDisplay.Position = UDim2.new(0.5, 0, 0, 0)
ItemIconDisplay.AnchorPoint = Vector2.new(0.5, 0)
ItemIconDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ItemIconDisplay.BorderSizePixel = 0
ItemIconDisplay.Image = "rbxassetid://0"
ItemIconDisplay.ScaleType = Enum.ScaleType.Fit
ItemIconDisplay.Parent = Details

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 12)
iconCorner.Parent = ItemIconDisplay

-- Icon text (emoji fallback)
local IconText = Instance.new("TextLabel")
IconText.Name = "IconText"
IconText.Size = UDim2.new(1, 0, 1, 0)
IconText.BackgroundTransparency = 1
IconText.Text = "🌱"
IconText.TextColor3 = Color3.fromRGB(150, 150, 150)
IconText.TextSize = 60
IconText.Font = Enum.Font.GothamBold
IconText.Parent = ItemIconDisplay

-- Item name
local ItemNameLabel = Instance.new("TextLabel")
ItemNameLabel.Name = "ItemNameLabel"
ItemNameLabel.Size = UDim2.new(1, 0, 0, 35)
ItemNameLabel.Position = UDim2.new(0, 0, 0, 135)
ItemNameLabel.BackgroundTransparency = 1
ItemNameLabel.Text = "SELECT AN ITEM"
ItemNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemNameLabel.TextSize = 22
ItemNameLabel.Font = Enum.Font.GothamBold
ItemNameLabel.TextWrapped = true
ItemNameLabel.Parent = Details

-- Item description
local ItemDescriptionLabel = Instance.new("TextLabel")
ItemDescriptionLabel.Name = "ItemDescriptionLabel"
ItemDescriptionLabel.Size = UDim2.new(1, 0, 0, 60)
ItemDescriptionLabel.Position = UDim2.new(0, 0, 0, 175)
ItemDescriptionLabel.BackgroundTransparency = 1
ItemDescriptionLabel.Text = "Choose a category to browse items"
ItemDescriptionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ItemDescriptionLabel.TextSize = 18 -- body >= 18 (FR-005)
ItemDescriptionLabel.Font = Enum.Font.Gotham
ItemDescriptionLabel.TextWrapped = true
ItemDescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
ItemDescriptionLabel.Parent = Details

-- Separator line
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, 0, 0, 2)
Separator.Position = UDim2.new(0, 0, 0, 250)
Separator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
Separator.BorderSizePixel = 0
Separator.Parent = Details

-- Price label
local PriceLabel = Instance.new("TextLabel")
PriceLabel.Name = "PriceLabel"
PriceLabel.Size = UDim2.new(1, 0, 0, 30)
PriceLabel.Position = UDim2.new(0, 0, 0, 265)
PriceLabel.BackgroundTransparency = 1
PriceLabel.Text = "💰 Price: 0 coins"
PriceLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
PriceLabel.TextSize = 20
PriceLabel.Font = Enum.Font.GothamBold
PriceLabel.TextXAlignment = Enum.TextXAlignment.Left
PriceLabel.Parent = Details

--[[
    QUANTITY STEPPER
]]
local QuantityStepper = Instance.new("Frame")
QuantityStepper.Name = "QuantityStepper"
QuantityStepper.Size = UDim2.new(0, 180, 0, 50)
QuantityStepper.Position = UDim2.new(0, 0, 0, 0)
QuantityStepper.BackgroundTransparency = 1
QuantityStepper.Parent = Footer

-- Minus button
local MinusBtn = Instance.new("TextButton")
MinusBtn.Name = "MinusBtn"
MinusBtn.Size = UDim2.new(0, 50, 0, 50)
MinusBtn.Position = UDim2.new(0, 0, 0, 0)
MinusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MinusBtn.BorderSizePixel = 0
MinusBtn.Text = "−"
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.TextSize = 28
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.AutoButtonColor = false
MinusBtn.Parent = QuantityStepper

local minusCorner = Instance.new("UICorner")
minusCorner.CornerRadius = UDim.new(0, 8)
minusCorner.Parent = MinusBtn

MinusBtn.MouseEnter:Connect(function()
    MinusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
end)

MinusBtn.MouseLeave:Connect(function()
    MinusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

-- Quantity display
local QuantityDisplay = Instance.new("TextLabel")
QuantityDisplay.Name = "QuantityDisplay"
QuantityDisplay.Size = UDim2.new(0, 70, 0, 50)
QuantityDisplay.Position = UDim2.new(0, 55, 0, 0)
QuantityDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
QuantityDisplay.BorderSizePixel = 0
QuantityDisplay.Text = "1"
QuantityDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
QuantityDisplay.TextSize = 24
QuantityDisplay.Font = Enum.Font.GothamBold
QuantityDisplay.Parent = QuantityStepper

local qtyCorner = Instance.new("UICorner")
qtyCorner.CornerRadius = UDim.new(0, 8)
qtyCorner.Parent = QuantityDisplay

-- Plus button
local PlusBtn = Instance.new("TextButton")
PlusBtn.Name = "PlusBtn"
PlusBtn.Size = UDim2.new(0, 50, 0, 50)
PlusBtn.Position = UDim2.new(0, 130, 0, 0)
PlusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
PlusBtn.BorderSizePixel = 0
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.TextSize = 28
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.AutoButtonColor = false
PlusBtn.Parent = QuantityStepper

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 8)
plusCorner.Parent = PlusBtn

PlusBtn.MouseEnter:Connect(function()
    PlusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
end)

PlusBtn.MouseLeave:Connect(function()
    PlusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

-- Buy button
local BuyButton = Instance.new("TextButton")
BuyButton.Name = "BuyButton"
BuyButton.Size = UDim2.new(1, 0, 0, 60)
BuyButton.Position = UDim2.new(0, 0, 1, -60)
BuyButton.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
BuyButton.BorderSizePixel = 0
BuyButton.Text = "BUY"
BuyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyButton.TextSize = 24
BuyButton.Font = Enum.Font.GothamBold
BuyButton.AutoButtonColor = false
BuyButton.Parent = Footer

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 10)
buyCorner.Parent = BuyButton

BuyButton.MouseEnter:Connect(function()
    BuyButton.BackgroundColor3 = Color3.fromRGB(90, 220, 140)
end)

BuyButton.MouseLeave:Connect(function()
    BuyButton.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
end)

--[[
    LOADING OVERLAY
    Shown during network requests
]]
local LoadingOverlay = Instance.new("Frame")
LoadingOverlay.Name = "LoadingOverlay"
-- Cover only the body below the 50px header so the CloseButton stays usable
-- while loading (US2, contracts/gui-tree.md).
LoadingOverlay.Size = UDim2.new(1, 0, 1, -50)
LoadingOverlay.Position = UDim2.new(0, 0, 0, 50)
LoadingOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LoadingOverlay.BackgroundTransparency = 0.7
LoadingOverlay.BorderSizePixel = 0
LoadingOverlay.Visible = false
LoadingOverlay.ZIndex = 100
LoadingOverlay.Parent = ShopFrame

local loadingCorner = Instance.new("UICorner")
loadingCorner.CornerRadius = UDim.new(0, 12)
loadingCorner.Parent = LoadingOverlay

-- Loading spinner container
local SpinnerContainer = Instance.new("Frame")
SpinnerContainer.Size = UDim2.new(0, 100, 0, 100)
SpinnerContainer.Position = UDim2.new(0.5, 0, 0.5, -30)
SpinnerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
SpinnerContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SpinnerContainer.BorderSizePixel = 0
SpinnerContainer.Parent = LoadingOverlay

local spinnerCorner = Instance.new("UICorner")
spinnerCorner.CornerRadius = UDim.new(0, 12)
spinnerCorner.Parent = SpinnerContainer

-- Spinner (rotating circle)
local Spinner = Instance.new("ImageLabel")
Spinner.Name = "Spinner"
Spinner.Size = UDim2.new(0, 60, 0, 60)
Spinner.Position = UDim2.new(0.5, 0, 0.5, 0)
Spinner.AnchorPoint = Vector2.new(0.5, 0.5)
Spinner.BackgroundTransparency = 1
Spinner.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
Spinner.ImageColor3 = Color3.fromRGB(80, 200, 120)
Spinner.Parent = SpinnerContainer

-- Rotate spinner continuously
local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    if LoadingOverlay.Visible then
        Spinner.Rotation = Spinner.Rotation + (dt * 180)
    end
end)

-- Loading text
local LoadingText = Instance.new("TextLabel")
LoadingText.Name = "LoadingText"
LoadingText.Size = UDim2.new(1, 0, 0, 30)
LoadingText.Position = UDim2.new(0.5, 0, 0.5, 60)
LoadingText.AnchorPoint = Vector2.new(0.5, 0)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Processing..."
LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingText.TextSize = 18
LoadingText.Font = Enum.Font.GothamBold
LoadingText.Parent = LoadingOverlay

print("✅ ShopUI created successfully!")
print("   Components:")
print("   - ShopFrame (main window)")
print("   - HeaderBar (title, close button)")
print("   - LeftPanel (category list)")
print("   - RightPanel (item details)")
print("   - QuantityStepper (-, qty, +)")
print("   - BuyButton")
print("   - LoadingOverlay (spinner)")
print("")
print("🎮 ShopUI is ready for ShopController!")
print("   Press 'B' to toggle shop")
