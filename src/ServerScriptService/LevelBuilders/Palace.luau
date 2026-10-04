--[[
	Palace - Level 7
	An enormous royal palace: four towers with golden domes, a grand hall with a central
	dome, crenellated walls, a gate, balconies and a courtyard.
]]

local BuildKit = require(script.Parent.BuildKit)

local WALL = Color3.fromRGB(246, 236, 218)
local TRIM = Color3.fromRGB(220, 200, 160)
local GOLD = Color3.fromRGB(240, 196, 70)
local GLASS = Color3.fromRGB(120, 170, 220)
local STONE = Color3.fromRGB(200, 192, 180)

return function(): Model
	local kit = BuildKit.new("Palace")

	kit:Part({ Name = "Courtyard", Size = Vector3.new(190, 0.4, 170), CFrame = CFrame.new(0, 0.2, -5), Color = Color3.fromRGB(214, 206, 190), Material = Enum.Material.Pavement })
	kit:Part({ Name = "Carpet", Size = Vector3.new(8, 0.45, 40), CFrame = CFrame.new(0, 0.25, -28), Color = Color3.fromRGB(180, 40, 50), Material = Enum.Material.Fabric, CanCollide = false })

	-- Grand hall
	kit:Surface({ Name = "GrandHall", Size = Vector3.new(70, 30, 36), CFrame = CFrame.new(0, 15.5, 8), Color = WALL, Material = Enum.Material.Limestone }, "Walls", { Faces = "Top,Front,Back,Left,Right" })
	kit:Part({ Name = "HallCornice", Size = Vector3.new(71.5, 1.2, 37.5), CFrame = CFrame.new(0, 30.4, 8), Color = TRIM })

	-- Central dome
	local size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 34, 8), 6, 26)
	kit:Surface({ Name = "DomeDrum", Size = size, CFrame = cf, Color = WALL, Material = Enum.Material.Limestone }, "Domes", { Faces = "Side" })
	kit:Surface({ Name = "CentralDome", Size = Vector3.new(26, 26, 26), CFrame = CFrame.new(0, 37, 8), Shape = Enum.PartType.Ball, Color = GOLD, Material = Enum.Material.Metal, Reflectance = 0.1 }, "Domes")
	size, cf = BuildKit.VerticalCylinder(Vector3.new(0, 53, 8), 6, 1.2)
	kit:Part({ Name = "Spire", Size = size, CFrame = cf, Color = GOLD, Material = Enum.Material.Metal })
	kit:Part({ Name = "SpireOrb", Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(0, 56.5, 8), Shape = Enum.PartType.Ball, Color = GOLD, Material = Enum.Material.Neon })

	-- Hall windows and entrance
	local function window(cframe: CFrame, width: number, height: number)
		kit:Part({ Name = "WindowTrim", Size = Vector3.new(width + 1.2, height + 1.2, 0.25), CFrame = cframe * CFrame.new(0, 0, 0.08), Color = GOLD, Material = Enum.Material.Metal })
		kit:Surface({ Name = "Window", Size = Vector3.new(width, height, 0.3), CFrame = cframe * CFrame.new(0, 0, -0.05), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.1 }, "Walls", { Faces = "Front" })
	end
	for _, y in ipairs({ 9, 22 }) do
		for _, x in ipairs({ -28, -19, -10, 10, 19, 28 }) do
			window(CFrame.new(x, y, -10.15), 4, 7)
			window(CFrame.new(x, y, 26.15) * CFrame.Angles(0, math.pi, 0), 4, 7)
		end
	end
	kit:Surface({ Name = "GrandDoors", Size = Vector3.new(10, 15, 0.4), CFrame = CFrame.new(0, 8.5, -10.2), Color = Color3.fromRGB(120, 60, 40), Material = Enum.Material.Wood }, "Gate", { Faces = "Front" })
	kit:Part({ Name = "DoorArch", Size = Vector3.new(12, 17, 0.3), CFrame = CFrame.new(0, 9.5, -10.05), Color = GOLD, Material = Enum.Material.Metal })
	kit:Surface({ Name = "EntranceSteps", Size = Vector3.new(24, 1, 6), CFrame = CFrame.new(0, 0.5, -13), Color = STONE, Material = Enum.Material.Marble }, "Courtyard", { Faces = "Top,Front,Left,Right" })

	-- Hall balconies
	for _, x in ipairs({ -19, 19 }) do
		kit:Surface({ Name = "Balcony", Size = Vector3.new(16, 1, 5), CFrame = CFrame.new(x, 16, -12.5), Color = STONE, Material = Enum.Material.Marble }, "Balconies", { Faces = "Top,Front,Left,Right,Bottom" })
		kit:Surface({ Name = "BalconyRail", Size = Vector3.new(16, 0.6, 0.6), CFrame = CFrame.new(x, 19, -14.7), Color = GOLD, Material = Enum.Material.Metal }, "Balconies", { Faces = "Top,Front" })
		for i = 0, 7 do
			kit:Part({ Name = "Baluster", Size = Vector3.new(0.4, 2.5, 0.4), CFrame = CFrame.new(x - 7.4 + i * 2.1, 17.75, -14.7), Color = TRIM })
		end
	end

	-- Towers with golden domes
	local towerPositions = { Vector3.new(-50, 0, -42), Vector3.new(50, 0, -42), Vector3.new(-50, 0, 34), Vector3.new(50, 0, 34) }
	for _, base in ipairs(towerPositions) do
		size, cf = BuildKit.VerticalCylinder(base + Vector3.new(0, 23.5, 0), 46, 12)
		kit:Surface({ Name = "Tower", Size = size, CFrame = cf, Color = WALL, Material = Enum.Material.Limestone }, "Towers", { Faces = "Side" })
		size, cf = BuildKit.VerticalCylinder(base + Vector3.new(0, 46.8, 0), 1.6, 14)
		kit:Surface({ Name = "TowerRing", Size = size, CFrame = cf, Color = TRIM, Material = Enum.Material.Limestone }, "Towers")
		kit:Surface({ Name = "TowerDome", Size = Vector3.new(13, 13, 13), CFrame = CFrame.new(base + Vector3.new(0, 48.5, 0)), Shape = Enum.PartType.Ball, Color = GOLD, Material = Enum.Material.Metal, Reflectance = 0.1 }, "Domes")
		kit:Part({ Name = "TowerSpire", Size = Vector3.new(0.8, 6, 0.8), CFrame = CFrame.new(base + Vector3.new(0, 57.5, 0)), Color = GOLD, Material = Enum.Material.Metal })
		-- Flag
		local flag = kit:Part({ Name = "Flag", Size = Vector3.new(0.1, 2, 3.4), CFrame = CFrame.new(base + Vector3.new(0, 59.4, 1.8)), Color = Color3.fromRGB(180, 40, 60), Material = Enum.Material.Fabric, CanCollide = false })
		flag.CastShadow = false
		-- Tower windows
		for _, y in ipairs({ 14, 28 }) do
			local outward = Vector3.new(base.X, 0, base.Z).Unit
			local position = base + Vector3.new(0, y, 0) + outward * 6.05
			kit:Part({ Name = "TowerWindow", Size = Vector3.new(2.4, 5, 0.3), CFrame = CFrame.lookAt(position, position + outward), Color = GLASS, Material = Enum.Material.Glass })
		end
	end

	-- Curtain walls between the towers
	local function wall(from: Vector3, to: Vector3, height: number, thickness: number, skipCenter: number?)
		local direction = to - from
		local length = direction.Magnitude
		local rotation = CFrame.lookAt(Vector3.zero, direction.Unit)
		local center = (from + to) / 2
		kit:Surface({
			Name = "CurtainWall",
			Size = Vector3.new(thickness, height, length),
			CFrame = CFrame.new(center + Vector3.new(0, height / 2 + 0.4, 0)) * rotation,
			Color = WALL,
			Material = Enum.Material.Limestone,
		}, "Walls", { Faces = "Top,Left,Right" })
		-- Crenellations
		local count = math.floor(length / 4)
		for i = 0, count - 1 do
			local position = from + direction.Unit * ((i + 0.5) * length / count)
			if skipCenter and math.abs(position.X) < skipCenter then
				continue
			end
			-- Wall ends stay clear for trusses
			if i % 2 == 0 and i > 0 and i < count - 1 then
				kit:Part({
					Name = "Merlon",
					Size = Vector3.new(thickness, 2.4, 2),
					CFrame = CFrame.new(position + Vector3.new(0, height + 1.6, 0)) * rotation,
					Color = TRIM,
					Material = Enum.Material.Limestone,
				})
			end
		end
	end
	wall(Vector3.new(-44, 0, -42), Vector3.new(-12, 0, -42), 16, 4)
	wall(Vector3.new(12, 0, -42), Vector3.new(44, 0, -42), 16, 4)
	wall(Vector3.new(-50, 0, -36), Vector3.new(-50, 0, 28), 16, 4)
	wall(Vector3.new(50, 0, -36), Vector3.new(50, 0, 28), 16, 4)
	wall(Vector3.new(-44, 0, 34), Vector3.new(44, 0, 34), 16, 4)

	-- Gate
	for _, x in ipairs({ -12, 12 }) do
		kit:Surface({ Name = "GateTower", Size = Vector3.new(8, 24, 8), CFrame = CFrame.new(x, 12.4, -42), Color = WALL, Material = Enum.Material.Limestone }, "Gate", { Faces = "Top,Front,Back,Left,Right" })
		kit:Surface({ Name = "GateTowerRoof", Class = "WedgePart", Size = Vector3.new(9, 4, 4.5), CFrame = CFrame.new(x, 26.4, -44.25), Color = GOLD, Material = Enum.Material.Metal }, "Domes", { Faces = "Slope" })
		kit:Surface({ Name = "GateTowerRoof", Class = "WedgePart", Size = Vector3.new(9, 4, 4.5), CFrame = CFrame.new(x, 26.4, -39.75) * CFrame.Angles(0, math.pi, 0), Color = GOLD, Material = Enum.Material.Metal }, "Domes", { Faces = "Slope" })
	end
	kit:Surface({ Name = "GateArch", Size = Vector3.new(16, 6, 6), CFrame = CFrame.new(0, 19.4, -42), Color = WALL, Material = Enum.Material.Limestone }, "Gate", { Faces = "Top,Front,Back,Bottom" })
	kit:Part({ Name = "GateCrest", Size = Vector3.new(5, 5, 0.4), CFrame = CFrame.new(0, 19.4, -45.2) * CFrame.Angles(0, 0, math.rad(45)), Color = GOLD, Material = Enum.Material.Metal })

	-- Courtyard: planters, trees, obelisks, fountain basin
	for _, x in ipairs({ -30, 30 }) do
		for _, z in ipairs({ -32, -20 }) do
			kit:Surface({ Name = "Planter", Size = Vector3.new(7, 2.4, 7), CFrame = CFrame.new(x, 1.6, z), Color = STONE, Material = Enum.Material.Marble }, "Courtyard", { Faces = "Front,Back,Left,Right" })
			local trunkSize, trunkCF = BuildKit.VerticalCylinder(Vector3.new(x, 5, z), 6, 1.2)
			kit:Part({ Name = "Trunk", Size = trunkSize, CFrame = trunkCF, Color = Color3.fromRGB(110, 76, 50), Material = Enum.Material.Wood })
			kit:Part({ Name = "Foliage", Size = Vector3.new(7, 7, 7), CFrame = CFrame.new(x, 10, z), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(70, 150, 70), Material = Enum.Material.Grass })
		end
	end
	for _, x in ipairs({ -16, 16 }) do
		kit:Surface({ Name = "Obelisk", Size = Vector3.new(2.4, 12, 2.4), CFrame = CFrame.new(x, 6.4, -30), Color = TRIM, Material = Enum.Material.Marble }, "Courtyard", { Faces = "Front,Back,Left,Right" })
		kit:Surface({ Name = "ObeliskTip", Class = "WedgePart", Size = Vector3.new(2.4, 2, 1.2), CFrame = CFrame.new(x, 13.4, -30.6), Color = GOLD, Material = Enum.Material.Metal }, "Courtyard", { Faces = "Slope" })
	end

	-- Access
	kit:Truss(Vector3.new(-36.2, 0.4, -8), 30)
	kit:Truss(Vector3.new(36.2, 0.4, -8), 30)
	kit:Truss(Vector3.new(-26, 0.4, -38.8), 16)
	kit:Truss(Vector3.new(26, 0.4, -38.8), 16)
	-- From the front wall up to a ledge next to the front tower domes
	for _, base in ipairs({ towerPositions[1], towerPositions[2] }) do
		local inward = -math.sign(base.X)
		kit:Truss(Vector3.new(base.X + inward * 8.6, 16.4, -43), 24)
		kit:Platform(CFrame.new(base.X + inward * 7.6, 40.7, -39.4), Vector3.new(3.2, 0.6, 5.2))
	end
	for _, x in ipairs({ -19, 19 }) do
		kit:Truss(Vector3.new(x + 9.2, 0.4, -14), 16)
	end

	kit:SetSpawn(Vector3.new(0, 3, -62), Vector3.new(0, 0, 0))
	kit:SetFinish(Vector3.new(0, 25, -4), Vector3.new(112, 60, 84))
	return kit:Finish()
end
