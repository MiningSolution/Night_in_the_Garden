--[[
    GuiEffects.lua
    Location: StarterPlayer/StarterPlayerScripts/Utils/

    Small visual behaviours for the static GUI in StarterGui (P2-3).
    These used to live in the Create*UI scripts that built the GUI at runtime;
    the GUI is now static, so the controllers attach them on startup.
]]

local RunService = game:GetService("RunService")

local GuiEffects = {}

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

return GuiEffects
