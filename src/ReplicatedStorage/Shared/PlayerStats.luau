--[[
	PlayerStats
	Derives gameplay stats from saved data (upgrades + equipped tool).
	Used by the server as the authority, and by the client for UI previews and
	for predicting peel duration so the animation feels instant.
]]

local Config = require(script.Parent.Config)
local ToolConfig = require(script.Parent.ToolConfig)
local UpgradeConfig = require(script.Parent.UpgradeConfig)

local PlayerStats = {}

export type Stats = {
	PeelRate: number, -- HP per second
	DurationFactor: number, -- multiplier on time (from Peel Speed)
	Capacity: number, -- simultaneous stickers
	Luck: number, -- 0.25 = +25%
	RewardMultiplier: number,
	ToolTier: number,
	ToolId: string,
}

local function upgradeLevel(data, id: string): number
	return (data and data.Upgrades and data.Upgrades[id]) or 0
end

function PlayerStats.Compute(data): Stats
	local tool = ToolConfig.Get(data and data.EquippedTool or "Hand") or ToolConfig.Tools.Hand

	local power = UpgradeConfig.GetValue("PeelPower", upgradeLevel(data, "PeelPower"))
	local speed = UpgradeConfig.GetValue("PeelSpeed", upgradeLevel(data, "PeelSpeed"))
	local capacity = UpgradeConfig.GetValue("StickerCapacity", upgradeLevel(data, "StickerCapacity"))
	local luck = UpgradeConfig.GetValue("Luck", upgradeLevel(data, "Luck"))
	local reward = UpgradeConfig.GetValue("RewardMultiplier", upgradeLevel(data, "RewardMultiplier"))

	return {
		PeelRate = Config.Peel.BasePeelRate * (1 + power) * (1 + tool.PeelSpeed),
		DurationFactor = math.max(0.4, 1 - speed),
		Capacity = math.clamp(1 + capacity + tool.MultiPeel, 1, Config.Peel.MaxCapacity),
		Luck = luck + tool.Luck,
		RewardMultiplier = 1 + reward,
		ToolTier = tool.Tier,
		ToolId = tool.Id,
	}
end

-- Full duration (seconds) to peel a sticker with `health` HP from 0%.
function PlayerStats.GetPeelDuration(stats: Stats, health: number): number
	return math.max(Config.Peel.MinDuration, health / stats.PeelRate * stats.DurationFactor)
end

function PlayerStats.GetComboMultiplier(combo: number): number
	for _, tier in ipairs(Config.Combo.Tiers) do
		if combo >= tier.Count then
			return tier.Multiplier
		end
	end
	return 1
end

return PlayerStats
