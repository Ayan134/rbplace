--[[
	PartyService
	Rooms / parties in the lobby.

	  * any player can create a room (becomes HOST) choosing level, difficulty and size
	  * others browse open rooms and join
	  * members toggle Ready; the host can change level / difficulty / size, kick players
	    and start the match when everyone is ready
	  * if the host leaves, the next member automatically becomes host
	  * empty rooms are removed

	Max size comes from Config.Party.MaxPartySize so rooms can grow beyond 4 later.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = require(script.Parent.PlayerDataService)
local LevelService = require(script.Parent.LevelService)
local Notifier = require(script.Parent.Parent.Systems.Notifier)
local RateLimiter = require(script.Parent.Parent.Systems.RateLimiter)

local PartyService = {}

export type Party = {
	Id: string,
	Host: Player,
	Members: { Player },
	Ready: { [Player]: boolean },
	LevelId: string,
	Difficulty: string,
	MaxSize: number,
	State: string, -- "Lobby" | "InGame"
	CreatedAt: number,
}

local parties: { [string]: Party } = {}
local playerParty: { [Player]: Party } = {}
local limiter = RateLimiter.new(5, 10)
local dirty = false

local function markDirty()
	dirty = true
end

local function result(success: boolean, message: string?)
	return { Success = success, Message = message }
end

local function canPlayLevel(player: Player, levelId: string, difficultyId: string): (boolean, string?)
	local data = PlayerDataService.Get(player)
	if not data then
		return false, "Data not loaded"
	end
	local level = LevelConfig.Get(levelId)
	local difficulty = DifficultyConfig.Get(difficultyId)
	if not level or not difficulty then
		return false, "Invalid level"
	end
	if not data.UnlockedLevels[levelId] then
		return false, level.Name .. " is locked"
	end
	if data.Level < difficulty.RequiredLevel then
		return false, string.format("%s difficulty requires level %d", difficulty.DisplayName, difficulty.RequiredLevel)
	end
	return true
end

local function validSize(size: any): boolean
	return type(size) == "number" and size == size and size % 1 == 0 and size >= Config.Party.MinPartySize and size <= Config.Party.MaxPartySize
end

local function serializeParty(party: Party)
	local members = {}
	for _, member in ipairs(party.Members) do
		local data = PlayerDataService.Get(member)
		table.insert(members, {
			UserId = member.UserId,
			Name = member.Name,
			DisplayName = member.DisplayName,
			Ready = party.Ready[member] == true or member == party.Host,
			IsHost = member == party.Host,
			Level = data and data.Level or 1,
		})
	end
	return {
		Id = party.Id,
		HostUserId = party.Host.UserId,
		HostName = party.Host.DisplayName,
		LevelId = party.LevelId,
		Difficulty = party.Difficulty,
		MaxSize = party.MaxSize,
		State = party.State,
		Members = members,
	}
end

local function roomList()
	local rooms = {}
	for _, party in pairs(parties) do
		table.insert(rooms, {
			Id = party.Id,
			HostName = party.Host.DisplayName,
			HostUserId = party.Host.UserId,
			LevelId = party.LevelId,
			Difficulty = party.Difficulty,
			MaxSize = party.MaxSize,
			Count = #party.Members,
			State = party.State,
			CreatedAt = party.CreatedAt,
		})
	end
	table.sort(rooms, function(a, b)
		return a.CreatedAt < b.CreatedAt
	end)
	return rooms
end

local function broadcast()
	local rooms = roomList()
	for _, player in ipairs(Players:GetPlayers()) do
		local party = playerParty[player]
		Remotes.PartyUpdate:FireClient(player, {
			Rooms = rooms,
			MyParty = party and serializeParty(party),
			MaxPartySize = Config.Party.MaxPartySize,
		})
	end
end

local function removeFromParty(player: Player, reason: string?)
	local party = playerParty[player]
	if not party then
		return
	end
	playerParty[player] = nil
	party.Ready[player] = nil
	local index = table.find(party.Members, player)
	if index then
		table.remove(party.Members, index)
	end

	if #party.Members == 0 then
		parties[party.Id] = nil
	elseif party.Host == player then
		party.Host = party.Members[1]
		party.Ready[party.Host] = nil
		for _, member in ipairs(party.Members) do
			Notifier.Toast(member, party.Host.DisplayName .. " is now the HOST", "Info")
		end
	end
	if reason and player.Parent then
		Notifier.Toast(player, reason, "Info")
	end
	markDirty()
end

function PartyService.GetParty(player: Player): Party?
	return playerParty[player]
end

function PartyService.Create(player: Player, levelId: any, difficultyId: any, size: any)
	if not limiter:Check(player) then
		return result(false, "Slow down!")
	end
	if not LevelConfig.IsValid(levelId) or not DifficultyConfig.IsValid(difficultyId) or not validSize(size) then
		return result(false, "Invalid room settings")
	end
	if LevelService.IsInMatch(player) then
		return result(false, "You are in a match")
	end
	local ok, message = canPlayLevel(player, levelId, difficultyId)
	if not ok then
		return result(false, message)
	end
	local roomCount = 0
	for _ in pairs(parties) do
		roomCount += 1
	end
	if roomCount >= Config.Party.MaxRooms then
		return result(false, "Too many rooms on this server")
	end
	removeFromParty(player)

	local party: Party = {
		Id = HttpService:GenerateGUID(false),
		Host = player,
		Members = { player },
		Ready = {},
		LevelId = levelId,
		Difficulty = difficultyId,
		MaxSize = size,
		State = "Lobby",
		CreatedAt = os.clock(),
	}
	parties[party.Id] = party
	playerParty[player] = party
	markDirty()
	return result(true)
end

function PartyService.Join(player: Player, partyId: any)
	if not limiter:Check(player) then
		return result(false, "Slow down!")
	end
	if type(partyId) ~= "string" then
		return result(false, "Invalid room")
	end
	local party = parties[partyId]
	if not party then
		return result(false, "That room no longer exists")
	end
	if playerParty[player] == party then
		return result(true)
	end
	if party.State ~= "Lobby" then
		return result(false, "That room is already playing")
	end
	if #party.Members >= party.MaxSize then
		return result(false, "That room is full")
	end
	if LevelService.IsInMatch(player) then
		return result(false, "You are in a match")
	end
	removeFromParty(player)
	table.insert(party.Members, player)
	playerParty[player] = party
	party.Ready[player] = false
	for _, member in ipairs(party.Members) do
		if member ~= player then
			Notifier.Toast(member, player.DisplayName .. " joined the room", "Info")
		end
	end
	markDirty()
	return result(true)
end

function PartyService.Leave(player: Player)
	removeFromParty(player)
end

function PartyService.Action(player: Player, action: any, value: any)
	if not limiter:Check(player) then
		return result(false, "Slow down!")
	end
	local party = playerParty[player]
	if not party then
		return result(false, "You are not in a room")
	end
	if party.State ~= "Lobby" then
		return result(false, "The match is in progress")
	end
	local isHost = party.Host == player

	if action == "SetReady" then
		if type(value) ~= "boolean" then
			return result(false, "Invalid value")
		end
		party.Ready[player] = value
		markDirty()
		return result(true)
	end

	if not isHost then
		return result(false, "Only the HOST can do that")
	end

	if action == "Kick" then
		if type(value) ~= "number" then
			return result(false, "Invalid player")
		end
		for _, member in ipairs(party.Members) do
			if member.UserId == value and member ~= player then
				removeFromParty(member, "You were removed from the room")
				return result(true)
			end
		end
		return result(false, "Player not in room")
	elseif action == "SetLevel" then
		if not LevelConfig.IsValid(value) then
			return result(false, "Invalid level")
		end
		local ok, message = canPlayLevel(player, value, party.Difficulty)
		if not ok then
			return result(false, message)
		end
		party.LevelId = value
	elseif action == "SetDifficulty" then
		if not DifficultyConfig.IsValid(value) then
			return result(false, "Invalid difficulty")
		end
		local ok, message = canPlayLevel(player, party.LevelId, value)
		if not ok then
			return result(false, message)
		end
		party.Difficulty = value
	elseif action == "SetSize" then
		if not validSize(value) then
			return result(false, "Invalid size")
		end
		if value < #party.Members then
			return result(false, "Kick players first to make the room smaller")
		end
		party.MaxSize = value
	else
		return result(false, "Unknown action")
	end

	-- Settings changed: everyone has to confirm again
	for _, member in ipairs(party.Members) do
		if member ~= party.Host then
			party.Ready[member] = false
		end
	end
	markDirty()
	return result(true)
end

function PartyService.StartMatch(player: Player)
	if not limiter:Check(player) then
		return result(false, "Slow down!")
	end
	local party = playerParty[player]
	if not party then
		return result(false, "You are not in a room")
	end
	if party.Host ~= player then
		return result(false, "Only the HOST can start")
	end
	if party.State ~= "Lobby" then
		return result(false, "Already playing")
	end
	local ok, message = canPlayLevel(player, party.LevelId, party.Difficulty)
	if not ok then
		return result(false, message)
	end
	if Config.Party.ReadyRequired then
		for _, member in ipairs(party.Members) do
			if member ~= party.Host and not party.Ready[member] then
				return result(false, member.DisplayName .. " is not ready")
			end
		end
	end
	for _, member in ipairs(party.Members) do
		if LevelService.IsInMatch(member) then
			return result(false, member.DisplayName .. " is still in a match")
		end
	end

	party.State = "InGame"
	local started, err = LevelService.StartMatch(party, table.clone(party.Members))
	if not started then
		party.State = "Lobby"
		markDirty()
		return result(false, err)
	end
	markDirty()
	return result(true)
end

function PartyService.Init()
	Remotes.CreateParty.OnServerInvoke = function(player, levelId, difficultyId, size)
		return PartyService.Create(player, levelId, difficultyId, size)
	end
	Remotes.JoinParty.OnServerInvoke = function(player, partyId)
		return PartyService.Join(player, partyId)
	end
	Remotes.StartParty.OnServerInvoke = function(player)
		return PartyService.StartMatch(player)
	end
	Remotes.PartyAction.OnServerInvoke = function(player, action, value)
		return PartyService.Action(player, action, value)
	end
	Remotes.LeaveParty.OnServerEvent:Connect(function(player)
		if limiter:Check(player) and not LevelService.IsInMatch(player) then
			removeFromParty(player)
		end
	end)
end

function PartyService.Start()
	Players.PlayerRemoving:Connect(function(player)
		removeFromParty(player)
	end)
	Players.PlayerAdded:Connect(markDirty)

	-- A player who quits a match mid-game also leaves the room
	LevelService.PlayerLeftMatch:Connect(function(player, _match, voluntary)
		if voluntary then
			removeFromParty(player)
		end
	end)

	-- Back to the room after a match, with the next level pre-selected when possible
	LevelService.MatchEnded:Connect(function(party)
		if not party or not parties[party.Id] then
			return
		end
		party.State = "Lobby"
		for _, member in ipairs(party.Members) do
			party.Ready[member] = false
		end
		local nextLevel = LevelConfig.GetNext(party.LevelId)
		local hostData = PlayerDataService.Get(party.Host)
		if nextLevel and hostData and hostData.UnlockedLevels[nextLevel.LevelId] then
			party.LevelId = nextLevel.LevelId
			Notifier.Toast(party.Host, "Next level selected: " .. nextLevel.Name, "Info")
		end
		markDirty()
	end)

	-- Member levels are shown in the room panel
	local knownLevels: { [Player]: number } = {}
	PlayerDataService.Changed:Connect(function(player, data)
		if playerParty[player] and knownLevels[player] ~= data.Level then
			knownLevels[player] = data.Level
			markDirty()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		knownLevels[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if dirty and elapsed >= 0.2 then
			elapsed = 0
			dirty = false
			broadcast()
		end
	end)
end

return PartyService
