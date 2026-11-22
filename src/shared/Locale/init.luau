--!strict
-- Locale.t("hud.koin_value", { n = "1.200" }) -> "1.200 Koin"
-- English is added post-launch as a sibling module (en.luau) + a picker here.

local id = require(script.id)

local strings: { [string]: string } = id
local warned: { [string]: boolean } = {}

local Locale = {}

-- True when the key exists (no warning). Used to tell which quests have a Naskah dialog (Q-3).
function Locale.has(key: string): boolean
	return strings[key] ~= nil
end

function Locale.t(key: string, vars: { [string]: any }?): string
	local template = strings[key]
	if template == nil then
		if not warned[key] then
			warned[key] = true
			warn(`[Locale] Missing key "{key}"`)
		end
		return key
	end
	if not vars then
		return template
	end
	local result = template:gsub("{(%w+)}", function(name: string): string?
		local value = vars[name]
		return if value ~= nil then tostring(value) else nil
	end)
	return result
end

function Locale.has(key: string): boolean
	return strings[key] ~= nil
end

-- Indonesian thousands separator: 1234567 -> "1.234.567"
function Locale.formatNumber(n: number): string
	local digits = tostring(math.floor(math.abs(n)))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if grouped:sub(1, 1) == "." then
		grouped = grouped:sub(2)
	end
	return (if n < 0 then "-" else "") .. grouped
end

return Locale
