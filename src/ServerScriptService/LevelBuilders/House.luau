--[[
	House - Level 4
	A cozy house: walls, windows, doors, roof, garage, balcony and fence.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)

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

	------------------------------------------------------------------
	-- Environment: a sunny suburban street
	------------------------------------------------------------------
	local env = kit.Environment
	local S = kit.Scale
	local rng = Random.new(404)
	local roadZ = -66

	Decor.Road(env, CFrame.new(0, 0, roadZ) * CFrame.Angles(0, math.pi / 2, 0), 400, 16)
	-- Driveway connection to the street
	kit:Decor({ Name = "DrivewayLink", Size = Vector3.new(16 * S, 0.12, 6), CFrame = CFrame.new(29 * S, 0.3, -55), Color = Color3.fromRGB(120, 120, 126), Material = Enum.Material.Asphalt })
	Decor.Car(env, CFrame.new(29 * S, 0.3, -38) * CFrame.Angles(0, 0, 0), Color3.fromRGB(70, 130, 220))

	for x = -160, 160, 40 do
		Decor.Lamp(env, Vector3.new(x, 0.5, roadZ + 11), 10)
	end

	-- Neighbour houses
	local neighbours = {
		{ Vector3.new(-125, 0, -10), Color3.fromRGB(196, 222, 240), Color3.fromRGB(80, 100, 150) },
		{ Vector3.new(140, 0, -12), Color3.fromRGB(244, 230, 190), Color3.fromRGB(150, 90, 60) },
		{ Vector3.new(-60, 0, -128), Color3.fromRGB(214, 236, 206), Color3.fromRGB(70, 120, 80) },
		{ Vector3.new(40, 0, -128), Color3.fromRGB(240, 210, 220), Color3.fromRGB(170, 70, 90) },
		{ Vector3.new(130, 0, -128), Color3.fromRGB(250, 240, 230), Color3.fromRGB(90, 90, 100) },
	}
	for _, def in ipairs(neighbours) do
		local position = def[1]
		local cf = CFrame.lookAt(position, Vector3.new(position.X, 0, roadZ))
		Decor.Building(env, cf, Vector3.new(34, 13, 26), def[2], { Roof = "Gable", RoofColor = def[3], Floors = 1, DoorColor = def[3] })
		Decor.Tree(env, (cf * CFrame.new(-22, 0, -12)).Position, 1.1, if rng:NextNumber() < 0.5 then "Round" else "Autumn", rng)
		Decor.Bush(env, (cf * CFrame.new(10, 0, -16)).Position, 3.5)
		Decor.Bush(env, (cf * CFrame.new(-8, 0, -16)).Position, 3.5)
		local post, postCF = BuildKit.VerticalCylinder((cf * CFrame.new(14, 0, -22)).Position + Vector3.new(0, 1.7, 0), 3.4, 0.4)
		kit:Decor({ Name = "MailboxPost", Size = post, CFrame = postCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(120, 86, 60), Material = Enum.Material.Wood })
		kit:Decor({ Name = "Mailbox", Size = Vector3.new(1.4, 1.2, 2.2), CFrame = cf * CFrame.new(14, 3.8, -22), Color = def[3], Material = Enum.Material.Metal })
	end

	-- Backyard: trampoline, doghouse, garden
	local yard = Vector3.new(-28, 0, 35)
	local tramp, trampCF = BuildKit.VerticalCylinder(yard + Vector3.new(0, 2.4, 0), 0.4, 14)
	kit:Decor({ Name = "TrampolineRing", Size = tramp, CFrame = trampCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(60, 150, 230) })
	local mat, matCF = BuildKit.VerticalCylinder(yard + Vector3.new(0, 2.5, 0), 0.4, 12)
	kit:Decor({ Name = "TrampolineMat", Size = mat, CFrame = matCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(30, 30, 36), Material = Enum.Material.Fabric })
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		kit:Decor({ Name = "TrampolineLeg", Size = Vector3.new(0.4, 2.4, 0.4), CFrame = CFrame.new(yard + Vector3.new(math.cos(angle) * 6.6, 1.2, math.sin(angle) * 6.6)), Color = Color3.fromRGB(80, 80, 90), Material = Enum.Material.Metal })
	end
	local dog = Vector3.new(42, 0, 36)
	kit:Decor({ Name = "Doghouse", Size = Vector3.new(5, 4, 6), CFrame = CFrame.new(dog + Vector3.new(0, 2, 0)), Color = Color3.fromRGB(200, 70, 60), Material = Enum.Material.WoodPlanks })
	kit:Decor({ Name = "DoghouseRoof", Class = "WedgePart", Size = Vector3.new(6, 2.4, 3.4), CFrame = CFrame.new(dog + Vector3.new(0, 5.2, -1.7)), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.WoodPlanks })
	kit:Decor({ Name = "DoghouseRoof", Class = "WedgePart", Size = Vector3.new(6, 2.4, 3.4), CFrame = CFrame.new(dog + Vector3.new(0, 5.2, 1.7)) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.WoodPlanks })
	kit:Decor({ Name = "DoghouseDoor", Size = Vector3.new(2, 2.4, 0.2), CFrame = CFrame.new(dog + Vector3.new(0, 1.2, -3.05)), Color = Color3.fromRGB(30, 24, 20) })
	for i = 0, 3 do
		Decor.FlowerBed(env, Vector3.new(-50 + i * 14, 0, 54), 4, rng)
	end
	for i = 0, 5 do
		Decor.Tree(env, Vector3.new(-70 + i * 28, 0, 85 + rng:NextNumber(-6, 6)), rng:NextNumber(1.1, 1.5), "Round", rng)
	end

	-- Street life: a lemonade stand, cars parked across the street, balloons
	Decor.Stall(env, CFrame.lookAt(Vector3.new(-30, 0.3, -53), Vector3.new(-30, 0.3, roadZ)), Color3.fromRGB(255, 205, 60), "LEMONADE 🍋")
	Decor.Balloons(env, Vector3.new(-26, 3.6, -53), 4, rng)
	for _, x in ipairs({ -110, -20, 85 }) do
		local colors = { Color3.fromRGB(230, 70, 70), Color3.fromRGB(240, 240, 245), Color3.fromRGB(90, 190, 140) }
		Decor.Car(env, CFrame.new(x, 0.2, roadZ - 4.5) * CFrame.Angles(0, math.rad(90), 0), colors[rng:NextInteger(1, #colors)])
	end
	-- Backyard grill and picnic table
	kit:Decor({ Name = "PicnicTable", Size = Vector3.new(8, 0.5, 3.4), CFrame = CFrame.new(8, 2.6, 36), Color = Color3.fromRGB(176, 120, 72), Material = Enum.Material.WoodPlanks })
	for _, z in ipairs({ 33.4, 38.6 }) do
		kit:Decor({ Name = "PicnicBench", Size = Vector3.new(8, 0.4, 1.2), CFrame = CFrame.new(8, 1.5, z), Color = Color3.fromRGB(160, 108, 64), Material = Enum.Material.WoodPlanks })
	end
	for _, x in ipairs({ 5, 11 }) do
		kit:Decor({ Name = "PicnicLeg", Size = Vector3.new(0.5, 2.4, 6.4), CFrame = CFrame.new(x, 1.2, 36), Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.Wood })
	end
	local grill, grillCF = BuildKit.VerticalCylinder(Vector3.new(22, 3, 37), 1.6, 2.6)
	kit:Decor({ Name = "Grill", Size = grill, CFrame = grillCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Metal })
	kit:Decor({ Name = "GrillLegs", Size = Vector3.new(0.3, 2.2, 0.3), CFrame = CFrame.new(22, 1.1, 37), Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.Metal })

	Decor.Backdrop(env, Vector3.zero, 235, rng)
	Decor.AmbientMotes(env, Vector3.zero, 80, "Sunlight")

	kit:SetSpawn(Vector3.new(0, 3, -40), Vector3.zero)
	kit:SetFinish(Vector3.new(5, 12, 0), Vector3.new(64, 26, 40))
	return kit:Finish()
end
