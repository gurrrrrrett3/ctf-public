local item = require("plugins.libpacket.item")
local human = require("plugins.libpacket.human")
local vehicle = require("plugins.libpacket.vehicle")
local events = require("plugins.libpacket.events")

---@class LibPacket
---@field item StaticLibPacketItem
---@field human StaticLibPacketHuman
---@field vehicle StaticLibPacketVehicle
---@field private currentConnection Connection
local libPacket = {
	item = item,
	human = human,
	vehicle = vehicle,
	events = events,
}

---@param plugin Plugin
function libPacket:load(plugin)
	libPacket.events.load(plugin)
end

---@param connection Connection
function libPacket:build(connection)
	if self.currentConnection == connection then
		return
	end

	self.currentConnection = connection

	libPacket.item:_build(connection)
	libPacket.human:_build(connection)
	libPacket.vehicle:_build(connection)
end

function libPacket:postBuild()
	libPacket.item:_postBuild()
	libPacket.human:_postBuild()
	libPacket.vehicle:_postBuild()
	self.currentConnection = nil
end

return libPacket
