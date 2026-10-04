--[[
	Car - Level 2
	A huge sports car: body, wheels, glass, hood, roof, bumpers and doors.
]]

local BuildKit = require(script.Parent.BuildKit)
local Decor = require(script.Parent.Parent.Systems.Decor)

local PAINT = Color3.fromRGB(230, 40, 52)
local PAINT_DARK = Color3.fromRGB(170, 24, 36)
local GLASS = Color3.fromRGB(60, 90, 130)
local TIRE = Color3.fromRGB(32, 32, 36)
local RIM = Color3.fromRGB(200, 204, 214)

return function(): Model
	local kit = BuildKit.new("Car")

	-- Showroom floor
	kit:Part({ Name = "Floor", Size = Vector3.new(44, 0.4, 60), CFrame = CFrame.new(0, 0.2, 0), Color = Color3.fromRGB(60, 62, 70), Material = Enum.Material.SmoothPlastic, Reflectance = 0.1 })

	-- Main body
	kit:Surface({ Name = "Body", Size = Vector3.new(15, 3.6, 34), CFrame = CFrame.new(0, 3.4, 0), Color = PAINT, Material = Enum.Material.SmoothPlastic, Reflectance = 0.08 }, "Body")
	-- Side skirts
	for _, x in ipairs({ -7.7, 7.7 }) do
		kit:Surface({ Name = "Skirt", Size = Vector3.new(0.6, 1.2, 20), CFrame = CFrame.new(x, 2, 0), Color = PAINT_DARK }, "Body", { Faces = if x > 0 then "Right,Top" else "Left,Top" })
	end

	-- Hood (slopes down toward the front)
	kit:Surface({ Name = "Hood", Class = "WedgePart", Size = Vector3.new(15, 1.6, 10), CFrame = CFrame.new(0, 6, -11.5), Color = PAINT, Reflectance = 0.08 }, "Hood", { Faces = "Slope" })
	kit:Surface({ Name = "HoodTop", Size = Vector3.new(15, 1.6, 6), CFrame = CFrame.new(0, 6, -3.5), Color = PAINT, Reflectance = 0.08 }, "Hood", { Faces = "Top" })

	-- Belt line under the cabin
	kit:Surface({ Name = "Beltline", Size = Vector3.new(15, 1.6, 9.5), CFrame = CFrame.new(0, 6, 4.25), Color = PAINT, Reflectance = 0.08 }, "Body", { Faces = "Left,Right" })

	-- Trunk
	kit:Surface({ Name = "Trunk", Size = Vector3.new(15, 1.6, 8), CFrame = CFrame.new(0, 6, 13), Color = PAINT, Reflectance = 0.08 }, "Body", { Faces = "Top,Back" })

	-- Cabin: windshield, side glass, rear glass, roof
	kit:Surface({ Name = "Windshield", Class = "WedgePart", Size = Vector3.new(13, 3.6, 5.5), CFrame = CFrame.new(0, 8.6, -2.75), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.15 }, "Glass", { Faces = "Slope" })
	kit:Surface({ Name = "CabinGlass", Size = Vector3.new(13, 3.6, 9), CFrame = CFrame.new(0, 8.6, 4.5), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.15 }, "Glass", { Faces = "Left,Right" })
	kit:Surface({ Name = "RearGlass", Class = "WedgePart", Size = Vector3.new(13, 3.6, 4), CFrame = CFrame.new(0, 8.6, 11) * CFrame.Angles(0, math.pi, 0), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.15 }, "Glass", { Faces = "Slope" })
	kit:Surface({ Name = "Roof", Size = Vector3.new(13.2, 0.7, 9.4), CFrame = CFrame.new(0, 10.75, 4.5), Color = PAINT, Reflectance = 0.08 }, "Roof", { Faces = "Top,Front,Back" })
	-- Window pillars
	for _, x in ipairs({ -6.55, 6.55 }) do
		kit:Part({ Name = "Pillar", Size = Vector3.new(0.3, 3.6, 0.5), CFrame = CFrame.new(x, 8.6, 0.1), Color = PAINT_DARK })
	end

	-- Doors
	for _, x in ipairs({ -7.65, 7.65 }) do
		kit:Surface({ Name = "Door", Size = Vector3.new(0.3, 3.4, 9), CFrame = CFrame.new(x, 3.6, 3), Color = PAINT, Reflectance = 0.08 }, "Doors", { Faces = if x > 0 then "Right" else "Left" })
		kit:Part({ Name = "Handle", Size = Vector3.new(0.3, 0.3, 1.2), CFrame = CFrame.new(x + (if x > 0 then 0.2 else -0.2), 4.6, 5.5), Color = RIM, Material = Enum.Material.Metal })
	end

	-- Bumpers
	kit:Surface({ Name = "FrontBumper", Size = Vector3.new(15.6, 1.6, 1.4), CFrame = CFrame.new(0, 2.2, -17.6), Color = PAINT_DARK }, "Bumpers")
	kit:Surface({ Name = "RearBumper", Size = Vector3.new(15.6, 1.6, 1.4), CFrame = CFrame.new(0, 2.2, 17.6), Color = PAINT_DARK }, "Bumpers")

	-- Lights
	for _, x in ipairs({ -5.5, 5.5 }) do
		kit:Part({ Name = "Headlight", Size = Vector3.new(3, 0.8, 0.3), CFrame = CFrame.new(x, 4.4, -17.05), Color = Color3.fromRGB(255, 250, 220), Material = Enum.Material.Neon })
		kit:Part({ Name = "Taillight", Size = Vector3.new(3.4, 0.7, 0.3), CFrame = CFrame.new(x, 4.6, 17.05), Color = Color3.fromRGB(255, 30, 30), Material = Enum.Material.Neon })
	end
	kit:Part({ Name = "Grille", Size = Vector3.new(6, 1, 0.3), CFrame = CFrame.new(0, 3.2, -17.05), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.DiamondPlate })

	-- Spoiler
	kit:Surface({ Name = "Spoiler", Size = Vector3.new(14, 0.4, 2.4), CFrame = CFrame.new(0, 9, 15.6), Color = Color3.fromRGB(30, 30, 34) }, "Body", { Faces = "Top,Back,Front" })
	for _, x in ipairs({ -4.5, 4.5 }) do
		kit:Part({ Name = "SpoilerStand", Size = Vector3.new(0.4, 2.2, 0.8), CFrame = CFrame.new(x, 7.9, 15.6), Color = Color3.fromRGB(30, 30, 34) })
	end

	-- Wheels (tire + rim)
	for _, x in ipairs({ -7.6, 7.6 }) do
		for _, z in ipairs({ -11, 11 }) do
			kit:Surface({ Name = "Tire", Size = Vector3.new(2.4, 6.2, 6.2), CFrame = CFrame.new(x, 3.1, z), Shape = Enum.PartType.Cylinder, Color = TIRE, Material = Enum.Material.Rubber }, "Wheels", { Faces = "Side", StickerWeight = 0.8 })
			local rimX = x + (if x > 0 then 0.1 else -0.1)
			kit:Surface({ Name = "Rim", Size = Vector3.new(2.4, 3.8, 3.8), CFrame = CFrame.new(rimX, 3.1, z), Shape = Enum.PartType.Cylinder, Color = RIM, Material = Enum.Material.Metal, Reflectance = 0.2 }, "Wheels", { Faces = "Ends" })
		end
	end

	-- Mirrors
	for _, x in ipairs({ -7.4, 7.4 }) do
		kit:Surface({ Name = "Mirror", Size = Vector3.new(1.2, 0.9, 0.8), CFrame = CFrame.new(x, 7.6, -1.6), Color = PAINT }, "Doors")
	end

	------------------------------------------------------------------
	-- Environment: evening car show
	------------------------------------------------------------------
	local env = kit.Environment
	local S = kit.Scale
	local rng = Random.new(202)
	local halfX, halfZ = 22 * S, 30 * S

	-- Asphalt lot with parking bays
	kit:Decor({ Name = "Lot", Size = Vector3.new(240, 0.1, 240), CFrame = CFrame.new(0, 0.05, 0), Color = Color3.fromRGB(46, 48, 54), Material = Enum.Material.Asphalt })
	for _, side in ipairs({ -1, 1 }) do
		for i = -5, 5 do
			kit:Decor({ Name = "BayLine", Size = Vector3.new(14, 0.12, 0.4), CFrame = CFrame.new(side * (halfX + 34), 0.11, i * 11), Color = Color3.fromRGB(235, 235, 235), CanCollide = false, CastShadow = false })
		end
		for i = -5, 4 do
			if rng:NextNumber() < 0.7 then
				local colors = { Color3.fromRGB(240, 240, 245), Color3.fromRGB(30, 30, 36), Color3.fromRGB(60, 120, 220), Color3.fromRGB(240, 190, 40), Color3.fromRGB(120, 200, 140), Color3.fromRGB(180, 60, 200) }
				Decor.Car(env, CFrame.new(side * (halfX + 34), 0, (i + 0.5) * 11) * CFrame.Angles(0, math.rad(90 * side), 0), colors[rng:NextInteger(1, #colors)])
			end
		end
	end

	-- Glowing stage outline around the show floor
	local neon = Color3.fromRGB(90, 220, 255)
	for _, def in ipairs({
		{ Vector3.new(halfX * 2 + 1, 0.2, 0.5), Vector3.new(0, 0.5, -halfZ - 0.25) },
		{ Vector3.new(halfX * 2 + 1, 0.2, 0.5), Vector3.new(0, 0.5, halfZ + 0.25) },
		{ Vector3.new(0.5, 0.2, halfZ * 2 + 1), Vector3.new(-halfX - 0.25, 0.5, 0) },
		{ Vector3.new(0.5, 0.2, halfZ * 2 + 1), Vector3.new(halfX + 0.25, 0.5, 0) },
	}) do
		kit:Decor({ Name = "NeonEdge", Size = def[1], CFrame = CFrame.new(def[2]), Color = neon, Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	end

	-- Showroom with a neon sign
	local showroom = CFrame.lookAt(Vector3.new(0, 0, halfZ + 46), Vector3.new(0, 0, 0))
	Decor.Building(env, showroom, Vector3.new(90, 21, 28), Color3.fromRGB(58, 60, 70), {
		Floors = 2,
		WindowColor = Color3.fromRGB(120, 210, 255),
		TrimColor = Color3.fromRGB(34, 34, 40),
		Door = false,
	})
	Decor.NeonSign(env, showroom * CFrame.new(0, 24.5, -14.4), "STICKER MOTORS", Color3.fromRGB(255, 90, 170), 34)

	-- Spotlights aimed at the car
	for _, corner in ipairs({ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }) do
		Decor.Spotlight(env, Vector3.new(corner.X * (halfX + 10), 0, corner.Z * (halfZ + 8)), Vector3.new(0, 6 * S, 0))
	end

	-- Flags and string lights at the entrance
	local flagColors = { Color3.fromRGB(255, 80, 120), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 210, 70) }
	local tops = {}
	for i = -3, 3 do
		local position = Vector3.new(i * 12, 0, -halfZ - 22)
		Decor.FlagPole(env, position, 14, flagColors[(i + 4) % 3 + 1])
		table.insert(tops, position + Vector3.new(0, 13.5, 0))
	end
	for i = 1, #tops - 1 do
		Decor.StringLights(env, tops[i], tops[i + 1], 7, 1.8)
	end

	-- Cones and tire stacks
	for i = -2, 2 do
		Decor.Cone(env, Vector3.new(i * 7, 0, -halfZ - 10))
	end
	Decor.TireStack(env, Vector3.new(halfX + 12, 0, halfZ + 20), 4)
	Decor.TireStack(env, Vector3.new(halfX + 16, 0, halfZ + 18), 3)
	Decor.TireStack(env, Vector3.new(-halfX - 12, 0, halfZ + 20), 3)
	for i = 0, 3 do
		Decor.Lamp(env, Vector3.new(-60 + i * 40, 0, -halfZ - 40), 12, Color3.fromRGB(200, 230, 255))
	end

	-- Velvet ropes around the show floor (open at the front so everyone can walk in)
	local ropeX, ropeZ = halfX + 4, halfZ + 4
	local function ropeLine(from: Vector3, to: Vector3, count: number)
		local points = {}
		for i = 0, count do
			table.insert(points, from:Lerp(to, i / count))
		end
		Decor.Stanchions(env, points)
	end
	ropeLine(Vector3.new(-ropeX, 0, ropeZ), Vector3.new(ropeX, 0, ropeZ), 8)
	ropeLine(Vector3.new(-ropeX, 0, -ropeZ + 14), Vector3.new(-ropeX, 0, ropeZ), 9)
	ropeLine(Vector3.new(ropeX, 0, -ropeZ + 14), Vector3.new(ropeX, 0, ropeZ), 9)

	-- Curb, grass strip and trees around the lot, with tall lot lights
	for _, def in ipairs({
		{ Vector3.new(240, 0.5, 1.2), Vector3.new(0, 0.25, -120) },
		{ Vector3.new(240, 0.5, 1.2), Vector3.new(0, 0.25, 120) },
		{ Vector3.new(1.2, 0.5, 240), Vector3.new(-120, 0.25, 0) },
		{ Vector3.new(1.2, 0.5, 240), Vector3.new(120, 0.25, 0) },
	}) do
		kit:Decor({ Name = "Curb", Size = def[1], CFrame = CFrame.new(def[2]), Color = Color3.fromRGB(196, 196, 200), Material = Enum.Material.Concrete })
	end
	for i = -3, 3 do
		for _, position in ipairs({ Vector3.new(i * 34, 0, -128), Vector3.new(-128, 0, i * 34), Vector3.new(128, 0, i * 34) }) do
			Decor.Tree(env, position, rng:NextNumber(0.9, 1.15), if rng:NextNumber() < 0.5 then "Round" else "Pine", rng)
		end
	end
	for _, position in ipairs({
		Vector3.new(-112, 0, -112), Vector3.new(112, 0, -112), Vector3.new(-112, 0, 112), Vector3.new(112, 0, 112),
		Vector3.new(-112, 0, 0), Vector3.new(112, 0, 0), Vector3.new(0, 0, -112),
	}) do
		Decor.Lamp(env, position, 16, Color3.fromRGB(190, 220, 255))
	end

	-- Food truck corner with tables and string lights
	local truck = CFrame.lookAt(Vector3.new(-88, 0, -62), Vector3.new(-88, 0, -40))
	Decor.FoodTruck(env, truck, Color3.fromRGB(255, 196, 70))
	local cafeColors = { Color3.fromRGB(240, 90, 110), Color3.fromRGB(90, 190, 255), Color3.fromRGB(120, 220, 140), Color3.fromRGB(240, 90, 110) }
	for i, offset in ipairs({ Vector3.new(-96, 0, -44), Vector3.new(-84, 0, -42), Vector3.new(-90, 0, -32), Vector3.new(-78, 0, -30) }) do
		Decor.CafeTable(env, offset + Vector3.new(0, 0.1, 0), cafeColors[i])
	end
	local poleA = Decor.Lamp(env, Vector3.new(-102, 0, -28), 10)
	local poleB = Decor.Lamp(env, Vector3.new(-72, 0, -50), 10)
	Decor.StringLights(env, poleA, poleB, 12, 2.2)
	Decor.StringLights(env, poleA, Vector3.new(-96, 9.5, -58), 8, 1.5)

	-- Tuning workshop with an open roller door
	local workshop = CFrame.lookAt(Vector3.new(92, 0, -70), Vector3.new(60, 0, -70))
	Decor.Building(env, workshop, Vector3.new(34, 14, 26), Color3.fromRGB(70, 74, 86), {
		Roof = "Flat",
		WindowColor = Color3.fromRGB(255, 200, 120),
		TrimColor = Color3.fromRGB(240, 170, 40),
		Door = false,
	})
	kit:Decor({ Name = "RollerDoor", Size = Vector3.new(14, 9, 0.4), CFrame = workshop * CFrame.new(0, 4.5, -13.2), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.DiamondPlate })
	Decor.NeonSign(env, workshop * CFrame.new(0, 16.5, -13.4), "TUNING", Color3.fromRGB(255, 180, 40), 14)
	Decor.TireStack(env, Vector3.new(70, 0, -84), 4)
	Decor.TireStack(env, Vector3.new(70, 0, -56), 2)
	Decor.Car(env, workshop * CFrame.new(0, 0, -22) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 120, 40))

	-- Balloons by the entrance flags
	Decor.Balloons(env, Vector3.new(-40, 0.5, -halfZ - 22), 6, rng)
	Decor.Balloons(env, Vector3.new(40, 0.5, -halfZ - 22), 6, rng)

	Decor.Backdrop(env, Vector3.zero, 230, rng, "Pine")
	Decor.AmbientMotes(env, Vector3.zero, 80, "Fireflies")

	kit:SetSpawn(Vector3.new(16, 3, -26), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 6, 0), Vector3.new(18, 12, 38))
	return kit:Finish()
end
