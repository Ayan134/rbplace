--[[
	EconomyService
	The only place that changes Coins, Gems and XP. Computes sticker rewards (combo,
	luck, reward multiplier), level-completion rewards, XP and level-ups.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerStats = require(Shared.PlayerStats)
local Progression = require(Shared.Progression)
local StickerConfig = require(Shared.StickerConfig)

local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local Notifier = require(script.Parent.Parent.Systems.Notifier)

local EconomyService = {}

type ComboState = { Count: number, Last: number }
local combos: { [Player]: ComboState } = {}
local rng = Random.new()

function EconomyService.GetStats(player: Player): PlayerStats.Stats
	return PlayerStats.Compute(PlayerDataService.Get(player))
end

function EconomyService.AddCoins(player: Player, amount: number, countAsEarned: boolean?)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	PlayerDataService.Update(player, function(data)
		data.Coins += amount
		if countAsEarned ~= false then
			data.Statistics.CoinsEarned += amount
		end
	end)
	if countAsEarned ~= false then
		QuestService.Track(player, "CoinsEarned", amount)
	end
end

function EconomyService.AddGems(player: Player, amount: number)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	PlayerDataService.Update(player, function(data)
		data.Gems += amount
		data.Statistics.GemsEarned += amount
	end)
end

-- Atomically checks and spends a currency. Returns true on success.
function EconomyService.TrySpend(player: Player, currency: string, amount: number): boolean
	local data = PlayerDataService.Get(player)
	if not data or amount < 0 or amount ~= amount then
		return false
	end
	local field = if currency == "Gems" then "Gems" else "Coins"
	if data[field] < amount then
		return false
	end
	PlayerDataService.Update(player, function(d)
		d[field] -= amount
	end)
	return true
end

function EconomyService.AddXP(player: Player, amount: number)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	local levelsGained = 0
	local newLevel = 1
	PlayerDataService.Update(player, function(data)
		local level, xp, gained = Progression.ApplyXP(data.Level, data.XP, amount)
		data.Level = level
		data.XP = xp
		levelsGained = gained
		newLevel = level
		if gained > 0 then
			data.Gems += Config.Rewards.LevelUpGems * gained
			data.Statistics.GemsEarned += Config.Rewards.LevelUpGems * gained
		end
	end)
	if levelsGained > 0 then
		local unlocks = {}
		for level = newLevel - levelsGained + 1, newLevel do
			for _, unlock in ipairs(Progression.GetUnlocksAt(level)) do
				table.insert(unlocks, unlock)
			end
		end
		Notifier.Effect(player, "LevelUp", {
			Level = newLevel,
			Gems = Config.Rewards.LevelUpGems * levelsGained,
			Unlocks = unlocks,
		})
	end
end

-- Registers a peel for the combo system. Returns combo count and multiplier.
function EconomyService.RegisterCombo(player: Player): (number, number)
	local now = os.clock()
	local state = combos[player]
	if not state or now - state.Last > Config.Combo.Window then
		state = { Count = 0, Last = now }
		combos[player] = state
	end
	state.Count += 1
	state.Last = now
	local data = PlayerDataService.Get(player)
	if data then
		if state.Count > data.Statistics.HighestCombo then
			data.Statistics.HighestCombo = state.Count
		end
		if state.Count > (data.Daily.BestComboToday or 0) then
			data.Daily.BestComboToday = state.Count
			if state.Count % 5 == 0 then
				QuestService.Track(player, "BestComboToday", state.Count)
			end
		end
	end
	return state.Count, PlayerStats.GetComboMultiplier(state.Count)
end

export type StickerReward = {
	Coins: number,
	XP: number,
	Combo: number,
	ComboMultiplier: number,
	Lucky: boolean,
	Gems: number,
}

--[[
	Awards a peeled sticker.
	context = {
		LevelInfo = LevelConfig entry,
		Difficulty = DifficultyConfig entry,
		Practice = boolean,      -- lobby showcase: no rewards
		PlayerCount = number,
	}
]]
function EconomyService.AwardSticker(player: Player, sticker, context): StickerReward
	local combo, comboMultiplier = EconomyService.RegisterCombo(player)
	if context.Practice then
		return { Coins = 0, XP = 0, Combo = combo, ComboMultiplier = comboMultiplier, Lucky = false, Gems = 0 }
	end

	local stats = EconomyService.GetStats(player)
	local info = StickerConfig.Get(sticker.Type)
	local lucky = rng:NextNumber() < stats.Luck * Config.Rewards.LuckyChanceScale
	local coins = sticker.BaseReward * stats.RewardMultiplier * comboMultiplier * (if lucky then 2 else 1)
	coins = math.max(1, math.floor(coins + 0.5))
	local xp = math.max(1, math.floor(info.XP * context.Difficulty.XPMultiplier + 0.5))

	local gems = 0
	if sticker.Type == "Diamond" then
		gems = Config.Rewards.DiamondGems
	elseif sticker.Type == "Legendary" then
		gems = Config.Rewards.LegendaryGems
	end

	PlayerDataService.Update(player, function(data)
		data.Coins += coins
		data.Gems += gems
		data.Statistics.CoinsEarned += coins
		data.Statistics.GemsEarned += gems
		data.Statistics.StickersPeeled += 1
		if (context.PlayerCount or 1) > 1 then
			data.Statistics.CoopStickers += 1
		end
		if info.IsRare then
			data.Statistics.RareFound += 1
			data.Statistics.RareByType[sticker.Type] = (data.Statistics.RareByType[sticker.Type] or 0) + 1
		end
	end)
	EconomyService.AddXP(player, xp)

	QuestService.Track(player, "StickersPeeled", 1)
	QuestService.Track(player, "CoinsEarned", coins)
	if info.IsRare then
		QuestService.Track(player, "RareFound", 1)
	end
	if (context.PlayerCount or 1) > 1 then
		QuestService.Track(player, "CoopStickers", 1)
	end

	return { Coins = coins, XP = xp, Combo = combo, ComboMultiplier = comboMultiplier, Lucky = lucky, Gems = gems }
end

function EconomyService.ResetCombo(player: Player)
	combos[player] = nil
end

function EconomyService.Init()
	Players.PlayerRemoving:Connect(function(player)
		combos[player] = nil
	end)
end

function EconomyService.Start() end

return EconomyService
