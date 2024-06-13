---@type MapBuilder
local map = require("modes.pvp.modules.maps.mapBuilder").create()

map:setName("rig")
	:setDescription("A map for CTF")
	:setAuthor("gart")
	:setMapBounds(Vector(1500, 24, 928), Vector(2062, 130, 1246))
	:addTeam()
	:setFlagLocation(Vector(2042, 24, 1074))
	:setSpawnRegion(Vector(2056, 24, 1084), Vector(2056, 24, 1084), orientations.nw)
	:setCaptureRegion(Vector(2056, 25, 1048), Vector(2032, 40, 1100))
	:addVehicle(enum.vehicle.beamer, Vector(2051.99, 24.84, 1047.86), orientations.n, {})
	:nextTeam()
	:setFlagLocation(Vector(1638, 24, 1234))
	:setSpawnRegion(Vector(1532.22, 29.71, 1238.95), Vector(1550.35, 29.71, 1233.69), orientations.nw)
	:setCaptureRegion(Vector(2056, 25, 1048), Vector(2032, 40, 1100))
	:addVehicle(enum.vehicle.beamer, Vector(1550.91, 29.71, 1228.49), orientations.n, {})
	:addVehicle(enum.vehicle.beamer, Vector(1546.29, 29.71, 1228.20), orientations.n, {})

return map
