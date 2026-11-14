--!strict
-- Day/week keys in WIB, used for daily orders, weekly order and daily visits.

local Progression = require(script.Parent.Parent.Config.Progression)

local TimeKeys = {}

function TimeKeys.day(now: number?): string
	return os.date("!%Y-%m-%d", (now or os.time()) + Progression.UTC_OFFSET) :: string
end

-- Weeks start Monday 00:00 WIB. (1970-01-01 was a Thursday, hence +3 days.)
function TimeKeys.week(now: number?): string
	local shifted = (now or os.time()) + Progression.UTC_OFFSET + 3 * 86400
	return `w{shifted // 604800}`
end

return TimeKeys
