--[[
	BagModels
	Builds the 3D look of every bag from code. Used by the physical shop displays
	(server) and the shop window previews (client). Models stand on their base at the
	origin and are roughly 3 studs tall.
]]

local BagModels = {}

local function part(model: Model, props): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Name = props.Name or "Part"
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Color = props.Color
	p.Material = props.Material or Enum.Material.SmoothPlastic
	if props.Shape and p:IsA("Part") then
		p.Shape = props.Shape
	end
	p.Reflectance = props.Reflectance or 0
	p.Transparency = props.Transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Vertical cylinder centered at y
local function disc(model: Model, name: string, y: number, height: number, diameter: number, color: Color3, material: Enum.Material?, reflectance: number?)
	return part(model, {
		Name = name,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Shape = Enum.PartType.Cylinder,
		Color = color,
		Material = material,
		Reflectance = reflectance,
	})
end

-- Thin rod between two points
local function rod(model: Model, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material?)
	return part(model, {
		Name = "Rod",
		Size = Vector3.new(thickness, thickness, (b - a).Magnitude),
		CFrame = CFrame.lookAt((a + b) / 2, b),
		Color = color,
		Material = material,
	})
end

-- Semicircular handle over the top
local function handle(model: Model, y: number, radius: number, color: Color3, material: Enum.Material?)
	local segments = 7
	local previous = Vector3.new(-radius, y, 0)
	for i = 1, segments do
		local angle = math.pi - i / segments * math.pi
		local point = Vector3.new(math.cos(angle) * radius, y + math.sin(angle) * radius * 0.8, 0)
		rod(model, previous, point, 0.14, color, material)
		previous = point
	end
end

local BUILDERS = {}

function BUILDERS.Pocket(model: Model, color: Color3)
	local base = part(model, { Name = "Base", Size = Vector3.new(2.4, 2.4, 0.5), CFrame = CFrame.new(0, 1.4, 0), Color = color, Material = Enum.Material.Fabric })
	part(model, { Name = "Bottom", Size = Vector3.new(2.4, 0.5, 2.4), CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(90), 0, 0), Shape = Enum.PartType.Cylinder, Color = color, Material = Enum.Material.Fabric })
	local stitch = color:Lerp(Color3.fromRGB(255, 220, 140), 0.6)
	part(model, { Name = "Stitch", Size = Vector3.new(2.1, 0.08, 0.06), CFrame = CFrame.new(0, 2.3, -0.27), Color = stitch })
	part(model, { Name = "Stitch", Size = Vector3.new(0.08, 1.8, 0.06), CFrame = CFrame.new(-1.05, 1.45, -0.27), Color = stitch })
	part(model, { Name = "Stitch", Size = Vector3.new(0.08, 1.8, 0.06), CFrame = CFrame.new(1.05, 1.45, -0.27), Color = stitch })
	for _, x in ipairs({ -1.05, 1.05 }) do
		part(model, { Name = "Rivet", Size = Vector3.new(0.22, 0.22, 0.22), CFrame = CFrame.new(x, 2.4, -0.27), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(230, 180, 70), Material = Enum.Material.Metal })
	end
	return base
end

function BUILDERS.PaperBag(model: Model, color: Color3)
	local base = part(model, { Name = "Base", Size = Vector3.new(2, 2.6, 1.3), CFrame = CFrame.new(0, 1.3, 0), Color = color, Material = Enum.Material.Cardboard })
	part(model, { Name = "Rim", Size = Vector3.new(2.06, 0.3, 1.36), CFrame = CFrame.new(0, 2.5, 0), Color = color:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Cardboard })
	for _, z in ipairs({ -0.45, 0.45 }) do
		local previous = Vector3.new(-0.5, 2.6, z)
		for i = 1, 5 do
			local angle = math.pi - i / 5 * math.pi
			local point = Vector3.new(math.cos(angle) * 0.5, 2.6 + math.sin(angle) * 0.7, z)
			rod(model, previous, point, 0.08, Color3.fromRGB(240, 236, 226))
			previous = point
		end
	end
	return base
end

function BUILDERS.Bucket(model: Model, color: Color3, shiny: boolean)
	local reflect = if shiny then 0.25 else 0.05
	local material = if shiny then Enum.Material.Metal else Enum.Material.SmoothPlastic
	local base = disc(model, "Base", 0.15, 0.3, 2.0, color:Lerp(Color3.new(0, 0, 0), 0.2), material, reflect)
	for i = 0, 4 do
		disc(model, "Body", 0.45 + i * 0.5, 0.52, 2.05 + i * 0.16, color, material, reflect)
	end
	disc(model, "Rim", 2.75, 0.22, 2.95, color:Lerp(Color3.new(1, 1, 1), 0.2), material, reflect)
	disc(model, "Inside", 2.7, 0.18, 2.6, color:Lerp(Color3.new(0, 0, 0), 0.35), material)
	handle(model, 2.75, 1.45, Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
	return base
end

function BUILDERS.Sack(model: Model, color: Color3, shiny: boolean)
	local material = if shiny then Enum.Material.Foil else Enum.Material.Fabric
	local base = part(model, { Name = "Base", Size = Vector3.new(2.6, 2.4, 2.4), CFrame = CFrame.new(0, 1.15, 0), Shape = Enum.PartType.Ball, Color = color, Material = material })
	disc(model, "Neck", 2.35, 0.6, 1.0, color, material)
	disc(model, "Tie", 2.45, 0.22, 1.1, Color3.fromRGB(150, 100, 60), Enum.Material.Fabric)
	part(model, { Name = "Tuft", Size = Vector3.new(1.3, 0.6, 1.3), CFrame = CFrame.new(0, 2.85, 0), Shape = Enum.PartType.Ball, Color = color, Material = material })
	part(model, { Name = "Patch", Size = Vector3.new(0.8, 0.8, 0.08), CFrame = CFrame.new(0.3, 1.3, -1.16), Color = color:Lerp(Color3.new(0, 0, 0), 0.25), Material = Enum.Material.Fabric })
	return base
end

function BUILDERS.Bin(model: Model, color: Color3)
	local base = part(model, { Name = "Base", Size = Vector3.new(1.9, 2.6, 2.1), CFrame = CFrame.new(0, 1.55, 0), Color = color })
	part(model, { Name = "Lid", Size = Vector3.new(2.1, 0.25, 2.4), CFrame = CFrame.new(0, 2.95, -0.1), Color = color:Lerp(Color3.new(0, 0, 0), 0.2) })
	part(model, { Name = "HandleBar", Size = Vector3.new(1.6, 0.18, 0.18), CFrame = CFrame.new(0, 2.85, 1.2), Color = Color3.fromRGB(40, 40, 46) })
	for _, x in ipairs({ -0.8, 0.8 }) do
		part(model, { Name = "Wheel", Size = Vector3.new(0.3, 0.6, 0.6), CFrame = CFrame.new(x, 0.3, 0.9), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Rubber })
	end
	part(model, { Name = "Label", Size = Vector3.new(0.9, 0.6, 0.06), CFrame = CFrame.new(0, 1.9, -1.08), Color = Color3.fromRGB(250, 250, 250) })
	return base
end

-- Returns a Model with PrimaryPart "Base" standing on the origin.
function BagModels.Build(info): Model
	local model = Instance.new("Model")
	model.Name = info.Id
	local builder = BUILDERS[info.Model] or BUILDERS.Pocket
	local base = builder(model, info.Color or Color3.fromRGB(200, 200, 200), info.Shiny == true)
	model.PrimaryPart = base
	return model
end

return BagModels
