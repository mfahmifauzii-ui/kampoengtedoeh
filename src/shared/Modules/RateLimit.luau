--!strict
-- Per-player token bucket. `rate` = tokens refilled per second, `burst` = bucket size.

local Players = game:GetService("Players")

type Bucket = { tokens: number, last: number }

local RateLimit = {}
RateLimit.__index = RateLimit

export type RateLimit = typeof(setmetatable(
	{} :: { rate: number, burst: number, buckets: { [Player]: Bucket } },
	RateLimit
))

function RateLimit.new(rate: number, burst: number?): RateLimit
	local self = setmetatable({
		rate = rate,
		burst = burst or rate,
		buckets = {} :: { [Player]: Bucket },
	}, RateLimit)

	Players.PlayerRemoving:Connect(function(player)
		self.buckets[player] = nil
	end)

	return self
end

function RateLimit.Check(self: RateLimit, player: Player): boolean
	local now = os.clock()
	local bucket = self.buckets[player]
	if not bucket then
		bucket = { tokens = self.burst, last = now }
		self.buckets[player] = bucket
	end

	bucket.tokens = math.min(self.burst, bucket.tokens + (now - bucket.last) * self.rate)
	bucket.last = now

	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

return RateLimit
