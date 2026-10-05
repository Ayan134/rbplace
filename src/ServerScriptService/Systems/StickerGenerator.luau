--[[
	StickerGenerator
	Automatically covers a level model with stickers.

	    Target Model -> Detect Surfaces -> Generate Positions -> (occlusion test) -> Assign Sticker Data

	Surfaces are the BaseParts inside `Model.StickerSurfaces` (falls back to `Model.Geometry`).
	Per-part attributes control placement:
	  Faces          "Top,Bottom,Front,Back,Left,Right" for blocks, "Side,Ends" for cylinders,
	                 "Slope,Back,Bottom,Sides" for wedges. Default: everything except Bottom.
	  MinAngle       min angle (deg) between surface normal and world up. Default 0
	  MaxAngle       max angle (deg) between surface normal and world up. Default 180
	  StickerWeight  relative sticker density. Default 1
	  HardToReach    force the hard-to-reach flag (more stickers on Hard/Extreme, bonus reward)
	  Zone           display name ("Roof", "Door", ...)

	Generation options:
	  Count, Seed, Difficulty (DifficultyConfig entry), Level (LevelConfig entry),
	  LuckBonus (party luck, boosts rare chance), GroundY, ExtraObstacles ({Instance})

	Supported shapes: Block, Wedge, Cylinder, Ball (MeshParts use their bounding box).
	Nothing here creates Instances: the output is plain data. Clients render it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local StickerConfig = require(Shared.StickerConfig)
local Utility = require(Shared.Utility)

local StickerGenerator = {}

type Face = {
	Id: number,
	Part: BasePart,
	Kind: string, -- "Rect" | "Cylinder" | "Disc" | "Sphere"
	CFrame: CFrame, -- Rect/Disc: Y = normal, centered. Cylinder: part CFrame (axis X). Sphere: center.
	SpanX: number,
	SpanZ: number,
	Radius: number,
	Length: number,
	Clip: string?, -- "WedgeSidePos" | "WedgeSideNeg"
	Area: number,
	Weight: number,
	Hard: boolean,
	Zone: string,
	MinDot: number, -- cos(MaxAngle)
	MaxDot: number, -- cos(MinAngle)
	BaseSize: number,
	ZMin: number?, -- Sphere: lowest sampled height (-1..1, local Y) so buried parts are skipped
}

local function parseFaces(part: BasePart, defaults: { string }): { [string]: boolean }
	local attribute = part:GetAttribute("Faces")
	local list = {}
	if type(attribute) == "string" and #attribute > 0 then
		for name in attribute:gmatch("[^,%s]+") do
			list[name] = true
		end
	else
		for _, name in ipairs(defaults) do
			list[name] = true
		end
	end
	return list
end

local function shapeOf(part: BasePart): string
	if part:IsA("WedgePart") then
		return "Wedge"
	elseif part:IsA("Part") then
		if part.Shape == Enum.PartType.Cylinder then
			return "Cylinder"
		elseif part.Shape == Enum.PartType.Ball then
			return "Ball"
		elseif part.Shape == Enum.PartType.Wedge then
			return "Wedge"
		end
	end
	return "Block"
end

local RECT_ROTATIONS = {
	Top = CFrame.new(),
	Bottom = CFrame.Angles(math.pi, 0, 0),
	Front = CFrame.Angles(-math.pi / 2, 0, 0),
	Back = CFrame.Angles(math.pi / 2, 0, 0),
	Right = CFrame.Angles(0, 0, -math.pi / 2),
	Left = CFrame.Angles(0, 0, math.pi / 2),
}

-- Detects every stickerable face in the model.
function StickerGenerator.DetectSurfaces(model: Model, groundY: number, difficulty): { Face }
	local container = model:FindFirstChild("StickerSurfaces") or model:FindFirstChild("Geometry") or model
	local faces: { Face } = {}

	local function addFace(face)
		face.Id = #faces + 1
		table.insert(faces, face)
	end

	for _, part in ipairs(container:GetDescendants()) do
		if not part:IsA("BasePart") or part.Transparency >= 1 then
			continue
		end
		local cf = part.CFrame
		local size = part.Size
		local weightAttr = part:GetAttribute("StickerWeight")
		local baseWeight = if type(weightAttr) == "number" then weightAttr else 1
		if baseWeight <= 0 then
			continue
		end
		local hardAttr = part:GetAttribute("HardToReach") == true
		local zoneAttr = part:GetAttribute("Zone")
		local zone = if type(zoneAttr) == "string" then zoneAttr else part.Name
		local minAngle = part:GetAttribute("MinAngle")
		local maxAngle = part:GetAttribute("MaxAngle")
		local maxDot = math.cos(math.rad(if type(minAngle) == "number" then minAngle else 0))
		local minDot = math.cos(math.rad(if type(maxAngle) == "number" then maxAngle else 180))

		local function base(kind: string, faceCF: CFrame, area: number)
			return {
				Id = 0,
				Part = part,
				Kind = kind,
				CFrame = faceCF,
				SpanX = 0,
				SpanZ = 0,
				Radius = 0,
				Length = 0,
				Clip = nil,
				Area = area,
				Weight = 0,
				Hard = hardAttr,
				Zone = zone,
				MinDot = minDot,
				MaxDot = maxDot,
				BaseSize = 1,
			}
		end

		local shape = shapeOf(part)
		if shape == "Block" then
			local allowed = parseFaces(part, { "Top", "Front", "Back", "Left", "Right" })
			local defs = {
				Top = { Vector3.new(0, size.Y / 2, 0), size.X, size.Z },
				Bottom = { Vector3.new(0, -size.Y / 2, 0), size.X, size.Z },
				Front = { Vector3.new(0, 0, -size.Z / 2), size.X, size.Y },
				Back = { Vector3.new(0, 0, size.Z / 2), size.X, size.Y },
				Right = { Vector3.new(size.X / 2, 0, 0), size.Y, size.Z },
				Left = { Vector3.new(-size.X / 2, 0, 0), size.Y, size.Z },
			}
			for name, def in pairs(defs) do
				if allowed[name] then
					local faceCF = cf * CFrame.new(def[1]) * RECT_ROTATIONS[name]
					local dot = faceCF.UpVector.Y
					if dot >= minDot - 1e-3 and dot <= maxDot + 1e-3 and def[2] > 0.3 and def[3] > 0.3 then
						local face = base("Rect", faceCF, def[2] * def[3])
						face.SpanX = def[2]
						face.SpanZ = def[3]
						addFace(face)
					end
				end
			end
		elseif shape == "Wedge" then
			local allowed = parseFaces(part, { "Slope", "Back", "Sides" })
			local slopeLength = math.sqrt(size.Y * size.Y + size.Z * size.Z)
			if allowed.Slope then
				local normal = Vector3.new(0, size.Z, -size.Y).Unit
				local faceCF = cf * CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, normal)
				local dot = faceCF.UpVector.Y
				if dot >= minDot - 1e-3 and dot <= maxDot + 1e-3 then
					local face = base("Rect", faceCF, size.X * slopeLength)
					face.SpanX = size.X
					face.SpanZ = slopeLength
					addFace(face)
				end
			end
			local rectDefs = {
				Back = { Vector3.new(0, 0, size.Z / 2), RECT_ROTATIONS.Back, size.X, size.Y },
				Bottom = { Vector3.new(0, -size.Y / 2, 0), RECT_ROTATIONS.Bottom, size.X, size.Z },
			}
			for name, def in pairs(rectDefs) do
				if allowed[name] then
					local faceCF = cf * CFrame.new(def[1]) * def[2]
					local dot = faceCF.UpVector.Y
					if dot >= minDot - 1e-3 and dot <= maxDot + 1e-3 then
						local face = base("Rect", faceCF, def[3] * def[4])
						face.SpanX = def[3]
						face.SpanZ = def[4]
						addFace(face)
					end
				end
			end
			if allowed.Sides then
				for _, sign in ipairs({ 1, -1 }) do
					local rotation = if sign > 0 then RECT_ROTATIONS.Right else RECT_ROTATIONS.Left
					local faceCF = cf * CFrame.new(sign * size.X / 2, 0, 0) * rotation
					local face = base("Rect", faceCF, size.Y * size.Z / 2)
					face.SpanX = size.Y
					face.SpanZ = size.Z
					face.Clip = if sign > 0 then "WedgeSidePos" else "WedgeSideNeg"
					addFace(face)
				end
			end
		elseif shape == "Cylinder" then
			local allowed = parseFaces(part, { "Side", "Ends" })
			local radius = math.min(size.Y, size.Z) / 2
			local length = size.X
			if allowed.Side then
				local face = base("Cylinder", cf, 2 * math.pi * radius * length)
				face.Radius = radius
				face.Length = length
				addFace(face)
			end
			if allowed.Ends then
				for _, sign in ipairs({ 1, -1 }) do
					local rotation = if sign > 0 then RECT_ROTATIONS.Right else RECT_ROTATIONS.Left
					local faceCF = cf * CFrame.new(sign * length / 2, 0, 0) * rotation
					local dot = faceCF.UpVector.Y
					if dot >= minDot - 1e-3 and dot <= maxDot + 1e-3 then
						local face = base("Disc", faceCF, math.pi * radius * radius)
						face.Radius = radius
						addFace(face)
					end
				end
			end
		elseif shape == "Ball" then
			local radius = math.min(size.X, size.Y, size.Z) / 2
			-- Only the part above the ground gets stickers (mounds are spheres sunk into the
			-- ground); sizing and sampling use that cap so coverage stays even.
			local zMin = -1
			if cf.UpVector.Y > 0.99 then
				zMin = math.clamp((groundY - cf.Position.Y) / radius, -1, 0.95)
			end
			local face = base("Sphere", cf, 2 * math.pi * radius * radius * (1 - zMin))
			face.Radius = radius
			face.ZMin = zMin
			addFace(face)
		end
	end

	-- Weights: area * density * hard-to-reach factor
	for _, face in ipairs(faces) do
		local centerY = face.CFrame.Position.Y - groundY
		if centerY > Config.Match.HardToReachHeight then
			face.Hard = true
		end
		if face.Kind == "Rect" and face.CFrame.UpVector.Y < -0.5 then
			face.Hard = true
		end
		local weightAttr = face.Part:GetAttribute("StickerWeight")
		local density = if type(weightAttr) == "number" then weightAttr else 1
		local hardFactor = if face.Hard then difficulty.HardToReachWeight else 1
		face.Weight = face.Area * density * hardFactor
	end
	return faces
end

-- Returns position, normal for local face coordinates u, v in [-1, 1].
local function samplePoint(face: Face, u: number, v: number): (Vector3?, Vector3?)
	if face.Kind == "Rect" then
		local x = u * face.SpanX / 2
		local z = v * face.SpanZ / 2
		if face.Clip then
			-- Wedge side triangle in the face's local (x = part Y, z = part Z) space.
			-- Inside when part-local y <= slope line.
			local partY = if face.Clip == "WedgeSidePos" then -x else x
			local height, depth = face.SpanX, face.SpanZ
			local slopeY = -height / 2 + (z + depth / 2) * height / depth
			if partY > slopeY then
				return nil, nil
			end
		end
		local cf = face.CFrame * CFrame.new(x, 0, z)
		return cf.Position, face.CFrame.UpVector
	elseif face.Kind == "Disc" then
		local r = math.sqrt((u + 1) / 2) * face.Radius
		local angle = (v + 1) * math.pi
		local cf = face.CFrame * CFrame.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		return cf.Position, face.CFrame.UpVector
	elseif face.Kind == "Cylinder" then
		local angle = (u + 1) * math.pi
		local x = v * face.Length / 2
		local localNormal = Vector3.new(0, math.cos(angle), math.sin(angle))
		local position = face.CFrame:PointToWorldSpace(Vector3.new(x, 0, 0) + localNormal * face.Radius)
		return position, face.CFrame:VectorToWorldSpace(localNormal)
	elseif face.Kind == "Sphere" then
		-- u -> height on the sphere (uniform area between ZMin and the top), v -> angle
		local zMin = face.ZMin or -1
		local z = zMin + (u + 1) / 2 * (1 - zMin)
		local angle = (v + 1) * math.pi
		local r = math.sqrt(math.max(0, 1 - z * z))
		local localNormal = Vector3.new(r * math.cos(angle), z, r * math.sin(angle))
		return face.CFrame:PointToWorldSpace(localNormal * face.Radius), face.CFrame:VectorToWorldSpace(localNormal)
	end
	return nil, nil
end

-- Maximum sticker extent that fits on the face.
local function faceSizeLimit(face: Face): number
	if face.Kind == "Rect" then
		return math.min(face.SpanX, face.SpanZ) * 0.98
	elseif face.Kind == "Disc" then
		return face.Radius * 1.4
	elseif face.Kind == "Cylinder" then
		-- Flat stickers on curved surfaces: keep them small enough to hug the curve
		return math.min(face.Length * 0.98, face.Radius * 0.85)
	else
		return face.Radius * 0.7
	end
end

local function pickType(rng: Random, difficulty, luckBonus: number, hard: boolean): string
	local entries = {}
	for _, id in ipairs(StickerConfig.Order) do
		local info = StickerConfig.Types[id]
		local weight
		if info.IsRare then
			if info.Special and not difficulty.SpecialStickers then
				weight = 0
			else
				weight = info.Weight * difficulty.RareChanceMultiplier * (1 + luckBonus) * (if hard then 1.5 else 1)
			end
		else
			weight = difficulty.SizeWeights[id] or info.Weight
		end
		table.insert(entries, { Weight = weight, Value = id })
	end
	return Utility.WeightedPick(rng, entries)
end

-- Main entry point. Returns an array of sticker records (server state).
function StickerGenerator.Generate(model: Model, options)
	local count: number = options.Count
	local seed: number = options.Seed or math.floor(os.clock() * 1000) % 2 ^ 30
	local difficulty = options.Difficulty
	local level = options.Level
	local luckBonus: number = math.clamp(options.LuckBonus or 0, 0, 3)
	local groundY: number = options.GroundY or model:GetPivot().Position.Y
	local rng = Random.new(seed)

	local faces = StickerGenerator.DetectSurfaces(model, groundY, difficulty)
	if #faces == 0 then
		warn("[StickerGenerator] No stickerable surfaces in " .. model.Name)
		return {}, seed
	end

	local totalWeight = 0
	for _, face in ipairs(faces) do
		totalWeight += face.Weight
	end

	-- Allocate counts per face (largest remainder method)
	local allocations = {}
	local remainders = {}
	local allocated = 0
	for i, face in ipairs(faces) do
		local exact = count * face.Weight / totalWeight
		local whole = math.floor(exact)
		allocations[i] = whole
		allocated += whole
		table.insert(remainders, { Index = i, Fraction = exact - whole })
	end
	table.sort(remainders, function(a, b)
		return a.Fraction > b.Fraction
	end)
	for i = 1, count - allocated do
		local entry = remainders[((i - 1) % #remainders) + 1]
		allocations[entry.Index] += 1
	end

	-- Base sticker size per face keeps coverage even regardless of density
	local sizeAdjust = Utility.Lerp(1, difficulty.SizeMultiplier, 0.5) * Config.Sticker.CoverageFactor
	for i, face in ipairs(faces) do
		local expected = math.max(count * face.Weight / totalWeight, 0.25)
		face.BaseSize = math.sqrt(face.Area / expected) * sizeAdjust
	end

	-- Occlusion test: a sticker must be visible from just in front of the surface
	local filter = { model:FindFirstChild("Geometry") or model, model:FindFirstChild("StickerSurfaces") or model }
	for _, extra in ipairs(options.ExtraObstacles or {}) do
		table.insert(filter, extra)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = filter

	local function visible(position: Vector3, normal: Vector3): boolean
		local origin = position + normal * 1.3
		local result = workspace:Raycast(origin, -normal * 1.45, params)
		if not result then
			return true
		end
		return (result.Position - position).Magnitude < 0.18
	end

	local stickers = {}
	local operations = 0

	local function tryCreate(face: Face, u: number, v: number): boolean
		operations += 1
		if operations % 350 == 0 then
			task.wait()
		end
		local typeId = pickType(rng, difficulty, luckBonus, face.Hard)
		local info = StickerConfig.Types[typeId]

		local size = face.BaseSize * info.SizeMultiplier * rng:NextNumber(0.85, 1.15)
		local maxSize = math.min(Config.Sticker.MaxSize, faceSizeLimit(face))
		size = math.clamp(size, math.min(Config.Sticker.MinSize, maxSize), maxSize)
		local circle = rng:NextNumber() < Config.Sticker.CircleChance
		local aspect = if circle then 1 else rng:NextNumber(0.8, 1.25)
		local sizeX = size * aspect
		local sizeZ = size / aspect

		-- Keep stickers on rect faces from hanging far over the edges
		if face.Kind == "Rect" and not face.Clip then
			local radius = math.max(sizeX, sizeZ) * 0.5 * 0.8
			local limitX = math.max(0, 1 - 2 * radius / face.SpanX)
			local limitZ = math.max(0, 1 - 2 * radius / face.SpanZ)
			u = math.clamp(u, -limitX, limitX)
			v = math.clamp(v, -limitZ, limitZ)
		end

		local position, normal = samplePoint(face, u, v)
		if not position or not normal then
			return false
		end
		local dot = normal.Y
		if dot < face.MinDot - 1e-3 or dot > face.MaxDot + 1e-3 then
			return false
		end
		if position.Y < groundY + 0.15 and normal.Y < 0.9 then
			return false -- buried in the ground
		end
		if not visible(position, normal) then
			return false
		end

		local hard = face.Hard or normal.Y < -0.5 or position.Y - groundY > Config.Match.HardToReachHeight
		local healthSizeFactor = math.clamp((size / 2) ^ 0.35, 0.8, 1.4)
		local health = info.Health * difficulty.HealthMultiplier * healthSizeFactor
		local reward = level.StickerReward
			* info.RewardMultiplier
			* difficulty.RewardMultiplier
			* (if hard then Config.Match.HardToReachRewardBonus else 1)

		table.insert(stickers, {
			Id = 0,
			Type = typeId,
			TypeIndex = info.Index,
			Rarity = info.Rarity,
			Position = position,
			Normal = normal,
			Spin = rng:NextNumber() * math.pi * 2,
			SizeX = sizeX,
			SizeZ = sizeZ,
			Health = health,
			ColorIndex = rng:NextInteger(1, StickerConfig.VariantCount), -- color + artwork variant
			Circle = circle,
			Hard = hard,
			Layer = if info.IsRare then 9 else rng:NextInteger(0, 7),
			BaseReward = reward,
			SurfaceId = face.Id,
			Zone = face.Zone,
			Alive = true,
			Progress = 0,
			State = "Attached",
			Peeler = nil,
			PeelStart = 0,
			PeelDuration = 0,
			PeelStartProgress = 0,
		})
		return true
	end

	-- Stratified (jittered grid) placement per face for an even, "fully covered" look
	local deficit = 0
	for i, face in ipairs(faces) do
		local n = allocations[i]
		if n <= 0 then
			continue
		end
		local aspect = 1
		if face.Kind == "Rect" then
			aspect = face.SpanX / math.max(face.SpanZ, 0.01)
		elseif face.Kind == "Cylinder" then
			aspect = (2 * math.pi * face.Radius) / math.max(face.Length, 0.01)
		end
		local cols = math.max(1, math.floor(math.sqrt(n * aspect) + 0.5))
		local rows = math.max(1, math.ceil(n / cols))
		local cells = {}
		for c = 0, cols - 1 do
			for r = 0, rows - 1 do
				table.insert(cells, { c, r })
			end
		end
		-- Shuffle cells, use the first n
		for k = #cells, 2, -1 do
			local j = rng:NextInteger(1, k)
			cells[k], cells[j] = cells[j], cells[k]
		end
		local placed = 0
		for k = 1, math.min(n, #cells) do
			local cell = cells[k]
			local u = ((cell[1] + rng:NextNumber()) / cols) * 2 - 1
			local v = ((cell[2] + rng:NextNumber()) / rows) * 2 - 1
			if tryCreate(face, u, v) then
				placed += 1
			end
		end
		deficit += n - placed
	end

	-- Fill whatever failed occlusion / clipping with weighted random samples
	local faceEntries = {}
	for _, face in ipairs(faces) do
		table.insert(faceEntries, { Weight = face.Weight, Value = face })
	end
	local attempts = deficit * 8
	while deficit > 0 and attempts > 0 do
		attempts -= 1
		local face = Utility.WeightedPick(rng, faceEntries)
		if tryCreate(face, rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) then
			deficit -= 1
		end
	end

	-- Guarantee at least one Golden-or-better sticker per level
	local hasSpecial = false
	for _, sticker in ipairs(stickers) do
		local info = StickerConfig.Types[sticker.Type]
		if info.Index >= StickerConfig.Types.Golden.Index then
			hasSpecial = true
			break
		end
	end
	if not hasSpecial and #stickers > 20 then
		local candidate = stickers[rng:NextInteger(1, #stickers)]
		for _ = 1, 30 do
			local s = stickers[rng:NextInteger(1, #stickers)]
			if s.Hard then
				candidate = s
				break
			end
		end
		local golden = StickerConfig.Types.Golden
		candidate.Type = "Golden"
		candidate.TypeIndex = golden.Index
		candidate.Rarity = golden.Rarity
		candidate.Layer = 9
		candidate.Health = golden.Health * difficulty.HealthMultiplier
		candidate.BaseReward = level.StickerReward * golden.RewardMultiplier * difficulty.RewardMultiplier
	end

	for index, sticker in ipairs(stickers) do
		sticker.Id = index
	end
	return stickers, seed
end

return StickerGenerator
