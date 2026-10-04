--[[
	BuildKit
	Helper for building level models from code. Every level model follows the same layout:

	  <LevelName> (Model)
	  ├── Geometry         decorative / structural parts (no stickers)
	  ├── StickerSurfaces  parts that get covered with stickers (see StickerGenerator attributes)
	  ├── Climb            trusses, scaffolding and platforms for hard-to-reach spots
	  ├── SpawnPoint       where players appear
	  ├── FinishArea       center of the completion celebration
	  └── Configuration    LevelId + metadata attributes

	Coordinates are relative to the model origin (ground level, object centered at 0,0).
	A hand-made model with this layout placed in ServerStorage.Levels overrides the builder.
]]

local BuildKit = {}
BuildKit.__index = BuildKit

export type PartProps = {
	Name: string?,
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3?,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Class: string?, -- "Part" | "WedgePart" | "TrussPart"
	Transparency: number?,
	Reflectance: number?,
	CanCollide: boolean?,
	CastShadow: boolean?,
	Attributes: { [string]: any }?,
}

function BuildKit.new(levelId: string)
	local model = Instance.new("Model")
	model.Name = levelId

	local function folder(name: string)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = model
		return f
	end

	local self = setmetatable({
		Model = model,
		Geometry = folder("Geometry"),
		StickerSurfaces = folder("StickerSurfaces"),
		Climb = folder("Climb"),
		LevelId = levelId,
	}, BuildKit)

	local config = Instance.new("Configuration")
	config.Name = "Configuration"
	config:SetAttribute("LevelId", levelId)
	config.Parent = model
	self.Configuration = config

	-- Invisible root exactly at the origin: the model's pivot is ground center,
	-- so PivotTo(CFrame.new(groundPoint)) places the object on the ground.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.CFrame = CFrame.new(0, 0, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root
	return self
end

local function makePart(props: PartProps, parent: Instance): BasePart
	local class = props.Class or "Part"
	local part = Instance.new(class) :: BasePart
	part.Name = props.Name or "Part"
	part.Size = props.Size
	part.CFrame = props.CFrame
	part.Color = props.Color or Color3.fromRGB(200, 200, 200)
	part.Material = props.Material or Enum.Material.SmoothPlastic
	if props.Shape and part:IsA("Part") then
		part.Shape = props.Shape
	end
	part.Transparency = props.Transparency or 0
	part.Reflectance = props.Reflectance or 0
	part.Anchored = true
	part.CanCollide = if props.CanCollide == nil then true else props.CanCollide
	part.CastShadow = if props.CastShadow == nil then true else props.CastShadow
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.Attributes then
		for key, value in pairs(props.Attributes) do
			part:SetAttribute(key, value)
		end
	end
	part.Parent = parent
	return part
end

-- Structural / decorative part (no stickers)
function BuildKit:Part(props: PartProps): BasePart
	return makePart(props, self.Geometry)
end

-- Part covered with stickers
function BuildKit:Surface(props: PartProps, zone: string?, attributes: { [string]: any }?): BasePart
	local part = makePart(props, self.StickerSurfaces)
	if zone then
		part:SetAttribute("Zone", zone)
	end
	if attributes then
		for key, value in pairs(attributes) do
			part:SetAttribute(key, value)
		end
	end
	return part
end

-- Climbable truss
function BuildKit:Truss(position: Vector3, height: number, rotation: CFrame?): BasePart
	return makePart({
		Name = "Truss",
		Class = "TrussPart",
		Size = Vector3.new(2, height, 2),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * (rotation or CFrame.new()),
		Color = Color3.fromRGB(255, 196, 40),
		Material = Enum.Material.Metal,
	}, self.Climb)
end

-- Walkable scaffold platform
function BuildKit:Platform(cframe: CFrame, size: Vector3): BasePart
	local platform = makePart({
		Name = "Platform",
		Size = size,
		CFrame = cframe,
		Color = Color3.fromRGB(255, 176, 40),
		Material = Enum.Material.DiamondPlate,
	}, self.Climb)
	-- Railing posts at corners for a scaffolding look
	local half = size / 2
	for _, corner in ipairs({ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }) do
		makePart({
			Name = "Post",
			Size = Vector3.new(0.3, 3, 0.3),
			CFrame = cframe * CFrame.new(half.X * corner.X * 0.95, half.Y + 1.5, half.Z * corner.Z * 0.95),
			Color = Color3.fromRGB(60, 60, 70),
			Material = Enum.Material.Metal,
			CanCollide = false,
		}, self.Climb)
	end
	return platform
end

-- Staircase from `from` (ground) climbing along `direction` to `height`
function BuildKit:Stairs(from: Vector3, direction: Vector3, height: number, width: number, color: Color3?)
	local steps = math.ceil(height / 1)
	local flat = Vector3.new(direction.X, 0, direction.Z).Unit
	local look = CFrame.lookAt(Vector3.zero, flat)
	for i = 1, steps do
		local h = i * (height / steps)
		local center = from + flat * (i - 0.5) * 1.6 + Vector3.new(0, h / 2, 0)
		makePart({
			Name = "Step",
			Size = Vector3.new(width, h, 1.6),
			CFrame = CFrame.new(center) * look.Rotation,
			Color = color or Color3.fromRGB(200, 200, 205),
			Material = Enum.Material.Concrete,
		}, self.Climb)
	end
end

-- Vertical cylinder helper (Roblox cylinders run along X, rotate so they stand up)
function BuildKit.VerticalCylinder(center: Vector3, height: number, diameter: number): (Vector3, CFrame)
	return Vector3.new(height, diameter, diameter), CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
end

-- Cylinder whose axis runs along Z
function BuildKit.ZCylinder(center: Vector3, length: number, diameter: number): (Vector3, CFrame)
	return Vector3.new(length, diameter, diameter), CFrame.new(center) * CFrame.Angles(0, math.rad(90), 0)
end

function BuildKit:SetSpawn(position: Vector3, lookAt: Vector3)
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnPoint"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.Parent = self.Model
	return spawn
end

function BuildKit:SetFinish(position: Vector3, size: Vector3)
	local finish = Instance.new("Part")
	finish.Name = "FinishArea"
	finish.Size = size
	finish.CFrame = CFrame.new(position)
	finish.Transparency = 1
	finish.Anchored = true
	finish.CanCollide = false
	finish.CanQuery = false
	finish.CanTouch = false
	finish.Parent = self.Model
	return finish
end

function BuildKit:Finish(): Model
	if not self.Model:FindFirstChild("SpawnPoint") then
		self:SetSpawn(Vector3.new(0, 3, 40), Vector3.zero)
	end
	if not self.Model:FindFirstChild("FinishArea") then
		local cf, size = self.Model:GetBoundingBox()
		self:SetFinish(cf.Position, size)
	end
	local _, size = self.Model:GetBoundingBox()
	self.Configuration:SetAttribute("BoundsSize", size)
	return self.Model
end

return BuildKit
