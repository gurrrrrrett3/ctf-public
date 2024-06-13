local Database = require("modes.pvp.modules.database.sqlite")
local QB = require("main.queryBuilder")
local PersistantStorage = require("plugins.persistantStorage.persistantStorage")
local PersistantStorage = require("plugins.persistantStorage.persistantStorage")
local PointValues = require("modes.pvp.modules.loadouts.pointValues")

---@class Loadouts
Loadouts = {}

---@type {[integer]: {[integer]: {name: string, items: {[integer]: string}}}}
Loadouts.loadouts = {}

function Loadouts.load()
	local loadouts = Database.query(QB:create():select():from("loadouts"))

	if type(loadouts) == "table" then
		for _, loadout in pairs(loadouts) do
			local loadoutId = loadout[1]
			local playerId = loadout[2]
			local loadoutName = loadout[3]

			-- print("Loading loadout " .. loadoutId .. " for player " .. playerId)

			local items = Database.query(
				QB:create()
					:select()
					:from("loadoutItems")
					:where({ column = "loadoutId", operator = "=", value = loadoutId })
			)

			if type(items) == "table" then
				local loadoutItems = {}

				local itc = 0
				for _, item in pairs(items) do
					local itemType = item[3]
					local slotId = item[4]

					loadoutItems[slotId] = itemType
					itc = itc + 1
				end

				Loadouts.loadouts[playerId] = Loadouts.loadouts[playerId] or {}
				Loadouts.loadouts[playerId][loadoutId] = {
					name = loadoutName,
					items = loadoutItems,
				}

				-- print("Loaded " .. itc .. " items for loadout " .. loadoutId .. " for player " .. playerId)
			end
		end
	end
end

---@param player Player
function Loadouts.loadPlayer(player)
	local loadouts = Database.query(
		QB:create():select():from("loadouts"):where({ column = "playerId", operator = "=", value = player.phoneNumber })
	)

	if type(loadouts) == "table" then
		for _, loadout in pairs(loadouts) do
			local loadoutId = loadout[1]
			local loadoutName = loadout[3]

			local items = Database.query(
				QB:create()
					:select()
					:from("loadoutItems")
					:where({ column = "loadoutId", operator = "=", value = loadoutId })
			)

			if type(items) == "table" then
				local loadoutItems = {}

				for _, item in pairs(items) do
					local itemType = item[3]
					local slotId = item[4]

					loadoutItems[slotId] = itemType
				end

				Loadouts.loadouts[player.phoneNumber] = Loadouts.loadouts[player.phoneNumber] or {}
				Loadouts.loadouts[player.phoneNumber][loadoutId] = {
					name = loadoutName,
					items = loadoutItems,
				}
			end
		end
	end

	-- audit loadouts

	local playerLoadouts = Loadouts.getPlayerLoadouts(player)
	if not playerLoadouts then
		return
	end

	local hasInvalidLoadout = false

	for loadoutId, loadout in pairs(playerLoadouts) do
		local loadoutItems = loadout.items

		local loadoutScore = PointValues.getLoadoutPoints(loadoutItems)
		local loadoutHasLockedItems = false

		-- invalid items

		for slotId, itemType in pairs(loadoutItems) do
			local item = ItemManager.getItem(itemType)
			if not item then
				print("LoadoutError: Item not found: " .. itemType)
				goto continue
			end

			if table.contains(player.data.unlocks.item, itemType) then
				print("LoadoutError: Player does not have unlock for item: " .. itemType)
				loadoutHasLockedItems = true
				goto continue
			end

			::continue::
		end

		-- loadout over cost

		if loadoutScore > PointValues.totalCost then
			print(
				"LoadoutError: Loadout " .. loadoutId .. " for player " .. player.phoneNumber .. " exceeds max points"
			)
			messagePlayerWrap(player, string.format(PVP_lang.loadout_audit_over_cost, loadout.name))
			hasInvalidLoadout = true
			-- Loadouts.deleteLoadout(player, loadoutId)
		end

		-- loadout has locked items

		if loadoutHasLockedItems then
			print("LoadoutError: Loadout " .. loadoutId .. " for player " .. player.phoneNumber .. " has locked items")
			messagePlayerWrap(player, string.format(PVP_lang.loadout_audit_locked_items, loadout.name))
			hasInvalidLoadout = true
			-- Loadouts.deleteLoadout(player, loadoutId)
		end
	end

	if hasInvalidLoadout then
		messagePlayerWrap(player, PVP_lang.loadout_audit_invalid)
	end
end

---@param player Player
function Loadouts.savePlayerLoadouts(player)
	local playerLoadouts = Loadouts.getPlayerLoadouts(player)

	for loadoutId, loadout in pairs(playerLoadouts) do
		local loadoutName = loadout.name
		local loadoutItems = loadout.items

		local existingLoadout = Database.query(QB.create():select():from("loadouts"):where({
			{ column = "id", operator = "=", value = loadoutId },
		}))

		-- create if not exists
		if type(existingLoadout) ~= "table" then
			Database.query(QB.create():insert("loadouts", {
				playerId = player.phoneNumber,
				name = loadoutName,
			}))
		end

		-- remove all items
		Database.query(QB.create():delete("loadoutItems"):where({
			{ column = "loadoutId", operator = "=", value = loadoutId },
		}))

		-- insert items
		for slotId, itemType in pairs(loadoutItems) do
			Database.query(QB.create():insert("loadoutItems", {
				loadoutId = loadoutId,
				itemType = itemType,
				slotId = slotId,
			}))
		end
	end
end

---@param player Player
---@param loadoutName string
function Loadouts.createLoadout(player, loadoutName)
	local newLoadout = Database.query(QB.create():insert("loadouts", {
		playerId = player.phoneNumber,
		name = loadoutName,
	}))

	if type(newLoadout) == "table" then
		local loadoutId = newLoadout[1]

		Loadouts.loadouts[player.phoneNumber] = Loadouts.loadouts[player.phoneNumber] or {}
		Loadouts.loadouts[player.phoneNumber][loadoutId] = {
			name = loadoutName,
			items = {},
		}

		return loadoutId
	end
end

---@param player Player
---@param loadoutId integer
function Loadouts.deleteLoadout(player, loadoutId)
	Database.query(QB.create():delete("loadouts"):where({
		{ column = "id", operator = "=", value = loadoutId },
		{ column = "playerId", operator = "=", value = player.phoneNumber },
	}))

	Database.query(QB.create():delete("loadoutItems"):where({
		{ column = "loadoutId", operator = "=", value = loadoutId },
	}))

	Loadouts.loadouts[player.phoneNumber][loadoutId] = nil
end

---@param player Player
---@return {[integer]: {name: string, items: {[integer]: string}}}
function Loadouts.getPlayerLoadouts(player)
	return Loadouts.loadouts[player.phoneNumber] or {}
end

---@param player Player
---@param loadoutId integer
function Loadouts.setLoadout(player, loadoutId)
	player.data.loadout = loadoutId
	PersistantStorage.set(player, "loadout", tostring(loadoutId))
end

---@param human Human
---@param loadoutId? integer
function Loadouts.giveLoadout(human, loadoutId)
	local player = human.player
	if not player then
		return
	end

	loadoutId = loadoutId or tonumber(PersistantStorage.get(player, "loadout"))
	local playerLoadouts = Loadouts.getPlayerLoadouts(player)
	---@type {name: string, items: {[integer]: string}}
	local loadout = playerLoadouts[loadoutId]

	if loadout then
		for slotId, itemType in pairs(loadout.items) do
			local item = ItemManager.getItem(itemType)
			if not item then
				print("Item not found: " .. itemType)
				goto continue
			end

			local itemInstance = ItemManager.spawnItem(itemType, human.pos, orientations.n)
			if not itemInstance then
				print("Failed to spawn item: " .. itemType)
				goto continue
			end

			local actualSlotLocation = math.floor(slotId / 2) + 2
			human:mountItem(itemInstance, actualSlotLocation)

			::continue::
		end
	else
		human:arm(enum.item.m16, 7)
	end
end

return Loadouts
