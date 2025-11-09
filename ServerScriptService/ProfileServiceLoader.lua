local ServerScriptService = game:GetService("ServerScriptService")
local ok, mod = pcall(function() return require(ServerScriptService:WaitForChild("ProfileService")) end)
if ok and mod then return mod end
local fallbackOk, assetMod = pcall(function() return require(17503543948) end)
if fallbackOk and assetMod then return assetMod end
error("ProfileService not found. Insert it into ServerScriptService or update asset id in ProfileServiceLoader.lua.")
