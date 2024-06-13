local Sqlite = require("modes.pvp.modules.database.sqlite")

---@class Leaderboard
local Leaderboard = {}

---@type {[string]: DatabasePlayer[]}
Leaderboard.leaderboards = {}

Leaderboard.itemsToSortBy = {
	"score",
	"gamesPlayed",
	"gamesWon",
	"gamesLost",
	"gamesTied",
	"kills",
	"deaths",
	"assists",
	"captures",
	"returns",
}

---@type {[string]: {[integer]: number}}
Leaderboard.percentileCache = {}
---@type {[string]: {[integer]: number}}
Leaderboard.topCache = {}

---@param limit integer?
function Leaderboard.updateLeaderboards(limit)
	for _, item in pairs(Leaderboard.itemsToSortBy) do
		Leaderboard.leaderboards[item] = Sqlite.getTop(item, limit or 1000)
	end

	Leaderboard.leaderboards["kd"] = Leaderboard.getKDLeaderboard(limit)

	print("Leaderboards updated")
end

---@param type 'score' | 'gamesPlayed' | 'gamesWon' | 'gamesLost' | 'gamesTied' | 'kills' | 'assists' | 'deaths' | 'captures' | 'returns'
---@return DatabasePlayer[]
function Leaderboard.getLeaderboard(type)
	return Leaderboard.leaderboards[type]
end

---@param limit integer?
---@return DatabasePlayer[]
function Leaderboard.getKDLeaderboard(limit)
	local players = Sqlite.getTop("kills", limit or 100)

	---@type {[integer]: number}
	local kdTable = {}

	for i, player in pairs(players) do
		local deaths = player.deaths
		local kills = player.kills
		if deaths == 0 then
			kdTable[i] = kills
		else
			kdTable[i] = kills / deaths
		end
	end

	table.sort(players, function(a, b)
		if not kdTable[a.id] then
			return false
		end
		if not kdTable[b.id] then
			return true
		end

		return kdTable[a.id] > kdTable[b.id]
	end)

	return players
end

---@param stat 'score' | 'gamesPlayed' | 'gamesWon' | 'gamesLost' | 'gamesTied' | 'kills' | 'assists' | 'deaths' | 'captures' | 'returns'
---@param value number
function Leaderboard.getPercentile(stat, value)
	if not Leaderboard.percentileCache[stat] then
		Leaderboard.percentileCache[stat] = {}
	end

	if not Leaderboard.percentileCache[stat][value] then
		local players = Leaderboard.getLeaderboard(stat)
		local count = #players
		local index = 0

		for i, player in pairs(players) do
			if player[stat] == value then
				index = i
				break
			end
		end

		Leaderboard.percentileCache[stat][value] = index / count
	end

	return Leaderboard.percentileCache[stat][value]
end

---@param stat 'score' | 'gamesPlayed' | 'gamesWon' | 'gamesLost' | 'gamesTied' | 'kills' | 'assists' | 'deaths' | 'captures' | 'returns'
---@param value number
function Leaderboard.getTop(stat, value)
	if not Leaderboard.topCache[stat] then
		Leaderboard.topCache[stat] = {}
	end

	if not Leaderboard.topCache[stat][value] then
		local players = Leaderboard.getLeaderboard(stat)
		local count = #players
		local index = 0

		for i, player in pairs(players) do
			if player[stat] == value then
				index = i
				break
			end
		end

		Leaderboard.topCache[stat][value] = index
	end

	return Leaderboard.topCache[stat][value]
end

---@param playerPhoneNumber integer
function Leaderboard.getScoreRanking(playerPhoneNumber)
	local player = Sqlite.getPlayer(playerPhoneNumber)

	return (player.gamesPlayed / 10) * (player.kills / player.deaths)
end

return Leaderboard
