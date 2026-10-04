--[[
	LobbyBuilder
	Builds the central lobby: plaza, paths, trees, lamps, kiosks (Play / Levels / Upgrades /
	Shop) with ProximityPrompts, a big title sign and a sticker-covered showcase object.

	If Workspace already contains a "Lobby" model (hand-made in Studio), it is used as-is;
	it only needs a SpawnLocation and a "ShowcaseAnchor" part (optional).
]]

local Workspace = game:GetService("Workspace")

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
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(40, 30, 60)
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.Parent = label
	return gui
end

local function tree(parent: Instance, position: Vector3, scale: number)
	local size, cf = vcyl(position + Vector3.new(0, 4 * scale, 0), 8 * scale, 1.6 * scale)
	part(parent, { Name = "Trunk", Size = size, CFrame = cf, Color = Color3.fromRGB(120, 82, 52), Material = Enum.Material.Wood })
	part(parent, { Name = "Leaves", Size = Vector3.new(9, 8, 9) * scale, CFrame = CFrame.new(position + Vector3.new(0, 10 * scale, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(80, 170, 70), Material = Enum.Material.Grass })
	part(parent, { Name = "Leaves", Size = Vector3.new(6, 6, 6) * scale, CFrame = CFrame.new(position + Vector3.new(1.5, 13.2, 1) * scale), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(96, 186, 80), Material = Enum.Material.Grass })
end

local function lamp(parent: Instance, position: Vector3)
	part(parent, { Name = "LampPost", Size = Vector3.new(0.6, 11, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 5.5, 0)), Color = Color3.fromRGB(46, 46, 56), Material = Enum.Material.Metal })
	local bulb = part(parent, { Name = "Bulb", Size = Vector3.new(1.8, 1.8, 1.8), CFrame = CFrame.new(position + Vector3.new(0, 11.6, 0)), Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 236, 190), Material = Enum.Material.Neon, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 226, 170)
	light.Parent = bulb
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
	part(lobby, { Name = "Plaza", Size = size, CFrame = cf, Color = PAVEMENT, Material = Enum.Material.Pavement })
	size, cf = vcyl(Vector3.new(0, 0.15, 0), 0.4, 60)
	part(lobby, { Name = "PlazaInner", Size = size, CFrame = cf, Color = Color3.fromRGB(240, 232, 220), Material = Enum.Material.Marble })

	-- Paths in four directions
	for i = 0, 3 do
		local angle = i * math.pi / 2
		part(lobby, { Name = "Path", Size = Vector3.new(12, 0.4, 70), CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.12, -80), Color = PATH, Material = Enum.Material.Sand })
	end

	-- Ring of flower beds and trees
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2 + math.pi / 12
		local position = Vector3.new(math.sin(angle) * 58, 0, math.cos(angle) * 58)
		tree(lobby, position, 1 + (i % 3) * 0.15)
		local bedSize, bedCF = vcyl(position + Vector3.new(0, 0.6, 0), 1.2, 9)
		part(lobby, { Name = "FlowerBed", Size = bedSize, CFrame = bedCF, Color = Color3.fromRGB(140, 100, 70), Material = Enum.Material.Ground })
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
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		lamp(lobby, Vector3.new(math.sin(angle) * 47, 0, math.cos(angle) * 47))
	end

	-- Outer trees and hedge boundary
	for i = 0, 27 do
		local angle = (i / 28) * math.pi * 2
		tree(lobby, Vector3.new(math.sin(angle) * 135, 0, math.cos(angle) * 135), 1.4)
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
	local signFrame = part(lobby, { Name = "TitleFrame", Size = Vector3.new(58, 16, 2), CFrame = CFrame.new(0, 22, -64), Color = Color3.fromRGB(255, 100, 170) })
	local sign = part(lobby, { Name = "TitleSign", Size = Vector3.new(55, 13, 0.4), CFrame = CFrame.new(0, 22, -65.1), Color = Color3.fromRGB(60, 40, 110) })
	signText(sign, Enum.NormalId.Back, "STICKER PEEL", Color3.fromRGB(255, 230, 90))
	signText(sign, Enum.NormalId.Front, "STICKER PEEL", Color3.fromRGB(255, 230, 90))
	for _, x in ipairs({ -24, 24 }) do
		part(lobby, { Name = "SignLeg", Size = Vector3.new(2, 15, 2), CFrame = CFrame.new(x, 7.5, -64), Color = Color3.fromRGB(80, 60, 130), Material = Enum.Material.Metal })
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

	-- Play portal
	local portal = Instance.new("Model")
	portal.Name = "PlayPortal"
	portal.Parent = lobby
	local portalCF = CFrame.new(0, 0, -50)
	for i = 0, 12 do
		local angle = math.pi * i / 12
		part(portal, {
			Name = "Arch",
			Size = Vector3.new(2.4, 3.2, 2.4),
			CFrame = portalCF * CFrame.new(math.cos(angle) * 10, 1.4 + math.sin(angle) * 12, 0),
			Color = if i % 2 == 0 then Color3.fromRGB(120, 80, 255) else Color3.fromRGB(255, 100, 200),
			Material = Enum.Material.Neon,
		})
	end
	local swirl = part(portal, { Name = "Swirl", Size = Vector3.new(0.4, 22, 18), CFrame = portalCF * CFrame.new(0, 7, 0) * CFrame.Angles(0, math.rad(90), 0), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(160, 120, 255), Material = Enum.Material.ForceField, CanCollide = false })
	swirl.Transparency = 0.2
	local portalPrompt = Instance.new("ProximityPrompt")
	portalPrompt.ObjectText = "PLAY"
	portalPrompt.ActionText = "Create / Join Room"
	portalPrompt.KeyboardKeyCode = Enum.KeyCode.F
	portalPrompt.MaxActivationDistance = 14
	portalPrompt.RequiresLineOfSight = false
	portalPrompt:SetAttribute("OpenUI", "Party")
	portalPrompt.Parent = swirl
	local portalSign = part(portal, { Name = "PortalSign", Size = Vector3.new(14, 3.4, 0.4), CFrame = portalCF * CFrame.new(0, 16.4, 0.6), Color = Color3.fromRGB(80, 50, 160) })
	signText(portalSign, Enum.NormalId.Back, "▶ PLAY", Color3.fromRGB(255, 255, 255))

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

	-- Showcase anchor (the showcase object is placed here by LevelService)
	part(lobby, { Name = "ShowcaseAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 0.35, 0), Transparency = 1, CanCollide = false })

	lobby.Parent = Workspace
	return lobby
end

return LobbyBuilder
