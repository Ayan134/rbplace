--[[
	ShopService
	Bags, trash cans and the physical shop.

	  * Trash cans: parts with the attribute SellPoint = true. Walking up to one (or using
	    its prompt) empties the bag and pays out the stickers' value.
	  * Shop displays: ProximityPrompts with the attributes Action = "BuyBag" | "BuyTool"
	    and ItemId. Triggering one buys the item, or equips it when it is already owned.
	  * Remotes BuyBag / EquipBag for the shop window.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BagConfig = require(Shared.BagConfig)
local Config = require(Shared.Config)
local ToolConfig = require(Shared.ToolConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local ToolService = require(script.Parent.ToolService)
local Notifier = require(script.Parent.Parent.Systems.Notifier)
local RateLimiter = require(script.Parent.Parent.Systems.RateLimiter)

local ShopService = {}

local limiter = RateLimiter.new(4, 8)
local sellPoints: { [BasePart]: boolean } = {}
local lastSell: { [Player]: number } = {}

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function sell(player: Player, point: BasePart?, fromPrompt: boolean)
	local count, coins = EconomyService.SellBag(player)
	if count <= 0 then
		if fromPrompt then
			Notifier.Toast(player, "Your bag is empty - peel some stickers first!", "Info")
		end
		return
	end
	lastSell[player] = os.clock()
	Notifier.Effect(player, "Sold", { Count = count, Coins = coins, Position = point and point.Position })
end

function ShopService.BuyBag(player: Player, bagId: any)
	if not limiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if not BagConfig.IsValid(bagId) then
		return { Success = false, Message = "Unknown bag" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end
	local info = BagConfig.Get(bagId)
	if data.UnlockedBags[bagId] then
		return { Success = false, Message = "You already own this bag" }
	end
	if not EconomyService.TrySpend(player, info.Currency, info.Price) then
		return { Success = false, Message = "Not enough " .. (if info.Currency == "Gems" then "Gems" else "money") }
	end
	PlayerDataService.Update(player, function(d)
		d.UnlockedBags[bagId] = true
		d.EquippedBag = bagId
	end)
	return { Success = true }
end

function ShopService.EquipBag(player: Player, bagId: any)
	if not limiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if not BagConfig.IsValid(bagId) then
		return { Success = false, Message = "Unknown bag" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end
	if not data.UnlockedBags[bagId] then
		return { Success = false, Message = "You don't own this bag" }
	end
	if data.Bag.Count > BagConfig.Get(bagId).Capacity then
		return { Success = false, Message = "Empty your bag first - it won't fit!" }
	end
	PlayerDataService.Update(player, function(d)
		d.EquippedBag = bagId
	end)
	return { Success = true }
end

-- A shop display prompt: buy the item, or equip it when it's already owned
local function onDisplay(player: Player, action: string, itemId: string)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	local result, name
	if action == "BuyBag" then
		local info = BagConfig.Get(itemId)
		name = info and info.Name
		if data.UnlockedBags[itemId] then
			if data.EquippedBag == itemId then
				return
			end
			result = ShopService.EquipBag(player, itemId)
		else
			result = ShopService.BuyBag(player, itemId)
			if result.Success then
				Notifier.Effect(player, "Purchased", { Name = name, Kind = "Bag", Id = itemId })
				return
			end
		end
	elseif action == "BuyTool" then
		local info = ToolConfig.Get(itemId)
		name = info and info.Name
		if data.UnlockedTools[itemId] then
			if data.EquippedTool == itemId then
				return
			end
			result = ToolService.Equip(player, itemId)
		else
			result = ToolService.Buy(player, itemId)
			if result.Success then
				Notifier.Effect(player, "Purchased", { Name = name, Kind = "Tool", Id = itemId })
				return
			end
		end
	end
	if result then
		if result.Success then
			Notifier.Toast(player, "Equipped " .. tostring(name), "Success")
		else
			Notifier.Toast(player, result.Message or "Can't do that", "Error")
		end
	end
end

local function track(instance: Instance)
	if instance:IsA("BasePart") and instance:GetAttribute("SellPoint") == true then
		sellPoints[instance] = true
	end
end

function ShopService.Init()
	Remotes.BuyBag.OnServerInvoke = function(player: Player, bagId: any)
		return ShopService.BuyBag(player, bagId)
	end
	Remotes.EquipBag.OnServerInvoke = function(player: Player, bagId: any)
		return ShopService.EquipBag(player, bagId)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local action = prompt:GetAttribute("Action")
		if action == "Sell" then
			local point = prompt.Parent
			sell(player, if point and point:IsA("BasePart") then point else nil, true)
		elseif action == "BuyBag" or action == "BuyTool" then
			local itemId = prompt:GetAttribute("ItemId")
			if type(itemId) == "string" then
				onDisplay(player, action, itemId)
			end
		end
	end)
end

function ShopService.Start()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		track(descendant)
	end
	Workspace.DescendantAdded:Connect(track)
	Workspace.DescendantRemoving:Connect(function(instance)
		sellPoints[instance :: any] = nil
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSell[player] = nil
	end)

	-- Walking up to a trash can empties the bag automatically
	local radius = Config.Bag.SellRadius
	while true do
		task.wait(0.25)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerDataService.Get(player)
			if not data or data.Bag.Count <= 0 or os.clock() - (lastSell[player] or 0) < 1 then
				continue
			end
			local position = rootPosition(player)
			if not position then
				continue
			end
			for point in pairs(sellPoints) do
				if (point.Position - position).Magnitude <= radius + math.max(point.Size.X, point.Size.Z) / 2 then
					sell(player, point, false)
					break
				end
			end
		end
	end
end

return ShopService
