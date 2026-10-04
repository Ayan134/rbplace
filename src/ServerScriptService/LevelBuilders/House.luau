--[[
	House - Level 4
	A cozy house: walls, windows, doors, roof, garage, balcony and fence.
]]

local BuildKit = require(script.Parent.BuildKit)

local WALL = Color3.fromRGB(246, 226, 196)
local TRIM = Color3.fromRGB(255, 255, 255)
local ROOF = Color3.fromRGB(176, 72, 60)
local GLASS = Color3.fromRGB(150, 200, 235)
local WOOD = Color3.fromRGB(140, 92, 56)
local FENCE = Color3.fromRGB(250, 250, 245)

return function(): Model
	local kit = BuildKit.new("House")

	-- Lawn & path
	kit:Part({ Name = "Lawn", Size = Vector3.new(96, 0.4, 76), CFrame = CFrame.new(5, 0.2, 0), Color = Color3.fromRGB(110, 180, 80), Material = Enum.Material.Grass })
	kit:Part({ Name = "Path", Size = Vector3.new(6, 0.5, 18), CFrame = CFrame.new(0, 0.25, -24), Color = Color3.fromRGB(190, 180, 170), Material = Enum.Material.Pavement })
	kit:Part({ Name = "Driveway", Size = Vector3.new(16, 0.5, 18), CFrame = CFrame.new(29, 0.25, -24), Color = Color3.fromRGB(120, 120, 126), Material = Enum.Material.Asphalt })

	-- Foundation and main walls (one solid core: interior is never visible)
	kit:Part({ Name = "Foundation", Size = Vector3.new(41, 1, 31), CFrame = CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(150, 150, 150), Material = Enum.Material.Concrete })
	kit:Surface({ Name = "Walls", Size = Vector3.new(40, 14, 30), CFrame = CFrame.new(0, 8, 0), Color = WALL, Material = Enum.Material.Plaster }, "Walls", { Faces = "Front,Back,Left,Right" })

	-- Gable roof (two wedges) + gable ends
	kit:Surface({ Name = "RoofFront", Class = "WedgePart", Size = Vector3.new(43, 9, 16.5), CFrame = CFrame.new(0, 19.5, -8.25), Color = ROOF, Material = Enum.Material.Slate }, "Roof", { Faces = "Slope" })
	kit:Surface({ Name = "RoofBack", Class = "WedgePart", Size = Vector3.new(43, 9, 16.5), CFrame = CFrame.new(0, 19.5, 8.25) * CFrame.Angles(0, math.pi, 0), Color = ROOF, Material = Enum.Material.Slate }, "Roof", { Faces = "Slope" })
	for _, x in ipairs({ -20, 20 }) do
		for _, sign in ipairs({ -1, 1 }) do
			kit:Surface({
				Name = "Gable",
				Class = "WedgePart",
				Size = Vector3.new(0.6, 8.8, 15),
				CFrame = CFrame.new(x, 19.4, sign * 7.5) * CFrame.Angles(0, if sign > 0 then math.pi else 0, 0),
				Color = WALL,
				Material = Enum.Material.Plaster,
			}, "Walls", { Faces = "Sides" })
		end
	end
	-- Chimney
	kit:Surface({ Name = "Chimney", Size = Vector3.new(3, 8, 3), CFrame = CFrame.new(-12, 23, 4), Color = Color3.fromRGB(150, 70, 60), Material = Enum.Material.Brick }, "Roof")

	-- Front door
	kit:Surface({ Name = "FrontDoor", Size = Vector3.new(5.6, 9, 0.4), CFrame = CFrame.new(0, 5.5, -15.2), Color = Color3.fromRGB(70, 110, 170), Material = Enum.Material.Wood }, "Doors", { Faces = "Front" })
	kit:Part({ Name = "DoorFrame", Size = Vector3.new(6.6, 9.8, 0.3), CFrame = CFrame.new(0, 5.9, -15.05), Color = TRIM })
	kit:Part({ Name = "Knob", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(2, 5.2, -15.5), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(230, 190, 70), Material = Enum.Material.Metal })
	kit:Surface({ Name = "Porch", Size = Vector3.new(12, 0.8, 5), CFrame = CFrame.new(0, 1.4, -17.5), Color = Color3.fromRGB(180, 170, 160), Material = Enum.Material.Concrete }, "Doors", { Faces = "Top,Front" })

	-- Windows (front, back, sides)
	local function window(cframe: CFrame, width: number, height: number)
		kit:Part({ Name = "WindowFrame", Size = Vector3.new(width + 0.8, height + 0.8, 0.25), CFrame = cframe * CFrame.new(0, 0, 0.08), Color = TRIM })
		kit:Surface({ Name = "Window", Size = Vector3.new(width, height, 0.3), CFrame = cframe * CFrame.new(0, 0, -0.05), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.1 }, "Windows", { Faces = "Front" })
	end
	for _, x in ipairs({ -12, 12 }) do
		window(CFrame.new(x, 6.5, -15.15), 7, 5)
		window(CFrame.new(x, 6.5, 15.15) * CFrame.Angles(0, math.pi, 0), 7, 5)
	end
	window(CFrame.new(0, 12.4, 15.15) * CFrame.Angles(0, math.pi, 0), 6, 3.4)
	for _, z in ipairs({ -7, 7 }) do
		window(CFrame.new(-20.15, 7, z) * CFrame.Angles(0, math.rad(90), 0), 6, 5)
	end

	-- Garage
	kit:Surface({ Name = "Garage", Size = Vector3.new(18, 11, 20), CFrame = CFrame.new(29, 6.5, -5), Color = WALL, Material = Enum.Material.Plaster }, "Garage", { Faces = "Top,Front,Back,Right" })
	kit:Surface({ Name = "GarageDoor", Size = Vector3.new(14, 8.5, 0.4), CFrame = CFrame.new(29, 5.25, -15.2), Color = Color3.fromRGB(235, 235, 240), Material = Enum.Material.CorrodedMetal }, "Garage", { Faces = "Front" })
	for i = 1, 4 do
		kit:Part({ Name = "GarageLine", Size = Vector3.new(14, 0.15, 0.1), CFrame = CFrame.new(29, 1 + i * 1.8, -15.45), Color = Color3.fromRGB(190, 190, 196) })
	end
	kit:Part({ Name = "GarageRoofTrim", Size = Vector3.new(19, 0.6, 21), CFrame = CFrame.new(29, 12.3, -5), Color = TRIM })

	-- Balcony on the back
	kit:Surface({ Name = "BalconyFloor", Size = Vector3.new(16, 0.8, 6), CFrame = CFrame.new(0, 10.4, 18), Color = WOOD, Material = Enum.Material.WoodPlanks }, "Balcony", { Faces = "Top,Back,Left,Right" })
	kit:Surface({ Name = "BalconyRail", Size = Vector3.new(16, 0.5, 0.5), CFrame = CFrame.new(0, 13.6, 20.75), Color = TRIM }, "Balcony", { Faces = "Top,Back" })
	-- Left side rail only: the right side is open to the stairs
	kit:Surface({ Name = "BalconySide", Size = Vector3.new(0.5, 0.5, 6), CFrame = CFrame.new(-7.75, 13.6, 18), Color = TRIM }, "Balcony", { Faces = "Top,Left,Right" })
	for i = 0, 8 do
		kit:Part({ Name = "Baluster", Size = Vector3.new(0.3, 2.8, 0.3), CFrame = CFrame.new(-7.6 + i * 1.9, 12.2, 20.75), Color = TRIM })
	end
	for _, x in ipairs({ -7.5, 7.5 }) do
		kit:Part({ Name = "BalconyPost", Size = Vector3.new(0.8, 10, 0.8), CFrame = CFrame.new(x, 5, 20.6), Color = TRIM })
	end
	kit:Part({ Name = "BalconyDoor", Size = Vector3.new(4, 6.5, 0.3), CFrame = CFrame.new(-4, 14.2, 15.15), Color = GLASS, Material = Enum.Material.Glass })

	-- Fence around the yard
	local function fenceRun(from: Vector3, to: Vector3, gapCenter: Vector3?, gapWidth: number?)
		local direction = to - from
		local length = direction.Magnitude
		local count = math.floor(length / 2.2)
		local rotation = CFrame.lookAt(Vector3.zero, direction.Unit)
		for i = 0, count do
			local position = from + direction.Unit * (i * length / math.max(count, 1))
			if gapCenter and gapWidth and (position - gapCenter).Magnitude < gapWidth / 2 then
				continue
			end
			kit:Surface({
				Name = "FenceBoard",
				Size = Vector3.new(1.6, 3.4, 0.35),
				CFrame = CFrame.new(position + Vector3.new(0, 2.1, 0)) * rotation * CFrame.Angles(0, math.rad(90), 0),
				Color = FENCE,
				Material = Enum.Material.Wood,
			}, "Fence", { Faces = "Front,Back", StickerWeight = 0.7 })
		end
		kit:Part({
			Name = "FenceRail",
			Size = Vector3.new(0.3, 0.3, length),
			CFrame = CFrame.new((from + to) / 2 + Vector3.new(0, 2.6, 0)) * rotation,
			Color = FENCE,
			CanCollide = false,
		})
	end
	fenceRun(Vector3.new(-42, 0, -36), Vector3.new(52, 0, -36), Vector3.new(14, 0, -36), 34)
	fenceRun(Vector3.new(52, 0, -36), Vector3.new(52, 0, 36))
	fenceRun(Vector3.new(52, 0, 36), Vector3.new(-42, 0, 36))
	fenceRun(Vector3.new(-42, 0, 36), Vector3.new(-42, 0, -36))

	-- Bushes & mailbox
	for _, x in ipairs({ -8, 8 }) do
		kit:Part({ Name = "Bush", Size = Vector3.new(4, 3.6, 4), CFrame = CFrame.new(x, 1.8, -18.5), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(70, 150, 60), Material = Enum.Material.Grass })
	end
	kit:Surface({ Name = "Mailbox", Size = Vector3.new(1.6, 1.4, 2.4), CFrame = CFrame.new(-6, 4, -33), Color = Color3.fromRGB(60, 110, 200), Material = Enum.Material.Metal }, "Fence")
	kit:Part({ Name = "MailboxPost", Size = Vector3.new(0.4, 3.4, 0.4), CFrame = CFrame.new(-6, 1.7, -33), Color = WOOD, Material = Enum.Material.Wood })

	-- Access: trusses up the side walls to the roof, stairs to the balcony
	kit:Truss(Vector3.new(-21.4, 1, 0), 14.5)
	kit:Truss(Vector3.new(39.2, 1, -5), 11.5)
	kit:Truss(Vector3.new(21.4, 1, 10), 14.5)
	kit:Stairs(Vector3.new(24.4, 0, 18), Vector3.new(-1, 0, 0), 10, 4, Color3.fromRGB(150, 110, 80))

	kit:SetSpawn(Vector3.new(0, 3, -40), Vector3.zero)
	kit:SetFinish(Vector3.new(5, 12, 0), Vector3.new(64, 26, 40))
	return kit:Finish()
end
