--[[
	SoundConfig
	The single place where SoundIds live. Never put SoundIds in other scripts -
	play sounds through the client SoundManager by name.

	Defaults use sounds that ship with the Roblox client (rbxasset://sounds/...), so the
	game is audible out of the box. Replace any SoundId with your own uploaded audio
	(e.g. "rbxassetid://1234567890"). An empty SoundId is silently skipped.

	  Group          "SFX" | "Music" (SoundGroup volume is controlled from Settings)
	  Volume
	  PlaybackSpeed  base pitch
	  PitchVariance  random +/- added to the pitch every play (keeps repeated sounds fresh)
	  Looped
]]

local SoundConfig = {}

SoundConfig.Sounds = {
	-- UI
	Click = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.5, PlaybackSpeed = 1.1 },
	ButtonClick = { SoundId = "rbxasset://sounds/button.wav", Group = "SFX", Volume = 0.55, PlaybackSpeed = 1.0 },
	Hover = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.18, PlaybackSpeed = 1.6 },
	Error = { SoundId = "rbxasset://sounds/button.wav", Group = "SFX", Volume = 0.6, PlaybackSpeed = 0.55 },
	Open = { SoundId = "rbxasset://sounds/swoosh.wav", Group = "SFX", Volume = 0.25, PlaybackSpeed = 1.5 },

	-- Peeling
	PeelStart = { SoundId = "rbxasset://sounds/unsheath.wav", Group = "SFX", Volume = 0.22, PlaybackSpeed = 1.6, PitchVariance = 0.15 },
	Peel = { SoundId = "rbxasset://sounds/swoosh.wav", Group = "SFX", Volume = 0.16, PlaybackSpeed = 0.65, PitchVariance = 0.1 },
	StickerRip = { SoundId = "rbxasset://sounds/swordslash.wav", Group = "SFX", Volume = 0.35, PlaybackSpeed = 1.55, PitchVariance = 0.2 },
	Pop = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.35, PlaybackSpeed = 0.8, PitchVariance = 0.15 },

	-- Rewards
	Reward = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.22, PlaybackSpeed = 1.7, PitchVariance = 0.05 },
	Combo = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.3, PlaybackSpeed = 1.0 },
	RareSticker = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.6, PlaybackSpeed = 0.75 },
	Lucky = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.45, PlaybackSpeed = 2.0 },
	LevelUp = { SoundId = "rbxasset://sounds/victory.wav", Group = "SFX", Volume = 0.6, PlaybackSpeed = 1.15 },
	LevelComplete = { SoundId = "rbxasset://sounds/victory.wav", Group = "SFX", Volume = 0.8, PlaybackSpeed = 1.0 },
	Upgrade = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.5, PlaybackSpeed = 1.25 },
	Purchase = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Group = "SFX", Volume = 0.55, PlaybackSpeed = 0.95 },
	Equip = { SoundId = "rbxasset://sounds/unsheath.wav", Group = "SFX", Volume = 0.4, PlaybackSpeed = 1.0 },
	Countdown = { SoundId = "rbxasset://sounds/clickfast.wav", Group = "SFX", Volume = 0.6, PlaybackSpeed = 0.7 },

	-- Ambience (paste your own looping audio ids here)
	LobbyAmbience = { SoundId = "", Group = "Music", Volume = 0.4, Looped = true },
	LevelAmbience = { SoundId = "", Group = "Music", Volume = 0.35, Looped = true },
}

function SoundConfig.Get(name: string)
	return SoundConfig.Sounds[name]
end

return SoundConfig
