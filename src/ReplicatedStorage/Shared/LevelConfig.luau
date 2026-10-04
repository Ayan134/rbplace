--[[
	LevelConfig
	Data-driven level definitions. Game logic never hardcodes levels - add a new entry here
	plus a model in ServerStorage.Levels (or a builder in ServerScriptService.LevelBuilders)
	and the level appears everywhere: level select, parties, rewards, unlocks.

	Fields:
	  LevelId             unique id, also the model name in ServerStorage.Levels
	  Order               display order / progression order
	  Name, Description   UI text
	  Size                "Small" | "Medium" | "Large" | "Huge" | "Colossal"
	  ObjectModel         model name in ServerStorage.Levels
	  BaseStickerCount    Normal-difficulty sticker count
	  StickerCounts       optional explicit count per difficulty (overrides the multiplier)
	  DifficultyMultiplier scales how strongly difficulty changes the sticker count
	  BaseReward          completion coins at Normal before bonuses
	  StickerReward       base coins per Small sticker
	  BaseXP              completion XP
	  RequiredLevel       player level needed to unlock
	  RecommendedPlayers  { min, max }
	  UnlockCost          coins to unlock (0 = free)
	  Stars               visual complexity rating 1..5
	  CameraMaxZoom       camera zoom limit inside the arena
	  Zones               display names of the surfaces stickers cover
]]

local DifficultyConfig = require(script.Parent.DifficultyConfig)
local Config = require(script.Parent.Config)

local LevelConfig = {}

LevelConfig.Levels = {
	{
		LevelId = "Fountain",
		Order = 1,
		Name = "City Fountain",
		Description = "A small city fountain someone covered in stickers overnight.",
		Size = "Small",
		ObjectModel = "Fountain",
		BaseStickerCount = 500,
		StickerCounts = { Easy = 300, Normal = 500, Hard = 750, Extreme = 1000 },
		DifficultyMultiplier = 1,
		BaseReward = 450,
		StickerReward = 2,
		BaseXP = 120,
		RequiredLevel = 1,
		RecommendedPlayers = { 1, 2 },
		UnlockCost = 0,
		Stars = 1,
		ThemeColor = Color3.fromRGB(86, 196, 255),
		CameraMaxZoom = 70,
		Zones = { "Basin", "Pillar", "Bowls", "Statue" },
	},
	{
		LevelId = "Car",
		Order = 2,
		Name = "Sports Car",
		Description = "A huge sports car - body, wheels, glass, hood, roof, bumpers and doors.",
		Size = "Medium",
		ObjectModel = "Car",
		BaseStickerCount = 700,
		StickerCounts = { Easy = 420, Normal = 700, Hard = 1050, Extreme = 1400 },
		DifficultyMultiplier = 1,
		BaseReward = 850,
		StickerReward = 3,
		BaseXP = 200,
		RequiredLevel = 3,
		RecommendedPlayers = { 1, 3 },
		UnlockCost = 1500,
		Stars = 2,
		ThemeColor = Color3.fromRGB(255, 82, 82),
		CameraMaxZoom = 80,
		Zones = { "Body", "Wheels", "Glass", "Hood", "Roof", "Bumpers", "Doors" },
	},
	{
		LevelId = "Statue",
		Order = 3,
		Name = "Grand Statue",
		Description = "A giant hero statue on a pedestal. Stickers cover every inch.",
		Size = "Large",
		ObjectModel = "Statue",
		BaseStickerCount = 900,
		DifficultyMultiplier = 1,
		BaseReward = 1400,
		StickerReward = 4,
		BaseXP = 320,
		RequiredLevel = 6,
		RecommendedPlayers = { 2, 3 },
		UnlockCost = 4000,
		Stars = 3,
		ThemeColor = Color3.fromRGB(200, 200, 150),
		CameraMaxZoom = 110,
		Zones = { "Pedestal", "Legs", "Body", "Arms", "Head", "Torch" },
	},
	{
		LevelId = "House",
		Order = 4,
		Name = "Cozy House",
		Description = "Walls, windows, doors, roof, garage, balcony and fence.",
		Size = "Large",
		ObjectModel = "House",
		BaseStickerCount = 1200,
		DifficultyMultiplier = 1,
		BaseReward = 2200,
		StickerReward = 5,
		BaseXP = 480,
		RequiredLevel = 10,
		RecommendedPlayers = { 2, 4 },
		UnlockCost = 9000,
		Stars = 3,
		ThemeColor = Color3.fromRGB(255, 196, 120),
		CameraMaxZoom = 110,
		Zones = { "Walls", "Windows", "Doors", "Roof", "Garage", "Balcony", "Fence" },
	},
	{
		LevelId = "Mansion",
		Order = 5,
		Name = "Mega Mansion",
		Description = "A huge mansion with columns, wings and a pool. Bring friends!",
		Size = "Huge",
		ObjectModel = "Mansion",
		BaseStickerCount = 2000,
		DifficultyMultiplier = 1,
		BaseReward = 3800,
		StickerReward = 7,
		BaseXP = 760,
		RequiredLevel = 15,
		RecommendedPlayers = { 3, 4 },
		UnlockCost = 20000,
		Stars = 4,
		ThemeColor = Color3.fromRGB(236, 236, 255),
		CameraMaxZoom = 140,
		Zones = { "Walls", "Columns", "Roof", "Windows", "Wings", "Pool", "Stairs" },
	},
	{
		LevelId = "Airplane",
		Order = 6,
		Name = "Jumbo Airplane",
		Description = "A gigantic airliner: wings, fuselage, tail, engines, cockpit and landing gear.",
		Size = "Huge",
		ObjectModel = "Airplane",
		BaseStickerCount = 2600,
		DifficultyMultiplier = 1,
		BaseReward = 5500,
		StickerReward = 9,
		BaseXP = 1100,
		RequiredLevel = 20,
		RecommendedPlayers = { 3, 4 },
		UnlockCost = 40000,
		Stars = 4,
		ThemeColor = Color3.fromRGB(120, 200, 255),
		CameraMaxZoom = 170,
		Zones = { "Wings", "Fuselage", "Tail", "Engines", "Cockpit", "Landing Gear" },
	},
	{
		LevelId = "Palace",
		Order = 7,
		Name = "Royal Palace",
		Description = "An enormous palace with towers and golden domes. The ultimate challenge.",
		Size = "Colossal",
		ObjectModel = "Palace",
		BaseStickerCount = 3000,
		DifficultyMultiplier = 1,
		BaseReward = 9000,
		StickerReward = 12,
		BaseXP = 1800,
		RequiredLevel = 28,
		RecommendedPlayers = { 4, 4 },
		UnlockCost = 90000,
		Stars = 5,
		ThemeColor = Color3.fromRGB(255, 214, 90),
		CameraMaxZoom = 200,
		Zones = { "Towers", "Domes", "Walls", "Gate", "Courtyard", "Balconies" },
	},
}

local byId = {}
for _, level in ipairs(LevelConfig.Levels) do
	byId[level.LevelId] = level
end
table.sort(LevelConfig.Levels, function(a, b)
	return a.Order < b.Order
end)

function LevelConfig.Get(levelId: string)
	return byId[levelId]
end

function LevelConfig.IsValid(levelId: any): boolean
	return type(levelId) == "string" and byId[levelId] ~= nil
end

function LevelConfig.GetOrdered()
	return LevelConfig.Levels
end

function LevelConfig.GetNext(levelId: string)
	local level = byId[levelId]
	if not level then
		return nil
	end
	for _, other in ipairs(LevelConfig.Levels) do
		if other.Order == level.Order + 1 then
			return other
		end
	end
	return nil
end

function LevelConfig.GetStickerCount(levelId: string, difficultyId: string): number
	local level = byId[levelId]
	local difficulty = DifficultyConfig.Get(difficultyId)
	if not level or not difficulty then
		return 0
	end
	local count
	if level.StickerCounts and level.StickerCounts[difficultyId] then
		count = level.StickerCounts[difficultyId]
	else
		local multiplier = 1 + (difficulty.StickerMultiplier - 1) * (level.DifficultyMultiplier or 1)
		count = math.floor(level.BaseStickerCount * multiplier / 10 + 0.5) * 10
	end
	return math.clamp(count, 1, Config.Sticker.MaxPerLevel)
end

function LevelConfig.GetCompletionReward(levelId: string, difficultyId: string): number
	local level = byId[levelId]
	local difficulty = DifficultyConfig.Get(difficultyId)
	if not level or not difficulty then
		return 0
	end
	return math.floor(level.BaseReward * difficulty.RewardMultiplier)
end

-- Rough estimate of the total coins a run pays out (stickers + completion), for UI display.
function LevelConfig.EstimateTotalReward(levelId: string, difficultyId: string): number
	local level = byId[levelId]
	local difficulty = DifficultyConfig.Get(difficultyId)
	if not level or not difficulty then
		return 0
	end
	local stickers = LevelConfig.GetStickerCount(levelId, difficultyId)
	local averageStickerValue = level.StickerReward * 1.45 * difficulty.RewardMultiplier
	return math.floor((stickers * averageStickerValue + LevelConfig.GetCompletionReward(levelId, difficultyId)) / 50 + 0.5)
		* 50
end

function LevelConfig.GetParTime(levelId: string, difficultyId: string, playerCount: number): number
	local stickers = LevelConfig.GetStickerCount(levelId, difficultyId)
	return stickers * Config.Match.ParSecondsPerSticker / math.max(1, playerCount) ^ 0.8
end

function LevelConfig.RecordKey(levelId: string, difficultyId: string): string
	return levelId .. "_" .. difficultyId
end

return LevelConfig
