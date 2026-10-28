--[[
    PlotInteraction (LocalScript)
    Location: StarterPlayer/StarterPlayerScripts/Utils/PlotInteraction

    PURPOSE:
    Hover feedback for garden plots: highlight + click cursor.

    WHY CLIENT-SIDE:
    The previous version was a server Script attached to each plot. It called
    InteractWithPlot:FireServer() (client-only API) and read the player's
    PlayerScripts (not visible to the server), so it could never work.

    Clicks are NOT sent from here: HotbarController already handles
    Mouse.Button1Down on plots and fires InteractWithPlot with the equipped tool.
    Sending here too would double every interaction.

    PLOT DETECTION:
    Any Model in Workspace with a PlotMarker child (same rule as PlotVisualizer).
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local HOVER_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local wired = {}

local function getInteractPart(plot)
    return plot.PrimaryPart or plot:FindFirstChild("PlotBase") or plot:FindFirstChildWhichIsA("BasePart")
end

local function setupPlot(plot)
    if wired[plot] then return end
    local part = getInteractPart(plot)
    if not part then
        warn("⚠️ PlotInteraction: no BasePart in", plot:GetFullName())
        return
    end
    wired[plot] = true

    -- ClickDetector gives the hand cursor and hover events; clicks are handled by HotbarController
    local detector = part:FindFirstChildOfClass("ClickDetector")
    if not detector then
        detector = Instance.new("ClickDetector")
        detector.Parent = part
    end
    detector.MaxActivationDistance = Constants.PLOT.CLIENT_CLICK_DISTANCE

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlotHighlight"
    highlight.Adornee = plot
    highlight.FillColor = Color3.fromRGB(80, 200, 120)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
    highlight.Enabled = false
    highlight.Parent = plot

    local hovered = false
    local outTween

    detector.MouseHoverEnter:Connect(function()
        if hovered then return end
        hovered = true
        if outTween then outTween:Cancel() end
        highlight.Enabled = true
        TweenService:Create(highlight, HOVER_IN, { FillTransparency = 0.7, OutlineTransparency = 0.3 }):Play()
    end)

    detector.MouseHoverLeave:Connect(function()
        if not hovered then return end
        hovered = false
        outTween = TweenService:Create(highlight, HOVER_OUT, { FillTransparency = 1, OutlineTransparency = 1 })
        outTween.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed and not hovered then
                highlight.Enabled = false
            end
        end)
        outTween:Play()
    end)

    plot.AncestryChanged:Connect(function()
        if not plot:IsDescendantOf(workspace) then
            wired[plot] = nil
            highlight:Destroy()
        end
    end)
end

local function tryPlot(obj)
    if obj:IsA("Model") and obj:FindFirstChild("PlotMarker") then
        setupPlot(obj)
    end
end

for _, obj in ipairs(workspace:GetChildren()) do
    tryPlot(obj)
end

-- Plots that stream in or get created later
workspace.ChildAdded:Connect(function(obj)
    task.defer(tryPlot, obj)
end)

local count = 0
for _ in pairs(wired) do count += 1 end
print(string.format("🌱 PlotInteraction: hover effects on %d plot(s)", count))
