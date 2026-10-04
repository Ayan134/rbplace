--[[
	SoundConfig
	The single place where SoundIds live. Never put SoundIds in other scripts -
	play sounds through the client SoundManager by name.

	Music and jingles use Roblox's own audio library (ids taken from the official
	Creator documentation, usable in any experience). Short frequent effects use sounds
	that ship with the Roblox client (rbxasset://sounds/...). Replace any SoundId with
	another Creator Store sound ("rbxassetid://1234567890"). An empty SoundId is skipped.

	  Group          "SFX" | "Music" (SoundGroup volume is controlled from Settings)
	  Volume
	  PlaybackSpeed  base pitch
	  PitchVariance  random +/- added to the pitch every play (keeps repeated sounds fresh)
	  Looped
]]

local SoundConfig = {}

SoundConfig.Sounds = {
	-- UI
	Click = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.35, PlaybackSpeed = 1.2 },
	ButtonClick = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.4, PlaybackSpeed = 1.0 },
	Hover = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.12, PlaybackSpeed = 1.6 },
	Error = { SoundId = "rbxasset://sounds/button.wav", Group = "SFX", Volume = 0.45, PlaybackSpeed = 0.55 },
	Open = { SoundId = "rbxasset://sounds/swoosh.wav", Group = "SFX", Volume = 0.15, PlaybackSpeed = 1.8 },

	-- Peeling: soft paper sounds (high, short whooshes instead of metal slashes)
	PeelStart = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.22, PlaybackSpeed = 0.7, PitchVariance = 0.1 },
	Peel = { SoundId = "rbxasset://sounds/swoosh.wav", Group = "SFX", Volume = 0.07, PlaybackSpeed = 0.9, PitchVariance = 0.15 },
	StickerRip = { SoundId = "rbxasset://sounds/swoosh.wav", Group = "SFX", Volume = 0.3, PlaybackSpeed = 2.3, PitchVariance = 0.25 },
	Pop = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.3, PlaybackSpeed = 0.85, PitchVariance = 0.15 },

	-- Rewards (Roblox audio library ids from the official Creator docs)
	Reward = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.14, PlaybackSpeed = 1.8, PitchVariance = 0.05 },
	Combo = { SoundId = "rbxassetid://4110925712", Group = "SFX", Volume = 0.35, PlaybackSpeed = 1.0 },
	RareSticker = { SoundId = "rbxassetid://4110925712", Group = "SFX", Volume = 0.6, PlaybackSpeed = 0.9 },
	Lucky = { SoundId = "rbxassetid://4110925712", Group = "SFX", Volume = 0.4, PlaybackSpeed = 1.4 },
	LevelUp = { SoundId = "rbxassetid://3422389728", Group = "SFX", Volume = 0.5, PlaybackSpeed = 1.0 },
	LevelComplete = { SoundId = "rbxasset://sounds/victory.wav", Group = "SFX", Volume = 0.6, PlaybackSpeed = 1.0 },
	Upgrade = { SoundId = "rbxassetid://4110925712", Group = "SFX", Volume = 0.45, PlaybackSpeed = 1.2 },
	Purchase = { SoundId = "rbxassetid://4110925712", Group = "SFX", Volume = 0.5, PlaybackSpeed = 1.05 },
	Equip = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.35, PlaybackSpeed = 0.8 },
	Countdown = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.45, PlaybackSpeed = 0.7 },

	-- Music (Roblox-licensed tracks from the official Creator docs)
	LobbyAmbience = { SoundId = "rbxassetid://1841461968", Group = "Music", Volume = 0.22, Looped = true },
	LevelAmbience = { SoundId = "rbxassetid://1837849285", Group = "Music", Volume = 0.18, Looped = true },
	ResultsMusic = { SoundId = "rbxassetid://1846248593", Group = "Music", Volume = 0.3, Looped = true },
}

function SoundConfig.Get(name: string)
	return SoundConfig.Sounds[name]
end

return SoundConfig
