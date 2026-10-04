--[[
	Utility
	Small shared helpers.
]]

local Utility = {}

function Utility.FormatNumber(value: number): string
	local negative = value < 0
	local str = tostring(math.floor(math.abs(value)))
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return (negative and "-" or "") .. formatted
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qd" }

function Utility.Abbreviate(value: number): string
	if math.abs(value) < 10000 then
		return Utility.FormatNumber(value)
	end
	local index = 1
	local v = value
	while math.abs(v) >= 1000 and index < #SUFFIXES do
		v /= 1000
		index += 1
	end
	if math.abs(v) >= 100 then
		return string.format("%d%s", math.floor(v), SUFFIXES[index])
	end
	return string.format("%.1f%s", math.floor(v * 10) / 10, SUFFIXES[index])
end

function Utility.FormatTime(seconds: number): string
	seconds = math.max(0, seconds)
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	if minutes >= 60 then
		local hours = math.floor(minutes / 60)
		return string.format("%d:%02d:%02d", hours, minutes % 60, math.floor(rest))
	end
	return string.format("%d:%04.1f", minutes, rest)
end

function Utility.FormatPercent(fraction: number, decimals: number?): string
	return string.format("%." .. tostring(decimals or 1) .. "f%%", fraction * 100)
end

function Utility.DeepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value :: any) do
		copy[Utility.DeepCopy(k)] = Utility.DeepCopy(v)
	end
	return (copy :: any) :: T
end

-- Fills in keys missing from `target` with copies of `template` values (recursively).
function Utility.Reconcile(target: { [any]: any }, template: { [any]: any })
	for key, value in pairs(template) do
		if target[key] == nil then
			target[key] = Utility.DeepCopy(value)
		elseif type(value) == "table" and type(target[key]) == "table" then
			Utility.Reconcile(target[key], value)
		end
	end
	return target
end

function Utility.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Utility.Round(value: number, decimals: number?): number
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

function Utility.Count(t: { [any]: any }): number
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

-- entries = { { Weight = number, Value = any }, ... }
function Utility.WeightedPick(rng: Random, entries: { { Weight: number, Value: any } }): any
	local total = 0
	for _, entry in ipairs(entries) do
		total += math.max(0, entry.Weight)
	end
	if total <= 0 then
		return entries[1] and entries[1].Value
	end
	local roll = rng:NextNumber() * total
	for _, entry in ipairs(entries) do
		roll -= math.max(0, entry.Weight)
		if roll <= 0 then
			return entry.Value
		end
	end
	return entries[#entries].Value
end

function Utility.Smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Utility.EaseOutBack(t: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

function Utility.UtcDay(): number
	return math.floor(os.time() / 86400)
end

return Utility
