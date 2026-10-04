--[[
	StickerConfig
	Sticker types, their rarity, peel health, reward multipliers and visuals.

	Weight              base spawn weight (Small/Medium/Large are overridden by difficulty SizeWeights)
	IsRare              rare weights are scaled by difficulty RareChanceMultiplier and party luck
	SizeMultiplier      relative to the level's computed base sticker size
	Health              peel HP (divided by player's peel rate => seconds)
	RewardMultiplier    multiplied with level StickerReward
	XP                  XP per sticker
	RequiredToolTier    minimum tool tier (difficulty ToolTierBonus is added for rare types)
	Special             only spawns when difficulty.SpecialStickers is true
	Notify              announce to the whole team when peeled
]]

local StickerConfig = {}

StickerConfig.Order = { "Small", "Medium", "Large", "Rare", "Golden", "Rainbow", "Diamond", "Legendary" }

StickerConfig.Types = {
	Small = {
		Id = "Small",
		Index = 1,
		DisplayName = "Small Sticker",
		Rarity = "Common",
		Weight = 50,
		IsRare = false,
		SizeMultiplier = 0.78,
		Health = 1.0,
		RewardMultiplier = 1,
		XP = 1,
		RequiredToolTier = 0,
		Material = Enum.Material.SmoothPlastic,
	},
	Medium = {
		Id = "Medium",
		Index = 2,
		DisplayName = "Sticker",
		Rarity = "Common",
		Weight = 32,
		IsRare = false,
		SizeMultiplier = 1.0,
		Health = 1.6,
		RewardMultiplier = 1.5,
		XP = 1,
		RequiredToolTier = 0,
		Material = Enum.Material.SmoothPlastic,
	},
	Large = {
		Id = "Large",
		Index = 3,
		DisplayName = "Large Sticker",
		Rarity = "Uncommon",
		Weight = 18,
		IsRare = false,
		SizeMultiplier = 1.38,
		Health = 2.4,
		RewardMultiplier = 2,
		XP = 2,
		RequiredToolTier = 0,
		Material = Enum.Material.SmoothPlastic,
	},
	Rare = {
		Id = "Rare",
		Index = 4,
		DisplayName = "Rare Sticker",
		Rarity = "Rare",
		Weight = 2.6,
		IsRare = true,
		SizeMultiplier = 1.05,
		Health = 3.0,
		RewardMultiplier = 3,
		XP = 4,
		RequiredToolTier = 0,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(150, 90, 255),
		Sparkle = true,
	},
	Golden = {
		Id = "Golden",
		Index = 5,
		DisplayName = "GOLDEN STICKER",
		Rarity = "Epic",
		Weight = 0.9,
		IsRare = true,
		SizeMultiplier = 1.1,
		Health = 4.0,
		RewardMultiplier = 5,
		XP = 8,
		RequiredToolTier = 0,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 40),
		Sparkle = true,
		Notify = true,
	},
	Rainbow = {
		Id = "Rainbow",
		Index = 6,
		DisplayName = "RAINBOW STICKER",
		Rarity = "Legendary",
		Weight = 0.32,
		IsRare = true,
		SizeMultiplier = 1.15,
		Health = 5.0,
		RewardMultiplier = 10,
		XP = 15,
		RequiredToolTier = 1,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 80, 200),
		Sparkle = true,
		Rainbow = true,
		Notify = true,
	},
	Diamond = {
		Id = "Diamond",
		Index = 7,
		DisplayName = "DIAMOND STICKER",
		Rarity = "Mythic",
		Weight = 0.09,
		IsRare = true,
		SizeMultiplier = 1.15,
		Health = 7.0,
		RewardMultiplier = 25,
		XP = 30,
		RequiredToolTier = 1,
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(150, 240, 255),
		Sparkle = true,
		Glow = true,
		Special = true,
		Notify = true,
	},
	Legendary = {
		Id = "Legendary",
		Index = 8,
		DisplayName = "LEGENDARY STICKER",
		Rarity = "Mythic",
		Weight = 0.035,
		IsRare = true,
		SizeMultiplier = 1.25,
		Health = 9.0,
		RewardMultiplier = 50,
		XP = 50,
		RequiredToolTier = 2,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 110, 40),
		Sparkle = true,
		Glow = true,
		Special = true,
		Notify = true,
	},
}

-- Palette for regular stickers (index is replicated, so only append to this list)
StickerConfig.Palette = {
	Color3.fromRGB(255, 92, 120),
	Color3.fromRGB(255, 160, 64),
	Color3.fromRGB(255, 220, 72),
	Color3.fromRGB(120, 224, 96),
	Color3.fromRGB(64, 200, 200),
	Color3.fromRGB(72, 150, 255),
	Color3.fromRGB(160, 110, 255),
	Color3.fromRGB(255, 120, 220),
	Color3.fromRGB(250, 250, 250),
	Color3.fromRGB(40, 44, 60),
	Color3.fromRGB(255, 130, 96),
	Color3.fromRGB(140, 230, 210),
}

local byIndex = {}
for _, id in ipairs(StickerConfig.Order) do
	local info = StickerConfig.Types[id]
	byIndex[info.Index] = info
end

function StickerConfig.Get(id: string)
	return StickerConfig.Types[id]
end

function StickerConfig.GetByIndex(index: number)
	return byIndex[index]
end

function StickerConfig.GetRequiredToolTier(typeId: string, difficulty): number
	local info = StickerConfig.Types[typeId]
	if not info then
		return 0
	end
	local required = info.RequiredToolTier
	if info.IsRare and difficulty then
		required += difficulty.ToolTierBonus
	end
	return required
end

function StickerConfig.GetColor(info, colorIndex: number): Color3
	if info.Color then
		return info.Color
	end
	return StickerConfig.Palette[((colorIndex - 1) % #StickerConfig.Palette) + 1]
end

return StickerConfig
