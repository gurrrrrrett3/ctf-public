---@class ItemUtil
local ItemUtil = {}

---@param itemType integer
---@param pos Vector
---@param rot RotMatrix
---@param noHover? boolean
---@param noPickup? boolean
---@return Item?
function ItemUtil.createStaticItem(itemType, pos, rot, noHover, noPickup)
	local itemType = itemTypes[itemType]
	local item = items.create(itemType, pos, rot)

	if not item then
		return nil
	end

	item.hasPhysics = true
	item.isStatic = true
	item.rigidBody.isSettled = true
	item.despawnTime = 2147483647
	item.data.noDespawn = true

	if noHover then
		item.parentHuman = humans[255]
	end

	item.data.noPickup = noPickup or false

	return item
end

---@param itemType integer
---@param pos Vector
---@param rot RotMatrix
---@param noHover? boolean
---@param noPickup? boolean
---@return Item?
function ItemUtil.createItem(itemType, pos, rot, noHover, noPickup)
	local itemType = itemTypes[itemType]
	local item = items.create(itemType, pos, rot)

	if not item then
		return nil
	end

	item.hasPhysics = true
	item.despawnTime = 2147483647
	item.data.noDespawn = true

	if noHover then
		item.parentHuman = humans[255]
	end

	item.data.noPickup = noPickup or false

	return item
end

return ItemUtil
