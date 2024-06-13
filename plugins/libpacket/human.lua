---@class StaticLibPacketHuman
local libPacketHuman = {
	---@type {[number]: LibPacketHuman}
	_humans = {},
}

---@class LibPacketHuman
---@field _baseHuman Human
---@field isLibPacketHuman boolean
---@field useVisibility boolean
---@field invertVisibility boolean
---@field private _playersVisibleTo {[number]: boolean}
---@field private _customHandler fun(human: LibPacketHuman, player: Player)
local packetHuman = {}
packetHuman.__index = packetHuman

--
-- Instance Methods
--

---Set the players that can see this human
---@param ... Player|Player[]|number|number[]
function packetHuman:setPlayersVisibleTo(...)
	self._playersVisibleTo = {}
	local args = { ... }

	for _, v in pairs(args) do
		if type(v) == "number" then
		elseif type(v) == "table" then
			for _, player in pairs(v) do
				self._playersVisibleTo[player.phoneNumber] = true
			end
		else
			self._playersVisibleTo[v.phoneNumber] = true
		end
	end
end

---Add a player to the list of players that can see this human
---@param player Player
function packetHuman:addPlayerVisibleTo(player)
	self._playersVisibleTo[player.phoneNumber] = true
end

---Remove a player from the list of players that can see this human
---@param player Player
function packetHuman:removePlayerVisibleTo(player)
	self._playersVisibleTo[player.phoneNumber] = nil
end

---is the human visible to the player
---@param player Player
function packetHuman:isHumanVisible(player)
	return self._playersVisibleTo[player.phoneNumber] and not self.invertVisibility
		or not self._playersVisibleTo[player.phoneNumber] and self.invertVisibility
end

---Set a custom handler for the human
---@param handler fun(human: LibPacketHuman, player: Player)
function packetHuman:setCustomHandler(handler)
	self._customHandler = handler
end

---Run the custom handler for the human
---@param player Player
function packetHuman:runCustomHandler(player)
	if self._customHandler then
		self._customHandler(self, player)
	end
end

---[PRIVATE] Handle visibility management for the human
---@param connection Connection
function packetHuman:_checkVisibility(connection)
	if self:isHumanVisible(connection.player) then
		self:_resetVisibility()
		return
	end

	self._baseHuman.isActive = false
end

---[PRIVATE] Handle visibility management for the human
function packetHuman:_resetVisibility()
	self._baseHuman.isActive = true
end

---Remove the human
function packetHuman:remove()
	libPacketHuman._humans[self._baseHuman.index] = nil
	if self._baseHuman then
		self._baseHuman:remove()
	end
end

--
-- Static Methods
--

---Create a new LibPacket human
---@param human Human
---@return LibPacketHuman
function libPacketHuman:create(human)
	local newHuman = {
		_baseHuman = human,
		isLibPacketHuman = true,
		useVisibility = true,
		_playersVisibleTo = {},
	}

	setmetatable(newHuman, packetHuman)
	libPacketHuman._humans[human.index] = newHuman

	return newHuman
end

---Get a LibPacket human by its base human
---@param human Human
---@return LibPacketHuman
function libPacketHuman:getByBaseHuman(human)
	return libPacketHuman._humans[human.index]
end

---Check if an human is a LibPacket human
---@param human Human
---@return boolean
function libPacketHuman:isPacketHuman(human)
	return libPacketHuman._humans[human.index] and true or false
end

---[PRIVATE] Manage humans during packet building
---@param connection Connection
function libPacketHuman:_build(connection)
	for _, human in pairs(self._humans) do
		if not human._baseHuman then
			human:remove()
			goto continue
		end

		if human.useVisibility then
			human:_checkVisibility(connection)
		end

		human:runCustomHandler(connection.player)
		::continue::
	end
end

---[PRIVATE] Reset human properties on PostServerSend
function libPacketHuman:_postBuild()
	for _, human in pairs(self._humans) do
		human:_resetVisibility()
	end
end

hook.add("PostResetGame", "LibPacketHuman", function(reason)
	libPacketHuman._humans = {}
end)

return libPacketHuman
