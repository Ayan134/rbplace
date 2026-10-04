--[[
	Pile - Level 1
	A huge rounded mound of stickers in a fenced backyard, with a few little spilled
	piles around it. Next to it: an orange house with a walk-in garage shop, trash cans
	to empty your bag, mushrooms and flowers; hills and rocky mountains beyond the fence.

	The mound is a single sphere sunk into the ground (overlapping spheres would hide
	stickers inside each other), the spilled piles are separate small spheres.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)
local ShopBuilder = require(script.Parent.Parent.Systems.ShopBuilder)

local PILE_COLOR = Color3.fromRGB(196, 186, 176)

return function(): Model
	local kit = BuildKit.new("Pile")

	-- The mound: diameter 72, sunk so it rises 19 studs and is ~63 studs wide at the ground
	kit:Surface({
		Name = "Mound",
		Size = Vector3.new(72, 72, 72),
		CFrame = CFrame.new(0, -17, 0),
		Shape = Enum.PartType.Ball,
		Color = PILE_COLOR,
		Material = Enum.Material.SmoothPlastic,
	}, "Pile")
	-- Spilled little piles, kept apart from the mound and each other
	for _, position in ipairs({ Vector3.new(44, -4, 18), Vector3.new(-42, -4, 24), Vector3.new(26, -4, -40) }) do
		kit:Surface({
			Name = "SmallPile",
			Size = Vector3.new(16, 16, 16),
			CFrame = CFrame.new(position),
			Shape = Enum.PartType.Ball,
			Color = PILE_COLOR,
			Material = Enum.Material.SmoothPlastic,
		}, "Pile")
	end

	------------------------------------------------------------------
	-- Environment: a fenced backyard
	------------------------------------------------------------------
	local env = kit.Environment
	local rng = Random.new(77)
	local halfX, halfZ = 100, 96
	local spawnPosition = Vector3.new(0, 0, 70)

	-- Dirt under and around the piles, paths to the spawn and the shop
	Decor.DirtCircle(env, Vector3.zero, 40)
	for _, position in ipairs({ Vector3.new(44, 0, 18), Vector3.new(-42, 0, 24), Vector3.new(26, 0, -40) }) do
		Decor.DirtCircle(env, position, 10)
	end
	Decor.DirtPath(env, CFrame.new(0, 0, 56), Vector2.new(12, 34))
	Decor.DirtCircle(env, spawnPosition, 10)
	local shopPosition = Vector3.new(-64, 0, -46)
	Decor.DirtPath(env, CFrame.lookAt((shopPosition + Vector3.new(-26, 0, -20)) / 2, Vector3.new(-26, 0, -20)), Vector2.new(12, 44))

	-- Walk-in garage shop facing the mound, orange house next to it
	local shopCF = CFrame.lookAt(shopPosition, Vector3.new(0, 0, 0))
	ShopBuilder.Build(env, shopCF)
	Decor.Building(env, shopCF * CFrame.new(-26, 0, 2), Vector3.new(22, 13, 20), Color3.fromRGB(236, 128, 64), {
		Roof = "Gable",
		RoofColor = Color3.fromRGB(46, 50, 62),
		TrimColor = Color3.fromRGB(250, 250, 248),
		WindowColor = Color3.fromRGB(170, 210, 240),
		DoorColor = Color3.fromRGB(50, 54, 66),
		Floors = 1,
	})
	kit.NoShopStall = true

	-- Yard details
	Decor.NoticeBoard(env, CFrame.lookAt(Vector3.new(16, 0, 74), Vector3.new(0, 0, 70)), "BAG IT ALL!", {
		"Hold E on the pile to peel",
		"Bag full? Walk to a trash can",
		"Bigger bags in the garage shop",
		"Clean the pile with your team!",
	})
	Decor.Mushroom(env, Vector3.new(-80, 0, 70), 14, nil, rng)
	Decor.Mushroom(env, Vector3.new(84, 0, 60), 12, nil, rng)
	Decor.Mushroom(env, Vector3.new(80, 0, -76), 13, nil, rng)
	Decor.Mushroom(env, Vector3.new(-30, 0, -84), 9, Color3.fromRGB(80, 150, 235), rng)
	for _ = 1, 10 do
		local position = Vector3.new(rng:NextNumber(-halfX + 8, halfX - 8), 0, rng:NextNumber(-halfZ + 8, halfZ - 8))
		if position.Magnitude > 52 and (position - shopPosition).Magnitude > 30 and (position - spawnPosition).Magnitude > 14 then
			Decor.MushroomCluster(env, position, rng:NextInteger(2, 4), rng, if rng:NextNumber() < 0.5 then Color3.fromRGB(80, 150, 235) else nil)
		end
	end
	for _ = 1, 12 do
		local position = Vector3.new(rng:NextNumber(-halfX + 6, halfX - 6), 0, rng:NextNumber(-halfZ + 6, halfZ - 6))
		if position.Magnitude > 50 and (position - shopPosition).Magnitude > 30 and (position - spawnPosition).Magnitude > 14 then
			Decor.FlowerBed(env, position, rng:NextNumber(2, 3.2), rng)
		end
	end
	for _, position in ipairs({ Vector3.new(70, 0, 30), Vector3.new(60, 0, -20), Vector3.new(-70, 0, 20), Vector3.new(40, 0, 70) }) do
		Decor.Tree(env, position, rng:NextNumber(1.1, 1.4), "Round", rng)
	end
	for i = 0, 19 do
		local t = (i + 0.5) / 20
		for _, position in ipairs({ Vector3.new(-halfX + 4 + t * (halfX * 2 - 8), 0, halfZ - 4), Vector3.new(halfX - 4, 0, -halfZ + 4 + t * (halfZ * 2 - 8)) }) do
			if rng:NextNumber() < 0.6 then
				Decor.Bush(env, position, rng:NextNumber(3, 5))
			end
		end
	end
	Decor.Balloons(env, Vector3.new(-6, 0.5, 64), 5, rng)
	Decor.Balloons(env, Vector3.new(6, 0.5, 64), 5, rng)

	-- Picket fence
	local corners = { Vector3.new(-halfX, 0, -halfZ), Vector3.new(halfX, 0, -halfZ), Vector3.new(halfX, 0, halfZ), Vector3.new(-halfX, 0, halfZ) }
	for i = 1, 4 do
		Decor.PicketFence(env, corners[i], corners[(i % 4) + 1])
	end

	-- Beyond the fence: trees, hills, rocky mountains, a hot air balloon
	for i = 0, 27 do
		local angle = (i / 28) * math.pi * 2
		local radius = rng:NextNumber(150, 185)
		Decor.Tree(env, Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), rng:NextNumber(1.3, 1.8), if rng:NextNumber() < 0.45 then "Pine" else "Round", rng)
	end
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		Decor.Hill(env, Vector3.new(math.cos(angle) * 215, 0, math.sin(angle) * 215), rng:NextNumber(28, 44))
	end
	for _, def in ipairs({ { Vector3.new(-70, 0, -240), 66 }, { Vector3.new(110, 0, -225), 72 }, { Vector3.new(240, 0, -40), 64 }, { Vector3.new(-240, 0, 60), 62 } }) do
		Decor.Mountain(env, def[1], def[2], rng)
	end
	Decor.HotAirBalloon(env, Vector3.new(120, 90, -160), Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 220, 110))
	Decor.AmbientMotes(env, Vector3.zero, 70, "Sunlight")

	kit:SetSpawn(spawnPosition + Vector3.new(0, 3, 0), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 8, 0), Vector3.new(66, 20, 66))
	return kit:Finish()
end
