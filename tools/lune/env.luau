--[[
	Lune harness: runs the game's own ModuleScripts (from a Rojo-built place) outside
	Roblox, filling in the few engine features Lune's data model doesn't provide
	(WaitForChild, Position, Model pivots/bounds, Raycast, Random).

	Used by build-place.luau (prebuilds lobby + levels into the place file) and
	test-generation.luau (sticker generation checks).
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

local Env = {}

------------------------------------------------------------------------
-- Engine shims
------------------------------------------------------------------------

local PART_CLASSES = { "Part", "WedgePart", "TrussPart", "SpawnLocation", "MeshPart", "CornerWedgePart" }

for _, className in ipairs(PART_CLASSES) do
	roblox.implementProperty(className, "Position", function(part)
		return part.CFrame.Position
	end, function(part, value)
		part.CFrame = CFrame.new(value) * part.CFrame.Rotation
	end)
end

local function implementEverywhere(methodName: string, callback)
	for _, className in ipairs({ "Instance", "Folder", "Model", "Workspace", "ReplicatedStorage", "ServerStorage", "ServerScriptService", "ModuleScript", "Configuration", "Part", "WedgePart", "DataModel" }) do
		pcall(roblox.implementMethod, className, methodName, callback)
	end
end

implementEverywhere("WaitForChild", function(self, name: string)
	local child = self:FindFirstChild(name)
	if not child then
		error("WaitForChild: " .. self:GetFullName() .. " has no child " .. name)
	end
	return child
end)

local function isPart(instance): boolean
	return instance:IsA("BasePart")
end

local function boundingBox(model)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	local any = false
	for _, descendant in ipairs(model:GetDescendants()) do
		if isPart(descendant) then
			any = true
			local cf = descendant.CFrame
			local half = descendant.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local corner = cf:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
						minV = Vector3.new(math.min(minV.X, corner.X), math.min(minV.Y, corner.Y), math.min(minV.Z, corner.Z))
						maxV = Vector3.new(math.max(maxV.X, corner.X), math.max(maxV.Y, corner.Y), math.max(maxV.Z, corner.Z))
					end
				end
			end
		end
	end
	if not any then
		return CFrame.new(), Vector3.new()
	end
	return CFrame.new((minV + maxV) / 2), maxV - minV
end

roblox.implementMethod("Model", "GetBoundingBox", function(model)
	return boundingBox(model)
end)

local function getPivot(model)
	if model.PrimaryPart then
		return model.PrimaryPart.CFrame
	end
	local cf = boundingBox(model)
	return cf
end

roblox.implementMethod("Model", "GetPivot", getPivot)

roblox.implementMethod("Model", "PivotTo", function(model, target)
	local delta = target * getPivot(model):Inverse()
	for _, descendant in ipairs(model:GetDescendants()) do
		if isPart(descendant) then
			descendant.CFrame = delta * descendant.CFrame
		end
	end
end)

------------------------------------------------------------------------
-- Raycast (convex shapes: block, wedge, ball, cylinder) for occlusion tests
------------------------------------------------------------------------

local function rayConvex(o, d, planes): number?
	local tEnter, tExit = -math.huge, math.huge
	for _, plane in ipairs(planes) do
		local n, offset = plane[1], plane[2]
		local denom = n:Dot(d)
		local dist = offset - n:Dot(o)
		if math.abs(denom) < 1e-9 then
			if dist < 0 then
				return nil
			end
		else
			local t = dist / denom
			if denom < 0 then
				tEnter = math.max(tEnter, t)
			else
				tExit = math.min(tExit, t)
			end
		end
	end
	if tEnter <= tExit and tExit >= 0 and tEnter <= 1 then
		return math.max(tEnter, 0)
	end
	return nil
end

local function intersectPart(part, origin, direction): number?
	local cf = part.CFrame
	local o = cf:PointToObjectSpace(origin)
	local d = cf:VectorToObjectSpace(direction)
	local h = part.Size / 2
	local shape = if part:IsA("Part") then part.Shape.Name else "Block"
	if part:IsA("WedgePart") then
		shape = "Wedge"
	end
	if shape == "Ball" then
		local r = math.min(h.X, h.Y, h.Z)
		local a = d:Dot(d)
		local b = 2 * o:Dot(d)
		local c = o:Dot(o) - r * r
		local disc = b * b - 4 * a * c
		if disc < 0 then
			return nil
		end
		local s = math.sqrt(disc)
		local t1, t2 = (-b - s) / (2 * a), (-b + s) / (2 * a)
		if t2 < 0 or t1 > 1 then
			return nil
		end
		return math.max(t1, 0)
	elseif shape == "Cylinder" then
		local r = math.min(h.Y, h.Z)
		local best: number? = nil
		local a = d.Y * d.Y + d.Z * d.Z
		if a > 1e-12 then
			local b = 2 * (o.Y * d.Y + o.Z * d.Z)
			local c = o.Y * o.Y + o.Z * o.Z - r * r
			local disc = b * b - 4 * a * c
			if disc >= 0 then
				local s = math.sqrt(disc)
				for _, t in ipairs({ (-b - s) / (2 * a), (-b + s) / (2 * a) }) do
					local x = o.X + d.X * t
					if t >= 0 and t <= 1 and math.abs(x) <= h.X then
						best = if best then math.min(best, t) else t
					end
				end
			end
		end
		if math.abs(d.X) > 1e-12 then
			for _, capX in ipairs({ -h.X, h.X }) do
				local t = (capX - o.X) / d.X
				if t >= 0 and t <= 1 then
					local y, z = o.Y + d.Y * t, o.Z + d.Z * t
					if y * y + z * z <= r * r then
						best = if best then math.min(best, t) else t
					end
				end
			end
		end
		-- Origin inside the cylinder counts as an immediate hit
		if not best and math.abs(o.X) <= h.X and o.Y * o.Y + o.Z * o.Z <= r * r then
			best = 0
		end
		return best
	end
	local planes = {
		{ Vector3.new(1, 0, 0), h.X },
		{ Vector3.new(-1, 0, 0), h.X },
		{ Vector3.new(0, 1, 0), h.Y },
		{ Vector3.new(0, -1, 0), h.Y },
		{ Vector3.new(0, 0, 1), h.Z },
		{ Vector3.new(0, 0, -1), h.Z },
	}
	if shape == "Wedge" then
		table.insert(planes, { Vector3.new(0, h.Z, -h.Y).Unit, 0 })
	end
	return rayConvex(o, d, planes)
end

local RaycastParams = {}
RaycastParams.__index = RaycastParams
function RaycastParams.new()
	return setmetatable({ FilterType = nil, FilterDescendantsInstances = {}, _cache = nil }, RaycastParams)
end

local function raycast(_workspace, origin, direction, params)
	if not params then
		return nil
	end
	if not params._cache then
		local parts = {}
		for _, root in ipairs(params.FilterDescendantsInstances) do
			if isPart(root) then
				table.insert(parts, root)
			end
			for _, descendant in ipairs(root:GetDescendants()) do
				if isPart(descendant) and descendant.CanQuery then
					table.insert(parts, descendant)
				end
			end
		end
		params._cache = parts
	end
	local bestT, bestPart = math.huge, nil
	for _, part in ipairs(params._cache) do
		local t = intersectPart(part, origin, direction)
		if t and t < bestT then
			bestT, bestPart = t, part
		end
	end
	if not bestPart then
		return nil
	end
	return { Instance = bestPart, Position = origin + direction * bestT, Distance = direction.Magnitude * bestT }
end
roblox.implementMethod("Workspace", "Raycast", raycast)

------------------------------------------------------------------------
-- Random (Park-Miller) - deterministic stand-in for Roblox's Random
------------------------------------------------------------------------

local Random = {}
Random.__index = Random
function Random.new(seed: number?)
	local s = math.floor(seed or (os.clock() * 1e6)) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return setmetatable({ s = s }, Random)
end
function Random:_next(): number
	self.s = (self.s * 16807) % 2147483647
	return self.s / 2147483647
end
function Random:NextNumber(a: number?, b: number?): number
	local r = self:_next()
	if a and b then
		return a + (b - a) * r
	end
	return r
end
function Random:NextInteger(a: number, b: number): number
	return math.min(b, a + math.floor((b - a + 1) * self:_next()))
end

------------------------------------------------------------------------
-- Module loader
------------------------------------------------------------------------

function Env.load(placePath: string)
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local cache = {}

	local baseEnv = {
		game = game,
		workspace = game:GetService("Workspace"),
		Instance = Instance,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		RaycastParams = RaycastParams,
		Random = Random,
		task = task,
		warn = function(...)
			print("[warn]", ...)
		end,
	}

	local function requireModule(module)
		if cache[module] ~= nil then
			return cache[module]
		end
		assert(module and module:IsA("ModuleScript"), "require expects a ModuleScript")
		-- Plain table: Luau resolves global imports with raw lookups
		local env = table.clone(baseEnv)
		env.script = module
		env.require = requireModule
		local chunk = luau.load(module.Source, { debugName = module:GetFullName(), environment = env })
		local result = chunk()
		cache[module] = result
		return result
	end

	return {
		Game = game,
		Require = requireModule,
		Save = function(path: string)
			-- Lune stores the legacy Font enum as-is; convert it to the FontFace datatype
			for _, descendant in ipairs(game:GetDescendants()) do
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
					local ok, legacy = pcall(function()
						return descendant.Font
					end)
					if ok and typeof(legacy) == "EnumItem" then
						descendant.FontFace = roblox.Font.fromEnum(legacy)
					end
				end
			end
			fs.writeFile(path, roblox.serializePlace(game))
		end,
	}
end

return Env
