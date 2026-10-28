--[[
    build_models.luau — regenerate StarterGui/*.model.json from the GUI builders.

    Run through the driver:  python3 Tools/StaticGui/build_models.py <path-to-luau>
    It feeds the builder sources in, splits the "@@@@MODEL <Name>" blocks this
    prints into StarterGui/<Name>.model.json and prints each fingerprint.
]]

local R = require("./GuiRecorder")

-- Minimal mock of the Roblox datatypes the builders use
local function kind(k, t) t.__kind = k; return t end
UDim2 = { new = function(xs, xo, ys, yo)
    return kind("UDim2", { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo } })
end }
UDim = { new = function(s, o) return kind("UDim", { Scale = s, Offset = o }) end }
Vector2 = { new = function(x, y) return kind("Vector2", { X = x, Y = y }) end }
Rect = { new = function(a, b, c, d) return kind("Rect", { Min = { X = a, Y = b }, Max = { X = c, Y = d } }) end }
Color3 = { fromRGB = function(r, g, b) return kind("Color3", { R = r / 255, G = g / 255, B = b / 255 }) end }
Enum = setmetatable({}, { __index = function(_, enumType)
    return setmetatable({}, { __index = function(_, name)
        return kind("EnumItem", { EnumType = enumType, Name = name })
    end })
end })
game = { GetService = function(_, name) return { Name = name } end }

-- JSON with a stable key order: name, className, properties (sorted), children
local function encode(v, indent)
    indent = indent or ""
    local t = type(v)
    if t == "string" then
        return '"' .. v:gsub('[%c"\\]', function(c)
            local map = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t", ["\r"] = "\\r" }
            return map[c] or string.format("\\u%04x", string.byte(c))
        end) .. '"'
    elseif t == "number" then
        if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
        local s = string.format("%.6f", v):gsub("0+$", ""):gsub("%.$", "")
        return s
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        if #v > 0 or next(v) == nil then
            local flat = true
            for _, x in ipairs(v) do if type(x) == "table" and (x.className or x.name) then flat = false end end
            local items = {}
            for _, x in ipairs(v) do table.insert(items, encode(x, indent .. "  ")) end
            if flat then return "[" .. table.concat(items, ", ") .. "]" end
            return "[\n" .. indent .. "  " .. table.concat(items, ",\n" .. indent .. "  ") .. "\n" .. indent .. "]"
        end
        local keys = {}
        if v.name ~= nil then table.insert(keys, "name") end
        if v.className ~= nil then table.insert(keys, "className") end
        if v.properties ~= nil then table.insert(keys, "properties") end
        if v.children ~= nil then table.insert(keys, "children") end
        if #keys == 0 then
            for k in pairs(v) do table.insert(keys, k) end
            table.sort(keys)
            -- typed value such as {"UDim2": [[0, 20], [0, 20]]}: keep it on one line
            if #keys == 1 and type(v[keys[1]]) == "table" and #v[keys[1]] > 0 then
                return '{"' .. keys[1] .. '": ' .. encode(v[keys[1]], indent) .. "}"
            end
        end
        local items = {}
        for _, k in ipairs(keys) do
            table.insert(items, '"' .. k .. '": ' .. encode(v[k], indent .. "  "))
        end
        return "{\n" .. indent .. "  " .. table.concat(items, ",\n" .. indent .. "  ") .. "\n" .. indent .. "}"
    end
    error("cannot encode " .. t)
end

-- The luau CLI has no file I/O: build_models.py defines SOURCES before this file runs.
local sources = SOURCES or {}
for _, entry in ipairs(sources) do
    local fn = assert(loadstring(R.transform(entry.src), "=" .. entry.name))()
    local Instance, roots = R.new(nil)
    fn({ Name = "PlayerGui", FindFirstChild = function() return nil end }, Instance)
    for _, root in ipairs(roots) do
        local summary = R.fingerprint(root, false)
        local model = R.toModel(root, true)
        model.name = nil
        print("@@@@MODEL " .. root.Name .. " " .. summary)
        print(encode(model))
        print("@@@@END")
    end
end
