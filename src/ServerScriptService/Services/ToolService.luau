--[[
	ToolService
	Tool purchases, equipping and attaching the equipped tool to the character.

	The tool model is welded into the right hand instead of being a Roblox Tool: a Tool
	forces the "arm held out" pose all the time, while a welded model lets the default
	idle / walk / run animations play normally. The peel swing is played by the client
	(AnimationController) and replicates like any character animation.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ToolConfig = require(Shared.ToolConfig)
local ToolModels = require(Shared.ToolModels)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local RateLimiter = require(script.Parent.Parent.Systems.RateLimiter)

local ToolService = {}

local limiter = RateLimiter.new(4, 8)

-- Tool points forward-down out of the fist instead of straight down along the arm
local GRIP = CFrame.Angles(math.rad(60), 0, 0)

local function removeHeld(character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "HeldTool" then
			child:Destroy()
		end
	end
end

function ToolService.AttachEquippedTool(player: Player)
	local data = PlayerDataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	removeHeld(character)
	local info = ToolConfig.Get(data.EquippedTool) or ToolConfig.Tools.Hand
	character:SetAttribute("ToolId", info.Id)

	local model = ToolModels.BuildHeld(info)
	if not model then
		return -- bare hands
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local handle = model.PrimaryPart
	if not hand or not hand:IsA("BasePart") or not handle then
		model:Destroy()
		return
	end
	local gripAttachment = hand:FindFirstChild("RightGripAttachment")
	local gripOffset = if gripAttachment and gripAttachment:IsA("Attachment")
		then gripAttachment.CFrame
		else CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)

	handle.CFrame = hand.CFrame * gripOffset * GRIP
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "HandWeld"
	weld.Part0 = hand
	weld.Part1 = handle
	weld.C0 = gripOffset * GRIP
	weld.C1 = CFrame.new()
	weld.Parent = handle
	model.Parent = character
end

function ToolService.Buy(player: Player, toolId: any)
	if not limiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if not ToolConfig.IsValid(toolId) then
		return { Success = false, Message = "Unknown tool" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end
	local info = ToolConfig.Get(toolId)
	if data.UnlockedTools[toolId] then
		return { Success = false, Message = "You already own this tool" }
	end
	if data.Level < info.RequiredLevel then
		return { Success = false, Message = string.format("Requires player level %d", info.RequiredLevel) }
	end
	if not EconomyService.TrySpend(player, info.Currency, info.Price) then
		return { Success = false, Message = "Not enough " .. (if info.Currency == "Gems" then "Gems" else "money") }
	end
	PlayerDataService.Update(player, function(d)
		d.UnlockedTools[toolId] = true
		d.EquippedTool = toolId
	end)
	ToolService.AttachEquippedTool(player)
	return { Success = true }
end

function ToolService.Equip(player: Player, toolId: any)
	if not limiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if not ToolConfig.IsValid(toolId) then
		return { Success = false, Message = "Unknown tool" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end
	if not data.UnlockedTools[toolId] then
		return { Success = false, Message = "You don't own this tool" }
	end
	PlayerDataService.Update(player, function(d)
		d.EquippedTool = toolId
	end)
	ToolService.AttachEquippedTool(player)
	return { Success = true }
end

function ToolService.Init()
	Remotes.BuyTool.OnServerInvoke = function(player: Player, toolId: any)
		return ToolService.Buy(player, toolId)
	end
	Remotes.EquipTool.OnServerInvoke = function(player: Player, toolId: any)
		return ToolService.Equip(player, toolId)
	end
end

function ToolService.Start()
	local function onCharacter(player: Player, character: Model)
		-- Wait for the avatar (appearance, hands) to finish loading
		local deadline = os.clock() + 6
		while not player:HasAppearanceLoaded() and os.clock() < deadline do
			task.wait(0.1)
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and player.Character == character then
			ToolService.AttachEquippedTool(player)
		end
	end
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end
end

return ToolService
