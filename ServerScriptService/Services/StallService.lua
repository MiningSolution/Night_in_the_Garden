-- StallService.lua
-- Feature 002, User Story 1: spawns the seller's stall with a "Sell" ProximityPrompt.
--
-- The world (Workspace) is NOT part of the Rojo-synced repository, so the stall is
-- created by this repo-tracked server service rather than placed loose in the place
-- file — keeping it reviewable and authoritative (constitution III, I). The prompt
-- gives the on-screen button on touch/gamepad and the E key on PC for free (FR-002).
-- SellController (client) listens to the prompt's Triggered to open the sell window;
-- selling itself goes through the validated SellItem/SellAll remotes.

local Workspace = game:GetService("Workspace")

local M = {}

local STALL_NAME = "SellStall"
local STALL_POSITION = Vector3.new(12, 2.5, 0) -- near spawn; adjust in Studio to taste
local ACTIVATION_DISTANCE = 12 -- studs (SellController watches a slightly larger range)

function M.Start()
    if Workspace:FindFirstChild(STALL_NAME) then
        return Workspace:FindFirstChild(STALL_NAME)
    end

    local model = Instance.new("Model")
    model.Name = STALL_NAME

    local part = Instance.new("Part")
    part.Name = "StallBase"
    part.Size = Vector3.new(6, 5, 2)
    part.Position = STALL_POSITION
    part.Anchored = true
    part.CanCollide = true
    part.Color = Color3.fromRGB(120, 85, 55)
    part.Material = Enum.Material.WoodPlanks
    part.Parent = model
    model.PrimaryPart = part

    -- A simple sign so the stall reads as a seller's stall.
    local sign = Instance.new("Part")
    sign.Name = "Sign"
    sign.Size = Vector3.new(6, 1.4, 0.4)
    sign.Position = STALL_POSITION + Vector3.new(0, 3.2, 0)
    sign.Anchored = true
    sign.CanCollide = false
    sign.Color = Color3.fromRGB(90, 60, 40)
    sign.Material = Enum.Material.WoodPlanks
    sign.Parent = model

    local gui = Instance.new("BillboardGui")
    gui.Name = "SignLabel"
    gui.Size = UDim2.new(0, 160, 0, 40)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🪙 Seller's Stall"
    label.TextColor3 = Color3.fromRGB(255, 240, 200)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SellPrompt"
    prompt.ActionText = "Sell"
    prompt.ObjectText = "Seller"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    -- Phase 1 already binds ButtonX (shop) / ButtonY (inventory) / B (close) through
    -- InputActions, so the prompt uses a free trigger to avoid a gamepad clash. The
    -- full gamepad binding pass is the input work in US6 / a later polish step.
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonR2
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = ACTIVATION_DISTANCE
    prompt.Parent = part

    model.Parent = Workspace
    print("[StallService] Seller stall spawned at", STALL_POSITION)
    return model
end

task.spawn(M.Start)

return M
