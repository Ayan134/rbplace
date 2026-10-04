--[[
	ToolModels
	Builds the 3D model of every tool from code, so each tool is visually distinct
	without external assets. Used for:
	  - the Tool held in the player's hand (server, ToolService)
	  - 3D previews in Inventory / Shop (client, ViewportFrames)

	Models are built around the grip at the origin with the working end pointing
	toward -Z (forward when held).
]]

local ToolModels = {}

type PartSpec = {
	Name: string?,
	Size: Vector3,
	Offset: CFrame,
	Color: Color3,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	Reflectance: number?,
}

local SPECS: { [string]: { PartSpec } } = {
	Hand = {
		{ Name = "Handle", Size = Vector3.new(1.05, 1.05, 1.05), Offset = CFrame.new(), Color = Color3.fromRGB(255, 140, 180), Material = Enum.Material.SmoothPlastic, Shape = Enum.PartType.Ball },
		{ Size = Vector3.new(1.1, 0.3, 0.3), Offset = CFrame.new(0, 0.42, 0.1), Color = Color3.fromRGB(255, 230, 240), Material = Enum.Material.SmoothPlastic },
	},
	PlasticScraper = {
		{ Name = "Handle", Size = Vector3.new(0.38, 0.38, 1.4), Offset = CFrame.new(0, 0, -0.1), Color = Color3.fromRGB(40, 120, 255), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.5, 0.42, 0.25), Offset = CFrame.new(0, 0, -0.85), Color = Color3.fromRGB(30, 90, 210), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(1.4, 0.08, 0.9), Offset = CFrame.new(0, 0, -1.4), Color = Color3.fromRGB(140, 200, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.15 },
	},
	MetalScraper = {
		{ Name = "Handle", Size = Vector3.new(0.42, 0.42, 1.4), Offset = CFrame.new(0, 0, 0), Color = Color3.fromRGB(120, 72, 40), Material = Enum.Material.Wood },
		{ Size = Vector3.new(0.46, 0.46, 0.18), Offset = CFrame.new(0, 0, -0.75), Color = Color3.fromRGB(70, 70, 76), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.22, 0.1, 0.8), Offset = CFrame.new(0, 0, -1.2), Color = Color3.fromRGB(180, 182, 190), Material = Enum.Material.Metal },
		{ Size = Vector3.new(1.6, 0.06, 0.85), Offset = CFrame.new(0, 0, -1.95), Color = Color3.fromRGB(205, 208, 215), Material = Enum.Material.Metal, Reflectance = 0.25 },
	},
	HeatGun = {
		{ Name = "Handle", Size = Vector3.new(0.42, 1.1, 0.55), Offset = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.8, 0.85, 2.0), Offset = CFrame.new(0, 0.75, -0.55), Color = Color3.fromRGB(255, 120, 30), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.9, 0.45, 0.45), Offset = CFrame.new(0, 0.75, -1.75) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(60, 60, 66), Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder },
		{ Size = Vector3.new(0.1, 0.36, 0.36), Offset = CFrame.new(0, 0.75, -2.22) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder },
		{ Size = Vector3.new(0.82, 0.2, 0.6), Offset = CFrame.new(0, 1.12, 0.1), Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.SmoothPlastic },
	},
	ElectricPeeler = {
		{ Name = "Handle", Size = Vector3.new(0.45, 1.05, 0.55), Offset = CFrame.new(0, 0, 0), Color = Color3.fromRGB(30, 30, 36), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.75, 0.75, 1.9), Offset = CFrame.new(0, 0.7, -0.5), Color = Color3.fromRGB(255, 210, 40), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.78, 0.2, 1.5), Offset = CFrame.new(0, 1.1, -0.5), Color = Color3.fromRGB(30, 30, 36), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.12, 1.1, 1.1), Offset = CFrame.new(0, 0.7, -1.6), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder },
		{ Size = Vector3.new(0.14, 0.4, 0.4), Offset = CFrame.new(0, 0.7, -1.6), Color = Color3.fromRGB(60, 180, 255), Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder },
		{ Size = Vector3.new(0.8, 0.12, 0.3), Offset = CFrame.new(0, 0.7, 0.2), Color = Color3.fromRGB(60, 180, 255), Material = Enum.Material.Neon },
	},
	LaserPeeler = {
		{ Name = "Handle", Size = Vector3.new(0.4, 1.05, 0.5), Offset = CFrame.new(0, 0, 0), Color = Color3.fromRGB(240, 240, 250), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.6, 0.6, 2.3), Offset = CFrame.new(0, 0.68, -0.6), Color = Color3.fromRGB(245, 245, 255), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.64, 0.26, 1.6), Offset = CFrame.new(0, 0.92, -0.5), Color = Color3.fromRGB(120, 230, 255), Material = Enum.Material.Glass, Transparency = 0.3 },
		{ Size = Vector3.new(0.3, 0.7, 0.7), Offset = CFrame.new(0, 0.68, -1.6) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 72, 200), Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder },
		{ Size = Vector3.new(0.9, 0.25, 0.25), Offset = CFrame.new(0, 0.68, -2.1) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(80, 255, 255), Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder },
		{ Size = Vector3.new(0.7, 0.08, 0.3), Offset = CFrame.new(0, 0.38, 0.05), Color = Color3.fromRGB(255, 72, 200), Material = Enum.Material.Neon },
	},
}

local function makePart(spec: PartSpec, origin: CFrame): BasePart
	local part = Instance.new("Part")
	part.Name = spec.Name or "Detail"
	part.Size = spec.Size
	part.CFrame = origin * spec.Offset
	part.Color = spec.Color
	part.Material = spec.Material or Enum.Material.SmoothPlastic
	part.Shape = spec.Shape or Enum.PartType.Block
	part.Transparency = spec.Transparency or 0
	part.Reflectance = spec.Reflectance or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	return part
end

local function buildParts(modelId: string, parent: Instance): BasePart?
	local specs = SPECS[modelId] or SPECS.Hand
	local origin = CFrame.new()
	local handle: BasePart? = nil
	local parts = {}
	for _, spec in ipairs(specs) do
		local part = makePart(spec, origin)
		if spec.Name == "Handle" then
			handle = part
		end
		table.insert(parts, part)
	end
	for _, part in ipairs(parts) do
		if part ~= handle and handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
		end
		part.Parent = parent
	end
	return handle
end

-- Tool instance ready to be put in a Backpack.
function ToolModels.BuildTool(toolInfo): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolInfo.Name
	tool.ToolTip = toolInfo.Description
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ManualActivationOnly = true
	tool:SetAttribute("ToolId", toolInfo.Id)
	tool:SetAttribute("Tier", toolInfo.Tier)
	buildParts(toolInfo.Model, tool)
	tool.Grip = CFrame.new(0, -0.1, 0.15)

	if toolInfo.Model == "LaserPeeler" or toolInfo.Model == "ElectricPeeler" or toolInfo.Model == "HeatGun" then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			local light = Instance.new("PointLight")
			light.Range = 6
			light.Brightness = 1.2
			light.Color = if toolInfo.Model == "HeatGun"
				then Color3.fromRGB(255, 120, 40)
				elseif toolInfo.Model == "ElectricPeeler" then Color3.fromRGB(80, 180, 255)
				else Color3.fromRGB(255, 90, 230)
			light.Parent = handle
		end
	end
	return tool
end

-- Plain Model for ViewportFrame previews.
function ToolModels.BuildPreview(toolInfo): Model
	local model = Instance.new("Model")
	model.Name = toolInfo.Id
	local handle = buildParts(toolInfo.Model, model)
	if handle then
		model.PrimaryPart = handle
	end
	return model
end

return ToolModels
