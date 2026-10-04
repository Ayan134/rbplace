--[[
	AssetConfig
	Ready-made Creator Store models that replace the procedural scenery at runtime
	(see AssetLoader). Every decoration built by Systems/Decor carries an AssetKind
	attribute; when one of the sources below loads, the decoration is swapped for the
	model, scaled to the same size. If nothing loads, the procedural version stays.

	Sources are tried in order:
	  { Pack = id, Match = { words }, Exclude = { words } }
	      an asset pack; children whose names contain a Match word (and no Exclude word)
	      become variants, picked per spot for variety
	  { Id = id }
	      a single model

	Fit:
	  "Height"     scaled so its height matches the placeholder (trees, mushrooms)
	  "Footprint"  scaled to fit the placeholder's ground footprint (rocks, benches, cars)

	Models published by Roblox (the Synty packs) always load. Other creators' free models
	load only when "Allow Loading Third Party Assets" is on in Studio:
	Game Settings > Security. Swap any id for a model you like.
]]

local SYNTY_NATURE = 6933438443 -- "Synty Nature Pack" by Roblox

return {
	Kinds = {
		["Tree.Round"] = {
			Fit = "Height",
			Sources = {
				{ Pack = SYNTY_NATURE, Match = { "tree" }, Exclude = { "pine", "fir", "dead", "stump", "log", "palm", "branch", "fallen", "trunk" } },
				{ Id = 2354329676 }, -- "trees" by lulufev
				{ Id = 3515211535 }, -- "Tree" by envsoux
			},
		},
		["Tree.Pine"] = {
			Fit = "Height",
			Sources = {
				{ Pack = SYNTY_NATURE, Match = { "pine", "fir" }, Exclude = { "dead", "stump", "log", "branch", "fallen" } },
				{ Id = 4830544188 }, -- "Low Poly Pine Tree FREE!!" by cocajola3
				{ Id = 2680518960 }, -- "Classic ROBLOX Tree/Pine" by Pumpkuin
			},
		},
		Rock = {
			Fit = "Footprint",
			Sources = {
				{ Pack = SYNTY_NATURE, Match = { "rock", "boulder" }, Exclude = { "cliff", "path", "pile" } },
				{ Id = 11935161111 }, -- "Low Poly Rocks" by ImAvafe
				{ Id = 2557020130 }, -- "Low Poly Rock" by FWS_Sinister
			},
		},
		Bush = {
			Fit = "Footprint",
			Sources = {
				{ Pack = SYNTY_NATURE, Match = { "bush", "shrub" }, Exclude = { "dead" } },
				{ Id = 74179576 }, -- "Bush" by CommanderJigglypuff
			},
		},
		Mushroom = {
			Fit = "Height",
			Sources = {
				{ Id = 4776442185 }, -- "Mushroom" by Mr10Cm
				{ Id = 1590134067 }, -- "Fungi" by TroxiousDev
			},
		},
		SmallMushroom = {
			Fit = "Height",
			Sources = {
				{ Pack = SYNTY_NATURE, Match = { "mushroom", "shroom", "fungi" }, Exclude = {} },
				{ Id = 5871477548 }, -- "[COTTAGE CORE] mushrooms" by silveki
			},
		},
		Bench = {
			Fit = "Footprint",
			Sources = {
				{ Id = 1127298073 }, -- "Modern Park Bench" by JDLENL
				{ Id = 13536685653 }, -- "a classic bench" by driftiguess
			},
		},
		Crate = {
			Fit = "Footprint",
			Sources = {
				{ Id = 182451376 }, -- "Static Wood Crate" by Quenty
			},
		},
		Car = {
			Fit = "Footprint",
			Sources = {
				{ Id = 15550351384 }, -- "Low Poly Car" by Rayhan100985
			},
		},
	},

	-- Seconds to wait for the Store before giving up (procedural scenery stays)
	LoadTimeout = 25,
	-- Variants taken from one pack match
	MaxVariants = 6,
}
