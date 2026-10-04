--[[
	StickerService
	ONE service owns the state of every sticker on the server. No sticker Instances
	exist on the server and no scripts live inside stickers.

	A "session" is a set of stickers shared by a group of players (a match arena, or
	the lobby showcase). The server is the authority:
	  * clients ask to Start / Complete / Cancel a peel
	  * the server validates (exists, alive, not locked, distance, tool tier, capacity,
	    rate limit, enough time elapsed) and broadcasts the result
	  * every member sees the same stickers disappear

	Network:
	  StickerData   (server -> client)  session snapshot in compact buffer chunks
	  StickerUpdate (server -> client)  batched events: S = started, C = cancelled, P = peeled, R = rejected
	  PeelSticker   (client -> server)  action, stickerId
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerStats = require(Shared.PlayerStats)
local StickerCodec = require(Shared.StickerCodec)
local StickerConfig = require(Shared.StickerConfig)
local Signal = require(Shared.Signal)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ToolService = require(script.Parent.ToolService)
local RateLimiter = require(script.Parent.Parent.Systems.RateLimiter)

local StickerService = {}

export type Session = {
	Id: string,
	Kind: string, -- "Match" | "Showcase"
	Stickers: { any },
	Total: number,
	Alive: number,
	Members: { [Player]: boolean },
	Difficulty: any,
	Meta: { [string]: any },
	Pending: { any },
	ActivePeels: { [Player]: { [number]: boolean } },
	Peeled: any, -- Signal(player?, sticker)
	Locked: boolean,
	Version: number,
}

local sessions: { [string]: Session } = {}
local playerSession: { [Player]: Session } = {}
local limiter = RateLimiter.new(Config.Peel.MaxRequestsPerSecond, Config.Peel.MaxRequestsPerSecond * 1.5)

-- Optional hook set by other services: (session, player, sticker) -> reward table
StickerService.RewardHandler = nil :: ((Session, Player?, any) -> any)?

local function queue(session: Session, event)
	table.insert(session.Pending, event)
end

local function flush(session: Session)
	if #session.Pending == 0 then
		return
	end
	local events = session.Pending
	session.Pending = {}
	for player in pairs(session.Members) do
		Remotes.StickerUpdate:FireClient(player, session.Id, events)
	end
end

local function sendSnapshot(session: Session, player: Player)
	local stickers = session.Stickers
	local total = #stickers
	local chunkSize = Config.Match.ChunkSize
	local chunkCount = math.max(1, math.ceil(total / chunkSize))
	local version = session.Version
	task.spawn(function()
		for chunk = 1, chunkCount do
			if not session.Members[player] or session.Version ~= version or not sessions[session.Id] then
				return
			end
			local first = (chunk - 1) * chunkSize + 1
			local last = math.min(total, chunk * chunkSize)
			local payload = if total > 0 then StickerCodec.Encode(stickers, first, last) else buffer.create(0)
			Remotes.StickerData:FireClient(player, {
				SessionId = session.Id,
				Kind = session.Kind,
				Version = version,
				Total = total,
				Alive = session.Alive,
				Chunk = chunk,
				ChunkCount = chunkCount,
				FirstId = first,
				Difficulty = session.Difficulty and session.Difficulty.Id,
				Meta = session.Meta,
			}, payload)
			if chunk < chunkCount then
				task.wait(0.05)
			end
		end
		-- Re-send in-progress peels so late joiners see them animating
		local now = os.clock()
		local events = {}
		for _, sticker in ipairs(stickers) do
			if sticker.Alive and sticker.State == "Peeling" and sticker.Peeler then
				local remaining = math.max(0.05, sticker.PeelStart + sticker.PeelDuration - now)
				local elapsedFraction = 1 - remaining / sticker.PeelDuration
				local progress = sticker.PeelStartProgress + (1 - sticker.PeelStartProgress) * math.clamp(elapsedFraction, 0, 1)
				table.insert(events, { "S", sticker.Id, sticker.Peeler.UserId, remaining, progress })
			end
		end
		if #events > 0 and session.Members[player] then
			Remotes.StickerUpdate:FireClient(player, session.Id, events)
		end
	end)
end

function StickerService.CreateSession(id: string, kind: string, stickers: { any }, difficulty, meta): Session
	local alive = 0
	for _, sticker in ipairs(stickers) do
		if sticker.Alive then
			alive += 1
		end
	end
	local session: Session = {
		Id = id,
		Kind = kind,
		Stickers = stickers,
		Total = #stickers,
		Alive = alive,
		Members = {},
		Difficulty = difficulty,
		Meta = meta or {},
		Pending = {},
		ActivePeels = {},
		Peeled = Signal.new(),
		Locked = false,
		Version = 1,
	}
	sessions[id] = session
	return session
end

-- Replaces all stickers of a session (used by the lobby showcase regeneration).
function StickerService.ReplaceStickers(session: Session, stickers: { any })
	session.Version += 1
	session.Stickers = stickers
	session.Total = #stickers
	session.Alive = #stickers
	session.ActivePeels = {}
	session.Pending = {}
	for player in pairs(session.Members) do
		sendSnapshot(session, player)
	end
end

function StickerService.GetSession(id: string): Session?
	return sessions[id]
end

function StickerService.GetPlayerSession(player: Player): Session?
	return playerSession[player]
end

local function cancelPeel(session: Session, sticker, reason: string?)
	if sticker.State ~= "Peeling" then
		return
	end
	local peeler = sticker.Peeler
	local elapsed = os.clock() - sticker.PeelStart
	local fraction = math.clamp(elapsed / math.max(sticker.PeelDuration, 0.01), 0, 1)
	local progress = sticker.PeelStartProgress + (1 - sticker.PeelStartProgress) * fraction
	sticker.Progress = math.min(progress, Config.Peel.MaxStoredProgress)
	sticker.State = "Attached"
	sticker.Peeler = nil
	if peeler and session.ActivePeels[peeler] then
		session.ActivePeels[peeler][sticker.Id] = nil
	end
	queue(session, { "C", sticker.Id, sticker.Progress, reason })
end

function StickerService.RemoveMember(player: Player)
	local session = playerSession[player]
	if not session then
		return
	end
	local active = session.ActivePeels[player]
	if active then
		for stickerId in pairs(active) do
			local sticker = session.Stickers[stickerId]
			if sticker then
				cancelPeel(session, sticker)
			end
		end
	end
	session.ActivePeels[player] = nil
	session.Members[player] = nil
	playerSession[player] = nil
	if player.Parent then
		Remotes.StickerData:FireClient(player, { SessionId = session.Id, Clear = true })
	end
end

function StickerService.AddMember(session: Session, player: Player)
	if playerSession[player] == session then
		return
	end
	StickerService.RemoveMember(player)
	session.Members[player] = true
	session.ActivePeels[player] = {}
	playerSession[player] = session
	sendSnapshot(session, player)
end

function StickerService.DestroySession(session: Session)
	for player in pairs(session.Members) do
		StickerService.RemoveMember(player)
	end
	session.Peeled:DisconnectAll()
	sessions[session.Id] = nil
end

-- Server-side peel used by the lobby "ghost" demo (no player).
function StickerService.GhostPeel(session: Session, stickerId: number, duration: number)
	local sticker = session.Stickers[stickerId]
	if not sticker or not sticker.Alive or sticker.State ~= "Attached" then
		return false
	end
	sticker.State = "Peeling"
	sticker.PeelStart = os.clock()
	sticker.PeelDuration = duration
	sticker.PeelStartProgress = sticker.Progress
	queue(session, { "S", sticker.Id, 0, duration, sticker.Progress })
	local version = session.Version
	task.delay(duration, function()
		if session.Version ~= version or (sticker.State :: string) ~= "Peeling" or sticker.Peeler then
			return
		end
		sticker.Alive = false
		sticker.State = "Peeled"
		session.Alive -= 1
		queue(session, { "P", sticker.Id, 0 })
		session.Peeled:Fire(nil, sticker)
	end)
	return true
end

local function reject(player: Player, session: Session, stickerId: number, reason: string)
	Remotes.StickerUpdate:FireClient(player, session.Id, { { "R", stickerId, reason } })
end

local function getRootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return (root :: BasePart).Position
end

local function handleStart(player: Player, session: Session, sticker)
	if session.Locked then
		return reject(player, session, sticker.Id, "Locked")
	end
	if not sticker.Alive then
		return reject(player, session, sticker.Id, "Gone")
	end
	if sticker.State == "Peeling" then
		if sticker.Peeler == player then
			return -- duplicate request
		end
		return reject(player, session, sticker.Id, "Busy")
	end

	local position = getRootPosition(player)
	if not position or (position - sticker.Position).Magnitude > Config.Peel.MaxDistance then
		return reject(player, session, sticker.Id, "TooFar")
	end

	local data = PlayerDataService.Get(player)
	if not data then
		return reject(player, session, sticker.Id, "NoData")
	end
	local stats = PlayerStats.Compute(data)
	local requiredTier = StickerConfig.GetRequiredToolTier(sticker.Type, session.Difficulty)
	if stats.ToolTier < requiredTier then
		return reject(player, session, sticker.Id, "Tool:" .. requiredTier)
	end

	local active = session.ActivePeels[player]
	local activeCount = 0
	for _ in pairs(active) do
		activeCount += 1
	end
	if activeCount >= stats.Capacity then
		return reject(player, session, sticker.Id, "Capacity")
	end

	local fullDuration = PlayerStats.GetPeelDuration(stats, sticker.Health)
	local remaining = math.max(0.1, fullDuration * (1 - sticker.Progress))
	sticker.State = "Peeling"
	sticker.Peeler = player
	sticker.PeelStart = os.clock()
	sticker.PeelDuration = remaining
	sticker.PeelStartProgress = sticker.Progress
	active[sticker.Id] = true
	queue(session, { "S", sticker.Id, player.UserId, remaining, sticker.Progress })
	if activeCount == 0 then
		ToolService.PlayPeelAnimation(player)
	end
	return
end

local function handleComplete(player: Player, session: Session, sticker)
	if not sticker.Alive or sticker.State ~= "Peeling" or sticker.Peeler ~= player then
		return reject(player, session, sticker.Id, "NotPeeling")
	end
	local elapsed = os.clock() - sticker.PeelStart
	local required = sticker.PeelDuration * Config.Peel.MinDurationFactor - Config.Peel.MinDurationLeeway
	if elapsed < required then
		-- Too fast: likely an exploit or a big lag spike. Keep it peeling; the client may retry.
		return reject(player, session, sticker.Id, "TooFast")
	end
	local position = getRootPosition(player)
	if not position or (position - sticker.Position).Magnitude > Config.Peel.MaxDistance + 6 then
		cancelPeel(session, sticker, "TooFar")
		return
	end

	sticker.Alive = false
	sticker.State = "Peeled"
	sticker.Progress = 1
	sticker.Peeler = nil
	session.ActivePeels[player][sticker.Id] = nil
	session.Alive -= 1

	local reward = nil
	if StickerService.RewardHandler then
		reward = StickerService.RewardHandler(session, player, sticker)
	end
	queue(session, {
		"P",
		sticker.Id,
		player.UserId,
		reward and reward.Coins or 0,
		reward and reward.Combo or 0,
		reward and reward.Lucky or false,
		reward and reward.ComboMultiplier or 1,
	})
	session.Peeled:Fire(player, sticker)
	return
end

local function handleCancel(player: Player, session: Session, sticker)
	if sticker.State == "Peeling" and sticker.Peeler == player then
		cancelPeel(session, sticker)
	end
end

local function onPeelRequest(player: Player, action: any, stickerId: any)
	if type(action) ~= "string" or type(stickerId) ~= "number" then
		return
	end
	if stickerId ~= stickerId or stickerId % 1 ~= 0 then
		return
	end
	if not limiter:Check(player) then
		return
	end
	local session = playerSession[player]
	if not session then
		return
	end
	local sticker = session.Stickers[stickerId]
	if not sticker then
		return
	end
	if action == "Start" then
		handleStart(player, session, sticker)
	elseif action == "Complete" then
		handleComplete(player, session, sticker)
	elseif action == "Cancel" then
		handleCancel(player, session, sticker)
	end
end

function StickerService.Init()
	Remotes.PeelSticker.OnServerEvent:Connect(onPeelRequest)
	Players.PlayerRemoving:Connect(function(player)
		StickerService.RemoveMember(player)
	end)
end

function StickerService.Start()
	local accumulator = 0
	local staleCheck = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		staleCheck += dt
		if accumulator >= 0.05 then
			accumulator = 0
			for _, session in pairs(sessions) do
				flush(session)
			end
		end
		if staleCheck >= 1 then
			staleCheck = 0
			local now = os.clock()
			for _, session in pairs(sessions) do
				for player, active in pairs(session.ActivePeels) do
					for stickerId in pairs(active) do
						local sticker = session.Stickers[stickerId]
						if sticker and sticker.State == "Peeling" then
							if now > sticker.PeelStart + sticker.PeelDuration + Config.Peel.StalePeelTimeout then
								cancelPeel(session, sticker, "Timeout")
							end
						else
							active[stickerId] = nil
						end
					end
					if not player.Parent then
						session.ActivePeels[player] = nil
					end
				end
			end
		end
	end)
end

return StickerService
