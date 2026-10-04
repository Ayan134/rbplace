--[[
	FirstPersonController
	The game is played in first person (StarterPlayer.CameraMode = LockFirstPerson).
	This controller adds what first person needs:
	  * a viewmodel: your hand holding the equipped tool in the lower right of the screen,
	    with weapon-style sway, walk bob and a chop swing on every peel
	  * a crosshair that lights up when it's on a sticker
	  * a free cursor while a window is open (Modal buttons) or while ALT is held on PC
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ToolConfig = require(Shared.ToolConfig)
local ToolModels = require(Shared.ToolModels)

local LOCAL_PLAYER = Players.LocalPlayer

local GRIP_OFFSET = CFrame.new(1.05, -1.0, -2.1) * CFrame.Angles(math.rad(6), math.rad(8), math.rad(-4))
local SWING_TIME = 0.3

local FirstPersonController = {}

local Controllers
local rig: Model? = nil
local rigToolId: string? = nil
local swingStart = -10
local sway = CFrame.new()
local lastRotation: CFrame? = nil
local bobPhase = 0
local crosshair: Frame
local crosshairGui: ScreenGui
local cursorButton: TextButton
local altHeld = false

local function skinColor(): Color3
	local character = LOCAL_PLAYER.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	if hand and hand:IsA("BasePart") then
		return hand.Color
	end
	return Color3.fromRGB(234, 184, 146)
end

local function prepare(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

-- Hand + forearm with the tool in the fist. The hand is the pivot (grip point).
local function buildRig(toolId: string): Model
	local model = Instance.new("Model")
	model.Name = "Viewmodel"
	local color = skinColor()

	local hand = Instance.new("Part")
	hand.Name = "Hand"
	hand.Shape = Enum.PartType.Ball
	hand.Size = Vector3.new(0.9, 0.9, 0.9)
	hand.Color = color
	hand.Material = Enum.Material.SmoothPlastic
	prepare(hand)
	hand.Parent = model
	model.PrimaryPart = hand

	local forearm = Instance.new("Part")
	forearm.Name = "Forearm"
	forearm.Size = Vector3.new(0.72, 0.72, 2.6)
	forearm.Color = color
	forearm.Material = Enum.Material.SmoothPlastic
	forearm.CFrame = CFrame.new(0.15, -0.3, 1.25) * CFrame.Angles(math.rad(-12), math.rad(8), 0)
	prepare(forearm)
	forearm.Parent = model

	local sleeve = Instance.new("Part")
	sleeve.Name = "Sleeve"
	sleeve.Size = Vector3.new(0.86, 0.86, 1.1)
	sleeve.Color = Color3.fromRGB(70, 110, 170)
	sleeve.Material = Enum.Material.Fabric
	sleeve.CFrame = forearm.CFrame * CFrame.new(0, 0, 1.2)
	prepare(sleeve)
	sleeve.Parent = model

	local info = ToolConfig.Get(toolId) or ToolConfig.Tools.Hand
	local tool = ToolModels.BuildHeld(info)
	if tool then
		local handle = tool.PrimaryPart
		if handle then
			tool:PivotTo(CFrame.new(0, 0.05, -0.1) * CFrame.Angles(math.rad(10), 0, 0))
		end
		for _, descendant in ipairs(tool:GetDescendants()) do
			if descendant:IsA("BasePart") then
				prepare(descendant)
			end
		end
		for _, child in ipairs(tool:GetChildren()) do
			child.Parent = model
		end
		tool:Destroy()
	end
	model:PivotTo(CFrame.new())
	return model
end

local function isFirstPerson(camera: Camera): boolean
	if camera.CameraType ~= Enum.CameraType.Custom then
		return false
	end
	local character = LOCAL_PLAYER.Character
	local head = character and character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return false
	end
	return (head.Position - camera.CFrame.Position).Magnitude < 2
end

local function cursorFree(): boolean
	return altHeld or (Controllers.UIController.IsCursorNeeded and Controllers.UIController.IsCursorNeeded())
end

function FirstPersonController.Swing()
	swingStart = os.clock()
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local mode = Controllers.UIController.Mode
	local playing = mode == "Lobby" or mode == "Game"
	local character = LOCAL_PLAYER.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local visible = playing and humanoid ~= nil and humanoid.Health > 0 and isFirstPerson(camera)

	-- Crosshair
	crosshairGui.Enabled = visible and not cursorFree()
	if crosshairGui.Enabled then
		local target = Controllers.InteractionController.Target
		local stroke = crosshair:FindFirstChildOfClass("UIStroke") :: UIStroke
		local size = if target then 16 else 10
		crosshair.Size = crosshair.Size:Lerp(UDim2.fromOffset(size, size), math.min(1, dt * 18))
		stroke.Color = if target then Color3.fromRGB(110, 255, 150) else Color3.fromRGB(255, 255, 255)
	end
	cursorButton.Visible = altHeld and playing

	-- Viewmodel
	local data = Controllers.DataController.Get()
	local toolId = data and data.EquippedTool or "Hand"
	if rig and rigToolId ~= toolId then
		rig:Destroy()
		rig = nil
	end
	if not visible then
		if rig then
			rig.Parent = nil
		end
		lastRotation = nil
		return
	end
	if not rig then
		rig = buildRig(toolId)
		rigToolId = toolId
	end
	local model = rig :: Model

	-- Sway: the hand lags a little behind fast camera turns
	local rotation = camera.CFrame.Rotation
	if lastRotation then
		local delta = lastRotation:ToObjectSpace(rotation)
		local rx, ry = delta:ToOrientation()
		local target = CFrame.Angles(math.clamp(rx * 1.6, -0.12, 0.12), math.clamp(ry * 1.6, -0.15, 0.15), 0)
		sway = sway:Lerp(target, math.min(1, dt * 10))
	end
	lastRotation = rotation

	-- Walk bob
	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0.1 and humanoid.FloorMaterial ~= Enum.Material.Air
	if moving then
		bobPhase += dt * 9
	else
		bobPhase += dt * 1.6
	end
	local bobAmount = if moving then 1 else 0.25
	local bob = CFrame.new(math.sin(bobPhase) * 0.05 * bobAmount, math.abs(math.cos(bobPhase)) * 0.06 * bobAmount, 0)

	-- Chop swing on each peel
	local swing = CFrame.new()
	local t = (os.clock() - swingStart) / SWING_TIME
	if t >= 0 and t < 1 then
		local s = math.sin(t * math.pi)
		swing = CFrame.new(-0.25 * s, -0.15 * s, -0.45 * s) * CFrame.Angles(-0.9 * s, 0.25 * s, 0.2 * s)
	end

	model:PivotTo(camera.CFrame * sway * bob * GRIP_OFFSET * swing)
	model.Parent = camera
end

function FirstPersonController.Init(controllers)
	Controllers = controllers
end

function FirstPersonController.Start()
	local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")
	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "CrosshairUI"
	crosshairGui.IgnoreGuiInset = true
	crosshairGui.ResetOnSpawn = false
	crosshairGui.DisplayOrder = 5
	crosshairGui.Parent = playerGui
	crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(10, 10)
	crosshair.BackgroundTransparency = 1
	crosshair.Parent = crosshairGui
	Instance.new("UICorner", crosshair).CornerRadius = UDim.new(0.5, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.1
	stroke.Parent = crosshair

	-- While ALT is held the cursor is free so the side buttons can be clicked
	local cursorGui = Instance.new("ScreenGui")
	cursorGui.Name = "CursorUnlock"
	cursorGui.ResetOnSpawn = false
	cursorGui.Parent = playerGui
	cursorButton = Instance.new("TextButton")
	cursorButton.Name = "Unlock"
	cursorButton.Size = UDim2.fromOffset(1, 1)
	cursorButton.BackgroundTransparency = 1
	cursorButton.Text = ""
	cursorButton.Modal = true
	cursorButton.Visible = false
	cursorButton.Parent = cursorGui

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
			altHeld = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
			altHeld = false
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		altHeld = false
	end)

	Controllers.AnimationController.Swung:Connect(FirstPersonController.Swing)
	LOCAL_PLAYER.CharacterAdded:Connect(function()
		if rig then
			rig:Destroy()
			rig = nil
		end
	end)
	RunService.RenderStepped:Connect(update)
end

return FirstPersonController
