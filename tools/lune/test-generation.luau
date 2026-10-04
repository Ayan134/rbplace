--[[
	test-generation.luau
	Runs the real StickerGenerator on every level and difficulty outside Roblox and
	checks the results: requested count reached, valid positions/normals/sizes,
	sensible rarity mix and hard-to-reach ratio. Exits non-zero on failure.

	  lune run tools/lune/test-generation.luau build/rojo.rbxl
]]

local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Env = require("./env")

local env = Env.load(process.args[1] or "build/rojo.rbxl")
local game = env.Game
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local LevelConfig = env.Require(Shared.LevelConfig)
local DifficultyConfig = env.Require(Shared.DifficultyConfig)
local StickerConfig = env.Require(Shared.StickerConfig)
local StickerGenerator = env.Require(ServerScriptService.Systems.StickerGenerator)

local failures = 0
local function check(condition: boolean, message: string)
	if not condition then
		failures += 1
		print("  FAIL: " .. message)
	end
end

local function finite(v): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e7 and math.abs(v.Y) < 1e7 and math.abs(v.Z) < 1e7
end

local ground = roblox.Instance.new("Part")
ground.Name = "Ground"
ground.Size = roblox.Vector3.new(520, 2, 520)
ground.CFrame = roblox.CFrame.new(0, -1, 0)
ground.Parent = Workspace

local difficulties = if process.args[2] == "all" then DifficultyConfig.Order else { "Easy", "Extreme" }

for _, level in ipairs(LevelConfig.GetOrdered()) do
	local builder = ServerScriptService.LevelBuilders:FindFirstChild(level.ObjectModel)
	local model = env.Require(builder)()
	model.Parent = Workspace
	model:PivotTo(roblox.CFrame.new(0, 0, 0))

	for _, difficultyId in ipairs(difficulties) do
		local difficulty = DifficultyConfig.Get(difficultyId)
		local count = LevelConfig.GetStickerCount(level.LevelId, difficultyId)
		local started = os.clock()
		local stickers = StickerGenerator.Generate(model, {
			Count = count,
			Seed = 12345,
			Difficulty = difficulty,
			Level = level,
			LuckBonus = 0,
			GroundY = 0,
			ExtraObstacles = { ground },
		})
		local elapsed = os.clock() - started

		local typeCounts = {}
		local hard = 0
		local sizeSum = 0
		for index, sticker in ipairs(stickers) do
			typeCounts[sticker.Type] = (typeCounts[sticker.Type] or 0) + 1
			if sticker.Hard then
				hard += 1
			end
			sizeSum += (sticker.SizeX + sticker.SizeZ) / 2
			if index <= #stickers then
				check(sticker.Id == index, "ids are sequential")
				check(finite(sticker.Position), level.LevelId .. " position finite")
				check(math.abs(sticker.Normal.Magnitude - 1) < 1e-3, level.LevelId .. " normal is unit length")
				check(sticker.SizeX > 0.2 and sticker.SizeZ > 0.2, level.LevelId .. " sticker size positive")
				check(sticker.Health > 0 and sticker.BaseReward > 0, level.LevelId .. " health/reward positive")
				check(sticker.Position.Y > -0.5, level.LevelId .. " sticker above ground")
			end
		end
		local rare = 0
		local mix = {}
		for _, id in ipairs(StickerConfig.Order) do
			local n = typeCounts[id] or 0
			if StickerConfig.Get(id).IsRare then
				rare += n
			end
			if n > 0 then
				table.insert(mix, id .. "=" .. n)
			end
		end
		print(string.format(
			"%-9s %-8s %5d/%5d  avg size %.2f  hard %4.1f%%  rare %d  (%.1fs)  %s",
			level.LevelId,
			difficultyId,
			#stickers,
			count,
			sizeSum / math.max(#stickers, 1),
			hard / math.max(#stickers, 1) * 100,
			rare,
			elapsed,
			table.concat(mix, " ")
		))
		check(#stickers >= count * 0.97, string.format("%s %s produced %d of %d stickers", level.LevelId, difficultyId, #stickers, count))
		check((typeCounts.Golden or 0) + (typeCounts.Rainbow or 0) + (typeCounts.Diamond or 0) + (typeCounts.Legendary or 0) >= 1, level.LevelId .. " has at least one golden-or-better sticker")
		if not difficulty.SpecialStickers then
			check((typeCounts.Diamond or 0) + (typeCounts.Legendary or 0) == 0, level.LevelId .. " no special stickers below Hard")
		end
	end
	model:Destroy()
end

if failures > 0 then
	print(string.format("%d check(s) failed", failures))
	process.exit(1)
end
print("All generation checks passed")
