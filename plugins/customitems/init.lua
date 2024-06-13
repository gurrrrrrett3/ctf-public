local CustomItemLoader = require("plugins.customitems.loader")
local ItemManager = require("plugins.customitems.managers.itemManager")
local WeaponManager = require("plugins.customitems.managers.weaponManager")

---@type Plugin
local plugin = ...
plugin.name = "customitems"
plugin.author = "gart"

plugin:addEnableHandler(function(isReload)
	CustomItemLoader:loadVanillaItems()
	CustomItemLoader:loadItems("plugins/customitems/namespaces")

	ItemManager.loadHooks(plugin)
	WeaponManager.loadHooks(plugin)

	ItemManager.eventEmitter:emit("PostLoad")
end)

plugin.commands["/customitem"] = {
	info = "Spawn a custom item",
	alias = { "/cit" },
	usage = "[name]",
	canCall = function(player)
		return player.isAdmin
	end,
	call = function(player, human, args)
		assert(#args >= 1, "usage")
		assert(human, "Not spawned in")

		local pos = human.pos:clone()
		pos.x = pos.x + (2 * math.cos(human.viewYaw - math.pi / 2))
		pos.y = pos.y + 0.2
		pos.z = pos.z + (2 * math.sin(human.viewYaw - math.pi / 2))

		local item, customItem = ItemManager.spawnItem(args[1], pos, orientations.n)
		if not item then
			player:sendMessage("Item not found")
			return
		end

		adminLog("%s spawned %s (%s)", player.name, customItem and customItem.name or "unknown", args[1])
	end,
}
