--[[
	FirstPersonController
	The game is played in first person (StarterPlayer.CameraMode = LockFirstPerson).
	This controller adds what first person needs:
	  * your own avatar's right arm (skin, sleeve and the held tool) in the lower right of
	    the screen: the arm is shown locally and posed toward where you look, with sway,
	    walk bob and a chop swing on every peel. Only this client sees the pose; everyone
	    else sees the normal character animations.
	  * a crosshair that lights up when it's on a sticker
	  * a free cursor while a window is open (Modal buttons) or while ALT is held on PC
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local SWING_TIME = 0.32
local ARM_PARTS_R15 = { "RightUpperArm", "RightLowerArm", "RightHand" }

local FirstPersonController = {}

local Controllers
local swingStart = -10
local swayX, swayY = 0, 0
local lastRotation: CFrame? = nil
local bobPhase = 0
local crosshair: Frame
local crosshairGui: ScreenGui
local cursorButton: TextButton
local altHeld = false
local posing = false
local currentRig: Rig? = nil
local pose = { Raise = 0, Inward = 0, Chop = 0 }

export type Rig = {
	Shoulder: Motor6D?,
	Elbow: Motor6D?,
	Wrist: Motor6D?,
	R6: boolean,
	Parts: { BasePart },
}

local function getRig(character: Model): Rig?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local rig: Rig = { R6 = humanoid.RigType == Enum.HumanoidRigType.R6, Parts = {} }
	if rig.R6 then
		local torso = character:FindFirstChild("Torso")
		rig.Shoulder = torso and torso:FindFirstChild("Right Shoulder") :: Motor6D?
		local arm = character:FindFirstChild("Right Arm")
		if arm and arm:IsA("BasePart") then
			table.insert(rig.Parts, arm)
		end
	else
		local upper = character:FindFirstChild("RightUpperArm")
		local lower = character:FindFirstChild("RightLowerArm")
		local hand = character:FindFirstChild("RightHand")
		rig.Shoulder = upper and upper:FindFirstChild("RightShoulder") :: Motor6D?
		rig.Elbow = lower and lower:FindFirstChild("RightElbow") :: Motor6D?
		rig.Wrist = hand and hand:FindFirstChild("RightWrist") :: Motor6D?
		for _, name in ipairs(ARM_PARTS_R15) do
			local part = character:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				table.insert(rig.Parts, part)
			end
		end
	end
	if not rig.Shoulder then
		return nil
	end
	-- The tool welded into the hand and anything worn on the arm (sleeves, watches)
	local held = character:FindFirstChild("HeldTool")
	if held then
		for _, descendant in ipairs(held:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(rig.Parts, descendant)
			end
		end
	end
	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")
			local weld = handle and handle:FindFirstChildWhichIsA("Weld")
			local attachedTo = weld and (weld.Part1 == handle and weld.Part0 or weld.Part1)
			if attachedTo and table.find(rig.Parts, attachedTo :: BasePart) then
				table.insert(rig.Parts, handle :: BasePart)
			end
		end
	end
	return rig
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

-- Runs after the camera (and its transparency pass) every frame
local function poseArm(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local mode = Controllers.UIController.Mode
	local playing = mode == "Lobby" or mode == "Game"
	local character = LOCAL_PLAYER.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local firstPerson = playing and humanoid ~= nil and humanoid.Health > 0 and isFirstPerson(camera)

	-- Crosshair
	crosshairGui.Enabled = firstPerson and not cursorFree()
	if crosshairGui.Enabled then
		local target = Controllers.InteractionController.Target
		local stroke = crosshair:FindFirstChildOfClass("UIStroke") :: UIStroke
		local size = if target then 16 else 10
		crosshair.Size = crosshair.Size:Lerp(UDim2.fromOffset(size, size), math.min(1, dt * 18))
		stroke.Color = if target then Color3.fromRGB(110, 255, 150) else Color3.fromRGB(255, 255, 255)
	end
	cursorButton.Visible = altHeld and playing

	if not firstPerson or not character then
		posing = false
		currentRig = nil
		lastRotation = nil
		return
	end
	local rig = getRig(character :: Model)
	if not rig then
		return
	end
	posing = true

	-- Show the arm and the tool (the default camera hides the whole body in first person)
	for _, part in ipairs(rig.Parts) do
		part.LocalTransparencyModifier = 0
	end

	-- Sway: the arm lags a little behind fast camera turns
	local rotation = camera.CFrame.Rotation
	if lastRotation then
		local delta = lastRotation:ToObjectSpace(rotation)
		local rx, ry = delta:ToOrientation()
		swayX += (math.clamp(rx * 1.4, -0.15, 0.15) - swayX) * math.min(1, dt * 10)
		swayY += (math.clamp(ry * 1.4, -0.2, 0.2) - swayY) * math.min(1, dt * 10)
	end
	lastRotation = rotation

	-- Walk bob
	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0.1 and humanoid.FloorMaterial ~= Enum.Material.Air
	bobPhase += dt * (if moving then 9 else 1.6)
	local bob = math.sin(bobPhase) * (if moving then 0.05 else 0.015)

	-- Chop swing on each peel
	local chop = 0
	local t = (os.clock() - swingStart) / SWING_TIME
	if t >= 0 and t < 1 then
		chop = math.sin(t * math.pi)
	end

	-- Aim the arm where the camera looks (the body only turns left/right)
	local pitch = math.asin(math.clamp(camera.CFrame.LookVector.Y, -0.85, 0.85))
	pitch = math.clamp(pitch, math.rad(-55), math.rad(60))
	pose.Raise = math.rad(78) + pitch * 0.9 + swayX + bob - chop * 0.55
	pose.Inward = math.rad(14) + swayY - chop * 0.15
	pose.Chop = chop
	currentRig = rig
end

-- Applied after the Animator wrote this frame's pose and before joints are solved
-- (see Motor6D.Transform timing); only this client renders the change.
local function applyPose()
	local rig = currentRig
	if not posing or not rig then
		return
	end
	local shoulder = rig.Shoulder
	if not shoulder or not shoulder.Parent then
		currentRig = nil
		return
	end
	if rig.R6 then
		shoulder.Transform = CFrame.Angles(0, 0, pose.Raise) * CFrame.Angles(0, -pose.Inward, 0)
	else
		shoulder.Transform = CFrame.Angles(pose.Raise, pose.Inward, math.rad(-6))
		if rig.Elbow then
			rig.Elbow.Transform = CFrame.Angles(math.rad(22) + pose.Chop * 0.35, 0, 0)
		end
		if rig.Wrist then
			rig.Wrist.Transform = CFrame.Angles(math.rad(-8) - pose.Chop * 0.3, 0, 0)
		end
	end
end

function FirstPersonController.IsPosing(): boolean
	return posing
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
	RunService:BindToRenderStep("FirstPersonArm", Enum.RenderPriority.Camera.Value + 1, poseArm)
	RunService.PreSimulation:Connect(applyPose)
end

return FirstPersonController
