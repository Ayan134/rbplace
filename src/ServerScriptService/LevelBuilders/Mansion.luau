--[[
	Mansion - Level 5
	A huge mansion: main hall with columned portico, two wings, roofs, many windows,
	front stairs and a pool.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)

local WALL = Color3.fromRGB(242, 240, 236)
local TRIM = Color3.fromRGB(205, 200, 190)
local ROOF = Color3.fromRGB(64, 72, 96)
local GLASS = Color3.fromRGB(130, 180, 220)
local STONE = Color3.fromRGB(196, 190, 182)

return function(): Model
	local kit = BuildKit.new("Mansion")

	kit:Part({ Name = "Lawn", Size = Vector3.new(150, 0.4, 120), CFrame = CFrame.new(0, 0.2, 5), Color = Color3.fromRGB(100, 176, 76), Material = Enum.Material.Grass })
	kit:Part({ Name = "Foundation", Size = Vector3.new(104, 1, 32), CFrame = CFrame.new(0, 0.5, 0), Color = STONE, Material = Enum.Material.Concrete })

	-- Main hall
	kit:Surface({ Name = "MainHall", Size = Vector3.new(50, 24, 30), CFrame = CFrame.new(0, 13, 0), Color = WALL, Material = Enum.Material.Plaster }, "Walls", { Faces = "Front,Back,Left,Right" })
	kit:Part({ Name = "Cornice", Size = Vector3.new(51, 1, 31), CFrame = CFrame.new(0, 25.5, 0), Color = TRIM })
	kit:Surface({ Name = "RoofFront", Class = "WedgePart", Size = Vector3.new(52, 8, 15.5), CFrame = CFrame.new(0, 30, -7.75), Color = ROOF, Material = Enum.Material.Slate }, "Roof", { Faces = "Slope" })
	kit:Surface({ Name = "RoofBack", Class = "WedgePart", Size = Vector3.new(52, 8, 15.5), CFrame = CFrame.new(0, 30, 7.75) * CFrame.Angles(0, math.pi, 0), Color = ROOF, Material = Enum.Material.Slate }, "Roof", { Faces = "Slope" })
	for _, x in ipairs({ -25.5, 25.5 }) do
		for _, sign in ipairs({ -1, 1 }) do
			kit:Surface({
				Name = "Gable",
				Class = "WedgePart",
				Size = Vector3.new(0.6, 7.8, 15),
				CFrame = CFrame.new(x, 29.9, sign * 7.5) * CFrame.Angles(0, if sign > 0 then math.pi else 0, 0),
				Color = WALL,
				Material = Enum.Material.Plaster,
			}, "Walls", { Faces = "Sides" })
		end
	end
	for _, x in ipairs({ -16, 16 }) do
		kit:Surface({ Name = "Chimney", Size = Vector3.new(3, 9, 3), CFrame = CFrame.new(x, 32, 5), Color = Color3.fromRGB(160, 80, 70), Material = Enum.Material.Brick }, "Roof")
	end

	-- Wings
	for _, sign in ipairs({ -1, 1 }) do
		local x = sign * 38
		kit:Surface({ Name = "Wing", Size = Vector3.new(26, 16, 24), CFrame = CFrame.new(x, 9, 0), Color = WALL, Material = Enum.Material.Plaster }, "Wings", { Faces = if sign > 0 then "Top,Front,Back,Right" else "Top,Front,Back,Left" })
		-- Parapet around the flat roof
		kit:Surface({ Name = "Parapet", Size = Vector3.new(26, 1.6, 0.8), CFrame = CFrame.new(x, 17.8, -11.6), Color = TRIM }, "Roof", { Faces = "Top,Front" })
		kit:Surface({ Name = "Parapet", Size = Vector3.new(26, 1.6, 0.8), CFrame = CFrame.new(x, 17.8, 11.6), Color = TRIM }, "Roof", { Faces = "Top,Back" })
		kit:Surface({ Name = "Parapet", Size = Vector3.new(0.8, 1.6, 24), CFrame = CFrame.new(x + sign * 12.6, 17.8, 0), Color = TRIM }, "Roof", { Faces = if sign > 0 then "Top,Right" else "Top,Left" })
		-- Wing balcony
		kit:Surface({ Name = "WingBalcony", Size = Vector3.new(12, 0.8, 4), CFrame = CFrame.new(x, 9.4, -14), Color = STONE, Material = Enum.Material.Marble }, "Wings", { Faces = "Top,Front,Left,Right" })
		kit:Surface({ Name = "WingBalconyRail", Size = Vector3.new(12, 0.6, 0.5), CFrame = CFrame.new(x, 12.4, -15.75), Color = TRIM }, "Wings", { Faces = "Top,Front" })
		for i = 0, 5 do
			kit:Part({ Name = "Baluster", Size = Vector3.new(0.4, 2.6, 0.4), CFrame = CFrame.new(x - 5.5 + i * 2.2, 11.1, -15.75), Color = TRIM })
		end
	end

	-- Windows
	local function window(cframe: CFrame, width: number, height: number)
		kit:Part({ Name = "WindowFrame", Size = Vector3.new(width + 1, height + 1, 0.25), CFrame = cframe * CFrame.new(0, 0, 0.08), Color = TRIM })
		kit:Surface({ Name = "Window", Size = Vector3.new(width, height, 0.3), CFrame = cframe * CFrame.new(0, 0, -0.05), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.1 }, "Windows", { Faces = "Front" })
	end
	for _, y in ipairs({ 7.5, 17.5 }) do
		for _, x in ipairs({ -20, -13, 13, 20 }) do
			window(CFrame.new(x, y, -15.15), 4, 6)
		end
		for _, x in ipairs({ -20, -13, -6, 6, 13, 20 }) do
			window(CFrame.new(x, y, 15.15) * CFrame.Angles(0, math.pi, 0), 4, 6)
		end
	end
	for _, sign in ipairs({ -1, 1 }) do
		for _, y in ipairs({ 5.5, 13 }) do
			for _, dx in ipairs({ -8, 0, 8 }) do
				local x = sign * 38 + dx
				if not (y > 9 and dx == 0) then
					window(CFrame.new(x, y, -12.15), 4, 4.6)
				end
				window(CFrame.new(x, y, 12.15) * CFrame.Angles(0, math.pi, 0), 4, 4.6)
			end
		end
	end

	-- Doors
	kit:Surface({ Name = "FrontDoors", Size = Vector3.new(8, 12, 0.4), CFrame = CFrame.new(0, 8, -15.2), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood }, "Walls", { Faces = "Front" })
	kit:Part({ Name = "DoorFrame", Size = Vector3.new(9.4, 13, 0.3), CFrame = CFrame.new(0, 8.4, -15.05), Color = TRIM })

	-- Portico: floor, steps, columns, roof, pediment
	kit:Surface({ Name = "PorticoFloor", Size = Vector3.new(40, 1, 10), CFrame = CFrame.new(0, 1.5, -20), Color = STONE, Material = Enum.Material.Marble }, "Stairs", { Faces = "Top,Front,Left,Right" })
	kit:Surface({ Name = "FrontSteps", Size = Vector3.new(44, 1, 4), CFrame = CFrame.new(0, 0.5, -27), Color = STONE, Material = Enum.Material.Marble }, "Stairs", { Faces = "Top,Front,Left,Right", StickerWeight = 0.7 })
	for i = 0, 5 do
		local x = -15 + i * 6
		local size, cf = BuildKit.VerticalCylinder(Vector3.new(x, 12, -22.5), 20, 2.8)
		kit:Surface({ Name = "Column", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = WALL, Material = Enum.Material.Marble }, "Columns", { Faces = "Side" })
		kit:Part({ Name = "ColumnBase", Size = Vector3.new(3.6, 0.8, 3.6), CFrame = CFrame.new(x, 2.4, -22.5), Color = TRIM, Material = Enum.Material.Marble })
		kit:Part({ Name = "ColumnCap", Size = Vector3.new(3.6, 0.8, 3.6), CFrame = CFrame.new(x, 21.6, -22.5), Color = TRIM, Material = Enum.Material.Marble })
	end
	kit:Surface({ Name = "PorticoRoof", Size = Vector3.new(40, 2, 10), CFrame = CFrame.new(0, 23, -20), Color = WALL, Material = Enum.Material.Marble }, "Roof", { Faces = "Top,Front,Left,Right,Bottom" })
	kit:Surface({ Name = "Pediment", Class = "WedgePart", Size = Vector3.new(2, 6, 20), CFrame = CFrame.new(10, 27, -24) * CFrame.Angles(0, -math.pi / 2, 0), Color = WALL, Material = Enum.Material.Marble }, "Roof", { Faces = "Slope,Sides" })
	kit:Surface({ Name = "Pediment", Class = "WedgePart", Size = Vector3.new(2, 6, 20), CFrame = CFrame.new(-10, 27, -24) * CFrame.Angles(0, math.pi / 2, 0), Color = WALL, Material = Enum.Material.Marble }, "Roof", { Faces = "Slope,Sides" })
	kit:Part({ Name = "PedimentBack", Size = Vector3.new(40, 6, 7), CFrame = CFrame.new(0, 27, -19.5), Color = WALL, Material = Enum.Material.Marble })

	-- Pool
	kit:Part({ Name = "PoolWater", Size = Vector3.new(30, 0.4, 16), CFrame = CFrame.new(0, 0.5, 34), Color = Color3.fromRGB(60, 180, 230), Material = Enum.Material.Glass, Transparency = 0.2 })
	kit:Surface({ Name = "PoolRim", Size = Vector3.new(33, 1.2, 1.5), CFrame = CFrame.new(0, 0.6, 25.25), Color = STONE, Material = Enum.Material.Marble }, "Pool", { Faces = "Top,Front,Back" })
	kit:Surface({ Name = "PoolRim", Size = Vector3.new(33, 1.2, 1.5), CFrame = CFrame.new(0, 0.6, 42.75), Color = STONE, Material = Enum.Material.Marble }, "Pool", { Faces = "Top,Front,Back" })
	for _, x in ipairs({ -15.75, 15.75 }) do
		kit:Surface({ Name = "PoolRim", Size = Vector3.new(1.5, 1.2, 16), CFrame = CFrame.new(x, 0.6, 34), Color = STONE, Material = Enum.Material.Marble }, "Pool", { Faces = "Top,Left,Right" })
	end
	for _, x in ipairs({ -22, 22 }) do
		kit:Surface({ Name = "SunLounger", Size = Vector3.new(3, 1, 7), CFrame = CFrame.new(x, 1, 34), Color = Color3.fromRGB(255, 255, 255) }, "Pool")
		kit:Part({ Name = "Umbrella", Size = Vector3.new(0.4, 7, 0.4), CFrame = CFrame.new(x, 3.5, 39), Color = Color3.fromRGB(240, 240, 240) })
		local size, cf = BuildKit.VerticalCylinder(Vector3.new(x, 7, 39), 0.6, 8)
		kit:Part({ Name = "UmbrellaTop", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 120, 90), Material = Enum.Material.Fabric, CanCollide = false })
	end

	-- Hedges
	for _, x in ipairs({ -60, 60 }) do
		kit:Part({ Name = "Hedge", Size = Vector3.new(4, 4, 60), CFrame = CFrame.new(x, 2, 5), Color = Color3.fromRGB(60, 130, 56), Material = Enum.Material.Grass })
	end

	-- Access
	for _, sign in ipairs({ -1, 1 }) do
		kit:Truss(Vector3.new(sign * 52.2, 1, 0), 16.6)
		kit:Truss(Vector3.new(sign * 26.2, 17, -6), 8.6)
	end
	kit:Truss(Vector3.new(21.2, 2, -20), 22)
	kit:Platform(CFrame.new(0, 13, -16.6), Vector3.new(10, 0.6, 2.4))
	kit:Truss(Vector3.new(6.2, 2, -16.6), 11)

	------------------------------------------------------------------
	-- Environment: a grand estate
	------------------------------------------------------------------
	local env = kit.Environment
	local rng = Random.new(505)
	local paving = Color3.fromRGB(222, 212, 196)
	local roundabout = Vector3.new(0, 0, -105)

	kit:Decor({ Name = "Driveway", Size = Vector3.new(14, 0.12, 140), CFrame = CFrame.new(0, 0.06, -132), Color = paving, Material = Enum.Material.Pavement })
	local disc, discCF = BuildKit.VerticalCylinder(roundabout + Vector3.new(0, 0.08, 0), 0.14, 46)
	kit:Decor({ Name = "Roundabout", Size = disc, CFrame = discCF, Shape = Enum.PartType.Cylinder, Color = paving, Material = Enum.Material.Pavement })

	-- Fountain in the roundabout
	local basin, basinCF = BuildKit.VerticalCylinder(roundabout + Vector3.new(0, 0.9, 0), 1.8, 22)
	kit:Decor({ Name = "FountainBasin", Size = basin, CFrame = basinCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(236, 232, 224), Material = Enum.Material.Marble })
	local water, waterCF = BuildKit.VerticalCylinder(roundabout + Vector3.new(0, 1.75, 0), 0.2, 20)
	kit:Decor({ Name = "FountainWater", Size = water, CFrame = waterCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(90, 180, 230), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false })
	local column, columnCF = BuildKit.VerticalCylinder(roundabout + Vector3.new(0, 4, 0), 6, 2)
	kit:Decor({ Name = "FountainColumn", Size = column, CFrame = columnCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(236, 232, 224), Material = Enum.Material.Marble })
	local bowl, bowlCF = BuildKit.VerticalCylinder(roundabout + Vector3.new(0, 7.2, 0), 0.8, 8)
	local bowlPart = kit:Decor({ Name = "FountainBowl", Size = bowl, CFrame = bowlCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(236, 232, 224), Material = Enum.Material.Marble })
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0.6, 0, 0)
	attachment.Parent = bowlPart
	local spray = Instance.new("ParticleEmitter")
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	spray.LightEmission = 0.3
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.1) })
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	spray.Lifetime = NumberRange.new(1, 1.4)
	spray.Rate = 30
	spray.Speed = NumberRange.new(8, 11)
	spray.SpreadAngle = Vector2.new(20, 20)
	spray.Acceleration = Vector3.new(0, -26, 0)
	spray.EmissionDirection = Enum.NormalId.Right
	spray.Parent = attachment

	-- Lamps and cypress trees along the driveway
	for z = -70, -195, -20 do
		if math.abs(z - roundabout.Z) > 26 then
			for _, x in ipairs({ -10, 10 }) do
				Decor.Lamp(env, Vector3.new(x, 0, z), 10)
				Decor.Tree(env, Vector3.new(x * 1.9, 0, z - 10), 0.9, "Pine", rng)
			end
		end
	end

	-- Formal gardens with hedge squares, flower beds and topiaries
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -95, -150 }) do
			local center = Vector3.new(side * 48, 0, z)
			for _, def in ipairs({ { 0, -15, 30, 0 }, { 0, 15, 30, 0 }, { -15, 0, 0, 30 }, { 15, 0, 0, 30 } }) do
				local hedgeSize = if def[3] > 0 then Vector3.new(def[3], 2.6, 2) else Vector3.new(2, 2.6, def[4])
				Decor.Hedge(env, CFrame.new(center + Vector3.new(def[1], 0, def[2])), hedgeSize)
			end
			Decor.FlowerBed(env, center, 8, rng)
			for _, corner in ipairs({ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }) do
				Decor.Topiary(env, center + corner * 18)
			end
		end
	end

	-- Entrance gate and boundary hedge
	local gateZ = -205
	for _, x in ipairs({ -12, 12 }) do
		kit:Decor({ Name = "GatePillar", Size = Vector3.new(6, 14, 6), CFrame = CFrame.new(x, 7, gateZ), Color = Color3.fromRGB(226, 220, 208), Material = Enum.Material.Limestone })
		kit:Decor({ Name = "PillarCap", Size = Vector3.new(7, 1, 7), CFrame = CFrame.new(x, 14.5, gateZ), Color = Color3.fromRGB(200, 192, 180), Material = Enum.Material.Limestone })
		local lantern = kit:Decor({ Name = "Lantern", Size = Vector3.new(2, 2.6, 2), CFrame = CFrame.new(x, 16.3, gateZ), Color = Color3.fromRGB(255, 220, 150), Material = Enum.Material.Neon, CanCollide = false })
		local glow = Instance.new("PointLight")
		glow.Shadows = false
		glow:SetAttribute("Night", true)
		glow.Range = 20
		glow.Brightness = 1.5
		glow.Color = Color3.fromRGB(255, 210, 150)
		glow.Parent = lantern
		for b = 0, 3 do
			kit:Decor({ Name = "GateBar", Size = Vector3.new(0.4, 10, 0.4), CFrame = CFrame.new(x * 0.55 + (if x > 0 then b else -b) * 1.4, 5, gateZ - 6 - b * 0.3) * CFrame.Angles(0, if x > 0 then math.rad(-60) else math.rad(60), 0), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Metal })
		end
		Decor.Hedge(env, CFrame.new(x / math.abs(x) * 75, 0, gateZ), Vector3.new(118, 7, 4))
	end

	-- Back garden: hedge walk to a gazebo ringed with roses, and a tennis court
	for _, x in ipairs({ -7, 7 }) do
		Decor.Hedge(env, CFrame.new(x, 0, 92), Vector3.new(2.4, 3, 26))
	end
	kit:Decor({ Name = "GardenWalk", Size = Vector3.new(10, 0.12, 30), CFrame = CFrame.new(0, 0.06, 92), Color = Color3.fromRGB(226, 214, 190), Material = Enum.Material.Pavement })
	Decor.Gazebo(env, Vector3.new(0, 0, 118), 8)
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2 + math.pi / 6
		Decor.FlowerBed(env, Vector3.new(math.cos(angle) * 17, 0, 118 + math.sin(angle) * 17), 3.5, rng)
	end
	Decor.TennisCourt(env, CFrame.new(78, 0, 112))
	Decor.Bench(env, CFrame.lookAt(Vector3.new(60, 0.1, 112), Vector3.new(78, 0.1, 112)))
	for i = 0, 3 do
		Decor.Tree(env, Vector3.new(-70 + i * 16, 0, 104 + (i % 2) * 14), 1.1, "Blossom", rng)
	end

	Decor.Backdrop(env, Vector3.new(0, 0, -20), 225, rng)
	Decor.AmbientMotes(env, Vector3.new(0, 0, -30), 90, "Petals")

	kit:SetSpawn(Vector3.new(0, 3, -48), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 18, 0), Vector3.new(104, 36, 40))
	return kit:Finish()
end
