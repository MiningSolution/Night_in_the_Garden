--[[
    PlotInteraction.lua
    Location: Workspace / [PlotModel] / (attach to PrimaryPart or specific part)
    
    PURPOSE:
    Handles player interaction with garden plots including:
    - Click detection via ClickDetector
    - Hover effects (highlight on mouse enter/leave)
    - Integration with HotbarController
    - Tool usage events to server
    - Visual feedback
    
    INSTALLATION:
    1. Create plot models in Workspace
    2. Set PrimaryPart for each plot model
    3. Attach this script to the PrimaryPart (or main part)
    4. Duplicate for each plot
    
    REQUIREMENTS:
    - Plot must be a Model
    - Plot should have identifiable name or PlotMarker
    - InteractWithPlot RemoteEvent in ReplicatedStorage
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get references
local plot = script.Parent.Parent -- The Plot Model
local interactPart = script.Parent -- The part this script is attached to (usually PrimaryPart)

-- Validate setup
if not plot:IsA("Model") then
    warn("⚠️ PlotInteraction: Parent is not a Model! Expected structure: Model/Part/Script")
    return
end

print("🌱 PlotInteraction initializing for:", plot.Name)

-- Get RemoteEvent
local InteractWithPlot = ReplicatedStorage:WaitForChild("InteractWithPlot", 30)

if not InteractWithPlot then
    warn("⚠️ PlotInteraction: InteractWithPlot RemoteEvent not found!")
    return
end

-- Create or get ClickDetector
local clickDetector = interactPart:FindFirstChildOfClass("ClickDetector")

if not clickDetector then
    clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = Constants.PLOT.CLIENT_CLICK_DISTANCE
    clickDetector.Parent = interactPart
    print("✅ Created ClickDetector for", plot.Name)
else
    print("✅ Using existing ClickDetector for", plot.Name)
end

-- Store original color and transparency for hover effects
local originalColor = interactPart.Color
local originalTransparency = interactPart.Transparency
local originalMaterial = interactPart.Material

-- Create highlight effect (optional - for better visibility)
local highlight = Instance.new("Highlight")
highlight.Name = "PlotHighlight"
highlight.Adornee = plot
highlight.FillColor = Color3.fromRGB(80, 200, 120)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 1 -- Hidden by default
highlight.OutlineTransparency = 1
highlight.Enabled = false
highlight.Parent = plot

-- P2-4: Use constant from Constants
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Plot state (can be extended)
local plotState = {
    isHovered = false,
    lastInteraction = 0,
    cooldown = Constants.PLOT.CLIENT_COOLDOWN
}

--[[
    Show hover effect
]]
local function ShowHoverEffect()
    if plotState.isHovered then return end
    plotState.isHovered = true
    
    -- Enable highlight
    highlight.Enabled = true
    
    -- Animate highlight in
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(highlight, tweenInfo, {
        FillTransparency = 0.7,
        OutlineTransparency = 0.3
    }):Play()
    
    -- Optional: Brighten the part slightly
    local colorTween = TweenService:Create(interactPart, tweenInfo, {
        Color = Color3.fromRGB(
            math.min(255, originalColor.R * 255 + 20),
            math.min(255, originalColor.G * 255 + 20),
            math.min(255, originalColor.B * 255 + 20)
        )
    })
    colorTween:Play()
end

--[[
    Hide hover effect
]]
local function HideHoverEffect()
    if not plotState.isHovered then return end
    plotState.isHovered = false
    
    -- Animate highlight out
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween = TweenService:Create(highlight, tweenInfo, {
        FillTransparency = 1,
        OutlineTransparency = 1
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        highlight.Enabled = false
    end)
    
    -- Reset part color
    local colorTween = TweenService:Create(interactPart, tweenInfo, {
        Color = originalColor
    })
    colorTween:Play()
end

--[[
    Handle click interaction
]]
local function OnPlotClicked(player)
    -- Check cooldown
    local currentTime = tick()
    if currentTime - plotState.lastInteraction < plotState.cooldown then
        print("⏱️ Plot interaction on cooldown")
        return
    end
    
    plotState.lastInteraction = currentTime
    
    -- Get player's equipped tool
    local success, toolName = pcall(function()
        -- Try to get HotbarController from player's scripts
        local playerScripts = player:WaitForChild("PlayerScripts", 1)
        if not playerScripts then return "Unknown" end
        
        local controllers = playerScripts:FindFirstChild("Controllers")
        if not controllers then return "Unknown" end
        
        local hotbarController = controllers:FindFirstChild("HotbarController")
        if not hotbarController then return "Unknown" end
        
        -- Require and get equipped tool
        local controller = require(hotbarController)
        return controller.GetEquippedTool()
    end)
    
    if not success then
        toolName = "Unknown"
    end
    
    print(string.format("🌱 %s clicked %s with tool: %s", player.Name, plot.Name, toolName))
    
    -- Visual feedback - quick pulse
    local pulseTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
    TweenService:Create(interactPart, pulseTweenInfo, {
        Transparency = math.max(0, originalTransparency - 0.2)
    }):Play()
    
    -- Send to server
    local sendSuccess, err = pcall(function()
        InteractWithPlot:FireServer(plot, toolName)
    end)
    
    if not sendSuccess then
        warn("⚠️ Failed to send interaction to server:", err)
    end
end

-- Connect events
clickDetector.MouseClick:Connect(OnPlotClicked)

clickDetector.MouseHoverEnter:Connect(function(player)
    ShowHoverEffect()
end)

clickDetector.MouseHoverLeave:Connect(function(player)
    HideHoverEffect()
end)

--[[
    Optional: ProximityPrompt support (for mobile/console)
    Uncomment this section if you want ProximityPrompt in addition to ClickDetector
]]
--[[
local proximityPrompt = Instance.new("ProximityPrompt")
proximityPrompt.ActionText = "Interact with Plot"
proximityPrompt.ObjectText = plot.Name
proximityPrompt.MaxActivationDistance = 10
proximityPrompt.HoldDuration = 0 -- Instant activation
proximityPrompt.Parent = interactPart

proximityPrompt.Triggered:Connect(function(player)
    OnPlotClicked(player)
end)

print("✅ ProximityPrompt added to", plot.Name)
]]

--[[
    Cleanup on script removal
]]
script.AncestryChanged:Connect(function()
    if not script.Parent then
        if highlight then
            highlight:Destroy()
        end
        print("🗑️ PlotInteraction cleaned up for", plot.Name)
    end
end)

print("✨ PlotInteraction ready for:", plot.Name)
print("   Click distance: 15 studs")
print("   Cooldown: 0.5 seconds")
print("   Hover effects: Enabled")
