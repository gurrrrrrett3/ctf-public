---@type MapBuilder
local map = require("modes.pvp.modules.maps.mapBuilder").create()
local spawnConditions = require("modes.pvp.modules.maps.spawnConditions")
local nitro = require("plugins.carmod.nitro")

local extraCarSpawnThreshold = 4

map
	:setName("corps")
	:setDescription("test map")
	:setAuthor("gart")
	:setMapBounds(Vector(1313, 23, 980), Vector(910, 237, 1843))
	-- Set all corporation doors to open
	:onLoad(function()
		for _, corp in pairs(corporations.getAll()) do
			setCorpDoorState(corp.index, true)
		end

		-- Set nitro values

		nitro.regen = 0.2
		nitro.strength = 0.02
	end)
	-- red team
	:addTeam()
	:setFlagLocation(Vector(1024, 24, 1024))
	:setSpawnRegion(Vector(1060.41, 25.03, 1071.64), Vector(1083.91, 25.03, 1087.24), orientations.nw)
	:setCaptureRegion(Vector(1041.50, 24.13, 1045.45), Vector(1084.18, 29.23, 1076.33))
	:setTeamOnlyRegion(Vector(1103.50, 22, 1103), Vector(1040, 60, 1041))
	:addVehicle(enum.vehicle.van, Vector(1046, 25.15, 1068), orientations.n)
	:addVehicle(enum.vehicle.town_car, Vector(1050, 25.15, 1068), orientations.n)
	:addVehicle(enum.vehicle.town_car, Vector(1054, 25.15, 1068), orientations.n)
	:addVehicle(enum.vehicle.hatchback, Vector(1058, 25.15, 1068), orientations.n)
	:addVehicle(enum.vehicle.beamer, Vector(1062, 25.15, 1068), orientations.n)
	-- Spawn extra cars if team size is greater than threshold
	:addVehicle(
		enum.vehicle.beamer,
		Vector(1085, 25.15, 1070),
		orientations.w,
		{
			spawnCondition = function(game, team)
				return team:getPlayerCount() >= extraCarSpawnThreshold
			end,
		}
	)
	:addVehicle(enum.vehicle.town_car, Vector(1085, 25.15, 1066), orientations.w, {
		spawnCondition = function(game, team)
			return team:getPlayerCount() >= extraCarSpawnThreshold
		end,
	})
	:addVehicle(enum.vehicle.hatchback, Vector(1085, 25.15, 1062), orientations.w, {
		spawnCondition = function(game, team)
			return team:getPlayerCount() >= extraCarSpawnThreshold
		end,
	})
	:addVehicle(enum.vehicle.van, Vector(1085, 25.15, 1058), orientations.w, {
		spawnCondition = function(game, team)
			return team:getPlayerCount() >= extraCarSpawnThreshold
		end,
	})
	-- blue team
	:nextTeam()
	:setFlagLocation(Vector(1072, 24, 1752))
	:setSpawnRegion(Vector(1135, 25.03, 1692), Vector(1123, 25.03, 1715), orientations.nw)
	:setCaptureRegion(Vector(1096, 25, 1731), Vector(1119, 29, 1697))
	:setTeamOnlyRegion(Vector(1152, 22, 1672), Vector(1088, 60, 1735))
	:addVehicle(enum.vehicle.van, Vector(1117, 25.15, 1730), orientations.w)
	:addVehicle(enum.vehicle.town_car, Vector(1116, 25.15, 1726), orientations.w)
	:addVehicle(enum.vehicle.town_car, Vector(1116, 25.15, 1722), orientations.w)
	:addVehicle(enum.vehicle.hatchback, Vector(1116, 25.15, 1718), orientations.w)
	:addVehicle(enum.vehicle.beamer, Vector(1116, 25.15, 1714), orientations.w)
	-- Spawn extra cars if team size is greater than threshold
	:addVehicle(
		enum.vehicle.beamer,
		Vector(1118, 25.15, 1692),
		orientations.s,
		{
			spawnCondition = function(game, team)
				return team:getPlayerCount() >= extraCarSpawnThreshold
			end,
		}
	)
	:addVehicle(enum.vehicle.town_car, Vector(1114, 25.15, 1692), orientations.s, {
		spawnCondition = function(game, team)
			return team:getPlayerCount() >= extraCarSpawnThreshold
		end,
	})
	:addVehicle(enum.vehicle.hatchback, Vector(1110, 25.15, 1692), orientations.s, {
		spawnCondition = function(game, team)
			return team:getPlayerCount() >= extraCarSpawnThreshold
		end,
	})
	:addVehicle(enum.vehicle.van, Vector(1106, 25.15, 1692), orientations.s, {
		spawnCondition = function(game, team)
			return team:getPlayerCount() >= extraCarSpawnThreshold
		end,
	})
return map
