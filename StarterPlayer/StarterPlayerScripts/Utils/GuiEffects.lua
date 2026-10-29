--[[
    GuiEffects.lua
    Location: StarterPlayer/StarterPlayerScripts/Utils/

    Small visual behaviours for the static GUI in StarterGui (P2-3).
    These used to live in the Create*UI scripts that built the GUI at runtime;
    the GUI is now static, so the controllers attach them on startup.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GuiEffects = {}

local OPEN_SCALE_NAME = "OpenAnimScale"
local OPEN_DURATION = 0.18
local OPEN_START_SCALE = 0.92
local OPEN_START_FADE = 0.3
local OPEN_TWEEN_INFO = TweenInfo.new(OPEN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- In-flight open tweens per frame (weak keys so destroyed frames are collected)
local openTweens = setmetatable({}, { __mode = "k" })

-- Swap BackgroundColor3 while the mouse is over the button
function GuiEffects.hoverColor(button: GuiObject, normal: Color3, hover: Color3)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hover
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normal
    end)
end

-- Rotate `image` while `overlay` is visible; no per-frame work while hidden
function GuiEffects.spinWhileVisible(image: GuiObject, overlay: GuiObject, degreesPerSecond: number?)
    local speed = degreesPerSecond or 180
    local connection
    local function update()
        if overlay.Visible and not connection then
            connection = RunService.RenderStepped:Connect(function(dt)
                image.Rotation += dt * speed
            end)
        elseif not overlay.Visible and connection then
            connection:Disconnect()
            connection = nil
        end
    end
    overlay:GetPropertyChangedSignal("Visible"):Connect(update)
    update()
end

-- Short ease-in when a window opens (visual only; the frame stays interactive).
-- Scales via a managed UIScale child (never touches the frame's Size) and fades
-- only when the frame is a CanvasGroup. Safe to call repeatedly or with nil.
function GuiEffects.openWindow(frame: GuiObject?)
    if not frame or not frame.Parent then
        return
    end

    local scale = frame:FindFirstChild(OPEN_SCALE_NAME)
    if not (scale and scale:IsA("UIScale")) then
        scale = Instance.new("UIScale")
        scale.Name = OPEN_SCALE_NAME
        scale.Parent = frame
    end

    -- Cancel any in-flight tweens from a previous open
    local running = openTweens[frame]
    if running then
        for _, tween in running do
            tween:Cancel()
        end
    end

    local tweens = {}
    scale.Scale = OPEN_START_SCALE
    table.insert(tweens, TweenService:Create(scale, OPEN_TWEEN_INFO, { Scale = 1 }))

    if frame:IsA("CanvasGroup") then
        frame.GroupTransparency = OPEN_START_FADE
        table.insert(tweens, TweenService:Create(frame, OPEN_TWEEN_INFO, { GroupTransparency = 0 }))
    end

    openTweens[frame] = tweens
    for _, tween in tweens do
        tween:Play()
    end
end

return GuiEffects
