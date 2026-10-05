--[[
	StickerRenderer
	Client-side visual layer for stickers.

	The server only replicates compact data (StickerData buffers + StickerUpdate events);
	this module turns it into lightweight pooled Parts (no scripts, no per-sticker
	connections) and animates the peel:

	  peel progress p:  the sticker splits into an attached part that shrinks and a
	                    "flap" that lifts off the edge, bends back (showing its white
	                    backing) and grows as p increases
	  completion:       the flap tears off, flies away from the surface, spins, shrinks
	                    and fades, with particles

	Everyone in a session sees the same thing: other players' peels are animated from
	the server's broadcast start time and duration.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DifficultyConfig = require(Shared.DifficultyConfig)
local Signal = require(Shared.Signal)
local StickerCodec = require(Shared.StickerCodec)
local StickerConfig = require(Shared.StickerConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local StickerRenderer = {}

StickerRenderer.SessionReady = Signal.new() -- (session)
StickerRenderer.SessionCleared = Signal.new() -- (sessionId)
StickerRenderer.LoadProgress = Signal.new() -- (session, received, total)
StickerRenderer.PeelStarted = Signal.new() -- (session, record, userId)
StickerRenderer.PeelCancelled = Signal.new() -- (session, record, reason)
StickerRenderer.PeelRejected = Signal.new() -- (session, record, reason)
StickerRenderer.Peeled = Signal.new() -- (session, record, userId, reward)

local THICKNESS = Config.Sticker.Thickness
local CELL = 8
local BUILD_BUDGET = 700 -- parts created per frame while loading
local BACKING_COLOR = Color3.fromRGB(245, 245, 240)
local LOCAL_PLAYER = Players.LocalPlayer

local Controllers
local rootFolder: Folder
local sessions: { [string]: any } = {}
local partLookup: { [BasePart]: any } = {} -- part -> record
local activePeels: { [any]: boolean } = {} -- records currently animating
local flying: { any } = {}
local rainbowRecords: { [any]: boolean } = {}
local pool: { BasePart } = {}
local lowVFX = false

-- Sticker artwork (emoji / image) is only drawn on the nearest stickers (LOD)
local ART_RADIUS = 70
local ART_MAX = 650
local ART_INTERVAL = 0.25
local artPool: { SurfaceGui } = {}
local artRecords: { [any]: boolean } = {}
local artFolder: Folder
local lastArtUpdate = 0
local showOthersVFX = true

StickerRenderer.CurrentSessionId = nil :: string?

------------------------------------------------------------------------
-- Part pool
------------------------------------------------------------------------

local function acquirePart(): Part
	local part = table.remove(pool) :: Part?
	if part then
		part.Transparency = 0
		part.Reflectance = 0
		return part
	end
	local new = Instance.new("Part")
	new.Anchored = true
	new.CanCollide = false
	new.CanTouch = false
	new.CastShadow = false
	new.TopSurface = Enum.SurfaceType.Smooth
	new.BottomSurface = Enum.SurfaceType.Smooth
	new.Locked = true
	return new
end

------------------------------------------------------------------------
-- Artwork
------------------------------------------------------------------------

local function acquireArt(): SurfaceGui
	local gui = table.remove(artPool)
	if gui then
		return gui
	end
	gui = Instance.new("SurfaceGui")
	gui.Name = "StickerArt"
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 48
	gui.LightInfluence = 1 -- lit like the paper under it (no glowing white stickers in the sun)
	gui.MaxDistance = ART_RADIUS + 15
	gui.ResetOnSpawn = false
	local emoji = Instance.new("TextLabel")
	emoji.Name = "Emoji"
	emoji.BackgroundTransparency = 1
	emoji.Size = UDim2.fromScale(0.9, 0.9)
	emoji.Position = UDim2.fromScale(0.5, 0.5)
	emoji.AnchorPoint = Vector2.new(0.5, 0.5)
	emoji.TextScaled = true
	emoji.Font = Enum.Font.GothamBold
	emoji.TextColor3 = Color3.new(1, 1, 1)
	emoji.Parent = gui
	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(0.86, 0.86)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.ScaleType = Enum.ScaleType.Fit
	image.Visible = false
	image.Parent = gui
	-- White die-cut edge, like a real vinyl sticker
	local border = Instance.new("Frame")
	border.Name = "Border"
	border.Size = UDim2.fromScale(1, 1)
	border.BackgroundTransparency = 1
	border.ZIndex = 2
	border.Parent = gui
	local borderCorner = Instance.new("UICorner")
	borderCorner.Name = "Corner"
	borderCorner.Parent = border
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.new(1, 1, 1)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = border
	-- Soft diagonal gloss
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Size = UDim2.fromScale(1, 1)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BorderSizePixel = 0
	gloss.ZIndex = 3
	gloss.Parent = gui
	local glossCorner = Instance.new("UICorner")
	glossCorner.Name = "Corner"
	glossCorner.Parent = gloss
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 55
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.25, 0.9),
		NumberSequenceKeypoint.new(0.3, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = gloss
	return gui
end

local function detachArt(record)
	local gui = record.Art
	if not gui then
		return
	end
	record.Art = nil
	artRecords[record] = nil
	gui.Adornee = nil
	gui.Enabled = false
	if #artPool < ART_MAX + 50 then
		table.insert(artPool, gui)
	else
		gui:Destroy()
	end
end

local function attachArt(record)
	if record.Art or not record.Part then
		return
	end
	local gui = acquireArt()
	local kind, content = StickerConfig.GetDesign(record.Info, record.ColorIndex)
	local emoji = gui:FindFirstChild("Emoji") :: TextLabel
	local image = gui:FindFirstChild("Image") :: ImageLabel
	emoji.Visible = kind == "Emoji"
	image.Visible = kind == "Image"
	if kind == "Emoji" then
		emoji.Text = content
	else
		image.Image = content
	end
	-- Border width scales with the sticker so small and huge stickers look alike
	local radius = if record.Circle then UDim.new(0.5, 0) else UDim.new(0.1, 0)
	local border = gui:FindFirstChild("Border") :: Frame
	local gloss = gui:FindFirstChild("Gloss") :: Frame
	local borderCorner = border:FindFirstChild("Corner") :: UICorner
	local glossCorner = gloss:FindFirstChild("Corner") :: UICorner
	local stroke = border:FindFirstChild("Stroke") :: UIStroke
	local shortSide = math.min(record.SizeX or 1, record.SizeZ or 1)
	borderCorner.CornerRadius = radius
	glossCorner.CornerRadius = radius
	stroke.Thickness = math.clamp(shortSide * gui.PixelsPerStud * 0.08, 2, 12)
	-- Circle stickers are cylinders whose +X axis is the surface normal
	gui.Face = if record.Circle then Enum.NormalId.Right else Enum.NormalId.Top
	gui.Adornee = record.Part
	gui.Enabled = record.Part.Transparency < 1
	gui.Parent = artFolder
	record.Art = gui
	artRecords[record] = true
end

local function updateArt(focus: Vector3?)
	local session = StickerRenderer.GetCurrentSession()
	if not session or not focus then
		for record in pairs(artRecords) do
			detachArt(record)
		end
		return
	end
	local nearby = StickerRenderer.QueryRadius(session, focus, ART_RADIUS)
	local wanted = {}
	for i = 1, math.min(#nearby, ART_MAX) do
		wanted[nearby[i]] = true
	end
	for record in pairs(artRecords) do
		if not wanted[record] or not record.Part then
			detachArt(record)
		end
	end
	for record in pairs(wanted) do
		attachArt(record)
	end
end

local function releasePart(part: BasePart?)
	if not part then
		return
	end
	partLookup[part] = nil
	CollectionService:RemoveTag(part, "Sticker")
	for _, child in ipairs(part:GetChildren()) do
		child:Destroy()
	end
	part.Parent = nil
	if #pool < 8000 then
		table.insert(pool, part)
	else
		part:Destroy()
	end
end

------------------------------------------------------------------------
-- Geometry helpers
------------------------------------------------------------------------

-- Positions a sticker-shaped part: cf has Y = surface normal; sx along X, sz along Z.
local function applyShape(part: Part, circle: boolean, cf: CFrame, sx: number, sz: number)
	if circle then
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(THICKNESS, math.max(sx, 0.05), math.max(sz, 0.05))
		part.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	else
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.new(math.max(sx, 0.05), THICKNESS, math.max(sz, 0.05))
		part.CFrame = cf
	end
end

local function baseCFrame(record): CFrame
	local offset = Config.Sticker.SurfaceOffset + (record.Layer % 10) * Config.Sticker.LayerStep
	return StickerCodec.BuildCFrame(record.Position + record.Normal * offset, record.Normal, record.Spin)
end

local function cellKey(x: number, y: number, z: number): string
	return x .. "," .. y .. "," .. z
end

local function cellOf(position: Vector3): (number, number, number)
	return math.floor(position.X / CELL), math.floor(position.Y / CELL), math.floor(position.Z / CELL)
end

------------------------------------------------------------------------
-- Building sticker parts
------------------------------------------------------------------------

local function addEffects(record, part: Part)
	if lowVFX then
		return
	end
	local info = record.Info
	if info.Sparkle then
		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(info.Color or Color3.new(1, 1, 1))
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Transparency = NumberSequence.new(0.2)
		sparkle.Lifetime = NumberRange.new(0.6, 1)
		sparkle.Rate = if info.Index >= 6 then 6 else 3
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = attachment
	end
	if info.Glow then
		local light = Instance.new("PointLight")
		light.Range = 8
		light.Brightness = 1.5
		light.Color = info.Color or Color3.new(1, 1, 1)
		light.Parent = part
	end
end

local function buildRecord(session, record)
	if not record.Alive then
		return
	end
	local part = acquirePart()
	local info = record.Info
	part.Name = "Sticker"
	part.Material = info.Material
	part.Color = StickerConfig.GetColor(info, record.ColorIndex)
	part.CanQuery = true
	record.Base = baseCFrame(record)
	applyShape(part, record.Circle, record.Base, record.SizeX, record.SizeZ)
	addEffects(record, part)
	part.Parent = session.Folder
	CollectionService:AddTag(part, "Sticker")
	record.Part = part
	partLookup[part] = record
	if info.Rainbow then
		rainbowRecords[record] = true
	end
	if record.Progress > 0.01 then
		StickerRenderer.RenderPeel(record, record.Progress)
	end
end

local function indexRecord(session, record)
	local x, y, z = cellOf(record.Position)
	local key = cellKey(x, y, z)
	local cell = session.Grid[key]
	if not cell then
		cell = {}
		session.Grid[key] = cell
	end
	table.insert(cell, record)
end

------------------------------------------------------------------------
-- Peel visuals
------------------------------------------------------------------------

local function ensurePeelParts(record)
	if not record.Flap then
		local flap = acquirePart()
		flap.Name = "StickerFlap"
		flap.CanQuery = false
		flap.Material = record.Part and record.Part.Material or Enum.Material.SmoothPlastic
		flap.Color = record.Part and record.Part.Color or Color3.new(1, 1, 1)
		flap.Parent = rootFolder
		record.Flap = flap
		local backing = acquirePart()
		backing.Name = "StickerBacking"
		backing.CanQuery = false
		backing.Material = Enum.Material.SmoothPlastic
		backing.Color = BACKING_COLOR
		backing.Parent = rootFolder
		record.Backing = backing
	end
end

-- Chooses which edge lifts first, based on where the peeler stands.
local function setupPeelFrame(record, userId: number?)
	local base = record.Base
	local peelerPosition: Vector3? = nil
	local player = if userId and userId > 0 then Players:GetPlayerByUserId(userId) else nil
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		peelerPosition = root.Position
	end
	local alongX = false
	local direction = 1
	if peelerPosition then
		local localOffset = base:PointToObjectSpace(peelerPosition)
		if math.abs(localOffset.X) > math.abs(localOffset.Z) then
			-- Peel along X: rotating the frame 90 degrees maps local +Z onto the old +X
			alongX = true
			direction = if localOffset.X >= 0 then 1 else -1
		else
			direction = if localOffset.Z >= 0 then 1 else -1
		end
	else
		direction = if record.Id % 2 == 0 then 1 else -1
	end
	if alongX then
		record.PeelBase = base * CFrame.Angles(0, math.pi / 2, 0)
		record.PeelW, record.PeelL = record.SizeZ, record.SizeX
	else
		record.PeelBase = base
		record.PeelW, record.PeelL = record.SizeX, record.SizeZ
	end
	record.PeelDir = direction
end

function StickerRenderer.RenderPeel(record, progress: number)
	if not record.Part then
		return
	end
	if not record.PeelBase then
		setupPeelFrame(record, nil)
	end
	ensurePeelParts(record)
	local p = math.clamp(progress, 0, 1)
	local d = record.PeelDir
	local w, l = record.PeelW, record.PeelL
	local base = record.PeelBase

	-- Attached remainder shrinks toward the far edge
	local attachedLength = l * (1 - p)
	local part = record.Part :: Part
	if record.Art then
		record.Art.Enabled = attachedLength >= 0.03
	end
	if attachedLength < 0.03 then
		part.Transparency = 1
	else
		part.Transparency = 0
		local center = -d * l / 2 + d * attachedLength / 2
		applyShape(part, record.Circle, base * CFrame.new(0, 0, center), w, attachedLength)
	end

	-- Flap lifts from the fold line and bends back over the sticker
	local flapLength = math.max(l * p, 0.05)
	local fold = -d * l / 2 + d * attachedLength
	local eased = Utility.Smoothstep(p)
	local angle = math.rad(28 + 128 * eased)
	local wobble = math.sin(os.clock() * 18 + record.Id) * math.rad(3) * (1 - p)
	local hinge = base * CFrame.new(0, THICKNESS * 0.5, fold) * CFrame.Angles(-(angle + wobble) * d, 0, 0)
	local flapCF = hinge * CFrame.new(0, 0, d * flapLength / 2)
	applyShape(record.Flap, record.Circle, flapCF, w, flapLength)
	applyShape(record.Backing, record.Circle, flapCF * CFrame.new(0, -THICKNESS * 0.9, 0), w * 0.98, flapLength * 0.98)
	record.Flap.Transparency = 0
	record.Backing.Transparency = 0
end

local function clearPeelParts(record)
	if record.Flap then
		releasePart(record.Flap)
		record.Flap = nil
	end
	if record.Backing then
		releasePart(record.Backing)
		record.Backing = nil
	end
end

local function resetFlat(record)
	clearPeelParts(record)
	if record.Art then
		record.Art.Enabled = true
	end
	if record.Part then
		record.Part.Transparency = 0
		applyShape(record.Part, record.Circle, record.Base, record.SizeX, record.SizeZ)
	end
	record.PeelBase = nil
end

function StickerRenderer.GetCurrentProgress(record): number
	local peel = record.Peel
	if not peel then
		return record.Progress
	end
	local t = (os.clock() - peel.Start) / math.max(peel.Duration, 0.01)
	return peel.P0 + (1 - peel.P0) * math.clamp(t, 0, 1)
end

-- Starts animating a peel (local prediction or server broadcast).
function StickerRenderer.BeginPeel(record, startTime: number, duration: number, p0: number, userId: number, isLocal: boolean)
	if not record.Alive or not record.Part then
		return
	end
	record.State = "Peeling"
	record.Peel = { Start = startTime, Duration = duration, P0 = p0, UserId = userId, Local = isLocal }
	setupPeelFrame(record, userId)
	activePeels[record] = true
end

-- Stops animating; the sticker stays partially peeled at `progress`.
function StickerRenderer.StopPeel(record, progress: number)
	activePeels[record] = nil
	record.Peel = nil
	if not record.Alive then
		return
	end
	record.State = "Attached"
	record.Progress = progress
	if progress <= 0.01 then
		resetFlat(record)
	else
		StickerRenderer.RenderPeel(record, progress)
	end
end

-- Tears the sticker off and sends it flying. `quiet` skips particles/sounds.
function StickerRenderer.Detach(session, record, quiet: boolean?)
	if record.Detached then
		return
	end
	record.Detached = true
	detachArt(record)
	activePeels[record] = nil
	rainbowRecords[record] = nil
	record.Peel = nil
	if not record.Part then
		return
	end
	-- Fully peeled flap (also when another player finished a half-peeled sticker)
	if not record.PeelBase then
		setupPeelFrame(record, nil)
	end
	StickerRenderer.RenderPeel(record, 1)
	local flap = record.Flap :: Part
	local backing = record.Backing :: Part
	record.Flap = nil
	record.Backing = nil
	releasePart(record.Part)
	record.Part = nil

	local rng = Random.new(record.Id)
	local normal = record.Normal
	local lateral = (record.Base.RightVector * rng:NextNumber(-1, 1) + record.Base.LookVector * rng:NextNumber(-1, 1)) * 1.5
	table.insert(flying, {
		Parts = { flap, backing },
		Start = os.clock(),
		Duration = 0.6,
		Origin = flap.CFrame,
		BackingOffset = flap.CFrame:ToObjectSpace(backing.CFrame),
		Sizes = { flap.Size, backing.Size },
		Velocity = normal * rng:NextNumber(9, 13) + lateral + Vector3.new(0, 4, 0),
		Spin = Vector3.new(rng:NextNumber(-12, 12), rng:NextNumber(-12, 12), rng:NextNumber(-12, 12)),
	})

	if not quiet and Controllers and Controllers.EffectsController then
		Controllers.EffectsController.StickerBurst(record.Position, normal, flap.Color, record.Info)
	end
	if session then
		session.Alive = math.max(0, session.Alive - 1)
	end
end

-- Undo a predicted detach the server did not accept.
function StickerRenderer.Restore(session, record)
	if not record.Detached or not record.Alive then
		return
	end
	record.Detached = false
	record.State = "Attached"
	record.Peel = nil
	record.PeelBase = nil
	buildRecord(session, record)
	session.Alive += 1
end

------------------------------------------------------------------------
-- Sessions
------------------------------------------------------------------------

local function destroySession(sessionId: string)
	local session = sessions[sessionId]
	if not session then
		return
	end
	sessions[sessionId] = nil
	for _, record in pairs(session.Records) do
		activePeels[record] = nil
		rainbowRecords[record] = nil
		detachArt(record)
		clearPeelParts(record)
		releasePart(record.Part)
		record.Part = nil
	end
	session.Folder:Destroy()
	if StickerRenderer.CurrentSessionId == sessionId then
		StickerRenderer.CurrentSessionId = nil
	end
	StickerRenderer.SessionCleared:Fire(sessionId)
end

local function onStickerData(meta, payload: buffer?)
	if meta.Clear then
		destroySession(meta.SessionId)
		return
	end
	local session = sessions[meta.SessionId]
	if session and session.Version ~= meta.Version then
		destroySession(meta.SessionId)
		session = nil
	end
	if not session then
		local folder = Instance.new("Folder")
		folder.Name = "Stickers_" .. meta.Kind
		folder.Parent = rootFolder
		session = {
			Id = meta.SessionId,
			Kind = meta.Kind,
			Version = meta.Version,
			Total = meta.Total,
			Alive = meta.Alive,
			Received = 0,
			Difficulty = DifficultyConfig.Get(meta.Difficulty or "Normal"),
			Meta = meta.Meta or {},
			Records = {},
			Grid = {},
			Folder = folder,
			BuildQueue = {},
			Ready = false,
			PendingEvents = {},
		}
		sessions[meta.SessionId] = session
		StickerRenderer.CurrentSessionId = meta.SessionId
	end
	if not payload then
		return
	end
	local records = StickerCodec.Decode(payload, meta.FirstId)
	for _, raw in ipairs(records) do
		local record: any = raw
		record.Info = StickerConfig.GetByIndex(record.TypeIndex) or StickerConfig.Types.Small
		record.State = if record.Alive then "Attached" else "Peeled"
		record.Detached = not record.Alive
		session.Records[record.Id] = record
		indexRecord(session, record)
		table.insert(session.BuildQueue, record)
	end
	session.Received += #records
	StickerRenderer.LoadProgress:Fire(session, session.Received, session.Total)
end

local function processEvent(session, event)
	local kind = event[1]
	local record = session.Records[event[2]]
	if not record then
		return
	end
	if kind == "S" then
		local userId = event[3]
		if userId == LOCAL_PLAYER.UserId and record.Peel and record.Peel.Local then
			-- Already predicted locally; adopt the server duration for accuracy
			record.Peel.Duration = math.max(event[4], 0.05)
			record.Peel.P0 = event[5]
		else
			StickerRenderer.BeginPeel(record, os.clock(), event[4], event[5], userId, false)
		end
		StickerRenderer.PeelStarted:Fire(session, record, userId)
	elseif kind == "C" then
		if record.Detached and record.Alive then
			StickerRenderer.Restore(session, record)
		end
		StickerRenderer.StopPeel(record, event[3])
		StickerRenderer.PeelCancelled:Fire(session, record, event[4])
	elseif kind == "P" then
		local userId = event[3]
		record.Alive = false
		record.State = "Peeled"
		if not record.Detached then
			local quiet = userId ~= LOCAL_PLAYER.UserId and userId ~= 0 and not showOthersVFX
			StickerRenderer.Detach(session, record, quiet)
		end
		StickerRenderer.Peeled:Fire(session, record, userId, {
			Coins = event[4],
			Combo = event[5],
			Lucky = event[6],
			ComboMultiplier = event[7],
		})
	elseif kind == "R" then
		StickerRenderer.PeelRejected:Fire(session, record, event[3])
	end
end

local function onStickerUpdate(sessionId: string, events)
	local session = sessions[sessionId]
	if not session then
		return
	end
	for _, event in ipairs(events) do
		if not session.Ready and event[1] ~= "R" then
			table.insert(session.PendingEvents, event)
		else
			processEvent(session, event)
		end
	end
end

------------------------------------------------------------------------
-- Queries
------------------------------------------------------------------------

function StickerRenderer.GetSession(sessionId: string?)
	return sessionId and sessions[sessionId]
end

function StickerRenderer.GetCurrentSession()
	return StickerRenderer.CurrentSessionId and sessions[StickerRenderer.CurrentSessionId]
end

function StickerRenderer.GetRecordFromPart(part: Instance)
	return partLookup[part :: BasePart]
end

function StickerRenderer.GetSessionFolder(): Folder
	return rootFolder
end

-- Alive, attached records near `position` sorted by distance.
function StickerRenderer.QueryRadius(session, position: Vector3, radius: number, filter: ((any) -> boolean)?): { any }
	local results = {}
	if not session then
		return results
	end
	local minX, minY, minZ = cellOf(position - Vector3.one * radius)
	local maxX, maxY, maxZ = cellOf(position + Vector3.one * radius)
	local radiusSq = radius * radius
	for x = minX, maxX do
		for y = minY, maxY do
			for z = minZ, maxZ do
				local cell = session.Grid[cellKey(x, y, z)]
				if cell then
					for _, record in ipairs(cell) do
						if record.Alive and record.Part and not record.Detached then
							local offset = record.Position - position
							local distSq = offset:Dot(offset)
							if distSq <= radiusSq and (not filter or filter(record)) then
								record._dist = distSq
								table.insert(results, record)
							end
						end
					end
				end
			end
		end
	end
	table.sort(results, function(a, b)
		return a._dist < b._dist
	end)
	return results
end

function StickerRenderer.GetAliveRecords(session): { any }
	local list = {}
	if session then
		for _, record in pairs(session.Records) do
			if record.Alive and not record.Detached then
				table.insert(list, record)
			end
		end
	end
	return list
end

------------------------------------------------------------------------
-- Frame update
------------------------------------------------------------------------

local function update()
	local now = os.clock()

	-- Build parts gradually so huge levels never freeze the client
	local budget = BUILD_BUDGET
	for _, session in pairs(sessions) do
		while budget > 0 and #session.BuildQueue > 0 do
			local record = table.remove(session.BuildQueue)
			buildRecord(session, record)
			budget -= 1
		end
		if not session.Ready and session.Received >= session.Total and #session.BuildQueue == 0 then
			session.Ready = true
			local alive = 0
			for _, record in pairs(session.Records) do
				if record.Alive then
					alive += 1
				end
			end
			session.Alive = alive
			StickerRenderer.SessionReady:Fire(session)
			if session.Kind == "Match" then
				-- Lets the server start the level once everyone's stickers are built
				Remotes.ClientReady:FireServer(session.Id)
			end
			local pending = session.PendingEvents
			session.PendingEvents = {}
			for _, event in ipairs(pending) do
				processEvent(session, event)
			end
		end
	end

	-- Active peels
	for record in pairs(activePeels) do
		if not record.Part or not record.Peel then
			activePeels[record] = nil
		else
			StickerRenderer.RenderPeel(record, StickerRenderer.GetCurrentProgress(record))
		end
	end

	-- Flying (torn-off) stickers
	for i = #flying, 1, -1 do
		local fly = flying[i]
		local t = (now - fly.Start) / fly.Duration
		if t >= 1 then
			for _, part in ipairs(fly.Parts) do
				releasePart(part)
			end
			table.remove(flying, i)
		else
			local elapsed = now - fly.Start
			local position = fly.Origin.Position + fly.Velocity * elapsed + Vector3.new(0, -30, 0) * elapsed * elapsed * 0.5
			local rotation = fly.Origin.Rotation * CFrame.Angles(fly.Spin.X * elapsed, fly.Spin.Y * elapsed, fly.Spin.Z * elapsed)
			local cf = CFrame.new(position) * rotation
			local scale = 1 - 0.65 * t
			local transparency = if t > 0.45 then (t - 0.45) / 0.55 else 0
			local flap = fly.Parts[1]
			local backing = fly.Parts[2]
			flap.CFrame = cf
			flap.Size = fly.Sizes[1] * scale
			flap.Transparency = transparency
			backing.CFrame = cf * fly.BackingOffset
			backing.Size = fly.Sizes[2] * scale
			backing.Transparency = transparency
		end
	end

	-- Artwork LOD around the player
	if now - lastArtUpdate > ART_INTERVAL then
		lastArtUpdate = now
		local character = LOCAL_PLAYER.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local camera = Workspace.CurrentCamera
		local focus = if root and root:IsA("BasePart") then root.Position elseif camera then camera.Focus.Position else nil
		updateArt(focus)
	end

	-- Rainbow stickers cycle hue
	if next(rainbowRecords) then
		local hue = (now * 0.35) % 1
		for record in pairs(rainbowRecords) do
			if record.Part then
				local color = Color3.fromHSV((hue + record.Id * 0.13) % 1, 0.75, 1)
				record.Part.Color = color
				if record.Flap then
					record.Flap.Color = color
				end
			else
				rainbowRecords[record] = nil
			end
		end
	end
end

function StickerRenderer.Init(controllers)
	Controllers = controllers
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "ClientStickers"
	rootFolder.Parent = Workspace
	artFolder = Instance.new("Folder")
	artFolder.Name = "StickerArt"
	artFolder.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
end

function StickerRenderer.Start()
	Remotes.StickerData.OnClientEvent:Connect(onStickerData)
	Remotes.StickerUpdate.OnClientEvent:Connect(onStickerUpdate)
	RunService.RenderStepped:Connect(update)

	local DataController = Controllers.DataController
	local function applySettings(data)
		if data and data.Settings then
			lowVFX = data.Settings.LowVFX == true
			showOthersVFX = data.Settings.ShowOthersVFX ~= false
		end
	end
	DataController.Changed:Connect(applySettings)
	applySettings(DataController.Get())
end

return StickerRenderer
