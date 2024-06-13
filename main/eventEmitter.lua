---@class EventEmitter
local EventEmitter = {}

---@type table<string, {id: integer, listener: function, once: boolean}[]>
EventEmitter._events = {}

---@class EventEmitterOnOptions
---@field priority number?
---@field once boolean?

---Create a new EventEmitter.
---@return EventEmitter
function EventEmitter.create()
	local self = setmetatable({}, { __index = EventEmitter })
	self._events = {}
	return self
end

---Register a listener for an event.
---@param event string
---@param listener function
---@param options EventEmitterOnOptions?
function EventEmitter:on(event, listener, options)
	if not self._events[event] then
		self._events[event] = {}
	end

	local id = #self._events[event] + 1

	if options and options.priority then
		table.insert(self._events[event], options.priority, {
			id = id,
			listener = listener,
			once = options.once,
		})
		return
	end

	table.insert(self._events[event], {
		id = id,
		listener = listener,
		once = options and options.once,
	})
end

---Register a listener for an event that will only be called once.
---@param event string
---@param listener function
function EventEmitter:once(event, listener)
	self:on(event, listener, { once = true })
end

---Emit an event.
---@param event string
---@vararg any
function EventEmitter:emit(event, ...)
	if not self._events[event] then
		return
	end

	local IDsToRemove = {}

	for _, listener in pairs(self._events[event]) do
		listener.listener(...)
		if listener.once then
			table.insert(IDsToRemove, listener.id)
		end
	end

	for _, id in pairs(IDsToRemove) do
		for i, listener in pairs(self._events[event]) do
			if listener.id == id then
				table.remove(self._events[event], i)
			end
		end
	end
end

---Remove a listener from an event.
---@param event string
---@param listener function
function EventEmitter:off(event, listener)
	if not self._events[event] then
		return
	end

	for i, v in pairs(self._events[event]) do
		if v == listener then
			table.remove(self._events[event], i)
		end
	end
end

return EventEmitter
