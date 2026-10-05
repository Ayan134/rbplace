--[[
	LobbyBuilder
	A cozy fenced yard (first-person friendly, everything a short walk away):
	  * dirt paths (real terrain) between the spawn, the four room circles, the walk-in
	    shop and the practice sticker pile
	  * walk-in shop (garage) next to an orange house, trash cans to sell your bag
	  * "How to play" boards, giant mushrooms, flowers, a market stall
	  * white picket fence, with trees, grassy hills and rocky mountains beyond it

	If Workspace already contains a "Lobby" model (hand-made in Studio), it is used as-is;
	it needs a SpawnLocation, a RoomPads model and a "ShowcaseAnchor" part (optional).
]]

local Workspace = game:GetService("Workspace")

local Decor = require(script.Parent.Decor)
local ShopBuilder = require(script.Parent.ShopBuilder)

local LobbyBuilder = {}

local HALF_X, HALF_Z = 70, 60
LobbyBuilder.PadCenters = {
	Vector3.new(-50, 0, -14),
	Vector3.new(-44, 0, 3),
	Vector3.new(-38, 0, 20),
	Vector3.new(-32, 0, 37),
}

local function part(parent: Instance, props): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Name = props.Name or "Part"
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	if props.Shape and p:IsA("Part") then
		p.Shape = props.Shape
	end
	p.Transparency = props.Transparency or 0
	p.Anchored = true
	p.CanCollide = if props.CanCollide == nil then true else props.CanCollide
	p.CanTouch = false
	p.CastShadow = if props.CastShadow == nil then true else props.CastShadow
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function vcyl(center: Vector3, height: number, diameter: number)
	return Vector3.new(height, diameter, diameter), CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
end

local function outlinedLabel(parent: Instance, name: string, text: string, color: Color3, size: UDim2, position: UDim2, stroke: number?)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = parent
	local outline = Instance.new("UIStroke")
	outline.Thickness = stroke or 3
	outline.Color = Color3.fromRGB(16, 18, 38)
	outline.Parent = label
	return label
end

-- Room circle: translucent white disc on the dirt with a glowing rim and a floating sign
local function roomPad(parent: Instance, index: number, center: Vector3)
	local pad = Instance.new("Model")
	pad.Name = "Pad" .. index
	pad:SetAttribute("PadIndex", index)
	pad.Parent = parent
	local ringSize, ringCF = vcyl(center + Vector3.new(0, 0.12, 0), 0.24, 14)
	part(pad, { Name = "Ring", Size = ringSize, CFrame = ringCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false, CastShadow = false })
	local discSize, discCF = vcyl(center + Vector3.new(0, 0.16, 0), 0.26, 12.6)
	local disc = part(pad, { Name = "Disc", Size = discSize, CFrame = discCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(250, 246, 236), Transparency = 0.45, CanCollide = false, CastShadow = false })
	local numberGui = Instance.new("SurfaceGui")
	numberGui.Face = Enum.NormalId.Right
	numberGui.PixelsPerStud = 20
	numberGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	numberGui.LightInfluence = 0.2
	numberGui.Parent = disc
	local number = outlinedLabel(numberGui, "Number", tostring(index), Color3.new(1, 1, 1), UDim2.fromScale(0.4, 0.4), UDim2.fromScale(0.3, 0.3), 4)
	number.TextTransparency = 0.35

	local anchor = part(pad, { Name = "SignAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center + Vector3.new(0, 6.5, 0)), Transparency = 1, CanCollide = false })
	anchor.CanQuery = false
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RoomSign"
	billboard.Size = UDim2.fromOffset(260, 74)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 90
	billboard.Parent = anchor
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 1
	panel.Parent = billboard
	outlinedLabel(panel, "Title", "ROOM " .. index, Color3.new(1, 1, 1), UDim2.new(1, 0, 0, 38), UDim2.new(), 3)
	outlinedLabel(panel, "Status", "Step in to create a room", Color3.fromRGB(255, 230, 120), UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 42), 2.5)
	return pad
end

-- Big wooden sign with the game title, standing behind the back fence
local function titleSign(parent: Instance, cframe: CFrame)
	local model = Instance.new("Model")
	model.Name = "TitleSign"
	model.Parent = parent
	for _, x in ipairs({ -16, 16 }) do
		part(model, { Name = "Post", Size = Vector3.new(1.6, 22, 1.6), CFrame = cframe * CFrame.new(x, 11, 0.6), Color = Color3.fromRGB(120, 80, 48), Material = Enum.Material.Wood })
	end
	local board = part(model, { Name = "Board", Size = Vector3.new(40, 11, 1), CFrame = cframe * CFrame.new(0, 17, 0), Color = Color3.fromRGB(196, 140, 86), Material = Enum.Material.WoodPlanks })
	part(model, { Name = "Frame", Size = Vector3.new(41.5, 12.5, 0.8), CFrame = cframe * CFrame.new(0, 17, 0.3), Color = Color3.fromRGB(120, 80, 48), Material = Enum.Material.Wood })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0.3
	gui.Parent = board
	outlinedLabel(gui, "Title", "STICKER PEEL", Color3.fromRGB(255, 214, 70), UDim2.new(1, -30, 0.62, 0), UDim2.fromOffset(15, 8), 6)
	outlinedLabel(gui, "Subtitle", "peel • collect • sell", Color3.new(1, 1, 1), UDim2.new(1, -30, 0.28, 0), UDim2.new(0, 15, 0.64, 0), 4)
	-- Decorative giant stickers on the corners
	local stickers = { { "⭐", Color3.fromRGB(255, 214, 70) }, { "🍩", Color3.fromRGB(255, 140, 190) }, { "🌈", Color3.fromRGB(120, 200, 255) }, { "🍓", Color3.fromRGB(255, 120, 120) } }
	for i, offset in ipairs({ Vector3.new(-20, 21.5, -0.6), Vector3.new(20, 21.5, -0.6), Vector3.new(-20, 12.5, -0.6), Vector3.new(20, 12.5, -0.6) }) do
		local holder = part(model, { Name = "BigSticker", Size = Vector3.new(5, 5, 0.1), CFrame = cframe * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(12 * (if i % 2 == 0 then 1 else -1))), Transparency = 1, CanCollide = false, CastShadow = false })
		local stickerGui = Instance.new("SurfaceGui")
		stickerGui.Face = Enum.NormalId.Front
		stickerGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		stickerGui.PixelsPerStud = 24
		stickerGui.Parent = holder
		local border = Instance.new("Frame")
		border.Size = UDim2.fromScale(1, 1)
		border.BackgroundColor3 = Color3.new(1, 1, 1)
		border.Parent = stickerGui
		Instance.new("UICorner", border).CornerRadius = UDim.new(0.5, 0)
		local paper = Instance.new("Frame")
		paper.Size = UDim2.fromScale(0.86, 0.86)
		paper.Position = UDim2.fromScale(0.07, 0.07)
		paper.BackgroundColor3 = stickers[i][2]
		paper.Parent = border
		Instance.new("UICorner", paper).CornerRadius = UDim.new(0.5, 0)
		local art = Instance.new("TextLabel")
		art.Size = UDim2.fromScale(0.7, 0.7)
		art.Position = UDim2.fromScale(0.15, 0.15)
		art.BackgroundTransparency = 1
		art.Text = stickers[i][1]
		art.TextScaled = true
		art.Parent = paper
	end
	return model
end

function LobbyBuilder.Build()
	local existing = Workspace:FindFirstChild("Lobby")
	if existing then
		return existing
	end

	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	local rng = Random.new(2025)

	-- Ground part: only for sticker occlusion tests (real terrain grass is filled at runtime)
	part(lobby, { Name = "Ground", Size = Vector3.new(420, 2, 420), CFrame = CFrame.new(0, -1, 0), Color = Color3.fromRGB(106, 170, 72), Material = Enum.Material.Grass })

	local grounds = Instance.new("Folder")
	grounds.Name = "Grounds"
	grounds.Parent = lobby

	-- Dirt paths (terrain ground at runtime)
	local spawnPosition = Vector3.new(0, 0, 44)
	local shopFront = Vector3.new(-22, 0, -26)
	local showcase = Vector3.new(24, 0, -8)
	local function path(from: Vector3, to: Vector3, width: number)
		local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		local length = flat.Magnitude
		Decor.DirtPath(grounds, CFrame.lookAt((from + to) / 2, to), Vector2.new(width, length + width * 0.6))
	end
	Decor.DirtCircle(grounds, spawnPosition, 11)
	path(spawnPosition, Vector3.new(0, 0, 8), 10)
	Decor.DirtCircle(grounds, Vector3.new(0, 0, 6), 12)
	path(Vector3.new(0, 0, 6), shopFront, 10)
	path(Vector3.new(0, 0, 6), showcase, 9)
	Decor.DirtCircle(grounds, showcase, 26)
	Decor.DirtPath(grounds, CFrame.new(-22, 0, -36), Vector2.new(34, 26))
	-- Strip under the room circles and a link to it
	path(LobbyBuilder.PadCenters[1] + Vector3.new(-3, 0, -6), LobbyBuilder.PadCenters[4] + Vector3.new(3, 0, 6), 20)
	path(Vector3.new(0, 0, 6), Vector3.new(-30, 0, 10), 8)
	path(spawnPosition, LobbyBuilder.PadCenters[4], 8)

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 0.2, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(196, 150, 100)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby

	-- Room circles
	local rooms = Instance.new("Model")
	rooms.Name = "RoomPads"
	rooms.Parent = lobby
	for index, center in ipairs(LobbyBuilder.PadCenters) do
		roomPad(rooms, index, center)
	end

	-- Walk-in shop with an orange house next to it (both face the yard, +Z)
	local facingYard = CFrame.Angles(0, math.pi, 0)
	ShopBuilder.Build(lobby, CFrame.new(-22, 0, -40) * facingYard)
	Decor.Building(grounds, CFrame.new(-54, 0, -43) * facingYard, Vector3.new(22, 13, 20), Color3.fromRGB(236, 128, 64), {
		Roof = "Gable",
		RoofColor = Color3.fromRGB(46, 50, 62),
		TrimColor = Color3.fromRGB(250, 250, 248),
		WindowColor = Color3.fromRGB(170, 210, 240),
		DoorColor = Color3.fromRGB(50, 54, 66),
		Floors = 1,
	})
	part(grounds, { Name = "Porch", Size = Vector3.new(12, 0.8, 5), CFrame = CFrame.new(-54, 0.4, -30.5), Color = Color3.fromRGB(240, 236, 228) })

	-- Trash cans to sell the bag
	Decor.TrashCan(grounds, Vector3.new(8, 0, 4))
	Decor.TrashCan(grounds, Vector3.new(50, 0, -26))
	Decor.TrashCan(grounds, Vector3.new(2, 0, -21))

	-- How to play
	Decor.NoticeBoard(grounds, CFrame.lookAt(Vector3.new(15, 0, 46), Vector3.new(0, 0, 44)), "HOW TO PLAY", {
		"1. Aim at a sticker, hold E to peel",
		"2. Bag full? Walk to a trash can",
		"3. Buy bigger bags + tools in the shop",
		"4. Step into a circle to play a level",
	})
	Decor.NoticeBoard(grounds, CFrame.lookAt(Vector3.new(-16, 0, 30), Vector3.new(-38, 0, 20)), "PLAY TOGETHER", {
		"Step into a free circle",
		"Pick level, difficulty, players",
		"Friends only? Tick the box",
		"Press START when ready!",
	})

	-- Market stall and benches by the sticker pile
	Decor.Stall(grounds, CFrame.lookAt(Vector3.new(50, 0, 30), Vector3.new(30, 0, 30)), Color3.fromRGB(255, 120, 160), "STICKERS")
	Decor.Balloons(grounds, Vector3.new(50, 3.6, 33.5), 5, rng)
	for _, angle in ipairs({ 200, 250, 290 }) do
		local position = showcase + Vector3.new(math.cos(math.rad(angle)) * 30, 0.1, math.sin(math.rad(angle)) * 30)
		Decor.Bench(grounds, CFrame.lookAt(position, showcase + Vector3.new(0, 0.1, 0)))
	end
	for _, position in ipairs({ Vector3.new(12, 0, 22), Vector3.new(-12, 0, 22), Vector3.new(30, 0, 22) }) do
		Decor.Lamp(grounds, position, 10)
	end

	-- Giant mushrooms, little mushroom clusters, flowers, rocks and bushes
	Decor.Mushroom(grounds, Vector3.new(-62, 0, 22), 13, nil, rng)
	Decor.Mushroom(grounds, Vector3.new(60, 0, 46), 11, nil, rng)
	Decor.Mushroom(grounds, Vector3.new(62, 0, -50), 12, nil, rng)
	Decor.Mushroom(grounds, Vector3.new(-66, 0, -14), 8, nil, rng)
	for _, def in ipairs({
		{ Vector3.new(-58, 0, 32), nil }, { Vector3.new(54, 0, 40), nil }, { Vector3.new(10, 0, -52), Color3.fromRGB(80, 150, 235) },
		{ Vector3.new(-8, 0, 54), Color3.fromRGB(80, 150, 235) }, { Vector3.new(64, 0, 0), nil }, { Vector3.new(36, 0, -52), Color3.fromRGB(80, 150, 235) },
		{ Vector3.new(-64, 0, 50), nil }, { Vector3.new(26, 0, 54), Color3.fromRGB(80, 150, 235) },
	}) do
		Decor.MushroomCluster(grounds, def[1], rng:NextInteger(2, 4), rng, def[2])
	end
	for _, position in ipairs({
		Vector3.new(-10, 0, 36), Vector3.new(22, 0, 34), Vector3.new(58, 0, 18), Vector3.new(-60, 0, 40), Vector3.new(4, 0, -48),
		Vector3.new(46, 0, -46), Vector3.new(-62, 0, 0), Vector3.new(34, 0, 50),
	}) do
		Decor.FlowerBed(grounds, position, rng:NextNumber(2, 3), rng)
	end
	for i = 0, 15 do
		local t = i / 16
		local position = if i < 8
			then Vector3.new(-HALF_X + 4 + t * 2 * (HALF_X * 2 - 8), 0, HALF_Z - 3)
			else Vector3.new(HALF_X - 3, 0, -HALF_Z + 6 + (t - 0.5) * 2 * (HALF_Z * 2 - 12))
		if (position - spawnPosition).Magnitude > 14 then
			Decor.Bush(grounds, position, rng:NextNumber(3, 4.5))
		end
	end
	for _, position in ipairs({ Vector3.new(-66, 0, -56), Vector3.new(66, 0, 56), Vector3.new(40, 0, -56), Vector3.new(-40, 0, 56) }) do
		Decor.Rock(grounds, position, rng:NextNumber(3, 5), rng)
	end

	-- White picket fence around the yard
	local corners = {
		Vector3.new(-HALF_X, 0, -HALF_Z), Vector3.new(HALF_X, 0, -HALF_Z),
		Vector3.new(HALF_X, 0, HALF_Z), Vector3.new(-HALF_X, 0, HALF_Z),
	}
	for i = 1, 4 do
		Decor.PicketFence(grounds, corners[i], corners[(i % 4) + 1])
	end
	for _, def in ipairs({ { 0, -HALF_Z - 1, HALF_X * 2, 2 }, { 0, HALF_Z + 1, HALF_X * 2, 2 }, { -HALF_X - 1, 0, 2, HALF_Z * 2 }, { HALF_X + 1, 0, 2, HALF_Z * 2 } }) do
		local wall = part(lobby, { Name = "Boundary", Size = Vector3.new(def[3], 60, def[4]), CFrame = CFrame.new(def[1], 30, def[2]), Transparency = 1 })
		wall.CanQuery = false
	end

	-- Beyond the fence: title sign, trees, hills, mountains and balloons in the sky
	titleSign(grounds, CFrame.new(0, 0, -HALF_Z - 8) * facingYard)
	local outer = Instance.new("Folder")
	outer.Name = "Outside"
	outer.Parent = grounds
	for i = 0, 29 do
		local angle = (i / 30) * math.pi * 2
		local radius = rng:NextNumber(98, 128)
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local style = if rng:NextNumber() < 0.45 then "Pine" else "Round"
		Decor.Tree(outer, position, rng:NextNumber(1.3, 1.8), style, rng)
	end
	for i = 0, 13 do
		local angle = (i / 14) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local radius = rng:NextNumber(150, 190)
		Decor.Hill(outer, Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), rng:NextNumber(30, 48))
	end
	for _, def in ipairs({
		{ Vector3.new(60, 0, -250), 80 }, { Vector3.new(-120, 0, -230), 70 }, { Vector3.new(230, 0, -120), 75 },
		{ Vector3.new(250, 0, 60), 65 }, { Vector3.new(-250, 0, -40), 72 }, { Vector3.new(-200, 0, 170), 60 },
	}) do
		Decor.Mountain(outer, def[1], def[2], rng)
	end
	Decor.HotAirBalloon(outer, Vector3.new(-110, 80, -120), Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 220, 110))
	Decor.HotAirBalloon(outer, Vector3.new(140, 96, 60), Color3.fromRGB(110, 190, 255), Color3.fromRGB(255, 255, 255))

	-- Showcase anchor (the practice sticker pile is placed here by LevelService)
	part(lobby, { Name = "ShowcaseAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(showcase + Vector3.new(0, 0.05, 0)), Transparency = 1, CanCollide = false })

	lobby.Parent = Workspace
	return lobby
end

-- Runtime-only polish (terrain can't be stored by the build tools): grass terrain,
-- dirt paths, hills and mountains, terrain colors and soft clouds.
function LobbyBuilder.Decorate(lobby: Model)
	local terrain = Workspace.Terrain
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(0, -5, 0), Vector3.new(760, 10, 760), Enum.Material.Grass)
	end)
	local ground = lobby:FindFirstChild("Ground")
	if ok and ground and ground:IsA("BasePart") then
		-- Terrain takes over walking; the part stays for sticker occlusion tests only
		ground.Transparency = 1
		ground.CanCollide = false
	end
	if ok then
		Decor.ApplyTerrain(lobby)
	end
	pcall(function()
		(terrain :: any).Decoration = false
		terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(106, 172, 70))
		terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(156, 112, 72))
		terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(128, 126, 132))
		terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(226, 206, 160))
	end)
	if not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.5
		clouds.Density = 0.5
		clouds.Color = Color3.fromRGB(255, 255, 255)
		clouds.Parent = terrain
	end
end

return LobbyBuilder
