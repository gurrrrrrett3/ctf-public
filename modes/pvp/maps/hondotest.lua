---@type MapBuilder
local map = require("modes.pvp.modules.maps.mapBuilder").create()

map:setName("hondo")
    :setDescription("test map")
    :setAuthor("gart")
    :setMapBounds(Vector(1674.29, 48.47, 1260.33), Vector(1732.77, 48.47, 1289.44))
    :addTeam()
    :setFlagLocation(Vector(1687.43, 48, 1268.52))
    :setSpawnRegion(Vector(1680.74, 49.37, 1274.55), Vector(1688.07, 49.37, 1257.73), orientations.nw)
    :setCaptureRegion(Vector(1680.74, 48, 1274.55), Vector(1688.07, 60, 1257.73))
    :nextTeam()
    :setFlagLocation(Vector(1731.70, 48, 1267.85))
    :setSpawnRegion(Vector(1738.44, 49.37, 1275.23), Vector(1725.86, 49.37, 1259.39), orientations.nw)
    :setCaptureRegion(Vector(1738.44, 48, 1275.23), Vector(1725.86, 60, 1259.39))

return map
