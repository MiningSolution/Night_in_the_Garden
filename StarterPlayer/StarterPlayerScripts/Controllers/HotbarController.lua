--[[
    HotbarController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/
    
    PURPOSE:
    Manages the hotbar system including:
    - Tool slot management (3 slots)
    - Keyboard shortcuts (1, 2, 3 keys)
    - Visual slot highlighting
    - Tool equipping and usage
    - Integration with plot interaction
    
    DEPENDENCIES:
    - HUD ScreenGui (with Hotbar frame)
    - InteractWithPlot RemoteEvent
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local WindowManager = require(script.Parent.Parent.Utils:WaitForChild("WindowManager"))

local HotbarController = {}

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI elements
-- Static GUI (P2-3) is cloned into PlayerGui when the character first spawns,
-- which can take longer than any fixed timeout on a slow join: wait for it.
-- Feature 001: the hotbar moved out of HUD into the always-on-top HUDControls
-- ScreenGui (so it stays usable above a window backdrop). Read it from there.
local HUDControls = playerGui:WaitForChild("HUDControls")
local hotbar

if HUDControls then
    hotbar = HUDControls:WaitForChild("Hotbar", 5)
end

-- RemoteEvents for plot interaction and tool syncing
local InteractWithPlot
local EquipTool

task.spawn(function()
    InteractWithPlot = ReplicatedStorage:WaitForChild("InteractWithPlot", 30)
    EquipTool = ReplicatedStorage:WaitForChild("EquipTool", 30)
    if InteractWithPlot then
        print("✅ InteractWithPlot RemoteEvent connected")
    end
    if EquipTool then
        print("✅ EquipTool RemoteEvent connected")
    end
end)

-- State
local equippedSlot = 1
local maxSlots = 3

-- Default hotbar configuration
local slots = {
    {
        tool = "WateringCan",
        icon = "rbxassetid://0",
        displayName = "Watering Can",
        description = "Water your plants to help them grow",
        emoji = "💧"
    },
    {
        tool = "Seed_Carrot",
        icon = "rbxassetid://0",
        displayName = "Carrot Seed",
        description = "Plant carrots in empty plots",
        emoji = "🥕"
    },
    {
        tool = "Lantern",
        icon = "rbxassetid://0",
        displayName = "Lantern",
        description = "Light up the garden at night",
        emoji = "🏮"
    }
}

--[[
    Update visual highlight for equipped slot
    @param slotNumber (number) - Slot to highlight (1-3)
]]
local function UpdateSlotVisuals(slotNumber)
    if not hotbar then return end
    
    for i = 1, maxSlots do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if slot then
            local selectionBorder = slot:FindFirstChild("SelectionBorder")
            local slotButton = slot:FindFirstChild("SlotButton")
            
            if i == slotNumber then
                -- Highlight selected slot
                if selectionBorder then
                    selectionBorder.Visible = true
                    
                    -- Pulse animation
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    TweenService:Create(selectionBorder, tweenInfo, {
                        ImageTransparency = 0
                    }):Play()
                end
                
                if slotButton then
                    TweenService:Create(slotButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                    }):Play()
                end
            else
                -- Deselect other slots
                if selectionBorder then
                    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    local tween = TweenService:Create(selectionBorder, tweenInfo, {
                        ImageTransparency = 1
                    })
                    tween:Play()
                    tween.Completed:Connect(function()
                        selectionBorder.Visible = false
                    end)
                end
                
                if slotButton then
                    TweenService:Create(slotButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                    }):Play()
                end
            end
        end
    end
end

--[[
    Equip tool in specified slot
    @param slotNumber (number) - Slot number (1-3)
]]
function HotbarController.EquipSlot(slotNumber)
    if slotNumber < 1 or slotNumber > maxSlots then
        warn("⚠️ Invalid slot number:", slotNumber)
        return
    end
    
    if slotNumber == equippedSlot then
        -- Already equipped, do nothing
        return
    end
    
    equippedSlot = slotNumber
    
    -- Update visuals
    UpdateSlotVisuals(slotNumber)
    
    local toolName = slots[slotNumber].tool
    local displayName = slots[slotNumber].displayName
    
    -- Convert tool name to server format
    -- Map client tool names to server item names
    local serverToolName = toolName
    if toolName == "WateringCan" then
        serverToolName = "basic_watering_can"
    elseif toolName:match("^Seed_") then
        -- Convert "Seed_Carrot" to "carrot_seed"
        local plantName = toolName:gsub("^Seed_", ""):lower()
        serverToolName = plantName .. "_seed"
    elseif toolName == "Harvest" then
        serverToolName = "Harvest"
    end
    
    -- Sync to server
    if EquipTool then
        local success, err = pcall(function()
            EquipTool:FireServer(serverToolName)
        end)
        if not success then
            warn("⚠️ Failed to sync tool to server:", err)
        end
    end
    
    print(string.format("🔧 Equipped slot %d: %s (server: %s)", slotNumber, displayName, serverToolName))
    
    -- Optional: Show notification
    local UIController = script.Parent:FindFirstChild("UIController")
    if UIController then
        local success, controller = pcall(require, UIController)
        if success then
            controller.ShowNotification(
                string.format("Equipped: %s", displayName),
                "info",
                1.5
            )
        end
    end
end

--[[
    Get currently equipped tool
    @return string - Tool name
]]
function HotbarController.GetEquippedTool()
    return slots[equippedSlot].tool
end

--[[
    Get equipped tool display info
    @return table - Tool information
]]
function HotbarController.GetEquippedToolInfo()
    return slots[equippedSlot]
end

--[[
    Use equipped tool on target
    @param target (Instance) - Target object (usually a plot)
]]
function HotbarController.UseTool(target)
    local toolName = HotbarController.GetEquippedTool()
    
    if not target then
        warn("⚠️ No target specified for tool use")
        return
    end
    
    if not InteractWithPlot then
        warn("⚠️ InteractWithPlot RemoteEvent not available")
        return
    end
    
    -- Validate target
    if not target:IsA("Model") and not target:IsA("Part") then
        warn("⚠️ Invalid target for tool use:", target.Name)
        return
    end
    
    print(string.format("🔧 Using tool: %s on %s", toolName, target.Name))
    
    -- Send to server
    local success, err = pcall(function()
        InteractWithPlot:FireServer(target, toolName)
    end)
    
    if not success then
        warn("⚠️ Failed to use tool:", err)
    end
    
    -- Visual feedback - Tool use animation
    if hotbar then
        local slot = hotbar:FindFirstChild("Slot" .. equippedSlot)
        if slot then
            local itemIcon = slot:FindFirstChild("ItemIcon")
            if itemIcon then
                -- Quick scale pulse
                local originalSize = itemIcon.Size
                local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
                TweenService:Create(itemIcon, tweenInfo, {
                    Size = UDim2.new(originalSize.X.Scale * 1.2, 0, originalSize.Y.Scale * 1.2, 0)
                }):Play()
            end
        end
    end
end

--[[
    Set tool in specific slot
    @param slotNumber (number) - Slot to modify (1-3)
    @param toolData (table) - Tool information {tool, icon, displayName, description}
]]
function HotbarController.SetSlotTool(slotNumber, toolData)
    if slotNumber < 1 or slotNumber > maxSlots then
        warn("⚠️ Invalid slot number:", slotNumber)
        return
    end
    
    -- Update slot configuration
    slots[slotNumber] = {
        tool = toolData.tool or "Empty",
        icon = toolData.icon or "rbxassetid://0",
        displayName = toolData.displayName or "Empty Slot",
        description = toolData.description or "",
        emoji = toolData.emoji or "❓"
    }
    
    -- Update visual if slot exists
    if hotbar then
        local slot = hotbar:FindFirstChild("Slot" .. slotNumber)
        if slot then
            local itemIcon = slot:FindFirstChild("ItemIcon")
            if itemIcon then
                itemIcon.Image = slots[slotNumber].icon
            end
            
            -- Update emoji text if no icon
            if slots[slotNumber].icon == "rbxassetid://0" then
                local emojiLabel = itemIcon:FindFirstChild("EmojiLabel")
                if emojiLabel then
                    emojiLabel.Text = slots[slotNumber].emoji
                end
            end
        end
    end
    
    print(string.format("📦 Updated slot %d: %s", slotNumber, toolData.displayName or toolData.tool))
end

--[[
    Get all slot configurations
    @return table - Array of slot data
]]
function HotbarController.GetAllSlots()
    return slots
end

--[[
    Cycle to next slot
]]
function HotbarController.NextSlot()
    local nextSlot = equippedSlot + 1
    if nextSlot > maxSlots then
        nextSlot = 1
    end
    HotbarController.EquipSlot(nextSlot)
end

--[[
    Cycle to previous slot
]]
function HotbarController.PreviousSlot()
    local prevSlot = equippedSlot - 1
    if prevSlot < 1 then
        prevSlot = maxSlots
    end
    HotbarController.EquipSlot(prevSlot)
end

--[[
    Setup click handlers for hotbar slots
]]
local function SetupSlotButtons()
    if not hotbar then return end
    
    for i = 1, maxSlots do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if slot then
            local slotButton = slot:FindFirstChild("SlotButton")
            
            if slotButton and slotButton:IsA("GuiButton") then
                -- Click handler
                slotButton.MouseButton1Click:Connect(function()
                    HotbarController.EquipSlot(i)
                end)
                
                -- Hover effect
                slotButton.MouseEnter:Connect(function()
                    if i ~= equippedSlot then
                        TweenService:Create(slotButton, TweenInfo.new(0.1), {
                            BackgroundColor3 = Color3.fromRGB(70, 70, 80)
                        }):Play()
                    end
                end)
                
                slotButton.MouseLeave:Connect(function()
                    if i ~= equippedSlot then
                        TweenService:Create(slotButton, TweenInfo.new(0.1), {
                            BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                        }):Play()
                    end
                end)
            end
        end
    end
end

--[[
    Setup keyboard shortcuts
]]
local function SetupKeyboardShortcuts()
    -- Number keys 1-3 for slot selection
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        -- Don't process if typing in chat or other UI
        if gameProcessed then return end
        
        -- Slot selection (1, 2, 3)
        if input.KeyCode == Enum.KeyCode.One then
            HotbarController.EquipSlot(1)
        elseif input.KeyCode == Enum.KeyCode.Two then
            HotbarController.EquipSlot(2)
        elseif input.KeyCode == Enum.KeyCode.Three then
            HotbarController.EquipSlot(3)
        end
        
        -- Optional: Mouse wheel to cycle slots
        -- You can enable this if desired
        --[[
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if input.Position.Z > 0 then
                HotbarController.NextSlot()
            else
                HotbarController.PreviousSlot()
            end
        end
        ]]
    end)
end

--[[
    Setup mouse click detection for tool usage
]]
local function SetupMouseClickDetection()
    local Mouse = player:GetMouse()
    
    Mouse.Button1Down:Connect(function()
        -- R6/FR-008: never use a tool when a window is open or when the press
        -- lands on an Active GUI element (backdrop, menu buttons, hotbar slots),
        -- so taps on the UI do not also water/plant the world.
        if WindowManager.GetOpen() ~= nil then return end
        local inset = GuiService:GetGuiInset()
        local mp = UserInputService:GetMouseLocation()
        for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(mp.X - inset.X, mp.Y - inset.Y)) do
            if obj.Active then return end
        end

        -- Get what the mouse is pointing at
        local target = Mouse.Target

        if not target then return end
        
        -- Check if target is a plot or valid interaction object
        -- Look for Plot parent model
        local parent = target.Parent
        if parent and parent:IsA("Model") then
            -- Check if it's a plot by looking for specific markers
            local isPlot = parent:FindFirstChild("PlotMarker") or 
                          parent.Name:lower():find("plot") or
                          parent:FindFirstChild("PlotData")
            
            if isPlot then
                HotbarController.UseTool(parent)
            end
        end
    end)
end

--[[
    Initialize hotbar controller
]]
function HotbarController.Initialize()
    print("========================================")
    print("🎮 Initializing HotbarController...")
    print("========================================")
    
    if not hotbar then
        warn("⚠️ Hotbar not found in HUD - controller in limited mode")
        warn("   Keyboard shortcuts will still work for slot selection")
    end
    
    -- Setup UI interactions
    SetupSlotButtons()
    SetupKeyboardShortcuts()
    SetupMouseClickDetection()
    
    -- Equip first slot by default
    HotbarController.EquipSlot(1)
    
    print("✅ Keyboard shortcuts registered:")
    print("   [1] - Equip slot 1")
    print("   [2] - Equip slot 2")
    print("   [3] - Equip slot 3")
    print("")
    print("✅ Mouse click detection enabled")
    print("✅ Slot buttons configured")
    print("")
    print("📋 Default tools loaded:")
    for i, slot in ipairs(slots) do
        print(string.format("   Slot %d: %s %s", i, slot.emoji, slot.displayName))
    end
    print("========================================")
    print("✨ HotbarController ready!")
    print("========================================")
end

-- Auto-initialize
HotbarController.Initialize()

return HotbarController
