--[[
	PartyService
	Rooms are 4 physical circles in the lobby.

	  * step into an empty circle -> you become HOST and pick: number of players,
	    "friends only", level and difficulty
	  * step into an open circle -> you join (if it isn't full, and if it's friends-only
	    you must be the host's friend)
	  * step out of the circle -> you leave the room; if the host leaves, the next player
	    becomes host; an empty circle resets
	  * the host presses START -> everyone in the circle goes to the level; the circle is
	    freed for other players. After the level the group returns to its circle if it's
	    still free, with the next level pre-selected

	Max size comes from Config.Party.MaxPartySize so rooms can grow beyond 4 later.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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

export type Pad = {
	Index: number,
	Center: Vector3,
	Radius: number,
	Ring: BasePart?,
	Title: TextLabel?,
	Status: TextLabel?,
	Party: any,
}

export type Party = {
	Id: string,
	Host: Player,
	Members: { Player },
	LevelId: string,
	Difficulty: string,
	MaxSize: number,
	FriendsOnly: boolean,
	State: string, -- "Setup" | "Open" | "InGame"
	Pad: Pad?,
	HomePad: number,
	CreatedAt: number,
}

local COLORS = {
	Empty = Color3.fromRGB(255, 255, 255),
	Setup = Color3.fromRGB(255, 210, 90),
	Open = Color3.fromRGB(110, 230, 150),
	Full = Color3.fromRGB(255, 110, 110),
}

local pads: { Pad } = {}
local parties: { [string]: Party } = {}
local playerParty: { [Player]: Party } = {}
local lastSettings: { [Player]: any } = {}
local friendCache: { [string]: boolean } = {}
local friendPending: { [Player]: boolean } = {}
local lastPushToast: { [Player]: number } = {}
local limiter = RateLimiter.new(6, 12)
local dirty = true

local function markDirty()
	dirty = true
end

local function result(success: boolean, message: string?)
	return { Success = success, Message = message }
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return root
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

local function defaultSettings(player: Player)
	local saved = lastSettings[player]
	if saved and canPlayLevel(player, saved.LevelId, saved.Difficulty) then
		return table.clone(saved)
	end
	return { LevelId = "Fountain", Difficulty = "Easy", MaxSize = Config.Party.MaxPartySize, FriendsOnly = false }
end

------------------------------------------------------------------------
-- Pads
------------------------------------------------------------------------

local function loadPads()
	local lobby = Workspace:WaitForChild("Lobby", 30)
	local container = lobby and lobby:FindFirstChild("RoomPads", true)
	if not container then
		warn("[PartyService] Lobby has no RoomPads - rooms are unavailable")
		return
	end
	for _, model in ipairs(container:GetChildren()) do
		local index = model:GetAttribute("PadIndex")
		local ring = model:FindFirstChild("Ring")
		if type(index) == "number" and ring and ring:IsA("BasePart") then
			local sign = model:FindFirstChild("RoomSign", true)
			local panel = sign and sign:FindFirstChild("Panel")
			pads[index] = {
				Index = index,
				Center = ring.Position,
				Radius = math.max(ring.Size.Y, ring.Size.Z) / 2,
				Ring = ring,
				Title = panel and panel:FindFirstChild("Title") :: TextLabel?,
				Status = panel and panel:FindFirstChild("Status") :: TextLabel?,
				Party = nil,
			}
		end
	end
end

local function padAt(position: Vector3): Pad?
	for _, pad in pairs(pads) do
		local offset = position - pad.Center
		local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if flat <= pad.Radius - 0.3 and offset.Y > -2 and offset.Y < 10 then
			return pad
		end
	end
	return nil
end

local function isInsidePad(position: Vector3, pad: Pad, margin: number): boolean
	local offset = position - pad.Center
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= pad.Radius + margin and offset.Y > -3 and offset.Y < 12
end

-- Moves a player just outside the circle (rejected entry, kick, leave button).
local function pushOut(player: Player, pad: Pad, reason: string?)
	local root = getRoot(player)
	if root then
		local offset = root.Position - pad.Center
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local direction = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
		local target = pad.Center + direction * (pad.Radius + 4) + Vector3.new(0, 3, 0)
		local character = root.Parent :: Model
		character:PivotTo(CFrame.lookAt(target, target + direction))
	end
	if reason then
		local now = os.clock()
		if not lastPushToast[player] or now - lastPushToast[player] > 2 then
			lastPushToast[player] = now
			Notifier.Toast(player, reason, "Error")
		end
	end
end

local function updatePadVisual(pad: Pad)
	local party = pad.Party
	local ring, title, status = pad.Ring, pad.Title, pad.Status
	if not ring then
		return
	end
	if not party then
		ring.Color = COLORS.Empty
		if title then
			title.Text = "ROOM " .. pad.Index
		end
		if status then
			status.Text = "Step in to create"
		end
		return
	end
	local level = LevelConfig.Get(party.LevelId)
	local difficulty = DifficultyConfig.Get(party.Difficulty)
	if party.State == "Setup" then
		ring.Color = COLORS.Setup
		if title then
			title.Text = party.Host.DisplayName .. "'s room"
		end
		if status then
			status.Text = "Setting up..."
		end
		return
	end
	local full = #party.Members >= party.MaxSize
	ring.Color = if full then COLORS.Full else COLORS.Open
	if title then
		title.Text = string.format("%s • %s", level and level.Name or "?", difficulty and difficulty.DisplayName or "?")
	end
	if status then
		status.Text = string.format("%d/%d players%s", #party.Members, party.MaxSize, if party.FriendsOnly then "  •  Friends only" else "")
	end
end

------------------------------------------------------------------------
-- Membership
------------------------------------------------------------------------

local function serializeParty(party: Party)
	local members = {}
	for _, member in ipairs(party.Members) do
		local data = PlayerDataService.Get(member)
		table.insert(members, {
			UserId = member.UserId,
			Name = member.Name,
			DisplayName = member.DisplayName,
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
		FriendsOnly = party.FriendsOnly,
		State = party.State,
		PadIndex = party.Pad and party.Pad.Index or party.HomePad,
		Members = members,
	}
end

local function removeFromParty(player: Player, reason: string?)
	local party = playerParty[player]
	if not party then
		return
	end
	playerParty[player] = nil
	local index = table.find(party.Members, player)
	if index then
		table.remove(party.Members, index)
	end
	if #party.Members == 0 then
		parties[party.Id] = nil
		if party.Pad then
			party.Pad.Party = nil
		end
	elseif party.Host == player then
		party.Host = party.Members[1]
		if party.State == "Setup" then
			party.State = "Open"
		end
		for _, member in ipairs(party.Members) do
			Notifier.Toast(member, party.Host.DisplayName .. " is now the HOST", "Info")
		end
	end
	if reason and player.Parent then
		Notifier.Toast(player, reason, "Info")
	end
	markDirty()
end

local function createParty(player: Player, pad: Pad)
	local settings = defaultSettings(player)
	local party: Party = {
		Id = HttpService:GenerateGUID(false),
		Host = player,
		Members = { player },
		LevelId = settings.LevelId,
		Difficulty = settings.Difficulty,
		MaxSize = settings.MaxSize,
		FriendsOnly = settings.FriendsOnly,
		State = "Setup",
		Pad = pad,
		HomePad = pad.Index,
		CreatedAt = os.clock(),
	}
	parties[party.Id] = party
	playerParty[player] = party
	pad.Party = party
	markDirty()
end

local function isFriend(player: Player, hostUserId: number): boolean?
	local key = math.min(player.UserId, hostUserId) .. ":" .. math.max(player.UserId, hostUserId)
	local cached = friendCache[key]
	if cached ~= nil then
		return cached
	end
	if not friendPending[player] then
		friendPending[player] = true
		task.spawn(function()
			local ok, isFriends = pcall(function()
				return (player :: any):IsFriendsWithAsync(hostUserId)
			end)
			if not ok then
				ok, isFriends = pcall(function()
					return (player :: any):IsFriendsWith(hostUserId)
				end)
			end
			friendCache[key] = ok and isFriends == true
			friendPending[player] = nil
		end)
	end
	return nil -- still checking
end

local function tryEnter(player: Player, pad: Pad)
	local party = pad.Party
	if not party then
		createParty(player, pad)
		return
	end
	if party.State == "Setup" then
		pushOut(player, pad, party.Host.DisplayName .. " is setting up this room")
		return
	end
	if #party.Members >= party.MaxSize then
		pushOut(player, pad, "This room is full")
		return
	end
	if party.FriendsOnly then
		local friend = isFriend(player, party.Host.UserId)
		if friend == nil then
			return -- decided on a later tick
		elseif not friend then
			pushOut(player, pad, "This room is for " .. party.Host.DisplayName .. "'s friends only")
			return
		end
	end
	table.insert(party.Members, player)
	playerParty[player] = party
	for _, member in ipairs(party.Members) do
		if member ~= player then
			Notifier.Toast(member, player.DisplayName .. " joined the room", "Info")
		end
	end
	markDirty()
end

local function scanPads()
	for _, player in ipairs(Players:GetPlayers()) do
		if LevelService.IsInMatch(player) or not PlayerDataService.IsLoaded(player) then
			continue
		end
		local root = getRoot(player)
		if not root then
			continue
		end
		local position = root.Position
		local party = playerParty[player]
		if party and party.Pad then
			-- Standing in our room: leave once clearly outside the circle
			if not isInsidePad(position, party.Pad, 1) then
				removeFromParty(player)
			end
		else
			local pad = padAt(position)
			if pad then
				if party then
					-- Came back early from a level and walked into another circle
					removeFromParty(player)
				end
				tryEnter(player, pad)
			end
		end
	end
end

------------------------------------------------------------------------
-- Remote handlers
------------------------------------------------------------------------

function PartyService.GetParty(player: Player): Party?
	return playerParty[player]
end

function PartyService.Configure(player: Player, settings: any)
	if not limiter:Check(player) then
		return result(false, "Slow down!")
	end
	local party = playerParty[player]
	if not party or not party.Pad then
		return result(false, "Step into a circle to create a room")
	end
	if party.Host ~= player then
		return result(false, "Only the HOST can change the room")
	end
	if type(settings) ~= "table" then
		return result(false, "Invalid settings")
	end
	local levelId = settings.LevelId
	local difficultyId = settings.Difficulty
	local size = settings.MaxSize
	local friendsOnly = settings.FriendsOnly
	if not LevelConfig.IsValid(levelId) or not DifficultyConfig.IsValid(difficultyId) or not validSize(size) or type(friendsOnly) ~= "boolean" then
		return result(false, "Invalid settings")
	end
	local ok, message = canPlayLevel(player, levelId, difficultyId)
	if not ok then
		return result(false, message)
	end
	if size < #party.Members then
		return result(false, "There are more players in the circle than that")
	end
	party.LevelId = levelId
	party.Difficulty = difficultyId
	party.MaxSize = size
	party.FriendsOnly = friendsOnly
	party.State = "Open"
	lastSettings[player] = { LevelId = levelId, Difficulty = difficultyId, MaxSize = size, FriendsOnly = friendsOnly }
	markDirty()
	return result(true)
end

function PartyService.Kick(player: Player, userId: any)
	local party = playerParty[player]
	if not party or party.Host ~= player or not party.Pad then
		return result(false, "Only the HOST can do that")
	end
	if type(userId) ~= "number" then
		return result(false, "Invalid player")
	end
	for _, member in ipairs(party.Members) do
		if member.UserId == userId and member ~= player then
			local pad = party.Pad
			removeFromParty(member, "You were removed from the room")
			pushOut(member, pad, nil)
			return result(true)
		end
	end
	return result(false, "Player not in room")
end

function PartyService.StartMatch(player: Player)
	if not limiter:Check(player) then
		return result(false, "Slow down!")
	end
	local party = playerParty[player]
	if not party or not party.Pad then
		return result(false, "Step into a circle to create a room")
	end
	if party.Host ~= player then
		return result(false, "Only the HOST can start")
	end
	if party.State ~= "Open" then
		return result(false, "Finish setting up the room first")
	end
	local ok, message = canPlayLevel(player, party.LevelId, party.Difficulty)
	if not ok then
		return result(false, message)
	end
	local pad = party.Pad :: Pad
	local started, err = LevelService.StartMatch(party, table.clone(party.Members))
	if not started then
		return result(false, err)
	end
	-- The circle is free for others while this group plays
	party.State = "InGame"
	party.HomePad = pad.Index
	party.Pad = nil
	pad.Party = nil
	markDirty()
	return result(true)
end

local function onMatchEnded(party)
	if not party or not parties[party.Id] then
		return
	end
	local members = {}
	for _, member in ipairs(party.Members) do
		if member.Parent and not LevelService.IsInMatch(member) then
			table.insert(members, member)
		end
	end
	if #members == 0 then
		for _, member in ipairs(table.clone(party.Members)) do
			removeFromParty(member)
		end
		return
	end
	local pad = pads[party.HomePad]
	if not pad or pad.Party then
		for _, member in ipairs(table.clone(party.Members)) do
			removeFromParty(member, "Your circle is taken - step into a free circle")
		end
		return
	end
	-- Back into the same circle, ready for the next level
	party.Members = members
	if not table.find(members, party.Host) then
		party.Host = members[1]
	end
	party.Pad = pad
	party.State = "Open"
	pad.Party = party
	local nextLevel = LevelConfig.GetNext(party.LevelId)
	if nextLevel and canPlayLevel(party.Host, nextLevel.LevelId, party.Difficulty) then
		party.LevelId = nextLevel.LevelId
		Notifier.Toast(party.Host, "Next level selected: " .. nextLevel.Name, "Info")
	end
	for index, member in ipairs(members) do
		local angle = (index / #members) * math.pi * 2
		local position = pad.Center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * math.min(3, pad.Radius - 2) + Vector3.new(0, 3, 0)
		local character = member.Character
		if character then
			character:PivotTo(CFrame.lookAt(position, Vector3.new(pad.Center.X, position.Y, pad.Center.Z)))
		end
	end
	markDirty()
end

local function broadcast()
	for _, pad in pairs(pads) do
		updatePadVisual(pad)
	end
	local padList = {}
	for index = 1, #pads do
		local pad = pads[index]
		local party = pad and pad.Party
		table.insert(padList, {
			Index = index,
			State = if party then party.State else "Empty",
			HostName = party and party.Host.DisplayName,
			LevelId = party and party.LevelId,
			Difficulty = party and party.Difficulty,
			MaxSize = party and party.MaxSize,
			Count = party and #party.Members or 0,
			FriendsOnly = party and party.FriendsOnly or false,
			Center = pad and pad.Center,
		})
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local party = playerParty[player]
		Remotes.PartyUpdate:FireClient(player, {
			Pads = padList,
			MyParty = party and serializeParty(party),
			MaxPartySize = Config.Party.MaxPartySize,
		})
	end
end

function PartyService.Init()
	Remotes.ConfigureRoom.OnServerInvoke = function(player, settings)
		return PartyService.Configure(player, settings)
	end
	Remotes.StartParty.OnServerInvoke = function(player)
		return PartyService.StartMatch(player)
	end
	Remotes.PartyAction.OnServerInvoke = function(player, action, value)
		if not limiter:Check(player) then
			return result(false, "Slow down!")
		end
		if action == "Kick" then
			return PartyService.Kick(player, value)
		end
		return result(false, "Unknown action")
	end
	Remotes.LeaveParty.OnServerEvent:Connect(function(player)
		local party = playerParty[player]
		if party and party.Pad and limiter:Check(player) then
			local pad = party.Pad
			removeFromParty(player)
			pushOut(player, pad, nil)
		end
	end)
end

function PartyService.Start()
	loadPads()

	Players.PlayerRemoving:Connect(function(player)
		removeFromParty(player)
		lastSettings[player] = nil
		friendPending[player] = nil
		lastPushToast[player] = nil
	end)
	Players.PlayerAdded:Connect(markDirty)

	-- A player who quits a level mid-game also leaves the room
	LevelService.PlayerLeftMatch:Connect(function(player, _match, voluntary)
		if voluntary then
			removeFromParty(player)
		end
	end)
	LevelService.MatchEnded:Connect(onMatchEnded)

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

	local scanElapsed = 0
	local broadcastElapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		scanElapsed += dt
		broadcastElapsed += dt
		if scanElapsed >= 0.2 then
			scanElapsed = 0
			scanPads()
		end
		if dirty and broadcastElapsed >= 0.2 then
			broadcastElapsed = 0
			dirty = false
			broadcast()
		end
	end)
end

return PartyService
