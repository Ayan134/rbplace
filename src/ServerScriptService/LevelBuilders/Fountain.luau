--[[
	Fountain - Level 1
	A small city fountain: basin ring, central pillar, two bowls and a top ornament.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)

local STONE = Color3.fromRGB(214, 206, 192)
local STONE_DARK = Color3.fromRGB(170, 162, 150)
local WATER = Color3.fromRGB(70, 170, 235)

return function(): Model
	local kit = BuildKit.new("Fountain")

	-- Plaza tiles
	local size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 0.1, 0), 0.2, 46)
	kit:Part({ Name = "Plaza", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(196, 190, 184), Material = Enum.Material.Pavement })

	-- Basin ring made of segments (outer and inner faces + rim)
	local segments = 14
	local radius = 13
	for i = 0, segments - 1 do
		local angle = (i / segments) * math.pi * 2
		local segmentLength = 2 * radius * math.tan(math.pi / segments) + 0.25
		kit:Surface({
			Name = "BasinWall",
			Size = Vector3.new(segmentLength, 3.2, 1.8),
			CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, 1.6, -radius),
			Color = STONE,
			Material = Enum.Material.Limestone,
		}, "Basin", { Faces = "Top,Front,Back" })
		-- Decorative rim cap
		kit:Part({
			Name = "Rim",
			Size = Vector3.new(segmentLength, 0.4, 2.2),
			CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, 3.4, -radius),
			Color = STONE_DARK,
			Material = Enum.Material.Limestone,
		})
	end

	-- Basin floor + water
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 0.6, 0), 1, radius * 2)
	kit:Part({ Name = "BasinFloor", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(90, 130, 160), Material = Enum.Material.Slate })
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 2.3, 0), 0.3, radius * 2 - 1)
	kit:Part({ Name = "Water", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WATER, Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false })

	-- Central pillar
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 4.5, 0), 8, 4.6)
	kit:Surface({ Name = "Pillar", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = STONE, Material = Enum.Material.Limestone }, "Pillar", { Faces = "Side" })

	-- Pillar base block
	kit:Surface({
		Name = "PillarBase",
		Size = Vector3.new(7, 2, 7),
		CFrame = CFrame.new(0, 1.5, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Limestone,
	}, "Pillar")

	-- Lower bowl
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 8.8, 0), 1.4, 13)
	kit:Surface({ Name = "LowerBowl", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = STONE, Material = Enum.Material.Limestone }, "Bowls")
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 9.55, 0), 0.2, 11.6)
	kit:Part({ Name = "LowerWater", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WATER, Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false })

	-- Upper pillar and bowl
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 11.5, 0), 4, 2.6)
	kit:Surface({ Name = "UpperPillar", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = STONE, Material = Enum.Material.Limestone }, "Pillar", { Faces = "Side" })
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 13.9, 0), 1, 7.5)
	kit:Surface({ Name = "UpperBowl", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = STONE, Material = Enum.Material.Limestone }, "Bowls")

	-- Top ornament
	kit:Surface({
		Name = "Ornament",
		Size = Vector3.new(3.4, 3.4, 3.4),
		CFrame = CFrame.new(0, 16.1, 0),
		Shape = Enum.PartType.Ball,
		Color = Color3.fromRGB(230, 200, 120),
		Material = Enum.Material.Marble,
	}, "Statue")
	local spire = kit:Part({
		Name = "Spire",
		Size = Vector3.new(0.6, 2.4, 0.6),
		CFrame = CFrame.new(0, 18.8, 0),
		Color = Color3.fromRGB(230, 200, 120),
		Material = Enum.Material.Marble,
	})

	-- Water spray
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 1.2, 0)
	attachment.Parent = spire
	local spray = Instance.new("ParticleEmitter")
	spray.Name = "WaterSpray"
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(180, 230, 255))
	spray.LightEmission = 0.4
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.1) })
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	spray.Lifetime = NumberRange.new(1.2, 1.6)
	spray.Rate = 40
	spray.Speed = NumberRange.new(10, 14)
	spray.SpreadAngle = Vector2.new(25, 25)
	spray.Acceleration = Vector3.new(0, -24, 0)
	spray.Parent = attachment

	------------------------------------------------------------------
	-- Environment: a cozy town square
	------------------------------------------------------------------
	local env = kit.Environment
	local S = kit.Scale
	local rng = Random.new(101)
	local plazaRadius = 23 * S

	-- Cobblestone square and a ring road with sidewalks
	local ringSize, ringCF = BuildKit.VerticalCylinder(Vector3.new(0, 0.06, 0), 0.12, plazaRadius * 2 + 26)
	kit:Decor({ Name = "Cobblestones", Size = ringSize, CFrame = ringCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(184, 172, 160), Material = Enum.Material.Cobblestone })
	local roadOffset = plazaRadius + 30
	for _, def in ipairs({
		{ CFrame.new(roadOffset, 0, 0), 240 },
		{ CFrame.new(-roadOffset, 0, 0), 240 },
		{ CFrame.new(0, 0, roadOffset) * CFrame.Angles(0, math.pi / 2, 0), 240 },
		{ CFrame.new(0, 0, -roadOffset) * CFrame.Angles(0, math.pi / 2, 0), 240 },
	}) do
		Decor.Road(env, def[1], def[2], 16)
	end
	for _, def in ipairs({ { 0, roadOffset }, { 0, -roadOffset }, { roadOffset, 0 }, { -roadOffset, 0 } }) do
		local rotation = if def[1] == 0 then CFrame.new() else CFrame.Angles(0, math.pi / 2, 0)
		Decor.Crosswalk(env, CFrame.new(def[1], 0, def[2]) * rotation, 16)
	end

	-- Pastel townhouses facing the square
	local pastel = {
		Color3.fromRGB(250, 214, 190), Color3.fromRGB(196, 222, 240), Color3.fromRGB(244, 236, 196),
		Color3.fromRGB(214, 236, 206), Color3.fromRGB(240, 206, 220), Color3.fromRGB(226, 214, 246),
	}
	local awnings = { Color3.fromRGB(220, 80, 80), Color3.fromRGB(60, 140, 200), Color3.fromRGB(70, 160, 110), Color3.fromRGB(240, 170, 60) }
	local buildingRing = roadOffset + 26
	for side = 0, 3 do
		local sideRotation = CFrame.Angles(0, side * math.pi / 2, 0)
		for slot = -1, 1 do
			local width = rng:NextNumber(22, 30)
			local height = rng:NextInteger(3, 4) * 7
			local position = (sideRotation * CFrame.new(slot * 36, 0, -buildingRing)).Position
			local cf = CFrame.lookAt(position, Vector3.new(0, 0, 0))
			Decor.Building(env, cf, Vector3.new(width, height, 18), pastel[rng:NextInteger(1, #pastel)], {
				Roof = if rng:NextNumber() < 0.5 then "Gable" else "Flat",
				Awning = awnings[rng:NextInteger(1, #awnings)],
				DoorColor = awnings[rng:NextInteger(1, #awnings)],
			})
		end
		-- Blossom trees on the corners
		local corner = (sideRotation * CFrame.new(roadOffset + 14, 0, -(roadOffset + 14))).Position
		Decor.Tree(env, corner, 1.2, "Blossom", rng)
	end

	-- Lamps around the square with string lights between them
	local lampTops = {}
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2 + math.pi / 8
		local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (plazaRadius + 4)
		table.insert(lampTops, Decor.Lamp(env, position, 11))
	end
	for i = 1, #lampTops do
		Decor.StringLights(env, lampTops[i], lampTops[(i % #lampTops) + 1], 9, 2.5)
	end

	-- Benches, planters and a little cafe
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.pi / 4
		local base = CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.1, -(plazaRadius - 3))
		Decor.Bench(env, base)
		Decor.Planter(env, base * CFrame.new(6, 0, 0), Vector3.new(3, 1.6, 3), rng)
		Decor.Planter(env, base * CFrame.new(-6, 0, 0), Vector3.new(3, 1.6, 3), rng)
	end
	local cafeColors = { Color3.fromRGB(230, 90, 90), Color3.fromRGB(80, 150, 220), Color3.fromRGB(250, 190, 70) }
	for i = 1, 3 do
		Decor.CafeTable(env, Vector3.new(-roadOffset + 12, 0.1, -16 + i * 9), cafeColors[i])
	end
	for i = 0, 5 do
		Decor.Tree(env, Vector3.new(roadOffset - 10, 0, -40 + i * 16), 0.9, "Round", rng)
	end

	Decor.Backdrop(env, Vector3.zero, 230, rng)
	Decor.AmbientMotes(env, Vector3.zero, 70, "Sunlight")

	kit:SetSpawn(Vector3.new(0, 3, 30), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 10, 0), Vector3.new(28, 20, 28))
	return kit:Finish()
end
