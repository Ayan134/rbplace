--[[
	BagConfig
	Bags hold the stickers a player peels. A full bag must be emptied into a trash
	can, which pays out the stickers' value. Bigger bags mean fewer trips.

	  Name, Description
	  Capacity    stickers the bag holds
	  Price, Currency ("Coins" | "Gems")
	  Icon        emoji used in compact UI
	  Model       look built by Shared.BagModels ("Pocket" | "PaperBag" | "Bucket" | "Sack" | "Bin")
	  Color       main color of the model
	  Shiny       sparkles on the shop display
]]

local BagConfig = {}

BagConfig.Order = { "Pocket", "PaperBag", "BlueBucket", "GoldenBucket", "Sack", "SunnyBag", "MegaBin" }

BagConfig.Bags = {
	Pocket = {
		Id = "Pocket",
		Name = "Pockets",
		Description = "Room for a handful of stickers.",
		Capacity = 25,
		Price = 0,
		Currency = "Coins",
		Icon = "👖",
		Model = "Pocket",
		Color = Color3.fromRGB(80, 110, 170),
	},
	PaperBag = {
		Id = "PaperBag",
		Name = "Paper Bag",
		Description = "A crinkly paper bag. More than twice your pockets.",
		Capacity = 60,
		Price = 150,
		Currency = "Coins",
		Icon = "🛍️",
		Model = "PaperBag",
		Color = Color3.fromRGB(196, 156, 108),
	},
	BlueBucket = {
		Id = "BlueBucket",
		Name = "Blue Bucket",
		Description = "A sturdy plastic bucket.",
		Capacity = 120,
		Price = 600,
		Currency = "Coins",
		Icon = "🪣",
		Model = "Bucket",
		Color = Color3.fromRGB(40, 120, 230),
	},
	GoldenBucket = {
		Id = "GoldenBucket",
		Name = "Golden Bucket",
		Description = "Shiny and roomy.",
		Capacity = 250,
		Price = 2500,
		Currency = "Coins",
		Icon = "🏆",
		Model = "Bucket",
		Color = Color3.fromRGB(250, 196, 40),
		Shiny = true,
	},
	Sack = {
		Id = "Sack",
		Name = "Big Sack",
		Description = "A huge canvas sack.",
		Capacity = 500,
		Price = 9000,
		Currency = "Coins",
		Icon = "💰",
		Model = "Sack",
		Color = Color3.fromRGB(214, 196, 160),
	},
	SunnyBag = {
		Id = "SunnyBag",
		Name = "Sunny Bag",
		Description = "Glows like the sun. Holds a thousand stickers.",
		Capacity = 1000,
		Price = 30000,
		Currency = "Coins",
		Icon = "🌞",
		Model = "Sack",
		Color = Color3.fromRGB(255, 214, 60),
		Shiny = true,
	},
	MegaBin = {
		Id = "MegaBin",
		Name = "Mega Bin",
		Description = "A wheelie bin on your back. Why not.",
		Capacity = 2500,
		Price = 120000,
		Currency = "Coins",
		Icon = "🗑️",
		Model = "Bin",
		Color = Color3.fromRGB(60, 170, 90),
	},
}

function BagConfig.Get(id: string?)
	return id and BagConfig.Bags[id] or nil
end

function BagConfig.IsValid(id: any): boolean
	return type(id) == "string" and BagConfig.Bags[id] ~= nil
end

return BagConfig
