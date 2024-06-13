require("modes.pvp.lang")
require("modes.pvp.globalSettings")
local Game = require("modes.pvp.modules.game.game")
local Scoring = require("modes.pvp.modules.game.scoring")
local LobbyMusic = require("modes.pvp.modules.lobby.music")
local PersistantStorage = require("plugins.persistantStorage.persistantStorage")

---@type Plugin
local mode = ...
mode.name = "pvp"
mode.author = "gart"

local needsToInit = false
local serverType = TYPE_TERMINATOR + 16

ServerOpen = true
StartGameEnabled = true

local _printPointer = print
function print(...)
	local str = (...)
	if type(str) == "string" then
		str = string.format(...):gsub(string.char(0x0c), "^")
	end
	_printPointer(str)
end

mode:addEnableHandler(function(isReload)
	server.type = serverType
	server.levelToLoad = "round"
	server.state = STATE_GAME
	server.name = "jpxs.ctf " .. (ServerOpen and "[OPEN]" or "[CLOSED]")
	server.maxPlayers = 24

	if not isReload then
		server:reset()

		needsToInit = true
	end
end)

mode:addHook("ResetGame", function()
	server.type = serverType
	server.levelToLoad = "round"
	server.state = STATE_GAME
	server.time = 36000
end)

mode:addHook("PostResetGame", function(reason)
	server.state = STATE_GAME
	server.time = 600

	if needsToInit then
		Game.init()
		needsToInit = false
	end
end)

mode:addHook("PostServerSend", function()
	server.type = serverType
end)

---@param human Human
mode:addHook("HumanPhysics", function(human)
	if human.player and not human.player.isBot and human.isAlive then
		for i = 0, 15 do
			local rb = human:getRigidBody(i)
			if not rb.isActive then
				mode:warn(
					string.format(
						"HumanPhysics: RigidBody is not active!! human: %s, rb: %s, idx: %s, type: %s",
						human.index,
						i,
						rb.index,
						rb.type
					)
				)
				rb.isActive = true
			end
		end
	end
end)

---@param item Item
mode:addHook("ItemLogic", function(item)
	if item.type.isGun and item.bullets > 1 then
		item.bullets = 1
		mode:warn("ItemLogic: item.bullets > 1, setting to 1")
	end
end)

mode.commands["/team"] = {
	info = "Change team",
	alias = { "/t" },
	usage = "[red/blue]",
	call = function(player, human, args)
		if not args[1] then
			player:sendMessage("Usage: /team [team]")
			return
		end

		if player.data.state ~= "lobby" then
			player:sendMessage(PVP_lang.command_team_error_disallowed)
			return
		end

		local teamId = tonumber(args[1])

		if teamId == nil then
			if args[1] == "red" then
				teamId = 1
			elseif args[1] == "blue" then
				teamId = 2
			end
		end

		if not teamId or (teamId < 0 or teamId > 2) then
			player:sendMessage(PVP_lang.command_team_error_invalid)
			return
		end

		Game.setPlayerTeam(player, teamId)
		player:sendMessage(string.format(PVP_lang.command_team_set, teamId))
	end,
}

-- mode.commands["/test"] = {
-- 	info = "test",
-- 	usage = "[red/blue]",
-- 	call = function(player, human, args)
-- 		chat.announce(string.char(0x0c):rep(20))
-- 	end,
-- }

mode.commands["/spectate"] = {
	info = "Spectate",
	alias = { "/spec" },
	call = function(player, human, args)
		if player.data.spectating then
			player.data.spectating = false
			player:sendMessage(PVP_lang.command_spectate_disabled)

			if _G.Game.gameActive then
				player:sendMessage(PVP_lang.command_spectate_disabled_in_game)
				return
			end
		else
			Game.setPlayerTeam(player, 0)
			player.data.spectating = true
			player:sendMessage(PVP_lang.command_spectate_enabled)

			if _G.Game.gameActive then
				if human and human.isAlive == true then
					local rb = human:getRigidBody(0)
					for i = 1, 5 do
						events.createBulletHit(1, rb.pos, Vector())
					end
					rb.vel:add(Vector(math.random(0.1, 2) - 1, math.random(0.1, 2) - 1, math.random(0.1, 2) - 1))
					human.isAlive = false
				end
			end
		end
	end,
}

mode.commands["/loadout"] = {
	info = "Change loadout",
	alias = { "/l" },
	usage = "[loadoutId | loadout name]",
	call = function(player, human, args)
		local loadouts = Loadouts.getPlayerLoadouts(player)

		if not args[1] then
			player:sendMessage(PVP_lang.command_loadouts_header)
			local loadoutIndex = 1
			for _, loadout in pairs(loadouts) do
				player:sendMessage(string.format("%d: %s", loadoutIndex, loadout.name))
				loadoutIndex = loadoutIndex + 1
			end

			return
		end

		local loadoutKey = tonumber(args[1])

		if not loadoutKey then
			player:sendMessage(PVP_lang.command_loadouts_invalid)
			return
		end

		local loadoutIndex = 1
		for loadoutId, loadout in pairs(loadouts) do
			if loadoutKey == loadoutIndex then
				Loadouts.setLoadout(player, loadoutId)
				player:sendMessage(string.format(PVP_lang.command_loadouts_set, loadout.name))
				return
			end

			loadoutIndex = loadoutIndex + 1
		end
	end,
}

mode.commands["/ctfa"] = {
	info = "CTF admin commands",
	canCall = function(player)
		return player.isAdmin or player.isConsole or false
	end,
	---@param player Player
	---@param human Human|nil
	---@param args string[]
	call = function(player, human, args)
		local commands = {
			["start"] = {
				info = "Force start the game",
				call = function()
					if Game.gameActive then
						return "Game is already active."
					end

					for _, ply in pairs(players.getNonBots()) do
						player.data.ready = true
					end

					Game.start()
				end,
			},

			["autobalance"] = {
				info = "Autobalance teams",
				call = function()
					Game.autobalance(#teams)
				end,
			},
			["cars"] = {
				info = "Respawn cars",
				call = function()
					Game.map:spawnVehicles()
				end,
			},
			["teams"] = {
				info = "Show teams",
				call = function()
					for _, team in pairs(_G.teams) do
						player:sendMessage(string.format("Team %d: %d players", team.index, #team.players))
					end
				end,
			},
			["scores"] = {
				info = "Show scores",
				call = function()
					for _, playerScore in pairs(Scoring.scores) do
						player:sendMessage(string.format("%s: %d", playerScore.name, playerScore.score))
					end
				end,
			},
			["skipsong"] = {
				info = "Skip the currently playing lobby song",
				call = function()
					LobbyMusic.nextSong()
				end,
			},
			["playsong"] = {
				info = "Play a specific song",
				call = function()
					table.remove(args, 1)
					local query = table.concat(args, " ")
					LobbyMusic.radio:search(query)
				end,
			},
			["loadout"] = {
				info = "give a loadout",
				call = function()
					table.remove(args, 1)
					local loadoutId = tonumber(args[1])
						or player.data.loadout
						or tonumber(PersistantStorage.get(player, "loadout"))
					assert(loadoutId, "Invalid loadout ID")
					assert(human, "Human is nil")
					Loadouts.giveLoadout(human, loadoutId)

					return "Loadout given"
				end,
			},
			["map"] = {
				info = "Change map",
				call = function()
					table.remove(args, 1)
					local mapName = table.concat(args, " ")
					if Game.setMap(mapName) then
						return "Map set to " .. mapName
					else
						return "Map not found"
					end
				end,
			},
			["lobbybots"] = {
				info = "spawn lobby bots for testing",
				call = function()
					for i = 1, 10 do
						local pos = vecRandBetween(Vector(1739.21, 49, 1260.93), Vector(1732.46, 49, 1274.91))
						SpawnBot(pos)
					end
				end,
			},
			["timer"] = {
				info = "toggle the timer",
				call = function()
					_G.Game.timerEnabled = not _G.Game.timerEnabled
					return "Timer enabled: " .. tostring(Game.timerEnabled)
				end,
			},
		}

		if not args[1] then
			player:sendMessage("Usage: /ctfa [command]")
			player:sendMessage("Available commands: " .. table.concat(table.keys(commands), ", "))
			return
		end

		local command = commands[args[1]]

		if not command then
			player:sendMessage("Invalid command")
			return
		end

		local result = command.call()

		if result then
			player:sendMessage(result)
		end
	end,
}
