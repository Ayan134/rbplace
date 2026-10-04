--[[
	InteractionController
	Finds the sticker the player is aiming at and handles peel input.

	  The game is first person, so the sticker under the crosshair (screen center) is the
	  target on every device.
	  PC:      aim with the crosshair -> "E - PEEL" prompt; hold E or the left mouse button
	  Mobile:  aim (or tap a sticker); if nothing is under the crosshair the nearest sticker
	           in front of you is used; hold the big PEEL button
	  Gamepad: aim; nearest sticker in front of you as a fallback; hold ButtonX / R2

	The actual peeling is delegated to PeelController.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rarity = require(Shared.Rarity)
local Signal = require(Shared.Signal)
local StickerConfig = require(Shared.StickerConfig)
local ToolConfig = require(Shared.ToolConfig)

local LOCAL_PLAYER = Players.LocalPlayer

local InteractionController = {}

InteractionController.InputModeChanged = Signal.new() -- ("KeyboardMouse" | "Touch" | "Gamepad")
InteractionController.TargetChanged = Signal.new() -- (record?)

InteractionController.InputMode = "KeyboardMouse"
InteractionController.Target = nil :: any
InteractionController.Enabled = true

local Controllers
local prompt: BillboardGui
local promptKey: TextLabel
local promptAction: TextLabel
local promptInfo: TextLabel
local highlight: SelectionBox
local raycastParams: RaycastParams

local holdSources: { [string]: boolean } = {}
local pinnedTarget: any = nil
local pinnedUntil = 0

local function getRoot(): BasePart?
	local character = LOCAL_PLAYER.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function setInputMode(mode: string)
	if InteractionController.InputMode ~= mode then
		InteractionController.InputMode = mode
		InteractionController.InputModeChanged:Fire(mode)
	end
end

local function classifyInput(inputType: Enum.UserInputType)
	if inputType == Enum.UserInputType.Touch then
		setInputMode("Touch")
	elseif inputType.Name:find("Gamepad") then
		setInputMode("Gamepad")
	elseif inputType == Enum.UserInputType.Keyboard or inputType.Name:find("Mouse") then
		setInputMode("KeyboardMouse")
	end
end

-- Returns whether the local player's tool can peel this sticker, and the required tier.
function InteractionController.CanPeel(record): (boolean, number)
	local session = Controllers.StickerRenderer.GetCurrentSession()
	local required = StickerConfig.GetRequiredToolTier(record.Info.Id, session and session.Difficulty)
	local stats = Controllers.DataController.GetStats()
	return stats.ToolTier >= required, required
end

local function isPeelable(record, rootPosition: Vector3): boolean
	if not record or not record.Alive or record.Detached or not record.Part then
		return false
	end
	if record.State == "Peeling" and not (record.Peel and record.Peel.Local) then
		return false
	end
	return (record.Position - rootPosition).Magnitude <= Config.Peel.ClientReach
end

-- Sticker under the crosshair (center of the screen)
local function findCenterTarget(rootPosition: Vector3)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	if UserInputService:GetFocusedTextBox() then
		return nil
	end
	local center = camera.ViewportSize / 2
	local ray = camera:ViewportPointToRay(center.X, center.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 250, raycastParams)
	if result then
		local record = Controllers.StickerRenderer.GetRecordFromPart(result.Instance)
		if record and isPeelable(record, rootPosition) then
			return record
		end
	end
	return nil
end

local function findNearestTarget(rootPosition: Vector3)
	local renderer = Controllers.StickerRenderer
	local session = renderer.GetCurrentSession()
	if not session then
		return nil
	end
	local camera = Workspace.CurrentCamera
	local look = camera and camera.CFrame.LookVector or Vector3.zAxis
	local candidates = renderer.QueryRadius(session, rootPosition, Config.Peel.ClientReach, function(record)
		return record.State ~= "Peeling" or (record.Peel and record.Peel.Local)
	end)
	local best, bestScore = nil, math.huge
	for i = 1, math.min(#candidates, 40) do
		local record = candidates[i]
		local offset = record.Position - rootPosition
		local distance = offset.Magnitude
		local facing = if distance > 0.01 then offset.Unit:Dot(look) else 1
		local score = distance - facing * 6
		if score < bestScore then
			best, bestScore = record, score
		end
	end
	return best
end

local function updatePrompt(record)
	if not record then
		prompt.Enabled = false
		(prompt :: any).Adornee = nil
		highlight.Adornee = nil
		return
	end
	local canPeel, required = InteractionController.CanPeel(record)
	local mode = InteractionController.InputMode
	prompt.Adornee = record.Part
	prompt.Enabled = true
	highlight.Adornee = record.Part
	highlight.Color3 = if canPeel then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(255, 80, 80)

	local info = record.Info
	if canPeel then
		promptKey.Text = if mode == "Touch" then "HOLD" elseif mode == "Gamepad" then "X" else "E"
		promptAction.Text = "PEEL"
		promptAction.TextColor3 = Color3.new(1, 1, 1)
	else
		local tool = ToolConfig.GetByTier(required)
		promptKey.Text = "🔒"
		promptAction.Text = "NEEDS " .. string.upper(tool and tool.Name or "BETTER TOOL")
		promptAction.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
	if info.IsRare then
		promptInfo.Text = "✨ " .. info.DisplayName
		promptInfo.TextColor3 = Rarity.Color(info.Rarity)
	elseif record.Hard then
		promptInfo.Text = "Hard to reach • bonus"
		promptInfo.TextColor3 = Color3.fromRGB(255, 200, 120)
	else
		promptInfo.Text = info.DisplayName
		promptInfo.TextColor3 = Color3.fromRGB(220, 220, 235)
	end
end

local function update()
	local renderer = Controllers.StickerRenderer
	local root = getRoot()
	local session = renderer.GetCurrentSession()
	local target = nil
	if InteractionController.Enabled and root and session and session.Ready then
		local position = root.Position
		if pinnedTarget and os.clock() < pinnedUntil and isPeelable(pinnedTarget, position) then
			target = pinnedTarget
		else
			target = findCenterTarget(position)
			if not target and InteractionController.InputMode ~= "KeyboardMouse" then
				target = findNearestTarget(position)
			end
		end
	end
	if target ~= InteractionController.Target then
		InteractionController.Target = target
		InteractionController.TargetChanged:Fire(target)
	end
	-- Hide the prompt for a sticker that's already being peeled by us (PeelController shows progress)
	if target and target.Peel and target.Peel.Local then
		updatePrompt(nil)
		highlight.Adornee = target.Part
	else
		updatePrompt(target)
	end
end

local function refreshHolding()
	local holding = false
	for _, value in pairs(holdSources) do
		if value then
			holding = true
			break
		end
	end
	Controllers.PeelController.SetHolding(holding)
end

function InteractionController.SetHold(source: string, value: boolean)
	holdSources[source] = value
	refreshHolding()
end

function InteractionController.IsHolding(): boolean
	for _, value in pairs(holdSources) do
		if value then
			return true
		end
	end
	return false
end

function InteractionController.ReleaseAll()
	table.clear(holdSources)
	refreshHolding()
end

local function buildPrompt()
	local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")
	prompt = Instance.new("BillboardGui")
	prompt.Name = "PeelPrompt"
	prompt.Size = UDim2.fromOffset(170, 66)
	prompt.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0)
	prompt.AlwaysOnTop = true
	prompt.LightInfluence = 0
	prompt.Enabled = false
	prompt.Parent = playerGui

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(44, 52, 96)
	row.BackgroundTransparency = 0.05
	row.Parent = prompt
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(16, 18, 38)
	stroke.Thickness = 3
	stroke.Parent = row

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.Size = UDim2.fromOffset(52, 34)
	key.Position = UDim2.fromOffset(5, 5)
	key.BackgroundColor3 = Color3.fromRGB(255, 204, 46)
	key.Font = Enum.Font.FredokaOne
	key.TextScaled = true
	key.TextColor3 = Color3.fromRGB(16, 18, 38)
	key.Parent = row
	Instance.new("UICorner", key).CornerRadius = UDim.new(0, 10)
	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = Color3.fromRGB(90, 60, 10)
	keyStroke.Thickness = 2.5
	keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	keyStroke.Parent = key
	local keyPadding = Instance.new("UIPadding")
	keyPadding.PaddingTop = UDim.new(0, 4)
	keyPadding.PaddingBottom = UDim.new(0, 4)
	keyPadding.Parent = key
	promptKey = key

	local action = Instance.new("TextLabel")
	action.Name = "Action"
	action.Size = UDim2.new(1, -68, 1, -10)
	action.Position = UDim2.fromOffset(64, 5)
	action.BackgroundTransparency = 1
	action.Font = Enum.Font.FredokaOne
	action.TextScaled = true
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.TextColor3 = Color3.new(1, 1, 1)
	action.Text = "PEEL"
	action.Parent = row
	local actionStroke = Instance.new("UIStroke")
	actionStroke.Thickness = 2
	actionStroke.Color = Color3.fromRGB(16, 18, 38)
	actionStroke.Parent = action
	promptAction = action

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "Info"
	infoLabel.Size = UDim2.new(1, 0, 0, 24)
	infoLabel.Position = UDim2.fromOffset(0, 48)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.FredokaOne
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.new(1, 1, 1)
	infoLabel.Parent = prompt
	local infoStroke = Instance.new("UIStroke")
	infoStroke.Thickness = 2
	infoStroke.Color = Color3.fromRGB(20, 16, 40)
	infoStroke.Parent = infoLabel
	promptInfo = infoLabel

	highlight = Instance.new("SelectionBox")
	highlight.Name = "StickerHighlight"
	highlight.LineThickness = 0.06
	highlight.SurfaceTransparency = 0.85
	highlight.SurfaceColor3 = Color3.new(1, 1, 1)
	highlight.Color3 = Color3.new(1, 1, 1)
	highlight.Parent = playerGui
end

function InteractionController.Init(controllers)
	Controllers = controllers
end

function InteractionController.Start()
	buildPrompt()
	raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Controllers.StickerRenderer.GetSessionFolder() }

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		setInputMode("Touch")
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		setInputMode("Gamepad")
	end
	UserInputService.LastInputTypeChanged:Connect(classifyInput)

	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.E and not processed then
			InteractionController.SetHold("E", true)
		elseif input.KeyCode == Enum.KeyCode.ButtonX or input.KeyCode == Enum.KeyCode.ButtonR2 then
			InteractionController.SetHold("Gamepad", true)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
			if InteractionController.Target and not GuiService.MenuIsOpen then
				InteractionController.SetHold("Mouse", true)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E then
			InteractionController.SetHold("E", false)
		elseif input.KeyCode == Enum.KeyCode.ButtonX or input.KeyCode == Enum.KeyCode.ButtonR2 then
			InteractionController.SetHold("Gamepad", false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			InteractionController.SetHold("Mouse", false)
		end
	end)

	-- Tap a sticker on mobile to target it explicitly
	UserInputService.TouchTapInWorld:Connect(function(position, processed)
		if processed then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local ray = camera:ViewportPointToRay(position.X, position.Y)
		local result = Workspace:Raycast(ray.Origin, ray.Direction * 250, raycastParams)
		if result then
			local record = Controllers.StickerRenderer.GetRecordFromPart(result.Instance)
			if record then
				pinnedTarget = record
				pinnedUntil = os.clock() + 4
			end
		end
	end)

	UserInputService.WindowFocusReleased:Connect(InteractionController.ReleaseAll)
	LOCAL_PLAYER.CharacterAdded:Connect(InteractionController.ReleaseAll)

	RunService.RenderStepped:Connect(update)
end

return InteractionController
