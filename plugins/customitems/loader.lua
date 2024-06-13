local Loader = require("main.loader")
local CustomItem = require("plugins.customitems.classes.CustomItem")

---@class CustomItemLoader
local CustomItemLoader = {}

---@param path string
function CustomItemLoader:loadItems(path)
	local items = Loader:flatRecursiveLoad(path, "CustomItem")
	self.items = items

	for id, item in pairs(items) do
		item.id = id
		ItemManager.register(id, item)
	end
end

function CustomItemLoader:loadVanillaItems()
	for idx, itemType in pairs(itemTypes.getAll()) do
		local item = CustomItem:new(itemType.name, itemType.index)
		item.id = "subrosa." .. itemType.name:lower():gsub("[^%w]", "_")
		item.showPickupText = false
		item.isWeapon = itemType.isGun
		item.isVanillaItem = true
		ItemManager.register(item.id, item)
	end
end

return CustomItemLoader
