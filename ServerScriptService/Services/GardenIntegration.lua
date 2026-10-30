-- GardenIntegration.lua
-- Garden World Kit: promote 3 of the kit's decorative garden beds into the game's
-- functional plots (Plot1..Plot3).
--
-- The world (Workspace) is NOT part of the Rojo-synced repository, so -- like
-- StallService -- this repo-tracked service adapts the committed map at runtime
-- instead of hand-editing the place file (constitution I, III). For each plot it:
--   * removes any pre-existing manual Plot<id> so names never duplicate,
--   * strips the bed's decorative-only crops (so the real plant visuals own the bed;
--     the kit's decorative plants must never read as a working farm),
--   * sets PrimaryPart to the bed soil and tags the model with PlotMarker (BoolValue),
--   * renames it Plot<id> and reparents it to top-level Workspace,
-- which is exactly what PlotVisualizer / PlotInteraction / PlotManager look for
-- (top-level Model, PlotMarker == true, a BasePart for placement). Plot *state* stays
-- server-authoritative in the player profile, keyed by the plot name, so moving the
-- model changes only where a plot is shown, not what it holds.

local Workspace = game:GetService("Workspace")

local M = {}

local PLOT_COUNT = 3 -- Plot1..Plot3 (matches PlotManager VALID_PLOT_IDS)

local function stripDecor(plot)
    for _, d in ipairs(plot:GetDescendants()) do
        if d:GetAttribute("DecorOnly") or d.Name:match("^DecorCrop") then
            d:Destroy()
        end
    end
end

local function choosePrimary(plot)
    -- Prefer a bed soil part so plants render in a tilled bed; fall back to the grass
    -- slab, then any part.
    return plot:FindFirstChild("Soil", true)
        or plot:FindFirstChild("PlotGrass")
        or plot:FindFirstChildWhichIsA("BasePart", true)
end

function M.Start()
    local map = Workspace:WaitForChild("NITG_GardenWorld", 30)
    if not map then
        warn("[GardenIntegration] NITG_GardenWorld not found; plots unchanged")
        return
    end
    local kitPlots = map:WaitForChild("Plots", 10)
    if not kitPlots then
        warn("[GardenIntegration] NITG_GardenWorld.Plots not found; plots unchanged")
        return
    end

    local promoted = 0
    for id = 1, PLOT_COUNT do
        local functionalName = "Plot" .. id
        local kitPlot = kitPlots:FindFirstChild("Plot_" .. id)
        if not kitPlot then
            warn("[GardenIntegration] missing kit plot Plot_" .. id)
        else
            -- Remove a pre-existing manual plot of this name (the pre-kit test plots)
            -- so the promoted bed is the only Plot<id>.
            local existing = Workspace:FindFirstChild(functionalName)
            if existing and existing ~= kitPlot then
                existing:Destroy()
            end

            stripDecor(kitPlot)

            local base = choosePrimary(kitPlot)
            if base then
                kitPlot.PrimaryPart = base
            end

            if not kitPlot:FindFirstChild("PlotMarker") then
                local marker = Instance.new("BoolValue")
                marker.Name = "PlotMarker"
                marker.Value = true
                marker.Parent = kitPlot
            end

            kitPlot.Name = functionalName
            kitPlot.Parent = Workspace
            promoted += 1
        end
    end

    print(string.format("[GardenIntegration] promoted %d kit bed(s) to functional Plot1..%d", promoted, PLOT_COUNT))
end

task.spawn(M.Start)

return M
