local CustomItem = require("plugins.customitems.classes.CustomItem")
---@class CustomAmmo : CustomItem
---@field super CustomItem
---@field ammoMax number
local CustomAmmo = CustomItem:extend()

---@param name string
---@param baseItem Enum.item
---@param ammoMax number
---@return CustomAmmo
function CustomAmmo:new(name, baseItem, ammoMax)
	---@type CustomAmmo
	---@diagnostic disable-next-line: assign-type-mismatch
	local item = self.super.new(self, name, baseItem)

	item.super = CustomAmmo
	item.ammoMax = ammoMax
	item.isNamePlural = true
	setmetatable(item, self)

	return item
end

---@param pos Vector
---@param rot RotMatrix
function CustomAmmo:spawn(pos, rot)
	local item = items.create(itemTypes[self.baseItem], pos, rot)
	assert(item, "Failed to create item")
	self:addCustomAmmoData(item)
	self:addCustomItemData(item)

	item.bullets = self.ammoMax
	return item
end

function CustomAmmo:onWeapon(eventName, func)
	self.eventEmitter:on(eventName, func)
end

---@param item Item
function CustomAmmo:addCustomAmmoData(item)
	self:addCustomItemData(item)
	item.data.CustomAmmo = self
end

function CustomAmmo:__tostring()
	return string.format("CustomAmmo(%s)", self.id)
end

return CustomAmmo
