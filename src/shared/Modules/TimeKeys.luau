--!strict
-- Day/week keys in WIB, used for daily orders, weekly order and daily visits.

local Progression = require(script.Parent.Parent.Config.Progression)

local TimeKeys = {}

-- Days roll over at Progression.RESET_HOUR (05:00 WIB), not at midnight.
local SHIFT = Progression.UTC_OFFSET - Progression.RESET_HOUR * 3600

function TimeKeys.day(now: number?): string
	return os.date("!%Y-%m-%d", (now or os.time()) + SHIFT) :: string
end

-- Weeks start Monday 05:00 WIB. (1970-01-01 was a Thursday, hence +3 days.)
function TimeKeys.week(now: number?): string
	local shifted = (now or os.time()) + SHIFT + 3 * 86400
	return `w{shifted // 604800}`
end

return TimeKeys
