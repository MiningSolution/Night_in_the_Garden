--[[
    GuiRecorder — runs a GUI builder script and records every property it sets.

    Used for P2-3 (static GUI). The original Create*UI scripts built the GUI at
    runtime; this runs the same code once and turns it into:
      - Rojo .model.json files (locally, with a mocked Roblox API), and
      - real instances in StarterGui (in Studio, with the real API),
    and a canonical fingerprint of both so they can be compared.

    Works in plain Luau and in Roblox Studio. Pass `realNew = Instance.new` in
    Studio; pass nil locally.
]]

local R = {}

-- Strip the runtime-only parts of a Create*UI LocalScript and turn it into a
-- function(playerGui, Instance) that builds into any parent.
--   * drops `local Players/player/playerGui = ...` (playerGui becomes a parameter)
--   * drops top-level `X:Connect(function ... end)` blocks (hover effects, tab
--     colors, spinner); that logic now lives in the controllers
function R.transform(src: string): string
    local out, skipping = {}, false
    for line in (src:gsub("\r\n", "\n") .. "\n"):gmatch("([^\n]*)\n") do
        if skipping then
            if line:match("^end%)") then skipping = false end
        elseif line:match("^[%w_%.]+:Connect%(function") then
            skipping = true
        elseif line:match("^local Players = ") or line:match("^local player = ") or line:match("^local playerGui = ") then
            -- provided by the caller
        else
            table.insert(out, line)
        end
    end
    return "return function(playerGui, Instance)\n" .. table.concat(out, "\n") .. "\nend\n"
end

-- kind of a value: real Roblox datatypes via typeof, mocks via __kind
local function kindOf(v)
    if type(v) == "table" and rawget(v, "__kind") then return v.__kind end
    return typeof(v)
end

local function num(n: number): string
    -- Color3/UDim scales are float32 in Roblox; 4 decimals is stable across both sides
    local s = string.format("%.4f", n)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    if s == "-0" then s = "0" end
    return s
end

-- Canonical text of a value, identical for mocks and real datatypes
function R.canon(v): string
    local k = kindOf(v)
    if k == "string" then return string.format("%q", v)
    elseif k == "number" then return num(v)
    elseif k == "boolean" then return tostring(v)
    elseif k == "UDim2" then return string.format("UDim2(%s,%s,%s,%s)", num(v.X.Scale), num(v.X.Offset), num(v.Y.Scale), num(v.Y.Offset))
    elseif k == "UDim" then return string.format("UDim(%s,%s)", num(v.Scale), num(v.Offset))
    elseif k == "Vector2" then return string.format("Vector2(%s,%s)", num(v.X), num(v.Y))
    elseif k == "Color3" then return string.format("Color3(%s,%s,%s)", num(v.R), num(v.G), num(v.B))
    elseif k == "ColorSequence" then
        local ps = {}
        for _, kp in ipairs(v.Keypoints) do
            table.insert(ps, num(kp.Time) .. ":" .. R.canon(kp.Value))
        end
        return "ColorSequence(" .. table.concat(ps, ",") .. ")"
    elseif k == "Rect" then return string.format("Rect(%s,%s,%s,%s)", num(v.Min.X), num(v.Min.Y), num(v.Max.X), num(v.Max.Y))
    elseif k == "EnumItem" then return string.format("Enum.%s.%s", tostring(v.EnumType), v.Name)
    end
    error("GuiRecorder: unsupported value kind " .. tostring(k))
end

-- Value in Rojo's implicit property format (used for .model.json)
function R.rojoValue(v)
    local k = kindOf(v)
    if k == "string" or k == "number" or k == "boolean" then return v
    -- Rojo has no implicit form for UDim2/UDim/Rect, so these are typed explicitly
    elseif k == "UDim2" then return { UDim2 = { { v.X.Scale, v.X.Offset }, { v.Y.Scale, v.Y.Offset } } }
    elseif k == "UDim" then return { UDim = { v.Scale, v.Offset } }
    elseif k == "Vector2" then return { v.X, v.Y }
    elseif k == "Color3" then return { v.R, v.G, v.B }
    elseif k == "ColorSequence" then
        local kps = {}
        for _, kp in ipairs(v.Keypoints) do
            table.insert(kps, { time = kp.Time, color = { kp.Value.R, kp.Value.G, kp.Value.B } })
        end
        return { ColorSequence = { keypoints = kps } }
    elseif k == "Rect" then return { Rect = { { v.Min.X, v.Min.Y }, { v.Max.X, v.Max.Y } } }
    elseif k == "EnumItem" then return v.Name
    end
    error("GuiRecorder: unsupported value kind " .. tostring(k))
end

-- Create a recorder. Returns an `Instance` table to hand to the builder and
-- the list of root nodes (instances parented to something outside the build).
function R.new(realNew)
    local roots = {}
    local nodeOf = setmetatable({}, { __mode = "k" })
    local Instance = {}

    function Instance.new(className: string)
        local real = realNew and realNew(className) or nil
        local node = { ClassName = className, Name = className, props = {}, keys = {}, children = {}, attributes = {}, attrKeys = {}, real = real }
        local proxy = setmetatable({}, {
            __index = function(_, key)
                if key == "Name" then return node.Name end
                if key == "ClassName" then return node.ClassName end
                if key == "FindFirstChild" then
                    -- search the recorded tree so later writes stay recorded
                    return function(_, name)
                        for _, child in ipairs(node.children) do
                            if child.Name == name then return child.proxy end
                        end
                        return nil
                    end
                end
                if key == "SetAttribute" then
                    -- record theme tags (Theme_<Prop> = "<Token>") into the model + fingerprint
                    return function(_, name, value)
                        if node.attributes[name] == nil then table.insert(node.attrKeys, name) end
                        node.attributes[name] = value
                        if real then real:SetAttribute(name, value) end
                    end
                end
                if key == "GetAttribute" then
                    return function(_, name) return node.attributes[name] end
                end
                if node.props[key] ~= nil then return node.props[key] end
                if real then
                    local v = real[key]
                    if type(v) == "function" then
                        return function(_, ...) return v(real, ...) end
                    end
                    return v
                end
                error("GuiRecorder: read of unset property " .. className .. "." .. tostring(key))
            end,
            __newindex = function(_, key, value)
                if key == "Parent" then
                    local parentNode = nodeOf[value]
                    if parentNode then
                        table.insert(parentNode.children, node)
                    else
                        table.insert(roots, node)
                    end
                    if real then real.Parent = parentNode and parentNode.real or value end
                    return
                end
                local raw = value
                if nodeOf[value] then raw = nodeOf[value].real end
                if key == "Name" then
                    node.Name = value
                else
                    if node.props[key] == nil then table.insert(node.keys, key) end
                    node.props[key] = value
                end
                if real then real[key] = raw end
            end,
        })
        nodeOf[proxy] = node
        node.proxy = proxy
        return proxy
    end

    return Instance, roots
end

-- Fingerprint of a recorded tree. With useReal = true (Studio) the values are
-- read back from the real instances, so the check also proves Roblox accepted them.
function R.fingerprint(node, useReal: boolean?): string
    local lines = {}
    local function walk(n, path)
        local keys = table.clone(n.keys)
        table.sort(keys)
        local parts = {}
        for _, key in ipairs(keys) do
            local v = (useReal and n.real) and n.real[key] or n.props[key]
            table.insert(parts, key .. "=" .. R.canon(v))
        end
        -- theme-tag attributes, read back from the real instance in Studio for parity
        local attrKeys = table.clone(n.attrKeys)
        table.sort(attrKeys)
        for _, key in ipairs(attrKeys) do
            local v = (useReal and n.real) and n.real:GetAttribute(key) or n.attributes[key]
            table.insert(parts, "@" .. key .. "=" .. R.canon(v))
        end
        table.insert(lines, path .. "|" .. n.ClassName .. "|" .. table.concat(parts, ";"))
        for i, child in ipairs(n.children) do
            walk(child, path .. "/" .. i .. ":" .. child.Name)
        end
    end
    walk(node, node.Name)
    local text = table.concat(lines, "\n")
    local h = 0
    for i = 1, #text do h = (h * 31 + string.byte(text, i)) % 2147483647 end
    return string.format("%d instances, hash %d", #lines, h), text
end

-- Rojo .model.json table for a recorded tree (root name comes from the file name)
function R.toModel(node, isRoot: boolean?)
    local m = {}
    if not isRoot then m.name = node.Name end
    m.className = node.ClassName
    local keys = table.clone(node.keys)
    table.sort(keys)
    if #keys > 0 then
        m.properties = {}
        for _, key in ipairs(keys) do m.properties[key] = R.rojoValue(node.props[key]) end
    end
    if #node.attrKeys > 0 then
        local attrKeys = table.clone(node.attrKeys)
        table.sort(attrKeys)
        m.attributes = {}
        for _, key in ipairs(attrKeys) do m.attributes[key] = R.rojoValue(node.attributes[key]) end
    end
    if #node.children > 0 then
        m.children = {}
        for _, child in ipairs(node.children) do table.insert(m.children, R.toModel(child, false)) end
    end
    return m
end

return R
