--[[
	DifficultyConfig
	Every difficulty affects much more than the sticker count:
	  StickerMultiplier     - number of stickers
	  SizeMultiplier        - sticker size (Easy = big stickers, Extreme = tiny stickers)
	  SizeWeights           - mix of Small / Medium / Large stickers
	  HealthMultiplier      - glue strength => peel speed
	  HardToReachWeight     - how many stickers end up on roofs, undersides, high spots
	  RewardMultiplier      - coin reward
	  XPMultiplier          - XP reward
	  RareChanceMultiplier  - chance for Rare / Golden / Rainbow / Diamond / Legendary stickers
	  ToolTierBonus         - added to the tool tier required for rare stickers
	  SpecialStickers       - enables Diamond / Legendary stickers
]]

local DifficultyConfig = {}

DifficultyConfig.Order = { "Easy", "Normal", "Hard", "Extreme" }

DifficultyConfig.Difficulties = {
	Easy = {
		Id = "Easy",
		DisplayName = "EASY",
		Stars = 1,
		Color = Color3.fromRGB(92, 214, 120),
		Description = "Lots of big stickers in easy places. Great for warming up.",
		RequiredLevel = 1,
		StickerMultiplier = 0.6,
		SizeMultiplier = 1.25,
		SizeWeights = { Small = 22, Medium = 40, Large = 38 },
		HealthMultiplier = 1.15,
		HardToReachWeight = 0.35,
		RewardMultiplier = 1.0,
		XPMultiplier = 1.0,
		RareChanceMultiplier = 0.8,
		ToolTierBonus = 0,
		RecommendedToolTier = 0,
		SpecialStickers = false,
	},
	Normal = {
		Id = "Normal",
		DisplayName = "NORMAL",
		Stars = 2,
		Color = Color3.fromRGB(80, 170, 255),
		Description = "The standard sticker-peeling experience.",
		RequiredLevel = 1,
		StickerMultiplier = 1.0,
		SizeMultiplier = 1.0,
		SizeWeights = { Small = 48, Medium = 34, Large = 18 },
		HealthMultiplier = 1.0,
		HardToReachWeight = 1.0,
		RewardMultiplier = 1.35,
		XPMultiplier = 1.25,
		RareChanceMultiplier = 1.0,
		ToolTierBonus = 0,
		RecommendedToolTier = 1,
		SpecialStickers = false,
	},
	Hard = {
		Id = "Hard",
		DisplayName = "HARD",
		Stars = 3,
		Color = Color3.fromRGB(255, 150, 56),
		Description = "More, smaller and stickier stickers. Hidden spots everywhere.",
		RequiredLevel = 5,
		StickerMultiplier = 1.5,
		SizeMultiplier = 0.85,
		SizeWeights = { Small = 62, Medium = 28, Large = 10 },
		HealthMultiplier = 1.2,
		HardToReachWeight = 1.9,
		RewardMultiplier = 1.9,
		XPMultiplier = 1.6,
		RareChanceMultiplier = 1.4,
		ToolTierBonus = 1,
		RecommendedToolTier = 2,
		SpecialStickers = true,
	},
	Extreme = {
		Id = "Extreme",
		DisplayName = "EXTREME",
		Stars = 4,
		Color = Color3.fromRGB(255, 64, 96),
		Description = "A sea of tiny super-glued stickers. Special rare stickers spawn!",
		RequiredLevel = 12,
		StickerMultiplier = 2.0,
		SizeMultiplier = 0.72,
		SizeWeights = { Small = 72, Medium = 22, Large = 6 },
		HealthMultiplier = 1.45,
		HardToReachWeight = 3.0,
		RewardMultiplier = 2.8,
		XPMultiplier = 2.2,
		RareChanceMultiplier = 1.9,
		ToolTierBonus = 2,
		RecommendedToolTier = 3,
		SpecialStickers = true,
	},
}

function DifficultyConfig.Get(id: string)
	return DifficultyConfig.Difficulties[id]
end

function DifficultyConfig.IsValid(id: any): boolean
	return type(id) == "string" and DifficultyConfig.Difficulties[id] ~= nil
end

return DifficultyConfig
