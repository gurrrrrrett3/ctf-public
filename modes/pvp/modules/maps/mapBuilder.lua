local Game = require("modes.pvp.modules.game.game")
local Team = require("modes.pvp.modules.game.team")
local ItemUtil = require("plugins.libutil.item")
local Disk = require("modes.pvp.modules.game.disk")

---@class Options
---@field spawnCondition fun(game: Game, team: Team): boolean
---@field data table

---@class VehicleOptions : Options

---@class ItemOptions : Options
---@field static boolean?
---@field hasPhysics boolean?
---@field pickupAllowed boolean?

---@class Refrence
---@field uid integer
---@field pos Vector
---@field rot RotMatrix

---@class VehicleRefrence : Refrence
---@field vehicleType Enum.vehicle
---@field color integer
---@field options VehicleOptions

---@class ItemRefrence : Refrence
---@field itemId Enum.item
---@field options ItemOptions

---@class MapOptions
---@field vehiclesAreTeamRestricted boolean

---@class MapBuilder
---@field name string
---@field author string
---@field description string
---@field mapBounds {a: Vector, b: Vector}
---@field teams TeamBuilder[]
---@field items ItemRefrence[]
---@field vehicles VehicleRefrence[]
---@field onLoadFunc fun()
---@field options MapOptions
---@field private uids {[string]: integer[]}
---@field private spawnedItems {[integer]: Item}
---@field private spawnedVehicles {[integer]: Vehicle}
local MapBuilder = {}

MapBuilder.__index = MapBuilder

---@class TeamBuilder
---@field private map MapBuilder
---@field index number
---@field captureRegion {a: Vector, b: Vector}
---@field spawnRegion {a: Vector, b: Vector}
---@field teamOnlyRegion {a: Vector, b: Vector}
---@field flagLocation Vector
---@field spawnDirection RotMatrix
local TeamBuilder = {}

TeamBuilder.__index = TeamBuilder

-- #####
-- TeamBuilder
-- #####

---@param map MapBuilder
---@param index number
function TeamBuilder.create(map, index)
	local self = setmetatable({
		map = map,
		index = index,
	}, TeamBuilder)
	-- print("TeamBuilder.create", self.index, map.name)
	return self
end

---@param a Vector
---@param b Vector
function TeamBuilder:setCaptureRegion(a, b)
	self.captureRegion = { a = a, b = b }
	return self
end

---@param a Vector
---@param b Vector
---@param direction RotMatrix
function TeamBuilder:setSpawnRegion(a, b, direction)
	self.spawnRegion = { a = a, b = b }
	self.spawnDirection = direction
	return self
end

---@param a Vector
---@param b Vector
function TeamBuilder:setTeamOnlyRegion(a, b)
	self.teamOnlyRegion = { a = a, b = b }
	return self
end

---@param pos Vector
function TeamBuilder:setFlagLocation(pos)
	self.flagLocation = pos
	return self
end

---@param vehicleType Enum.vehicle
---@param pos Vector
---@param rot RotMatrix
---@param options? VehicleOptions
function TeamBuilder:addVehicle(vehicleType, pos, rot, options)
	if self.map.options then
		options = options or {}
		options.data = options.data or {}
		options.data.restrictToTeam = self.index
	end

	self.map:addVehicle(vehicleType, self.index, pos, rot, options)

	return self
end

function TeamBuilder:verify()
	assert(
		self.captureRegion,
		string.format("[map: %s | team: %d] Capture region is required", self.map.name, self.index)
	)
	assert(self.spawnRegion, string.format("[map: %s | team: %d] Spawn region is required", self.map.name, self.index))
	assert(
		self.flagLocation,
		string.format("[map: %s | team: %d] Flag location is required", self.map.name, self.index)
	)
end

function TeamBuilder:nextTeam()
	return self.map:addTeam()
end

function TeamBuilder:back()
	return self.map
end

-- #####
-- MapBuilder
-- #####

function MapBuilder.create()
	local self = setmetatable({
		teams = {},
		items = {},
		vehicles = {},
		spawnedItems = {},
		spawnedVehicles = {},
	}, MapBuilder)
	return self
end

-- Building

---@param mapName string
function MapBuilder:setName(mapName)
	self.name = mapName
	return self
end

---@param author string
function MapBuilder:setAuthor(author)
	self.author = author
	return self
end

---@param description string
function MapBuilder:setDescription(description)
	self.description = description
	return self
end

---@param a Vector
---@param b Vector
function MapBuilder:setMapBounds(a, b)
	self.mapBounds = { a = a, b = b }
	return self
end

---@param func fun()
function MapBuilder:onLoad(func)
	self.onLoadFunc = func
	return self
end

---@param options MapOptions
function MapBuilder:setOptions(options)
	self.options = options
	return self
end

function MapBuilder:addTeam()
	local team = TeamBuilder.create(self, #self.teams + 1)
	table.insert(self.teams, team)
	return team
end

---@param itemId Enum.item
---@param pos Vector
---@param rot RotMatrix
---@param options ItemOptions
function MapBuilder:addItem(itemId, pos, rot, options)
	---@type ItemRefrence
	local item = {
		uid = self:getUid("item"),
		itemId = itemId,
		pos = pos,
		rot = rot,
		options = options,
	}
	table.insert(self.items, item)
	return self
end

---@param vehicleType Enum.vehicle
---@param color integer
---@param pos Vector
---@param rot RotMatrix
---@param options? VehicleOptions
function MapBuilder:addVehicle(vehicleType, color, pos, rot, options)
	---@type VehicleRefrence
	local vehicle = {
		uid = self:getUid("vehicle"),
		vehicleType = vehicleType,
		color = color,
		pos = pos,
		rot = rot,
		options = options or {},
	}
	table.insert(self.vehicles, vehicle)
	return self
end

-- Spawning

---@param item ItemRefrence
---@param teamIndex integer?
function MapBuilder:spawnItem(item, teamIndex)
	local spawn = true

	if item.options.spawnCondition then
		spawn = item.options.spawnCondition(Game, Game.getTeam(teamIndex or 0)) or false
	end

	local spawnedItem = self.spawnedItems[item.uid]

	print("spawnItem", item.uid, spawn, spawnedItem, spawnedItem and spawnedItem.isActive)

	if spawnedItem and spawnedItem.isActive then
		spawn = false
	end

	-- print("spawnItem", item.uid, spawn, spawnedItem, spawnedItem.isActive)

	if spawn then
		local newItem = item.options.static
				and ItemUtil.createStaticItem(
					item.itemId,
					item.pos,
					item.rot,
					item.options.pickupAllowed and true or false
				)
			or ItemUtil.createItem(item.itemId, item.pos, item.rot)

		assert(newItem, string.format("Failed to spawn item %d (%d) for map %s", item.itemId, item.uid, self.name))

		newItem.hasPhysics = item.options.hasPhysics or false
		createVirtualTable(item.options.data or {}, newItem.data)

		if item.options.static then
			newItem.isStatic = true
			newItem.rigidBody.isSettled = true
		end

		newItem.despawnTime = 2147483647
		newItem.data.noDespawn = true
		newItem.data.uid = item.uid

		self.spawnedItems[item.uid] = newItem
	end
end

---@param vehicle VehicleRefrence
---@param teamIndex integer?
function MapBuilder:spawnVehicle(vehicle, teamIndex)
	local spawn = true

	if vehicle.options.spawnCondition then
		spawn = vehicle.options.spawnCondition(Game, Game.getTeam(teamIndex or 1)) or false
	end

	local spawnedVehicle = self.spawnedVehicles[vehicle.uid]

	if spawnedVehicle and spawnedVehicle.isActive then
		local distanceFromSpawnLocation = spawnedVehicle.pos:dist(vehicle.pos)

		if
			distanceFromSpawnLocation < 20
			or (
				spawnedVehicle.lastDriver
				and spawnedVehicle.lastDriver.human
				and spawnedVehicle.lastDriver.human.vehicle
				and spawnedVehicle.lastDriver.human.vehicle.index == spawnedVehicle.index
			)
		then
			spawn = false
		end
	end

	if spawn then
		local newVehicle = vehicles.create(vehicleTypes[vehicle.vehicleType], vehicle.pos, vehicle.rot, vehicle.color)

		assert(
			newVehicle,
			string.format("Failed to spawn vehicle %d (%d) for map %s", vehicle.vehicleType, vehicle.uid, self.name)
		)

		for key, value in pairs(vehicle.options.data or {}) do
			newVehicle.data[key] = value
		end

		newVehicle.data.uid = vehicle.uid

		if vehicle.vehicleType ~= enum.vehicle.helicopter then
			newVehicle.data.hasNitro = true
		end

		self.spawnedVehicles[vehicle.uid] = newVehicle
	end
end

function MapBuilder:spawnItemsAndVehicles()
	for _, item in pairs(self.items) do
		self:spawnItem(item)
	end

	for _, vehicle in pairs(self.vehicles) do
		self:spawnVehicle(vehicle)
	end
end

function MapBuilder:spawnVehicles()
	for _, vehicle in pairs(self.vehicles) do
		self:spawnVehicle(vehicle)
	end
end

function MapBuilder:buildMap(firstLoad)
	print("building map", self.name)
	if firstLoad then
		for _, team in pairs(self.teams) do
			_G.teams[team.index] = Team.create(team.index)
			-- print("team", team.index)
		end
	end

	if self.onLoadFunc then
		self:onLoadFunc()
	end

	self:spawnItemsAndVehicles()
end

function MapBuilder:buildFlags()
	for _, team in pairs(self.teams) do
		table.insert(
			self.spawnedItems,
			ItemUtil.createStaticItem(enum.item.box, team.flagLocation, orientations.n, true, true)
		)
		table.insert(
			self.spawnedItems,
			ItemUtil.createStaticItem(enum.item.rope, team.flagLocation + Vector(0, 0.5, 0), orientations.n, true, true)
		)
		table.insert(
			self.spawnedItems,
			ItemUtil.createStaticItem(enum.item.rope, team.flagLocation + Vector(0, 1.5, 0), orientations.n, true, true)
		)
		table.insert(
			self.spawnedItems,
			ItemUtil.createStaticItem(enum.item.box, team.flagLocation + Vector(0, 2, 0), orientations.n, true, true)
		)
	end
end

function MapBuilder:reset()
	for _, item in pairs(self.spawnedItems) do
		item:remove()
	end

	for _, vehicle in pairs(self.spawnedVehicles) do
		vehicle:remove()
	end

	self.spawnedItems = {}
	self.spawnedVehicles = {}

	for idx, team in pairs(_G.teams) do
		if team.disk then
			team.disk._baseItem:remove()
			team.disk = nil
		end
		local teamData = self.teams[idx]
		local disk = Disk.create(idx, teamData.flagLocation + Vector(0, 1, 0))
		team:setDisk(disk)
	end

	self:buildMap()
	self:buildFlags()
	self:spawnItemsAndVehicles()
end

-- verify

function MapBuilder:verify()
	assert(self.name, "Map name is required")
	assert(self.author, string.format("[map: %s] Author is required", self.name))
	assert(self.mapBounds, string.format("[map: %s] Map bounds are required", self.name))
	assert(#self.teams > 1, string.format("[map: %s] At least 2 teams are required", self.name))

	for _, team in pairs(self.teams) do
		team:verify()
	end

	print("Map verified")

	return self
end

-- util

---@param index integer
function MapBuilder.getVehicleColorByIndex(index)
	local vehicleColors = {
		[1] = enum.color.vehicle.red,
		[2] = enum.color.vehicle.blue,
		[3] = enum.color.vehicle.green,
		[4] = enum.color.vehicle.golden,
	}

	assert(vehicleColors[index], "Invalid vehicle color index")

	return vehicleColors[index]
end

---@param type 'vehicle'|'item'
function MapBuilder:getUid(type)
	if not self.uids then
		self.uids = {}
	end

	if not self.uids[type] then
		self.uids[type] = {}
	end

	local uid = #self.uids[type] + 1

	table.insert(self.uids[type], uid)
	return uid
end

---@param index number
function MapBuilder:getTeam(index)
	return self.teams[index]
end

MapBuilder.TeamBuilder = TeamBuilder

return MapBuilder
