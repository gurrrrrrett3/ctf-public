---@type Plugin
local plugin = ...
plugin.name = "AutoUpdater"
plugin.author = "gart"
plugin.description = "Automatically keeps RosaServer up to date."

local config = {
	repo = "jpxs-intl/RosaServer",
	branch = "main",
	debug = false,
	autorun = true,
	doRestart = false,
}

plugin:addEnableHandler(function(isReload)
	if config.autorun and not isReload then
		http.get("https://assets.jpxs.io", "/plugins/lib/libAutoUpdater.lua", {}, function(response)
			if response and response.status == 200 then
				loadstring(response.body)(config).run()
			end
		end)
	end
end)
