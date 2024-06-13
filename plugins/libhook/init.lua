---@type Plugin
local plugin = ...
plugin.name = "libhook"
plugin.author = "gart"

-- typed hooks

local hooks = {
	keys = {
		{ "Human", humans.getAll },
		{ "Item", items.getAll },
		{ "Player", players.getNonBots },
		{ "Vehicle", vehicles.getAll },
	},
	hooks = { "Logic", "Physics" },
}

plugin:addEnableHandler(function(isReload)
	for _, pair in pairs(hooks.keys) do
		for _, hookName in pairs(hooks.hooks) do
			plugin:addHook(hookName, function()
				for _, obj in pairs(pair[2]()) do
					hook.run(pair[1] .. hookName, obj)
				end
			end)
		end
	end
end)

-- Player join queue

local playerJoinQueue = {}

plugin:addHook("PostPlayerCreate", function(ply)
	playerJoinQueue[ply.index] = true
end)

plugin:addHook("PostPlayerDelete", function(ply)
	playerJoinQueue[ply.index] = nil
end)

plugin:addHook("Logic", function()
	for index, _ in pairs(playerJoinQueue) do
		---@type Player
		local player = players[index]
		if player.isBot then
			playerJoinQueue[index] = nil
		else
			if player.connection then
				local connectionAddress = memory.getAddress(player.connection)
				local conEventsSynced = memory.readInt(connectionAddress + 0x4c)
				if conEventsSynced == events.getCount() then
					playerJoinQueue[index] = nil
					hook.run("PlayerInit", player)
				end
			end
		end
	end
end)

plugin:addHook("PostResetGame", function()
	for _, player in pairs(players.getNonBots()) do
		hook.run("PostPlayerCreate", player)
	end
end)
