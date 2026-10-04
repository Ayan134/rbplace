--[[
	RateLimiter
	Token-bucket limiter keyed by player. Used to reject remote spam.

	local limiter = RateLimiter.new(10, 20) -- 10 requests/sec, burst 20
	if not limiter:Check(player) then return end
]]

local Players = game:GetService("Players")

local RateLimiter = {}
RateLimiter.__index = RateLimiter

local allLimiters = setmetatable({}, { __mode = "k" })

function RateLimiter.new(ratePerSecond: number, burst: number?)
	local self = setmetatable({
		Rate = ratePerSecond,
		Burst = burst or ratePerSecond,
		Buckets = {} :: { [Player]: { Tokens: number, Last: number } },
	}, RateLimiter)
	allLimiters[self] = true
	return self
end

function RateLimiter:Check(player: Player, cost: number?): boolean
	local now = os.clock()
	local bucket = self.Buckets[player]
	if not bucket then
		bucket = { Tokens = self.Burst, Last = now }
		self.Buckets[player] = bucket
	end
	bucket.Tokens = math.min(self.Burst, bucket.Tokens + (now - bucket.Last) * self.Rate)
	bucket.Last = now
	local price = cost or 1
	if bucket.Tokens < price then
		return false
	end
	bucket.Tokens -= price
	return true
end

Players.PlayerRemoving:Connect(function(player)
	for limiter in pairs(allLimiters) do
		limiter.Buckets[player] = nil
	end
end)

return RateLimiter
