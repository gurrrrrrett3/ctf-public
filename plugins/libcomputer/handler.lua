local Loader = require("main.loader")

---@class LibComputerHandler
local LibComputerHandler = {
	---@type {[string]: fun(computer: LibComputerItem)}
	_handlers = {},
}

---@class LibComputerHandlerInstance
---@field id string
---@field method fun(computer: LibComputerItem)

---Register a handler for a computer item.
---@param id string
---@param handler fun(computer: LibComputerItem)
function LibComputerHandler.register(id, handler)
	LibComputerHandler._handlers[id] = handler
end

---Handle a computer item.
---@param computer LibComputerItem
function LibComputerHandler.handle(computer)
	if not computer or not computer.handlerId then
		return
	end

	local handler = LibComputerHandler._handlers[computer.handlerId]
	if handler then
		handler(computer)
	end
end

---@param directory string
function LibComputerHandler.loadHandlers(directory)
	local files = Loader:flatRecursiveLoad(directory, "LibComputerHandlerInstance")
	for _, file in ipairs(files) do
		LibComputerHandler.register(file.id, file.method)

		print("Loaded computer handler: " .. file.id)
	end
end

return LibComputerHandler
