---@type Plugin
local plugin = ...
plugin.name = "carmod"
plugin.author = "gart"

plugin:require("ice")
require("plugins.carmod.nitro")

plugin.commands["/traffic"] = {
	info = "Create traffic",
	canCall = function(player)
		return INDEV and (player.isAdmin or player.isConsole or false)
	end,
	call = function(player, human, args)
		local count = tonumber(args[1]) or 200
		trafficCars.createMany(count)
	end,
}

plugin.commands["/givenitro"] = {
	info = "Give nitro to the vehicle",
	canCall = function(player)
		return INDEV and (player.isAdmin or player.isConsole or false)
	end,
	call = function(player, human, args)
		assert(human, "Not spawned in")
		assert(human.vehicle, "Player is not in a vehicle")

		local vehicle = human.vehicle
		if not vehicle then
			return
		end
		vehicle.data.hasNitro = true
	end,
}
