--[[
	Airplane - Level 6
	A gigantic airliner: wings, fuselage, tail, engines, cockpit and landing gear.
	Airstairs and scaffolding give access to the wings, roof and tail fin.
]]

local BuildKit = require(script.Parent.BuildKit)

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
	kit:Surface({ Name = "Fuselage", Size = size, CFrame = cf, Color = WHITE, Material = Enum.Material.SmoothPlastic }, "Fuselage", { Faces = "Side" })
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
	kit:Surface({ Name = "TailCone", Size = size, CFrame = cf, Color = WHITE }, "Tail", { Faces = "Side" })
	size, cf = BuildKit.ZCylinder(Vector3.new(0, 14.8, 57.5), 6, 9.4)
	kit:Surface({ Name = "TailCone", Size = size, CFrame = cf, Color = WHITE }, "Tail", { Faces = "Side" })
	size, cf = BuildKit.ZCylinder(Vector3.new(0, 16.2, 62.5), 5, 6.4)
	kit:Surface({ Name = "TailCone", Size = size, CFrame = cf, Color = WHITE }, "Tail", { Faces = "Side,Ends" })

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
		kit:Surface({ Name = "Engine", Size = size, CFrame = cf, Color = GREY, Material = Enum.Material.Metal }, "Engines", { Faces = "Side" })
		size, cf = BuildKit.ZCylinder(engineCenter + Vector3.new(0, 0, -5.4), 0.8, 6)
		kit:Surface({ Name = "Intake", Size = size, CFrame = cf, Color = Color3.fromRGB(200, 205, 214), Material = Enum.Material.Metal }, "Engines", { Faces = "Side" })
		size, cf = BuildKit.ZCylinder(engineCenter + Vector3.new(0, 0, -5.3), 0.5, 4.8)
		kit:Part({ Name = "Fan", Size = size, CFrame = cf, Color = DARK, Material = Enum.Material.Metal })
		kit:Part({ Name = "Pylon", Size = Vector3.new(1, 2.6, 7), CFrame = CFrame.new(engineCenter + Vector3.new(0, 3.2, 0.5)), Color = GREY })

		-- Main landing gear
		local gearX = side * 7.5
		size, cf = BuildKit.VerticalCylinder(Vector3.new(gearX, 4.5, 6), 6, 0.9)
		kit:Surface({ Name = "GearStrut", Size = size, CFrame = cf, Color = GREY, Material = Enum.Material.Metal }, "Landing Gear", { Faces = "Side" })
		for _, dz in ipairs({ -1.5, 1.5 }) do
			kit:Surface({ Name = "GearWheel", Size = Vector3.new(1.6, 3.2, 3.2), CFrame = CFrame.new(gearX, 1.6, 6 + dz), Shape = Enum.PartType.Cylinder, Color = DARK, Material = Enum.Material.Rubber }, "Landing Gear")
		end
	end

	-- Nose gear
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 4, -40), 5, 0.8)
	kit:Surface({ Name = "NoseStrut", Size = size, CFrame = cf, Color = GREY, Material = Enum.Material.Metal }, "Landing Gear", { Faces = "Side" })
	for _, x in ipairs({ -0.9, 0.9 }) do
		kit:Surface({ Name = "NoseWheel", Size = Vector3.new(1, 2.6, 2.6), CFrame = CFrame.new(x, 1.3, -40), Shape = Enum.PartType.Cylinder, Color = DARK, Material = Enum.Material.Rubber }, "Landing Gear")
	end

	-- Access: airstairs to the left wing, trusses to the roof, scaffold at the tail
	kit:Stairs(Vector3.new(-30, 0, -22), Vector3.new(0, 0, 1), 9.5, 4, Color3.fromRGB(230, 230, 236))
	kit:Truss(Vector3.new(9, 0.4, -22), 19.6)
	kit:Truss(Vector3.new(-9, 0.4, 24), 19.6)
	kit:Truss(Vector3.new(10.5, 0.4, 52), 19)
	kit:Platform(CFrame.new(6.5, 19.7, 52), Vector3.new(5, 0.6, 10))

	kit:SetSpawn(Vector3.new(-36, 3, -48), Vector3.new(0, 0, 0))
	kit:SetFinish(Vector3.new(0, 14, 5), Vector3.new(100, 30, 120))
	return kit:Finish()
end
