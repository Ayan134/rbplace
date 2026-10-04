--[[
	Mansion - Level 5
	A huge mansion: main hall with columned portico, two wings, roofs, many windows,
	front stairs and a pool.
]]

local BuildKit = require(script.Parent.BuildKit)

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
		kit:Surface({ Name = "Column", Size = size, CFrame = cf, Color = WALL, Material = Enum.Material.Marble }, "Columns", { Faces = "Side" })
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
		kit:Part({ Name = "UmbrellaTop", Size = size, CFrame = cf, Color = Color3.fromRGB(255, 120, 90), Material = Enum.Material.Fabric, CanCollide = false })
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

	kit:SetSpawn(Vector3.new(0, 3, -48), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 18, 0), Vector3.new(104, 36, 40))
	return kit:Finish()
end
