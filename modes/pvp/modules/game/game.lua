local MapLoader = require("modes.pvp.modules.maps.mapLoader")
local Team = require("modes.pvp.modules.game.team")
local Lobby = require("modes.pvp.modules.lobby.manager")
local Database = require("modes.pvp.modules.database.sqlite")
local LibComputer = require("plugins.libcomputer.libcomputer")
local LibPacketEvents = require("plugins.libpacket.events")
local Scoring = require("modes.pvp.modules.game.scoring")
local DatabaseManager = require("modes.pvp.modules.database.databaseManager")
local Leaderboard = require("modes.pvp.modules.database.leaderboard")
local Unlocks = require("modes.pvp.modules.loadouts.unlocks")
local Loadouts = require("modes.pvp.modules.loadouts.loadouts")
local TaskScheduler = require("main.taskScheduler")

---@class CTFConfig
---@field diskResetTimeSeconds integer Time in seconds that the disc takes to auto reset
---@field teamMustHaveFlagToScore boolean Whether the team must have their own flag at the pedestal to score
---@field roundTimeSeconds integer Time in seconds for each round
---@field lobbyTimeSeconds integer Time in seconds for the lobby
---@field targetType "firstTo" | "rounds" The type of target for the game
---@field targetValue integer The target value for the game
---@field vehicleRespawnSeconds integer Time in seconds between vehicle respawns
---@field lobbyReadyPercent number  Percentage of players that need to be ready for the game to start
---@field respawnTimeSeconds number Time in seconds for respawn
---@field defaultMap string The default map to use

---@class Game
local Game = {
	---@type MapBuilder
	map = nil,

	---@type CTFConfig Game config
	config = {
		diskResetTimeSeconds = 20,
		teamMustHaveFlagToScore = false,
		roundTimeSeconds = 600,
		lobbyTimeSeconds = 120,
		targetType = "firstTo",
		targetValue = 3,
		vehicleRespawnSeconds = 15,
		lobbyReadyPercent = 0.75,
		respawnTimeSeconds = 10,
		defaultMap = "corps",
	},

	---@type Database
	db = Database,

	---@enum Game.State
	STATE = {
		lobby = "lobby",
		game = "game",
		roundOver = "round over",
		gameOver = "game over",
		resetting = "resetting",
	},

	---@enum Game.PlayerState
	PLAYER_STATE = {
		lobby = "lobby",
		ingame = "ingame",
	},

	---@type Game.State Current game state
	state = "lobby",

	---@type boolean
	gameActive = false,

	---@type boolean
	gameResetting = false,

	---@type integer
	espHideTimer = -1,

	---@type integer
	gameResetTimer = 0,

	---@type integer
	roundNumber = 1,
}

---@type boolean
Game.timerEnabled = true

---@type table<integer, Team>
_G.teams = {}
_G.Game = Game

LibComputer.handler.loadHandlers("modes/pvp/modules/computerHandlers")
Database.open()

---@param index integer
---@return Team
function Game.getTeam(index)
	return _G.teams[index]
end

---@param map string
function Game.setMap(map)
	if not MapLoader.maps[map] then
		return false
	end

	Game.map = MapLoader.maps[map]
	Game.map:verify()

	return true
end

---@param player Player
---@param teamIndex integer
function Game.setPlayerTeam(player, teamIndex)
	for _, team in pairs(_G.teams) do
		team.players[player.index] = nil
	end

	player.data.team = teamIndex

	if player.human then
		player.human.model = enum.clothing.casual
		player.human.suitColor = teamIndex == 1 and enum.color.suit.red or enum.color.suit.blue
		player.human.lastUpdatedWantedGroup = -1
	end

	if _G.teams[teamIndex] then
		_G.teams[teamIndex].players[player.index] = player
	end
end

---@param teamIndex integer
function Game.calculateTeamRankingScore(teamIndex) end

---@param teamCount integer
---@param exclude Player[]?
function Game.autobalance(teamCount, exclude)
	local playerCount = 0
	local players = players.getNonBots()

	for _, team in pairs(_G.teams) do
		team.players = {}
	end

	for _, player in pairs(players) do
		if not exclude or not exclude[player.index] then
			Game.setPlayerTeam(player, Game.getLeastPopulatedTeamIndex())
			playerCount = playerCount + 1
		end
	end
end

function Game.getLeastPopulatedTeamIndex()
	return teams[1]:getPlayerCount() < teams[2]:getPlayerCount() and 1 or 2
end

---@param state Game.State
function Game.setState(state)
	local oldState = Game.state
	Game.state = state
	print("Game state changed from " .. oldState .. " to " .. state)
end

function Game.init()
	print("Initializing CTF")

	MapLoader.loadMaps()
	Game.map = MapLoader.maps[Game.config.defaultMap]
	Game.map:verify()

	Leaderboard.updateLeaderboards()
	Loadouts.load()

	Lobby.buildMap()

	for _, player in pairs(players.getNonBots()) do
		player.team = 0
	end

	-- Teams

	for idx, _ in pairs(Game.map.teams) do
		local team = Team.create(idx)

		_G.teams[idx] = team
	end

	for _, player in pairs(players.getNonBots()) do
		player.data.state = Game.STATE.lobby
		player.data.ready = false

		Unlocks.giveForRank(player, player.data.db.rank or 1, player.data.db.supportLevel or 0)
	end

	chat.announceWrap("discord.jpxs.io")

	-- Hooks

	hook.add("PostResetGame", "ctf.game", function(reason)
		print("Game reset: current mode is " .. Game.state)

		if Game.state == Game.STATE.lobby then
			for _, player in pairs(players.getNonBots()) do
				player.data.state = Game.STATE.lobby
				player.data.ready = false

				Unlocks.giveForRank(player, player.data.db.rank or 1, player.data.db.supportLevel or 0)
			end

			chat.announceWrap(PVP_lang.discord)

			Lobby.buildMap()
			TaskScheduler.runNextTick(function()
				server.time = Game.config.lobbyTimeSeconds * 60
			end)
		elseif Game.state == Game.STATE.game then
			Game.beginRound()
		end
	end)

	hook.add("Logic", "ctf.game", function()
		server.state = 2

		if Game.timerEnabled then
			server.time = server.time - 1
		end

		-- Time announcements

		if server.time / 60 == Game.config.roundTimeSeconds / 2 then
			events.createMessage(3, string.format(PVP_lang.ctf_time_halfway, server.time / 3600), -1, 1)
		end

		if server.time / 60 == 60 then
			events.createMessage(3, PVP_lang.ctf_time_one_minute, -1, 1)
		end

		if server.time / 60 == 30 then
			events.createMessage(3, PVP_lang.ctf_time_thirty_seconds, -1, 1)
		end

		if server.time == 0 then
			if Game.state == Game.STATE.game then
				Game.handleTie()
			end

			if Game.state == Game.STATE.lobby then
				Game.start()
			end
		end

		-- Game reset

		if Game.gameResetting then
			Game.gameResetTimer = Game.gameResetTimer - 1
			server.time = Game.gameResetTimer

			if Game.gameResetTimer <= 0 then
				Game.gameResetting = false
				Game.gameActive = true
				Game.gameResetTimer = 0

				if Game.state == Game.STATE.roundOver then
					for _, player in pairs(players.getNonBots()) do
						if player.data.state == Game.PLAYER_STATE.ingame then
							player.data.ready = true
							if player.human then
								player.human:remove()
							end
						end
					end

					Game.setState(Game.STATE.game)
					Game.roundNumber = Game.roundNumber + 1
					server:reset()
				elseif Game.state == Game.STATE.gameOver then
					DatabaseManager.PostGame()

					for _, player in pairs(players.getNonBots()) do
						player.data.state = Game.STATE.lobby
						player.data.ready = false
						if player.human then
							player.human:remove()
						end
					end

					for _, team in pairs(_G.teams) do
						team.score = 0
						team.disk._baseItem:remove()
						team.disk = nil
					end

					Game.setState(Game.STATE.lobby)
					Game.roundNumber = 1
					Game.gameActive = false
					server:reset()
				end
			end
		end

		-- ESP hiding

		if Game.espHideTimer > 0 then
			Game.espHideTimer = Game.espHideTimer - 1
		elseif Game.espHideTimer == 0 then
			-- for _, player in pairs(players.getNonBots()) do
			-- 	LibPacketEvents.hideEliminatorESP(player)
			-- end

			Game.espHideTimer = -1
		end

		-- Spawning

		for _, player in ipairs(players.getNonBots()) do
			if player.human == nil and not player.data.spectating and not player.data.isRespawning then
				if not player.data.team then
					-- lobby team
					player.data.team = 0
				end

				--- conditions to spawn in game
				-- 1. game is in progress
				-- 2. player is in a game team

				if Game.gameActive and player.data.team > 0 then
					player.data.ready = false
					player.data.state = Game.PLAYER_STATE.ingame

					-- game team
					local team = Game.getTeam(player.data.team)
					local spawn = Game.map.teams[player.data.team].spawnRegion
					local spawnDirection = Game.map.teams[player.data.team].spawnDirection

					if spawn then
						local man = humans.create(vecRandBetween(spawn.a, spawn.b), spawnDirection, player)
						hook.run("PostHumanCreate", man)

						man.suitColor = team.index == 1 and enum.color.suit.red or enum.color.suit.blue
						man.model = enum.clothing.casual
						man.lastUpdatedWantedGroup = -1

						assert(man, "failed to spawn man")
						Loadouts.giveLoadout(man)
					end
				elseif not Game.gameActive then
					-- lobby team
					player.data.state = Game.STATE.lobby
					player.data.ready = false
					local man = humans.create(vecRandBetween(Lobby.spawn.a, Lobby.spawn.b), orientations.nw, player)
					hook.run("PostHumanCreate", man)

					assert(man, "failed to spawn human")

					-- local memo = items.create(itemTypes[enum.item.paper], man.pos:clone(), orientations.n)
					-- assert(memo, "failed to spawn memo")
					-- local textFile = io.open("modes/ctf/data/memo.txt")
					-- assert(textFile, "failed to open memo.txt")
					-- local text = textFile:read("*a")
					-- textFile:close()
					-- memo.memoText = text
					-- -- memo.data.noDespawn = true
					-- memo.despawnTime = 2147483647

					-- man:mountItem(memo, 0)
				else
					local teamIndex = Game.getLeastPopulatedTeamIndex()
					Game.setPlayerTeam(player, teamIndex)

					LibPacketEvents.createClientMessage(
						3,
						string.format("%s " .. PVP_lang.ctf_currentTeam, "", Team.getTeamNameByIndex(teamIndex)),
						-1,
						1,
						player
					)
				end
			elseif player.data.isRespawning then
				if player.data.respawnTimer > 0 then
					player.data.respawnTimer = player.data.respawnTimer - 1
				else
					player.data.isRespawning = false
				end
			end
		end

		-- vehicle respawn

		if Game.gameActive and server.ticksSinceReset % math.floor(Game.config.vehicleRespawnSeconds * 62.5) == 0 then
			Game.map:spawnVehicles()
		end

		-- Disks

		for _, team in pairs(_G.teams) do
			if not team.disk or not Game.gameActive or Game.gameResetting then
				goto continue
			end
			if team.disk.isStatic then
				team.disk._baseItem.rot = eulerAnglesToRotMatrix(
					(server.ticksSinceReset / 100) % math.pi * 2,
					(server.ticksSinceReset / 100) % math.pi * 2,
					(server.ticksSinceReset / 100) % math.pi * 2
				)
			end

			if team.disk._baseItem.physicsSettled and not team.disk.isBeingHeld and not team.disk.isStatic then
				team.disk._baseItem.hasPhysics = false
				team.disk._baseItem.isStatic = true
				team.disk._baseItem.pos = team.disk._baseItem.pos + Vector(0, 1, 0)
				team.disk.isStatic = true
			end

			if team.disk.resetTimer > 0 and not team.disk.isBeingHeld then
				team.disk.resetTimer = team.disk.resetTimer - 1

				local secondsLeft = math.floor(team.disk.resetTimer / 62.5)

				if server.ticksSinceReset % 62 == 0 then
					team.disk._baseItem:speak(tostring(secondsLeft), 2)
				end

				if team.disk.resetTimer <= 0 then
					team.disk:reset()
				end
			end

			-- beep
			if server.ticksSinceReset % (62 * 3) == 0 then
				local pitch = team.disk.resetTimer > 0
						and 1 + (1 - (team.disk.resetTimer / (Game.config.diskResetTimeSeconds * 62.5)))
					or 1

				events.createSound(enum.sound.phone.buttons[1], team.disk._baseItem.pos, 0.5, pitch)
			end

			-- capture logic

			for _, otherTeam in pairs(_G.teams) do
				if not otherTeam.disk or otherTeam.index == team.index then
					goto continue
				end
				if Game.config.teamMustHaveFlagToScore and not team.disk.isAtPedestal then
					goto continue
				end

				local captureRegion = Game.map.teams[otherTeam.index].captureRegion

				if isVectorInCuboid(team.disk._baseItem.pos, captureRegion.a, captureRegion.b) then
					if not team.disk.hasExploded then
						Game.handleCapture(players[team.disk.lastHeldBy])
						events.createExplosion(team.disk._baseItem.pos:clone())
						team.disk.hasExploded = true
					end
				end

				::continue::
			end
			::continue::
		end
	end)

	-- Item pickup logic

	hook.add("ItemLink", "ctf.game", function(item, childItem, parentHuman, slot)
		if item.data.Disk then
			---@type Disk
			local disk = item.data.Disk

			if not Game.gameActive or Game.gameResetting then
				return hook.override
			end

			-- picked up own disk (return)
			if parentHuman and parentHuman.player.data.team == disk.teamIndex then
				if not disk.isAtPedestal then
					disk:reset(false)

					events.createMessage(
						3,
						string.format(PVP_lang.ctf_flag_returned, Team.getTeamNameByIndex(disk.teamIndex)),
						-1,
						1
					)

					Scoring.returnFlag(parentHuman.player)
				end
				return hook.override
			end

			disk.isBeingHeld = not not parentHuman

			-- picked up static disk
			if disk.isStatic and disk.isBeingHeld then
				disk.isStatic = false
				disk._baseItem.hasPhysics = true
				disk._baseItem.isStatic = false
				disk.isAtPedestal = false
				disk.lastHeldBy = (parentHuman).player.index

				events.createMessage(
					3,
					string.format(
						PVP_lang.ctf_flag_taken,
						(parentHuman).player.name,
						Team.getTeamNameByIndex(disk.teamIndex)
					),
					-1,
					1
				)
			end

			-- disk dropped
			if not disk.isBeingHeld then
				disk.resetTimer = Game.config.diskResetTimeSeconds * 62.5
				LibPacketEvents.hideEliminatorESP(players[disk.lastHeldBy])

				-- disk picked up
			else
				disk.resetTimer = 0
				disk.lastHeldBy = (parentHuman).player.index

				-- get center of capture region
				local spawnPos = (
					Game.map.teams[(parentHuman).player.data.team].captureRegion.a
					+ Game.map.teams[(parentHuman).player.data.team].captureRegion.b
				) / 2

				LibPacketEvents.createClientMessage(
					3,
					string.format(PVP_lang.ctf_have_flag, Team.getTeamNameByIndex(disk.teamIndex)),
					-1,
					1,
					(parentHuman).player
				)

				LibPacketEvents.showEliminatorESP((parentHuman).player, spawnPos, 2)
			end
		end
	end)

	hook.add("HumanLimbInverseKinematics", "ctf.game", function(human, _, trunkBoneId)
		if
			not Game.gameActive
			or trunkBoneId ~= 10
			or not human.player
			or not human.player.data.team
			or human.player.data.team > 4
		then
			return
		end

		local otherTeam = human.player.data.team and (human.player.data.team == 1 and 2 or 1) or nil
		local otherTeamOnlyArea = Game.map.teams[otherTeam].teamOnlyRegion

		if
			isVectorInCuboid(human.pos, Game.map.mapBounds.a, Game.map.mapBounds.b)
			and (not otherTeamOnlyArea or not isVectorInCuboid(human.pos, otherTeamOnlyArea.a, otherTeamOnlyArea.b))
		then
			human.data.oldPosition = human.vehicle and human.vehicle.pos:clone() or human.pos:clone()
			human.data.isInBounds = true
		else
			if human.data.oldPosition then
				if human.vehicle then
					local force = human.vehicle.rigidBody.vel:clone() + (human.data.oldPosition - human.pos) / 10
					human.vehicle.rigidBody.vel = Vector(force.x, 0, force.z)
				else
					human:addVelocity((human.data.oldPosition - human.pos) / 2)
				end

				if human.player and human.data.isInBounds then
					LibPacketEvents.createClientMessage(
						3,
						PVP_lang.ctf_game_outOfBounds[math.random(1, #PVP_lang.ctf_game_outOfBounds)],
						-1,
						1,
						human.player
					)
				end

				human.data.isInBounds = false
			else
				-- man.data.oldPosition = man.pos:clone()
			end
		end
	end)

	hook.add("PostPlayerDeathTax", "ctf.game", function(player)
		player.data.isRespawning = true
		player.data.respawnTimer = Game.config.respawnTimeSeconds * 62
		player:sendMessage(string.format(PVP_lang.ctf_death_respawning, Game.config.respawnTimeSeconds))

		if player.human and not player.human.data.loadout then
			player:sendMessage(PVP_lang.ctf_loadout_tip)
		end
	end)

	hook.add("BulletHitHuman", "ctf.game", function(human, bullet)
		local bulletOwner = bullet.player
		if not bulletOwner or not bulletOwner.data.team then
			return
		end

		local bulletTeam = Game.getTeam(bulletOwner.data.team)
		if not bulletTeam then
			return
		end

		if human.player and human.player.data and human.player.data.team == bulletOwner.data.team then
			return hook.override
		end
	end)

	hook.add("HumanCollisionVehicle", "ctf.game", function(human, vehicle)
		if not Game.gameActive then
			return
		end

		local driver = vehicle.lastDriver
		if not driver or not driver.data.team or not human.player or not human.player.data.team then
			return
		end

		if driver.data.team == human.player.data.team then
			return hook.override
		end
	end)

	hook.add("EventBullet", "ctf.game", function(type, position, velocity, item)
		for _, team in pairs(Game.map.teams) do
			if team.teamOnlyRegion and isVectorInCuboid(position, team.teamOnlyRegion.a, team.teamOnlyRegion.b) then
				return hook.override
			end
		end
	end)
end

function Game.start()
	Game.gameActive = true
	Game.setState(Game.STATE.game)

	if #_G.teams == 2 then
		Game.espHideTimer = 600
	end

	Scoring:init()

	server:reset()
end

function Game.beginRound()
	Game.map:reset()

	for _, player in pairs(players.getNonBots()) do
		if not player.data.team or player.data.team == 0 then
			player.data.team = math.random(1, #_G.teams)
		end
	end

	for _, team in pairs(_G.teams) do
		if team.disk then
			team.disk:reset(false)
		end
	end

	for _, player in pairs(players.getNonBots()) do
		local team = Game.getTeam(player.data.team)
		if not team then
			return
		end
		local teamName = team.getTeamNameByIndex(team.index)

		LibPacketEvents.createClientMessage(
			3,
			string.format(
				"%s " .. PVP_lang.ctf_currentTeam,
				Game.roundNumber == 1 and "" or PVP_lang.ctf_game_started,
				teamName
			),
			-1,
			1,
			player
		)

		if #_G.teams == 2 then
			local opposingTeam = Game.getTeam(team.index == 1 and 2 or 1)
			local opposingTeamName = team.getTeamNameByIndex(opposingTeam.index)

			LibPacketEvents.createClientMessage(
				3,
				string.format(PVP_lang.ctf_game_instructions, opposingTeamName),
				-1,
				1,
				player
			)

			local opposingTeamFlagPos = Game.map.teams[opposingTeam.index].flagLocation

			LibPacketEvents.showEliminatorESP(player, opposingTeamFlagPos, 1)
		end

		if player.human then
			player.human:remove()
			player.data.needsWeapons = true
		end
	end

	TaskScheduler.runNextTick(function()
		server.time = Game.config.roundTimeSeconds * 60
	end)
end

---@param player Player
function Game.handleCapture(player)
	if Game.gameResetting then
		return
	end
	local team = Game.getTeam(player.data.team)
	local teamName = team.getTeamNameByIndex(team.index)

	team.score = team.score + 1

	Scoring.capture(player)

	events.createMessage(3, string.format(PVP_lang.ctf_point_scored, player.name, teamName), -1, 1)
	events.createSound(enum.sound.misc.whistle, player.human.pos:clone(), 1, 1)

	Game.handleEndOfRound(team)
end

function Game.handleTie()
	---@type {[integer]: number}
	local scores = {}

	for _, team in pairs(_G.teams) do
		local teamScore = 0

		for index, player in pairs(team.players) do
            if Scoring.scores[player.phoneNumber] then
				teamScore = teamScore + (Scoring.scores[player.phoneNumber].score or 0)
            end
		end

		scores[team.index] = teamScore
	end

	---@type Team[]
	local sortedTeams = {}

	for _, team in pairs(_G.teams) do
		table.insert(sortedTeams, team)
	end

	table.sort(sortedTeams, function(a, b)
		return scores[a.index] > scores[b.index]
	end)

	-- if scores[sortedTeams[1].index] == scores[sortedTeams[2].index] then
	-- 	events.createMessage(3, PVP_lang.ctf_score_tie, -1, 1)
	-- 	Game.handleEndOfRound(nil)
	-- end

	local highestScore = scores[sortedTeams[1].index]
	local highestTeam = sortedTeams[1]

	if highestTeam then
		if Game.gameResetting then
			return
		end

		events.createMessage(
			3,
			string.format(PVP_lang.ctf_score_win, highestTeam.getTeamNameByIndex(highestTeam.index), highestScore),
			-1,
			1
		)
		Game.handleEndOfRound(highestTeam)
	end
end

---@param winningTeam Team
function Game.handleEndOfRound(winningTeam)
	local nextState = Game.STATE.roundOver

	if Game.config.targetType == "firstTo" then
		if winningTeam.score >= Game.config.targetValue then
			nextState = Game.STATE.gameOver
		end
	elseif Game.config.targetType == "rounds" then
		if Game.roundNumber >= Game.config.targetValue then
			nextState = Game.STATE.gameOver
		end
	end

	local sortedTeams = {}

	for _, team in pairs(_G.teams) do
		table.insert(sortedTeams, team)
	end

	table.sort(sortedTeams, function(a, b)
		return a.score > b.score
	end)

	if nextState == Game.STATE.gameOver then
		chat.announceWrap(PVP_lang.ctf_game_over)
	else
		chat.announceWrap(string.format(PVP_lang.ctf_round_over, Game.roundNumber))
	end
	for i, team in pairs(sortedTeams) do
		chat.announceWrap(string.format("%s: %d", team.getTeamNameByIndex(team.index), team.score))
	end

	Game.setState(nextState)
	Game.gameResetTimer = 600
	Game.gameResetting = true
end

return Game
