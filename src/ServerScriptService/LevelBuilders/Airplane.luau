--[[
	Airplane - Level 6
	A gigantic airliner: wings, fuselage, tail, engines, cockpit and landing gear.
	Airstairs and scaffolding give access to the wings, roof and tail fin.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)

local WHITE = Color3.fromRGB(244, 246, 250)
local BLUE = Color3.fromRGB(40, 90, 200)
local GREY = Color3.fromRGB(170, 176, 186)
local DARK = Color3.fromRGB(40, 44, 54)

return function(): Model
	local kit = BuildKit.new("Airplane")

	-- Runway
	kit:Part({ Name = "Runway", Size = Vector3.new(140, 0.4, 190), CFrame = CFrame.new(0, 0.2, 5), Color = Color3.fromRGB(70, 72, 78), Material = Enum.Material.Asphalt })
	for i = -8, 8 do
		kit:Part({ Name = "RunwayLine", Size = Vector3.new(1, 0.45, 6), CFrame = CFrame.new(0, 0.22, i * 11), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	end

	-- Fuselage
	local size, cf = BuildKit.ZCylinder(Vector3.new(0, 13, 0), 96, 14)
	kit:Surface({ Name = "Fuselage", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WHITE, Material = Enum.Material.SmoothPlastic }, "Fuselage", { Faces = "Side" })
	-- Passenger windows
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 25 do
			local z = -38 + i * 3
			local x = side * 6.75
			kit:Part({
				Name = "Window",
				Size = Vector3.new(0.3, 1.3, 0.9),
				CFrame = CFrame.new(x, 15, z) * CFrame.Angles(0, 0, side * math.rad(-16)),
				Color = DARK,
				Material = Enum.Material.Glass,
				CanCollide = false,
			})
		end
	end
	-- Door
	kit:Part({ Name = "Door", Size = Vector3.new(0.3, 4.6, 2.6), CFrame = CFrame.new(-6.95, 12.6, -34), Color = GREY, CanCollide = false })

	-- Nose & cockpit
	kit:Surface({ Name = "Nose", Size = Vector3.new(14, 14, 14), CFrame = CFrame.new(0, 13, -48), Shape = Enum.PartType.Ball, Color = WHITE }, "Cockpit")
	for _, x in ipairs({ -2.6, -0.9, 0.9, 2.6 }) do
		local position = Vector3.new(0, 13, -48) + Vector3.new(x, 3.6, -6.0)
		local normal = (position - Vector3.new(0, 13, -48)).Unit
		kit:Part({ Name = "CockpitWindow", Size = Vector3.new(1.5, 1, 0.3), CFrame = CFrame.lookAt(position + normal * 0.1, position + normal * 2), Color = DARK, Material = Enum.Material.Glass, CanCollide = false })
	end

	-- Tail cone
	size, cf = BuildKit.ZCylinder(Vector3.new(0, 13.6, 51), 8, 12.4)
	kit:Surface({ Name = "TailCone", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WHITE }, "Tail", { Faces = "Side" })
	size, cf = BuildKit.ZCylinder(Vector3.new(0, 14.8, 57.5), 6, 9.4)
	kit:Surface({ Name = "TailCone", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WHITE }, "Tail", { Faces = "Side" })
	size, cf = BuildKit.ZCylinder(Vector3.new(0, 16.2, 62.5), 5, 6.4)
	kit:Surface({ Name = "TailCone", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WHITE }, "Tail", { Faces = "Side,Ends" })

	-- Vertical fin & horizontal stabilizers
	kit:Surface({ Name = "Fin", Size = Vector3.new(1, 15, 9), CFrame = CFrame.new(0, 25, 59) * CFrame.Angles(math.rad(28), 0, 0), Color = BLUE }, "Tail", { Faces = "Left,Right,Front,Back,Top" })
	for _, side in ipairs({ -1, 1 }) do
		kit:Surface({
			Name = "Stabilizer",
			Size = Vector3.new(15, 0.9, 6.5),
			CFrame = CFrame.new(side * 9.5, 16.4, 60) * CFrame.Angles(0, side * math.rad(-18), side * math.rad(5)),
			Color = WHITE,
		}, "Tail", { Faces = "Top,Bottom,Front,Back" })
	end

	-- Wings with winglets
	for _, side in ipairs({ -1, 1 }) do
		local wingCF = CFrame.new(side * 28, 9.6, 3) * CFrame.Angles(0, side * math.rad(-14), side * math.rad(4))
		kit:Surface({ Name = "Wing", Size = Vector3.new(44, 1.4, 15), CFrame = wingCF, Color = WHITE }, "Wings", { Faces = "Top,Bottom,Front,Back" })
		kit:Surface({ Name = "Winglet", Size = Vector3.new(0.8, 6, 5), CFrame = wingCF * CFrame.new(side * 22, 2.8, 4) * CFrame.Angles(0, 0, side * math.rad(-12)), Color = BLUE }, "Wings", { Faces = "Left,Right,Front" })
		kit:Part({ Name = "WingLight", Size = Vector3.new(0.6, 0.6, 0.6), CFrame = wingCF * CFrame.new(side * 21.8, 0.5, -6), Shape = Enum.PartType.Ball, Color = if side > 0 then Color3.fromRGB(40, 255, 80) else Color3.fromRGB(255, 40, 40), Material = Enum.Material.Neon, CanCollide = false })

		-- Engines
		local engineCenter = Vector3.new(side * 16, 5.8, -4)
		size, cf = BuildKit.ZCylinder(engineCenter, 11, 5.6)
		kit:Surface({ Name = "Engine", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = GREY, Material = Enum.Material.Metal }, "Engines", { Faces = "Side" })
		size, cf = BuildKit.ZCylinder(engineCenter + Vector3.new(0, 0, -5.4), 0.8, 6)
		kit:Surface({ Name = "Intake", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(200, 205, 214), Material = Enum.Material.Metal }, "Engines", { Faces = "Side" })
		size, cf = BuildKit.ZCylinder(engineCenter + Vector3.new(0, 0, -5.3), 0.5, 4.8)
		kit:Part({ Name = "Fan", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = DARK, Material = Enum.Material.Metal })
		kit:Part({ Name = "Pylon", Size = Vector3.new(1, 2.6, 7), CFrame = CFrame.new(engineCenter + Vector3.new(0, 3.2, 0.5)), Color = GREY })

		-- Main landing gear
		local gearX = side * 7.5
		size, cf = BuildKit.VerticalCylinder(Vector3.new(gearX, 4.5, 6), 6, 0.9)
		kit:Surface({ Name = "GearStrut", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = GREY, Material = Enum.Material.Metal }, "Landing Gear", { Faces = "Side" })
		for _, dz in ipairs({ -1.5, 1.5 }) do
			kit:Surface({ Name = "GearWheel", Size = Vector3.new(1.6, 3.2, 3.2), CFrame = CFrame.new(gearX, 1.6, 6 + dz), Shape = Enum.PartType.Cylinder, Color = DARK, Material = Enum.Material.Rubber }, "Landing Gear")
		end
	end

	-- Nose gear
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 4, -40), 5, 0.8)
	kit:Surface({ Name = "NoseStrut", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = GREY, Material = Enum.Material.Metal }, "Landing Gear", { Faces = "Side" })
	for _, x in ipairs({ -0.9, 0.9 }) do
		kit:Surface({ Name = "NoseWheel", Size = Vector3.new(1, 2.6, 2.6), CFrame = CFrame.new(x, 1.3, -40), Shape = Enum.PartType.Cylinder, Color = DARK, Material = Enum.Material.Rubber }, "Landing Gear")
	end

	-- Access: airstairs to the left wing, trusses to the roof, scaffold at the tail
	kit:Stairs(Vector3.new(-30, 0, -22), Vector3.new(0, 0, 1), 9.5, 4, Color3.fromRGB(230, 230, 236))
	kit:Truss(Vector3.new(9, 0.4, -22), 19.6)
	kit:Truss(Vector3.new(-9, 0.4, 24), 19.6)
	kit:Truss(Vector3.new(10.5, 0.4, 52), 19)
	kit:Platform(CFrame.new(6.5, 19.7, 52), Vector3.new(5, 0.6, 10))

	------------------------------------------------------------------
	-- Environment: airport
	------------------------------------------------------------------
	local env = kit.Environment
	local rng = Random.new(606)

	-- Long runway with threshold stripes and edge lights
	kit:Decor({ Name = "RunwayStrip", Size = Vector3.new(60, 0.1, 500), CFrame = CFrame.new(0, 0.05, 0), Color = Color3.fromRGB(64, 66, 72), Material = Enum.Material.Asphalt })
	kit:Decor({ Name = "Apron", Size = Vector3.new(120, 0.08, 160), CFrame = CFrame.new(150, 0.04, 10), Color = Color3.fromRGB(150, 150, 156), Material = Enum.Material.Concrete })
	for _, z in ipairs({ -235, 235 }) do
		for k = -3, 3 do
			kit:Decor({ Name = "Threshold", Size = Vector3.new(4, 0.12, 22), CFrame = CFrame.new(k * 7.5, 0.1, z), Color = Color3.fromRGB(245, 245, 245), CanCollide = false, CastShadow = false })
		end
	end
	for z = -240, 240, 16 do
		for _, x in ipairs({ -82, 82 }) do
			kit:Decor({ Name = "EdgeLight", Size = Vector3.new(0.6, 0.8, 0.6), CFrame = CFrame.new(x, 0.4, z), Color = if math.abs(z) > 200 then Color3.fromRGB(255, 90, 90) else Color3.fromRGB(110, 170, 255), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
	end
	for z = -60, 120, 30 do
		kit:Decor({ Name = "TaxiLine", Size = Vector3.new(0.6, 0.12, 18), CFrame = CFrame.new(100, 0.1, z), Color = Color3.fromRGB(255, 205, 60), CanCollide = false, CastShadow = false })
	end

	-- Terminal with a sign
	local terminal = CFrame.lookAt(Vector3.new(185, 0, 10), Vector3.new(0, 0, 10))
	Decor.Building(env, terminal, Vector3.new(170, 20, 40), Color3.fromRGB(232, 236, 242), {
		Floors = 2,
		WindowColor = Color3.fromRGB(120, 200, 245),
		TrimColor = Color3.fromRGB(70, 120, 200),
		Door = false,
	})
	Decor.NeonSign(env, terminal * CFrame.new(0, 23.5, -20.4), "STICKER AIR", Color3.fromRGB(80, 170, 255), 30)
	for k = -2, 2 do
		Decor.FlagPole(env, (terminal * CFrame.new(k * 14, 0, -30)).Position, 12, Color3.fromRGB(80, 150, 255))
	end

	-- Control tower
	local towerBase = Vector3.new(200, 0, -150)
	local shaft, shaftCF = BuildKit.VerticalCylinder(towerBase + Vector3.new(0, 24, 0), 48, 10)
	kit:Decor({ Name = "TowerShaft", Size = shaft, CFrame = shaftCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(236, 238, 242), Material = Enum.Material.Concrete })
	local cab, cabCF = BuildKit.VerticalCylinder(towerBase + Vector3.new(0, 52, 0), 8, 18)
	kit:Decor({ Name = "TowerCab", Size = cab, CFrame = cabCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(70, 140, 190), Material = Enum.Material.Glass, Transparency = 0.15 })
	local roof, roofCF = BuildKit.VerticalCylinder(towerBase + Vector3.new(0, 56.6, 0), 1.2, 20)
	kit:Decor({ Name = "TowerRoof", Size = roof, CFrame = roofCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(60, 64, 74), Material = Enum.Material.Metal })
	kit:Decor({ Name = "Antenna", Size = Vector3.new(0.5, 10, 0.5), CFrame = CFrame.new(towerBase + Vector3.new(0, 62, 0)), Color = Color3.fromRGB(220, 60, 60), Material = Enum.Material.Metal })
	local beacon = kit:Decor({ Name = "Beacon", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(towerBase + Vector3.new(0, 67.5, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 70, 70), Material = Enum.Material.Neon, CanCollide = false })
	local beaconLight = Instance.new("PointLight")
	beaconLight.Shadows = false
	beaconLight:SetAttribute("Night", true)
	beaconLight.Range = 16
	beaconLight.Color = Color3.fromRGB(255, 80, 80)
	beaconLight.Parent = beacon

	-- Hangar with an arched roof
	local hangar = Vector3.new(-165, 0, 80)
	kit:Decor({ Name = "HangarWalls", Size = Vector3.new(60, 22, 64), CFrame = CFrame.new(hangar + Vector3.new(0, 11, 0)), Color = Color3.fromRGB(196, 202, 210), Material = Enum.Material.CorrodedMetal })
	local arch, archCF = BuildKit.ZCylinder(hangar + Vector3.new(0, 22, 0), 64, 60)
	kit:Decor({ Name = "HangarRoof", Size = arch, CFrame = archCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(150, 160, 172), Material = Enum.Material.CorrodedMetal })
	kit:Decor({ Name = "HangarDoor", Size = Vector3.new(0.4, 18, 50), CFrame = CFrame.new(hangar + Vector3.new(30.2, 9, 0)), Color = Color3.fromRGB(70, 76, 88), Material = Enum.Material.DiamondPlate })
	kit:Decor({ Name = "HangarStripe", Size = Vector3.new(0.5, 2, 64), CFrame = CFrame.new(hangar + Vector3.new(30.3, 20, 0)), Color = Color3.fromRGB(255, 200, 50), CanCollide = false })

	-- Ground equipment
	for k = 0, 2 do
		local cart = CFrame.new(-28 - k * 8, 0, 30) * CFrame.Angles(0, math.rad(90), 0)
		kit:Decor({ Name = "BaggageCart", Size = Vector3.new(4, 1.8, 6), CFrame = cart * CFrame.new(0, 2, 0), Color = Color3.fromRGB(80, 90, 104), Material = Enum.Material.Metal })
		kit:Decor({ Name = "Luggage", Size = Vector3.new(2, 1.4, 2.6), CFrame = cart * CFrame.new(0.5, 3.6, -1), Color = ({ Color3.fromRGB(220, 80, 80), Color3.fromRGB(70, 150, 220), Color3.fromRGB(240, 190, 60) })[k + 1] })
		for _, x in ipairs({ -1.8, 1.8 }) do
			for _, z in ipairs({ -2.2, 2.2 }) do
				kit:Decor({ Name = "CartWheel", Size = Vector3.new(0.5, 1.2, 1.2), CFrame = cart * CFrame.new(x, 0.6, z), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Rubber })
			end
		end
	end
	Decor.Car(env, CFrame.new(-6, 0, 30) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 200, 40))
	for _, position in ipairs({ Vector3.new(0, 0, -68), Vector3.new(-12, 0, -60), Vector3.new(12, 0, -60), Vector3.new(-17, 0, -10), Vector3.new(17, 0, -10) }) do
		Decor.Cone(env, position)
	end

	-- Windsock
	local sock = Vector3.new(-110, 0, -160)
	local pole, poleCF = BuildKit.VerticalCylinder(sock + Vector3.new(0, 7, 0), 14, 0.5)
	kit:Decor({ Name = "WindsockPole", Size = pole, CFrame = poleCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(230, 230, 236), Material = Enum.Material.Metal })
	for k = 0, 2 do
		local segment, segmentCF = BuildKit.ZCylinder(sock + Vector3.new(0, 13.2 - k * 0.4, 1.6 + k * 2.6), 2.6, 2.4 - k * 0.5)
		kit:Decor({ Name = "Windsock", Size = segment, CFrame = segmentCF * CFrame.Angles(0, 0, 0), Shape = Enum.PartType.Cylinder, Color = if k % 2 == 0 then Color3.fromRGB(255, 120, 40) else Color3.fromRGB(250, 250, 250), Material = Enum.Material.Fabric, CanCollide = false })
	end

	Decor.Backdrop(env, Vector3.zero, 245, rng, "Pine", {
		{ Position = Vector3.new(185, 0, 10), Radius = 110 },
		{ Position = towerBase, Radius = 24 },
		{ Position = hangar, Radius = 55 },
	})

	kit:SetSpawn(Vector3.new(-36, 3, -48), Vector3.new(0, 0, 0))
	kit:SetFinish(Vector3.new(0, 14, 5), Vector3.new(100, 30, 120))
	return kit:Finish()
end
