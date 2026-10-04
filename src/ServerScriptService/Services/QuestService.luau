--[[
	QuestService
	Daily quests ("tasks"). Rolled per player per UTC day, progress tracked from gameplay
	stats, rewards claimed through the ClaimQuest remote (validated server-side).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestConfig = require(Shared.QuestConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Parent.Systems.Notifier)
local RateLimiter = require(script.Parent.Parent.Systems.RateLimiter)

local QuestService = {}

local claimLimiter = RateLimiter.new(3, 6)

local function rollQuests(userId: number, day: number, playerLevel: number)
	local rng = Random.new(userId * 31 + day * 7919)
	local pool = table.clone(QuestConfig.Templates)
	local list = {}
	-- Higher player level => harder tiers more often
	local tierBias = math.clamp(playerLevel / 20, 0, 1)
	for _ = 1, math.min(QuestConfig.DailyCount, #pool) do
		local index = rng:NextInteger(1, #pool)
		local template = table.remove(pool, index)
		local roll = rng:NextNumber() + tierBias * 0.6
		local tier = if roll > 1.15 then 3 elseif roll > 0.6 then 2 else 1
		table.insert(list, {
			Id = template.Id,
			Tier = tier,
			Target = template.Targets[tier],
			Progress = 0,
			Claimed = false,
		})
	end
	return list
end

-- Makes sure the player's quests belong to the current UTC day.
function QuestService.EnsureDaily(player: Player, data)
	local today = Utility.UtcDay()
	if data.Quests.Day ~= today then
		data.Quests.Day = today
		data.Quests.List = rollQuests(player.UserId, today, data.Level)
	end
	if data.Daily.Day ~= today then
		data.Daily.Day = today
		data.Daily.BestComboToday = 0
	end
end

-- Adds `amount` to every quest tracking `stat` (or raises it, for max-type quests).
function QuestService.Track(player: Player, stat: string, amount: number)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	PlayerDataService.Update(player, function(d)
		QuestService.EnsureDaily(player, d)
		for _, quest in ipairs(d.Quests.List) do
			local template = QuestConfig.Get(quest.Id)
			if template and template.Stat == stat and not quest.Claimed then
				local before = quest.Progress
				if template.IsMax then
					quest.Progress = math.max(quest.Progress, amount)
				else
					quest.Progress += amount
				end
				quest.Progress = math.min(quest.Progress, quest.Target)
				if before < quest.Target and quest.Progress >= quest.Target then
					Notifier.Toast(player, "✅ Quest complete: " .. string.format(template.Text, quest.Target) .. " - claim your reward!", "Success")
				end
			end
		end
	end)
end

function QuestService.Claim(player: Player, index: any)
	if not claimLimiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if type(index) ~= "number" or index ~= index or index % 1 ~= 0 then
		return { Success = false, Message = "Invalid quest" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end
	QuestService.EnsureDaily(player, data)
	local quest = data.Quests.List[index]
	if not quest then
		return { Success = false, Message = "Invalid quest" }
	end
	if quest.Claimed then
		return { Success = false, Message = "Already claimed" }
	end
	if quest.Progress < quest.Target then
		return { Success = false, Message = "Quest not finished yet" }
	end
	local template = QuestConfig.Get(quest.Id)
	if not template then
		return { Success = false, Message = "Invalid quest" }
	end
	local coins = template.RewardCoins[quest.Tier] or 0
	local gems = template.RewardGems[quest.Tier] or 0
	PlayerDataService.Update(player, function(d)
		local q = d.Quests.List[index]
		q.Claimed = true
		d.Coins += coins
		d.Gems += gems
		d.Statistics.CoinsEarned += coins
		d.Statistics.GemsEarned += gems
	end)
	return { Success = true, Coins = coins, Gems = gems }
end

function QuestService.Init()
	Remotes.ClaimQuest.OnServerInvoke = function(player: Player, index: any)
		return QuestService.Claim(player, index)
	end
	PlayerDataService.Loaded:Connect(function(player, data)
		QuestService.EnsureDaily(player, data)
		PlayerDataService.PushToClient(player)
	end)
end

function QuestService.Start() end

return QuestService
