--[[
	EffectsController
	Client-side VFX: sticker tear particles, rare sparkles, floating reward text,
	screen confetti and flashes. Everything is pooled and kept deliberately light.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local EffectsController = {}

local Controllers
local emitterAttachment: Attachment
local bits: ParticleEmitter
local sparkles: ParticleEmitter
local coins: ParticleEmitter
local textPool: { BillboardGui } = {}
local fxGui: ScreenGui
local playerGui: PlayerGui
local lowVFX = false
local rng = Random.new()

local function makeEmitter(props): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Enabled = true
	for key, value in pairs(props) do
		(emitter :: any)[key] = value
	end
	emitter.Parent = emitterAttachment
	return emitter
end

function EffectsController.StickerBurst(position: Vector3, normal: Vector3, color: Color3, info)
	emitterAttachment.WorldCFrame = CFrame.lookAt(position, position + normal)
	bits.Color = ColorSequence.new(color)
	bits:Emit(if lowVFX then 3 else 7)
	if info and info.IsRare and not lowVFX then
		sparkles.Color = ColorSequence.new(info.Color or Color3.new(1, 1, 1))
		sparkles:Emit(if info.Index >= 5 then 22 else 10)
	end
	local SoundManager = Controllers.SoundManager
	SoundManager.Play("StickerRip", { Position = position })
	SoundManager.Play("Pop", { Position = position })
end

function EffectsController.CoinBurst(position: Vector3, amount: number)
	if lowVFX then
		return
	end
	emitterAttachment.WorldCFrame = CFrame.new(position)
	coins:Emit(math.clamp(math.floor(amount / 5) + 2, 2, 12))
end

local function acquireText(): BillboardGui
	local gui = table.remove(textPool)
	if gui then
		return gui
	end
	gui = Instance.new("BillboardGui")
	gui.Name = "FloatingText"
	gui.Size = UDim2.fromOffset(220, 60)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4
	stroke.Parent = label
	local scale = Instance.new("UIScale")
	scale.Parent = label
	return gui
end

-- "+25 Coins" style popup that rises and fades.
function EffectsController.FloatingText(position: Vector3, text: string, color: Color3?, size: number?)
	local gui = acquireText()
	local label = gui:FindFirstChild("Label") :: TextLabel
	local stroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	local scale = label:FindFirstChildOfClass("UIScale") :: UIScale
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 220, 70)
	label.TextTransparency = 0
	stroke.Transparency = 0
	gui.Size = UDim2.fromOffset(220 * (size or 1), 60 * (size or 1))
	gui.StudsOffsetWorldSpace = Vector3.zero
	gui.Adornee = nil
	gui.Parent = playerGui -- BillboardGuis render from PlayerGui, not from inside a ScreenGui

	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = position
	anchor.Parent = Workspace.Terrain
	gui.Adornee = anchor

	local drift = Vector3.new(rng:NextNumber(-0.6, 0.6), 0, rng:NextNumber(-0.6, 0.6))
	scale.Scale = 0.4
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(gui, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0) + drift }):Play()
	local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.7)
	TweenService:Create(label, fadeInfo, { TextTransparency = 1 }):Play()
	local fade = TweenService:Create(stroke, fadeInfo, { Transparency = 1 })
	fade:Play()
	fade.Completed:Once(function()
		gui.Parent = nil
		gui.Adornee = nil
		anchor:Destroy()
		if #textPool < 40 then
			table.insert(textPool, gui)
		else
			gui:Destroy()
		end
	end)
end

-- Falling 2D confetti for big moments.
function EffectsController.Confetti(amount: number?)
	local count = if lowVFX then 20 else (amount or 70)
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local colors = {
		Color3.fromRGB(255, 92, 170),
		Color3.fromRGB(80, 200, 255),
		Color3.fromRGB(255, 214, 60),
		Color3.fromRGB(120, 230, 110),
		Color3.fromRGB(180, 120, 255),
	}
	for _ = 1, count do
		local piece = Instance.new("Frame")
		piece.BorderSizePixel = 0
		piece.BackgroundColor3 = colors[rng:NextInteger(1, #colors)]
		piece.Size = UDim2.fromOffset(rng:NextInteger(8, 14), rng:NextInteger(12, 20))
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromOffset(rng:NextNumber(0, viewport.X), rng:NextNumber(-140, -20))
		piece.Rotation = rng:NextNumber(0, 360)
		piece.Parent = fxGui
		local duration = rng:NextNumber(2.2, 3.6)
		local tween = TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(piece.Position.X.Offset + rng:NextNumber(-160, 160), viewport.Y + 60),
			Rotation = piece.Rotation + rng:NextNumber(-540, 540),
		})
		tween:Play()
		tween.Completed:Once(function()
			piece:Destroy()
		end)
	end
end

-- Fireworks bursting above the cleaned object
local FIREWORK_COLORS = {
	Color3.fromRGB(255, 96, 150),
	Color3.fromRGB(255, 214, 80),
	Color3.fromRGB(110, 222, 164),
	Color3.fromRGB(110, 190, 255),
	Color3.fromRGB(200, 140, 255),
	Color3.fromRGB(255, 150, 80),
}

local function launchFirework(from: Vector3, to: Vector3, color: Color3)
	local rocket = Instance.new("Part")
	rocket.Name = "Firework"
	rocket.Size = Vector3.new(0.5, 0.5, 0.5)
	rocket.Shape = Enum.PartType.Ball
	rocket.Material = Enum.Material.Neon
	rocket.Color = color
	rocket.Anchored = true
	rocket.CanCollide = false
	rocket.CanQuery = false
	rocket.CanTouch = false
	rocket.CastShadow = false
	rocket.CFrame = CFrame.new(from)
	rocket.Parent = Workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = rocket
	local trail = Instance.new("ParticleEmitter")
	trail.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 230, 180))
	trail.LightEmission = 1
	trail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = NumberRange.new(0.3, 0.5)
	trail.Speed = NumberRange.new(0.5, 2)
	trail.SpreadAngle = Vector2.new(20, 20)
	trail.Rate = 60
	trail.Parent = attachment

	local rise = rng:NextNumber(0.9, 1.3)
	local flight = TweenService:Create(rocket, TweenInfo.new(rise, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(to) })
	flight:Play()
	flight.Completed:Once(function()
		trail.Enabled = false
		rocket.Transparency = 1
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		burst.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
		burst.LightEmission = 1
		burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 0) })
		burst.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.2), NumberSequenceKeypoint.new(1, 1) })
		burst.Lifetime = NumberRange.new(1.2, 1.8)
		burst.Speed = NumberRange.new(22, 30)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Drag = 2.4
		burst.Acceleration = Vector3.new(0, -7, 0)
		burst.Rate = 0
		burst.Parent = attachment
		burst:Emit(if lowVFX then 40 else 110)
		local glow = Instance.new("PointLight")
		glow.Color = color
		glow.Range = 40
		glow.Brightness = 4
		glow.Parent = rocket
		TweenService:Create(glow, TweenInfo.new(1.2), { Brightness = 0 }):Play()
		Controllers.SoundManager.Play("Fireworks", { Position = to })
		task.delay(2.2, function()
			rocket:Destroy()
		end)
	end)
end

function EffectsController.Fireworks(focus: Vector3?, count: number?)
	local center = focus
	if not center then
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		center = camera.CFrame.Position + camera.CFrame.LookVector * 60
	end
	local base = center :: Vector3
	local total = if lowVFX then 4 else (count or 10)
	task.spawn(function()
		for i = 1, total do
			local angle = rng:NextNumber(0, math.pi * 2)
			local radius = rng:NextNumber(18, 40)
			local from = base + Vector3.new(math.cos(angle) * radius, -8, math.sin(angle) * radius)
			local to = base + Vector3.new(math.cos(angle) * radius * 0.6, rng:NextNumber(32, 54), math.sin(angle) * radius * 0.6)
			launchFirework(from, to, FIREWORK_COLORS[(i % #FIREWORK_COLORS) + 1])
			task.wait(rng:NextNumber(0.25, 0.55))
		end
	end)
end

function EffectsController.Flash(color: Color3, intensity: number?)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - (intensity or 0.35)
	flash.BorderSizePixel = 0
	flash.ZIndex = 50
	flash.Parent = fxGui
	local tween = TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Once(function()
		flash:Destroy()
	end)
end

function EffectsController.Init(controllers)
	Controllers = controllers
	emitterAttachment = Instance.new("Attachment")
	emitterAttachment.Name = "FXEmitter"
	emitterAttachment.Parent = Workspace.Terrain

	bits = makeEmitter({
		Name = "Bits",
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.05) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(55, 55),
		Acceleration = Vector3.new(0, -30, 0),
		Drag = 2,
		RotSpeed = NumberRange.new(-200, 200),
		Rotation = NumberRange.new(0, 360),
		LightEmission = 0.3,
	})
	sparkles = makeEmitter({
		Name = "Sparkles",
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0.1),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(180, 180),
		LightEmission = 1,
		Drag = 3,
	})
	coins = makeEmitter({
		Name = "Coins",
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 214, 60)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2) }),
		Lifetime = NumberRange.new(0.5, 0.8),
		Speed = NumberRange.new(5, 9),
		SpreadAngle = Vector2.new(40, 40),
		Acceleration = Vector3.new(0, 10, 0),
		LightEmission = 0.8,
	})

	fxGui = Instance.new("ScreenGui")
	fxGui.Name = "FXGui"
	fxGui.IgnoreGuiInset = true
	fxGui.ResetOnSpawn = false
	fxGui.DisplayOrder = 40
	playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui") :: PlayerGui
	fxGui.Parent = playerGui
end

function EffectsController.Start()
	local DataController = Controllers.DataController
	local function applySettings(data)
		if data and data.Settings then
			lowVFX = data.Settings.LowVFX == true
		end
	end
	DataController.Changed:Connect(applySettings)
	applySettings(DataController.Get())
end

return EffectsController
