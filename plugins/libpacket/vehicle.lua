---@class StaticLibPacketVehicle
local libPacketVehicle = {
	---@type {[number]: LibPacketVehicle}
	_vehicles = {},
}

---@class LibPacketVehicle
---@field _baseVehicle Vehicle
---@field isLibPacketVehicle boolean
---@field useVisibility boolean
---@field invertVisibility boolean
---@field private _playersVisibleTo {[number]: boolean}
---@field private _customHandler fun(vehicle: LibPacketVehicle, player: Player)
local packetVehicle = {}
packetVehicle.__index = packetVehicle

--
-- Instance Methods
--

---Set the players that can see this vehicle
---@param ... Player|Player[]|number|number[]
function packetVehicle:setPlayersVisibleTo(...)
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

---Add a player to the list of players that can see this vehicle
---@param player Player
function packetVehicle:addPlayerVisibleTo(player)
	self._playersVisibleTo[player.phoneNumber] = true
end

---Remove a player from the list of players that can see this vehicle
---@param player Player
function packetVehicle:removePlayerVisibleTo(player)
	self._playersVisibleTo[player.phoneNumber] = nil
end

---is the vehicle visible to the player
---@param player Player
function packetVehicle:isVehicleVisible(player)
	return self._playersVisibleTo[player.phoneNumber] and not self.invertVisibility
		or not self._playersVisibleTo[player.phoneNumber] and self.invertVisibility
end

---Set a custom handler for the vehicle
---@param handler fun(vehicle: LibPacketVehicle, player: Player)
function packetVehicle:setCustomHandler(handler)
	self._customHandler = handler
end

---Run the custom handler for the vehicle
---@param player Player
function packetVehicle:runCustomHandler(player)
	if self._customHandler then
		self._customHandler(self, player)
	end
end

---[PRIVATE] Handle visibility management for the vehicle
---@param connection Connection
function packetVehicle:_checkVisibility(connection)
	if self:isVehicleVisible(connection.player) then
		self:_resetVisibility()
		return
	end

	self._baseVehicle.isActive = false
end

---[PRIVATE] Handle visibility management for the vehicle
function packetVehicle:_resetVisibility()
	self._baseVehicle.isActive = true
end

---Remove the vehicle
function packetVehicle:remove()
	libPacketVehicle._vehicles[self._baseVehicle.index] = nil
	if self._baseVehicle then
		self._baseVehicle:remove()
	end
end

--
-- Static Methods
--

---Create a new LibPacket vehicle
---@param vehicle Vehicle
---@return LibPacketVehicle
function libPacketVehicle:create(vehicle)
	local newVehicle = {
		_baseVehicle = vehicle,
		isLibPacketVehicle = true,
		useVisibility = true,
		_playersVisibleTo = {},
	}

	setmetatable(newVehicle, packetVehicle)
	libPacketVehicle._vehicles[vehicle.index] = newVehicle

	return newVehicle
end

---Get a LibPacket vehicle by its base vehicle
---@param vehicle Vehicle
---@return LibPacketVehicle
function libPacketVehicle:getByBaseVehicle(vehicle)
	return libPacketVehicle._vehicles[vehicle.index]
end

---Check if an vehicle is a LibPacket vehicle
---@param vehicle Vehicle
---@return boolean
function libPacketVehicle:isPacketVehicle(vehicle)
	return libPacketVehicle._vehicles[vehicle.index] and true or false
end

---[PRIVATE] Manage vehicles during packet building
---@param connection Connection
function libPacketVehicle:_build(connection)
	for _, vehicle in pairs(self._vehicles) do
		if not vehicle._baseVehicle then
			vehicle:remove()
			goto continue
		end

		if vehicle.useVisibility then
			vehicle:_checkVisibility(connection)
		end

		vehicle:runCustomHandler(connection.player)
		::continue::
	end
end

---[PRIVATE] Reset vehicle properties on PostServerSend
function libPacketVehicle:_postBuild()
	for _, vehicle in pairs(self._vehicles) do
		vehicle:_resetVisibility()
	end
end

hook.add("PostResetGame", "LibPacketVehicle", function(reason)
	libPacketVehicle._vehicles = {}
end)

return libPacketVehicle
