---@class Performance
local Performance = {
	tps = 0,
	mspt = 0,
	playerCount = 0,
	maxPlayers = 0,
	itemCount = 0,
	vehicleCount = 0,
	humanCount = 0,
	eventCount = 0,
}

hook.add("Logic", "Performance", function()
	if server.ticksSinceReset % 62 == 0 then
		-- ---@diagnostic disable-next-line: undefined-field
		-- if not _G.jpxs then
		-- 	print("wating on jpxs to load...")
		-- 	return
		-- end

		--- server performance
		---@type number
		---@diagnostic disable-next-line: undefined-field
		-- Performance.tps = _G.jpxs.tpsInfo.recent
		Performance.mspt = 1 / Performance.tps * 1000
		Performance.playerCount = #players.getNonBots()
		Performance.maxPlayers = server.maxPlayers
		Performance.itemCount = #items.getAll()
		Performance.vehicleCount = #vehicles.getAll()
		Performance.humanCount = #humans.getAll()
		Performance.eventCount = #events.getAll()
	end
end)

return Performance
