--[[
	SoundConfig
	The single place where SoundIds live. Never put SoundIds in other scripts -
	play sounds through the client SoundManager by name.

	Every sound has a fallback chain in `SoundIds`: the SoundManager preloads the first id
	and, if Roblox can't load it (deleted, private or moderated audio), moves on to the next.
	The last entry is always a sound that ships with the Roblox client (rbxasset://sounds/...),
	so nothing ever goes silent. Replace or reorder ids freely ("rbxassetid://1234567890").

	Sources: Roblox Creator Store / Roblox audio library (the 91xxxxxxxx ids are the
	Roblox-licensed Pro Sound Effects library; the lo-fi music is Roblox-licensed APM Music
	by @APMOfficial) and popular public effects listed on robloxsong.com.

	  Group          "SFX" | "Music" | "Ambience" (Ambience follows the SFX volume slider)
	  Volume
	  PlaybackSpeed  base pitch
	  PitchVariance  random +/- added to the pitch every play (keeps repeated sounds fresh)
	  Looped
]]

local SoundConfig = {}

local CLICK = "rbxasset://sounds/clickfast.wav"
local SWOOSH = "rbxasset://sounds/swoosh.wav"
local PING = "rbxasset://sounds/electronicpingshort.wav"
local VICTORY = "rbxasset://sounds/victory.wav"

SoundConfig.Sounds = {
	-- UI: soft tonal blips instead of mechanical clicks
	Click = { SoundIds = { "rbxassetid://9126109935", CLICK }, Group = "SFX", Volume = 0.3, PlaybackSpeed = 1.15, PitchVariance = 0.04 },
	ButtonClick = { SoundIds = { "rbxassetid://9126109935", CLICK }, Group = "SFX", Volume = 0.32, PlaybackSpeed = 1.0, PitchVariance = 0.04 },
	Hover = { SoundIds = { "rbxassetid://9125397532", CLICK }, Group = "SFX", Volume = 0.06, PlaybackSpeed = 1.5 },
	Open = { SoundIds = { "rbxassetid://9126139357", SWOOSH }, Group = "SFX", Volume = 0.16, PlaybackSpeed = 1.3 },
	Notify = { SoundIds = { "rbxassetid://9125397532", PING }, Group = "SFX", Volume = 0.22, PlaybackSpeed = 1.0 },
	Error = { SoundIds = { "rbxassetid://9117981543", "rbxasset://sounds/button.wav" }, Group = "SFX", Volume = 0.35, PlaybackSpeed = 0.8 },

	-- Peeling: cloth/paper lift, a crisp paper tear and a bubbly pop when the sticker comes off
	PeelStart = { SoundIds = { "rbxassetid://9113824106", CLICK }, Group = "SFX", Volume = 0.28, PlaybackSpeed = 1.25, PitchVariance = 0.12 },
	Peel = { SoundIds = { "rbxassetid://3657879622", "rbxassetid://5751743646", SWOOSH }, Group = "SFX", Volume = 0.08, PlaybackSpeed = 1.1, PitchVariance = 0.15 },
	StickerRip = { SoundIds = { "rbxassetid://3657879622", "rbxassetid://5751743646", "rbxassetid://2991461059", SWOOSH }, Group = "SFX", Volume = 0.34, PlaybackSpeed = 1.15, PitchVariance = 0.2 },
	Pop = { SoundIds = { "rbxassetid://2375539277", "rbxassetid://4607031412", CLICK }, Group = "SFX", Volume = 0.26, PlaybackSpeed = 1.05, PitchVariance = 0.18 },

	-- Rewards: coin sparkle per sticker, bells for combos and rare finds
	Reward = { SoundIds = { "rbxassetid://1169755927", "rbxassetid://138125823", PING }, Group = "SFX", Volume = 0.08, PlaybackSpeed = 1.15, PitchVariance = 0.04 },
	Combo = { SoundIds = { "rbxassetid://9126073011", "rbxassetid://5654075071", "rbxassetid://4110925712" }, Group = "SFX", Volume = 0.22, PlaybackSpeed = 1.0 },
	RareSticker = { SoundIds = { "rbxassetid://9116420445", "rbxassetid://9126073011", "rbxassetid://4110925712" }, Group = "SFX", Volume = 0.55, PlaybackSpeed = 1.0 },
	Lucky = { SoundIds = { "rbxassetid://5654075071", "rbxassetid://9126073011", "rbxassetid://4110925712" }, Group = "SFX", Volume = 0.35, PlaybackSpeed = 1.2 },
	LevelUp = { SoundIds = { "rbxassetid://2686079706", "rbxassetid://6914808015", "rbxassetid://5153733046", "rbxassetid://3422389728" }, Group = "SFX", Volume = 0.5, PlaybackSpeed = 1.0 },
	LevelComplete = { SoundIds = { "rbxassetid://1507116849", VICTORY }, Group = "SFX", Volume = 0.55, PlaybackSpeed = 1.0 },
	Fireworks = { SoundIds = { "rbxassetid://9114363548", "rbxasset://sounds/collide.wav" }, Group = "SFX", Volume = 0.22, PlaybackSpeed = 1.0, PitchVariance = 0.15 },
	Upgrade = { SoundIds = { "rbxassetid://9119219346", "rbxassetid://9126073011", "rbxassetid://4110925712" }, Group = "SFX", Volume = 0.4, PlaybackSpeed = 1.0 },
	-- Classic cash register "ka-ching" when the bag is emptied into a trash can
	Sell = { SoundIds = { "rbxassetid://6658761720", "rbxassetid://7112275565", "rbxassetid://1882275320", "rbxassetid://9126073011", PING }, Group = "SFX", Volume = 0.45, PlaybackSpeed = 1.0 },
	BagFull = { SoundIds = { "rbxassetid://9125397532", "rbxasset://sounds/button.wav" }, Group = "SFX", Volume = 0.25, PlaybackSpeed = 0.8 },
	Purchase = { SoundIds = { "rbxassetid://5437842453", "rbxassetid://1169755927", "rbxassetid://4110925712" }, Group = "SFX", Volume = 0.45, PlaybackSpeed = 1.0 },
	Equip = { SoundIds = { "rbxassetid://9113824106", CLICK }, Group = "SFX", Volume = 0.35, PlaybackSpeed = 1.4 },
	Countdown = { SoundIds = { "rbxassetid://9113081793", SWOOSH }, Group = "SFX", Volume = 0.3, PlaybackSpeed = 1.0 },

	-- Music: chill lo-fi from the Roblox-licensed APM library (usable in any experience).
	-- `Playlist` entries play one after another (unloadable tracks are skipped).
	LobbyMusic = {
		Playlist = {
			"rbxassetid://9043887091", -- Lo-fi Chill A
			"rbxassetid://9046863253", -- Poolside
			"rbxassetid://9046863579", -- City Lights
			"rbxassetid://9042666762", -- Chillin at Home
		},
		Group = "Music",
		Volume = 0.3,
	},
	LevelMusic = {
		Playlist = {
			"rbxassetid://9046863253", -- Poolside
			"rbxassetid://9048511491", -- Wavy Shores
			"rbxassetid://9043887120", -- Lo-fi Chill B
			"rbxassetid://9042666762", -- Chillin at Home
			"rbxassetid://9047050075", -- Lo Fi Dreams Hip Hop
			"rbxassetid://9043887091", -- Lo-fi Chill A
		},
		Group = "Music",
		Volume = 0.24,
	},
	RoyalMusic = {
		Playlist = {
			"rbxassetid://9048511491", -- Wavy Shores
			"rbxassetid://9043887320", -- Lo-fi Chill C
			"rbxassetid://1845341094", -- Chill Jazz
			"rbxassetid://9046863579", -- City Lights
		},
		Group = "Music",
		Volume = 0.24,
	},
	ResultsMusic = { SoundIds = { "rbxassetid://9046863579", "rbxassetid://9043887120" }, Group = "Music", Volume = 0.32, Looped = true },

	-- Environment ambience loops (Pro Sound Effects library)
	AmbienceCity = { SoundIds = { "rbxassetid://9112758786" }, Group = "Ambience", Volume = 0.12, Looped = true },
	AmbienceNature = { SoundIds = { "rbxassetid://9116258071" }, Group = "Ambience", Volume = 0.16, Looped = true },
	AmbienceWind = { SoundIds = { "rbxassetid://9125515917", "rbxassetid://9125742111" }, Group = "Ambience", Volume = 0.1, Looped = true },
}

-- Music and ambience per place. Missing levels fall back to `Default`.
SoundConfig.Themes = {
	Lobby = { Music = "LobbyMusic", Ambience = "AmbienceNature" },
	Default = { Music = "LevelMusic", Ambience = "AmbienceNature" },
	Pile = { Music = "LevelMusic", Ambience = "AmbienceNature" },
	Fountain = { Music = "LevelMusic", Ambience = "AmbienceCity" },
	Car = { Music = "LevelMusic", Ambience = "AmbienceCity" },
	Statue = { Music = "LevelMusic", Ambience = "AmbienceNature" },
	House = { Music = "LevelMusic", Ambience = "AmbienceCity" },
	Mansion = { Music = "RoyalMusic", Ambience = "AmbienceNature" },
	Airplane = { Music = "LevelMusic", Ambience = "AmbienceWind" },
	Palace = { Music = "RoyalMusic", Ambience = "AmbienceNature" },
}

function SoundConfig.Get(name: string)
	return SoundConfig.Sounds[name]
end

function SoundConfig.GetTheme(placeId: string?)
	return SoundConfig.Themes[placeId or "Default"] or SoundConfig.Themes.Default
end

return SoundConfig
