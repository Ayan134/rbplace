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
		Weight = 1.5,
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
		Weight = 0.4,
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
		Weight = 0.13,
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
		Weight = 0.035,
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
		Weight = 0.012,
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
	Color3.fromRGB(255, 92, 140), -- pink
	Color3.fromRGB(255, 150, 50), -- orange
	Color3.fromRGB(255, 214, 46), -- yellow
	Color3.fromRGB(110, 214, 80), -- green
	Color3.fromRGB(40, 196, 220), -- cyan
	Color3.fromRGB(70, 130, 255), -- blue
	Color3.fromRGB(160, 100, 255), -- purple
	Color3.fromRGB(255, 110, 200), -- magenta
	Color3.fromRGB(240, 70, 70), -- red
	Color3.fromRGB(60, 64, 90), -- night
	Color3.fromRGB(255, 255, 255), -- white
	Color3.fromRGB(30, 200, 150), -- teal
}

--[[
	Sticker artwork.
	Every sticker shows a picture. By default pictures are emoji glyphs, which Roblox
	renders with its built-in emoji font - no uploaded assets needed.

	To use real image stickers, put image asset ids in `Images`
	(e.g. "rbxassetid://1234567890" - use the IMAGE id, not the decal id; in Studio paste
	the decal into a Decal.Texture and copy the resulting id). When `Images` is not empty,
	regular stickers use them instead of emoji.
]]
StickerConfig.Designs = {
	"😀", "😎", "🥳", "😍", "🤩", "😺", "🐶", "🦊", "🐼", "🐸", "🐙", "🦄",
	"🐝", "🦋", "🌈", "⭐", "❤️", "💜", "💙", "💚", "🍕", "🍩", "🍉", "🍓",
	"🍒", "🍦", "🚀", "⚡", "🔥", "🎈", "🎮", "👾", "🌸", "🌻", "🍀", "🎵",
}

StickerConfig.Images = {
	-- "rbxassetid://...",
}

-- Special stickers always use their own artwork
StickerConfig.SpecialDesigns = {
	Rare = "💫",
	Golden = "🏆",
	Rainbow = "🌈",
	Diamond = "💎",
	Legendary = "👑",
}

-- Distinct (paper color, artwork) combinations; replicated as one byte, so <= 255.
StickerConfig.VariantCount = 252

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

function StickerConfig.GetColor(info, variant: number): Color3
	if info.Color then
		return info.Color
	end
	-- Artwork cycles fastest, paper color changes every #Designs variants
	local palette = StickerConfig.Palette
	return palette[(math.floor((variant - 1) / #StickerConfig.Designs) % #palette) + 1]
end

-- Returns kind ("Emoji" | "Image") and the content for a sticker variant.
function StickerConfig.GetDesign(info, variant: number): (string, string)
	local special = StickerConfig.SpecialDesigns[info.Id]
	if special then
		return "Emoji", special
	end
	local images = StickerConfig.Images
	if #images > 0 then
		return "Image", images[((variant - 1) % #images) + 1]
	end
	local designs = StickerConfig.Designs
	return "Emoji", designs[((variant - 1) % #designs) + 1]
end

return StickerConfig
