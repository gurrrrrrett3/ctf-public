local Scoring = require("modes.pvp.modules.game.scoring")
local Sqlite = require("modes.pvp.modules.database.sqlite")
local QB = require("main.queryBuilder")
local Leaderboard = require("modes.pvp.modules.database.leaderboard")

---@class DatabaseManager
local DatabaseManager = {}

function DatabaseManager.PostGame()
	print("Game over, saving scores...")

	---@type {[integer]: integer}
	local teamScores = {}

	for teamIndex, team in pairs(_G.teams) do
		teamScores[teamIndex] = team.score
	end

	local gameWasTie = teamScores[1] == teamScores[2]
	local winnerTeam = teamScores[1] > teamScores[2] and 1 or 2

	for phoneNumber, player in pairs(Scoring.scores) do
		local state = gameWasTie and "tie" or (player.team == winnerTeam and "win" or "loss")
		Scoring:updateScore(phoneNumber)

		DatabaseManager.updatePlayer(phoneNumber, player, state)
	end

	Sqlite.query(QB.create():insert("matches", {
		redScore = teamScores[1],
		blueScore = teamScores[2],
		winner = winnerTeam,
		tie = gameWasTie and 1 or 0,
	}))

	Leaderboard.updateLeaderboards()
end

---@param phoneNumber integer
---@param player PlayerScore
---@param state "win" | "loss" | "tie"
function DatabaseManager.updatePlayer(phoneNumber, player, state)
	local dbPlayer = Sqlite.getPlayer(phoneNumber, player.name)

	dbPlayer.gamesPlayed = (dbPlayer.gamesPlayed or 0) + 1
	dbPlayer.kills = (dbPlayer.kills or 0) + player.kills
	dbPlayer.assists = (dbPlayer.assists or 0) + player.assists
	dbPlayer.deaths = (dbPlayer.deaths or 0) + player.deaths
	dbPlayer.captures = (dbPlayer.captures or 0) + player.captures
	dbPlayer.returns = (dbPlayer.returns or 0) + player.returns

	if state == "win" then
		dbPlayer.gamesWon = dbPlayer.gamesWon + 1
	elseif state == "loss" then
		dbPlayer.gamesLost = dbPlayer.gamesLost + 1
	else
		dbPlayer.gamesTied = dbPlayer.gamesTied + 1
	end

	dbPlayer.score = Scoring.calculateScore(
		dbPlayer.kills,
		dbPlayer.deaths,
		dbPlayer.captures,
		dbPlayer.assists,
		dbPlayer.returns,
		dbPlayer.gamesWon,
		dbPlayer.gamesLost,
		dbPlayer.gamesTied
	)

	dbPlayer.rank = Scoring.getRank(dbPlayer.score)
	Sqlite.updatePlayer(dbPlayer)
end

return DatabaseManager
