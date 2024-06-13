local ItemUtil = require("plugins.libutil.item")
local LibComputerItem = require("plugins.libcomputer.item")
local LibPacketItem = require("plugins.libpacket.item")
local Team = require("modes.pvp.modules.game.team")
local Scoring = require("modes.pvp.modules.game.scoring")
local Leaderboard = require("modes.pvp.modules.database.leaderboard")
local Avatars = require("modes.pvp.modules.lobby.avatars")
local ComputerControls = require("plugins.libinput.computerControls")
local LoadoutUi = require("modes.pvp.modules.loadouts.ui")
local LobbyMusic = require("modes.pvp.modules.lobby.music")
local Support    = require("modes.pvp.modules.game.support")
local PersistantStorage = require("plugins.persistantStorage.persistantStorage")

---@class LobbyMap
local LobbyMap = {

	---@type LibComputerItem
	statsPc = nil,
	---@type LibComputerItem[]
	leaderboardPcs = {},
	---@type LibComputerItem[]
	statPcs = {},
	---@type LibComputerItem[]
	lastRoundPcs = {},
	---@type LibComputerItem[]
	loadoutPcs = {},
	---@type LibComputerItem[]
	settingsPcs = {},
	---@type LibComputerItem
	supportPc = nil,
	---@type LibComputerItem
	creditsPc = nil,
	---@type integer
	lastRoundPcCurrentTeam = 0,

	---@type Human[]
	podiumHumans = {},
}

---@type {[string]: Item}
local items = {}

---@type {[string]: Item}

---@param pos Vector
function LobbyMap.pillar(pos)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0, 0, 0.75), eulerAnglesToRotMatrix(0, 0, math.rad(90)), true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(-0.75, 0, 0),
		eulerAnglesToRotMatrix(math.rad(90), 0, math.rad(90)),
		true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0, 0, -0.75), eulerAnglesToRotMatrix(0, 0, math.rad(90)), true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0.75, 0, 0),
		eulerAnglesToRotMatrix(math.rad(90), 0, math.rad(90)),
		true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(1, 1.75, 0), eulerAnglesToRotMatrix(math.rad(90), 0, 0), true)
end

---@param pos Vector
function LobbyMap.pillarRotated(pos)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0, 0, 0.75), eulerAnglesToRotMatrix(0, 0, math.rad(90)), true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(-0.75, 0, 0),
		eulerAnglesToRotMatrix(math.rad(90), 0, math.rad(90)),
		true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0, 0, -0.75), eulerAnglesToRotMatrix(0, 0, math.rad(90)), true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0.75, 0, 0),
		eulerAnglesToRotMatrix(math.rad(90), 0, math.rad(90)),
		true)
	ItemUtil.createStaticItem(enum.item.wall, pos + Vector(0, 1.75, 1),
		eulerAnglesToRotMatrix(math.rad(90), math.rad(90), 0),
		true)
end

function LobbyMap.build()
	-- computers

	-- local redSelectTeamPc = ItemUtil.createStaticItem(enum.item.computer, Vector(1687.8, 49.5, 1281.75), orientations.w,
	-- 	true)
	-- assert(redSelectTeamPc, "Failed to create Select Team PC")
	-- redSelectTeamPc.data.computerId = "redSelectTeamPc"
	-- redSelectTeamPc.data.itemTeam = 1
	-- LobbyMap.redSelectTeamPc = LibComputerItem.create(redSelectTeamPc)
	-- local redSelectTeamPacketItem = LibPacketItem:create(redSelectTeamPc)
	-- redSelectTeamPacketItem.useVisibility = false
	-- redSelectTeamPacketItem:setCustomHandler(LobbyMap.teamSelectGUI)

	-- local blueSelectTeamPc = ItemUtil.createStaticItem(enum.item.computer, Vector(1687.8, 49.5, 1279.75), orientations.w,
	-- 	true)
	-- assert(blueSelectTeamPc, "Failed to create Select Team PC")
	-- blueSelectTeamPc.data.computerId = "blueSelectTeamPc"
	-- blueSelectTeamPc.data.itemTeam = 2
	-- LobbyMap.blueSelectTeamPc = LibComputerItem.create(blueSelectTeamPc)
	-- local blueSelectTeamPacketItem = LibPacketItem:create(blueSelectTeamPc)
	-- blueSelectTeamPacketItem.useVisibility = false
	-- blueSelectTeamPacketItem:setCustomHandler(LobbyMap.teamSelectGUI)

	-- leaderboard

	local leaderboardPcs = {
		ItemUtil.createStaticItem(enum.item.computer, Vector(1731.5, 49.25, 1287), orientations.e),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1731.5, 49.25, 1289), orientations.e),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1731.5, 49.25, 1291), orientations.e),
	}

	for i, pc in pairs(leaderboardPcs) do
		pc.data.computerId = "leaderboardPc" .. i
		LobbyMap.leaderboardPcs[i] = LibComputerItem.create(pc)
	end

	-- stats
	local statPcs = {
		ItemUtil.createStaticItem(enum.item.computer, Vector(1731.5, 49.25, 1285), orientations.e),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1731.5, 49.25, 1283), orientations.e),
	}

	for i, pc in pairs(statPcs) do
		pc.data.computerId = "statPc" .. i
		LobbyMap.statPcs[i] = LibComputerItem.create(pc)
	end

	-- last round
	local lastRoundPcs = {
		ItemUtil.createStaticItem(enum.item.computer, Vector(1709, 49.25, 1287.75), orientations.s,
			true),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1707, 49.25, 1287.75), orientations.s,
			true),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1705, 49.25, 1287.75), orientations.s,
			true),
	}

	for i, pc in pairs(lastRoundPcs) do
		pc.data.computerId = "lastRoundPc" .. i
		LobbyMap.lastRoundPcs[i] = LibComputerItem.create(pc)
	end

	-- loadouts
	local loadoutPcs = {
		ItemUtil.createStaticItem(enum.item.computer, Vector(1699, 49.25, 1287.75), orientations.s),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1697, 49.25, 1287.75), orientations.s),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1695, 49.25, 1287.75), orientations.s),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1693, 49.25, 1287.75), orientations.s),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1691, 49.25, 1287.75), orientations.s),
	}

	for i, pc in pairs(loadoutPcs) do
		pc.data.computerId = "loadoutPc" .. i
		LobbyMap.loadoutPcs[i] = LibComputerItem.create(pc)
	end

	-- settings
	local settingsPcs = {
		ItemUtil.createStaticItem(enum.item.computer, Vector(1727, 49.25, 1291.75), orientations.s),
		ItemUtil.createStaticItem(enum.item.computer, Vector(1725, 49.25, 1291.75), orientations.s),
	}

	for i, pc in pairs(settingsPcs) do
		pc.data.computerId = "settingsPc" .. i
		LobbyMap.settingsPcs[i] = LibComputerItem.create(pc)
	end

	-- support
	local supportPc = ItemUtil.createStaticItem(enum.item.computer, Vector(1736, 49.25, 1275.75), orientations.s, true)
	assert(supportPc, "Failed to create Support PC")
	supportPc.data.computerId = "supportPc"
	LobbyMap.supportPc = LibComputerItem.create(supportPc)

	-- last round podium

	local lastRoundPodiumPos = Vector(1713.5, 49, 1287.5)

	LobbyMap.pillarRotated(lastRoundPodiumPos + Vector(0, 0, 0))
	LobbyMap.pillarRotated(lastRoundPodiumPos + Vector(-1.5, -2, 0))
	LobbyMap.pillarRotated(lastRoundPodiumPos + Vector(1.5, -1, 0))

	-- leaderboard podium

	local podiumPos = Vector(1731.5, 49, 1279.5)

	LobbyMap.pillar(podiumPos + Vector(0, 0, 0))
	LobbyMap.pillar(podiumPos + Vector(0, -2, -1.5))
	LobbyMap.pillar(podiumPos + Vector(0, -1, 1.5))

	-- last round podium humans
	if dictLength(Scoring.scores) > 0 then
		---@type {id: integer, name: string, score: integer, team: integer}[]
		local sortedScores = {}

		for id, score in pairs(Scoring.scores) do
			table.insert(sortedScores, {
				id = id,
				name = score.name,
				score = score.score,
				team = score.team
			})
		end

		table.sort(sortedScores, function(a, b)
			return a.score > b.score
		end)

		if sortedScores[1] then
			LobbyMap.createPodiumHuman(sortedScores[1].id, lastRoundPodiumPos + Vector(0, 2.8, 0), orientations.n,
				sortedScores[1].name,
				sortedScores[1].score, 4, sortedScores[1].team)
		end
		if sortedScores[2] then
			LobbyMap.createPodiumHuman(sortedScores[2].id, lastRoundPodiumPos + Vector(1.5, 1.8, 0), orientations.n,
				sortedScores[2].name,
				sortedScores[2].score, 5, sortedScores[2].team)
		end
		if sortedScores[3] then
			LobbyMap.createPodiumHuman(sortedScores[3].id, lastRoundPodiumPos + Vector(-1.5, 0.8, 0), orientations.n,
				sortedScores[3].name,
				sortedScores[3].score, 6, sortedScores[3].team)
		end
	end


	-- podium humans

	local firstPlace = Leaderboard.getLeaderboard("score")[1]
	local secondPlace = Leaderboard.getLeaderboard("score")[2]
	local thirdPlace = Leaderboard.getLeaderboard("score")[3]

	LobbyMap.createPodiumHuman(firstPlace.id, podiumPos + Vector(0, 2.8, 0), orientations.w, firstPlace.name,
		firstPlace.score, 1)
	LobbyMap.createPodiumHuman(secondPlace.id, podiumPos + Vector(0, 1.8, 1.5), orientations.w, secondPlace.name,
		secondPlace.score, 2)
	LobbyMap.createPodiumHuman(thirdPlace.id, podiumPos + Vector(0, 0.8, -1.5), orientations.w, thirdPlace.name,
		thirdPlace.score, 3)

	-- tables

	-- leaderboard

	ItemUtil.createStaticItem(enum.item.table, Vector(1731.5, 48.5, 1283), orientations.e, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1731.5, 48.5, 1285), orientations.e, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1731.5, 48.5, 1287), orientations.e, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1731.5, 48.5, 1289), orientations.e, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1731.5, 48.5, 1291), orientations.e, true, true)
	
	-- last round
	ItemUtil.createStaticItem(enum.item.table, Vector(1709, 48.5, 1287.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1707, 48.5, 1287.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1705, 48.5, 1287.5), orientations.n, true, true)
	-- ItemUtil.createStaticItem(enum.item.table, Vector(1705, 48.5, 1287.5), orientations.n, true, true)

	-- loadouts
	ItemUtil.createStaticItem(enum.item.table, Vector(1699, 48.5, 1287.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1697, 48.5, 1287.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1695, 48.5, 1287.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1693, 48.5, 1287.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1691, 48.5, 1287.5), orientations.n, true, true)

	-- settings 
	ItemUtil.createStaticItem(enum.item.table, Vector(1727, 48.5, 1291.5), orientations.n, true, true)
	ItemUtil.createStaticItem(enum.item.table, Vector(1725, 48.5, 1291.5), orientations.n, true, true)

	-- support
	ItemUtil.createStaticItem(enum.item.table, Vector(1736, 48.5, 1275.5), orientations.n, true, true)

	-- -- team select stuff
	-- ItemUtil.createStaticItem(enum.item.box, Vector(1688.5, 48.25, 1281.75), orientations.n, true, true)
	-- ItemUtil.createStaticItem(enum.item.box, Vector(1688.5, 48.75, 1281.75), orientations.n, true, true)
	-- ItemUtil.createStaticItem(enum.item.box, Vector(1688.5, 48.25, 1279.75), orientations.n, true, true)
	-- ItemUtil.createStaticItem(enum.item.box, Vector(1688.5, 48.75, 1279.75), orientations.n, true, true)

	-- items["redButton"] = ItemUtil.createStaticItem(enum.item.disk_red, Vector(1688.5, 49.5, 1281.75), orientations.n)
	-- items["blueButton"] = ItemUtil.createStaticItem(enum.item.disk_blue, Vector(1688.5, 49.5, 1279.75), orientations.n)

	-- items["redButton"].data.itemTeam = 1
	-- items["blueButton"].data.itemTeam = 2

	-- local lpRedButton = LibPacketItem:create(items["redButton"])
	-- local lpBlueButton = LibPacketItem:create(items["blueButton"])

	-- local function diskActiveHandler(item, player)
	-- 	item._baseItem.isActive = player.data.team ~= item._baseItem.data.itemTeam
	-- end

	-- lpRedButton:setCustomHandler(diskActiveHandler)
	-- lpBlueButton:setCustomHandler(diskActiveHandler)

	LobbyMusic.init()

	-- murals
	QueueMural("lobby.support", Vector(1740, 53.7, 1275.984), math.rad(180), nil, 0.05)
	QueueMural("lobby.leaderboard", Vector(1731.984, 53.7, 1276), math.rad(90), nil, 0.05)
	QueueMural("lobby.settings", Vector(1731, 53.7, 1291.984), math.rad(180), nil, 0.05)
	QueueMural("lobby.loadouts", Vector(1700, 53.7, 1287.984), math.rad(180), nil, 0.05)
	QueueMural("lobby.lastround", Vector(1712, 53.7, 1287.984), math.rad(180), nil, 0.05)
	-- QueueMural("lobby.teamselect", Vector(1688.016, 53.7, 1287), math.rad(270), nil, 0.05)

	local eventCount = BuildQueue()

	return eventCount
end

hook.add("Logic", "LobbyMap", function()
	if #players.getNonBots() == 0 then
		return
	end

	if _G.Game.state == "lobby" and items["redButton"] then
		items["redButton"].rot = eulerAnglesToRotMatrix(
			(server.ticksSinceReset / 100) % math.pi * 2,
			(server.ticksSinceReset / 100) % math.pi * 2,
			(server.ticksSinceReset / 100) % math.pi * 2
		)

		items["blueButton"].rot = eulerAnglesToRotMatrix(
			(server.ticksSinceReset / 100) % math.pi * 2,
			(server.ticksSinceReset / 100) % math.pi * 2,
			(server.ticksSinceReset / 100) % math.pi * 2
		)
	end

	if _G.Game.state == "lobby" and server.ticksSinceReset % 10 == 0 then
		if #LobbyMap.lastRoundPcs > 0 then
			LobbyMap.lastRoundGUI()
		end

		if #LobbyMap.loadoutPcs > 0 then
			LoadoutUi.ui(LobbyMap.loadoutPcs)
		end
	end

	if _G.Game.state == "lobby" and server.ticksSinceReset % 120 == 0 then
		if #LobbyMap.leaderboardPcs > 0 then
			LobbyMap.leaderboardGUI()
		end

		if #LobbyMap.statPcs > 0 then
			LobbyMap.statsGUI()
		end

		for i, pc in pairs(LobbyMap.settingsPcs) do
			LobbyMap.settingsGUI(pc._baseItem.parentHuman and pc._baseItem.parentHuman.player, pc)
		end

		if LobbyMap.supportPc then
			LobbyMap.supportGUI()
		end
	end
end)

hook.add("ItemLink", "LobbyMap", function(item, childItem, parentHuman, slot)
	if not parentHuman then return end

	if item.data.itemTeam then
		if parentHuman.player.data.team ~= item.data.itemTeam then
			_G.Game.setPlayerTeam(parentHuman.player, item.data.itemTeam)
			parentHuman.player:sendMessage(string.format(PVP_lang.lobby_team_select_confirm,
				Team.getTeamNameByIndex(item.data.itemTeam)))
		end

		return hook.override
	end

	if item.data.computerId and item.data.computerId:startsWith("statPc") then
		LobbyMap.statsGUI(LibComputerItem.getFromBaseItem(item), (parentHuman).player)
	end

	if item.data.computerId and item.data.computerId:startsWith("settingsPc") then
		LobbyMap.settingsGUI((parentHuman).player, LibComputerItem.getFromBaseItem(item))
	end
end)

hook.add("HumanLimbInverseKinematics", "LobbyMap",
	function(human, trunkBoneID, branchBoneID, destination, destinationAxis, unk_vecA, unk_a, rotation, strength,
			 unk_vecB, unk_vecC, flags)
		if human.data.isPodiumBot and branchBoneID == 10 then
			local memTable = { { 0x54, 0 }, { 0x7c, 1 }, { 0x58, 5 }, { 0x679c, 4.20 }, { 0x69e8, 4.20 } }
			for i = 1, #memTable do
				memory.writeInt(memory.getAddress(human) + memTable[i][1], memTable[i][2])
			end

			for i = 0, 15 do
				local body = human:getRigidBody(i)
				body.isSettled = true
				body.vel = Vector()
				body.rotVel = RotMatrix()
			end
		end
	end)

---@param player Player
---@param pc Item
---@param key string
hook.add("PlayerComputerInputPress", "LobbyMap", function(player, pc, key)
	if pc.data.computerId and pc.data.computerId:startsWith("leaderboardPc") then
		pc.data.currentIndex = pc.data.currentIndex or 1
		pc.data.sortingInxex = pc.data.sortingInxex or 1
		if ComputerControls.isUp(key) then
			pc.data.currentIndex = pc.data.currentIndex - 1
		elseif ComputerControls.isDown(key) then
			pc.data.currentIndex = pc.data.currentIndex + 1
		elseif ComputerControls.isLeft(key) then
			pc.data.sortingInxex = pc.data.sortingInxex - 1
		elseif ComputerControls.isRight(key) then
			pc.data.sortingInxex = pc.data.sortingInxex + 1
		end

		pc.data.currentIndex = math.clamp(pc.data.currentIndex, 1, #Leaderboard.getLeaderboard("score"))
		pc.data.sortingInxex = pc.data.sortingInxex % 8

		LobbyMap.leaderboardGUI()
	elseif pc.data.computerId and pc.data.computerId:startsWith("settingsPc") then
		pc.data.currentIndex = pc.data.currentIndex or 1
		if ComputerControls.isUp(key) then
			pc.data.currentIndex = pc.data.currentIndex - 1
		elseif ComputerControls.isDown(key) then
			pc.data.currentIndex = pc.data.currentIndex + 1
		elseif ComputerControls.isInteract(key) then
			local itemIndex = 1
			for settingsKey, _ in pairs(GLOBAL_SETTINGS) do
				if pc.data.currentIndex == itemIndex then
					local settingStatus = PersistantStorage.get(player, settingsKey) == "true" and "false" or "true"
					PersistantStorage.set(player, settingsKey, settingStatus)
					break
				end
				
				itemIndex = itemIndex + 1
			end
		end

		pc.data.currentIndex = math.clamp(pc.data.currentIndex, 1, 2)

		LobbyMap.settingsGUI(player, LibComputerItem.getFromBaseItem(pc))
	end
end)

---@param player Player
local function statsPcInputUpdate(player)
	if not player or not player.human then
		return
	end

	local pcItem = player.human:getInventorySlot(0).primaryItem
	if not pcItem or not pcItem.data.computerId or not pcItem.data.computerId:startsWith("statPc") then
		return
	end

	LobbyMap.statsGUI(LibComputerItem.getFromBaseItem(pcItem), player)
end

hook.add("PlayerInputPress[shift]", "LobbyMap", statsPcInputUpdate)
hook.add("PlayerInputRelease[shift]", "LobbyMap", statsPcInputUpdate)

---@param computerItem LibPacketItem
---@param player Player
---@param distance number
function LobbyMap.teamSelectGUI(computerItem, player, distance)
	if not player or not player.human or distance > 5 then
		return
	end

	local computer = LibComputerItem.getFromBaseItem(computerItem._baseItem)
	local teamIndex = computerItem._baseItem.data.itemTeam
	local color = teamIndex == 1 and enum.color.computer.red_light or enum.color.computer.blue_light

	computer:clear(enum.color.computer.black)
	computer:addText(1, 1, PVP_lang.lobby_team_select, enum.color.computer.black, enum.color.computer.white, false)

	-- blue team
	computer:drawHLine(1, 2, 5, color)
	computer:drawHLine(11, 2, 3, color)
	computer:addText(3, 2, string.format(PVP_lang.lobby_team_select_name, Team.getTeamNameByIndex(teamIndex)), color,
		enum.color.computer.white, false)

	local team = _G.teams[teamIndex]
	local index = 0
	if team then
		for i, ply in pairs(team.players) do
			computer:addText(
				1,
				3 + index,
				ply.name,
				enum.color.computer.black,
				ply.index == player.index and enum.color.computer.white or color,
				false
			)
			index = index + 1
		end

		computer:addText(
			1,
			21,
			PVP_lang.lobby_team_select_team_command_tip,
			enum.color.computer.black,
			enum.color.computer.white,
			false
		)
	end

	computer:refresh()
end

function LobbyMap.leaderboardGUI()
	local pcs = LobbyMap.leaderboardPcs

	for i, pc in pairs(pcs) do
		pc:clear(enum.color.computer.black)

		local sortCols = {
			"score",
			"kills",
			"deaths",
			"assists",
			"captures",
			"gamesPlayed",
			"gamesWon",
			"gamesLost",
		}

		local sortingInxex = pc._baseItem.data.sortingInxex or 0
		local sortingBy = sortCols[sortingInxex % #sortCols + 1]

		-- header
		pc:drawHLine(1, 3, pc.width, enum.color.computer.dark_gray)

		pc:addText(1, 3, PVP_lang.lobby_leaderboard_name, enum.color.computer.dark_gray, enum.color.computer.white, false)
		pc:addText(20, 3, PVP_lang.lobby_leaderboard_score, enum.color.computer.dark_gray,
			sortingBy == "score" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(27, 3, PVP_lang.lobby_leaderboard_kills, enum.color.computer.dark_gray,
			sortingBy == "kills" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(32, 3, PVP_lang.lobby_leaderboard_deaths, enum.color.computer.dark_gray,
			sortingBy == "deaths" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(37, 3, PVP_lang.lobby_leaderboard_kd, enum.color.computer.dark_gray,
			sortingBy == "kd" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(43, 3, PVP_lang.lobby_leaderboard_assists, enum.color.computer.dark_gray,
			sortingBy == "assists" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(47, 3, PVP_lang.lobby_leaderboard_captures, enum.color.computer.dark_gray,
			sortingBy == "captures" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(51, 3, PVP_lang.lobby_leaderboard_games, enum.color.computer.dark_gray,
			sortingBy == "gamesPlayed" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(55, 3, PVP_lang.lobby_leaderboard_wins, enum.color.computer.dark_gray,
			sortingBy == "gamesWon" and enum.color.computer.green_light or enum.color.computer.white, false)
		pc:addText(59, 3, PVP_lang.lobby_leaderboard_losses, enum.color.computer.dark_gray,
			sortingBy == "gamesLost" and enum.color.computer.green_light or enum.color.computer.white, false)


		local index = pc._baseItem.data.currentIndex or 1
		local showCount = 15
		local leaderboard = Leaderboard.getLeaderboard(sortingBy)

		pc:addText(1, 1,
			string.format(PVP_lang.lobby_leaderboard, index, math.min(#leaderboard, index + showCount),
				#leaderboard,
				sortingBy),
			enum.color.computer.black, enum.color.computer.white, false)

		for i = index, math.min(#leaderboard, index + showCount) do
			local line = leaderboard[i]

			if not line then
				break
			end

			if i % 2 == 0 then
				pc:drawHLine(1, 4 + i - index, pc.width, enum.color.computer.dark_gray)
			end

			local backgroundColor = i % 2 == 0 and enum.color.computer.dark_gray or enum.color.computer.black

			pc:addText(1, 4 + i - index, line.name:sub(1, 18), backgroundColor, enum.color.computer.white, false)
			pc:addText(20, 4 + i - index, tostring(line.score), backgroundColor, enum.color.computer.white, false)
			pc:addText(27, 4 + i - index, tostring(line.kills), backgroundColor, enum.color.computer.white, false)
			pc:addText(32, 4 + i - index, tostring(line.deaths), backgroundColor, enum.color.computer.white, false)
			pc:addText(37, 4 + i - index, string.format("%.2f", line.kills / (line.deaths == 0 and 1 or line.deaths)),
				backgroundColor, enum.color.computer.white, false)
			pc:addText(43, 4 + i - index, tostring(line.assists), backgroundColor, enum.color.computer.white, false)
			pc:addText(47, 4 + i - index, tostring(line.captures), backgroundColor, enum.color.computer.white,
				false)
			pc:addText(51, 4 + i - index, tostring(line.gamesPlayed), backgroundColor, enum.color.computer.white,
				false)
			pc:addText(55, 4 + i - index, tostring(line.gamesWon), backgroundColor, enum.color.computer.white,
				false)
			pc:addText(59, 4 + i - index, tostring(line.gamesLost), backgroundColor, enum.color.computer.white,
				false)
		end

		pc:addText(1, 21, PVP_lang.lobby_leaderboard_controls, enum.color.computer.black, enum.color.computer.white,
			false)

		pc:refresh()
	end
end

---@param player Player | nil
---@param pc LibComputerItem
function LobbyMap.settingsGUI(player, pc)
	pc:clear(enum.color.computer.black)

	if player then
		
	
		local index = pc._baseItem.data.currentIndex or 1

		pc:addText(1, 1, PVP_lang.lobby_settings, enum.color.computer.black, enum.color.computer.white, false)

		local y = 3
		for settingKey, settingString in pairs(GLOBAL_SETTINGS) do
			local settingStatus = PersistantStorage.get(player, settingKey) == "true" and "Enabled" or "Disabled"
			pc:addText(1, y, (index + 2 == y and "> " or "  ") .. string.format(settingString, settingStatus), enum.color.computer.black, enum.color.computer.white, false)
			y = y + 1
		end
	else
		pc:addText(1, 1, PVP_lang.lobby_settings, enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 2, PVP_lang.lobby_settings_no_player, enum.color.computer.black, enum.color.computer.white, false)
	end

	pc:refresh()
end

function LobbyMap.lastRoundGUI()
	local pc = LobbyMap.lastRoundPcs[1]

	if not pc then
		return
	end

	pc:clear(enum.color.computer.black)
	local currentTeam = LobbyMap.lastRoundPcCurrentTeam
	pc:addText(1, 1,
		string.format("%s | %s Team", PVP_lang.lobby_last_round, Team.getTeamNameByIndex(currentTeam == 1 and 1 or 2)),
		enum.color.computer.black, enum.color.computer.white, false)

	pc:drawHLine(1, 2, pc.width, currentTeam == 1 and enum.color.computer.red_light or enum.color.computer.blue_light)

	pc:addText(1, 4, PVP_lang.lobby_last_round_name, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(20, 4, PVP_lang.lobby_last_round_score, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(26, 4, PVP_lang.lobby_last_round_kills, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(30, 4, PVP_lang.lobby_last_round_deaths, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(34, 4, PVP_lang.lobby_last_round_assists, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(38, 4, PVP_lang.lobby_last_round_captures, enum.color.computer.black, enum.color.computer.white, false)

	local total = {
		score = 0,
		kills = 0,
		deaths = 0,
		assists = 0,
		captures = 0,
	}

	local index = 0
	for id, score in pairs(Scoring.scores) do
		if score.team ~= currentTeam then
			goto continue
		end

		pc:addText(1, 5 + index, score.name, enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(20, 5 + index, tostring(score.score), enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(26, 5 + index, tostring(score.kills), enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(30, 5 + index, tostring(score.deaths), enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(34, 5 + index, tostring(score.assists), enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(38, 5 + index, tostring(score.captures), enum.color.computer.black, enum.color.computer.white, false)

		total.score = total.score + score.score
		total.kills = total.kills + score.kills
		total.deaths = total.deaths + score.deaths
		total.assists = total.assists + score.assists
		total.captures = total.captures + score.captures

		index = index + 1
		::continue::
	end

	pc:addText(20, 19, PVP_lang.lobby_last_round_score, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(26, 19, PVP_lang.lobby_last_round_kills, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(30, 19, PVP_lang.lobby_last_round_deaths, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(34, 19, PVP_lang.lobby_last_round_assists, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(38, 19, PVP_lang.lobby_last_round_captures, enum.color.computer.black, enum.color.computer.white, false)

	pc:addText(1, 20, PVP_lang.lobby_last_round_total, enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(20, 20, tostring(total.score), enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(26, 20, tostring(total.kills), enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(30, 20, tostring(total.deaths), enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(34, 20, tostring(total.assists), enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(38, 20, tostring(total.captures), enum.color.computer.black, enum.color.computer.white, false)


	local switchTimer = server.ticksSinceReset % 1240
	local percentDone = (switchTimer % 620) / 620

	pc:drawHLine(1, 22, pc.width - (pc.width * percentDone), enum.color.computer.white)

	pc:refresh()

	LobbyMap.lastRoundPcs[2]:refreshFrom(pc)
	LobbyMap.lastRoundPcs[3]:refreshFrom(pc)

	LobbyMap.lastRoundPcCurrentTeam = switchTimer > 620 and 1 or 2
end

---@param pc LibComputerItem?
---@param player Player?
function LobbyMap.statsGUI(pc, player)
	if not pc then
		for i, statsPc in pairs(LobbyMap.statPcs) do
			local ply = statsPc._baseItem.parentHuman and statsPc._baseItem.parentHuman.player

			if not ply then
				statsPc:clear(enum.color.computer.black)
				statsPc:addText(1, 1, PVP_lang.lobby_stats, enum.color.computer.black, enum.color.computer.white, false)
				statsPc:addText(1, 3, PVP_lang.lobby_stats_no_player, enum.color.computer.black,
					enum.color.computer.white,
					false)

				statsPc:refresh()
				goto continue
			end

			LobbyMap.statsGUI(statsPc)
			::continue::
		end
	elseif player then
		pc:clear(enum.color.computer.black)
		---@type DatabasePlayer
		local dbInfo = player.data.db

		local rank = dbInfo.rank

		pc:addText(1, 1, PVP_lang.lobby_stats_rank, enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(pc.width, 1, player.account.name, enum.color.computer.black,
			enum.color.computer.white, true)
		pc:bigFont(1, 2, tostring(rank), enum.color.computer.white)

		-- rank info

		local totalScore = dbInfo.score
		local scoreForNextRank = Scoring.getScoreNeededForRank(rank + 1)
		local scoreForThisRank = Scoring.getScoreNeededForRank(rank)
		local scoreTotalForRank = scoreForNextRank - scoreForThisRank
		local thisRankProgression = totalScore - scoreForThisRank

		local percentage = math.floor((thisRankProgression / scoreTotalForRank) * 100)
		local scoreString = string.format(PVP_lang.lobby_stats_score_info, thisRankProgression, scoreTotalForRank,
			percentage)
		pc:addText(1, 9, scoreString,
			enum.color.computer.black, enum.color.computer.white, false)

		local barStartX = 2 + string.len(scoreString)
		local barWidth = pc.width - barStartX - 1

		pc:drawHLine(barStartX, 9, barWidth, enum.color.computer.dark_gray)
		pc:drawHLine(barStartX, 9, barWidth * (percentage / 100), enum.color.computer.green_light)

		local shift = player.data.input.shift

		-- data col 1

		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_kills, "kills", dbInfo.kills, 1, 11, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_deaths, "deaths", dbInfo.deaths, 1, 12, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_assists, "assists", dbInfo.assists, 1, 13, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_captures, "captures", dbInfo.captures, 1, 14, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_returns, "returns", dbInfo.returns, 1, 15, shift)

		-- data col 2

		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_score, "score", dbInfo.score, 30, 11, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_games, "gamesPlayed", dbInfo.gamesPlayed, 30, 12, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_wins, "gamesWon", dbInfo.gamesWon, 30, 13, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_losses, "gamesLost", dbInfo.gamesLost, 30, 14, shift)
		LobbyMap.statsPrintStat(pc, PVP_lang.lobby_stats_ties, "gamesTied", dbInfo.gamesTied, 30, 15, shift)

		local kd = dbInfo.deaths == 0 and dbInfo.kills or dbInfo.kills / dbInfo.deaths
		local wl = dbInfo.gamesLost == 0 and dbInfo.gamesWon or dbInfo.gamesWon / dbInfo.gamesLost

		pc:addText(1, 17, PVP_lang.lobby_stats_kd, enum.color.computer.black, enum.color.computer.gray_light,
			false)
		pc:addText(10, 17, string.format("%.2f", kd), enum.color.computer.black, enum.color.computer.white,
			false)

		pc:addText(1, 18, PVP_lang.lobby_stats_wl, enum.color.computer.black, enum.color.computer.gray_light,
			false)
		pc:addText(10, 18, string.format("%.2f", wl), enum.color.computer.black, enum.color.computer.white,
			false)

		local supportLevel = dbInfo.supportLevel

		pc:addText(1, 20, PVP_lang.lobby_stats_support, enum.color.computer.black,
			enum.color.computer.gray_light, false)
		pc:addText(10, 20, Support.getSupportText(supportLevel), enum.color.computer.black,
			enum.color.computer.white, false)

			if supportLevel > 0 then
				-- split the text into multiple lines
				pc:addText(25, 17, "Thanks for supporting us!", enum.color.computer.black,
					enum.color.computer.white)
				pc:addText(25, 18, "You allow me to cover server costs", enum.color.computer.black,
					enum.color.computer.white)
				pc:addText(25, 19, "and keep the game running!", enum.color.computer.black,
					enum.color.computer.white)

				
			end

		pc:addText(1, 21, PVP_lang.lobby_stats_tip, enum.color.computer.black, enum.color.computer.gray_light)

		pc:refresh()
	end
end

---@param pc LibComputerItem
---@param statName string
---@param statKey string
---@param statValue number
---@param x integer
---@param y integer
---@param shiftPressed boolean
function LobbyMap.statsPrintStat(pc, statName, statKey, statValue, x, y, shiftPressed)
	local value = shiftPressed and Leaderboard.getTop(statKey, statValue) or math.round(Leaderboard.getPercentile(statKey, statValue) * 100, 0)
	pc:addText(x, y, string.format("%s:", statName), enum.color.computer.black, enum.color.computer.gray_light, false)
	pc:addText(x + 10, y, tostring(statValue),
		enum.color.computer.black, enum.color.computer.white, false)
	pc:addText(x + 15, y, string.format(shiftPressed and PVP_lang.lobby_stats_top or PVP_lang.lobby_stats_percentile, value),
		enum.color.computer.black, enum.color.computer.gray_light, false)
end

function LobbyMap.supportGUI()
		local pc = LobbyMap.supportPc

		pc:clear(enum.color.computer.black)

		pc:addText(1, 1, "Support", enum.color.computer.black, enum.color.computer.white, false)
		
		pc:addText(1, 3, "Get in game benefits from our patreon!", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 4, "https://patreon.jpxs.io", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 5, string.char(0xaf):rep(23), enum.color.computer.black, enum.color.computer.white, false)

		pc:addText(1, 6, "Benefits:", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 7, "- Server join priority", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 8, "- Custom song requests in lobby", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 9, "- Extra loadout slots", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 10, "- Patreon-only emotes/hats/poses", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 11, "- Custom name color on leaderboards", enum.color.computer.black, enum.color.computer.white, false)
		pc:addText(1, 12, "- Discord Benefits", enum.color.computer.black, enum.color.computer.white, false)

		pc:addText(1, 14, "- Helps keep the servers up!", enum.color.computer.black, enum.color.computer.white, false)

		pc:addText(1, 16, "Thanks for supporting us!", enum.color.computer.black, enum.color.computer.white, false)
		
		pc:refresh()		

end

---@param phoneNumber integer
---@param pos Vector
---@param rot RotMatrix
---@param name string
---@param score integer
---@param place integer
---@param team integer?
function LobbyMap.createPodiumHuman(phoneNumber, pos, rot, name, score, place, team)
	Avatars.getAvatar(phoneNumber, function(avatar)
		if not avatar then
			return
		end

		local bot = players.createBot()
		assert(bot, "Failed to create bot")
		local human = humans.create(pos:clone(), rot, bot)
		assert(human, "Failed to create human")

		human.model = enum.clothing.casual
		human.gender = avatar.gender
		human.head = avatar.head
		human.skinColor = avatar.skinColor
		human.hairColor = avatar.hairColor
		human.hair = avatar.hair
		human.eyeColor = avatar.eyeColor

		team = team or math.random(1, 2)
		human.model = enum.clothing.casual
		human.suitColor = team == 1 and enum.color.shirt.red or enum.color.shirt.blue

		bot.name = string.format("%s (%s)", name, score)
		bot.phoneNumber = phoneNumber

		human.lastUpdatedWantedGroup = -1
		bot.criminalRating = 50

		bot:update()
		bot:updateFinance()

		human.data.isPodiumBot = true
		human.data.podiumPlace = place

		LobbyMap.podiumHumans[place] = human
	end)
end

return LobbyMap
