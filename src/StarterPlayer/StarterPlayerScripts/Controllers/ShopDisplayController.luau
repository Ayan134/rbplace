--[[
	ShopDisplayController
	Personalizes the walk-in shop for the local player: each item's price tag and
	prompt show "Buy $600", "Equip" or "EQUIPPED" depending on what you own.
	(Changes to BillboardGuis and prompts made here are only seen by this client.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BagConfig = require(Shared.BagConfig)
local ToolConfig = require(Shared.ToolConfig)
local Utility = require(Shared.Utility)

local GREEN = Color3.fromRGB(112, 255, 120)
local YELLOW = Color3.fromRGB(255, 214, 70)
local WHITE = Color3.fromRGB(235, 240, 255)
local RED = Color3.fromRGB(255, 110, 110)

local ShopDisplayController = {}

local Controllers
local displays: { [BasePart]: boolean } = {}

local function track(instance: Instance)
	if instance:IsA("BasePart") and instance.Name == "Display" and instance:GetAttribute("ItemId") then
		displays[instance] = true
		local data = Controllers.DataController.Get()
		if data then
			ShopDisplayController.Refresh(data, instance)
		end
	end
end

local function apply(anchor: BasePart, data)
	local action = anchor:GetAttribute("Action")
	local itemId = anchor:GetAttribute("ItemId")
	local tag = anchor:FindFirstChild("PriceTag")
	local priceLabel = tag and tag:FindFirstChild("Price") :: TextLabel?
	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	local info, owned, equipped, levelOk
	if action == "BuyBag" then
		info = BagConfig.Get(itemId)
		owned = data.UnlockedBags and data.UnlockedBags[itemId] == true
		equipped = data.EquippedBag == itemId
		levelOk = true
	else
		info = ToolConfig.Get(itemId)
		owned = data.UnlockedTools and data.UnlockedTools[itemId] == true
		equipped = data.EquippedTool == itemId
		levelOk = info ~= nil and data.Level >= info.RequiredLevel
	end
	if not info then
		return
	end
	local price = if info.Currency == "Gems" then "💎 " .. Utility.FormatNumber(info.Price) else Utility.FormatMoney(info.Price)
	local text, color, actionText, enabled
	if equipped then
		text, color, actionText, enabled = "EQUIPPED", YELLOW, "Equipped", false
	elseif owned then
		text, color, actionText, enabled = "OWNED", WHITE, "Equip", true
	elseif not levelOk then
		text, color, actionText, enabled = "Level " .. info.RequiredLevel, RED, "Locked", false
	else
		local balance = if info.Currency == "Gems" then data.Gems else data.Coins
		text, color, actionText, enabled = price, if balance >= info.Price then GREEN else RED, "Buy " .. price, true
	end
	if priceLabel then
		priceLabel.Text = text
		priceLabel.TextColor3 = color
	end
	if prompt then
		prompt.ActionText = actionText
		prompt.Enabled = enabled
	end
end

function ShopDisplayController.Refresh(data, only: BasePart?)
	if only then
		apply(only, data)
		return
	end
	for anchor in pairs(displays) do
		if anchor.Parent then
			apply(anchor, data)
		else
			displays[anchor] = nil
		end
	end
end

function ShopDisplayController.Init(controllers)
	Controllers = controllers
end

function ShopDisplayController.Start()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		track(descendant)
	end
	Workspace.DescendantAdded:Connect(track)
	Controllers.DataController.Changed:Connect(function(data)
		if data then
			ShopDisplayController.Refresh(data)
		end
	end)
end

return ShopDisplayController
