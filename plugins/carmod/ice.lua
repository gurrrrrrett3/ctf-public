local plugin = ...

local computer = require("plugins.libcomputer.libcomputer")
local itemUtil = require("plugins.libutil.item")
local Performance = require("plugins.libutil.performance")
local nitro = require("plugins.carmod.nitro")

---@type {[number]: LibComputerItem}
local inCarComputers

if not inCarComputers then
	inCarComputers = {}
end

---@type {[integer]: {forward: number, up: number, pitch: number}}
local IceCarPositions = {
	[enum.vehicle.town_car] = {
		forward = 1.25,
		up = -0.2,
		pitch = 0.1785,
	},
	[enum.vehicle.beamer] = {
		forward = 1.35,
		up = -0.2,
		pitch = 0.1785,
	},
	[enum.vehicle.van] = {
		forward = 1.6,
		up = -0.2,
		pitch = 0.1785,
	},
	[enum.vehicle.hatchback] = {
		forward = 1.1,
		up = -0.25,
		pitch = 0.1785,
	},
}

local playerColors = {
	["hasDisk"] = enum.color.computer.green_light,
	["isDead"] = enum.color.computer.gray_light,
}

---@param ice LibComputerItem
local function iceGui(ice)
	---@type Vehicle
	local vehicle = ice._baseItem.data.vehicle

	local speed = vehicle.rigidBody.vel:dist(Vector()) * 100
	local rpm = vehicle.engineRPM

	local accentColor = vehicle.color == enum.color.vehicle.red and enum.color.computer.red_light
		or enum.color.computer.blue_light

	ice:clear(enum.color.computer.black)
	ice:drawHLine(1, 1, ice.width - 2, accentColor)

	ice:addText(1, 1, "ICE", accentColor, math.round(server.ticksSinceReset / 10, 0) % 16, false)

	ice:addText(
		ice.width,
		1,
		string.format("%s | %sRPM | %.0f MPH", tostring(math.round(vehicle.health, 0)) .. "%", rpm, speed),
		accentColor,
		enum.color.computer.white,
		true
	)

	-- nitro

	if vehicle.data.nitro then
		local nitroPercent = vehicle.data.nitro.current / nitro.max
		local nitroHeight = math.round(nitroPercent * (ice.height - 3), 0)

		local barColor = vehicle.data.nitro.isBoosting and enum.color.computer.white
			or nitroPercent > 0.5 and enum.color.computer.green
			or enum.color.computer.red

		local textColor = (vehicle.data.nitro.isBoosting or nitroPercent > 0.5) and enum.color.computer.black
			or enum.color.computer.white

		for i = 1, ice.height - 3 do
			ice:setChar(
				ice.width,
				i + 2,
				" ",
				(ice.height - 3 - i) < nitroHeight and barColor or enum.color.computer.dark_gray
			)
			ice:setChar(
				ice.width - 1,
				i + 2,
				" ",
				(ice.height - 3 - i) < nitroHeight and barColor or enum.color.computer.dark_gray
			)
		end

		if vehicle.data.nitro.current < nitro.max then
			local timeUntilFull = ((nitro.max - vehicle.data.nitro.current) / nitro.regen) / 62.5
			ice:addText(ice.width - 1, 3, string.format("%.0fs", timeUntilFull), barColor, textColor, true)
		end

		ice:addText(
			ice.width + 1,
			ice.height - 1,
			string.format("%.0f%%", nitroPercent * 100),
			barColor,
			textColor,
			true
		)

		ice:addText(ice.width, ice.height, "NITRO", barColor, textColor, true)
	end

	ice:addText(
		1,
		ice.height - 2,
		string.format("P: %.0f/%.0f | E: %.0f", Performance.playerCount, Performance.maxPlayers, Performance.eventCount),
		enum.color.computer.dark_gray,
		enum.color.computer.white,
		false
	)

	ice:addText(
		1,
		ice.height - 1,
		string.format(
			"I: %.0f | H: %.0f | V: %.0f",
			Performance.itemCount,
			Performance.humanCount,
			Performance.vehicleCount
		),
		enum.color.computer.dark_gray,
		enum.color.computer.white,
		false
	)
	ice:addText(
		1,
		ice.height,
		string.format("TPS: %.2f | MSPT: %.2f", Performance.tps, Performance.mspt),
		enum.color.computer.dark_gray,
		enum.color.computer.white,
		false
	)

	if not vehicle then
		return ice:refresh()
	end
	local lastDriver = vehicle.lastDriver or nil
	local teamNum = (vehicle.lastDriver and vehicle.lastDriver.team or 0)
	local team = _G.Game.getTeam(teamNum)
	local teamIndex = (team and team.index or nil)
	local otherTeam = (teamIndex ~= nil and _G.Game.getTeam(teamIndex == 1 and 2 or 1))
	-- assert(team, "Team is nil")
	-- assert(otherTeam, "Other team is nil")
	--print(teamIndex)
	--print('jpsh print 150 ice.lua', lastDriver, teamNum, team, otherTeam)
	if not team or not team.disk then
		return ice:refresh()
	end

	local color = team.index == 1 and enum.color.computer.red_light or enum.color.computer.blue_light

	local playerCount = 0
	for i, ply in pairs(team.players) do
		local playerColor = color
		if otherTeam.disk.isBeingHeld and otherTeam.disk.lastHeldBy == ply.index then
			playerColor = playerColors.hasDisk
		elseif ply.human and not ply.human.isAlive then
			playerColor = playerColors.isDead
		end
		local man = ply.human
		local veh = (man and man.vehicle or nil)
		local health = (veh and veh.health or man and math.max(man.health, 0) or 0)
		local healthColor = (veh and enum.color.computer.gray_light)
			or (
				health > 50 and enum.color.computer.green_light
				or health > 25 and enum.color.computer.yellow
				or enum.color.computer.red_light
			)
		local healthBarLength = math.round(health / 100 * 20, 0)

		ice:drawHLine(1, 3 + playerCount, 20, enum.color.computer.dark_gray)
		ice:drawHLine(1, 3 + playerCount, healthBarLength, healthColor)

		ice:addText(22, 3 + playerCount, ply.name, enum.color.computer.black, playerColor, false)

		playerCount = playerCount + 1
	end

	ice:refresh()

	ice:refresh()
end

---@param vehicle Vehicle
local function createICE(vehicle)
	if
		not vehicle.data.ice
		and vehicle.lastDriver
		and vehicle.lastDriver.human
		and vehicle.lastDriver.human.vehicle
		and vehicle.lastDriver.human.vehicle.index == vehicle.index
	then
		local ice = itemUtil.createStaticItem(enum.item.computer, vehicle.pos:clone(), orientations.n)
		ice.hasPhysics = false
		ice.despawnTime = 2147483647

		assert(ice, "Computer is nil")
		ice.data.isIce = true
		ice.data.vehicle = vehicle
		vehicle.data.ice = ice

		local libCIce = computer.item.create(ice)

		inCarComputers[vehicle.index] = libCIce
	end
end

plugin:addHook("PostVehicleDelete", function(vehicle)
	if vehicle.data.ice then
		vehicle.data.ice:remove()
		computer.item.getFromBaseItem(vehicle.data.ice):remove()
		vehicle.data.ice = nil
	end
end)

plugin:addHook("PostPhysics", function()
	for _, vehicle in pairs(vehicles.getAll()) do
		if not vehicle.data.ice then
			if vehicle.lastDriver and vehicle.lastDriver.human and vehicle.lastDriver.human.vehicle then
				createICE(vehicle)
			end
			goto continue
		end

		if
			vehicle.data.ice
			and (not vehicle.lastDriver or not vehicle.lastDriver.human or not vehicle.lastDriver.human.vehicle)
		then
			vehicle.data.ice:remove()
			computer.item.getFromBaseItem(vehicle.data.ice):remove()
			vehicle.data.ice = nil
		end

		::continue::
	end

	for _, ice in pairs(inCarComputers) do
		---@type Vehicle
		local vehicle = ice._baseItem.data.vehicle

		if not vehicle or not vehicle.isActive then
			ice._baseItem:remove()
			ice:remove()

			for i, v in pairs(inCarComputers) do
				if v == ice then
					inCarComputers[i] = nil
				end
			end

			goto continue
		end

		local mod = IceCarPositions[vehicle.type.index] or IceCarPositions[6]

		local pos = (vehicle.rot:forwardUnit() * mod.forward) + vehicle.rot:upUnit() * mod.up + vehicle.pos
		ice._baseItem.pos = pos

		ice._baseItem.rot = pitchToRotMatrix(mod.pitch) * vehicle.rot:clone()

		if server.ticksSinceReset % 5 == 0 then
			iceGui(ice)
		end

		::continue::
	end
end)

plugin:addHook("PlayerInputPress[del]", function(player)
	if player.human.vehicle and player.human.vehicle.data.ice then
		local vehicle = player.human.vehicle
		local ice = computer.item.getFromBaseItem(vehicle.data.ice)

		if bit32.band(vehicle.lastDriver.inputFlags, enum.input.del) == enum.input.del then
			if not ice._baseItem.parentHuman then
				vehicle.lastDriver.human:mountItem(ice._baseItem, 0)
			else
				ice._baseItem:unmount()
			end
		end
	end
end)
