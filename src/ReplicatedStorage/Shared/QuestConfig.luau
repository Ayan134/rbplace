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
		Targets = { 150, 300, 600 },
		RewardCoins = { 300, 650, 1400 },
		RewardGems = { 2, 4, 8 },
	},
	{
		Id = "FindRare",
		Stat = "RareFound",
		Text = "Find %d rare stickers",
		Targets = { 3, 8, 15 },
		RewardCoins = { 400, 900, 1800 },
		RewardGems = { 3, 6, 10 },
	},
	{
		Id = "CompleteLevels",
		Stat = "LevelsCompleted",
		Text = "Complete %d levels",
		Targets = { 1, 2, 4 },
		RewardCoins = { 500, 1100, 2400 },
		RewardGems = { 3, 6, 12 },
	},
	{
		Id = "ReachCombo",
		Stat = "BestComboToday",
		Text = "Reach a x%d combo",
		Targets = { 15, 30, 60 },
		RewardCoins = { 350, 800, 1600 },
		RewardGems = { 2, 5, 9 },
		IsMax = true, -- progress is the highest value reached, not a sum
	},
	{
		Id = "EarnCoins",
		Stat = "CoinsEarned",
		Text = "Earn %d coins",
		Targets = { 1500, 4000, 10000 },
		RewardCoins = { 300, 700, 1500 },
		RewardGems = { 2, 4, 8 },
	},
	{
		Id = "CoopPeel",
		Stat = "CoopStickers",
		Text = "Peel %d stickers with friends",
		Targets = { 100, 250, 500 },
		RewardCoins = { 450, 1000, 2000 },
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
