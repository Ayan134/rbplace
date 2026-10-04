--[[
	PlayerDataService
	Loads, caches and saves persistent player data with DataStoreService.

	Data-loss protection:
	  * UpdateAsync everywhere (never SetAsync), with exponential-backoff retries
	  * Session locking: a server claims the profile on load; other servers wait, and only
	    steal the lock once it is stale (Config.Data.SessionLockTimeout)
	  * If loading fails the player is kicked instead of playing on default data that
	    would later overwrite the real save
	  * Saves are refused if another server has taken the lock
	  * Autosave + save on leave + BindToClose
	  * In Studio without API access the service falls back to in-memory data
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Signal = require(Shared.Signal)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = {}

PlayerDataService.Loaded = Signal.new() -- (player, data)
PlayerDataService.Changed = Signal.new() -- (player, data)

local DEFAULT_DATA = {
	Version = Config.Data.SchemaVersion,
	Coins = 0,
	Gems = 0,
	XP = 0,
	Level = 1,
	UnlockedLevels = { Fountain = true },
	UnlockedTools = { Hand = true },
	EquippedTool = "Hand",
	Upgrades = {
		PeelPower = 0,
		PeelSpeed = 0,
		StickerCapacity = 0,
		Luck = 0,
		RewardMultiplier = 0,
	},
	Statistics = {
		StickersPeeled = 0,
		RareFound = 0,
		LevelsCompleted = 0,
		CoinsEarned = 0,
		GemsEarned = 0,
		MatchesPlayed = 0,
		HighestCombo = 0,
		PlayTime = 0,
		CoopStickers = 0,
		RareByType = {},
	},
	BestTimes = {}, -- [LevelId_Difficulty] = seconds
	Completed = {}, -- [LevelId_Difficulty] = number of completions
	Quests = { Day = 0, List = {} },
	Daily = { Day = 0, BestComboToday = 0 },
	Settings = {
		MusicVolume = 0.5,
		SFXVolume = 0.8,
		LowVFX = false,
		AutoChain = true,
		ShowOthersVFX = true,
	},
	FirstJoin = 0,
	LastJoin = 0,
}

type Profile = {
	Data: any,
	Dirty: boolean,
	LastSave: number,
	JoinTime: number,
	PushQueued: boolean,
	Released: boolean,
}

local profiles: { [Player]: Profile } = {}
local loading: { [Player]: boolean } = {}

local store: DataStore? = nil
local memoryMode = false

local function isApiAccessError(err: any): boolean
	local message = tostring(err)
	return message:find("StudioAccessToApisNotAllowed") ~= nil
		or message:find("publish") ~= nil
		or message:find("403") ~= nil
end

local function enableMemoryMode(reason: string)
	if not memoryMode then
		memoryMode = true
		warn("[PlayerDataService] DataStores unavailable (" .. reason .. "). Using in-memory data - progress will NOT be saved.")
	end
end

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Data.DataStoreName)
	end)
	if ok then
		store = result
	else
		enableMemoryMode(tostring(result))
	end
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

-- Runs `callback` with retries and exponential backoff. Returns success, result.
local function withRetries(label: string, callback: () -> any): (boolean, any)
	local lastError
	for attempt = 1, Config.Data.MaxRetries do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		if RunService:IsStudio() and isApiAccessError(result) then
			enableMemoryMode(tostring(result))
			return false, "memory"
		end
		warn(string.format("[PlayerDataService] %s failed (attempt %d/%d): %s", label, attempt, Config.Data.MaxRetries, tostring(result)))
		if attempt < Config.Data.MaxRetries then
			task.wait(math.min(2 ^ (attempt - 1), 16))
		end
	end
	return false, lastError
end

local function migrate(data)
	data.Version = data.Version or 1
	-- Future schema changes go here, e.g.:
	-- if data.Version < 2 then ... data.Version = 2 end
	return data
end

local function sanitize(data)
	-- Repair anything that could have been corrupted or removed from configs
	data.Coins = math.max(0, math.floor(tonumber(data.Coins) or 0))
	data.Gems = math.max(0, math.floor(tonumber(data.Gems) or 0))
	data.Level = math.clamp(math.floor(tonumber(data.Level) or 1), 1, Config.XP.MaxLevel)
	data.XP = math.max(0, tonumber(data.XP) or 0)
	data.UnlockedTools.Hand = true
	data.UnlockedLevels.Fountain = true
	if not data.UnlockedTools[data.EquippedTool] then
		data.EquippedTool = "Hand"
	end
	return data
end

local function newDefault()
	local data = Utility.DeepCopy(DEFAULT_DATA)
	data.FirstJoin = os.time()
	return data
end

-- Snapshot sent to the client (internal fields stripped)
local function clientSnapshot(data)
	local snapshot = Utility.DeepCopy(data)
	snapshot.SessionLock = nil
	return snapshot
end

function PlayerDataService.PushToClient(player: Player)
	local profile = profiles[player]
	if not profile or profile.PushQueued then
		return
	end
	profile.PushQueued = true
	task.delay(0.08, function()
		profile.PushQueued = false
		if profiles[player] == profile and player.Parent then
			Remotes.UpdateUI:FireClient(player, clientSnapshot(profile.Data))
		end
	end)
end

local function loadData(player: Player)
	if memoryMode or not store then
		return true, newDefault()
	end

	local key = keyFor(player)
	local lockAttempts = 4
	for attempt = 1, lockAttempts do
		local lockedByOther = false
		local forceSteal = attempt == lockAttempts
		local ok, result = withRetries("Load " .. key, function()
			return (store :: DataStore):UpdateAsync(key, function(old)
				local data = old or newDefault()
				local lock = data.SessionLock
				if lock and lock.JobId ~= game.JobId and not forceSteal then
					if os.time() - (lock.Time or 0) < Config.Data.SessionLockTimeout then
						lockedByOther = true
						return nil -- cancel write, someone else owns this profile right now
					end
				end
				data.SessionLock = { JobId = game.JobId, Time = os.time() }
				return data
			end)
		end)
		if not ok then
			if result == "memory" then
				return true, newDefault()
			end
			return false, result
		end
		if not lockedByOther then
			return true, result or newDefault()
		end
		warn(string.format("[PlayerDataService] %s is locked by another server, waiting (%d/%d)", key, attempt, lockAttempts))
		task.wait(5)
		if not player.Parent then
			return false, "left"
		end
	end
	return false, "lock"
end

local function saveData(player: Player, profile: Profile, release: boolean): boolean
	if memoryMode or not store then
		profile.Dirty = false
		return true
	end
	local data = profile.Data
	if release then
		data.SessionLock = nil
	else
		data.SessionLock = { JobId = game.JobId, Time = os.time() }
	end
	local payload = Utility.DeepCopy(data)
	local refused = false
	local ok, err = withRetries("Save " .. keyFor(player), function()
		return (store :: DataStore):UpdateAsync(keyFor(player), function(old)
			if old and old.SessionLock and old.SessionLock.JobId ~= game.JobId then
				refused = true
				return nil -- another server stole the lock; never overwrite its newer data
			end
			return payload
		end)
	end)
	if refused then
		warn("[PlayerDataService] Save refused for " .. player.Name .. " - session lock owned by another server")
		return false
	end
	if ok then
		profile.Dirty = false
		profile.LastSave = os.clock()
	else
		warn("[PlayerDataService] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

local function onPlayerAdded(player: Player)
	if profiles[player] or loading[player] then
		return
	end
	loading[player] = true
	local ok, result = loadData(player)
	loading[player] = nil

	if not player.Parent then
		-- Player left during load: release the lock we may have taken.
		if ok and result and not memoryMode then
			saveData(player, { Data = result, Dirty = true, LastSave = 0, JoinTime = 0, PushQueued = false, Released = true }, true)
		end
		return
	end

	if not ok then
		warn("[PlayerDataService] Could not load data for " .. player.Name .. ": " .. tostring(result))
		player:Kick("We couldn't load your save data. Your progress is safe - please rejoin in a moment.")
		return
	end

	local data = sanitize(Utility.Reconcile(migrate(result), DEFAULT_DATA))
	data.LastJoin = os.time()
	if data.FirstJoin == 0 then
		data.FirstJoin = os.time()
	end

	local profile: Profile = {
		Data = data,
		Dirty = true,
		LastSave = os.clock(),
		JoinTime = os.clock(),
		PushQueued = false,
		Released = false,
	}
	profiles[player] = profile
	PlayerDataService.Loaded:Fire(player, data)
	PlayerDataService.PushToClient(player)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if not profile or profile.Released then
		return
	end
	profile.Released = true
	profile.Data.Statistics.PlayTime += math.floor(os.clock() - profile.JoinTime)
	saveData(player, profile, true)
	profiles[player] = nil
end

function PlayerDataService.Get(player: Player)
	local profile = profiles[player]
	return profile and profile.Data
end

function PlayerDataService.IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

function PlayerDataService.WaitForData(player: Player, timeout: number?)
	local deadline = os.clock() + (timeout or 30)
	while player.Parent and not profiles[player] and os.clock() < deadline do
		task.wait(0.1)
	end
	return PlayerDataService.Get(player)
end

-- Mutates data through a callback, marks it dirty and replicates it.
function PlayerDataService.Update(player: Player, callback: (data: any) -> ()): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	callback(profile.Data)
	profile.Dirty = true
	PlayerDataService.Changed:Fire(player, profile.Data)
	PlayerDataService.PushToClient(player)
	return true
end

function PlayerDataService.IsMemoryMode(): boolean
	return memoryMode
end

local function validateSettings(payload: any)
	if type(payload) ~= "table" then
		return nil
	end
	local clean = {}
	if type(payload.MusicVolume) == "number" and payload.MusicVolume == payload.MusicVolume then
		clean.MusicVolume = math.clamp(payload.MusicVolume, 0, 1)
	end
	if type(payload.SFXVolume) == "number" and payload.SFXVolume == payload.SFXVolume then
		clean.SFXVolume = math.clamp(payload.SFXVolume, 0, 1)
	end
	for _, key in ipairs({ "LowVFX", "AutoChain", "ShowOthersVFX" }) do
		if type(payload[key]) == "boolean" then
			clean[key] = payload[key]
		end
	end
	return clean
end

function PlayerDataService.Init()
	Remotes.GetData.OnServerInvoke = function(player: Player)
		local data = PlayerDataService.Get(player)
		return data and clientSnapshot(data)
	end

	local lastSettingsUpdate: { [Player]: number } = {}
	Remotes.UpdateSettings.OnServerEvent:Connect(function(player: Player, payload: any)
		local now = os.clock()
		if lastSettingsUpdate[player] and now - lastSettingsUpdate[player] < 0.25 then
			return
		end
		lastSettingsUpdate[player] = now
		local clean = validateSettings(payload)
		if not clean then
			return
		end
		PlayerDataService.Update(player, function(data)
			for key, value in pairs(clean) do
				data.Settings[key] = value
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSettingsUpdate[player] = nil
	end)
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(Config.Data.AutosaveInterval)
			for player, profile in pairs(profiles) do
				if profile.Dirty and not profile.Released then
					task.spawn(saveData, player, profile, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, profile in pairs(profiles) do
			if not profile.Released then
				profile.Released = true
				pending += 1
				task.spawn(function()
					saveData(player, profile, true)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return PlayerDataService
