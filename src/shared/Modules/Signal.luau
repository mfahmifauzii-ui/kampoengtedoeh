--!strict
-- Minimal server/client-local signal. Connect returns a disconnect function.

local Signal = {}
Signal.__index = Signal

export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> () -> (),
	Fire: (self: Signal, ...any) -> (),
}

function Signal.new(): Signal
	local self = setmetatable({ _handlers = {} :: { (...any) -> () } }, Signal)
	return (self :: any) :: Signal
end

function Signal.Connect(self: any, fn: (...any) -> ()): () -> ()
	table.insert(self._handlers, fn)
	return function()
		local index = table.find(self._handlers, fn)
		if index then
			table.remove(self._handlers, index)
		end
	end
end

function Signal.Fire(self: any, ...: any)
	for _, fn in table.clone(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
