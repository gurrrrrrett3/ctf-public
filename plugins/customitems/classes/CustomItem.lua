local Object = require("main.classic")
local EventEmitter = require("main.eventEmitter")

---@class CustomItem : Object
---@field super Object
---@field public name string
---@field public id string
---@field public baseItem Enum.item
---@field public showPickupText boolean
---@field public isWeapon boolean
---@field public eventEmitter EventEmitter
---@field public isNamePlural boolean
---@field public isVanillaItem boolean
---@field on fun(self: CustomItem, eventName: "create", func: fun(item: Item): nil)
---@field on fun(self: CustomItem, eventName: "remove", func: fun(item: Item): nil)
---@field on fun(self: CustomItem, eventName: "playerPickupItem", func: fun(parentHuman: Human,  item: Item): nil)
---@field on fun(self: CustomItem, eventName: "playerDropItem", func: fun(item: Item): nil)
---@field on fun(self: CustomItem, eventName: "logic", func: fun(item: Item): nil)
---@field on fun(self: CustomItem, eventName: "physics", func: fun(item: Item): nil)
local CustomItem = Object:extend()

---@param name string
---@param baseItem Enum.item
---@return CustomItem
function CustomItem:new(name, baseItem)
	self.super:new()

	local newItem = {}

	newItem.name = name
	newItem.baseItem = baseItem
	newItem.showPickupText = true
	newItem.isWeapon = false
	newItem.eventEmitter = EventEmitter.create()
	newItem.isNamePlural = false

	setmetatable(newItem, self)

	return newItem
end

function CustomItem:on(eventName, func)
	self.eventEmitter:on(eventName, func)
end

---@param pos Vector
---@param rot RotMatrix
function CustomItem:spawn(pos, rot)
	local item = items.create(itemTypes[self.baseItem], pos, rot)
	assert(item, "Failed to create item")
	self:addCustomItemData(item)
	return item
end

---@param item Item
function CustomItem:addCustomItemData(item)
	item.hasPhysics = true
	item.despawnTime = 2147483647
	item.data.noDespawn = true
	item.data.CustomItem = self
end

function CustomItem:__tostring()
	return string.format("CustomItem(%s)", self.id)
end

return CustomItem
