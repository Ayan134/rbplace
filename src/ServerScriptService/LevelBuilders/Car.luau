--[[
	Car - Level 2
	A huge sports car: body, wheels, glass, hood, roof, bumpers and doors.
]]

local BuildKit = require(script.Parent.BuildKit)

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

	kit:SetSpawn(Vector3.new(16, 3, -26), Vector3.zero)
	kit:SetFinish(Vector3.new(0, 6, 0), Vector3.new(18, 12, 38))
	return kit:Finish()
end
