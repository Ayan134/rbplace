--[[
	Progression
	Player level / XP curve and "what unlocks at level N".
]]

local Config = require(script.Parent.Config)
local LevelConfig = require(script.Parent.LevelConfig)
local ToolConfig = require(script.Parent.ToolConfig)
local UpgradeConfig = require(script.Parent.UpgradeConfig)
local DifficultyConfig = require(script.Parent.DifficultyConfig)

local Progression = {}

-- XP needed to go from `level` to `level + 1`
function Progression.XPToNext(level: number): number
	return math.floor(Config.XP.Base * level ^ Config.XP.Exponent / 10 + 0.5) * 10
end

-- Adds XP and returns newLevel, newXP, levelsGained
function Progression.ApplyXP(level: number, xp: number, gained: number): (number, number, number)
	local startLevel = level
	xp += math.max(0, gained)
	while level < Config.XP.MaxLevel and xp >= Progression.XPToNext(level) do
		xp -= Progression.XPToNext(level)
		level += 1
	end
	if level >= Config.XP.MaxLevel then
		xp = math.min(xp, Progression.XPToNext(level))
	end
	return level, xp, level - startLevel
end

-- Returns a list of human readable unlocks reached exactly at `level`.
function Progression.GetUnlocksAt(level: number): { string }
	local unlocks = {}
	for _, levelInfo in ipairs(LevelConfig.GetOrdered()) do
		if levelInfo.RequiredLevel == level and level > 1 then
			table.insert(unlocks, "Level: " .. levelInfo.Name)
		end
	end
	for _, id in ipairs(ToolConfig.Order) do
		local tool = ToolConfig.Tools[id]
		if tool.RequiredLevel == level and level > 1 then
			table.insert(unlocks, "Tool: " .. tool.Name)
		end
	end
	for _, id in ipairs(DifficultyConfig.Order) do
		local difficulty = DifficultyConfig.Difficulties[id]
		if difficulty.RequiredLevel == level and level > 1 then
			table.insert(unlocks, "Difficulty: " .. difficulty.DisplayName)
		end
	end
	for _, id in ipairs(UpgradeConfig.Order) do
		local upgrade = UpgradeConfig.Upgrades[id]
		for upgradeLevel = 1, upgrade.MaxLevel do
			local required = UpgradeConfig.GetRequiredPlayerLevel(id, upgradeLevel)
			if required == level and level > 1 then
				table.insert(unlocks, string.format("Upgrade: %s Lv.%d+", upgrade.Name, upgradeLevel))
				break
			end
		end
	end
	return unlocks
end

return Progression
