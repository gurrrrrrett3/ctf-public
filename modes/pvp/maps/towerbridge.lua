---@type MapBuilder
local map = require("modes.pvp.modules.maps.mapBuilder").create()

map:setName("towerbridge")
	:setDescription("A map for CTF")
	:setAuthor("gart")
	:setMapBounds(Vector(1095.86, 121.95, 1370), Vector(1160.11, 109.80, 1480))
	:addTeam()
	:setFlagLocation(Vector(1128, 112, 1470))
	:setSpawnRegion(Vector(1124, 113, 1480), Vector(1136, 113, 1473), orientations.nw)
	:setCaptureRegion(Vector(1100, 113, 1464), Vector(1155, 120, 1471))
	:nextTeam()
	:setFlagLocation(Vector(1128, 112, 1410))
	:setSpawnRegion(Vector(1124, 113, 1400), Vector(1136, 113, 1408), orientations.nw)
	:setCaptureRegion(Vector(1100, 113, 1415), Vector(1155, 120, 1408))

return map
