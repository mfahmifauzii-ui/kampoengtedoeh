--!strict
-- Seasonal events, fully data-driven. Add an entry + locale keys "event.<id>" / "event.<id>.desc".
-- Dates are WIB days, inclusive ("YYYY-MM-DD"). Only one event should be active at a time.
--
-- What an event does today:
--   * Workspace attribute "ActiveEvent" = id (client UI can theme itself)
--   * decor items with `event = <id>` in Config/Decor can be BOUGHT only while it runs.
--     Anything already bought is kept forever (stock or placed).
-- Calm rules: no countdowns in UI, no FOMO copy, items return next year.

export type Event = {
	id: string,
	from: string,
	to: string,
}

local list: { Event } = {
	{ id = "lebaran", from = "2027-02-08", to = "2027-03-21" }, -- Ramadan 1448 H + Idul Fitri (approx., check sidang isbat)
}

local byId: { [string]: Event } = {}
for _, event in list do
	byId[event.id] = event
end

return {
	list = list,
	byId = byId,
	CHECK_SECONDS = 60,
}
