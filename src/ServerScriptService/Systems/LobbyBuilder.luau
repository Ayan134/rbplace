--[[
	LobbyBuilder
	Builds the central lobby: plaza, paths, trees, lamps, kiosks (Play / Levels / Upgrades /
	Shop) with ProximityPrompts, a big title sign and a sticker-covered showcase object.

	If Workspace already contains a "Lobby" model (hand-made in Studio), it is used as-is;
	it only needs a SpawnLocation and a "ShowcaseAnchor" part (optional).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Decor = require(script.Parent.Decor)
local StickerConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StickerConfig"))

local LobbyBuilder = {}

local GRASS = Color3.fromRGB(116, 190, 86)
local PAVEMENT = Color3.fromRGB(226, 220, 210)
local PATH = Color3.fromRGB(240, 204, 150)

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
	p.CastShadow = if props.CastShadow == nil then true else props.CastShadow
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function vcyl(center: Vector3, height: number, diameter: number)
	return Vector3.new(height, diameter, diameter), CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
end

local function signText(target: BasePart, face: Enum.NormalId, text: string, color: Color3, background: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 30
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if background then 0 else 1
	label.BackgroundColor3 = background or Color3.new()
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.Parent = label
	return gui
end

-- A kiosk with a canopy, sign and ProximityPrompt that opens a UI on the client.
local function kiosk(parent: Instance, cframe: CFrame, title: string, color: Color3, openUI: string, actionText: string)
	local model = Instance.new("Model")
	model.Name = title .. "Kiosk"
	model.Parent = parent
	part(model, { Name = "Counter", Size = Vector3.new(12, 4, 4), CFrame = cframe * CFrame.new(0, 2, 0), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.SmoothPlastic })
	part(model, { Name = "CounterTop", Size = Vector3.new(12.6, 0.5, 4.6), CFrame = cframe * CFrame.new(0, 4.25, 0), Color = color })
	for _, x in ipairs({ -5.6, 5.6 }) do
		part(model, { Name = "Pole", Size = Vector3.new(0.6, 9, 0.6), CFrame = cframe * CFrame.new(x, 4.5, 2.6), Color = Color3.fromRGB(250, 250, 250) })
	end
	-- Striped canopy
	for i = 0, 5 do
		part(model, {
			Name = "Canopy",
			Class = "WedgePart",
			Size = Vector3.new(2.2, 1.6, 6),
			CFrame = cframe * CFrame.new(-5.5 + i * 2.2, 9.8, 0.6),
			Color = if i % 2 == 0 then color else Color3.fromRGB(255, 255, 255),
		})
	end
	local board = part(model, { Name = "Sign", Size = Vector3.new(11, 3, 0.4), CFrame = cframe * CFrame.new(0, 12, 2.8), Color = color })
	signText(board, Enum.NormalId.Front, title, Color3.fromRGB(255, 255, 255))

	local promptPart = part(model, { Name = "PromptAnchor", Size = Vector3.new(1, 1, 1), CFrame = cframe * CFrame.new(0, 3, -2.6), Transparency = 1, CanCollide = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = title
	prompt.ActionText = actionText
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OpenUI", openUI)
	prompt.Parent = promptPart
	return model
end

-- A die-cut sticker painted on a SurfaceGui: white border, colored paper, emoji art and a soft gloss
local function wallSticker(parent: Instance, cframe: CFrame, diameter: number, art: string, paper: Color3, round: boolean)
	local holder = part(parent, { Name = "WallSticker", Size = Vector3.new(diameter, diameter, 0.05), CFrame = cframe, Transparency = 1, CanCollide = false, CastShadow = false })
	holder.CanQuery = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0.5
	gui.Parent = holder
	local radius = if round then UDim.new(0.5, 0) else UDim.new(0.2, 0)
	local border = Instance.new("Frame")
	border.Size = UDim2.fromScale(1, 1)
	border.BackgroundColor3 = Color3.new(1, 1, 1)
	border.BorderSizePixel = 0
	border.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = border
	local paperFrame = Instance.new("Frame")
	paperFrame.Size = UDim2.fromScale(0.86, 0.86)
	paperFrame.Position = UDim2.fromScale(0.5, 0.5)
	paperFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	paperFrame.BackgroundColor3 = paper
	paperFrame.BorderSizePixel = 0
	paperFrame.Parent = border
	corner:Clone().Parent = paperFrame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.74, 0.74)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = art
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = paperFrame
	local gloss = Instance.new("Frame")
	gloss.Size = UDim2.fromScale(1, 1)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BorderSizePixel = 0
	gloss.Parent = border
	corner:Clone().Parent = gloss
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 60
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.38, 0.82),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = gloss
	return holder
end

local function duck(parent: Instance, cframe: CFrame)
	part(parent, { Name = "DuckBody", Size = Vector3.new(1.6, 1.1, 2.2), CFrame = cframe * CFrame.new(0, 0.35, 0), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 226, 90), CanCollide = false })
	part(parent, { Name = "DuckHead", Size = Vector3.new(1, 1, 1), CFrame = cframe * CFrame.new(0, 1.2, -0.75), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 226, 90), CanCollide = false })
	part(parent, { Name = "DuckBeak", Size = Vector3.new(0.5, 0.22, 0.5), CFrame = cframe * CFrame.new(0, 1.1, -1.3), Color = Color3.fromRGB(255, 140, 40), CanCollide = false })
	for _, x in ipairs({ -0.28, 0.28 }) do
		part(parent, { Name = "DuckEye", Size = Vector3.new(0.16, 0.16, 0.16), CFrame = cframe * CFrame.new(x, 1.35, -1.18), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(20, 20, 24), CanCollide = false, CastShadow = false })
	end
end

-- Giant capsule machine full of sticker capsules
local function capsuleMachine(parent: Instance, position: Vector3, rng: Random)
	local model = Instance.new("Model")
	model.Name = "CapsuleMachine"
	model.Parent = parent
	local base, baseCF = vcyl(position + Vector3.new(0, 3, 0), 6, 9)
	part(model, { Name = "Base", Size = base, CFrame = baseCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(240, 84, 110) })
	local rim, rimCF = vcyl(position + Vector3.new(0, 6.2, 0), 0.6, 10)
	part(model, { Name = "Rim", Size = rim, CFrame = rimCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 255, 255) })
	local globeCenter = position + Vector3.new(0, 11.5, 0)
	part(model, { Name = "Globe", Size = Vector3.new(11, 11, 11), CFrame = CFrame.new(globeCenter), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(220, 240, 255), Material = Enum.Material.Glass, Transparency = 0.6, CastShadow = false })
	local colors = { Color3.fromRGB(255, 120, 150), Color3.fromRGB(255, 210, 90), Color3.fromRGB(110, 222, 164), Color3.fromRGB(120, 180, 255), Color3.fromRGB(190, 150, 255), Color3.fromRGB(255, 160, 90) }
	for i = 1, 26 do
		local offset = Vector3.new(rng:NextNumber(-3.4, 3.4), rng:NextNumber(-4, 1.2), rng:NextNumber(-3.4, 3.4))
		if offset.Magnitude < 4.2 then
			part(model, { Name = "Capsule", Size = Vector3.new(1.7, 1.7, 1.7), CFrame = CFrame.new(globeCenter + offset), Shape = Enum.PartType.Ball, Color = colors[(i % #colors) + 1], CanCollide = false, CastShadow = false })
		end
	end
	local cap, capCF = vcyl(position + Vector3.new(0, 17.2, 0), 1, 4)
	part(model, { Name = "Cap", Size = cap, CFrame = capCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(240, 84, 110) })
	part(model, { Name = "Knob", Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(position + Vector3.new(0, 18.2, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 210, 90) })
	part(model, { Name = "Dial", Size = Vector3.new(0.6, 2.6, 2.6), CFrame = CFrame.new(position + Vector3.new(0, 3.6, -4.6)) * CFrame.Angles(0, math.rad(90), 0), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(230, 230, 236), Material = Enum.Material.Metal })
	part(model, { Name = "Chute", Size = Vector3.new(2.6, 2, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 1.4, -4.4)), Color = Color3.fromRGB(46, 48, 58) })
end

-- Extra scenery around the plaza: a duck pond, a sticker photo wall, a welcome arch,
-- flags to the room circles, a capsule machine, balloons and a horizon backdrop
function LobbyBuilder.BuildGrounds(lobby: Model)
	local rng = Random.new(2024)
	local grounds = Instance.new("Folder")
	grounds.Name = "Grounds"
	grounds.Parent = lobby

	-- Duck pond (east)
	local pond = Instance.new("Folder")
	pond.Name = "Pond"
	pond.Parent = grounds
	local pondCenter = Vector3.new(104, 0, 44)
	Decor.Water(pond, CFrame.new(pondCenter + Vector3.new(0, -2, 0)), Vector3.new(44, 4, 28))
	for i = 0, 19 do
		local angle = (i / 20) * math.pi * 2
		local position = pondCenter + Vector3.new(math.cos(angle) * 24.5, -0.3, math.sin(angle) * 16.5)
		if not (angle > math.rad(250) and angle < math.rad(290)) then -- leave room for the dock
			Decor.Rock(pond, position, rng:NextNumber(2.2, 4.2), rng)
		end
	end
	for _ = 1, 8 do
		local position = pondCenter + Vector3.new(rng:NextNumber(-15, 15), 0.06, rng:NextNumber(-9, 9))
		local padSize, padCF = vcyl(position, 0.12, rng:NextNumber(1.8, 2.8))
		part(pond, { Name = "LilyPad", Size = padSize, CFrame = padCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(76, 160, 80), Material = Enum.Material.Grass, CanCollide = false, CastShadow = false })
		if rng:NextNumber() < 0.5 then
			part(pond, { Name = "LilyFlower", Size = Vector3.new(0.7, 0.5, 0.7), CFrame = CFrame.new(position + Vector3.new(0.3, 0.3, 0.2)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 170, 210), CanCollide = false, CastShadow = false })
		end
	end
	for i, offset in ipairs({ Vector3.new(-8, 0, 4), Vector3.new(-5, 0, 6.5), Vector3.new(9, 0, -3) }) do
		duck(pond, CFrame.new(pondCenter + offset) * CFrame.Angles(0, i * 1.9, 0))
	end
	-- Reeds
	for _ = 1, 22 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local base = pondCenter + Vector3.new(math.cos(angle) * 21, 0, math.sin(angle) * 13.5)
		local height = rng:NextNumber(3, 5)
		local reed, reedCF = vcyl(base + Vector3.new(0, height / 2, 0), height, 0.2)
		part(pond, { Name = "Reed", Size = reed, CFrame = reedCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(90, 150, 70), Material = Enum.Material.Grass, CanCollide = false, CastShadow = false })
		part(pond, { Name = "Cattail", Size = Vector3.new(0.45, 1, 0.45), CFrame = CFrame.new(base + Vector3.new(0, height, 0)), Color = Color3.fromRGB(120, 80, 50), CanCollide = false, CastShadow = false })
	end
	-- Wooden dock reaching in from the path side
	local dockCenter = pondCenter + Vector3.new(0, 0.7, -12)
	for i = -3, 3 do
		part(pond, { Name = "DockPlank", Size = Vector3.new(5, 0.35, 1.9), CFrame = CFrame.new(dockCenter + Vector3.new(0, 0, i * 2)), Color = Color3.fromRGB(176, 124, 76):Lerp(Color3.fromRGB(150, 104, 62), (i + 3) / 6), Material = Enum.Material.WoodPlanks })
	end
	for _, x in ipairs({ -2.3, 2.3 }) do
		for _, z in ipairs({ -6.5, 0, 6.5 }) do
			part(pond, { Name = "DockPost", Size = Vector3.new(0.6, 5, 0.6), CFrame = CFrame.new(dockCenter + Vector3.new(x, -1.6, z)), Color = Color3.fromRGB(120, 84, 52), Material = Enum.Material.Wood })
		end
	end
	for _, def in ipairs({ { Vector3.new(-14, 0, -20) }, { Vector3.new(14, 0, -20) }, { Vector3.new(30, 0, 4) } }) do
		local position = pondCenter + def[1]
		Decor.Bench(pond, CFrame.lookAt(position + Vector3.new(0, 0.1, 0), pondCenter + Vector3.new(0, 0.1, 0)))
	end
	for _, offset in ipairs({ Vector3.new(-30, 0, 10), Vector3.new(-22, 0, 24), Vector3.new(4, 0, 26), Vector3.new(26, 0, 22), Vector3.new(34, 0, -12) }) do
		Decor.Tree(pond, pondCenter + offset, rng:NextNumber(1, 1.25), "Blossom", rng)
	end
	Decor.Lamp(pond, pondCenter + Vector3.new(-6, 0, -18), 9)
	Decor.Lamp(pond, pondCenter + Vector3.new(6, 0, -18), 9)

	-- Sticker photo wall (west)
	local wall = Instance.new("Folder")
	wall.Name = "StickerWall"
	wall.Parent = grounds
	local wallCF = CFrame.lookAt(Vector3.new(-116, 11, 40), Vector3.new(0, 11, 40))
	part(wall, { Name = "Wall", Size = Vector3.new(46, 22, 2), CFrame = wallCF, Color = Color3.fromRGB(250, 248, 244) })
	part(wall, { Name = "WallCap", Size = Vector3.new(47.5, 1.2, 2.8), CFrame = wallCF * CFrame.new(0, 11.4, 0), Color = Color3.fromRGB(110, 222, 164) })
	part(wall, { Name = "WallBase", Size = Vector3.new(47.5, 1.4, 3), CFrame = wallCF * CFrame.new(0, -10.4, 0), Color = Color3.fromRGB(60, 62, 72) })
	local designs = StickerConfig.Designs
	local palette = StickerConfig.Palette
	for gx = -4, 4 do
		for gy = -2, 2 do
			local x = gx * 4.9 + rng:NextNumber(-0.9, 0.9)
			local y = gy * 3.9 + rng:NextNumber(-0.7, 0.7)
			wallSticker(
				wall,
				wallCF * CFrame.new(x, y, -1.06 - (gx + gy) % 3 * 0.01) * CFrame.Angles(0, 0, rng:NextNumber(-0.4, 0.4)),
				rng:NextNumber(2.8, 4.4),
				designs[rng:NextInteger(1, #designs)],
				palette[rng:NextInteger(1, #palette)],
				rng:NextNumber() < 0.6
			)
		end
	end
	local wallSign = part(wall, { Name = "WallSign", Size = Vector3.new(26, 3.6, 0.4), CFrame = wallCF * CFrame.new(0, 14.2, 0), Color = Color3.fromRGB(28, 28, 34) })
	signText(wallSign, Enum.NormalId.Front, "STICK  •  PEEL  •  REPEAT", Color3.fromRGB(255, 255, 255))
	for _, x in ipairs({ -10, 10 }) do
		part(wall, { Name = "SignLeg", Size = Vector3.new(0.5, 2, 0.5), CFrame = wallCF * CFrame.new(x, 12.4, 0), Color = Color3.fromRGB(28, 28, 34), Material = Enum.Material.Metal })
	end
	-- Photo spot marker on the ground
	local marker = part(wall, { Name = "PhotoSpot", Size = Vector3.new(7, 0.2, 7), CFrame = CFrame.new(-100, 0.2, 40), Transparency = 1, CanCollide = false, CastShadow = false })
	local markerGui = Instance.new("SurfaceGui")
	markerGui.Face = Enum.NormalId.Top
	markerGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	markerGui.PixelsPerStud = 24
	markerGui.Parent = marker
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	ring.Parent = markerGui
	Instance.new("UICorner", ring).CornerRadius = UDim.new(0.5, 0)
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Thickness = 8
	ringStroke.Color = Color3.fromRGB(255, 255, 255)
	ringStroke.Transparency = 0.2
	ringStroke.Parent = ring
	local camera = Instance.new("TextLabel")
	camera.Size = UDim2.fromScale(0.5, 0.5)
	camera.Position = UDim2.fromScale(0.25, 0.25)
	camera.BackgroundTransparency = 1
	camera.Text = "📸"
	camera.TextScaled = true
	camera.Rotation = 90
	camera.Parent = ring
	for _, z in ipairs({ -27, 27 }) do
		Decor.Planter(wall, CFrame.new(-112, 0, 40 + z), Vector3.new(4, 2.4, 4), rng)
		Decor.Tree(wall, Vector3.new(-120, 0, 40 + z * 1.15), 1.1, "Blossom", rng)
	end
	for _, z in ipairs({ -18, 18 }) do
		Decor.Spotlight(wall, Vector3.new(-92, 0, 40 + z), wallCF.Position, Color3.fromRGB(255, 240, 220))
	end

	-- Welcome arch between the spawn and the plaza
	local arch = Instance.new("Folder")
	arch.Name = "WelcomeArch"
	arch.Parent = grounds
	for _, x in ipairs({ -10, 10 }) do
		part(arch, { Name = "ArchPillar", Size = Vector3.new(2.2, 14, 2.2), CFrame = CFrame.new(x, 7, 61), Color = Color3.fromRGB(255, 255, 255) })
		part(arch, { Name = "ArchFoot", Size = Vector3.new(3.2, 1, 3.2), CFrame = CFrame.new(x, 0.5, 61), Color = Color3.fromRGB(60, 62, 72) })
		Decor.Balloons(arch, Vector3.new(x, 14.5, 61), 6, rng)
	end
	local beam = part(arch, { Name = "ArchSign", Size = Vector3.new(24, 3.4, 1.4), CFrame = CFrame.new(0, 15.6, 61), Color = Color3.fromRGB(255, 120, 160) })
	signText(beam, Enum.NormalId.Front, "WELCOME!", Color3.fromRGB(255, 255, 255))
	signText(beam, Enum.NormalId.Back, "HAVE FUN!", Color3.fromRGB(255, 255, 255))
	Decor.Bunting(arch, Vector3.new(-10, 13.6, 61.8), Vector3.new(10, 13.6, 61.8), 9, 1.4)

	-- Flags lining the path to the room circles
	local flagColors = { Color3.fromRGB(255, 120, 150), Color3.fromRGB(255, 210, 90), Color3.fromRGB(110, 222, 164), Color3.fromRGB(120, 180, 255) }
	local flagTops = {}
	for i, z in ipairs({ -52, -63 }) do
		for side, x in ipairs({ -8.5, 8.5 }) do
			Decor.FlagPole(grounds, Vector3.new(x, 0, z), 12, flagColors[((i + side) % #flagColors) + 1])
			flagTops[side] = flagTops[side] or {}
			table.insert(flagTops[side], Vector3.new(x, 10.5, z))
		end
	end
	for _, tops in pairs(flagTops) do
		Decor.Bunting(grounds, tops[1], tops[2], 7, 1)
	end
	Decor.Bunting(grounds, Vector3.new(-8.5, 10.5, -52), Vector3.new(8.5, 10.5, -52), 10, 1.6)

	-- Capsule machine at the end of the south path
	capsuleMachine(grounds, Vector3.new(0, 0, 124), rng)
	Decor.Balloons(grounds, Vector3.new(-7, 0.5, 118), 5, rng)
	Decor.Balloons(grounds, Vector3.new(7, 0.5, 118), 5, rng)

	-- Flower corners and bushes along the hedge
	for _, cx in ipairs({ -1, 1 }) do
		for _, cz in ipairs({ -1, 1 }) do
			Decor.FlowerBed(grounds, Vector3.new(cx * 136, 0, cz * 136), 6, rng)
		end
	end
	for i = 0, 18 do
		local t = -144 + i * 16
		for _, position in ipairs({ Vector3.new(t, 0, 152), Vector3.new(t, 0, -152), Vector3.new(152, 0, t), Vector3.new(-152, 0, t) }) do
			if math.abs(position.X) > 10 or math.abs(position.Z) < 100 then
				Decor.Bush(grounds, position, rng:NextNumber(3.5, 5.5), Color3.fromRGB(70, 146, 64):Lerp(Color3.fromRGB(96, 170, 80), rng:NextNumber()))
			end
		end
	end

	-- Hot air balloons and the horizon
	Decor.HotAirBalloon(grounds, Vector3.new(-150, 78, -110), Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 220, 110))
	Decor.HotAirBalloon(grounds, Vector3.new(175, 96, 70), Color3.fromRGB(110, 190, 255), Color3.fromRGB(255, 255, 255))
	Decor.HotAirBalloon(grounds, Vector3.new(40, 118, 210), Color3.fromRGB(130, 222, 150), Color3.fromRGB(255, 170, 90))
	Decor.Backdrop(grounds, Vector3.zero, 215, rng)
end

function LobbyBuilder.Build()
	local existing = Workspace:FindFirstChild("Lobby")
	if existing then
		return existing
	end

	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"

	-- Ground
	part(lobby, { Name = "Ground", Size = Vector3.new(320, 2, 320), CFrame = CFrame.new(0, -1, 0), Color = GRASS, Material = Enum.Material.Grass })
	local size, cf = vcyl(Vector3.new(0, 0.1, 0), 0.4, 96)
	part(lobby, { Name = "Plaza", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = PAVEMENT, Material = Enum.Material.Pavement })
	size, cf = vcyl(Vector3.new(0, 0.15, 0), 0.4, 60)
	part(lobby, { Name = "PlazaInner", Size = size, CFrame = cf, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(240, 232, 220), Material = Enum.Material.Marble })

	-- Paths in four directions
	for i = 0, 3 do
		local angle = i * math.pi / 2
		part(lobby, { Name = "Path", Size = Vector3.new(12, 0.4, 70), CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.12, -80), Color = PATH, Material = Enum.Material.Sand })
	end

	-- Ring of flower beds and trees
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2 + math.pi / 12
		local position = Vector3.new(math.sin(angle) * 58, 0, math.cos(angle) * 58)
		Decor.Tree(lobby, position, 0.95 + (i % 3) * 0.12, if i % 2 == 0 then "Blossom" else "Round", Random.new(i))
		local bedSize, bedCF = vcyl(position + Vector3.new(0, 0.6, 0), 1.2, 9)
		part(lobby, { Name = "FlowerBed", Size = bedSize, CFrame = bedCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(140, 100, 70), Material = Enum.Material.Ground })
		for f = 0, 5 do
			local fa = f / 6 * math.pi * 2
			part(lobby, {
				Name = "Flower",
				Size = Vector3.new(0.9, 0.9, 0.9),
				CFrame = CFrame.new(position + Vector3.new(math.cos(fa) * 3.4, 1.5, math.sin(fa) * 3.4)),
				Shape = Enum.PartType.Ball,
				Color = ({ Color3.fromRGB(255, 90, 140), Color3.fromRGB(255, 220, 70), Color3.fromRGB(150, 110, 255) })[(f % 3) + 1],
				CanCollide = false,
			})
		end
	end
	-- Lamps around the plaza with festive string lights between them
	local lampTops = {}
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2 + math.pi / 8
		table.insert(lampTops, Decor.Lamp(lobby, Vector3.new(math.sin(angle) * 47, 0, math.cos(angle) * 47), 11))
	end
	for i = 2, #lampTops, 2 do
		-- Only the spans over the four paths (the others would cross the kiosk signs)
		Decor.StringLights(lobby, lampTops[i], lampTops[(i % #lampTops) + 1], 10, 2.6)
	end

	-- Outer trees (kept clear of the pond, the photo wall and the paths) and hedge boundary
	local outerRng = Random.new(7)
	local keepClear = {
		{ Position = Vector3.new(104, 0, 44), Radius = 40 },
		{ Position = Vector3.new(-108, 0, 40), Radius = 36 },
	}
	for i = 0, 35 do
		local angle = (i / 36) * math.pi * 2
		local position = Vector3.new(math.sin(angle) * 138, 0, math.cos(angle) * 138)
		local blocked = math.abs(position.X) < 14 or math.abs(position.Z) < 14
		for _, area in ipairs(keepClear) do
			if (position - area.Position).Magnitude < area.Radius then
				blocked = true
			end
		end
		if not blocked then
			local style = ({ "Round", "Pine", "Round", "Blossom", "Autumn" })[outerRng:NextInteger(1, 5)]
			Decor.Tree(lobby, position, outerRng:NextNumber(1.2, 1.6), style, outerRng)
		end
	end
	for _, def in ipairs({ { 0, -158, 320, 4 }, { 0, 158, 320, 4 }, { -158, 0, 4, 320 }, { 158, 0, 4, 320 } }) do
		part(lobby, { Name = "Hedge", Size = Vector3.new(def[3], 6, def[4]), CFrame = CFrame.new(def[1], 3, def[2]), Color = Color3.fromRGB(70, 140, 60), Material = Enum.Material.Grass })
		part(lobby, { Name = "Boundary", Size = Vector3.new(def[3], 80, def[4]), CFrame = CFrame.new(def[1], 40, def[2]), Transparency = 1 })
	end

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 0.6, 70)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 120, 180)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby
	local spawnDecal = Instance.new("Decal")
	spawnDecal.Face = Enum.NormalId.Top
	spawnDecal.Texture = "rbxasset://textures/SpawnLocation.png"
	spawnDecal.Parent = spawn

	-- Title sign
	local signFrame = part(lobby, { Name = "TitleFrame", Size = Vector3.new(58, 16, 2), CFrame = CFrame.new(0, 26, -122), Color = Color3.fromRGB(255, 100, 170) })
	local sign = part(lobby, { Name = "TitleSign", Size = Vector3.new(55, 13, 0.4), CFrame = CFrame.new(0, 26, -123.1), Color = Color3.fromRGB(60, 40, 110) })
	signText(sign, Enum.NormalId.Back, "STICKER PEEL", Color3.fromRGB(255, 230, 90))
	signText(sign, Enum.NormalId.Front, "STICKER PEEL", Color3.fromRGB(255, 230, 90))
	for _, x in ipairs({ -24, 24 }) do
		part(lobby, { Name = "SignLeg", Size = Vector3.new(2, 19, 2), CFrame = CFrame.new(x, 9.5, -122), Color = Color3.fromRGB(80, 60, 130), Material = Enum.Material.Metal })
	end
	-- Decorative giant stickers on the sign frame
	local stickerColors = { Color3.fromRGB(255, 220, 70), Color3.fromRGB(90, 220, 255), Color3.fromRGB(140, 255, 120), Color3.fromRGB(255, 140, 70) }
	for i, offset in ipairs({ Vector3.new(-27, 7, 1.2), Vector3.new(27, 6.5, 1.2), Vector3.new(-26, -7, 1.2), Vector3.new(26, -6.5, 1.2) }) do
		part(lobby, {
			Name = "DecoSticker",
			Size = Vector3.new(0.2, 5, 5),
			CFrame = signFrame.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(90), math.rad(15 * i)),
			Shape = Enum.PartType.Cylinder,
			Color = stickerColors[i],
			CanCollide = false,
		})
	end

	-- Room circles: step into a circle to create or join a room
	local rooms = Instance.new("Model")
	rooms.Name = "RoomPads"
	rooms.Parent = lobby
	part(rooms, { Name = "RoomsFloor", Size = Vector3.new(100, 0.4, 34), CFrame = CFrame.new(0, 0.15, -88), Color = Color3.fromRGB(232, 228, 222), Material = Enum.Material.Pavement })
	for index, x in ipairs({ -33, -11, 11, 33 }) do
		local pad = Instance.new("Model")
		pad.Name = "Pad" .. index
		pad:SetAttribute("PadIndex", index)
		pad.Parent = rooms
		local center = Vector3.new(x, 0, -88)
		local ringSize, ringCF = vcyl(center + Vector3.new(0, 0.45, 0), 0.3, 15)
		part(pad, { Name = "Ring", Size = ringSize, CFrame = ringCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, CanCollide = false })
		local discSize, discCF = vcyl(center + Vector3.new(0, 0.5, 0), 0.32, 13.6)
		local disc = part(pad, { Name = "Disc", Size = discSize, CFrame = discCF, Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(46, 48, 58), Material = Enum.Material.SmoothPlastic })
		-- Big number painted on the floor
		local numberGui = Instance.new("SurfaceGui")
		numberGui.Face = Enum.NormalId.Right
		numberGui.PixelsPerStud = 20
		numberGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		numberGui.LightInfluence = 0.3
		numberGui.Parent = disc
		local numberLabel = Instance.new("TextLabel")
		numberLabel.Size = UDim2.fromScale(0.5, 0.5)
		numberLabel.Position = UDim2.fromScale(0.5, 0.5)
		numberLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		numberLabel.BackgroundTransparency = 1
		numberLabel.Text = tostring(index)
		numberLabel.TextScaled = true
		numberLabel.Font = Enum.Font.GothamBold
		numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		numberLabel.TextTransparency = 0.75
		numberLabel.Parent = numberGui
		-- Floating status sign (text is updated by PartyService)
		local anchor = part(pad, { Name = "SignAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center + Vector3.new(0, 9, 0)), Transparency = 1, CanCollide = false })
		anchor.CanQuery = false
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "RoomSign"
		billboard.Size = UDim2.fromOffset(240, 78)
		billboard.LightInfluence = 0
		billboard.MaxDistance = 140
		billboard.Parent = anchor
		local panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Size = UDim2.fromScale(1, 1)
		panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		panel.BackgroundTransparency = 0.25
		panel.Parent = billboard
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = panel
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -20, 0, 32)
		title.Position = UDim2.fromOffset(10, 6)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Text = "ROOM " .. index
		title.Parent = panel
		local status = Instance.new("TextLabel")
		status.Name = "Status"
		status.Size = UDim2.new(1, -20, 0, 26)
		status.Position = UDim2.fromOffset(10, 42)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamMedium
		status.TextScaled = true
		status.TextColor3 = Color3.fromRGB(190, 190, 200)
		status.Text = "Step in to create"
		status.Parent = panel
	end
	local roomsSign = part(rooms, { Name = "RoomsSign", Size = Vector3.new(30, 4, 0.4), CFrame = CFrame.new(0, 3.6, -103), Color = Color3.fromRGB(28, 28, 34) })
	signText(roomsSign, Enum.NormalId.Back, "PLAY  •  STEP INTO A CIRCLE", Color3.fromRGB(255, 255, 255))
	for _, x in ipairs({ -13, 13 }) do
		part(rooms, { Name = "SignLeg", Size = Vector3.new(0.6, 2, 0.6), CFrame = CFrame.new(x, 1, -103), Color = Color3.fromRGB(28, 28, 34), Material = Enum.Material.Metal })
	end

	-- Kiosks around the plaza
	kiosk(lobby, CFrame.new(-36, 0, -24) * CFrame.Angles(0, math.rad(-150), 0), "LEVELS", Color3.fromRGB(70, 170, 255), "Levels", "Choose Level")
	kiosk(lobby, CFrame.new(36, 0, -24) * CFrame.Angles(0, math.rad(150), 0), "UPGRADES", Color3.fromRGB(255, 120, 60), "Upgrades", "Upgrade")
	kiosk(lobby, CFrame.new(-36, 0, 24) * CFrame.Angles(0, math.rad(-30), 0), "SHOP", Color3.fromRGB(255, 196, 40), "Shop", "Browse Tools")
	kiosk(lobby, CFrame.new(36, 0, 24) * CFrame.Angles(0, math.rad(30), 0), "TOOLS", Color3.fromRGB(110, 220, 120), "Inventory", "Equip Tools")

	-- Benches
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2 + math.pi / 8
		local base = CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -40)
		part(lobby, { Name = "BenchSeat", Size = Vector3.new(7, 0.5, 2.2), CFrame = base * CFrame.new(0, 1.7, 0), Color = Color3.fromRGB(160, 104, 60), Material = Enum.Material.Wood })
		part(lobby, { Name = "BenchBack", Size = Vector3.new(7, 2, 0.4), CFrame = base * CFrame.new(0, 2.8, -1), Color = Color3.fromRGB(160, 104, 60), Material = Enum.Material.Wood })
		for _, x in ipairs({ -3, 3 }) do
			part(lobby, { Name = "BenchLeg", Size = Vector3.new(0.4, 1.5, 1.8), CFrame = base * CFrame.new(x, 0.75, 0), Color = Color3.fromRGB(50, 50, 56), Material = Enum.Material.Metal })
		end
	end

	LobbyBuilder.BuildGrounds(lobby)

	-- Showcase anchor (the showcase object is placed here by LevelService)
	part(lobby, { Name = "ShowcaseAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 0.35, 0), Transparency = 1, CanCollide = false })

	lobby.Parent = Workspace
	return lobby
end

-- Runtime-only polish (terrain can't be stored by the build tools): real grass terrain
-- under the lobby and soft clouds in the sky.
function LobbyBuilder.Decorate(lobby: Model)
	local terrain = Workspace.Terrain
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(0, -5, 0), Vector3.new(600, 10, 600), Enum.Material.Grass)
	end)
	if ok then
		Decor.ApplyTerrain(lobby)
	end
	local ground = lobby:FindFirstChild("Ground")
	if ok and ground and ground:IsA("BasePart") then
		-- Terrain takes over walking; the part stays for sticker occlusion tests only
		ground.Transparency = 1
		ground.CanCollide = false
	end
	if not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.55
		clouds.Color = Color3.fromRGB(255, 255, 255)
		clouds.Parent = terrain
	end
	pcall(function()
		(terrain :: any).Decoration = true
	end)
end

return LobbyBuilder
