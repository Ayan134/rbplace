--[[
	Config
	Global game constants shared by server and client.
	Gameplay content (levels, tools, upgrades, stickers) lives in its own config modules.
]]

local Config = {
	GameName = "Sticker Peel Simulator",

	Data = {
		DataStoreName = "StickerPeel_PlayerData_v1",
		AutosaveInterval = 120, -- seconds
		MaxRetries = 5,
		SessionLockTimeout = 600, -- seconds before a stale session lock may be stolen
		SchemaVersion = 1,
	},

	Party = {
		-- Raising MaxPartySize is the only change needed to allow bigger rooms:
		-- UI size buttons, validation and team lists are all generated from this value.
		MaxPartySize = 4,
		MinPartySize = 1,
		ReadyRequired = true, -- every non-host member must be Ready before Start
		MaxRooms = 64,
	},

	Peel = {
		BasePeelRate = 2.0, -- sticker HP removed per second with no upgrades / Hand tool
		MinDuration = 0.3, -- seconds, floor for any single sticker
		MinDurationFactor = 0.8, -- server accepts completion after >= 80% of required time (latency)
		MinDurationLeeway = 0.12, -- extra absolute leeway in seconds
		MaxDistance = 19, -- server distance check (studs, HumanoidRootPart -> sticker)
		ClientReach = 16, -- client targeting distance
		ChainRadius = 8, -- multi-peel picks extra targets within this radius of the main target
		ChainStagger = 0.12, -- seconds between starting chained stickers
		MaxCapacity = 10, -- hard cap on simultaneous stickers per player
		MaxRequestsPerSecond = 40,
		StalePeelTimeout = 12, -- seconds after expected finish before a peel auto-cancels
		MaxStoredProgress = 0.97,
	},

	Combo = {
		Window = 2.75, -- seconds between peels to keep the combo alive
		-- Highest matching tier wins
		Tiers = {
			{ Count = 100, Multiplier = 2.5 },
			{ Count = 50, Multiplier = 2.0 },
			{ Count = 25, Multiplier = 1.5 },
			{ Count = 10, Multiplier = 1.25 },
			{ Count = 5, Multiplier = 1.1 },
		},
	},

	Arena = {
		Origin = Vector3.new(0, 0, 3000),
		Spacing = 1000,
		Columns = 8,
		MaxSlots = 48,
		GroundSize = 520,
	},

	Match = {
		LoadingMinTime = 2.5,
		ResultsDuration = 30, -- seconds before players are returned to the lobby automatically
		CoopBonusPerPlayer = 0.15, -- +15% completion reward for every extra player
		SpeedBonusMax = 0.5, -- up to +50% completion reward for beating par time
		ParSecondsPerSticker = 1.15,
		AfkContributionThreshold = 0.02, -- players below 2% contribution get half completion reward
		FinderThreshold = 0.015, -- markers appear on the last 1.5% of stickers (min 5)
		FinderMinimum = 5,
		ChunkSize = 900, -- stickers per StickerData network chunk
		HardToReachHeight = 17, -- surfaces above this height (out of reach from the ground) are hard to reach
		HardToReachRewardBonus = 1.25,
		ArenaJumpHeight = 10,
	},

	Lobby = {
		ShowcaseStickerCount = 260,
		ShowcaseRegenerateAt = 0.7, -- regenerate when 70% peeled
		GhostPeelInterval = 1.4, -- demo "ghost" peels a sticker every N seconds
		ShowcaseLevel = "Fountain",
	},

	Rewards = {
		FirstCompletionGems = 5,
		FirstCompletionXPBonus = 0.5, -- +50% XP the first time a level/difficulty is completed
		LevelUpGems = 10,
		DiamondGems = 1,
		LegendaryGems = 3,
		RecordXPBonus = 50,
		LuckyChanceScale = 0.25, -- chance of a LUCKY x2 reward = Luck * scale
	},

	Sticker = {
		Thickness = 0.06,
		SurfaceOffset = 0.035,
		LayerStep = 0.0045,
		CoverageFactor = 1.22, -- >1 means stickers overlap so the object looks fully covered
		MinSize = 0.45,
		MaxSize = 9,
		CircleChance = 0.35,
		MaxPerLevel = 6000,
	},

	XP = {
		Base = 100,
		Exponent = 1.42,
		MaxLevel = 100,
	},
}

return Config
