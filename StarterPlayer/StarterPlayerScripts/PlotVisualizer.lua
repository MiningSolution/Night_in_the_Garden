--[[
    PlotVisualizer.lua
    Location: StarterPlayer/StarterPlayerScripts/
    
    PURPOSE:
    Handles 3D visualization of garden plots including:
    - Plant growth stages (Empty → Planted → Growing → Ready → Harvesting → Empty)
    - Growth progress bars with TimeRemaining support
    - Visual effects (particles, glows)
    - Color changes based on state
    - Watering indicator
    - Harvest sparkles
    
    PLOT MODEL STRUCTURE (in Workspace):
    
    PlotModel (Model)
    ├── PlotBase (Part) - Ground/soil
    ├── PlotBorder (Parts) - Optional decorative border
    ├── PlantAttachment (Attachment) - Where plant model spawns
    ├── ProgressBarAttachment (Attachment) - Where progress UI goes
    └── PlotMarker (BoolValue) - Identifies this as a plot
    
    DEPENDENCIES:
    - ReplicatedStorage/PlantData (for plant info)
    - EventHandlers.lua (receives PlotStateChanged events)
    
    VERSION: 2.0 (supports TimeRemaining and Harvesting state)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local PlotVisualizer = {}

-- References
local player = Players.LocalPlayer
local workspace = game:Workspace

-- Load plant configuration
local PlantData = require(ReplicatedStorage:WaitForChild("PlantData"))

-- Cache for plot visuals
local plotVisuals = {} -- [plotId] = {model, plantInstance, progressBar, etc.}

-- P2-6: Object pooling for particle emitters
local particlePool = {
    water = {},
    grow = {},
    harvest = {}
}

-- ========================================
-- CONFIGURATION
-- ========================================

local CONFIG = {
    -- Colors for different states
    Colors = {
        Empty = Color3.fromRGB(101, 67, 33),        -- Brown soil
        Planted = Color3.fromRGB(85, 85, 85),       -- Dark (just planted)
        Growing = Color3.fromRGB(70, 120, 50),      -- Green (growing)
        ReadyToHarvest = Color3.fromRGB(255, 215, 0), -- Golden (ready!)
        Harvesting = Color3.fromRGB(255, 180, 0),   -- Bright gold (being harvested)
        Withered = Color3.fromRGB(139, 69, 19)      -- Dark brown (dead)
    },
    
    -- Materials
    Materials = {
        Empty = Enum.Material.Ground,
        Planted = Enum.Material.Ground,
        Growing = Enum.Material.Grass,
        ReadyToHarvest = Enum.Material.Grass,
        Harvesting = Enum.Material.Neon,
        Withered = Enum.Material.Ground
    },
    
    -- Progress bar settings
    ProgressBar = {
        Size = UDim2.new(3, 0, 0.3, 0),
        BackgroundColor = Color3.fromRGB(30, 30, 30),
        FillColor = Color3.fromRGB(80, 200, 120),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        ShowTimeRemaining = true  -- Show "⏱ Xs" instead of percentage when available
    },
    
    -- Plant scale settings
    PlantScale = {
        Planted = 0.2,      -- Just sprouted
        Growing = 0.6,      -- Mid-growth
        Ready = 1.0         -- Full size
    },
    
    -- Animation durations
    AnimationSpeed = 0.3,
    
    -- Particle effects
    EnableParticles = true
}

-- ========================================
-- PLOT DISCOVERY
-- ========================================

--[[
    Find all plot models in Workspace
    @return table - Array of plot models
]]
local function FindAllPlots()
    local plots = {}
    
    -- Look for models with PlotMarker
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local marker = obj:FindFirstChild("PlotMarker")
            if marker and marker:IsA("BoolValue") and marker.Value == true then
                table.insert(plots, obj)
            end
        end
    end
    
    -- Fallback: Look for models with "Plot" in name
    if #plots == 0 then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name:match("Plot") then
                table.insert(plots, obj)
            end
        end
    end
    
    return plots
end

--[[
    Get or create plot visual data
    @param plotModel (Model) - The plot model
    @return table - Visual data structure
]]
local function GetPlotVisual(plotModel)
    local plotId = plotModel.Name
    
    if plotVisuals[plotId] then
        return plotVisuals[plotId]
    end
    
    -- Create new visual data
    local visual = {
        model = plotModel,
        plotBase = plotModel:FindFirstChild("PlotBase") or plotModel.PrimaryPart or plotModel:FindFirstChildWhichIsA("Part"),
        plantAttachment = plotModel:FindFirstChild("PlantAttachment"),
        progressBarAttachment = plotModel:FindFirstChild("ProgressBarAttachment"),
        plantInstance = nil,
        progressBarGui = nil,
        particleEmitter = nil,
        currentState = "Empty",
        currentPlantId = nil
    }
    
    plotVisuals[plotId] = visual
    return visual
end

-- ========================================
-- PROGRESS BAR SYSTEM
-- ========================================

--[[
    Create or get progress bar GUI
    @param visual (table) - Plot visual data
    @return BillboardGui
]]
local function GetOrCreateProgressBar(visual)
    if visual.progressBarGui then
        return visual.progressBarGui
    end
    
    local attachment = visual.progressBarAttachment or visual.plotBase
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ProgressBar"
    billboardGui.Size = UDim2.new(4, 0, 1.5, 0)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Adornee = attachment
    billboardGui.Parent = attachment:IsA("Attachment") and attachment.Parent or attachment
    
    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = CONFIG.ProgressBar.Size
    background.Position = UDim2.new(0.5, 0, 0.5, 0)
    background.AnchorPoint = Vector2.new(0.5, 0.5)
    background.BackgroundColor3 = CONFIG.ProgressBar.BackgroundColor
    background.BorderSizePixel = 0
    background.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = background
    
    -- Fill bar
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = CONFIG.ProgressBar.FillColor
    fill.BorderSizePixel = 0
    fill.Parent = background
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = fill
    
    -- Progress text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ProgressText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "0%"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = CONFIG.ProgressBar.TextSize
    textLabel.Font = CONFIG.ProgressBar.Font
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Parent = background
    
    billboardGui.Enabled = false -- Hidden by default
    
    visual.progressBarGui = billboardGui
    return billboardGui
end

--[[
    Update progress bar
    @param visual (table) - Plot visual data
    @param progress (number) - Progress 0 to 1
    @param state (string) - Current state
    @param timeRemaining (number|nil) - Seconds remaining (optional)
]]
local function UpdateProgressBar(visual, progress, state, timeRemaining)
    local progressBar = GetOrCreateProgressBar(visual)
    
    -- Show/hide based on state
    if state == "Growing" then
        progressBar.Enabled = true
    elseif state == "ReadyToHarvest" then
        progressBar.Enabled = true
    elseif state == "Harvesting" then
        progressBar.Enabled = true
    else
        progressBar.Enabled = false
        return
    end
    
    progress = math.clamp(progress, 0, 1)
    
    local background = progressBar:FindFirstChild("Background")
    if not background then return end
    
    local fill = background:FindFirstChild("Fill")
    local textLabel = background:FindFirstChild("ProgressText")
    
    if fill then
        -- Animate fill
        local tweenInfo = TweenInfo.new(CONFIG.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(fill, tweenInfo, {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        
        -- Change color based on progress/state
        if state == "Harvesting" then
            fill.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange (harvesting)
        elseif progress >= 1 then
            fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold (ready)
        elseif progress >= 0.75 then
            fill.BackgroundColor3 = Color3.fromRGB(150, 200, 100) -- Light green
        else
            fill.BackgroundColor3 = CONFIG.ProgressBar.FillColor -- Normal green
        end
    end
    
    if textLabel then
        if state == "Harvesting" then
            textLabel.Text = "🌾 HARVESTING..."
        elseif progress >= 1 then
            textLabel.Text = "✨ READY!"
        elseif CONFIG.ProgressBar.ShowTimeRemaining and timeRemaining and timeRemaining > 0 then
            -- Show time remaining if available
            local minutes = math.floor(timeRemaining / 60)
            local seconds = math.floor(timeRemaining % 60)
            
            if minutes > 0 then
                textLabel.Text = string.format("⏱ %dm %ds", minutes, seconds)
            else
                textLabel.Text = string.format("⏱ %ds", seconds)
            end
        else
            -- Show percentage
            textLabel.Text = string.format("%d%%", math.floor(progress * 100))
        end
    end
end

-- ========================================
-- PLANT MODEL SYSTEM
-- ========================================

--[[
    Create placeholder plant model
    @param plantId (string) - Plant identifier
    @param scale (number) - Size scale
    @return Model
]]
local function CreatePlaceholderPlant(plantId, scale)
    local plantInfo = PlantData[plantId] or {}
    
    -- Create simple plant representation
    local plantModel = Instance.new("Model")
    plantModel.Name = plantId .. "_Plant"
    
    -- Stem
    local stem = Instance.new("Part")
    stem.Name = "Stem"
    stem.Size = Vector3.new(0.2, 2, 0.2) * scale
    stem.Color = Color3.fromRGB(34, 139, 34)
    stem.Material = Enum.Material.SmoothPlastic
    stem.Anchored = true
    stem.CanCollide = false
    stem.Parent = plantModel
    
    local stemMesh = Instance.new("CylinderMesh")
    stemMesh.Parent = stem
    
    -- Leaves (simple sphere)
    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Size = Vector3.new(1, 1, 1) * scale
    leaves.Shape = Enum.PartType.Ball
    leaves.Color = Color3.fromRGB(50, 200, 50)
    leaves.Material = Enum.Material.Grass
    leaves.Anchored = true
    leaves.CanCollide = false
    leaves.Position = stem.Position + Vector3.new(0, stem.Size.Y / 2 + 0.5 * scale, 0)
    leaves.Parent = plantModel
    
    -- Optional: Add plant-specific features
    if plantId == "carrot" then
        leaves.Color = Color3.fromRGB(255, 140, 0) -- Orange
    elseif plantId == "tomato" then
        leaves.Color = Color3.fromRGB(255, 50, 50) -- Red
    elseif plantId == "wheat" then
        leaves.Color = Color3.fromRGB(218, 165, 32) -- Golden
    elseif plantId == "pumpkin" then
        -- Add pumpkin on ground
        local pumpkin = Instance.new("Part")
        pumpkin.Name = "Pumpkin"
        pumpkin.Size = Vector3.new(1.5, 1, 1.5) * scale
        pumpkin.Shape = Enum.PartType.Ball
        pumpkin.Color = Color3.fromRGB(255, 140, 0)
        pumpkin.Material = Enum.Material.SmoothPlastic
        pumpkin.Anchored = true
        pumpkin.CanCollide = false
        pumpkin.Position = stem.Position
        pumpkin.Parent = plantModel
    elseif plantId == "moonflower" or plantId == "starberry" then
        -- Night plants - glowing
        leaves.Color = Color3.fromRGB(150, 150, 255)
        leaves.Material = Enum.Material.Neon
        
        -- Add point light
        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Range = 10
        light.Color = Color3.fromRGB(150, 150, 255)
        light.Parent = leaves
    end
    
    plantModel.PrimaryPart = stem
    
    return plantModel
end

--[[
    Spawn or update plant visual
    @param visual (table) - Plot visual data
    @param plantId (string) - Plant identifier
    @param scale (number) - Size scale
]]
local function SpawnPlant(visual, plantId, scale)
    scale = scale or CONFIG.PlantScale.Planted
    
    -- Remove old plant if exists
    if visual.plantInstance then
        visual.plantInstance:Destroy()
        visual.plantInstance = nil
    end
    
    -- Create new plant
    local plant = CreatePlaceholderPlant(plantId, scale)
    
    -- Position plant
    if visual.plantAttachment then
        plant:SetPrimaryPartCFrame(visual.plantAttachment.WorldCFrame)
    elseif visual.plotBase then
        local baseCFrame = visual.plotBase.CFrame
        plant:SetPrimaryPartCFrame(baseCFrame * CFrame.new(0, visual.plotBase.Size.Y / 2 + 1, 0))
    end
    
    plant.Parent = workspace
    visual.plantInstance = plant
    visual.currentPlantId = plantId
    
    -- Spawn animation
    if plant.PrimaryPart then
        plant.PrimaryPart.Size = Vector3.new(0.1, 0.1, 0.1)
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
        TweenService:Create(plant.PrimaryPart, tweenInfo, {
            Size = Vector3.new(0.2, 2, 0.2) * scale
        }):Play()
    end
    
    print(string.format("🌱 Spawned %s plant (scale: %.2f)", plantId, scale))
end

--[[
    Remove plant visual
    @param visual (table) - Plot visual data
]]
local function RemovePlant(visual)
    if visual.plantInstance then
        -- Despawn animation
        if visual.plantInstance.PrimaryPart then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local tween = TweenService:Create(visual.plantInstance.PrimaryPart, tweenInfo, {
                Size = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1
            })
            tween:Play()
            
            tween.Completed:Connect(function()
                if visual.plantInstance then
                    visual.plantInstance:Destroy()
                    visual.plantInstance = nil
                end
            end)
        else
            visual.plantInstance:Destroy()
            visual.plantInstance = nil
        end
    end
    
    visual.currentPlantId = nil
end

-- ========================================
-- PARTICLE EFFECTS
-- ========================================

--[[
    Create particle effect for plot
    @param visual (table) - Plot visual data
    @param effectType (string) - "water", "grow", "harvest"
]]
-- P2-6: Get or create particle emitter from pool
local function getParticleFromPool(effectType)
    local pool = particlePool[effectType]
    if not pool then
        warn("[PlotVisualizer] Unknown particle effect type:", effectType)
        return nil
    end
    
    -- Try to get inactive emitter from pool
    for i, emitter in ipairs(pool) do
        if not emitter.Enabled and emitter.Parent == nil then
            return emitter
        end
    end
    
    -- Create new if pool empty
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = effectType .. "Effect"
    
    -- Configure based on type
    if effectType == "water" then
        emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(100, 150, 255))
        emitter.Size = NumberSequence.new(0.3, 0.1)
        emitter.Transparency = NumberSequence.new(0.3, 1)
        emitter.Lifetime = NumberRange.new(0.5, 1)
        emitter.Rate = 20
        emitter.Speed = NumberRange.new(2, 4)
        emitter.SpreadAngle = Vector2.new(30, 30)
        
    elseif effectType == "grow" then
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(80, 200, 120))
        emitter.Size = NumberSequence.new(0.2, 0)
        emitter.Transparency = NumberSequence.new(0, 1)
        emitter.Lifetime = NumberRange.new(1, 2)
        emitter.Rate = 5
        emitter.Speed = NumberRange.new(1, 2)
        
    elseif effectType == "harvest" then
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
        emitter.Size = NumberSequence.new(0.5, 0)
        emitter.Transparency = NumberSequence.new(0, 1)
        emitter.Lifetime = NumberRange.new(0.5, 1.5)
        emitter.Rate = 50
        emitter.Speed = NumberRange.new(5, 10)
        emitter.SpreadAngle = Vector2.new(180, 180)
    end
    
    table.insert(pool, emitter)
    return emitter
end

-- P2-6: Return emitter to pool
local function returnParticleToPool(emitter)
    if not emitter then return end
    emitter.Enabled = false
    emitter.Parent = nil
end

local function CreateParticleEffect(visual, effectType)
    if not CONFIG.EnableParticles then return end
    if not visual.plotBase then return end
    
    -- P2-6: Remove existing particles and return to pool
    if visual.particleEmitter then
        returnParticleToPool(visual.particleEmitter)
        visual.particleEmitter = nil
    end
    
    -- P2-6: Get from pool
    local emitter = getParticleFromPool(effectType)
    if not emitter then return end
    
    emitter.Parent = visual.plotBase
    emitter.Enabled = true
    visual.particleEmitter = emitter
    
    -- P2-6: Auto-disable and return to pool after duration
    if effectType == "water" then
        task.delay(2, function()
            if emitter and visual.particleEmitter == emitter then
                returnParticleToPool(emitter)
                visual.particleEmitter = nil
            end
        end)
    elseif effectType == "harvest" then
        task.delay(1, function()
            if emitter and visual.particleEmitter == emitter then
                returnParticleToPool(emitter)
                visual.particleEmitter = nil
            end
        end)
    end
    -- "grow" particles stay active until manually disabled
end

-- ========================================
-- MAIN UPDATE FUNCTION
-- ========================================

--[[
    Update plot visual based on state
    @param plotId (string) - Plot identifier
    @param plotData (table) - Plot state data from server
]]
function PlotVisualizer.UpdatePlot(plotId, plotData)
    -- Find plot model in workspace
    local plotModel = workspace:FindFirstChild(plotId)
    
    if not plotModel then
        warn(string.format("⚠️ Plot model '%s' not found in Workspace", plotId))
        return
    end
    
    local visual = GetPlotVisual(plotModel)
    local state = plotData.State or "Empty"
    local plantId = plotData.PlantId
    local progress = plotData.GrowthProgress or 0
    local isWatered = plotData.IsWatered or false
    local timeRemaining = plotData.TimeRemaining  -- NEW: from server
    
    print(string.format("🎨 Updating visual: %s → %s (%s %.0f%% | ⏱ %s)", 
        plotId, 
        state, 
        plantId or "none", 
        progress * 100,
        timeRemaining and (timeRemaining .. "s") or "N/A"
    ))
    
    -- Update plot base color/material
    if visual.plotBase then
        local targetColor = CONFIG.Colors[state] or CONFIG.Colors.Empty
        local targetMaterial = CONFIG.Materials[state] or CONFIG.Materials.Empty
        
        local tweenInfo = TweenInfo.new(CONFIG.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(visual.plotBase, tweenInfo, {
            Color = targetColor,
            Material = targetMaterial
        }):Play()
        
        -- Watered effect (darker/wetter look)
        if isWatered and (state == "Planted" or state == "Growing") then
            visual.plotBase.Reflectance = 0.3
        else
            visual.plotBase.Reflectance = 0
        end
    end
    
    -- Handle plant visual based on state
    if state == "Empty" then
        -- Remove plant
        RemovePlant(visual)
        UpdateProgressBar(visual, 0, state, timeRemaining)
        
    elseif state == "Planted" then
        -- Spawn small plant
        if not visual.plantInstance or visual.currentPlantId ~= plantId then
            SpawnPlant(visual, plantId, CONFIG.PlantScale.Planted)
        end
        UpdateProgressBar(visual, 0, state, timeRemaining)
        CreateParticleEffect(visual, "grow")
        
    elseif state == "Growing" then
        -- Update plant size based on growth
        local scale = CONFIG.PlantScale.Planted + (CONFIG.PlantScale.Ready - CONFIG.PlantScale.Planted) * progress
        
        if not visual.plantInstance or visual.currentPlantId ~= plantId then
            SpawnPlant(visual, plantId, scale)
        elseif visual.plantInstance and visual.plantInstance.PrimaryPart then
            -- Animate scale
            local targetSize = Vector3.new(0.2, 2, 0.2) * scale
            local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
            TweenService:Create(visual.plantInstance.PrimaryPart, tweenInfo, {
                Size = targetSize
            }):Play()
        end
        
        UpdateProgressBar(visual, progress, state, timeRemaining)
        
        -- Water effect if just watered
        if isWatered then
            CreateParticleEffect(visual, "water")
        end
        
    elseif state == "ReadyToHarvest" then
        -- Full size plant
        if not visual.plantInstance or visual.currentPlantId ~= plantId then
            SpawnPlant(visual, plantId, CONFIG.PlantScale.Ready)
        end
        
        UpdateProgressBar(visual, 1, state, 0)  -- TimeRemaining = 0 when ready
        
        -- Don't spam harvest particles - only on initial ready state
        if visual.currentState ~= "ReadyToHarvest" then
            CreateParticleEffect(visual, "harvest")
        end
        
        -- Glow effect for ready plants
        if visual.plantInstance then
            for _, part in ipairs(visual.plantInstance:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Neon
                end
            end
        end
        
    elseif state == "Harvesting" then
        -- NEW: Harvesting state - intense particles and animation
        UpdateProgressBar(visual, 1, state, 0)
        CreateParticleEffect(visual, "harvest")
        
        -- Pulse animation on plant
        if visual.plantInstance and visual.plantInstance.PrimaryPart then
            local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            local tween = TweenService:Create(visual.plantInstance.PrimaryPart, tweenInfo, {
                Size = visual.plantInstance.PrimaryPart.Size * 1.2
            })
            tween:Play()
            
            tween.Completed:Connect(function()
                if visual.plantInstance and visual.plantInstance.PrimaryPart then
                    TweenService:Create(visual.plantInstance.PrimaryPart, tweenInfo, {
                        Size = visual.plantInstance.PrimaryPart.Size / 1.2
                    }):Play()
                end
            end)
        end
        
    elseif state == "Withered" then
        -- Dead plant visual
        if visual.plantInstance then
            for _, part in ipairs(visual.plantInstance:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = Color3.fromRGB(100, 70, 40)
                    part.Material = Enum.Material.Wood
                end
            end
        end
        UpdateProgressBar(visual, 0, state, timeRemaining)
    end
    
    visual.currentState = state
end

--[[
    Initialize plot visualizer system
]]
function PlotVisualizer.Initialize()
    print("========================================")
    print("🎨 Initializing PlotVisualizer v2.0...")
    print("========================================")
    
    -- Find all plots in workspace
    local plots = FindAllPlots()
    
    if #plots == 0 then
        warn("⚠️ No plots found in Workspace!")
        warn("   Make sure plot models have 'PlotMarker' BoolValue set to true")
        warn("   Or name them 'Plot1', 'Plot2', etc.")
    else
        print(string.format("✅ Found %d plot(s) in Workspace:", #plots))
        for i, plot in ipairs(plots) do
            print(string.format("   %d. %s", i, plot.Name))
            
            -- Initialize visual for each plot
            GetPlotVisual(plot)
        end
    end
    
    print("")
    print("✅ Plot visualization system ready!")
    print("   States: Empty, Planted, Growing, ReadyToHarvest, Harvesting, Withered")
    print("   Features:")
    print("     - Progress bars with TimeRemaining support")
    print("     - Particle effects (water, grow, harvest)")
    print("     - Color/material changes")
    print("     - Plant scaling animation")
    print("========================================")
end

-- Auto-initialize
PlotVisualizer.Initialize()

return PlotVisualizer
