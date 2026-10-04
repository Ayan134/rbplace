--[[
	ToolConfig
	Peeling tools. Each tool has:
	  Name, Description, Rarity, Tier
	  PeelSpeed   bonus peel rate (0.2 = +20%)
	  MultiPeel   extra simultaneous stickers
	  Luck        extra luck
	  Price, Currency ("Coins" | "Gems")
	  RequiredLevel
	  Icon        emoji icon used in compact UI
	  Model       model id built by Shared.ToolModels (3D model in hand + UI previews)
]]

local ToolConfig = {}

ToolConfig.Order = { "Hand", "PlasticScraper", "MetalScraper", "HeatGun", "ElectricPeeler", "LaserPeeler" }

ToolConfig.Tools = {
	Hand = {
		Id = "Hand",
		Name = "Hand",
		Description = "Your trusty fingernails. Slow, but free.",
		Rarity = "Common",
		Tier = 0,
		PeelSpeed = 0,
		MultiPeel = 0,
		Luck = 0,
		Price = 0,
		Currency = "Coins",
		RequiredLevel = 1,
		Icon = "✋",
		Model = "Hand",
	},
	PlasticScraper = {
		Id = "PlasticScraper",
		Name = "Plastic Scraper",
		Description = "A small plastic scraper. Gets under sticker edges easily.",
		Rarity = "Uncommon",
		Tier = 1,
		PeelSpeed = 0.2,
		MultiPeel = 0,
		Luck = 0,
		Price = 750,
		Currency = "Coins",
		RequiredLevel = 2,
		Icon = "🔷",
		Model = "PlasticScraper",
	},
	MetalScraper = {
		Id = "MetalScraper",
		Name = "Metal Scraper",
		Description = "A sharp steel scraper for stubborn stickers.",
		Rarity = "Rare",
		Tier = 2,
		PeelSpeed = 0.4,
		MultiPeel = 0,
		Luck = 0.02,
		Price = 4000,
		Currency = "Coins",
		RequiredLevel = 5,
		Icon = "🔩",
		Model = "MetalScraper",
	},
	HeatGun = {
		Id = "HeatGun",
		Name = "Heat Gun",
		Description = "Melts the glue so stickers slide right off. +1 multi-peel.",
		Rarity = "Epic",
		Tier = 3,
		PeelSpeed = 0.6,
		MultiPeel = 1,
		Luck = 0.05,
		Price = 15000,
		Currency = "Coins",
		RequiredLevel = 10,
		Icon = "🔥",
		Model = "HeatGun",
	},
	ElectricPeeler = {
		Id = "ElectricPeeler",
		Name = "Electric Peeler",
		Description = "A buzzing electric peeler. +1 multi-peel.",
		Rarity = "Legendary",
		Tier = 4,
		PeelSpeed = 1.0,
		MultiPeel = 1,
		Luck = 0.08,
		Price = 50000,
		Currency = "Coins",
		RequiredLevel = 18,
		Icon = "⚡",
		Model = "ElectricPeeler",
	},
	LaserPeeler = {
		Id = "LaserPeeler",
		Name = "Laser Peeler",
		Description = "Very rare sci-fi tech. Vaporizes glue instantly-ish. +2 multi-peel.",
		Rarity = "Mythic",
		Tier = 5,
		PeelSpeed = 2.0,
		MultiPeel = 2,
		Luck = 0.15,
		Price = 1200,
		Currency = "Gems",
		RequiredLevel = 25,
		Icon = "🌟",
		Model = "LaserPeeler",
	},
}

function ToolConfig.Get(id: string)
	return ToolConfig.Tools[id]
end

function ToolConfig.IsValid(id: any): boolean
	return type(id) == "string" and ToolConfig.Tools[id] ~= nil
end

function ToolConfig.GetByTier(tier: number)
	for _, id in ipairs(ToolConfig.Order) do
		local tool = ToolConfig.Tools[id]
		if tool.Tier == tier then
			return tool
		end
	end
	return nil
end

return ToolConfig
