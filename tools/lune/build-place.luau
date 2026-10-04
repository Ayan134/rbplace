--[[
	build-place.luau
	Turns the Rojo-built place into the final StickerPeel.rbxl with the lobby and all
	level models already built, so they are visible and editable in Studio edit mode.

	  rojo build default.project.json -o build/rojo.rbxl
	  lune run tools/lune/build-place.luau build/rojo.rbxl StickerPeel.rbxl

	At runtime the game only builds what's missing, so hand-edited models are kept.
]]

local process = require("@lune/process")

local Env = require("./env")

local input = process.args[1] or "build/rojo.rbxl"
local output = process.args[2] or "StickerPeel.rbxl"

local env = Env.load(input)
local game = env.Game
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local levels = ServerStorage:FindFirstChild("Levels")
local builders = ServerScriptService:FindFirstChild("LevelBuilders")
local built = 0
for _, module in ipairs(builders:GetChildren()) do
	if module:IsA("ModuleScript") and module.Name ~= "BuildKit" and not levels:FindFirstChild(module.Name) then
		local model = env.Require(module)()
		model.Name = module.Name
		model.Parent = levels
		local parts = 0
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				parts += 1
			end
		end
		print(string.format("  built level %-10s %4d parts", module.Name, parts))
		built += 1
	end
end

local lobby = env.Require(ServerScriptService.Systems.LobbyBuilder).Build()
local lobbyParts = 0
for _, descendant in ipairs(lobby:GetDescendants()) do
	if descendant:IsA("BasePart") then
		lobbyParts += 1
	end
end
print(string.format("  built lobby %d parts", lobbyParts))

env.Save(output)
print(string.format("Saved %s (%d levels prebuilt)", output, built))
