local BigFont = require("plugins.libcomputer.bigfont")

---@class LibComputerItem
---@field class 'LibComputerItem'
---@field _baseItem Item
---@field isLibComputerItem boolean
---@field frame {bgColor: integer, fgColor: integer, character: string}[][]
---@field needsRefresh boolean
---@field handlerId string?
local LibComputerItem = {
	width = 63,
	height = 22,

	---@type {[number]: LibComputerItem}
	_items = {},

	rgbCga = {
		[0x0] = { 0, 0, 0 },
		[0x1] = { 0, 0, 170 },
		[0x2] = { 0, 170, 0 },
		[0x3] = { 0, 170, 170 },
		[0x4] = { 170, 0, 0 },
		[0x5] = { 170, 0, 170 },
		[0x6] = { 170, 85, 0 },
		[0x7] = { 170, 170, 170 },
		[0x8] = { 85, 85, 85 },
		[0x9] = { 85, 85, 255 },
		[0xa] = { 85, 255, 85 },
		[0xb] = { 85, 255, 255 },
		[0xc] = { 255, 85, 85 },
		[0xd] = { 255, 85, 255 },
		[0xe] = { 255, 255, 85 },
		[0xf] = { 255, 255, 255 },
	},
}

LibComputerItem.__index = LibComputerItem

---@param item Item
---@param handlerId string?
function LibComputerItem.create(item, handlerId)
	assert(item, "Item is nil")
	assert(item.type.index == enum.item.computer, "Item is not a computer")

	local newItem = {
		class = "LibComputerItem",
		_baseItem = item,
		isLibComputerItem = true,
		handlerId = handlerId,
		frame = {},
	}

	setmetatable(newItem, LibComputerItem)
	LibComputerItem._items[item.index] = newItem

	item.computerCursor = -1

	return newItem
end

---@param path string
function LibComputerItem:setPcImage(path)
	local image = Image.new()
	image:loadFromFile(path)

	if image.width ~= self.width or image.height ~= self.height then
		error(
			string.format(
				"Image dimensions do not match computer dimensions. Expected %dx%d, got %dx%d",
				self.width,
				self.height,
				image.width,
				image.height
			)
		)
	end

	for y = 0, self.height do
		self.frame[y] = {}
		for x = 0, self.width do
			local r, g, b = image:getRGB(x, y)

			self.frame[y][x] = {
				bgColor = self:rgbToCga(r, g, b),
				character = "O",
			}
		end
	end
end

---Get the closest CGA color to the given RGB color
---@param r number
---@param g number
---@param b number
function LibComputerItem:rgbToCga(r, g, b)
	-- check exact matches first
	for k, v in pairs(self.rgbCga) do
		if v[1] == r and v[2] == g and v[3] == b then
			return k
		end
	end

	-- find closest match

	local closest = 0
	local closestDist = 1000000

	for k, v in pairs(self.rgbCga) do
		local dist = (v[1] - r) ^ 2 + (v[2] - g) ^ 2 + (v[3] - b) ^ 2
		if dist < closestDist then
			closest = k
			closestDist = dist
		end
	end

	return closest
end

---Get the current state to restore later
function LibComputerItem:getState()
	local state = {}

	for y = 0, self.height - 1 do
		state[y] = {}
		for x = 0, self.width - 1 do
			state[y][x] = {
				bgColor = self.frame[y][x].bgColor,
				fgColor = self.frame[y][x].fgColor,
				character = self.frame[y][x].character,
			}
		end
	end

	return state
end

---Restore the state from a previous call to getState
---@param state table
function LibComputerItem:restoreState(state)
	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			self.frame[y][x] = {
				bgColor = state[y][x].bgColor,
				fgColor = state[y][x].fgColor,
				character = state[y][x].character,
			}
		end
	end

	self.needsRefresh = true
end

---Refresh the computer screen
function LibComputerItem:refresh()
	if not self.needsRefresh then
		return
	end
	for y = 1, self.height do
		self.frame[y] = self.frame[y] or {}
		local line = ""
		for x = 1, self.width do
			self.frame[y][x] = self.frame[y][x] or { bgColor = 0, fgColor = 0, character = " " }
			line = line .. (self.frame[y][x].character or " ")
			local color = bit32.lshift(self.frame[y][x].bgColor or 0, 4) + (self.frame[y][x].fgColor or 0)
			self._baseItem:computerSetColor(y - 1, x - 1, color)
		end

		self._baseItem:computerSetLine(y - 1, line)
		self._baseItem:computerTransmitLine(y - 1)
		self._baseItem.computerCursor = -1
	end

	self.needsRefresh = false
end

--- Refresh the computer screen using another LibComputerItem's frame
---@param other LibComputerItem
function LibComputerItem:refreshFrom(other)
	self.frame = other.frame
	self.needsRefresh = true
	self:refresh()
end

---Set the color and text of a single character on the computer screen
---@param x number
---@param y number
---@param character string
---@param bgColor integer?
---@param fgColor integer?
function LibComputerItem:setChar(x, y, character, bgColor, fgColor)
	self.frame[y] = self.frame[y] or {}

	x = math.max(0, math.min(x, self.width - 1))
	y = math.max(0, math.min(y, self.height - 1))

	self.frame[y][x] = {
		character = character,
		bgColor = bgColor or (self.frame[y][x] or {}).bgColor or 0,
		fgColor = fgColor or (self.frame[y][x] or {}).fgColor or 0,
	}

	self.needsRefresh = true
end

---Add text at the given position on the computer screen with the given colors
---@param x number
---@param y number
---@param text string
---@param bgColor integer?
---@param fgColor integer?
---@param rightToLeft boolean?
function LibComputerItem:addText(x, y, text, bgColor, fgColor, rightToLeft)
	if rightToLeft then
		x = x - text:len()
	end

	for i = 1, text:len() do
		self:setChar(x + i - 1, y, text:sub(i, i), bgColor, fgColor)
	end
end

---Add text at the given position on the computer screen with the given colors
---@param x number
---@param y number
---@param text string[]
---@param bgColor integer?
---@param fgColor integer?
---@param rightToLeft boolean?
function LibComputerItem:addTextArray(x, y, text, bgColor, fgColor, rightToLeft)
	for i = 1, #text do
		self:addText(x, y + i - 1, text[i], bgColor, fgColor, rightToLeft)
	end
end

---Clear the computer screen
---@param bgColor integer?
function LibComputerItem:clear(bgColor)
	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			self:setChar(x, y, " ", bgColor, 0)
		end
	end
end

---Draw a background rectangle on the computer screen
---@param x number
---@param y number
---@param width number
---@param height number
---@param bgColor integer
function LibComputerItem:drawRect(x, y, width, height, bgColor)
	for i = 0, height - 1 do
		for j = 0, width - 1 do
			self:setChar(j + x, i + y, " ", bgColor)
		end
	end
end

---Draw a horizontal line on the computer screen
---@param x number
---@param y number
---@param width number
---@param bgColor integer
function LibComputerItem:drawHLine(x, y, width, bgColor)
	for i = 0, width - 1 do
		self:setChar(i + x, y, " ", bgColor)
	end
end

---Draw a vertical line on the computer screen
---@param x number
---@param y number
---@param height number
---@param bgColor integer
function LibComputerItem:drawVLine(x, y, height, bgColor)
	for i = 0, height - 1 do
		self:setChar(x, i + y, " ", bgColor)
	end
end

---Draw text in bigfont (max like 6 chars)
---@param x number
---@param y number
---@param text string
---@param bgColor integer
function LibComputerItem:bigFont(x, y, text, bgColor)
	BigFont.draw(self, x, y, bgColor, text)
end

---Destroy the LibComputerItem
function LibComputerItem:remove()
	self:clear()
	if self._baseItem then
		self._baseItem:remove()
	end
	LibComputerItem._items[self._baseItem.index] = nil
end

---Get the LibComputerItem for the given base item
---@param item Item
function LibComputerItem.getFromBaseItem(item)
	return LibComputerItem._items[item.index]
end

hook.add("ResetGame", "LibComputerItem", function(reason)
	LibComputerItem._items = {}
end)

return LibComputerItem
