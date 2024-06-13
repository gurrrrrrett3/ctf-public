local item = require("plugins.libcomputer.item")
local handler = require("plugins.libcomputer.handler")
local bigFont = require("plugins.libcomputer.bigfont")

---@class libcomputer
local libcomputer = {
	item = item,
	handler = handler,
	bigFont = bigFont,
}

return libcomputer
