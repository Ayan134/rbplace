--[[
	Fountain - Level 1
	A small city fountain: basin ring, central pillar, two bowls and a top ornament.
]]

local BuildKit = require(script.Parent.BuildKit)

local STONE = Color3.fromRGB(214, 206, 192)
local STONE_DARK = Color3.fromRGB(170, 162, 150)
local WATER = Color3.fromRGB(70, 170, 235)

return function(): Model
	local kit = BuildKit.new("Fountain")

	-- Plaza tiles
	local size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 0.1, 0), 0.2, 46)
	kit:Part({ Name = "Plaza", Size = size, CFrame = cf, Color = Color3.fromRGB(196, 190, 184), Material = Enum.Material.Pavement })

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
	kit:Part({ Name = "BasinFloor", Size = size, CFrame = cf, Color = Color3.fromRGB(90, 130, 160), Material = Enum.Material.Slate })
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 2.3, 0), 0.3, radius * 2 - 1)
	kit:Part({ Name = "Water", Size = size, CFrame = cf, Color = WATER, Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false })

	-- Central pillar
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 4.5, 0), 8, 4.6)
	kit:Surface({ Name = "Pillar", Size = size, CFrame = cf, Color = STONE, Material = Enum.Material.Limestone }, "Pillar", { Faces = "Side" })

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
	kit:Surface({ Name = "LowerBowl", Size = size, CFrame = cf, Color = STONE, Material = Enum.Material.Limestone }, "Bowls")
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 9.55, 0), 0.2, 11.6)
	kit:Part({ Name = "LowerWater", Size = size, CFrame = cf, Color = WATER, Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false })

	-- Upper pillar and bowl
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 11.5, 0), 4, 2.6)
	kit:Surface({ Name = "UpperPillar", Size = size, CFrame = cf, Color = STONE, Material = Enum.Material.Limestone }, "Pillar", { Faces = "Side" })
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 13.9, 0), 1, 7.5)
	kit:Surface({ Name = "UpperBowl", Size = size, CFrame = cf, Color = STONE, Material = Enum.Material.Limestone }, "Bowls")

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

	-- Benches and lamps around the plaza
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.pi / 4
		local base = CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -20)
		kit:Part({ Name = "BenchSeat", Size = Vector3.new(6, 0.5, 2), CFrame = base * CFrame.new(0, 1.6, 0), Color = Color3.fromRGB(150, 96, 56), Material = Enum.Material.Wood })
		kit:Part({ Name = "BenchBack", Size = Vector3.new(6, 1.8, 0.4), CFrame = base * CFrame.new(0, 2.6, -0.9), Color = Color3.fromRGB(150, 96, 56), Material = Enum.Material.Wood })
		for _, x in ipairs({ -2.5, 2.5 }) do
			kit:Part({ Name = "BenchLeg", Size = Vector3.new(0.4, 1.4, 1.6), CFrame = base * CFrame.new(x, 0.7, 0), Color = Color3.fromRGB(60, 60, 66), Material = Enum.Material.Metal })
		end

		local lampAngle = i * math.pi / 2
		local lampBase = CFrame.Angles(0, lampAngle, 0) * CFrame.new(0, 0, -21)
		kit:Part({ Name = "LampPost", Size = Vector3.new(0.5, 9, 0.5), CFrame = lampBase * CFrame.new(0, 4.5, 0), Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.Metal })
		local bulb = kit:Part({ Name = "LampBulb", Size = Vector3.new(1.4, 1.4, 1.4), CFrame = lampBase * CFrame.new(0, 9.4, 0), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 236, 180), Material = Enum.Material.Neon, CanCollide = false })
		local light = Instance.new("PointLight")
		light.Range = 16
		light.Brightness = 1
		light.Color = Color3.fromRGB(255, 226, 170)
		light.Parent = bulb
	end

	kit:SetSpawn(Vector3.new(0, 3, 30), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 10, 0), Vector3.new(28, 20, 28))
	return kit:Finish()
end
