--[[
    CreateInventoryUI.lua
    Location: StarterGui (as LocalScript)
    
    PURPOSE:
    Programmatically creates the Inventory UI including:
    - Header bar with title and close button
    - Tab system (Seeds / Items)
    - Scrolling item grid
    - Tooltip for item details
    
    INSTALLATION:
    1. Place this script in StarterGui as a LocalScript
    2. Run the game once - InventoryUI will be created automatically
    3. You can disable this script after creation if desired
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Check if InventoryUI already exists
if playerGui:FindFirstChild("InventoryUI") then
    print("⚠️ InventoryUI already exists, skipping creation")
    return
end

print("🎨 Creating InventoryUI...")

-- Create main ScreenGui
local InventoryUI = Instance.new("ScreenGui")
InventoryUI.Name = "InventoryUI"
InventoryUI.ResetOnSpawn = false
InventoryUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
InventoryUI.Enabled = false -- Hidden by default, opened with 'I' key
InventoryUI.Parent = playerGui

--[[
    MAIN INVENTORY FRAME
    Centered modal window
]]
local InventoryFrame = Instance.new("Frame")
InventoryFrame.Name = "InventoryFrame"
InventoryFrame.Size = UDim2.new(0, 600, 0, 500)
InventoryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
InventoryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
InventoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
InventoryFrame.BorderSizePixel = 0
InventoryFrame.Parent = InventoryUI

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = InventoryFrame

-- Drop shadow effect
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
frameShadow.Parent = InventoryFrame

--[[
    HEADER BAR
    Title and close button
]]
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = InventoryFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = HeaderBar

-- Cover bottom corners
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
TitleLabel.Text = "📦 INVENTORY"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 24
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -50, 0.5, 0)
CloseButton.AnchorPoint = Vector2.new(0, 0.5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 24
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = false
CloseButton.Parent = HeaderBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = CloseButton

-- Close button hover effect
CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
end)

--[[
    TAB CONTAINER
    Seeds and Items tabs
]]
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -40, 0, 45)
TabContainer.Position = UDim2.new(0, 20, 0, 60)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = InventoryFrame

-- Seeds tab
local SeedsTab = Instance.new("TextButton")
SeedsTab.Name = "SeedsTab"
SeedsTab.Size = UDim2.new(0, 140, 1, 0)
SeedsTab.Position = UDim2.new(0, 0, 0, 0)
SeedsTab.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
SeedsTab.BorderSizePixel = 0
SeedsTab.Text = "🌱 Seeds"
SeedsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
SeedsTab.TextSize = 18
SeedsTab.Font = Enum.Font.GothamBold
SeedsTab.AutoButtonColor = false
SeedsTab.Parent = TabContainer

local seedsCorner = Instance.new("UICorner")
seedsCorner.CornerRadius = UDim.new(0, 8)
seedsCorner.Parent = SeedsTab

-- Items tab
local ItemsTab = Instance.new("TextButton")
ItemsTab.Name = "ItemsTab"
ItemsTab.Size = UDim2.new(0, 140, 1, 0)
ItemsTab.Position = UDim2.new(0, 150, 0, 0)
ItemsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ItemsTab.BorderSizePixel = 0
ItemsTab.Text = "📦 Items"
ItemsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
ItemsTab.TextSize = 18
ItemsTab.Font = Enum.Font.GothamBold
ItemsTab.AutoButtonColor = false
ItemsTab.Parent = TabContainer

local itemsCorner = Instance.new("UICorner")
itemsCorner.CornerRadius = UDim.new(0, 8)
itemsCorner.Parent = ItemsTab

-- Tab switching logic
SeedsTab.MouseButton1Click:Connect(function()
    SeedsTab.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    SeedsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    ItemsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ItemsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

ItemsTab.MouseButton1Click:Connect(function()
    ItemsTab.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    ItemsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    SeedsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    SeedsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

--[[
    ITEM GRID
    Scrolling frame with grid layout
]]
local ItemGrid = Instance.new("ScrollingFrame")
ItemGrid.Name = "ItemGrid"
ItemGrid.Size = UDim2.new(1, -40, 1, -125)
ItemGrid.Position = UDim2.new(0, 20, 0, 115)
ItemGrid.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ItemGrid.BorderSizePixel = 0
ItemGrid.ScrollBarThickness = 8
ItemGrid.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
ItemGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ItemGrid.Parent = InventoryFrame

local gridCorner = Instance.new("UICorner")
gridCorner.CornerRadius = UDim.new(0, 8)
gridCorner.Parent = ItemGrid

-- Grid layout
local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0, 100, 0, 100)
GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
GridLayout.SortOrder = Enum.SortOrder.Name
GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GridLayout.Parent = ItemGrid

-- Padding for grid
local GridPadding = Instance.new("UIPadding")
GridPadding.PaddingTop = UDim.new(0, 10)
GridPadding.PaddingBottom = UDim.new(0, 10)
GridPadding.PaddingLeft = UDim.new(0, 10)
GridPadding.PaddingRight = UDim.new(0, 10)
GridPadding.Parent = ItemGrid

--[[
    TOOLTIP FRAME
    Shows item details on hover
]]
local TooltipFrame = Instance.new("Frame")
TooltipFrame.Name = "TooltipFrame"
TooltipFrame.Size = UDim2.new(0, 250, 0, 120)
TooltipFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
TooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
TooltipFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TooltipFrame.BorderSizePixel = 0
TooltipFrame.Visible = false
TooltipFrame.ZIndex = 10
TooltipFrame.Parent = InventoryUI

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 8)
tooltipCorner.Parent = TooltipFrame

-- Tooltip shadow
local tooltipShadow = Instance.new("ImageLabel")
tooltipShadow.Name = "Shadow"
tooltipShadow.Size = UDim2.new(1, 20, 1, 20)
tooltipShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
tooltipShadow.AnchorPoint = Vector2.new(0.5, 0.5)
tooltipShadow.BackgroundTransparency = 1
tooltipShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
tooltipShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
tooltipShadow.ImageTransparency = 0.6
tooltipShadow.ScaleType = Enum.ScaleType.Slice
tooltipShadow.SliceCenter = Rect.new(8, 8, 8, 8)
tooltipShadow.ZIndex = 9
tooltipShadow.Parent = TooltipFrame

-- Tooltip padding
local TooltipPadding = Instance.new("UIPadding")
TooltipPadding.PaddingTop = UDim.new(0, 10)
TooltipPadding.PaddingBottom = UDim.new(0, 10)
TooltipPadding.PaddingLeft = UDim.new(0, 12)
TooltipPadding.PaddingRight = UDim.new(0, 12)
TooltipPadding.Parent = TooltipFrame

-- Tooltip title
local TooltipTitle = Instance.new("TextLabel")
TooltipTitle.Name = "TooltipTitle"
TooltipTitle.Size = UDim2.new(1, 0, 0, 25)
TooltipTitle.BackgroundTransparency = 1
TooltipTitle.Text = "Item Name"
TooltipTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TooltipTitle.TextSize = 18
TooltipTitle.Font = Enum.Font.GothamBold
TooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
TooltipTitle.TextYAlignment = Enum.TextYAlignment.Top
TooltipTitle.Parent = TooltipFrame

-- Tooltip description
local TooltipDescription = Instance.new("TextLabel")
TooltipDescription.Name = "TooltipDescription"
TooltipDescription.Size = UDim2.new(1, 0, 0, 40)
TooltipDescription.Position = UDim2.new(0, 0, 0, 30)
TooltipDescription.BackgroundTransparency = 1
TooltipDescription.Text = "Item description goes here"
TooltipDescription.TextColor3 = Color3.fromRGB(180, 180, 180)
TooltipDescription.TextSize = 14
TooltipDescription.Font = Enum.Font.Gotham
TooltipDescription.TextXAlignment = Enum.TextXAlignment.Left
TooltipDescription.TextYAlignment = Enum.TextYAlignment.Top
TooltipDescription.TextWrapped = true
TooltipDescription.Parent = TooltipFrame

-- Separator line
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, 0, 0, 1)
Separator.Position = UDim2.new(0, 0, 0, 75)
Separator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
Separator.BorderSizePixel = 0
Separator.Parent = TooltipFrame

-- Tooltip stats
local TooltipStats = Instance.new("TextLabel")
TooltipStats.Name = "TooltipStats"
TooltipStats.Size = UDim2.new(1, 0, 1, -80)
TooltipStats.Position = UDim2.new(0, 0, 0, 80)
TooltipStats.BackgroundTransparency = 1
TooltipStats.Text = "Quantity: 10\n💰 Sell Value: 15 coins\n🌱 Type: Seed"
TooltipStats.TextColor3 = Color3.fromRGB(200, 200, 200)
TooltipStats.TextSize = 13
TooltipStats.Font = Enum.Font.Gotham
TooltipStats.TextXAlignment = Enum.TextXAlignment.Left
TooltipStats.TextYAlignment = Enum.TextYAlignment.Top
TooltipStats.Parent = TooltipFrame

print("✅ InventoryUI created successfully!")
print("   Components:")
print("   - InventoryFrame (main window)")
print("   - HeaderBar (title, close button)")
print("   - TabContainer (Seeds, Items tabs)")
print("   - ItemGrid (scrolling with grid layout)")
print("   - TooltipFrame (item details)")
print("")
print("🎮 InventoryUI is ready for InventoryController!")
print("   Press 'I' to toggle inventory")
