--[[
	Rarity
	Shared rarity tiers used by tools and stickers.
]]

local Rarity = {}

Rarity.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

Rarity.Info = {
	Common = { Name = "Common", Rank = 1, Color = Color3.fromRGB(196, 200, 210) },
	Uncommon = { Name = "Uncommon", Rank = 2, Color = Color3.fromRGB(96, 214, 112) },
	Rare = { Name = "Rare", Rank = 3, Color = Color3.fromRGB(72, 156, 255) },
	Epic = { Name = "Epic", Rank = 4, Color = Color3.fromRGB(176, 96, 255) },
	Legendary = { Name = "Legendary", Rank = 5, Color = Color3.fromRGB(255, 178, 46) },
	Mythic = { Name = "Mythic", Rank = 6, Color = Color3.fromRGB(255, 72, 132) },
}

function Rarity.Get(name: string)
	return Rarity.Info[name] or Rarity.Info.Common
end

function Rarity.Color(name: string): Color3
	return Rarity.Get(name).Color
end

return Rarity
