local EventEmitter = require("main.eventEmitter")
---@class ItemManager
---@field on fun(eventName: "PostLoad", func: fun(): nil)
ItemManager = ItemManager or {}

---@type {[string]: CustomItem}
ItemManager.items = {}

---@type {[integer]: Item}
ItemManager.spawnedItems = {}

ItemManager.eventEmitter = EventEmitter.create()

--- INTERNAL | Loads hooks for the item manager
---@param plugin Plugin
function ItemManager.loadHooks(plugin)
	hook.add("ItemLink", "customItems.itemManager", function(item, childItem, parentHuman, slot)
		if item and item.data.CustomItem and parentHuman and parentHuman.player then
			---@type CustomItem
			local customItem = item.data.CustomItem
			if
				(not item.data.lastHumanIndex or item.data.lastHumanIndex ~= parentHuman.index)
				and customItem.showPickupText
			then
				parentHuman.player:sendMessage(
					string.format("Picked up %s%s.", customItem.isNamePlural and "" or " a ", customItem.name)
				)
			elseif slot == 0 and customItem.showPickupText then
				parentHuman.player:sendMessage("Holding " .. customItem.name .. ".")
			end

			item.data.lastHumanIndex = parentHuman.index
		end
	end)

	hook.add("Logic", "customItems.itemManager", function()
		for _, item in pairs(ItemManager.spawnedItems) do
			if item and item.data.CustomItem and item.isActive then
				---@type CustomItem
				local customItem = item.data.CustomItem
				customItem.eventEmitter:emit("logic", item)
			end
		end
	end)

	hook.add("Physics", "customItems.itemManager", function()
		for _, item in pairs(ItemManager.spawnedItems) do
			if item and item.data.CustomItem and item.isActive then
				---@type CustomItem
				local customItem = item.data.CustomItem
				customItem.eventEmitter:emit("physics", item)
			end
		end
	end)

	hook.add("ItemDelete", "customItems.itemManager", function(item)
		if item and item.data.CustomItem then
			---@type CustomItem
			local customItem = item.data.CustomItem
			customItem.eventEmitter:emit("remove", item)
		end
	end)

	hook.add("PostItemDelete", "customItems.itemManager", function(item)
		if item and item.data.CustomItem then
			ItemManager.spawnedItems[item.index] = nil
		end
	end)
end

---@param id string
---@param item CustomItem
function ItemManager.register(id, item)
	ItemManager.items[id] = item
	print("Registered item: " .. id)
end

---@param id string
---@return CustomItem
function ItemManager.getItem(id)
	return ItemManager.items[id]
end

---@param id string
---@param pos Vector
---@param rot RotMatrix
---@return Item?, CustomItem?
function ItemManager.spawnItem(id, pos, rot)
	local item = ItemManager.getItem(id)
	if item then
		local obj = item:spawn(pos, rot)
		ItemManager.spawnedItems[obj.index] = obj
		return obj, item
	end
	return nil
end

---@param id string
---@param pos Vector
---@param rot RotMatrix
---@param count number
---@return Item[]?, CustomItem?
function ItemManager.spawnItems(id, pos, rot, count)
	local item = ItemManager.getItem(id)
	if item then
		---@type Item[]
		local objects = {}

		for i = 1, count do
			local obj = item:spawn(pos, rot)
			ItemManager.spawnedItems[obj.index] = obj
			table.insert(objects, obj)
		end

		return objects, item
	end
	return nil
end

---@param id string
---@param player Player
function ItemManager.giveItem(id, player)
	assert(player.human, "Not spawned in.")
	local item = ItemManager.spawnItem(id, player.human.pos:clone(), orientations.n)
	print("Giving item to player: " .. id)
	if item then
		player.human:mountItem(item, 0)
	end
	return item
end

function ItemManager.on(eventName, listener)
	ItemManager.eventEmitter:on(eventName, listener)
end

return ItemManager
