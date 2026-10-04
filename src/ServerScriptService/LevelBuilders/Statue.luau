--[[
	Statue - Level 3
	A giant hero statue holding a torch, on a stepped pedestal. Scaffolding gives access
	to the high (hard to reach) parts.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)

local BRONZE = Color3.fromRGB(110, 170, 150)
local BRONZE_DARK = Color3.fromRGB(80, 140, 122)
local MARBLE = Color3.fromRGB(226, 222, 214)

return function(): Model
	local kit = BuildKit.new("Statue")

	-- Stepped pedestal
	kit:Surface({ Name = "Step1", Size = Vector3.new(30, 1.2, 30), CFrame = CFrame.new(0, 0.6, 0), Color = MARBLE, Material = Enum.Material.Marble }, "Pedestal", { Faces = "Top,Front,Back,Left,Right", StickerWeight = 0.5 })
	kit:Surface({ Name = "Step2", Size = Vector3.new(25, 1.2, 25), CFrame = CFrame.new(0, 1.8, 0), Color = MARBLE, Material = Enum.Material.Marble }, "Pedestal", { StickerWeight = 0.6 })
	kit:Surface({ Name = "Pedestal", Size = Vector3.new(19, 7, 19), CFrame = CFrame.new(0, 5.9, 0), Color = MARBLE, Material = Enum.Material.Marble }, "Pedestal")
	kit:Surface({ Name = "PedestalCap", Size = Vector3.new(21, 1, 21), CFrame = CFrame.new(0, 9.9, 0), Color = Color3.fromRGB(200, 196, 188), Material = Enum.Material.Marble }, "Pedestal")
	-- Plaque
	local plaque = kit:Part({ Name = "Plaque", Size = Vector3.new(8, 2.5, 0.3), CFrame = CFrame.new(0, 6, -9.6), Color = Color3.fromRGB(210, 170, 60), Material = Enum.Material.Metal })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.Parent = plaque
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "THE STICKER HERO"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(70, 50, 20)
	label.Parent = gui

	-- Feet & legs
	for _, x in ipairs({ -2.6, 2.6 }) do
		kit:Surface({ Name = "Foot", Size = Vector3.new(4, 1.6, 6), CFrame = CFrame.new(x, 11.2, -0.8), Color = BRONZE_DARK, Material = Enum.Material.Metal }, "Legs")
		kit:Surface({ Name = "Leg", Size = Vector3.new(3.8, 12, 3.8), CFrame = CFrame.new(x, 18, 0), Color = BRONZE, Material = Enum.Material.Metal }, "Legs", { Faces = "Front,Back,Left,Right" })
	end

	-- Torso, belt, chest emblem
	kit:Surface({ Name = "Torso", Size = Vector3.new(9.4, 11, 5.2), CFrame = CFrame.new(0, 29.5, 0), Color = BRONZE, Material = Enum.Material.Metal }, "Body")
	kit:Surface({ Name = "Belt", Size = Vector3.new(9.8, 1.4, 5.6), CFrame = CFrame.new(0, 24.6, 0), Color = BRONZE_DARK, Material = Enum.Material.Metal }, "Body", { Faces = "Front,Back,Left,Right" })
	kit:Surface({ Name = "Emblem", Size = Vector3.new(3.2, 3.2, 0.6), CFrame = CFrame.new(0, 31, -2.8) * CFrame.Angles(0, 0, math.rad(45)), Color = Color3.fromRGB(230, 190, 70), Material = Enum.Material.Metal }, "Body", { Faces = "Front" })

	-- Cape
	kit:Surface({ Name = "Cape", Size = Vector3.new(9, 15, 0.8), CFrame = CFrame.new(0, 26, 3.2) * CFrame.Angles(math.rad(-6), 0, 0), Color = Color3.fromRGB(150, 60, 70), Material = Enum.Material.Fabric }, "Body", { Faces = "Back,Left,Right" })

	-- Arms: left arm down, right arm raised with torch
	kit:Surface({ Name = "Shoulder", Size = Vector3.new(3.6, 3.6, 3.6), CFrame = CFrame.new(-6.2, 33, 0), Shape = Enum.PartType.Ball, Color = BRONZE, Material = Enum.Material.Metal }, "Arms")
	kit:Surface({ Name = "LeftArm", Size = Vector3.new(3.2, 10, 3.2), CFrame = CFrame.new(-6.6, 28.5, 0) * CFrame.Angles(0, 0, math.rad(-8)), Color = BRONZE, Material = Enum.Material.Metal }, "Arms", { Faces = "Front,Back,Left,Right" })
	kit:Surface({ Name = "Shoulder", Size = Vector3.new(3.6, 3.6, 3.6), CFrame = CFrame.new(6.2, 33, 0), Shape = Enum.PartType.Ball, Color = BRONZE, Material = Enum.Material.Metal }, "Arms")
	kit:Surface({ Name = "RightArm", Size = Vector3.new(3.2, 10, 3.2), CFrame = CFrame.new(7.4, 38, 0) * CFrame.Angles(0, 0, math.rad(-12)), Color = BRONZE, Material = Enum.Material.Metal }, "Arms", { Faces = "Front,Back,Left,Right" })

	-- Neck & head
	local size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 35.8, 0), 1.6, 3)
	kit:Part({ Name = "Neck", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = BRONZE_DARK, Material = Enum.Material.Metal })
	kit:Surface({ Name = "Head", Size = Vector3.new(6.4, 6.4, 6.4), CFrame = CFrame.new(0, 39.4, 0), Shape = Enum.PartType.Ball, Color = BRONZE, Material = Enum.Material.Metal }, "Head")
	-- Crown spikes
	for i = 0, 6 do
		local angle = (i / 7) * math.pi * 2
		kit:Surface({
			Name = "CrownSpike",
			Class = "WedgePart",
			Size = Vector3.new(1.2, 2.4, 1.2),
			CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, 42.6, -2.4),
			Color = Color3.fromRGB(230, 190, 70),
			Material = Enum.Material.Metal,
		}, "Head", { Faces = "Slope,Back" })
	end

	-- Torch
	size, cf = BuildKit.VerticalCylinder(Vector3.new(8.6, 44.6, 0), 4, 1.4)
	kit:Surface({ Name = "TorchHandle", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = BRONZE_DARK, Material = Enum.Material.Metal }, "Torch", { Faces = "Side" })
	size, cf = BuildKit.VerticalCylinder(Vector3.new(8.6, 47.2, 0), 1.6, 4)
	kit:Surface({ Name = "TorchCup", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(230, 190, 70), Material = Enum.Material.Metal }, "Torch", { Faces = "Side" })
	local flame = kit:Part({ Name = "Flame", Size = Vector3.new(2.4, 3, 2.4), CFrame = CFrame.new(8.6, 49.4, 0), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 150, 40), Material = Enum.Material.Neon, CanCollide = false })
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 9
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 220, 90)
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Range = 24
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Parent = flame

	-- Scaffolding for hard-to-reach spots
	kit:Truss(Vector3.new(-11.5, 2.4, -11.5), 8.4)
	kit:Truss(Vector3.new(11.5, 2.4, 11.5), 8.4)
	-- Front-left tower to torso height
	kit:Truss(Vector3.new(-10.2, 10.4, -8.2), 14)
	kit:Platform(CFrame.new(-10.2, 24.6, -2), Vector3.new(4, 0.6, 10))
	-- Rear-right tower to head height
	kit:Truss(Vector3.new(9, 10.4, 9.5), 22)
	kit:Platform(CFrame.new(5, 32.6, 6.5), Vector3.new(12, 0.6, 4))
	kit:Truss(Vector3.new(11, 32.9, 4.6), 9.1)
	kit:Platform(CFrame.new(10.5, 42.2, 0), Vector3.new(5, 0.6, 7))

	------------------------------------------------------------------
	-- Environment: a city park
	------------------------------------------------------------------
	local env = kit.Environment
	local rng = Random.new(303)
	local plaza = 38

	local size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 0.06, 0), 0.12, plaza * 2)
	kit:Decor({ Name = "ParkPlaza", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(222, 214, 200), Material = Enum.Material.Pavement })
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 0.04, 0), 0.08, plaza * 2 + 4)
	kit:Decor({ Name = "PlazaBorder", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(170, 160, 150), Material = Enum.Material.Cobblestone })

	-- Paths out in four directions, lined with lamps
	for side = 0, 3 do
		local rotation = CFrame.Angles(0, side * math.pi / 2, 0)
		kit:Decor({ Name = "Path", Size = Vector3.new(9, 0.1, 150), CFrame = rotation * CFrame.new(0, 0.05, -(plaza + 75)), Color = Color3.fromRGB(226, 200, 156), Material = Enum.Material.Sand })
		for step = 1, 4 do
			for _, x in ipairs({ -6.5, 6.5 }) do
				Decor.Lamp(env, (rotation * CFrame.new(x, 0, -(plaza + step * 28))).Position, 9)
			end
		end
		-- Flower beds and blossom trees between the paths
		local diagonal = CFrame.Angles(0, side * math.pi / 2 + math.pi / 4, 0)
		Decor.FlowerBed(env, (diagonal * CFrame.new(0, 0, -(plaza + 14))).Position, 7, rng)
		Decor.Tree(env, (diagonal * CFrame.new(-16, 0, -(plaza + 30))).Position, 1.1, "Blossom", rng)
		Decor.Tree(env, (diagonal * CFrame.new(16, 0, -(plaza + 30))).Position, 1.1, "Round", rng)
		Decor.Bench(env, diagonal * CFrame.new(0, 0.1, -(plaza - 3)))
	end

	-- Hedge ring with gaps for the paths
	for i = 0, 15 do
		local angle = (i + 0.5) / 16 * math.pi * 2
		local isGap = math.abs(math.sin(angle * 2)) < 0.3
		if not isGap then
			local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (plaza + 3)
			Decor.Hedge(env, CFrame.lookAt(position, Vector3.zero), Vector3.new(14, 3, 2.4))
		end
	end

	-- Pond with rocks, lily pads and benches
	local pond = Vector3.new(95, 0, 70)
	Decor.Water(env, CFrame.new(pond + Vector3.new(0, -2, 0)), Vector3.new(48, 4, 32))
	for i = 0, 13 do
		local angle = i / 14 * math.pi * 2
		Decor.Rock(env, pond + Vector3.new(math.cos(angle) * 26, 0, math.sin(angle) * 18), rng:NextNumber(2, 4), rng)
	end
	for i = 1, 6 do
		local lily, lilyCF = BuildKit.VerticalCylinder(pond + Vector3.new(rng:NextNumber(-16, 16), 0.05, rng:NextNumber(-9, 9)), 0.1, rng:NextNumber(2, 3.4))
		kit:Decor({ Name = "LilyPad", Size = lily, CFrame = lilyCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(90, 170, 80), Material = Enum.Material.Grass, CanCollide = false })
	end
	Decor.Bench(env, CFrame.lookAt(pond + Vector3.new(-30, 0.1, -16), pond))
	Decor.Bench(env, CFrame.lookAt(pond + Vector3.new(-8, 0.1, -24), pond))
	Decor.Tree(env, pond + Vector3.new(30, 0, -12), 1.4, "Blossom", rng)
	Decor.Tree(env, pond + Vector3.new(26, 0, 20), 1.2, "Round", rng)

	-- Woods around the park
	for i = 0, 27 do
		local angle = i / 28 * math.pi * 2
		local r = rng:NextNumber(120, 170)
		local position = Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		local onPath = math.abs(position.X) < 12 or math.abs(position.Z) < 12
		if (position - pond).Magnitude > 40 and not onPath then
			Decor.Tree(env, position, rng:NextNumber(1.1, 1.6), if rng:NextNumber() < 0.45 then "Pine" else "Round", rng)
		end
	end
	for i = 0, 11 do
		local angle = i / 12 * math.pi * 2 + 0.2
		Decor.Bush(env, Vector3.new(math.cos(angle) * 62, 0, math.sin(angle) * 62), rng:NextNumber(3.5, 5.5))
	end

	Decor.Backdrop(env, Vector3.zero, 235, rng)
	Decor.AmbientMotes(env, Vector3.zero, 80, "Sunlight")

	kit:SetSpawn(Vector3.new(0, 3, -26), Vector3.new(0, 0, 0))
	kit:SetFinish(Vector3.new(0, 26, 0), Vector3.new(24, 50, 24))
	return kit:Finish()
end
