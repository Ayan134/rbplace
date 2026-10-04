--[[
	UpgradeService
	Validates and applies upgrade purchases. The client only sends the upgrade id;
	price, max level and level requirements are all checked here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeConfig = require(Shared.UpgradeConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local RateLimiter = require(script.Parent.Parent.Systems.RateLimiter)

local UpgradeService = {}

local limiter = RateLimiter.new(6, 10)

function UpgradeService.Buy(player: Player, upgradeId: any)
	if not limiter:Check(player) then
		return { Success = false, Message = "Slow down!" }
	end
	if not UpgradeConfig.IsValid(upgradeId) then
		return { Success = false, Message = "Unknown upgrade" }
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return { Success = false, Message = "Data not loaded" }
	end

	local upgrade = UpgradeConfig.Get(upgradeId)
	local current = data.Upgrades[upgradeId] or 0
	if current >= upgrade.MaxLevel then
		return { Success = false, Message = "Already maxed!" }
	end
	local requiredLevel = UpgradeConfig.GetRequiredPlayerLevel(upgradeId, current + 1)
	if data.Level < requiredLevel then
		return { Success = false, Message = string.format("Requires player level %d", requiredLevel) }
	end
	local cost = UpgradeConfig.GetCost(upgradeId, current)
	if not EconomyService.TrySpend(player, "Coins", cost) then
		return { Success = false, Message = "Not enough Coins" }
	end
	PlayerDataService.Update(player, function(d)
		d.Upgrades[upgradeId] = current + 1
	end)
	return { Success = true, Level = current + 1 }
end

function UpgradeService.Init()
	Remotes.BuyUpgrade.OnServerInvoke = function(player: Player, upgradeId: any)
		return UpgradeService.Buy(player, upgradeId)
	end
end

function UpgradeService.Start() end

return UpgradeService
