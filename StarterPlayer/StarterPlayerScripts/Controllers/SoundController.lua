--[[
    SoundController.lua
    Location: StarterPlayer/StarterPlayerScripts/Controllers/

    PURPOSE:
    Plays short UI sounds (button press, confirmed purchase).
    - One reusable Sound under SoundService, created lazily on first use
    - Ids and volume come from ReplicatedStorage/UISound (empty id = silent)
    - Never yields and never errors: a bad id just plays nothing

    DEPENDENCIES:
    - UISound config module (ReplicatedStorage)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UISound = require(ReplicatedStorage:WaitForChild("UISound"))

local SoundController = {}

local PRESS_MIN_INTERVAL = 0.06 -- seconds; presses closer than this are dropped
local sound = nil
local lastPress = 0

-- Single place that decides whether UI sound is allowed.
-- No game sound setting exists yet; wire the real one here later.
local function isSoundEnabled()
    return true
end

local function getSound()
    if not sound or not sound.Parent then
        sound = Instance.new("Sound")
        sound.Name = "UISound"
        sound.Parent = SoundService
    end
    return sound
end

local function playId(id)
    if id == nil or id == "" then
        return
    end
    pcall(function()
        local s = getSound()
        s.Volume = UISound.Volume
        s.SoundId = id
        s:Play()
    end)
end

function SoundController.Press()
    if not isSoundEnabled() then
        return
    end
    local now = os.clock()
    if now - lastPress < PRESS_MIN_INTERVAL then
        return
    end
    lastPress = now
    playId(UISound.Press)
end

function SoundController.Purchase()
    if not isSoundEnabled() then
        return
    end
    playId(UISound.Purchase)
end

return SoundController
