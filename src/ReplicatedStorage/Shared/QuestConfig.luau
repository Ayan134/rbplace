--[[
	QuestConfig
	Daily quests ("tasks"). Every UTC day each player rolls `DailyCount` quests from
	these templates. Progress is tracked on the server by stat keys.
]]

local QuestConfig = {}

QuestConfig.DailyCount = 3

QuestConfig.Templates = {
	{
		Id = "PeelStickers",
		Stat = "StickersPeeled",
		Text = "Peel %d stickers",
		Targets = { 1000, 2500, 5000 },
		RewardCoins = { 900, 1950, 4200 },
		RewardGems = { 2, 4, 8 },
	},
	{
		Id = "FindRare",
		Stat = "RareFound",
		Text = "Find %d rare stickers",
		Targets = { 10, 25, 50 },
		RewardCoins = { 1200, 2700, 5400 },
		RewardGems = { 3, 6, 10 },
	},
	{
		Id = "CompleteLevels",
		Stat = "LevelsCompleted",
		Text = "Complete %d levels",
		Targets = { 1, 2, 4 },
		RewardCoins = { 1500, 3300, 7200 },
		RewardGems = { 3, 6, 12 },
	},
	{
		Id = "ReachCombo",
		Stat = "BestComboToday",
		Text = "Reach a x%d combo",
		Targets = { 25, 50, 100 },
		RewardCoins = { 1050, 2400, 4800 },
		RewardGems = { 2, 5, 9 },
		IsMax = true, -- progress is the highest value reached, not a sum
	},
	{
		Id = "EarnCoins",
		Stat = "CoinsEarned",
		Text = "Earn %d coins",
		Targets = { 5000, 15000, 40000 },
		RewardCoins = { 900, 2100, 4500 },
		RewardGems = { 2, 4, 8 },
	},
	{
		Id = "CoopPeel",
		Stat = "CoopStickers",
		Text = "Peel %d stickers with friends",
		Targets = { 800, 2000, 4000 },
		RewardCoins = { 1350, 3000, 6000 },
		RewardGems = { 3, 6, 10 },
	},
}

local byId = {}
for _, template in ipairs(QuestConfig.Templates) do
	byId[template.Id] = template
end

function QuestConfig.Get(id: string)
	return byId[id]
end

return QuestConfig
