---@type Plugin
local plugin = ...
plugin.name = "libpacket"
plugin.author = "gart, jpsh, checkraisefold"

---@type LibPacket
local libPacket = require("plugins.libpacket.libpacket")

libPacket:load(plugin)

plugin:addHook("PacketBuilding", function(connection)
	libPacket:build(connection)
end)

plugin:addHook("PostServerSend", function()
	libPacket:postBuild()
end)

plugin.commands["/cartest"] = {
	info = "Test command",
	canCall = function(player)
		return INDEV and (player.isAdmin or player.isConsole or false)
	end,
	call = function(ply, man, args)
		assert(ply, "Player is nil")
		assert(man, "Human is nil")

		local veh = vehicles.create(
			vehicleTypes[enum.vehicle.beamer],
			ply.human.pos:clone(),
			orientations.nw,
			enum.color.vehicle.golden
		)

		man.vehicle = veh
		man.vehicleSeat = 0

		assert(veh, "Vehicle is nil")

		local lpVeh = libPacket.vehicle:create(veh)
		assert(lpVeh, "LibPacket vehicle is nil")

		lpVeh:setPlayersVisibleTo(ply)
	end,
}

plugin.commands["/carallow"] = {
	info = "Test command",
	canCall = function(player)
		return INDEV and (player.isAdmin or player.isConsole or false)
	end,
	call = function(player, human, args)
		assert(player, "Player is nil")
		assert(human, "Human is nil")

		local veh = human.vehicle

		assert(veh, "Vehicle is nil")

		local lpVeh = libPacket.vehicle:getByBaseVehicle(veh)

		local player = findOnePlayer(args[1])
		assert(player, "Player not found")

		lpVeh:addPlayerVisibleTo(player)
	end,
}

plugin.commands["/cardeny"] = {
	info = "Test command",
	canCall = function(player)
		return INDEV and (player.isAdmin or player.isConsole or false)
	end,
	call = function(player, human, args)
		assert(player, "Player is nil")
		assert(human, "Human is nil")

		local veh = human.vehicle

		assert(veh, "Vehicle is nil")

		local lpVeh = libPacket.vehicle:getByBaseVehicle(veh)

		local player = findOnePlayer(args[1])
		assert(player, "Player not found")

		lpVeh:removePlayerVisibleTo(player)
	end,
}

plugin.commands["/itemtest"] = {
	info = "Test command",
	canCall = function(player)
		return INDEV and (player.isAdmin or player.isConsole or false)
	end,
	call = function(ply, man, args)
		assert(ply, "Player is nil")
		assert(man, "Human is nil")

		local itemId = args[1] and tonumber(args[1]) or enum.item.computer

		local item = items.create(itemTypes[itemId], ply.human.pos:clone(), orientations.nw)
		assert(item, "Item is nil")

		local lpItem = libPacket.item:create(item)
		assert(lpItem, "LibPacket item is nil")

		lpItem.useVisibility = false
		lpItem:setCustomHandler(function(item, player)
			lpItem._baseItem.parentHuman = humans[255]

			local baseItem = item._baseItem

			baseItem:computerSetLine(0, string.format("Hello, %s! (ID: %d)", player.name, player.index))
			baseItem:computerTransmitLine(0)

			baseItem.pos = player.human:getRigidBody(3).rot:forwardUnit() + player.human:getRigidBody(3).pos

			baseItem:computerSetLine(
				1,
				string.format("Self X: %.2f, Y: %.2f, Z: %.2f", baseItem.pos.x, baseItem.pos.y, baseItem.pos.z)
			)
			baseItem:computerTransmitLine(1)

			baseItem.rot = pitchToRotMatrix(player.human.viewPitch) * yawToRotMatrix(player.human.viewYaw)
			-- item._baseItem.rigidBody.rot = pitchToRotMatrix(player.human.viewPitch)
			-- 	* yawToRotMatrix(player.human.viewYaw)

			baseItem:computerSetLine(2, string.format("Rot:  %s", tostring(baseItem.rot)))
			baseItem:computerTransmitLine(2)

			baseItem.rigidBody.isSettled = true
			events.prepareObjectPacket()
		end)
	end,
}

plugin.commands["/vanish"] = {
	alias = { "/v", "/sv" },
	info = "vanish",
	canCall = function(player)
		return player.isAdmin or false
	end,
	call = function(player, human, args)
		assert(player, "Player is nil")
		assert(human, "Human is nil")

		local adminsList = {}

		-- for _, ply in pairs(players.getNonBots()) do
		-- 	if ply.isAdmin then
		-- 		table.insert(adminsList, ply)
		-- 	end
		-- end

		table.insert(adminsList, player)

		local libPacketHuman = libPacket.human:getByBaseHuman(human) or libPacket.human:create(human)
		human.data.isInvisible = not (human.data.isInvisible or false)

		libPacketHuman.useVisibility = human.data.isInvisible
		libPacketHuman:setPlayersVisibleTo(adminsList)

		libPacket.events.createClientMessage(
			3,
			"You are now " .. (human.data.isInvisible and "invisible" or "visible"),
			-1,
			1,
			player
		)
	end,
}

return libPacket
