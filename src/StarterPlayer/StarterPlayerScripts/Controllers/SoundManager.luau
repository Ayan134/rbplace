--[[
	SoundManager
	Centralized client sound system. Every sound is referenced by name from
	Shared.SoundConfig - no script hardcodes SoundIds.

	SoundManager.Play("StickerRip")                          -- 2D
	SoundManager.Play("Peel", { Position = pos })            -- 3D at a world position
	SoundManager.Play("Combo", { PlaybackSpeed = 1.4 })      -- pitch override
	SoundManager.PlayTheme("Fountain")                       -- level music + ambience, crossfaded
	SoundManager.PlayMusic("ResultsMusic")                   -- music channel only
	SoundManager.Duck(2)                                     -- lowers music under a jingle

	Each sound has a fallback chain of ids. Templates start on the first id and are
	preloaded in the background; an id that fails to load is replaced by the next one
	everywhere (templates, pooled copies and the playing music/ambience).
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared.SoundConfig)

local SoundManager = {}

type Channel = { Name: string?, Sound: Sound?, Target: number }

local templates: { [string]: Sound } = {}
local pools: { [string]: { Sound } } = {}
local groups: { [string]: SoundGroup } = {}
local resolvedIndex: { [string]: number } = {}
local channels: { [string]: Channel } = {
	Music = { Name = nil, Sound = nil, Target = 0 },
	Ambience = { Name = nil, Sound = nil, Target = 0 },
}
local positionalAnchor: BasePart
local rng = Random.new()
local lastPlayed: { [string]: number } = {}
local duckToken = 0

local MIN_INTERVAL = 0.03 -- the same sound can't stack more often than this
local CROSSFADE = 1.6

local function idsOf(info): { string }
	if info.SoundIds then
		return info.SoundIds
	end
	if info.Playlist then
		return { info.Playlist[1] }
	end
	return if info.SoundId and info.SoundId ~= "" then { info.SoundId } else {}
end

local function getGroup(name: string): SoundGroup
	if groups[name] then
		return groups[name]
	end
	-- Ambience lives inside the SFX group so the SFX slider controls it too
	local parent: Instance = if name == "Ambience" then getGroup("SFX") else SoundService
	local group = parent:FindFirstChild(name)
	if not group or not group:IsA("SoundGroup") then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = parent
	end
	groups[name] = group :: SoundGroup
	return group :: SoundGroup
end

local function applyId(name: string, soundId: string)
	if templates[name] then
		templates[name].SoundId = soundId
	end
	for _, sound in ipairs(pools[name] or {}) do
		sound.SoundId = soundId
	end
	for _, channel in pairs(channels) do
		local sound = channel.Sound
		if channel.Name == name and sound then
			sound.SoundId = soundId
			sound:Play()
		end
	end
end

-- Walks the fallback chain until an id loads
local function resolve(name: string)
	local info = SoundConfig.Get(name)
	local ids = idsOf(info)
	task.spawn(function()
		for index = resolvedIndex[name] or 1, #ids do
			local id = ids[index]
			if string.sub(id, 1, 11) == "rbxasset://" then
				-- Bundled with the client, always available
				resolvedIndex[name] = index
				if index > 1 then
					applyId(name, id)
				end
				return
			end
			local probe = Instance.new("Sound")
			probe.SoundId = id
			local loaded = false
			pcall(function()
				ContentProvider:PreloadAsync({ probe }, function(_, status)
					loaded = status == Enum.AssetFetchStatus.Success
				end)
			end)
			probe:Destroy()
			if loaded then
				resolvedIndex[name] = index
				if index > 1 then
					applyId(name, id)
				end
				return
			end
		end
	end)
end

local function buildTemplate(name: string): Sound?
	if templates[name] then
		return templates[name]
	end
	local info = SoundConfig.Get(name)
	if not info then
		return nil
	end
	local ids = idsOf(info)
	if #ids == 0 then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = ids[resolvedIndex[name] or 1]
	sound.Volume = info.Volume or 0.5
	sound.PlaybackSpeed = info.PlaybackSpeed or 1
	sound.Looped = info.Looped == true
	sound.SoundGroup = getGroup(info.Group or "SFX")
	templates[name] = sound
	resolve(name)
	return sound
end

local function acquire(name: string, template: Sound): Sound
	local pool = pools[name]
	if not pool then
		pool = {}
		pools[name] = pool
	end
	for _, sound in ipairs(pool) do
		if not sound.IsPlaying then
			return sound
		end
	end
	local sound = template:Clone()
	table.insert(pool, sound)
	return sound
end

export type PlayOptions = {
	Position: Vector3?,
	PlaybackSpeed: number?,
	Volume: number?,
}

function SoundManager.Play(name: string, options: PlayOptions?)
	local template = buildTemplate(name)
	if not template then
		return
	end
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < MIN_INTERVAL then
		return
	end
	lastPlayed[name] = now

	local info = SoundConfig.Get(name)
	local sound = acquire(name, template)
	local speed = (options and options.PlaybackSpeed) or info.PlaybackSpeed or 1
	if info.PitchVariance then
		speed += rng:NextNumber(-info.PitchVariance, info.PitchVariance)
	end
	sound.PlaybackSpeed = speed
	sound.Volume = (options and options.Volume) or info.Volume or 0.5

	if options and options.Position then
		local attachment = sound.Parent
		if not attachment or not attachment:IsA("Attachment") then
			attachment = Instance.new("Attachment")
			attachment.Name = "SoundEmitter"
			attachment.Parent = positionalAnchor
			sound.Parent = attachment
		end
		(attachment :: Attachment).WorldPosition = options.Position
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMaxDistance = 140
		sound.RollOffMinDistance = 14
	else
		if sound.Parent ~= SoundService then
			local oldParent = sound.Parent
			sound.Parent = SoundService
			if oldParent and oldParent:IsA("Attachment") then
				oldParent:Destroy()
			end
		end
	end
	sound.TimePosition = 0
	sound:Play()
end

-- Crossfades a looping channel ("Music" or "Ambience") to a new sound (nil = silence)
local function playChannel(channelName: string, name: string?)
	local channel = channels[channelName]
	if channel.Name == name then
		return
	end
	channel.Name = name
	local previous = channel.Sound
	channel.Sound = nil
	if previous then
		local fade = TweenService:Create(previous, TweenInfo.new(CROSSFADE), { Volume = 0 })
		fade:Play()
		fade.Completed:Once(function()
			previous:Destroy()
		end)
	end
	if not name then
		return
	end
	local template = buildTemplate(name)
	if not template then
		return
	end
	local sound = template:Clone()
	channel.Target = sound.Volume
	sound.Volume = 0
	sound.Parent = SoundService
	local info = SoundConfig.Get(name)
	if info.Playlist then
		-- Play the tracks one after another, starting at a random one
		local playlist = info.Playlist
		local index = rng:NextInteger(1, #playlist)
		local failures = 0
		local function playTrack()
			if channel.Sound ~= sound then
				return
			end
			sound.SoundId = playlist[index]
			sound.TimePosition = 0
			sound:Play()
			-- Skip tracks that never load (deleted or private)
			task.delay(12, function()
				if channel.Sound == sound and not sound.IsLoaded and failures < #playlist then
					failures += 1
					index = (index % #playlist) + 1
					playTrack()
				end
			end)
		end
		sound.Looped = false
		sound.Ended:Connect(function()
			failures = 0
			index = (index % #playlist) + 1
			playTrack()
		end)
		channel.Sound = sound
		playTrack()
	else
		sound.Looped = true
		sound:Play()
		channel.Sound = sound
	end
	TweenService:Create(sound, TweenInfo.new(CROSSFADE + 0.6), { Volume = channel.Target }):Play()
end

function SoundManager.PlayMusic(name: string?)
	playChannel("Music", name)
end

function SoundManager.PlayAmbience(name: string?)
	playChannel("Ambience", name)
end

-- Music + ambience for a place ("Lobby" or a LevelId)
function SoundManager.PlayTheme(placeId: string?)
	local theme = SoundConfig.GetTheme(placeId)
	playChannel("Music", theme.Music)
	playChannel("Ambience", theme.Ambience)
end

-- Temporarily lowers the music so a jingle can shine
function SoundManager.Duck(seconds: number, level: number?)
	local channel = channels.Music
	local sound = channel.Sound
	if not sound then
		return
	end
	duckToken += 1
	local token = duckToken
	TweenService:Create(sound, TweenInfo.new(0.25), { Volume = channel.Target * (level or 0.25) }):Play()
	task.delay(seconds, function()
		if token == duckToken and channel.Sound == sound then
			TweenService:Create(sound, TweenInfo.new(1.2), { Volume = channel.Target }):Play()
		end
	end)
end

function SoundManager.SetVolumes(sfx: number, music: number)
	getGroup("SFX").Volume = math.clamp(sfx, 0, 1)
	getGroup("Music").Volume = math.clamp(music, 0, 1)
end

function SoundManager.Init()
	positionalAnchor = Instance.new("Part")
	positionalAnchor.Name = "SoundAnchor"
	positionalAnchor.Anchored = true
	positionalAnchor.CanCollide = false
	positionalAnchor.CanQuery = false
	positionalAnchor.CanTouch = false
	positionalAnchor.Transparency = 1
	positionalAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	positionalAnchor.CFrame = CFrame.new(0, -400, 0)
	positionalAnchor.Parent = Workspace

	getGroup("Ambience")
	-- Build templates and start resolving every fallback chain in the background
	for name in pairs(SoundConfig.Sounds) do
		buildTemplate(name)
	end
end

function SoundManager.Start() end

return SoundManager
