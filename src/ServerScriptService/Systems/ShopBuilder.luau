--[[
	ShopBuilder
	Builds the walk-in shop: an open-front garage room with bags on counters along the
	left wall, tools on cork boards on the back and right walls, ceiling lamps and an
	upgrade machine. Every item has a floating name + green price tag and a prompt (F):
	ShopService buys or equips it, ShopDisplayController (client) shows owned/equipped.

	ShopBuilder.Build(parent, cframe) -- the open front faces local -Z
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BagConfig = require(Shared.BagConfig)
local BagModels = require(Shared.BagModels)
local ToolConfig = require(Shared.ToolConfig)
local ToolModels = require(Shared.ToolModels)

local ShopBuilder = {}

local WIDTH, DEPTH, HEIGHT = 28, 22, 12
local WALL = Color3.fromRGB(236, 206, 150)
local TRIM = Color3.fromRGB(226, 120, 60)
local FLOOR = Color3.fromRGB(222, 196, 150)

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

local function textLabel(parent: Instance, name: string, text: string, color: Color3, size: UDim2, position: UDim2)
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
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(16, 18, 38)
	stroke.Parent = label
	return label
end

-- Invisible anchor with the price tag and the buy prompt
local function display(parent: Instance, position: Vector3, action: string, itemId: string, name: string, price: string, tagHeight: number)
	local anchor = part(parent, { Name = "Display", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(position), Transparency = 1, CanCollide = false, CastShadow = false })
	anchor.CanQuery = false
	anchor:SetAttribute("Action", action)
	anchor:SetAttribute("ItemId", itemId)

	local tag = Instance.new("BillboardGui")
	tag.Name = "PriceTag"
	tag.Size = UDim2.fromScale(5, 1.9)
	tag.StudsOffset = Vector3.new(0, tagHeight, 0)
	tag.LightInfluence = 0
	tag.MaxDistance = 34
	tag.Parent = anchor
	textLabel(tag, "ItemName", name, Color3.new(1, 1, 1), UDim2.fromScale(1, 0.45), UDim2.new())
	textLabel(tag, "Price", price, Color3.fromRGB(112, 255, 120), UDim2.fromScale(1, 0.55), UDim2.fromScale(0, 0.45))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. price
	prompt.ObjectText = name
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", action)
	prompt:SetAttribute("ItemId", itemId)
	prompt.Parent = anchor
	return anchor
end

local function priceText(price: number, currency: string): string
	if price <= 0 then
		return "FREE"
	end
	if currency == "Gems" then
		return "💎 " .. tostring(price)
	end
	local formatted = tostring(math.floor(price)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return "$" .. formatted
end

local function counter(parent: Instance, cframe: CFrame, length: number)
	part(parent, { Name = "Counter", Size = Vector3.new(3.4, 3.2, length), CFrame = cframe * CFrame.new(0, 1.6, 0), Color = Color3.fromRGB(240, 236, 224), Material = Enum.Material.Wood })
	part(parent, { Name = "CounterTop", Size = Vector3.new(3.8, 0.35, length + 0.4), CFrame = cframe * CFrame.new(0, 3.37, 0), Color = Color3.fromRGB(140, 90, 52), Material = Enum.Material.WoodPlanks })
	local drawers = math.max(1, math.floor(length / 2.8))
	for i = 1, drawers do
		local z = -length / 2 + (i - 0.5) * length / drawers
		part(parent, { Name = "Drawer", Size = Vector3.new(0.1, 1.2, length / drawers - 0.5), CFrame = cframe * CFrame.new(1.72, 2.2, z), Color = Color3.fromRGB(226, 220, 206), CastShadow = false })
		part(parent, { Name = "Knob", Size = Vector3.new(0.2, 0.18, 0.7), CFrame = cframe * CFrame.new(1.8, 2.2, z), Color = Color3.fromRGB(150, 150, 160), Material = Enum.Material.Metal, CastShadow = false })
	end
end

local function sparkle(target: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Parent = target
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Rate = 6
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = attachment
end

-- Moves every part of `model` so that its pivot lands on `cframe`
local function place(model: Model, cframe: CFrame)
	local pivot = if model.PrimaryPart then model.PrimaryPart.CFrame else CFrame.new()
	local offset = cframe * pivot:Inverse()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CFrame = offset * descendant.CFrame
		end
	end
end

function ShopBuilder.Build(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Shop"
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return cframe * CFrame.new(x, y, z)
	end

	-- Shell: floor, three walls, ceiling, roof and an open front with a header
	part(model, { Name = "Floor", Size = Vector3.new(WIDTH, 0.6, DEPTH), CFrame = at(0, 0.3, 0), Color = FLOOR, Material = Enum.Material.WoodPlanks })
	part(model, { Name = "BackWall", Size = Vector3.new(WIDTH, HEIGHT, 1), CFrame = at(0, HEIGHT / 2, DEPTH / 2), Color = WALL, Material = Enum.Material.WoodPlanks })
	for _, side in ipairs({ -1, 1 }) do
		part(model, { Name = "SideWall", Size = Vector3.new(1, HEIGHT, DEPTH), CFrame = at(side * WIDTH / 2, HEIGHT / 2, 0), Color = WALL, Material = Enum.Material.WoodPlanks })
		part(model, { Name = "Pillar", Size = Vector3.new(1.6, HEIGHT, 1.6), CFrame = at(side * WIDTH / 2, HEIGHT / 2, -DEPTH / 2), Color = Color3.fromRGB(250, 250, 248) })
	end
	part(model, { Name = "Ceiling", Size = Vector3.new(WIDTH, 0.6, DEPTH), CFrame = at(0, HEIGHT, 0), Color = Color3.fromRGB(246, 232, 200) })
	part(model, { Name = "Trim", Size = Vector3.new(WIDTH - 1, 0.3, 0.2), CFrame = at(0, HEIGHT - 0.5, DEPTH / 2 - 0.6), Color = TRIM, CastShadow = false })
	part(model, { Name = "Header", Size = Vector3.new(WIDTH + 1.6, 2.2, 1.4), CFrame = at(0, HEIGHT - 1.1, -DEPTH / 2), Color = Color3.fromRGB(250, 250, 248) })
	part(model, { Name = "Roof", Size = Vector3.new(WIDTH + 3, 1, DEPTH + 3), CFrame = at(0, HEIGHT + 0.8, 0), Color = Color3.fromRGB(46, 50, 62), Material = Enum.Material.RoofShingles })
	part(model, { Name = "RoofEdge", Size = Vector3.new(WIDTH + 3.4, 0.5, 0.5), CFrame = at(0, HEIGHT + 0.3, -DEPTH / 2 - 1.5), Color = Color3.fromRGB(250, 250, 248) })

	-- Striped awning and sign over the entrance
	for i = 0, 9 do
		part(model, {
			Name = "Awning",
			Size = Vector3.new(WIDTH / 10, 0.2, 3.4),
			CFrame = at(-WIDTH / 2 + (i + 0.5) * WIDTH / 10, HEIGHT - 2.6, -DEPTH / 2 - 1.6) * CFrame.Angles(math.rad(-20), 0, 0),
			Color = if i % 2 == 0 then Color3.fromRGB(70, 170, 255) else Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Fabric,
			CanCollide = false,
		})
	end
	local sign = part(model, { Name = "Sign", Size = Vector3.new(14, 3.4, 0.4), CFrame = at(0, HEIGHT + 3, -DEPTH / 2 - 1.2), Color = Color3.fromRGB(255, 204, 46) })
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 30
	signGui.LightInfluence = 0.2
	signGui.Parent = sign
	textLabel(signGui, "Text", "🛒 SHOP", Color3.new(1, 1, 1), UDim2.new(1, -20, 1, -16), UDim2.fromOffset(10, 8))
	for _, x in ipairs({ -5, 5 }) do
		part(model, { Name = "SignPost", Size = Vector3.new(0.4, 2, 0.4), CFrame = at(x, HEIGHT + 1.4, -DEPTH / 2 - 1.2), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal })
	end

	-- Ceiling lamps
	for _, x in ipairs({ -6.5, 6.5 }) do
		local lamp = part(model, { Name = "CeilingLamp", Size = Vector3.new(0.5, 3.4, 3.4), CFrame = at(x, HEIGHT - 0.5, 1) * CFrame.Angles(0, 0, math.rad(90)), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 244, 220), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		part(model, { Name = "LampRim", Size = Vector3.new(0.3, 3.8, 3.8), CFrame = at(x, HEIGHT - 0.25, 1) * CFrame.Angles(0, 0, math.rad(90)), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(150, 110, 70), CanCollide = false, CastShadow = false })
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.4
		light.Color = Color3.fromRGB(255, 230, 190)
		light.Shadows = false
		light.Parent = lamp
	end

	-- Bags on two counters along the left wall
	local bags = {}
	for _, id in ipairs(BagConfig.Order) do
		local bag = BagConfig.Get(id)
		if bag.Price > 0 then
			table.insert(bags, bag)
		end
	end
	local counterX = -WIDTH / 2 + 2.4
	counter(model, at(counterX, 0.6, -3), 8.6)
	counter(model, at(counterX, 0.6, 6), 8.6)
	for index, bag in ipairs(bags) do
		local slot = (index - 1) % 3
		local z = (if index <= 3 then -3 else 6) + (slot - 1) * 2.8
		local look = BagModels.Build(bag)
		-- Bags face into the room (+X)
		place(look, at(counterX, 4.15, z) * CFrame.Angles(0, math.rad(-90), 0))
		look.Parent = model
		if bag.Shiny and look.PrimaryPart then
			sparkle(look.PrimaryPart)
		end
		display(model, (at(counterX + 0.4, 5.4, z)).Position, "BuyBag", bag.Id, bag.Name, priceText(bag.Price, bag.Currency), 2.4)
	end

	-- Tools on cork boards: three on the back wall, two on the right wall
	local tools = {}
	for _, id in ipairs(ToolConfig.Order) do
		local tool = ToolConfig.Get(id)
		if tool.Price > 0 then
			table.insert(tools, tool)
		end
	end
	-- Board fronts (local -Z) face into the room
	local boardSpots = {
		at(-7, 6.4, DEPTH / 2 - 0.65),
		at(0, 6.4, DEPTH / 2 - 0.65),
		at(7, 6.4, DEPTH / 2 - 0.65),
		at(WIDTH / 2 - 0.65, 6.4, 5) * CFrame.Angles(0, math.rad(90), 0),
		at(WIDTH / 2 - 0.65, 6.4, -2) * CFrame.Angles(0, math.rad(90), 0),
	}
	for index, tool in ipairs(tools) do
		local boardCF = boardSpots[index]
		if not boardCF then
			break
		end
		part(model, { Name = "BoardFrame", Size = Vector3.new(5.4, 4.4, 0.25), CFrame = boardCF, Color = Color3.fromRGB(240, 236, 228) })
		part(model, { Name = "Board", Size = Vector3.new(5, 4, 0.3), CFrame = boardCF * CFrame.new(0, 0, -0.06), Color = Color3.fromRGB(176, 122, 76), Material = Enum.Material.Wood })
		local look = ToolModels.BuildPreview(tool)
		-- Lay the tool across the board (its working end points left), tilted a little
		place(look, boardCF * CFrame.new(1.1, -0.2, -0.6) * CFrame.Angles(0, 0, math.rad(25)) * CFrame.Angles(0, math.rad(90), 0))
		look.Parent = model
		for _, descendant in ipairs(look:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
		display(model, (boardCF * CFrame.new(0, 0, -1.2)).Position, "BuyTool", tool.Id, tool.Name, priceText(tool.Price, tool.Currency), 2.8)
	end

	-- Upgrade machine by the entrance
	local machine = at(WIDTH / 2 - 3.2, 0.6, -DEPTH / 2 + 3.5) * CFrame.Angles(0, math.rad(90), 0)
	part(model, { Name = "Machine", Size = Vector3.new(4.4, 6, 3), CFrame = machine * CFrame.new(0, 3, 0), Color = Color3.fromRGB(255, 140, 46) })
	part(model, { Name = "MachineTop", Size = Vector3.new(4.8, 0.6, 3.4), CFrame = machine * CFrame.new(0, 6.3, 0), Color = Color3.fromRGB(200, 90, 30) })
	local screen = part(model, { Name = "Screen", Size = Vector3.new(3.4, 2.2, 0.2), CFrame = machine * CFrame.new(0, 4.2, -1.55), Color = Color3.fromRGB(90, 220, 255), Material = Enum.Material.Neon, CastShadow = false })
	local screenGui = Instance.new("SurfaceGui")
	screenGui.Face = Enum.NormalId.Front
	screenGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	screenGui.PixelsPerStud = 40
	screenGui.LightInfluence = 0
	screenGui.Parent = screen
	textLabel(screenGui, "Text", "⬆️ UPGRADES", Color3.new(1, 1, 1), UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8))
	for i = 0, 2 do
		part(model, { Name = "Button", Size = Vector3.new(0.7, 0.3, 0.7), CFrame = machine * CFrame.new(-1.2 + i * 1.2, 2.6, -1.6) * CFrame.Angles(math.rad(90), 0, 0), Shape = Enum.PartType.Cylinder, Color = ({ Color3.fromRGB(240, 66, 80), Color3.fromRGB(78, 214, 96), Color3.fromRGB(255, 204, 46) })[i + 1], CastShadow = false })
	end
	local machinePrompt = Instance.new("ProximityPrompt")
	machinePrompt.Name = "UpgradePrompt"
	machinePrompt.ActionText = "Upgrade"
	machinePrompt.ObjectText = "Upgrade machine"
	machinePrompt.KeyboardKeyCode = Enum.KeyCode.F
	machinePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	machinePrompt.HoldDuration = 0
	machinePrompt.MaxActivationDistance = 9
	machinePrompt.RequiresLineOfSight = false
	machinePrompt:SetAttribute("OpenUI", "Upgrades")
	machinePrompt.Parent = screen

	-- Doormat
	part(model, { Name = "Doormat", Size = Vector3.new(8, 0.1, 3), CFrame = at(0, 0.62, -DEPTH / 2 + 2), Color = Color3.fromRGB(120, 60, 50), Material = Enum.Material.Fabric, CanCollide = false })
	return model
end

ShopBuilder.Size = Vector3.new(WIDTH, HEIGHT, DEPTH)

return ShopBuilder
