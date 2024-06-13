---@type Plugin
local plugin = ...
plugin.name = "libutil"
plugin.author = "gart"

plugin:addHook("ItemDelete", function(item)
	if item.data.noDespawn then
		return hook.override
	end
end)
