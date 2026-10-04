--[[
	AnimationController
	Character feedback that needs no uploaded animation assets:
	  * idle / walk come from the default Animate script
	  * peeling: the server triggers the default tool "slash" swing (replicates to all);
	    locally the tool also scrapes back and forth and the character turns to face
	    the sticker being peeled
	  * celebration: default "cheer" emote + jump on level complete
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer

local AnimationController = {}

local peelTarget: Vector3? = nil
local baseGrips: { [Tool]: CFrame } = {}
local pulseUntil = 0

local function getCharacterParts(): (Humanoid?, BasePart?, Tool?)
	local character = LOCAL_PLAYER.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local tool = character:FindFirstChildOfClass("Tool")
	return humanoid, if root and root:IsA("BasePart") then root else nil, tool
end

function AnimationController.SetPeelTarget(position: Vector3?)
	peelTarget = position
end

-- Short extra "dig in" motion when a new sticker starts.
function AnimationController.PeelPulse()
	pulseUntil = os.clock() + 0.25
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
	local humanoid, root, tool = getCharacterParts()
	if not humanoid or not root then
		return
	end
	local now = os.clock()

	-- Face the sticker while standing still and peeling
	if peelTarget and humanoid.MoveDirection.Magnitude < 0.1 then
		humanoid.AutoRotate = false
		local flatTarget = Vector3.new(peelTarget.X, root.Position.Y, peelTarget.Z)
		if (flatTarget - root.Position).Magnitude > 0.5 then
			local goal = CFrame.lookAt(root.Position, flatTarget)
			root.CFrame = root.CFrame:Lerp(goal, 0.18)
		end
	else
		humanoid.AutoRotate = true
	end

	-- Tool scraping motion (local only; the replicated swing comes from the server)
	if tool then
		local base = baseGrips[tool]
		if not base then
			base = tool.Grip
			baseGrips[tool] = base
		end
		if peelTarget then
			local scrape = math.sin(now * 22) * math.rad(14)
			local pulse = if now < pulseUntil then math.rad(-20) * ((pulseUntil - now) / 0.25) else 0
			tool.Grip = base * CFrame.Angles(scrape + pulse, 0, math.sin(now * 11) * math.rad(6))
		elseif tool.Grip ~= base then
			tool.Grip = base
		end
	end
end

function AnimationController.Init() end

function AnimationController.Start()
	RunService.RenderStepped:Connect(update)
	LOCAL_PLAYER.CharacterAdded:Connect(function()
		table.clear(baseGrips)
		peelTarget = nil
	end)
end

return AnimationController
