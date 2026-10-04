--[[
	LevelService
	Owns levels and matches:
	  * builds level models into ServerStorage.Levels (unless hand-made models exist there)
	  * publishes preview copies to ReplicatedStorage.Assets.LevelPreviews for the UI
	  * builds the lobby and its sticker-covered showcase object (with a demo "ghost" peeler)
	  * runs matches: allocates an arena slot, clones the level, generates stickers,
	    teleports the party, tracks progress, awards completion rewards, returns players

	Many parties can play at the same time; each match gets its own arena far from the lobby.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)
local PlayerStats = require(Shared.PlayerStats)
local Signal = require(Shared.Signal)
local StickerConfig = require(Shared.StickerConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Systems = script.Parent.Parent.Systems
local Decor = require(Systems.Decor)
local LobbyBuilder = require(Systems.LobbyBuilder)
local Notifier = require(Systems.Notifier)
local RateLimiter = require(Systems.RateLimiter)
local StickerGenerator = require(Systems.StickerGenerator)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local QuestService = require(script.Parent.QuestService)
local StickerService = require(script.Parent.StickerService)

local LevelService = {}

LevelService.MatchEnded = Signal.new() -- (party, match)
LevelService.PlayerLeftMatch = Signal.new() -- (player, match, voluntary)

local levelsFolder = ServerStorage:WaitForChild("Levels")
local previewsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("LevelPreviews")
local arenasFolder: Folder

local matches: { [string]: any } = {}
local matchBySession: { [string]: any } = {}
local playerMatch: { [Player]: any } = {}
local slots: { [number]: any } = {}

local lobbyModel: Model
local lobbySession = nil
local unlockLimiter = RateLimiter.new(3, 6)

------------------------------------------------------------------------
-- Level models
------------------------------------------------------------------------

local function buildLevelModels()
	local buildersFolder = script.Parent.Parent:FindFirstChild("LevelBuilders")
	if not buildersFolder then
		return
	end
	for _, module in ipairs(buildersFolder:GetChildren()) do
		if module:IsA("ModuleScript") and module.Name ~= "BuildKit" then
			if levelsFolder:FindFirstChild(module.Name) then
				continue -- a hand-made model takes priority
			end
			local ok, result = pcall(function()
				return require(module)()
			end)
			if ok and typeof(result) == "Instance" then
				result.Name = module.Name
				result.Parent = levelsFolder
			else
				warn("[LevelService] Failed to build level " .. module.Name .. ": " .. tostring(result))
			end
		end
	end
end

local function publishPreviews()
	for _, level in ipairs(LevelConfig.GetOrdered()) do
		local source = levelsFolder:FindFirstChild(level.ObjectModel)
		if source and not previewsFolder:FindFirstChild(level.LevelId) then
			local preview = source:Clone()
			preview.Name = level.LevelId
			-- Previews show the object only; the scenery around it is far too big for a viewport
			local environment = preview:FindFirstChild("Environment")
			if environment then
				environment:Destroy()
			end
			for _, descendant in ipairs(preview:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
					descendant.CanCollide = false
					descendant.CanQuery = false
					descendant.CanTouch = false
				elseif descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("Light") or descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("ProximityPrompt") then
					descendant:Destroy()
				end
			end
			preview.Parent = previewsFolder
		end
	end
end

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function spawnCharacter(player: Player)
	local ok = pcall(function()
		(player :: any):LoadCharacterAsync()
	end)
	if not ok and player.Parent then
		-- Older engines without LoadCharacterAsync
		(player :: any):LoadCharacter()
	end
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function teleport(player: Player, cframe: CFrame)
	local character = player.Character
	if character and character.PrimaryPart then
		character:PivotTo(cframe + Vector3.new(0, 3, 0))
	end
end

local function lobbySpawnCFrame(): CFrame
	local spawn = lobbyModel:FindFirstChild("SpawnLocation", true)
	if spawn and spawn:IsA("BasePart") then
		return spawn.CFrame * CFrame.Angles(0, math.pi, 0)
	end
	return CFrame.new(0, 3, 60)
end

local function setJumpHeight(player: Player, height: number)
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = height
	end
end

local function joinLobbySession(player: Player)
	if lobbySession and not playerMatch[player] and PlayerDataService.IsLoaded(player) then
		StickerService.AddMember(lobbySession, player)
	end
end

local function slotOrigin(slot: number): Vector3
	local column = (slot - 1) % Config.Arena.Columns
	local row = math.floor((slot - 1) / Config.Arena.Columns)
	return Config.Arena.Origin + Vector3.new(column * Config.Arena.Spacing, 0, row * Config.Arena.Spacing)
end

local function allocateSlot(match): number?
	for slot = 1, Config.Arena.MaxSlots do
		if not slots[slot] then
			slots[slot] = match
			return slot
		end
	end
	return nil
end

local function matchPlayers(match): { Player }
	local list = {}
	for player in pairs(match.Players) do
		table.insert(list, player)
	end
	return list
end

local function teamSnapshot(match)
	local team = {}
	for userId, info in pairs(match.Participants) do
		table.insert(team, {
			UserId = userId,
			Name = info.DisplayName,
			Peeled = match.Contributions[userId] or 0,
			Present = info.Present,
		})
	end
	table.sort(team, function(a, b)
		return a.Peeled > b.Peeled
	end)
	return team
end

local function buildArena(match): (Model, BasePart)
	local origin = match.Origin
	local arena = Instance.new("Model")
	arena.Name = "Arena_" .. match.Slot

	local groundSize = Config.Arena.GroundSize
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(groundSize, 2, groundSize)
	ground.CFrame = CFrame.new(origin - Vector3.new(0, 1, 0))
	ground.Anchored = true
	ground.Color = Color3.fromRGB(116, 190, 86)
	ground.Material = Enum.Material.Grass
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = arena

	-- Real grass terrain under the arena (deep enough for ponds and moats);
	-- the part stays only for sticker occlusion tests
	local filled = pcall(function()
		Workspace.Terrain:FillBlock(CFrame.new(origin - Vector3.new(0, 5, 0)), Vector3.new(groundSize, 10, groundSize), Enum.Material.Grass)
	end)
	if filled then
		ground.Transparency = 1
		ground.CanCollide = false
		match.TerrainFilled = true
	end

	local playable = Config.Arena.PlayableSize
	for _, def in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
		local wall = Instance.new("Part")
		wall.Name = "Boundary"
		wall.Size = if def[1] == 0 then Vector3.new(playable, 300, 4) else Vector3.new(4, 300, playable)
		wall.CFrame = CFrame.new(origin + Vector3.new(def[1] * playable / 2, 150, def[2] * playable / 2))
		wall.Anchored = true
		wall.Transparency = 1
		wall.CanQuery = false
		wall.Parent = arena
	end

	local source = levelsFolder:FindFirstChild(match.LevelInfo.ObjectModel)
	local level: Model
	if source and source:IsA("Model") then
		level = source:Clone()
	else
		warn("[LevelService] Missing level model " .. match.LevelInfo.ObjectModel)
		level = Instance.new("Model")
	end
	level.Name = match.LevelInfo.LevelId
	level:PivotTo(CFrame.new(origin))
	level.Parent = arena
	if filled then
		-- Ponds, moats and fountains become real terrain water
		Decor.ApplyTerrain(level)
	end
	if not level:FindFirstChild("Environment") then
		-- Hand-made models without scenery still get a tree ring
		local rng = Random.new(match.Slot)
		local folder = Instance.new("Folder")
		folder.Name = "Environment"
		folder.Parent = level
		Decor.Backdrop(folder, origin, playable / 2 - 20, rng)
	end
	arena.Parent = arenasFolder
	return level, ground
end

------------------------------------------------------------------------
-- Rewards (called by StickerService on every validated peel)
------------------------------------------------------------------------

local function onRewardRequested(session, player: Player?, sticker)
	if not player then
		return nil
	end
	if session.Kind == "Showcase" then
		return EconomyService.AwardSticker(player, sticker, { Practice = true })
	end
	local match = matchBySession[session.Id]
	if not match or match.State ~= "Playing" then
		return nil
	end
	local reward = EconomyService.AwardSticker(player, sticker, {
		LevelInfo = match.LevelInfo,
		Difficulty = match.Difficulty,
		PlayerCount = Utility.Count(match.Players),
	})
	local userId = player.UserId
	match.Contributions[userId] = (match.Contributions[userId] or 0) + 1
	match.Earned[userId] = (match.Earned[userId] or 0) + reward.Coins
	match.XP[userId] = (match.XP[userId] or 0) + reward.XP
	match.TeamDirty = true

	local info = StickerConfig.Get(sticker.Type)
	if info.IsRare then
		match.Rare[userId] = match.Rare[userId] or {}
		match.Rare[userId][sticker.Type] = (match.Rare[userId][sticker.Type] or 0) + 1
	end
	if info.Notify then
		Notifier.Effect(player, "RareFound", { Type = sticker.Type, Coins = reward.Coins, Gems = reward.Gems })
		for other in pairs(match.Players) do
			-- With thousands of stickers only the rarest finds are announced to the team
			if other ~= player and info.Index >= StickerConfig.Types.Rainbow.Index then
				Notifier.Toast(other, string.format("✨ %s found a %s!", player.DisplayName, info.DisplayName), "Rare")
			end
		end
	end
	return reward
end

------------------------------------------------------------------------
-- Match lifecycle
------------------------------------------------------------------------

local endMatch

local function removePlayerFromMatch(match, player: Player, toLobby: boolean, voluntary: boolean)
	if playerMatch[player] ~= match then
		return
	end
	playerMatch[player] = nil
	match.Players[player] = nil
	if match.Participants[player.UserId] then
		match.Participants[player.UserId].Present = false
	end
	match.TeamDirty = true
	StickerService.RemoveMember(player)
	EconomyService.ResetCombo(player)

	if toLobby and player.Parent then
		Remotes.MatchEvent:FireClient(player, "Ended", {})
		teleport(player, lobbySpawnCFrame())
		setJumpHeight(player, StarterPlayer.CharacterJumpHeight)
		joinLobbySession(player)
	end
	LevelService.PlayerLeftMatch:Fire(player, match, voluntary)

	if next(match.Players) == nil then
		endMatch(match)
	end
end

local function completeMatch(match)
	if match.State ~= "Playing" then
		return
	end
	match.State = "Complete"
	match.Session.Locked = true
	local elapsed = os.clock() - match.StartTime
	local players = matchPlayers(match)
	local playerCount = #players
	local levelInfo = match.LevelInfo
	local difficulty = match.Difficulty
	local total = match.Session.Total
	local key = LevelConfig.RecordKey(levelInfo.LevelId, difficulty.Id)

	local completionBase = LevelConfig.GetCompletionReward(levelInfo.LevelId, difficulty.Id)
	local coopBonus = completionBase * Config.Match.CoopBonusPerPlayer * math.max(0, playerCount - 1)
	local par = LevelConfig.GetParTime(levelInfo.LevelId, difficulty.Id, playerCount)
	local speedFraction = math.clamp((par - elapsed) / par, 0, 1) * Config.Match.SpeedBonusMax
	local speedBonus = completionBase * speedFraction
	local team = teamSnapshot(match)

	for _, player in ipairs(players) do
		local data = PlayerDataService.Get(player)
		if not data then
			continue
		end
		local stats = PlayerStats.Compute(data)
		local userId = player.UserId
		local contribution = match.Contributions[userId] or 0
		local afk = playerCount > 1 and contribution / math.max(total, 1) < Config.Match.AfkContributionThreshold
		local afkFactor = if afk then 0.5 else 1

		local completionCoins = math.floor(completionBase * stats.RewardMultiplier * afkFactor)
		local coopCoins = math.floor(coopBonus * stats.RewardMultiplier * afkFactor)
		local speedCoins = math.floor(speedBonus * stats.RewardMultiplier * afkFactor)
		local firstTime = (data.Completed[key] or 0) == 0
		local previousBest = data.BestTimes[key]
		local newRecord = previousBest == nil or elapsed < previousBest

		local xp = levelInfo.BaseXP * difficulty.XPMultiplier
		if firstTime then
			xp *= 1 + Config.Rewards.FirstCompletionXPBonus
		end
		if newRecord and previousBest then
			xp += Config.Rewards.RecordXPBonus
		end
		xp = math.floor(xp * afkFactor)
		local gems = if firstTime then Config.Rewards.FirstCompletionGems else 0
		local bonusCoins = completionCoins + coopCoins + speedCoins

		PlayerDataService.Update(player, function(d)
			d.Coins += bonusCoins
			d.Gems += gems
			d.Statistics.CoinsEarned += bonusCoins
			d.Statistics.GemsEarned += gems
			d.Statistics.LevelsCompleted += 1
			d.Statistics.MatchesPlayed += 1
			d.Completed[key] = (d.Completed[key] or 0) + 1
			if newRecord then
				d.BestTimes[key] = math.floor(elapsed * 10) / 10
			end
		end)
		EconomyService.AddXP(player, xp)
		QuestService.Track(player, "LevelsCompleted", 1)
		QuestService.Track(player, "CoinsEarned", bonusCoins)

		local rareList = {}
		for typeId, count in pairs(match.Rare[userId] or {}) do
			table.insert(rareList, { Type = typeId, Count = count })
		end
		table.sort(rareList, function(a, b)
			return StickerConfig.Get(a.Type).Index > StickerConfig.Get(b.Type).Index
		end)

		local nextLevel = LevelConfig.GetNext(levelInfo.LevelId)
		Remotes.MatchEvent:FireClient(player, "Complete", {
			LevelId = levelInfo.LevelId,
			LevelName = levelInfo.Name,
			Difficulty = difficulty.Id,
			Time = elapsed,
			ParTime = par,
			StickersTotal = total,
			StickersPeeled = contribution,
			StickerCoins = match.Earned[userId] or 0,
			CompletionCoins = completionCoins,
			CoopBonus = coopCoins,
			SpeedBonus = speedCoins,
			TotalCoins = (match.Earned[userId] or 0) + bonusCoins,
			XP = (match.XP[userId] or 0) + xp,
			Gems = gems,
			FirstCompletion = firstTime,
			NewRecord = newRecord,
			BestTime = if newRecord then elapsed else previousBest,
			RareFound = rareList,
			Team = team,
			PlayerCount = playerCount,
			Afk = afk,
			NextLevel = nextLevel and nextLevel.LevelId,
			ReturnIn = Config.Match.ResultsDuration,
		})
	end

	task.delay(Config.Match.ResultsDuration, function()
		endMatch(match)
	end)
end

function endMatch(match)
	if match.Ended then
		return
	end
	match.Ended = true
	for _, player in ipairs(matchPlayers(match)) do
		removePlayerFromMatch(match, player, true, false)
	end
	if match.Session then
		matchBySession[match.Session.Id] = nil
		StickerService.DestroySession(match.Session)
	end
	if match.Arena then
		match.Arena:Destroy()
	end
	if match.TerrainFilled then
		local groundSize = Config.Arena.GroundSize
		pcall(function()
			Workspace.Terrain:FillBlock(CFrame.new(match.Origin - Vector3.new(0, 4, 0)), Vector3.new(groundSize + 8, 16, groundSize + 8), Enum.Material.Air)
		end)
	end
	slots[match.Slot] = nil
	matches[match.Id] = nil
	LevelService.MatchEnded:Fire(match.Party, match)
end

local function loadMatch(match)
	local level, ground = buildArena(match)
	match.Arena = level.Parent

	-- Party luck slightly increases rare sticker spawns
	local luckTotal, luckCount = 0, 0
	for player in pairs(match.Players) do
		local data = PlayerDataService.Get(player)
		if data then
			luckTotal += PlayerStats.Compute(data).Luck
			luckCount += 1
		end
	end

	local count = LevelConfig.GetStickerCount(match.LevelInfo.LevelId, match.Difficulty.Id)
	local stickers, seed = StickerGenerator.Generate(level, {
		Count = count,
		Difficulty = match.Difficulty,
		Level = match.LevelInfo,
		LuckBonus = if luckCount > 0 then luckTotal / luckCount * 0.5 else 0,
		GroundY = match.Origin.Y,
		ExtraObstacles = { ground },
	})
	match.Seed = seed

	if match.Ended or next(match.Players) == nil then
		endMatch(match)
		return
	end

	local session = StickerService.CreateSession("Match_" .. match.Id, "Match", stickers, match.Difficulty, {
		LevelId = match.LevelInfo.LevelId,
		Difficulty = match.Difficulty.Id,
	})
	match.Session = session
	session.Locked = true -- nobody peels behind the loading screen
	matchBySession[session.Id] = match
	session.Peeled:Connect(function()
		match.TeamDirty = true
		if session.Alive <= 0 then
			completeMatch(match)
		end
	end)

	local spawn = level:FindFirstChild("SpawnPoint")
	match.SpawnCFrame = if spawn and spawn:IsA("BasePart") then spawn.CFrame else CFrame.new(match.Origin + Vector3.new(0, 3, 40))
	local finish = level:FindFirstChild("FinishArea")
	match.FocusPosition = if finish and finish:IsA("BasePart") then finish.Position else match.Origin

	local players = matchPlayers(match)
	for index, player in ipairs(players) do
		StickerService.AddMember(session, player)
		local offset = (index - (#players + 1) / 2) * 4
		teleport(player, match.SpawnCFrame * CFrame.new(offset, 0, 0))
		setJumpHeight(player, Config.Match.ArenaJumpHeight)
	end

	-- Give clients time to receive sticker chunks behind the loading screen
	-- Wait behind the loading screen until every client has built its stickers
	local loadStart = os.clock()
	task.wait(Config.Match.LoadingMinTime)
	while not match.Ended and os.clock() - loadStart < Config.Match.LoadTimeout do
		local allReady = true
		for player in pairs(match.Players) do
			if not match.ClientReady[player] then
				allReady = false
				break
			end
		end
		if allReady then
			break
		end
		task.wait(0.2)
	end
	if match.Ended or next(match.Players) == nil then
		endMatch(match)
		return
	end

	match.State = "Playing"
	match.StartTime = os.clock()
	session.Locked = false
	for player in pairs(match.Players) do
		Remotes.MatchEvent:FireClient(player, "Start", {
			LevelId = match.LevelInfo.LevelId,
			Difficulty = match.Difficulty.Id,
			Total = session.Total,
			ServerStart = Workspace:GetServerTimeNow(),
			Focus = match.FocusPosition,
			Team = teamSnapshot(match),
		})
	end

	-- Team panel updates
	task.spawn(function()
		while not match.Ended and match.State == "Playing" do
			task.wait(1)
			if match.TeamDirty and match.State == "Playing" then
				match.TeamDirty = false
				local team = teamSnapshot(match)
				for player in pairs(match.Players) do
					Remotes.MatchEvent:FireClient(player, "Team", { Team = team, Alive = session.Alive })
				end
			end
		end
	end)
end

-- Called by PartyService. Returns success, errorMessage.
function LevelService.StartMatch(party, members: { Player }): (boolean, string?)
	local levelInfo = LevelConfig.Get(party.LevelId)
	local difficulty = DifficultyConfig.Get(party.Difficulty)
	if not levelInfo or not difficulty then
		return false, "Invalid level"
	end
	local players = {}
	for _, player in ipairs(members) do
		if player.Parent and PlayerDataService.IsLoaded(player) and not playerMatch[player] and player.Character then
			table.insert(players, player)
		end
	end
	if #players == 0 then
		return false, "No players ready"
	end

	local match = {
		Id = HttpService:GenerateGUID(false),
		Party = party,
		LevelInfo = levelInfo,
		Difficulty = difficulty,
		State = "Loading",
		Players = {},
		Participants = {},
		Contributions = {},
		Earned = {},
		XP = {},
		Rare = {},
		TeamDirty = true,
		ClientReady = {},
		Ended = false,
		StartTime = 0,
	}
	local slot = allocateSlot(match)
	if not slot then
		return false, "All arenas are busy - try again in a moment"
	end
	match.Slot = slot
	match.Origin = slotOrigin(slot)
	matches[match.Id] = match

	for _, player in ipairs(players) do
		playerMatch[player] = match
		match.Players[player] = true
		match.Participants[player.UserId] = { DisplayName = player.DisplayName, Present = true }
		StickerService.RemoveMember(player)
		Remotes.MatchEvent:FireClient(player, "Loading", {
			LevelId = levelInfo.LevelId,
			Difficulty = difficulty.Id,
			Total = LevelConfig.GetStickerCount(levelInfo.LevelId, difficulty.Id),
		})
	end

	task.spawn(function()
		local ok, err = pcall(loadMatch, match)
		if not ok then
			warn("[LevelService] Match failed to load: " .. tostring(err))
			for player in pairs(match.Players) do
				Notifier.Toast(player, "Something went wrong loading the level. Returning to lobby.", "Error")
			end
			endMatch(match)
		end
	end)
	return true
end

-- Buys access to a level (validated: level requirement + coins).
function LevelService.UnlockLevel(player: Player, levelId: any)
	if not unlockLimiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if not LevelConfig.IsValid(levelId) then
		return { Success = false, Message = "Unknown level" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end
	local level = LevelConfig.Get(levelId)
	if data.UnlockedLevels[levelId] then
		return { Success = false, Message = "Already unlocked" }
	end
	if data.Level < level.RequiredLevel then
		return { Success = false, Message = string.format("Requires player level %d", level.RequiredLevel) }
	end
	if not EconomyService.TrySpend(player, "Coins", level.UnlockCost) then
		return { Success = false, Message = "Not enough Coins" }
	end
	PlayerDataService.Update(player, function(d)
		d.UnlockedLevels[levelId] = true
	end)
	return { Success = true }
end

function LevelService.GetPlayerMatch(player: Player)
	return playerMatch[player]
end

function LevelService.IsInMatch(player: Player): boolean
	return playerMatch[player] ~= nil
end

------------------------------------------------------------------------
-- Lobby showcase
------------------------------------------------------------------------

local function setupShowcase()
	local anchor = lobbyModel:FindFirstChild("ShowcaseAnchor", true)
	local source = levelsFolder:FindFirstChild(Config.Lobby.ShowcaseLevel)
	if not source then
		return
	end
	local model = source:Clone()
	model.Name = "Showcase"
	-- The lobby has its own plaza and scenery; keep only the object itself
	for _, name in ipairs({ "Plaza", "Environment" }) do
		local child = model:FindFirstChild(name, true)
		if child then
			child:Destroy()
		end
	end
	local position = if anchor and anchor:IsA("BasePart") then anchor.Position else Vector3.new(0, 0.35, 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = lobbyModel

	local levelInfo = LevelConfig.Get(Config.Lobby.ShowcaseLevel)
	local difficulty = DifficultyConfig.Get("Normal")
	local function generate()
		local stickers = StickerGenerator.Generate(model, {
			Count = Config.Lobby.ShowcaseStickerCount,
			Difficulty = difficulty,
			Level = levelInfo,
			LuckBonus = 1,
			GroundY = position.Y,
			ExtraObstacles = { lobbyModel:FindFirstChild("Ground") },
		})
		return stickers
	end

	lobbySession = StickerService.CreateSession("Lobby", "Showcase", generate(), difficulty, {
		LevelId = levelInfo.LevelId,
		Practice = true,
	})
	for _, player in ipairs(Players:GetPlayers()) do
		joinLobbySession(player)
	end

	-- Demo loop: a "ghost" peels stickers so players see the mechanic immediately,
	-- and the showcase regenerates once most stickers are gone.
	local rng = Random.new()
	local regenerating = false
	task.spawn(function()
		while true do
			task.wait(Config.Lobby.GhostPeelInterval)
			local session = lobbySession
			if not session or regenerating then
				continue
			end
			if session.Alive / math.max(session.Total, 1) <= 1 - Config.Lobby.ShowcaseRegenerateAt then
				regenerating = true
				task.wait(2)
				StickerService.ReplaceStickers(session, generate())
				regenerating = false
				continue
			end
			for _ = 1, 12 do
				local candidate = session.Stickers[rng:NextInteger(1, math.max(1, session.Total))]
				if candidate and candidate.Alive and candidate.State == "Attached" then
					StickerService.GhostPeel(session, candidate.Id, rng:NextNumber(0.9, 1.5))
					break
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- Player spawning
------------------------------------------------------------------------

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		task.delay(3, function()
			if player.Parent and player.Character == character then
				spawnCharacter(player)
			end
		end)
	end)
	task.defer(function()
		local match = playerMatch[player]
		if match and match.SpawnCFrame then
			teleport(player, match.SpawnCFrame)
			setJumpHeight(player, Config.Match.ArenaJumpHeight)
		else
			joinLobbySession(player)
		end
	end)
end

function LevelService.Init()
	arenasFolder = Instance.new("Folder")
	arenasFolder.Name = "Arenas"
	arenasFolder.Parent = Workspace

	buildLevelModels()
	publishPreviews()
	lobbyModel = LobbyBuilder.Build()
	LobbyBuilder.Decorate(lobbyModel)

	StickerService.RewardHandler = onRewardRequested

	Remotes.UnlockLevel.OnServerInvoke = function(player: Player, levelId: any)
		return LevelService.UnlockLevel(player, levelId)
	end

	Remotes.ClientReady.OnServerEvent:Connect(function(player: Player)
		local match = playerMatch[player]
		if match then
			match.ClientReady[player] = true
		end
	end)

	Remotes.LeaveMatch.OnServerEvent:Connect(function(player: Player)
		local match = playerMatch[player]
		if match then
			removePlayerFromMatch(match, player, true, match.State ~= "Complete")
		end
	end)
end

function LevelService.Start()
	setupShowcase()

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end

	-- Characters only spawn once data is loaded (CharacterAutoLoads is disabled)
	PlayerDataService.Loaded:Connect(function(player)
		if player.Parent and not player.Character then
			spawnCharacter(player)
		end
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerDataService.IsLoaded(player) and not player.Character then
			task.spawn(spawnCharacter, player)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		local match = playerMatch[player]
		if match then
			removePlayerFromMatch(match, player, false, true)
		end
	end)
end

return LevelService
