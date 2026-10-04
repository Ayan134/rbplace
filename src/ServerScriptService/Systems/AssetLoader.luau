--[[
	AssetLoader
	Loads the Creator Store models listed in AssetConfig at server start and swaps them
	in for the procedural decorations that carry a matching AssetKind attribute.

	  AssetLoader.LoadAll()          -- yields until every kind resolved or timed out
	  AssetLoader.ApplyTo(root)      -- replaces placeholders under root

	Loaded models are sanitized (no scripts, sounds, prompts or physics), anchored and
	normalized so their pivot is the bottom center. Nothing here runs in the build tools;
	in Studio edit mode you see the procedural scenery.
]]

local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local AssetConfig = require(script.Parent.AssetConfig)

local AssetLoader = {}

type Variant = { Model: Model, Size: Vector3 }

local variants: { [string]: { Variant } } = {}
local loadedAssets: { [number]: Instance | false } = {}
local loading: { [number]: boolean } = {}
local cache: Folder? = nil

local REMOVE_CLASSES = {
	"Script", "LocalScript", "ModuleScript", "Sound", "ProximityPrompt", "ClickDetector", "Humanoid",
	"BodyMover", "Constraint", "Tool", "Seat", "VehicleSeat", "SpawnLocation", "Camera", "Dialog",
}

local function getCache(): Folder
	if not cache then
		local folder = Instance.new("Folder")
		folder.Name = "AssetCache"
		folder.Parent = ServerStorage
		cache = folder
	end
	return cache :: Folder
end

local function fetch(assetId: number): Instance?
	if loadedAssets[assetId] ~= nil then
		return loadedAssets[assetId] or nil
	end
	if loading[assetId] then
		while loading[assetId] do
			task.wait(0.1)
		end
		return loadedAssets[assetId] or nil
	end
	loading[assetId] = true
	local ok, result = pcall(function()
		return (AssetService :: any):LoadAssetAsync(assetId)
	end)
	if not ok or not result then
		ok, result = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)
	end
	loading[assetId] = nil
	if ok and typeof(result) == "Instance" then
		loadedAssets[assetId] = result
		return result
	end
	warn(string.format("[AssetLoader] Could not load asset %d: %s", assetId, tostring(result)))
	loadedAssets[assetId] = false
	return nil
end

local function sanitize(root: Instance)
	for _, descendant in ipairs(root:GetDescendants()) do
		local remove = false
		for _, className in ipairs(REMOVE_CLASSES) do
			if descendant:IsA(className) then
				remove = true
				break
			end
		end
		if remove then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Locked = true
		end
	end
end

-- Wraps `source` in a fresh Model with its pivot at the bottom center
local function normalize(source: Instance): Variant?
	local model = Instance.new("Model")
	model.Name = source.Name
	if source:IsA("Model") or source:IsA("Folder") then
		for _, child in ipairs(source:GetChildren()) do
			child.Parent = model
		end
	else
		source.Parent = model
	end
	sanitize(model)
	local hasParts = false
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			hasParts = true
			break
		end
	end
	if not hasParts then
		model:Destroy()
		return nil
	end
	model.WorldPivot = CFrame.new()
	local cf, size = model:GetBoundingBox()
	if size.Y < 0.3 or size.Magnitude > 600 then
		model:Destroy()
		return nil
	end
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	model.Parent = getCache()
	return { Model = model, Size = size }
end

local function containsAny(name: string, words: { string }): boolean
	for _, word in ipairs(words) do
		if string.find(name, word, 1, true) then
			return true
		end
	end
	return false
end

-- Children of a pack whose names match, topmost first (a match's own parts are skipped)
local function variantsFromPack(pack: Instance, source): { Variant }
	local found = {}
	local taken: { [Instance]: boolean } = {}
	for _, descendant in ipairs(pack:GetDescendants()) do
		if #found >= AssetConfig.MaxVariants then
			break
		end
		if not (descendant:IsA("Model") or descendant:IsA("BasePart")) then
			continue
		end
		local insideTaken = false
		local ancestor = descendant.Parent
		while ancestor and ancestor ~= pack do
			if taken[ancestor] then
				insideTaken = true
				break
			end
			ancestor = ancestor.Parent
		end
		if insideTaken then
			continue
		end
		local name = string.lower(descendant.Name)
		if containsAny(name, source.Match) and not containsAny(name, source.Exclude or {}) then
			taken[descendant] = true
			local variant = normalize(descendant:Clone())
			if variant then
				table.insert(found, variant)
			end
		end
	end
	return found
end

local function resolveKind(kind: string, entry)
	for _, source in ipairs(entry.Sources) do
		if source.Pack then
			local pack = fetch(source.Pack)
			if pack then
				local found = variantsFromPack(pack, source)
				if #found > 0 then
					variants[kind] = found
					return
				end
			end
		elseif source.Id then
			local asset = fetch(source.Id)
			if asset then
				local variant = normalize(asset:Clone())
				if variant then
					variants[kind] = { variant }
					return
				end
			end
		end
	end
end

function AssetLoader.LoadAll()
	local pending = 0
	for kind, entry in pairs(AssetConfig.Kinds) do
		pending += 1
		task.spawn(function()
			local ok, err = pcall(resolveKind, kind, entry)
			if not ok then
				warn("[AssetLoader] " .. kind .. ": " .. tostring(err))
			end
			pending -= 1
		end)
	end
	local deadline = os.clock() + AssetConfig.LoadTimeout
	while pending > 0 and os.clock() < deadline do
		task.wait(0.2)
	end
	local summary = {}
	for kind, list in pairs(variants) do
		table.insert(summary, string.format("%s(%d)", kind, #list))
	end
	print("[AssetLoader] Store models ready: " .. (if #summary > 0 then table.concat(summary, ", ") else "none (procedural scenery)"))
end

function AssetLoader.HasAny(): boolean
	return next(variants) ~= nil
end

local function footprintOf(target: Instance): (CFrame, Vector3)
	if target:IsA("Model") then
		return target:GetBoundingBox()
	end
	local part = target :: BasePart
	-- World-aligned box around a (possibly tilted) part
	local cf, size = part.CFrame, part.Size
	local extent = Vector3.new(
		math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z,
		math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z,
		math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z
	)
	return CFrame.new(cf.Position), extent
end

local function replace(target: Instance, kind: string, fit: string)
	local list = variants[kind]
	local cf, size = footprintOf(target)
	local position = cf.Position
	local seed = math.floor(math.abs(position.X * 7.3 + position.Z * 13.1))
	local variant = list[(seed % #list) + 1]
	local natural = variant.Size

	-- Ground footprint and the direction of its long side
	local yaw = (seed % 360) / 180 * math.pi
	local scale
	if fit == "Height" then
		scale = size.Y / natural.Y
	else
		local targetLong = math.max(size.X, size.Z)
		local targetShort = math.min(size.X, size.Z)
		local assetLong = math.max(natural.X, natural.Z)
		local assetShort = math.min(natural.X, natural.Z)
		scale = math.min(targetLong / assetLong, targetShort / math.max(assetShort, 0.1), size.Y * 1.6 / natural.Y)
		-- Line the long sides up (benches, cars) using the placeholder's orientation
		local look = cf.LookVector
		local right = cf.RightVector
		local targetYaw = if size.X >= size.Z then math.atan2(-right.X, -right.Z) else math.atan2(-look.X, -look.Z)
		local assetOffset = if natural.X >= natural.Z then math.pi / 2 else 0
		yaw = targetYaw + assetOffset + (if seed % 2 == 0 then 0 else math.pi)
	end
	if scale ~= scale or scale < 0.03 or scale > 40 then
		return
	end
	local clone = variant.Model:Clone()
	if math.abs(scale - 1) > 0.01 then
		local ok = pcall(function()
			clone:ScaleTo(scale)
		end)
		if not ok then
			clone:Destroy()
			return
		end
	end
	local bottom = Vector3.new(position.X, position.Y - size.Y / 2, position.Z)
	clone:PivotTo(CFrame.new(bottom) * CFrame.Angles(0, yaw, 0))
	clone.Name = (target.Name or kind) .. "_Store"
	clone.Parent = target.Parent
	target:Destroy()
end

function AssetLoader.ApplyTo(root: Instance)
	if not AssetLoader.HasAny() then
		return 0
	end
	local targets = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		local kind = descendant:GetAttribute("AssetKind")
		if type(kind) == "string" and variants[kind] then
			table.insert(targets, descendant)
		end
	end
	local replaced = 0
	for index, target in ipairs(targets) do
		if target.Parent then
			local kind = target:GetAttribute("AssetKind") :: string
			local entry = AssetConfig.Kinds[kind]
			local ok = pcall(replace, target, kind, entry and entry.Fit or "Height")
			if ok then
				replaced += 1
			end
		end
		if index % 40 == 0 then
			task.wait()
		end
	end
	return replaced
end

return AssetLoader
