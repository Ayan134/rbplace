--[[
	AnimationController
	Character feedback using only Roblox's own default animations (no uploads needed):
	  * idle / walk / run / jump come from the default Animate script
	  * peeling: the default tool "slash" swing is replayed while stickers are being
	    peeled (character animations replicate to everyone) and the character turns to
	    face the sticker
	  * celebration: default "cheer" emote + jump on level complete
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer

-- Roblox default tool slash animations (used if the Animate script doesn't provide one)
local FALLBACK_SLASH = {
	R15 = "rbxassetid://522635514",
	R6 = "rbxassetid://129967390",
}
local SWING_INTERVAL = 0.55

local AnimationController = {}

local peelTarget: Vector3? = nil
local slashTrack: AnimationTrack? = nil
local lastSwing = 0
local pendingPulse = false

local function getCharacterParts(): (Humanoid?, BasePart?)
	local character = LOCAL_PLAYER.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return humanoid, if root and root:IsA("BasePart") then root else nil
end

local function loadSlash(humanoid: Humanoid): AnimationTrack?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animationId = FALLBACK_SLASH[if humanoid.RigType == Enum.HumanoidRigType.R15 then "R15" else "R6"]
	local animate = humanoid.Parent and humanoid.Parent:FindFirstChild("Animate")
	local slashValue = animate and animate:FindFirstChild("toolslash")
	local animation = slashValue and slashValue:FindFirstChildOfClass("Animation")
	if animation and animation.AnimationId ~= "" then
		animationId = animation.AnimationId
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = animationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		return track
	end
	return nil
end

function AnimationController.SetPeelTarget(position: Vector3?)
	peelTarget = position
end

-- Swing right away when a new sticker starts.
function AnimationController.PeelPulse()
	pendingPulse = true
end

function AnimationController.Celebrate()
	local humanoid = getCharacterParts()
	if not humanoid then
		return
	end
	local ok, played = pcall(function()
		return humanoid:PlayEmote("cheer")
	end)
	if not ok or not played then
		humanoid.Jump = true
	end
	task.delay(0.6, function()
		if humanoid.Parent then
			humanoid.Jump = true
		end
	end)
end

local function update()
	local humanoid, root = getCharacterParts()
	if not humanoid or not root then
		return
	end
	local now = os.clock()

	-- Face the sticker while standing still and peeling
	if peelTarget and humanoid.MoveDirection.Magnitude < 0.1 then
		humanoid.AutoRotate = false
		local flatTarget = Vector3.new(peelTarget.X, root.Position.Y, peelTarget.Z)
		if (flatTarget - root.Position).Magnitude > 0.5 then
			root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, flatTarget), 0.18)
		end
	else
		humanoid.AutoRotate = true
	end

	-- Arm swing while peeling
	if peelTarget and (pendingPulse or now - lastSwing > SWING_INTERVAL) then
		pendingPulse = false
		lastSwing = now
		if not slashTrack then
			slashTrack = loadSlash(humanoid)
		end
		if slashTrack then
			slashTrack:Play(0.1, 1, 1.15)
		end
	elseif not peelTarget then
		pendingPulse = false
	end
end

function AnimationController.Init() end

function AnimationController.Start()
	RunService.RenderStepped:Connect(update)
	LOCAL_PLAYER.CharacterAdded:Connect(function()
		slashTrack = nil
		peelTarget = nil
	end)
end

return AnimationController
