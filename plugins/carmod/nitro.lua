---@class carNitro
---@field public max number
---@field public regen number
---@field public strength number
---@field public cost number
local carNitro = {}

carNitro.max = 100
carNitro.regen = 0.125
carNitro.strength = 0.02
carNitro.cost = 5

---@param vehicle Vehicle
hook.add("VehicleLogic", "carmod.nitro", function(vehicle)
	if
		not vehicle.data.hasNitro
		or vehicle.trafficCar
		or not vehicle.lastDriver
		or not vehicle.lastDriver.human
		or not vehicle.lastDriver.human.vehicle
	then
		return
	end

	if not vehicle.data.nitro then
		vehicle.data.nitro = {
			current = 0,
			isBoosting = false,
		}
	end

	if vehicle.data.nitro.isBoosting then
		if vehicle.data.nitro.current > 0 then
			vehicle.data.nitro.current = vehicle.data.nitro.current - carNitro.cost
			vehicle.rigidBody.vel:add(vehicle.rigidBody.rot:forwardUnit() * carNitro.strength)

			if server.ticksSinceReset % 3 == 0 then
				--events.createSound(enum.sound.computer.disk_drive, vehicle.rigidBody.pos, 1, 3)
			end
		end
	else
		if vehicle.data.nitro.current < carNitro.max then
			vehicle.data.nitro.current = math.round(vehicle.data.nitro.current + carNitro.regen, 2)
		end
	end
end)

---@param player Player
hook.add("PlayerInputPress[shift]", "carmod.nitro", function(player)
	if
		not player.human
		or not player.human.vehicle
		or not player.human.vehicle.data.hasNitro
		or not player.human.vehicle.data.nitro
		or player.human.vehicle.health <= 0
		or player.human.vehicleSeat ~= 0
	then
		return
	end
	player.human.vehicle.data.nitro.isBoosting = true
end)

---@param player Player
hook.add("PlayerInputRelease[shift]", "carmod.nitro", function(player)
	if
		not player.human
		or not player.human.vehicle
		or not player.human.vehicle.data.hasNitro
		or not player.human.vehicle.data.nitro
	then
		return
	end
	player.human.vehicle.data.nitro.isBoosting = false
end)

return carNitro
