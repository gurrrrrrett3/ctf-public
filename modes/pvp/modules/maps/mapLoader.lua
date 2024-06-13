local Loader = require("main.loader")

---@class MapLoader
local MapLoader = {
	---@type {[string]: MapBuilder}
	maps = {},
}

function MapLoader.loadMaps()
	local maps = Loader:flatRecursiveLoad("modes/pvp/maps", "MapBuilder")
	MapLoader.maps = maps

	for i, v in pairs(maps) do
		print("Loaded map: " .. i)
	end
end

return MapLoader
