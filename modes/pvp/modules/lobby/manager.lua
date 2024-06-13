local LobbyMap = require("modes.pvp.modules.lobby.map")
local LibPacketEvents = require("plugins.libpacket.events")

---@class LobbyManager
local LobbyManager = {
	bounds = {
		a = Vector(1660, 36, 1250),
		b = Vector(1760, 62, 1300),
	},
	spawn = {
		a = Vector(1719.55, 48.84, 1256.34),
		b = Vector(1697.52, 48.84, 1259.42),
	},
	ready = {
		a = Vector(1696.05, 48, 1260.57),
		b = Vector(1720.67, 43, 1282.13),
	},

	countdownLength = 5,
	countdownTimer = 0,
	countdownStarted = false,
	eventWaitingToSync = 0,
	playersSynced = {},
}

function LobbyManager.buildMap()
	local eventCount = LobbyMap.build()

	LobbyManager.eventWaitingToSync = eventCount
	if #players.getNonBots() > 0 then --Fixing 90% cpu usage - JP
		SetTPSDelay(1)
		print("TPS limit disabled, Waiting for " .. eventCount .. " events to sync")
	else
		print("not unlocking TPS, no players to sync")
	end
end

function LobbyManager.startCountdown()
	LobbyManager.countdownStarted = true
	LobbyManager.countdownTimer = LobbyManager.countdownLength * 62
end

---@param player Player?
---@param newState boolean?
function LobbyManager.updatePlayers(player, newState)
	-- updates ready counts and checks if all players are ready

	local players = players.getNonBots()

	local total = math.ceil(#players * _G.Game.config.lobbyReadyPercent)
	local ready = 0

	for _, player in pairs(players) do
		if player.data.ready then
			ready = ready + 1
		end
	end

	if player and newState ~= nil then
		events.createMessage(
			3,
			string.format(
				"%s %s! %d/%d",
				player.name,
				newState and PVP_lang.lobby_ready or PVP_lang.lobby_droppedOut,
				ready,
				total
			),
			-1,
			1
		)
	else
		events.createMessage(3, string.format(PVP_lang.lobby_players_ready, ready, total), -1, 1)
	end

	if ready == total then
		events.createMessage(3, PVP_lang.lobby_all_ready, -1, 1)
		events.createMessage(3, string.format(PVP_lang.lobby_game_starting, LobbyManager.countdownLength), -1, 1)
		LobbyManager.startCountdown()
	end
end

---@param player Player
hook.add("PlayerLogic", "LobbyManager", function(player)
	-- only run lobby logic when game state is lobby
	if player.data.state ~= "lobby" or _G.Game.gameActive or LobbyManager.countdownStarted or not player.human then
		return
	end

	-- ready region

	if StartGameEnabled and isVectorInCuboid(player.human.pos, LobbyManager.ready.a, LobbyManager.ready.b) then
		if not player.data.ready then
			player.data.ready = true
			LobbyManager.updatePlayers(player, true)
		end
	else
		if player.data.ready then
			player.data.ready = false
			LobbyManager.updatePlayers(player, false)
		end
	end

	-- lobby out of bounds

	if
		player.human
		and player.human.isAlive
		and not isVectorInCuboid(player.human.pos, LobbyManager.bounds.a, LobbyManager.bounds.b)
		-- and not player.isAdmin
	then
		-- player.human:remove()
		-- local message = PVP_lang.lobby_outOfBounds[math.random(1, #PVP_lang.lobby_outOfBounds)]
		-- LibPacketEvents.createClientMessage(3, message, -1, 1, player)
	end
end)

hook.add("Logic", "LobbyManager", function()
	-- countdown logic

	if LobbyManager.countdownStarted then
		LobbyManager.countdownTimer = LobbyManager.countdownTimer - 1
		server.time = LobbyManager.countdownTimer + 62

		if LobbyManager.countdownTimer % 62 == 0 then
			local seconds = LobbyManager.countdownTimer / 62
			if seconds > 0 then
				if seconds == 1 then
					events.createMessage(3, PVP_lang.ctf_game_starting_1, -1, 1)
				else
					events.createMessage(3, string.format(PVP_lang.ctf_game_starting, seconds), -1, 1)
				end

				events.createSound(enum.sound.phone.buttons[1], Vector(1706.83, 44.84, 1269.59))
			else
				events.createSound(enum.sound.phone.buttons[1], Vector(1706.83, 44.84, 1269.59), 1, 2)
			end
		end

		if LobbyManager.countdownTimer <= 0 then
			LobbyManager.countdownStarted = false
			LobbyManager.countdownTimer = 0

			_G.Game.start()
		end
	end
end)

hook.add("Physics", "LobbyMap", function()
	-- stuff to make

	if LobbyManager.eventWaitingToSync > 0 then
		local syncCount = 0
		for _, player in pairs(players.getNonBots()) do
			if player.connection:hasReceivedEvent(events[LobbyManager.eventWaitingToSync]) then
				syncCount = syncCount + 1
				break
			else
				player.forwardBackInput = 0
				player.leftRightInput = 0
				player.connection.timeoutTime = 0
				server.time = 59
			end
		end

		if syncCount > 0 then
			LobbyManager.playersSynced = {}
			LobbyManager.eventWaitingToSync = 0

			print("All players synced, TPS back to normal")
			SetTPSDelay(15)

			server.time = Game.config.lobbyTimeSeconds * 60
		end
	end
end)

-- disable human collision in lobby

hook.add("CollideBodies", "LobbyMap", function(aBody, bBody, aLocalPos, bLocalPos, normal, a, b, c, d)
	if _G.Game.state == "lobby" and aBody.type == 0 and bBody.type == 0 then
		return hook.override
	end
end)

return LobbyManager
