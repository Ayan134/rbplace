--[[
	SoundManager
	Centralized client sound system. Every sound is referenced by name from
	Shared.SoundConfig - no script hardcodes SoundIds.

	SoundManager.Play("StickerRip")                          -- 2D
	SoundManager.Play("Peel", { Position = pos })            -- 3D at a world position
	SoundManager.Play("Combo", { PlaybackSpeed = 1.4 })      -- pitch override
	SoundManager.PlayAmbience("LobbyAmbience")               -- looping, crossfaded
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared.SoundConfig)

local SoundManager = {}

local templates: { [string]: Sound } = {}
local pools: { [string]: { Sound } } = {}
local groups: { [string]: SoundGroup } = {}
local ambience: Sound? = nil
local ambienceName: string? = nil
local positionalAnchor: BasePart
local rng = Random.new()
local lastPlayed: { [string]: number } = {}

local MIN_INTERVAL = 0.03 -- the same sound can't stack more often than this

local function getGroup(name: string): SoundGroup
	if groups[name] then
		return groups[name]
	end
	local group = SoundService:FindFirstChild(name)
	if not group or not group:IsA("SoundGroup") then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end
	groups[name] = group :: SoundGroup
	return group :: SoundGroup
end

local function buildTemplate(name: string): Sound?
	if templates[name] then
		return templates[name]
	end
	local info = SoundConfig.Get(name)
	if not info or info.SoundId == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = info.SoundId
	sound.Volume = info.Volume or 0.5
	sound.PlaybackSpeed = info.PlaybackSpeed or 1
	sound.Looped = info.Looped == true
	sound.SoundGroup = getGroup(info.Group or "SFX")
	templates[name] = sound
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
		sound.RollOffMaxDistance = 120
		sound.RollOffMinDistance = 12
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

function SoundManager.PlayAmbience(name: string?)
	if ambienceName == name then
		return
	end
	ambienceName = name
	local previous = ambience
	ambience = nil
	if previous then
		local fade = TweenService:Create(previous, TweenInfo.new(1.5), { Volume = 0 })
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
	local targetVolume = sound.Volume
	sound.Volume = 0
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(2), { Volume = targetVolume }):Play()
	ambience = sound
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

	-- Preload templates
	for name in pairs(SoundConfig.Sounds) do
		buildTemplate(name)
	end
end

function SoundManager.Start() end

return SoundManager
