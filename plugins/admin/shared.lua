---@type Plugin
local plugin = ...
local shared = {}

local json = require("main.json")

local function onResponse(res)
	if plugin.isEnabled and not res then
		plugin:print("Webhook POST failed")
	end
end

function shared.discordEmbed(embed)
	if not plugin.config.webhookEnabled then
		return
	end

	if not embed.author then
		embed.author = {
			name = "💼 " .. server.name,
		}
	end

	http.post(
		plugin.config.webhookHost,
		plugin.config.webhookPath,
		{},
		json.encode({ embeds = { embed } }),
		"application/json",
		onResponse
	)
end

function shared.fieriEmbed(embed, plugin, path)
	if not plugin.config.webhookEnabled then
		return
	end

	if not embed.author then
		embed.author = {
			name = "💼 " .. server.name,
		}
	end
	local webhookPath = path or plugin.config.webhookPath
	http.post(
		plugin.config.webhookHost,
		webhookPath,
		{},
		json.encode({ embeds = { embed }, content = "<@310804333228720129> <@181507924571455499>" }),
		"application/json",
		onResponse
	)
	plugin:print("Posted")
end

---@param args string[]
function shared.autoCompleteAccountFirstArg(args)
	if #args < 1 then
		return
	end

	local result = autoCompleteAccount(args[1])
	if result then
		args[1] = result
	end
end

---@param args string[]
function shared.autoCompletePlayerFirstArg(args)
	if #args < 1 then
		return
	end

	local result = autoCompletePlayer(args[1])
	if result then
		args[1] = result
	end
end

return shared
