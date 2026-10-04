--[[
	UpgradeConfig
	Permanent player upgrades bought with Coins.

	  ValuePerLevel   effect gained per level
	  BaseCost        cost of the first level
	  CostGrowth      cost multiplier per level
	  MaxLevel
	  RequiredLevels  optional { [upgradeLevel] = playerLevel } gates
	  LevelGateEvery  otherwise: every N upgrade levels require +LevelGateStep player levels
]]

local UpgradeConfig = {}

UpgradeConfig.Order = { "PeelPower", "PeelSpeed", "StickerCapacity", "Luck", "RewardMultiplier" }

UpgradeConfig.Upgrades = {
	PeelPower = {
		Id = "PeelPower",
		Name = "Peel Power",
		Description = "Stronger grip - increases how fast you peel.",
		Icon = "💪",
		Color = Color3.fromRGB(255, 96, 96),
		MaxLevel = 25,
		BaseCost = 100,
		CostGrowth = 1.32,
		ValuePerLevel = 0.08,
		Format = "Percent", -- +8% per level
		LevelGateEvery = 5,
		LevelGateStep = 4,
	},
	PeelSpeed = {
		Id = "PeelSpeed",
		Name = "Peel Speed",
		Description = "Better technique - reduces the time each sticker takes.",
		Icon = "⏱️",
		Color = Color3.fromRGB(80, 190, 255),
		MaxLevel = 20,
		BaseCost = 150,
		CostGrowth = 1.33,
		ValuePerLevel = 0.025,
		Format = "ReducePercent", -- -2.5% time per level (max -50%)
		LevelGateEvery = 5,
		LevelGateStep = 5,
	},
	StickerCapacity = {
		Id = "StickerCapacity",
		Name = "Sticker Capacity",
		Description = "Peel more stickers at the same time. Each one still peels on its own!",
		Icon = "🖐️",
		Color = Color3.fromRGB(255, 196, 60),
		MaxLevel = 5,
		BaseCost = 1200,
		CostGrowth = 2.6,
		ValuePerLevel = 1,
		Format = "Count", -- +1 sticker per level
		RequiredLevels = { [1] = 3, [2] = 7, [3] = 12, [4] = 18, [5] = 25 },
	},
	Luck = {
		Id = "Luck",
		Name = "Luck",
		Description = "More rare stickers and more LUCKY bonus rewards.",
		Icon = "🍀",
		Color = Color3.fromRGB(96, 220, 120),
		MaxLevel = 20,
		BaseCost = 200,
		CostGrowth = 1.36,
		ValuePerLevel = 0.05,
		Format = "Percent",
		LevelGateEvery = 5,
		LevelGateStep = 5,
	},
	RewardMultiplier = {
		Id = "RewardMultiplier",
		Name = "Reward Multiplier",
		Description = "Earn more Coins from every sticker and level.",
		Icon = "🪙",
		Color = Color3.fromRGB(255, 214, 72),
		MaxLevel = 25,
		BaseCost = 250,
		CostGrowth = 1.34,
		ValuePerLevel = 0.06,
		Format = "Percent",
		LevelGateEvery = 5,
		LevelGateStep = 4,
	},
}

function UpgradeConfig.Get(id: string)
	return UpgradeConfig.Upgrades[id]
end

function UpgradeConfig.IsValid(id: any): boolean
	return type(id) == "string" and UpgradeConfig.Upgrades[id] ~= nil
end

-- Cost to go from `currentLevel` to `currentLevel + 1`
function UpgradeConfig.GetCost(id: string, currentLevel: number): number
	local upgrade = UpgradeConfig.Upgrades[id]
	if not upgrade then
		return math.huge
	end
	local raw = upgrade.BaseCost * upgrade.CostGrowth ^ currentLevel
	return math.floor(raw / 5 + 0.5) * 5
end

-- Player level required to buy upgrade level `targetLevel`
function UpgradeConfig.GetRequiredPlayerLevel(id: string, targetLevel: number): number
	local upgrade = UpgradeConfig.Upgrades[id]
	if not upgrade then
		return math.huge
	end
	if upgrade.RequiredLevels then
		return upgrade.RequiredLevels[targetLevel] or 1
	end
	if upgrade.LevelGateEvery then
		local gate = math.floor((targetLevel - 1) / upgrade.LevelGateEvery)
		return 1 + gate * (upgrade.LevelGateStep or 5)
	end
	return 1
end

function UpgradeConfig.GetValue(id: string, level: number): number
	local upgrade = UpgradeConfig.Upgrades[id]
	if not upgrade then
		return 0
	end
	return upgrade.ValuePerLevel * level
end

function UpgradeConfig.FormatValue(id: string, level: number): string
	local upgrade = UpgradeConfig.Upgrades[id]
	if not upgrade then
		return ""
	end
	local value = UpgradeConfig.GetValue(id, level)
	if upgrade.Format == "Percent" then
		return string.format("+%d%%", math.floor(value * 100 + 0.5))
	elseif upgrade.Format == "ReducePercent" then
		return string.format("-%.1f%%", value * 100)
	elseif upgrade.Format == "Count" then
		return string.format("%d stickers", 1 + value)
	end
	return tostring(value)
end

return UpgradeConfig
