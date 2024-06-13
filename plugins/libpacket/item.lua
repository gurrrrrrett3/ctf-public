---@class StaticLibPacketItem
local libPacketItem = {
	---@type {[number]: LibPacketItem}
	_items = {},
}

---@class LibPacketItem
---@field _baseItem Item
---@field isLibPacketItem boolean
---@field useVisibility boolean
---@field invertVisibility boolean
---@field private _playersVisibleTo {[number]: boolean}
---@field private _customHandler fun(item: LibPacketItem, player: Player, distance: number)
local packetItem = {}
packetItem.__index = packetItem

--
-- Instance Methods
--

---Set the players that can see this item
---@param ... Player|Player[]|number|number[]
function packetItem:setPlayersVisibleTo(...)
	self._playersVisibleTo = {}
	local args = { ... }

	for _, v in pairs(args) do
		if type(v) == "number" then
			self._playersVisibleTo[v] = true
		else
			self._playersVisibleTo[v.phoneNumber] = true
		end
	end
end

---Add a player to the list of players that can see this item
---@param player Player
function packetItem:addPlayerVisibleTo(player)
	self._playersVisibleTo[player.phoneNumber] = true
end

---Remove a player from the list of players that can see this item
---@param player Player
function packetItem:removePlayerVisibleTo(player)
	self._playersVisibleTo[player.phoneNumber] = nil
end

---is the item visible to the player
---@param player Player
function packetItem:isItemVisible(player)
	return self._playersVisibleTo[player.phoneNumber] and not self.invertVisibility
		or not self._playersVisibleTo[player.phoneNumber] and self.invertVisibility
end

---Set a custom handler for the item
---@param handler fun(item: LibPacketItem, player: Player, distance: number)
function packetItem:setCustomHandler(handler)
	self._customHandler = handler
end

---Run the custom handler for the item
---@param player Player
function packetItem:runCustomHandler(player)
	if self._customHandler then
		local distance = player and player.human and self._baseItem and player.human.pos:dist(self._baseItem.pos) or
			math.huge
		self._customHandler(self, player, distance)
	end
end

---[PRIVATE] Handle visibility management for the item
---@param connection Connection
function packetItem:_checkVisibility(connection)
	if self:isItemVisible(connection.player) then
		self:_resetVisibility()
		return
	end

	if self._baseItem.class == "Item" then
		self._baseItem.isActive = false
	else
		print("LibPacketItem: _checkVisibility: Invalid item class: attempted to set isActive on " .. self._baseItem)
	end
end

---[PRIVATE] Handle visibility management for the item
function packetItem:_resetVisibility()
	self._baseItem.isActive = true
end

---Remove the item
function packetItem:remove()
	libPacketItem._items[self._baseItem.index] = nil
	if self._baseItem then
		self._baseItem:remove()
	end
end

--
-- Static Methods
--

---Create a new LibPacket item
---@param item Item
---@return LibPacketItem
function libPacketItem:create(item)
	local newItem = {
		_baseItem = item,
		isLibPacketItem = true,
		useVisibility = true,
		_playersVisibleTo = {},
	}

	setmetatable(newItem, packetItem)
	libPacketItem._items[item.index] = newItem

	return newItem
end

---Get a LibPacket item by its base item
---@param item Item
---@return LibPacketItem
function libPacketItem:getByBaseItem(item)
	return libPacketItem._items[item.index]
end

---Check if an item is a LibPacket item
---@param item Item
---@return boolean
function libPacketItem:isPacketItem(item)
	return libPacketItem._items[item.index] and true or false
end

---[PRIVATE] Manage items during packet building
---@param connection Connection
function libPacketItem:_build(connection)
	for _, item in pairs(self._items) do
		if not item._baseItem then
			item:remove()
			goto continue
		end

		if item.useVisibility then
			item:_checkVisibility(connection)
		end

		item:runCustomHandler(connection.player)
		::continue::
	end
end

---[PRIVATE] Reset item properties on PostServerSend
function libPacketItem:_postBuild()
	for _, item in pairs(self._items) do
		item:_resetVisibility()
	end
end

hook.add("ResetGame", "LibPacketItem", function(reason)
	libPacketItem._items = {}
end)

return libPacketItem
