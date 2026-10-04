--[[
	Decor
	Reusable low-poly scenery prefabs for levels and the lobby: trees, bushes, flower
	beds, lamps with string lights, benches, buildings, roads, cars, flags, hills,
	water, etc. Everything is anchored and built from plain Parts (no assets).

	Water / terrain: parts tagged with the attribute TerrainMaterial (e.g. "Water") are
	converted into real Terrain at runtime by Decor.ApplyTerrain - in Studio edit mode
	they show as translucent placeholders.
]]

local Workspace = game:GetService("Workspace")

local Decor = {}

local GREENS = {
	Color3.fromRGB(86, 168, 74),
	Color3.fromRGB(104, 184, 82),
	Color3.fromRGB(72, 150, 70),
	Color3.fromRGB(122, 190, 90),
}
local FLOWERS = {
	Color3.fromRGB(255, 120, 160),
	Color3.fromRGB(255, 214, 90),
	Color3.fromRGB(170, 130, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 150, 90),
}
local WARM_LIGHT = Color3.fromRGB(255, 214, 160)

function Decor.Part(parent: Instance, props): BasePart
	local part = Instance.new(props.Class or "Part") :: BasePart
	part.Name = props.Name or "Decor"
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
	part.Parent = parent
	return part
end

local P = Decor.Part

local function vcyl(center: Vector3, height: number, diameter: number): (Vector3, CFrame)
	return Vector3.new(height, diameter, diameter), CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
end

local function pick(rng: Random?, list)
	if rng then
		return list[rng:NextInteger(1, #list)]
	end
	return list[1]
end

local function light(parent: Instance, range: number, brightness: number, color: Color3?)
	local pointLight = Instance.new("PointLight")
	pointLight.Range = range
	pointLight.Brightness = brightness
	pointLight.Color = color or WARM_LIGHT
	pointLight.Shadows = false
	pointLight.Parent = parent
	return pointLight
end

------------------------------------------------------------------------
-- Nature
------------------------------------------------------------------------

-- style: "Round" | "Pine" | "Palm" | "Blossom" | "Autumn"
function Decor.Tree(parent: Instance, position: Vector3, scale: number?, style: string?, rng: Random?)
	local s = scale or 1
	local kind = style or "Round"
	local model = Instance.new("Model")
	model.Name = "Tree"
	if kind == "Pine" or kind == "Round" then
		-- A Store tree can take its place at runtime (AssetLoader)
		model:SetAttribute("AssetKind", "Tree." .. kind)
	end
	model.Parent = parent
	if kind == "Pine" then
		local size, cf = vcyl(position + Vector3.new(0, 3 * s, 0), 6 * s, 1.4 * s)
		P(model, { Name = "Trunk", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(110, 76, 50), Material = Enum.Material.Wood })
		local green = Color3.fromRGB(52, 120, 72)
		for i = 0, 3 do
			local width = (9 - i * 2) * s
			local layer, layerCF = vcyl(position + Vector3.new(0, (5 + i * 3.2) * s, 0), 3.4 * s, width)
			P(model, { Name = "Needles", Size = layer, CFrame = layerCF, Shape = Enum.PartType.Cylinder, Color = green:Lerp(Color3.fromRGB(70, 150, 90), i / 4), Material = Enum.Material.Grass })
		end
	elseif kind == "Palm" then
		for i = 0, 4 do
			P(model, {
				Name = "Trunk",
				Size = Vector3.new(1.3 * s, 2.6 * s, 1.3 * s),
				CFrame = CFrame.new(position + Vector3.new(i * 0.35 * s, (1.3 + i * 2.5) * s, 0)) * CFrame.Angles(0, 0, math.rad(-6)),
				Color = Color3.fromRGB(150, 116, 74),
				Material = Enum.Material.Wood,
			})
		end
		local top = position + Vector3.new(1.8 * s, 13 * s, 0)
		for i = 0, 6 do
			local angle = i / 7 * math.pi * 2
			P(model, {
				Name = "Leaf",
				Size = Vector3.new(1.6 * s, 0.3 * s, 7 * s),
				CFrame = CFrame.new(top) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -3 * s) * CFrame.Angles(math.rad(-22), 0, 0),
				Color = Color3.fromRGB(80, 168, 76),
				Material = Enum.Material.Grass,
				CanCollide = false,
			})
		end
	else
		local size, cf = vcyl(position + Vector3.new(0, 3.5 * s, 0), 7 * s, 1.5 * s)
		P(model, { Name = "Trunk", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(116, 80, 52), Material = Enum.Material.Wood })
		local palette = if kind == "Blossom"
			then { Color3.fromRGB(255, 182, 206), Color3.fromRGB(255, 204, 222), Color3.fromRGB(250, 160, 190) }
			elseif kind == "Autumn" then { Color3.fromRGB(240, 150, 60), Color3.fromRGB(230, 110, 50), Color3.fromRGB(250, 196, 80) }
			else GREENS
		local blobs = {
			{ Vector3.new(0, 9.5, 0), 8.5 },
			{ Vector3.new(2.4, 8, 1.2), 5.6 },
			{ Vector3.new(-2.2, 8.4, -1), 5.2 },
			{ Vector3.new(0.6, 12, -0.6), 5 },
		}
		for _, blob in ipairs(blobs) do
			P(model, {
				Name = "Leaves",
				Size = Vector3.one * blob[2] * s,
				CFrame = CFrame.new(position + blob[1] * s),
				Shape = Enum.PartType.Ball,
				Color = pick(rng, palette),
				Material = Enum.Material.Grass,
			})
		end
	end
	return model
end

function Decor.Bush(parent: Instance, position: Vector3, size: number?, color: Color3?)
	local s = size or 4
	local bush = P(parent, { Name = "Bush", Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(position + Vector3.new(0, s * 0.3, 0)), Shape = Enum.PartType.Ball, Color = color or GREENS[3], Material = Enum.Material.Grass })
	bush:SetAttribute("AssetKind", "Bush")
	return bush
end

function Decor.Rock(parent: Instance, position: Vector3, size: number, rng: Random?)
	local r = rng or Random.new()
	local rock = P(parent, {
		Name = "Rock",
		Size = Vector3.new(size, size * 0.6, size * 0.8),
		CFrame = CFrame.new(position + Vector3.new(0, size * 0.2, 0)) * CFrame.Angles(r:NextNumber(-0.3, 0.3), r:NextNumber(0, 6.28), r:NextNumber(-0.3, 0.3)),
		Color = Color3.fromRGB(150, 150, 156),
		Material = Enum.Material.Slate,
	})
	rock:SetAttribute("AssetKind", "Rock")
	return rock
end

function Decor.FlowerBed(parent: Instance, position: Vector3, radius: number, rng: Random?)
	local size, cf = vcyl(position + Vector3.new(0, 0.5, 0), 1, radius * 2)
	P(parent, { Name = "FlowerBedRim", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(196, 186, 170), Material = Enum.Material.Cobblestone })
	local soil, soilCF = vcyl(position + Vector3.new(0, 0.6, 0), 1, radius * 2 - 1)
	P(parent, { Name = "Soil", Size = soil, CFrame = soilCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(110, 78, 58), Material = Enum.Material.Ground })
	local count = math.floor(radius * 2.5)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local r = (radius - 1) * (0.35 + 0.6 * ((i * 37) % 10) / 10)
		P(parent, {
			Name = "Flower",
			Size = Vector3.new(0.9, 0.9, 0.9),
			CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * r, 1.4, math.sin(angle) * r)),
			Shape = Enum.PartType.Ball,
			Color = pick(rng, FLOWERS),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- Big rounded hill, half buried, for distant backdrops
function Decor.Hill(parent: Instance, position: Vector3, radius: number, color: Color3?)
	P(parent, {
		Name = "Hill",
		Size = Vector3.new(radius * 2, radius * 1.1, radius * 2),
		CFrame = CFrame.new(position - Vector3.new(0, radius * 0.25, 0)),
		Shape = Enum.PartType.Ball,
		Color = color or Color3.fromRGB(96, 168, 86),
		Material = Enum.Material.Grass,
		CanCollide = false,
	})
end

-- Ring of hills and tree clusters far from the object so the horizon never looks empty
-- avoid: optional { { Position = Vector3, Radius = number } } areas kept free of trees
function Decor.Backdrop(parent: Instance, center: Vector3, radius: number, rng: Random, style: string?, avoid: { any }?)
	local folder = Instance.new("Folder")
	folder.Name = "Backdrop"
	folder.Parent = parent
	for i = 0, 17 do
		local angle = (i / 18) * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
		local r = radius + rng:NextNumber(-10, 20)
		local hillColor = Color3.fromRGB(90, 160, 84):Lerp(Color3.fromRGB(120, 180, 96), rng:NextNumber())
		local hillRadius = rng:NextNumber(26, 46)
		local position = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		local blocked = false
		for _, area in ipairs(avoid or {}) do
			if (Vector3.new(position.X, 0, position.Z) - Vector3.new(area.Position.X, 0, area.Position.Z)).Magnitude < area.Radius + hillRadius * 0.6 then
				blocked = true
				break
			end
		end
		if not blocked then
			Decor.Hill(folder, position, hillRadius, hillColor)
		end
	end
	for i = 0, 23 do
		local angle = (i / 24) * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
		local r = radius - rng:NextNumber(20, 40)
		local treeStyle = style or (if rng:NextNumber() < 0.4 then "Pine" else "Round")
		local position = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		local blocked = false
		for _, area in ipairs(avoid or {}) do
			if (Vector3.new(position.X, 0, position.Z) - Vector3.new(area.Position.X, 0, area.Position.Z)).Magnitude < area.Radius then
				blocked = true
				break
			end
		end
		if not blocked then
			Decor.Tree(folder, position, rng:NextNumber(1.2, 1.8), treeStyle, rng)
		end
	end
	return folder
end

-- Slow particles floating over the play area for atmosphere
-- style: "Sunlight" (dust motes drifting down) | "Fireflies" (glowing, rising) | "Petals" (pink, drifting)
function Decor.AmbientMotes(parent: Instance, center: Vector3, radius: number, style: string?)
	local kind = style or "Sunlight"
	local rising = kind == "Fireflies"
	local emitterPart = P(parent, {
		Name = "AmbientMotes",
		Size = Vector3.new(radius * 2, 1, radius * 2),
		CFrame = CFrame.new(center + Vector3.new(0, if rising then 1 else 34, 0)),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})
	emitterPart.CanQuery = false
	emitterPart.CanTouch = false
	local looks = {
		Sunlight = { Color = Color3.fromRGB(255, 244, 214), Size = 0.18, Rate = 26, Light = 0.8 },
		Fireflies = { Color = Color3.fromRGB(230, 255, 140), Size = 0.32, Rate = 18, Light = 1 },
		Petals = { Color = Color3.fromRGB(255, 190, 214), Size = 0.3, Rate = 22, Light = 0.3 },
	}
	local look = looks[kind] or looks.Sunlight
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = kind
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.EmissionDirection = if rising then Enum.NormalId.Top else Enum.NormalId.Bottom
	emitter.Color = ColorSequence.new(look.Color)
	emitter.LightEmission = look.Light
	emitter.LightInfluence = 0.2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.15, look.Size),
		NumberSequenceKeypoint.new(0.85, look.Size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.15),
		NumberSequenceKeypoint.new(0.8, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(9, 14)
	emitter.Rate = look.Rate
	emitter.Speed = NumberRange.new(0.6, 1.8)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = if kind == "Petals" then Vector3.new(0.5, -0.4, 0.3) else Vector3.new(0.15, 0, 0.1)
	emitter.RotSpeed = NumberRange.new(-40, 40)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Parent = emitterPart
	return emitterPart
end

function Decor.Hill(parent: Instance, position: Vector3, radius: number, color: Color3?)
	local hill = P(parent, {
		Name = "Hill",
		Size = Vector3.one * radius * 2,
		CFrame = CFrame.new(position - Vector3.new(0, radius * 0.45, 0)),
		Shape = Enum.PartType.Ball,
		Color = color or Color3.fromRGB(96, 168, 86),
		Material = Enum.Material.Grass,
		CanCollide = false,
	})
	hill:SetAttribute("TerrainMaterial", "Grass")
	return hill
end

-- Rocky mountain: a cluster of overlapping rock balls (real terrain at runtime)
function Decor.Mountain(parent: Instance, position: Vector3, size: number, rng: Random?)
	local r = rng or Random.new(7)
	local folder = Instance.new("Folder")
	folder.Name = "Mountain"
	folder.Parent = parent
	local function blob(offset: Vector3, radius: number, material: string)
		local part = P(folder, {
			Name = "Rock",
			Size = Vector3.one * radius * 2,
			CFrame = CFrame.new(position + offset),
			Shape = Enum.PartType.Ball,
			Color = if material == "Rock" then Color3.fromRGB(128, 126, 130) else Color3.fromRGB(96, 168, 86),
			Material = if material == "Rock" then Enum.Material.Rock else Enum.Material.Grass,
			CanCollide = false,
		})
		part:SetAttribute("TerrainMaterial", material)
	end
	blob(Vector3.new(0, -size * 0.25, 0), size, "Rock")
	for _ = 1, 4 do
		local angle = r:NextNumber(0, math.pi * 2)
		local radius = size * r:NextNumber(0.45, 0.7)
		blob(Vector3.new(math.cos(angle) * size * 0.7, -radius * 0.35, math.sin(angle) * size * 0.7), radius, "Rock")
	end
	-- Grassy foothills in front
	for _ = 1, 3 do
		local angle = r:NextNumber(0, math.pi * 2)
		local radius = size * r:NextNumber(0.3, 0.45)
		blob(Vector3.new(math.cos(angle) * size * 1.1, -radius * 0.5, math.sin(angle) * size * 1.1), radius, "Grass")
	end
	return folder
end

-- Dirt path / patch: replaces the top layer of grass with terrain ground at runtime
function Decor.DirtPath(parent: Instance, cframe: CFrame, size: Vector2, material: string?)
	local patch = P(parent, {
		Name = "DirtPath",
		Size = Vector3.new(size.X, 2, size.Y),
		CFrame = cframe * CFrame.new(0, -0.9, 0),
		Color = Color3.fromRGB(150, 108, 70),
		Material = Enum.Material.Ground,
		CanCollide = false,
		CastShadow = false,
	})
	patch:SetAttribute("TerrainMaterial", material or "Ground")
	return patch
end

-- Round dirt patch made of a terrain ball flattened into the ground
function Decor.DirtCircle(parent: Instance, position: Vector3, radius: number, material: string?)
	local patch = P(parent, {
		Name = "DirtCircle",
		Size = Vector3.new(2, radius * 2, radius * 2),
		CFrame = CFrame.new(position - Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(150, 108, 70),
		Material = Enum.Material.Ground,
		CanCollide = false,
		CastShadow = false,
	})
	patch:SetAttribute("TerrainMaterial", material or "Ground")
	return patch
end

-- White picket fence from a to b (posts, two rails and pointed pickets)
function Decor.PicketFence(parent: Instance, a: Vector3, b: Vector3, height: number?)
	local h = height or 4
	local model = Instance.new("Model")
	model.Name = "PicketFence"
	model.Parent = parent
	local white = Color3.fromRGB(250, 250, 248)
	local flatA, flatB = Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, 0, b.Z)
	local length = (flatB - flatA).Magnitude
	if length < 0.5 then
		return model
	end
	local frame = CFrame.lookAt(flatA, flatB)
	for _, y in ipairs({ h * 0.3, h * 0.72 }) do
		P(model, { Name = "Rail", Size = Vector3.new(0.25, 0.4, length), CFrame = frame * CFrame.new(0, y, -length / 2), Color = white, Material = Enum.Material.WoodPlanks })
	end
	local posts = math.max(1, math.floor(length / 8))
	for i = 0, posts do
		local z = -length * i / posts
		P(model, { Name = "Post", Size = Vector3.new(0.6, h + 0.6, 0.6), CFrame = frame * CFrame.new(0, (h + 0.6) / 2, z), Color = white, Material = Enum.Material.WoodPlanks })
		P(model, { Name = "PostCap", Size = Vector3.new(0.8, 0.25, 0.8), CFrame = frame * CFrame.new(0, h + 0.7, z), Color = white })
	end
	local pickets = math.floor(length / 1.6)
	for i = 0, pickets - 1 do
		local z = -(i + 0.5) * length / pickets
		P(model, { Name = "Picket", Size = Vector3.new(0.18, h - 0.6, 0.8), CFrame = frame * CFrame.new(0.2, (h - 0.6) / 2, z), Color = white, Material = Enum.Material.WoodPlanks, CastShadow = false })
		-- Pointed top: a square turned 45 degrees, half sunk into the picket
		P(model, { Name = "PicketTip", Size = Vector3.new(0.18, 0.57, 0.57), CFrame = frame * CFrame.new(0.2, h - 0.6, z) * CFrame.Angles(math.rad(45), 0, 0), Color = white, CastShadow = false })
	end
	return model
end

-- Cartoon mushroom: white stem, round cap with spots. AssetKind lets a Store model replace it.
function Decor.Mushroom(parent: Instance, position: Vector3, height: number, capColor: Color3?, rng: Random?)
	local r = rng or Random.new(math.floor(position.X * 13 + position.Z * 7))
	local model = Instance.new("Model")
	model.Name = "Mushroom"
	model:SetAttribute("AssetKind", if height > 6 then "Mushroom" else "SmallMushroom")
	model.Parent = parent
	local cap = capColor or Color3.fromRGB(230, 40, 50)
	local stemHeight = height * 0.62
	local stem, stemCF = vcyl(position + Vector3.new(0, stemHeight / 2, 0), stemHeight, height * 0.26)
	P(model, { Name = "Stem", Size = stem, CFrame = stemCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(250, 244, 230) })
	local skirt, skirtCF = vcyl(position + Vector3.new(0, stemHeight * 0.7, 0), height * 0.06, height * 0.36)
	P(model, { Name = "Skirt", Size = skirt, CFrame = skirtCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(240, 232, 214) })
	local capCenter = position + Vector3.new(0, stemHeight, 0)
	P(model, { Name = "Cap", Size = Vector3.new(height * 0.95, height * 0.55, height * 0.95), CFrame = CFrame.new(capCenter + Vector3.new(0, height * 0.08, 0)), Shape = Enum.PartType.Ball, Color = cap })
	P(model, { Name = "CapUnder", Size = Vector3.new(height * 0.08, height * 0.85, height * 0.85), CFrame = CFrame.new(capCenter - Vector3.new(0, height * 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90)), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(240, 220, 200) })
	-- White spots on the cap
	local spots = 7
	for i = 1, spots do
		local angle = (i / spots) * math.pi * 2 + r:NextNumber(-0.3, 0.3)
		local elevation = r:NextNumber(0.35, 1.15)
		local dir = Vector3.new(math.cos(angle) * math.cos(elevation), math.sin(elevation), math.sin(angle) * math.cos(elevation))
		local surface = capCenter + Vector3.new(0, height * 0.08, 0) + Vector3.new(dir.X * height * 0.46, dir.Y * height * 0.27, dir.Z * height * 0.46)
		P(model, { Name = "Spot", Size = Vector3.new(height * 0.05, height * 0.17, height * 0.17), CFrame = CFrame.lookAt(surface, surface + dir) * CFrame.Angles(0, math.rad(90), 0), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 255, 255), CastShadow = false })
	end
	return model
end

function Decor.MushroomCluster(parent: Instance, position: Vector3, count: number, rng: Random?, capColor: Color3?)
	local r = rng or Random.new(3)
	for _ = 1, count do
		local offset = Vector3.new(r:NextNumber(-2.4, 2.4), 0, r:NextNumber(-2.4, 2.4))
		Decor.Mushroom(parent, position + offset, r:NextNumber(1.2, 2.4), capColor, r)
	end
end

-- Placeholder that becomes real terrain water at runtime
function Decor.Water(parent: Instance, cframe: CFrame, size: Vector3)
	local water = P(parent, {
		Name = "Water",
		Size = size,
		CFrame = cframe,
		Color = Color3.fromRGB(70, 160, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.4,
		CanCollide = false,
		CastShadow = false,
	})
	water:SetAttribute("TerrainMaterial", "Water")
	return water
end

-- Converts TerrainMaterial placeholders under `root` into terrain (runtime only)
function Decor.ApplyTerrain(root: Instance)
	local terrain = Workspace.Terrain
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local materialName = descendant:GetAttribute("TerrainMaterial")
			if type(materialName) == "string" then
				local ok = pcall(function()
					if materialName == "Water" then
						-- Soft sandy bed and shore so the water never floats over the void
						local size = descendant.Size
						terrain:FillBlock(descendant.CFrame * CFrame.new(0, -size.Y / 2 - 1.5, 0), Vector3.new(size.X + 4, 3, size.Z + 4), Enum.Material.Sand)
						terrain:FillBlock(descendant.CFrame * CFrame.new(0, size.Y / 2 - 0.5, 0), Vector3.new(size.X + 3, 1, size.Z + 3), Enum.Material.Sand)
					end
					local material = (Enum.Material :: any)[materialName]
					if descendant:IsA("Part") and descendant.Shape == Enum.PartType.Ball then
						terrain:FillBall(descendant.Position, math.min(descendant.Size.X, descendant.Size.Y, descendant.Size.Z) / 2, material)
					else
						terrain:FillBlock(descendant.CFrame, descendant.Size, material)
					end
				end)
				if ok then
					descendant.Transparency = 1
					descendant.CanQuery = false
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Street furniture
------------------------------------------------------------------------

function Decor.Lamp(parent: Instance, position: Vector3, height: number?, color: Color3?): Vector3
	local h = height or 10
	local size, cf = vcyl(position + Vector3.new(0, h / 2, 0), h, 0.5)
	P(parent, { Name = "LampPost", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(40, 42, 50), Material = Enum.Material.Metal })
	local base, baseCF = vcyl(position + Vector3.new(0, 0.4, 0), 0.8, 1.3)
	P(parent, { Name = "LampBase", Size = base, CFrame = baseCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(40, 42, 50), Material = Enum.Material.Metal })
	P(parent, { Name = "LampCap", Class = "WedgePart", Size = Vector3.new(1.6, 0.6, 1.6), CFrame = CFrame.new(position + Vector3.new(0, h + 1.3, 0)), Color = Color3.fromRGB(40, 42, 50), Material = Enum.Material.Metal })
	local bulb = P(parent, { Name = "LampBulb", Size = Vector3.new(1.2, 1.4, 1.2), CFrame = CFrame.new(position + Vector3.new(0, h + 0.5, 0)), Color = color or Color3.fromRGB(255, 236, 196), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	light(bulb, 18, 1.2, color)
	return position + Vector3.new(0, h + 0.2, 0)
end

-- Sagging chain of little bulbs between two points
function Decor.StringLights(parent: Instance, a: Vector3, b: Vector3, count: number?, sag: number?)
	local n = count or 8
	local colors = { Color3.fromRGB(255, 220, 140), Color3.fromRGB(255, 160, 190), Color3.fromRGB(160, 220, 255), Color3.fromRGB(190, 255, 170) }
	local drop = sag or 2
	for i = 1, n do
		local t = i / (n + 1)
		local position = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * drop, 0)
		P(parent, {
			Name = "Bulb",
			Size = Vector3.new(0.45, 0.55, 0.45),
			CFrame = CFrame.new(position),
			Shape = Enum.PartType.Ball,
			Color = colors[(i % #colors) + 1],
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
	end
	-- Thin wire
	local mid = (a + b) / 2 - Vector3.new(0, drop * 0.6, 0)
	for _, segment in ipairs({ { a, mid }, { mid, b } }) do
		local from, to = segment[1], segment[2]
		local length = (to - from).Magnitude
		P(parent, {
			Name = "Wire",
			Size = Vector3.new(0.06, 0.06, length),
			CFrame = CFrame.lookAt((from + to) / 2, to),
			Color = Color3.fromRGB(30, 30, 34),
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- Triangle pennant flags hanging from a sagging line
function Decor.Bunting(parent: Instance, a: Vector3, b: Vector3, count: number?, sag: number?)
	local n = count or 10
	local drop = sag or 1.5
	local colors = {
		Color3.fromRGB(255, 120, 150), Color3.fromRGB(255, 210, 90), Color3.fromRGB(110, 222, 164),
		Color3.fromRGB(120, 180, 255), Color3.fromRGB(190, 150, 255),
	}
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local yaw = if flat.Magnitude > 0.01 then CFrame.lookAt(Vector3.zero, flat).Rotation else CFrame.new()
	for i = 1, n do
		local t = i / (n + 1)
		local position = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * drop, 0)
		P(parent, {
			Name = "Pennant",
			Class = "WedgePart",
			Size = Vector3.new(0.08, 1.4, 1.1),
			CFrame = CFrame.new(position - Vector3.new(0, 0.7, 0)) * yaw * CFrame.Angles(0, math.rad(90), math.rad(180)),
			Color = colors[(i % #colors) + 1],
			Material = Enum.Material.Fabric,
			CanCollide = false,
			CastShadow = false,
		})
	end
	local mid = (a + b) / 2 - Vector3.new(0, drop, 0)
	for _, segment in ipairs({ { a, mid }, { mid, b } }) do
		local from, to = segment[1], segment[2]
		P(parent, {
			Name = "Rope",
			Size = Vector3.new(0.06, 0.06, (to - from).Magnitude),
			CFrame = CFrame.lookAt((from + to) / 2, to),
			Color = Color3.fromRGB(240, 240, 240),
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- Bunch of party balloons tied to a point
function Decor.Balloons(parent: Instance, position: Vector3, count: number?, rng: Random?)
	local r = rng or Random.new(3)
	local colors = {
		Color3.fromRGB(255, 96, 130), Color3.fromRGB(255, 200, 70), Color3.fromRGB(100, 200, 255),
		Color3.fromRGB(130, 230, 150), Color3.fromRGB(200, 140, 255), Color3.fromRGB(255, 150, 80),
	}
	for i = 1, count or 5 do
		local angle = (i / (count or 5)) * math.pi * 2
		local top = position + Vector3.new(math.cos(angle) * r:NextNumber(0.8, 1.8), r:NextNumber(4.5, 6.5), math.sin(angle) * r:NextNumber(0.8, 1.8))
		P(parent, {
			Name = "Balloon",
			Size = Vector3.new(1.8, 2.2, 1.8),
			CFrame = CFrame.new(top),
			Shape = Enum.PartType.Ball,
			Color = colors[(i % #colors) + 1],
			Reflectance = 0.15,
			CanCollide = false,
		})
		P(parent, {
			Name = "String",
			Size = Vector3.new(0.05, 0.05, (top - position).Magnitude),
			CFrame = CFrame.lookAt((top + position) / 2, top),
			Color = Color3.fromRGB(245, 245, 245),
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- Hot air balloon floating high above the scene
function Decor.HotAirBalloon(parent: Instance, position: Vector3, color: Color3, stripe: Color3?)
	local model = Instance.new("Model")
	model.Name = "HotAirBalloon"
	model.Parent = parent
	P(model, { Name = "Envelope", Size = Vector3.new(20, 23, 20), CFrame = CFrame.new(position), Shape = Enum.PartType.Ball, Color = color, Material = Enum.Material.Fabric, CanCollide = false })
	local band, bandCF = vcyl(position + Vector3.new(0, 1, 0), 3.2, 20.3)
	P(model, { Name = "Band", Size = band, CFrame = bandCF, Shape = Enum.PartType.Cylinder, Color = stripe or Color3.fromRGB(255, 255, 255), Material = Enum.Material.Fabric, CanCollide = false })
	local skirt, skirtCF = vcyl(position - Vector3.new(0, 11, 0), 2.6, 7)
	P(model, { Name = "Skirt", Size = skirt, CFrame = skirtCF, Shape = Enum.PartType.Cylinder, Color = color, Material = Enum.Material.Fabric, CanCollide = false })
	local basket = position - Vector3.new(0, 18, 0)
	P(model, { Name = "Basket", Size = Vector3.new(4, 3, 4), CFrame = CFrame.new(basket), Color = Color3.fromRGB(150, 104, 60), Material = Enum.Material.Wood, CanCollide = false })
	for _, corner in ipairs({ Vector3.new(1.8, 0, 1.8), Vector3.new(-1.8, 0, 1.8), Vector3.new(1.8, 0, -1.8), Vector3.new(-1.8, 0, -1.8) }) do
		local from = basket + corner + Vector3.new(0, 1.5, 0)
		local to = position - Vector3.new(0, 11, 0) + corner * 1.4
		P(model, { Name = "Rope", Size = Vector3.new(0.12, 0.12, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = Color3.fromRGB(80, 60, 40), CanCollide = false, CastShadow = false })
	end
	local flame = P(model, { Name = "Burner", Size = Vector3.new(1, 1.2, 1), CFrame = CFrame.new(position - Vector3.new(0, 13.5, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 170, 60), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	light(flame, 12, 1.5, Color3.fromRGB(255, 170, 80))
	return model
end

function Decor.Bench(parent: Instance, cframe: CFrame)
	local wood = Color3.fromRGB(168, 112, 66)
	local bench = Instance.new("Model")
	bench.Name = "Bench"
	bench:SetAttribute("AssetKind", "Bench")
	bench.Parent = parent
	parent = bench
	P(parent, { Name = "BenchSeat", Size = Vector3.new(6, 0.4, 2), CFrame = cframe * CFrame.new(0, 1.6, 0), Color = wood, Material = Enum.Material.WoodPlanks })
	P(parent, { Name = "BenchBack", Size = Vector3.new(6, 1.6, 0.35), CFrame = cframe * CFrame.new(0, 2.6, 0.9) * CFrame.Angles(math.rad(-10), 0, 0), Color = wood, Material = Enum.Material.WoodPlanks })
	for _, x in ipairs({ -2.5, 2.5 }) do
		P(parent, { Name = "BenchLeg", Size = Vector3.new(0.35, 1.5, 1.8), CFrame = cframe * CFrame.new(x, 0.75, 0.1), Color = Color3.fromRGB(46, 48, 56), Material = Enum.Material.Metal })
	end
	-- Keep the bench's orientation so a replacement model lines up with it
	bench.WorldPivot = cframe
	return bench
end

function Decor.Planter(parent: Instance, cframe: CFrame, size: Vector3, rng: Random?)
	P(parent, { Name = "Planter", Size = size, CFrame = cframe * CFrame.new(0, size.Y / 2, 0), Color = Color3.fromRGB(214, 206, 192), Material = Enum.Material.Concrete })
	P(parent, { Name = "PlanterSoil", Size = Vector3.new(size.X - 0.6, 0.2, size.Z - 0.6), CFrame = cframe * CFrame.new(0, size.Y + 0.05, 0), Color = Color3.fromRGB(100, 72, 54), Material = Enum.Material.Ground })
	local count = math.max(2, math.floor(size.X * size.Z / 6))
	for i = 1, count do
		local x = ((i * 0.618) % 1 - 0.5) * (size.X - 1.4)
		local z = ((i * 0.381) % 1 - 0.5) * (size.Z - 1.4)
		P(parent, { Name = "Flower", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = cframe * CFrame.new(x, size.Y + 0.6, z), Shape = Enum.PartType.Ball, Color = pick(rng, FLOWERS), CanCollide = false, CastShadow = false })
	end
end

function Decor.CafeTable(parent: Instance, position: Vector3, umbrellaColor: Color3)
	local top, topCF = vcyl(position + Vector3.new(0, 2.6, 0), 0.2, 3)
	P(parent, { Name = "TableTop", Size = top, CFrame = topCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(245, 245, 245) })
	local leg, legCF = vcyl(position + Vector3.new(0, 1.3, 0), 2.6, 0.3)
	P(parent, { Name = "TableLeg", Size = leg, CFrame = legCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(60, 60, 66), Material = Enum.Material.Metal })
	local pole, poleCF = vcyl(position + Vector3.new(0, 4.5, 0), 4, 0.2)
	P(parent, { Name = "UmbrellaPole", Size = pole, CFrame = poleCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(240, 240, 240), CanCollide = false })
	for i = 0, 5 do
		P(parent, {
			Name = "Umbrella",
			Class = "WedgePart",
			Size = Vector3.new(2.2, 1, 2.6),
			CFrame = CFrame.new(position + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, i * math.pi / 3, 0) * CFrame.new(0, 0, -1.3),
			Color = if i % 2 == 0 then umbrellaColor else Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Fabric,
			CanCollide = false,
		})
	end
	for _, angle in ipairs({ 0, math.pi }) do
		local chair = position + Vector3.new(math.cos(angle) * 2.6, 0, math.sin(angle) * 2.6)
		P(parent, { Name = "Chair", Size = Vector3.new(1.4, 0.3, 1.4), CFrame = CFrame.new(chair + Vector3.new(0, 1.6, 0)), Color = umbrellaColor })
		P(parent, { Name = "ChairLeg", Size = Vector3.new(0.25, 1.5, 0.25), CFrame = CFrame.new(chair + Vector3.new(0, 0.75, 0)), Color = Color3.fromRGB(60, 60, 66), Material = Enum.Material.Metal })
	end
end

function Decor.FlagPole(parent: Instance, position: Vector3, height: number, color: Color3)
	local pole, poleCF = vcyl(position + Vector3.new(0, height / 2, 0), height, 0.4)
	P(parent, { Name = "FlagPole", Size = pole, CFrame = poleCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(230, 230, 236), Material = Enum.Material.Metal })
	P(parent, { Name = "PoleTop", Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(position + Vector3.new(0, height + 0.3, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(240, 200, 80), Material = Enum.Material.Metal })
	P(parent, { Name = "Flag", Size = Vector3.new(0.1, 2.6, 4), CFrame = CFrame.new(position + Vector3.new(0, height - 1.5, 2.1)), Color = color, Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
end

function Decor.Banner(parent: Instance, cframe: CFrame, color: Color3)
	P(parent, { Name = "Banner", Size = Vector3.new(3, 6, 0.1), CFrame = cframe, Color = color, Material = Enum.Material.Fabric, CanCollide = false })
	P(parent, { Name = "BannerTip", Class = "WedgePart", Size = Vector3.new(0.1, 1.4, 1.5), CFrame = cframe * CFrame.new(0.75, -3.7, 0) * CFrame.Angles(0, math.rad(90), math.rad(180)), Color = color, Material = Enum.Material.Fabric, CanCollide = false })
	P(parent, { Name = "BannerTip", Class = "WedgePart", Size = Vector3.new(0.1, 1.4, 1.5), CFrame = cframe * CFrame.new(-0.75, -3.7, 0) * CFrame.Angles(0, math.rad(-90), math.rad(180)), Color = color, Material = Enum.Material.Fabric, CanCollide = false })
end

function Decor.Cone(parent: Instance, position: Vector3)
	P(parent, { Name = "ConeBase", Size = Vector3.new(1.6, 0.2, 1.6), CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)), Color = Color3.fromRGB(255, 120, 40) })
	for i = 0, 2 do
		local size, cf = vcyl(position + Vector3.new(0, 0.45 + i * 0.6, 0), 0.6, 1.1 - i * 0.3)
		P(parent, { Name = "Cone", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = if i == 1 then Color3.fromRGB(250, 250, 250) else Color3.fromRGB(255, 120, 40) })
	end
end

function Decor.TireStack(parent: Instance, position: Vector3, count: number?)
	for i = 0, (count or 3) - 1 do
		local size, cf = vcyl(position + Vector3.new(0, 0.6 + i * 1.1, 0), 1.1, 3)
		P(parent, { Name = "Tire", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(34, 34, 38), Material = Enum.Material.Rubber })
	end
end

function Decor.Crate(parent: Instance, cframe: CFrame, size: number?)
	local s = size or 3
	local crate = P(parent, { Name = "Crate", Size = Vector3.one * s, CFrame = cframe * CFrame.new(0, s / 2, 0), Color = Color3.fromRGB(176, 128, 76), Material = Enum.Material.WoodPlanks })
	crate:SetAttribute("AssetKind", "Crate")
	return crate
end

-- Low-poly car
function Decor.Car(parent: Instance, cframe: CFrame, color: Color3)
	local model = Instance.new("Model")
	model.Name = "ParkedCar"
	model:SetAttribute("AssetKind", "Car")
	model.Parent = parent
	P(model, { Name = "Body", Size = Vector3.new(5, 1.6, 10), CFrame = cframe * CFrame.new(0, 1.6, 0), Color = color, Reflectance = 0.05 })
	P(model, { Name = "Cabin", Size = Vector3.new(4.4, 1.5, 5), CFrame = cframe * CFrame.new(0, 3.1, 0.6), Color = Color3.fromRGB(60, 80, 110), Material = Enum.Material.Glass, Transparency = 0.15 })
	P(model, { Name = "Roof", Size = Vector3.new(4.5, 0.3, 4.4), CFrame = cframe * CFrame.new(0, 4, 0.6), Color = color })
	for _, x in ipairs({ -2.4, 2.4 }) do
		for _, z in ipairs({ -3.2, 3.2 }) do
			P(model, { Name = "Wheel", Size = Vector3.new(0.8, 2, 2), CFrame = cframe * CFrame.new(x, 1, z), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Rubber })
		end
	end
	for _, x in ipairs({ -1.6, 1.6 }) do
		P(model, { Name = "Headlight", Size = Vector3.new(1, 0.4, 0.1), CFrame = cframe * CFrame.new(x, 1.8, -5), Color = Color3.fromRGB(255, 250, 220), Material = Enum.Material.Neon, CanCollide = false })
		P(model, { Name = "Taillight", Size = Vector3.new(1, 0.4, 0.1), CFrame = cframe * CFrame.new(x, 1.8, 5), Color = Color3.fromRGB(255, 50, 50), Material = Enum.Material.Neon, CanCollide = false })
	end
	model.WorldPivot = cframe
	return model
end

------------------------------------------------------------------------
-- Buildings & ground
------------------------------------------------------------------------

--[[
	Low-poly building with window bands.
	opts: Roof "Flat" | "Gable", Floors, WindowColor, TrimColor, Awning (Color3), Door
]]
function Decor.Building(parent: Instance, cframe: CFrame, size: Vector3, color: Color3, opts)
	local options = opts or {}
	local model = Instance.new("Model")
	model.Name = "Building"
	model.Parent = parent
	local trim = options.TrimColor or Color3.fromRGB(245, 240, 232)
	local glass = options.WindowColor or Color3.fromRGB(150, 200, 235)
	P(model, { Name = "Walls", Size = size, CFrame = cframe * CFrame.new(0, size.Y / 2, 0), Color = color, Material = Enum.Material.Plaster })
	local floors = options.Floors or math.max(1, math.floor(size.Y / 7))
	local floorHeight = size.Y / floors
	for floor = 1, floors do
		local y = (floor - 0.5) * floorHeight + 0.6
		-- Front window band with mullions
		P(model, { Name = "Windows", Size = Vector3.new(size.X * 0.82, floorHeight * 0.42, 0.2), CFrame = cframe * CFrame.new(0, y, -size.Z / 2 - 0.06), Color = glass, Material = Enum.Material.Glass, Transparency = 0.05, CanCollide = false })
		local mullions = math.max(1, math.floor(size.X / 4))
		for m = 1, mullions - 1 do
			local x = -size.X * 0.41 + m * (size.X * 0.82 / mullions)
			P(model, { Name = "Mullion", Size = Vector3.new(0.3, floorHeight * 0.44, 0.3), CFrame = cframe * CFrame.new(x, y, -size.Z / 2 - 0.12), Color = trim, CanCollide = false })
		end
		P(model, { Name = "Sill", Size = Vector3.new(size.X * 0.86, 0.3, 0.5), CFrame = cframe * CFrame.new(0, y - floorHeight * 0.23, -size.Z / 2 - 0.2), Color = trim, CanCollide = false })
		-- Side windows
		for _, side in ipairs({ -1, 1 }) do
			P(model, { Name = "SideWindows", Size = Vector3.new(0.2, floorHeight * 0.42, size.Z * 0.7), CFrame = cframe * CFrame.new(side * (size.X / 2 + 0.06), y, 0), Color = glass, Material = Enum.Material.Glass, Transparency = 0.05, CanCollide = false })
		end
	end
	P(model, { Name = "Cornice", Size = Vector3.new(size.X + 0.8, 0.8, size.Z + 0.8), CFrame = cframe * CFrame.new(0, size.Y + 0.4, 0), Color = trim })
	if options.Roof == "Gable" then
		local roofColor = options.RoofColor or Color3.fromRGB(176, 80, 66)
		local half = size.Z / 2 + 0.6
		P(model, { Name = "Roof", Class = "WedgePart", Size = Vector3.new(size.X + 1.2, size.Z * 0.35, half), CFrame = cframe * CFrame.new(0, size.Y + 0.8 + size.Z * 0.175, -half / 2), Color = roofColor, Material = Enum.Material.Slate })
		P(model, { Name = "Roof", Class = "WedgePart", Size = Vector3.new(size.X + 1.2, size.Z * 0.35, half), CFrame = cframe * CFrame.new(0, size.Y + 0.8 + size.Z * 0.175, half / 2) * CFrame.Angles(0, math.pi, 0), Color = roofColor, Material = Enum.Material.Slate })
	end
	if options.Door ~= false then
		P(model, { Name = "Door", Size = Vector3.new(3, 5.5, 0.3), CFrame = cframe * CFrame.new(0, 2.75, -size.Z / 2 - 0.1), Color = options.DoorColor or Color3.fromRGB(110, 70, 46), Material = Enum.Material.Wood, CanCollide = false })
	end
	if options.Awning then
		P(model, { Name = "Awning", Class = "WedgePart", Size = Vector3.new(size.X * 0.7, 1, 2.4), CFrame = cframe * CFrame.new(0, 6.6, -size.Z / 2 - 1.2), Color = options.Awning, Material = Enum.Material.Fabric, CanCollide = false })
	end
	return model
end

-- Road strip along its local Z with dashed center line and curbs/sidewalks
function Decor.Road(parent: Instance, cframe: CFrame, length: number, width: number, opts)
	local options = opts or {}
	P(parent, { Name = "Road", Size = Vector3.new(width, 0.2, length), CFrame = cframe * CFrame.new(0, 0.1, 0), Color = Color3.fromRGB(58, 60, 66), Material = Enum.Material.Asphalt })
	if options.Dashes ~= false then
		local dashes = math.floor(length / 8)
		for i = 0, dashes - 1 do
			P(parent, { Name = "Dash", Size = Vector3.new(0.4, 0.22, 3.5), CFrame = cframe * CFrame.new(0, 0.12, -length / 2 + (i + 0.5) * (length / dashes)), Color = Color3.fromRGB(250, 240, 200), CanCollide = false, CastShadow = false })
		end
	end
	if options.Sidewalks ~= false then
		for _, side in ipairs({ -1, 1 }) do
			P(parent, { Name = "Sidewalk", Size = Vector3.new(4, 0.5, length), CFrame = cframe * CFrame.new(side * (width / 2 + 2), 0.25, 0), Color = Color3.fromRGB(196, 192, 186), Material = Enum.Material.Concrete })
		end
	end
end

function Decor.Crosswalk(parent: Instance, cframe: CFrame, width: number)
	for i = -3, 3 do
		P(parent, { Name = "Stripe", Size = Vector3.new(1.2, 0.23, width * 0.25), CFrame = cframe * CFrame.new(i * 2, 0.12, 0), Color = Color3.fromRGB(250, 250, 250), CanCollide = false, CastShadow = false })
	end
end

function Decor.Hedge(parent: Instance, cframe: CFrame, size: Vector3)
	P(parent, { Name = "Hedge", Size = size, CFrame = cframe * CFrame.new(0, size.Y / 2, 0), Color = Color3.fromRGB(64, 136, 62), Material = Enum.Material.Grass })
end

function Decor.Topiary(parent: Instance, position: Vector3)
	local pot, potCF = vcyl(position + Vector3.new(0, 0.9, 0), 1.8, 2.4)
	P(parent, { Name = "Pot", Size = pot, CFrame = potCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(226, 220, 210), Material = Enum.Material.Marble })
	local stem, stemCF = vcyl(position + Vector3.new(0, 2.6, 0), 1.8, 0.4)
	P(parent, { Name = "Stem", Size = stem, CFrame = stemCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(110, 76, 50), Material = Enum.Material.Wood })
	P(parent, { Name = "Topiary", Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(position + Vector3.new(0, 4.6, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(70, 146, 66), Material = Enum.Material.Grass })
end

-- Tall pole with a downward spotlight aimed at `target`
function Decor.Spotlight(parent: Instance, position: Vector3, target: Vector3, color: Color3?)
	local height = 18
	local pole, poleCF = vcyl(position + Vector3.new(0, height / 2, 0), height, 0.6)
	P(parent, { Name = "SpotPole", Size = pole, CFrame = poleCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.Metal })
	local head = position + Vector3.new(0, height, 0)
	local lamp = P(parent, { Name = "SpotHead", Size = Vector3.new(1.6, 1.2, 2), CFrame = CFrame.lookAt(head, target), Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.Metal })
	local lens = P(parent, { Name = "SpotLens", Size = Vector3.new(1.3, 1, 0.1), CFrame = CFrame.lookAt(head, target) * CFrame.new(0, 0, -1.02), Color = color or Color3.fromRGB(255, 250, 230), Material = Enum.Material.Neon, CanCollide = false })
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = 50
	spot.Range = 60
	spot.Brightness = 3
	spot.Color = color or Color3.fromRGB(255, 250, 230)
	spot.Parent = lens
	return lamp
end

-- Chrome posts with sagging velvet ropes (non-colliding, purely decorative)
function Decor.Stanchions(parent: Instance, points: { Vector3 }, ropeColor: Color3?)
	local rope = ropeColor or Color3.fromRGB(190, 30, 60)
	for index, point in ipairs(points) do
		local post, postCF = vcyl(point + Vector3.new(0, 1.6, 0), 3.2, 0.3)
		P(parent, { Name = "StanchionPost", Size = post, CFrame = postCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(220, 222, 230), Material = Enum.Material.Metal, Reflectance = 0.2, CanCollide = false })
		local foot, footCF = vcyl(point + Vector3.new(0, 0.1, 0), 0.2, 1.2)
		P(parent, { Name = "StanchionFoot", Size = foot, CFrame = footCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(220, 222, 230), Material = Enum.Material.Metal, CanCollide = false })
		P(parent, { Name = "StanchionTop", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(point + Vector3.new(0, 3.3, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(240, 200, 90), Material = Enum.Material.Metal, CanCollide = false })
		local nextPoint = points[index + 1]
		if nextPoint then
			local a = point + Vector3.new(0, 3, 0)
			local b = nextPoint + Vector3.new(0, 3, 0)
			local mid = (a + b) / 2 - Vector3.new(0, 0.7, 0)
			for _, segment in ipairs({ { a, mid }, { mid, b } }) do
				local from, to = segment[1], segment[2]
				P(parent, { Name = "Rope", Size = Vector3.new(0.22, 0.22, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = rope, Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
			end
		end
	end
end

-- Little food truck with an awning and a glowing menu board; front faces local -Z
function Decor.FoodTruck(parent: Instance, cframe: CFrame, color: Color3)
	local model = Instance.new("Model")
	model.Name = "FoodTruck"
	model.Parent = parent
	P(model, { Name = "Body", Size = Vector3.new(16, 8, 7), CFrame = cframe * CFrame.new(0, 5, 0), Color = color })
	P(model, { Name = "Cab", Size = Vector3.new(4.5, 5.5, 7), CFrame = cframe * CFrame.new(10.2, 3.75, 0), Color = color })
	P(model, { Name = "Windshield", Size = Vector3.new(0.2, 2.4, 6), CFrame = cframe * CFrame.new(12.5, 5, 0), Color = Color3.fromRGB(60, 80, 110), Material = Enum.Material.Glass, Transparency = 0.2 })
	P(model, { Name = "Stripe", Size = Vector3.new(16.1, 1, 7.1), CFrame = cframe * CFrame.new(0, 3, 0), Color = Color3.fromRGB(255, 255, 255) })
	P(model, { Name = "Window", Size = Vector3.new(9, 3, 0.2), CFrame = cframe * CFrame.new(-1, 6, -3.55), Color = Color3.fromRGB(255, 230, 170), Material = Enum.Material.Neon })
	P(model, { Name = "Counter", Size = Vector3.new(9.5, 0.4, 1.4), CFrame = cframe * CFrame.new(-1, 4.4, -4.1), Color = Color3.fromRGB(240, 240, 240) })
	for i = 0, 4 do
		P(model, { Name = "Awning", Size = Vector3.new(2, 0.2, 3), CFrame = cframe * CFrame.new(-5 + i * 2, 8.4, -4.8) * CFrame.Angles(math.rad(-18), 0, 0), Color = if i % 2 == 0 then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(240, 90, 110), Material = Enum.Material.Fabric, CanCollide = false })
	end
	for _, x in ipairs({ -5, 5, 10 }) do
		for _, z in ipairs({ -3.6, 3.6 }) do
			P(model, { Name = "Wheel", Size = Vector3.new(1, 2.4, 2.4), CFrame = cframe * CFrame.new(x, 1.2, z) * CFrame.Angles(0, math.rad(90), 0), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Rubber })
		end
	end
	local sign = P(model, { Name = "MenuSign", Size = Vector3.new(8, 2, 0.4), CFrame = cframe * CFrame.new(-1, 10.2, -2), Color = Color3.fromRGB(30, 30, 36) })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🍔 🍟 🥤"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	light(sign, 16, 1.2, Color3.fromRGB(255, 220, 170))
	return model
end

-- White garden gazebo with a tiered roof
function Decor.Gazebo(parent: Instance, position: Vector3, radius: number?, roofColor: Color3?)
	local r = radius or 8
	local model = Instance.new("Model")
	model.Name = "Gazebo"
	model.Parent = parent
	local white = Color3.fromRGB(250, 248, 242)
	local floor, floorCF = vcyl(position + Vector3.new(0, 0.6, 0), 1.2, r * 2 + 1)
	P(model, { Name = "GazeboFloor", Size = floor, CFrame = floorCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(220, 214, 204), Material = Enum.Material.Marble })
	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		local post, postCF = vcyl(position + Vector3.new(math.cos(angle) * r, 4.7, math.sin(angle) * r), 7, 0.7)
		P(model, { Name = "GazeboPost", Size = post, CFrame = postCF, Shape = Enum.PartType.Cylinder, Color = white })
	end
	local ring, ringCF = vcyl(position + Vector3.new(0, 8.5, 0), 0.8, r * 2 + 1.5)
	P(model, { Name = "GazeboRing", Size = ring, CFrame = ringCF, Shape = Enum.PartType.Cylinder, Color = white })
	local roof = roofColor or Color3.fromRGB(110, 170, 150)
	for tier = 0, 3 do
		local tierSize, tierCF = vcyl(position + Vector3.new(0, 9.2 + tier * 0.9, 0), 0.9, (r * 2 + 3) * (1 - tier * 0.24))
		P(model, { Name = "GazeboRoof", Size = tierSize, CFrame = tierCF, Shape = Enum.PartType.Cylinder, Color = roof, Material = Enum.Material.Slate })
	end
	P(model, { Name = "GazeboTop", Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(position + Vector3.new(0, 13, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(240, 200, 90), Material = Enum.Material.Metal })
	local lantern = P(model, { Name = "Lantern", Size = Vector3.new(1, 1.3, 1), CFrame = CFrame.new(position + Vector3.new(0, 7.4, 0)), Color = Color3.fromRGB(255, 226, 170), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	light(lantern, 16, 1)
	return model
end

-- Small market stall with a striped canopy and a sign; front faces local -Z
function Decor.Stall(parent: Instance, cframe: CFrame, color: Color3, text: string)
	local model = Instance.new("Model")
	model.Name = "Stall"
	model.Parent = parent
	P(model, { Name = "StallCounter", Size = Vector3.new(6, 3, 2.4), CFrame = cframe * CFrame.new(0, 1.5, 0), Color = Color3.fromRGB(246, 240, 228), Material = Enum.Material.WoodPlanks })
	P(model, { Name = "StallTop", Size = Vector3.new(6.4, 0.3, 2.8), CFrame = cframe * CFrame.new(0, 3.15, 0), Color = color })
	for _, x in ipairs({ -2.9, 2.9 }) do
		P(model, { Name = "StallPost", Size = Vector3.new(0.3, 4, 0.3), CFrame = cframe * CFrame.new(x, 5, 1), Color = Color3.fromRGB(246, 240, 228) })
	end
	for i = 0, 3 do
		P(model, { Name = "StallCanopy", Size = Vector3.new(1.6, 0.2, 3.4), CFrame = cframe * CFrame.new(-2.4 + i * 1.6, 7.1, -0.2) * CFrame.Angles(math.rad(-14), 0, 0), Color = if i % 2 == 0 then color else Color3.fromRGB(255, 255, 255), Material = Enum.Material.Fabric, CanCollide = false })
	end
	local sign = P(model, { Name = "StallSign", Size = Vector3.new(5.6, 1.2, 0.2), CFrame = cframe * CFrame.new(0, 2, -1.25), Color = color })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.4
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	return model
end

-- Tennis court with lines, a net and a low fence; length along local Z
function Decor.TennisCourt(parent: Instance, cframe: CFrame)
	local model = Instance.new("Model")
	model.Name = "TennisCourt"
	model.Parent = parent
	P(model, { Name = "CourtSurround", Size = Vector3.new(26, 0.14, 44), CFrame = cframe * CFrame.new(0, 0.07, 0), Color = Color3.fromRGB(70, 140, 100), Material = Enum.Material.Concrete })
	P(model, { Name = "Court", Size = Vector3.new(18, 0.16, 36), CFrame = cframe * CFrame.new(0, 0.08, 0), Color = Color3.fromRGB(60, 110, 170), Material = Enum.Material.Concrete })
	local white = Color3.fromRGB(250, 250, 250)
	for _, def in ipairs({
		{ Vector3.new(18, 0.02, 0.3), Vector3.new(0, 0, 18) }, { Vector3.new(18, 0.02, 0.3), Vector3.new(0, 0, -18) },
		{ Vector3.new(0.3, 0.02, 36), Vector3.new(9, 0, 0) }, { Vector3.new(0.3, 0.02, 36), Vector3.new(-9, 0, 0) },
		{ Vector3.new(0.3, 0.02, 36), Vector3.new(6.8, 0, 0) }, { Vector3.new(0.3, 0.02, 36), Vector3.new(-6.8, 0, 0) },
		{ Vector3.new(13.6, 0.02, 0.3), Vector3.new(0, 0, 10) }, { Vector3.new(13.6, 0.02, 0.3), Vector3.new(0, 0, -10) },
		{ Vector3.new(0.3, 0.02, 20), Vector3.new(0, 0, 0) },
	}) do
		P(model, { Name = "CourtLine", Size = def[1], CFrame = cframe * CFrame.new(def[2] + Vector3.new(0, 0.17, 0)), Color = white, CanCollide = false, CastShadow = false })
	end
	P(model, { Name = "Net", Size = Vector3.new(20, 1.8, 0.1), CFrame = cframe * CFrame.new(0, 1.05, 0), Color = Color3.fromRGB(30, 30, 34), Transparency = 0.35, CanCollide = false })
	P(model, { Name = "NetTape", Size = Vector3.new(20, 0.2, 0.15), CFrame = cframe * CFrame.new(0, 2, 0), Color = white, CanCollide = false })
	for _, x in ipairs({ -10.2, 10.2 }) do
		P(model, { Name = "NetPost", Size = Vector3.new(0.3, 2.2, 0.3), CFrame = cframe * CFrame.new(x, 1.1, 0), Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.Metal })
	end
	return model
end

-- Metal trash can where players empty their sticker bags. The body carries the SellPoint
-- attribute (walk up to sell) and a prompt (F) as a fallback.
function Decor.TrashCan(parent: Instance, position: Vector3, scale: number?)
	local s = scale or 1
	local model = Instance.new("Model")
	model.Name = "TrashCan"
	model.Parent = parent
	local metal = Color3.fromRGB(150, 158, 170)
	local dark = Color3.fromRGB(112, 120, 132)
	local body, bodyCF = vcyl(position + Vector3.new(0, 2.7 * s, 0), 5 * s, 4.2 * s)
	local bodyPart = P(model, { Name = "Body", Size = body, CFrame = bodyCF, Shape = Enum.PartType.Cylinder, Color = metal, Material = Enum.Material.Metal, Reflectance = 0.05 })
	local base, baseCF = vcyl(position + Vector3.new(0, 0.2 * s, 0), 0.4 * s, 3.8 * s)
	P(model, { Name = "Base", Size = base, CFrame = baseCF, Shape = Enum.PartType.Cylinder, Color = dark, Material = Enum.Material.Metal })
	for _, y in ipairs({ 1.2, 2.7, 4.2 }) do
		local rib, ribCF = vcyl(position + Vector3.new(0, y * s, 0), 0.3 * s, 4.45 * s)
		P(model, { Name = "Rib", Size = rib, CFrame = ribCF, Shape = Enum.PartType.Cylinder, Color = dark, Material = Enum.Material.Metal })
	end
	local lid, lidCF = vcyl(position + Vector3.new(0, 5.45 * s, 0), 0.5 * s, 4.8 * s)
	P(model, { Name = "Lid", Size = lid, CFrame = lidCF, Shape = Enum.PartType.Cylinder, Color = metal, Material = Enum.Material.Metal, Reflectance = 0.05 })
	local dome, domeCF = vcyl(position + Vector3.new(0, 5.85 * s, 0), 0.35 * s, 3.6 * s)
	P(model, { Name = "LidTop", Size = dome, CFrame = domeCF, Shape = Enum.PartType.Cylinder, Color = dark, Material = Enum.Material.Metal })
	P(model, { Name = "Handle", Size = Vector3.new(1.8 * s, 0.35 * s, 0.4 * s), CFrame = CFrame.new(position + Vector3.new(0, 6.3 * s, 0)), Color = dark, Material = Enum.Material.Metal })
	for _, x in ipairs({ -0.8, 0.8 }) do
		P(model, { Name = "HandlePost", Size = Vector3.new(0.3 * s, 0.5 * s, 0.3 * s), CFrame = CFrame.new(position + Vector3.new(x * s, 6.05 * s, 0)), Color = dark, Material = Enum.Material.Metal })
	end
	-- Green sell zone painted on the ground
	local ring, ringCF = vcyl(position + Vector3.new(0, 0.07, 0), 0.06, 11 * s)
	P(model, { Name = "SellZone", Size = ring, CFrame = ringCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(90, 220, 120), Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false, CastShadow = false })
	local inner, innerCF = vcyl(position + Vector3.new(0, 0.08, 0), 0.06, 10 * s)
	P(model, { Name = "SellZoneInner", Size = inner, CFrame = innerCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(60, 150, 80), Material = Enum.Material.SmoothPlastic, Transparency = 0.6, CanCollide = false, CastShadow = false })

	bodyPart:SetAttribute("SellPoint", true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Throw away stickers"
	prompt.ObjectText = "Trash Can"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", "Sell")
	prompt.Parent = bodyPart

	local anchor = P(model, { Name = "SignAnchor", Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(position + Vector3.new(0, 8.4 * s, 0)), Transparency = 1, CanCollide = false, CastShadow = false })
	anchor.CanQuery = false
	local sign = Instance.new("BillboardGui")
	sign.Name = "SellSign"
	sign.Size = UDim2.fromScale(6 * s, 2 * s)
	sign.LightInfluence = 0
	sign.MaxDistance = 140
	sign.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = "🗑️ SELL"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(110, 255, 130)
	label.Parent = sign
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(20, 60, 30)
	stroke.Parent = label
	return model
end

-- Little shop stall in a level: its prompt opens the shop window on the client
function Decor.ShopStall(parent: Instance, cframe: CFrame)
	local stall = Decor.Stall(parent, cframe, Color3.fromRGB(70, 170, 255), "🛒 SHOP")
	local counter = stall:FindFirstChild("StallCounter")
	if counter then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.ActionText = "Open shop"
		prompt.ObjectText = "Shop"
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("OpenUI", "Shop")
		prompt.Parent = counter
	end
	return stall
end

-- Wooden notice board with lines of text; front faces local -Z
function Decor.NoticeBoard(parent: Instance, cframe: CFrame, title: string, lines: { string })
	local model = Instance.new("Model")
	model.Name = "NoticeBoard"
	model.Parent = parent
	local wood = Color3.fromRGB(150, 100, 60)
	for _, x in ipairs({ -4.6, 4.6 }) do
		P(model, { Name = "Leg", Size = Vector3.new(0.6, 8, 0.6), CFrame = cframe * CFrame.new(x, 4, 0), Color = wood, Material = Enum.Material.Wood })
	end
	local board = P(model, { Name = "Board", Size = Vector3.new(9, 5.6, 0.4), CFrame = cframe * CFrame.new(0, 5, 0), Color = Color3.fromRGB(196, 150, 100), Material = Enum.Material.WoodPlanks })
	P(model, { Name = "Roof", Class = "WedgePart", Size = Vector3.new(10.4, 0.8, 0.8), CFrame = cframe * CFrame.new(0, 8.2, -0.4), Color = Color3.fromRGB(120, 70, 40), Material = Enum.Material.Wood })
	P(model, { Name = "Roof", Class = "WedgePart", Size = Vector3.new(10.4, 0.8, 0.8), CFrame = cframe * CFrame.new(0, 8.2, 0.4) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(120, 70, 40), Material = Enum.Material.Wood })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = board
	local paper = Instance.new("Frame")
	paper.Size = UDim2.new(1, -24, 1, -24)
	paper.Position = UDim2.fromOffset(12, 12)
	paper.BackgroundColor3 = Color3.fromRGB(250, 244, 226)
	paper.Parent = gui
	Instance.new("UICorner", paper).CornerRadius = UDim.new(0, 10)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = paper
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = paper
	local function line(text: string, size: number, color: Color3, order: number)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, size)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.Text = text
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = color
		label.LayoutOrder = order
		label.Parent = paper
	end
	line(title, 44, Color3.fromRGB(200, 60, 60), 0)
	for i, text in ipairs(lines) do
		line(text, 30, Color3.fromRGB(60, 44, 30), i)
	end
	return model
end

-- Neon-lit sign board
function Decor.NeonSign(parent: Instance, cframe: CFrame, text: string, color: Color3, width: number?)
	local w = width or 16
	local board = P(parent, { Name = "Sign", Size = Vector3.new(w, 3.6, 0.4), CFrame = cframe, Color = Color3.fromRGB(22, 22, 28) })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 30
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = gui
	light(board, 14, 1, color)
	return board
end

return Decor
