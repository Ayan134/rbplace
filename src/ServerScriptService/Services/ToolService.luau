--[[
	ToolService
	Tool purchases, equipping and giving the equipped tool to the character.
	The tool is a real Tool instance held in the right hand. The backpack UI is hidden
	on the client, and the tool is re-equipped automatically if it gets unequipped.
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
local currentTools: { [Player]: Tool } = {}

local function removeTools(player: Player)
	local function clear(container: Instance?)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("ToolId") then
				child:Destroy()
			end
		end
	end
	clear(player:FindFirstChildOfClass("Backpack"))
	clear(player.Character)
	currentTools[player] = nil
end

function ToolService.GiveEquippedTool(player: Player)
	local data = PlayerDataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not humanoid or not backpack then
		return
	end
	removeTools(player)

	local info = ToolConfig.Get(data.EquippedTool) or ToolConfig.Tools.Hand
	local tool = ToolModels.BuildTool(info)
	tool.Parent = backpack
	currentTools[player] = tool
	humanoid:EquipTool(tool)

	-- Keep the tool in hand
	tool.AncestryChanged:Connect(function()
		if currentTools[player] ~= tool then
			return
		end
		task.defer(function()
			if currentTools[player] == tool and tool.Parent == backpack and humanoid.Parent and humanoid.Health > 0 then
				humanoid:EquipTool(tool)
			end
		end)
	end)
end

-- Plays the arm swing animation: a "toolanim" StringValue makes the default Animate
-- script play its tool slash animation, which replicates to everyone.
function ToolService.PlayPeelAnimation(player: Player)
	local tool = currentTools[player]
	if not tool or not tool.Parent or not tool.Parent:IsA("Model") then
		return
	end
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	task.delay(0.3, function()
		anim:Destroy()
	end)
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
		return { Success = false, Message = "Not enough " .. info.Currency }
	end
	PlayerDataService.Update(player, function(d)
		d.UnlockedTools[toolId] = true
		d.EquippedTool = toolId
	end)
	ToolService.GiveEquippedTool(player)
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
	ToolService.GiveEquippedTool(player)
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
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end
		task.wait(0.2)
		if player.Character == character then
			ToolService.GiveEquippedTool(player)
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
	Players.PlayerRemoving:Connect(function(player)
		currentTools[player] = nil
	end)
end

return ToolService
