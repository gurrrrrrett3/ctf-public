---@class PlayerScore
---@field public name string
---@field public team integer
---@field public kills integer
---@field public deaths integer
---@field public assists integer
---@field public captures integer
---@field public returns integer
---@field public score integer

---@class Scoring
local Scoring = {
	---@type {[integer]: PlayerScore}
	scores = {},

	PointValues = {
		kill = 2,
		assist = 1,
		death = 0,
		flagCapture = 5,
		flagReturn = 1,
		win = 10,
		loss = 0,
		tie = 3,
	},
}

function Scoring:init()
	self.scores = {}

	for i, player in ipairs(players.getNonBots()) do
		self.scores[player.phoneNumber] = {
			name = player.account.name,
			team = player.data.team,
			kills = 0,
			deaths = 0,
			assists = 0,
			captures = 0,
			returns = 0,
			score = 0,
		}
	end
end

---@param player Player
function Scoring:getOrCreate(player)
	if not self.scores[player.phoneNumber] then
		self.scores[player.phoneNumber] = {
			name = player.name,
			team = player.data.team,
			kills = 0,
			deaths = 0,
			assists = 0,
			captures = 0,
			returns = 0,
			score = 0,
		}
	end

	return self.scores[player.phoneNumber]
end

---@param phoneNumber integer?
function Scoring:updateScore(phoneNumber)
	if phoneNumber then
		local playerScore = self.scores[phoneNumber]

		playerScore.score = Scoring.calculateScorePerRound(
			playerScore.kills,
			playerScore.deaths,
			playerScore.assists,
			playerScore.captures,
			playerScore.returns
		)

		-- print(playerScore.name .. " has " .. playerScore.score .. " points")
	else
		for index, score in pairs(self.scores) do
			Scoring:updateScore(index)
		end
	end
end

---@param kills integer
---@param deaths integer
---@param assists integer
---@param captures integer
---@param returns integer
---@return integer
function Scoring.calculateScorePerRound(kills, deaths, assists, captures, returns)
	return kills * Scoring.PointValues.kill
		+ assists * Scoring.PointValues.assist
		+ deaths * Scoring.PointValues.death
		+ captures * Scoring.PointValues.flagCapture
		+ returns * Scoring.PointValues.flagReturn
end

---@param kills integer
---@param assists integer
---@param deaths integer
---@param captures integer
---@param returns integer
---@param wins integer
---@param losses integer
---@param ties integer
---@return integer
function Scoring.calculateScore(kills, deaths, assists, captures, returns, wins, losses, ties)
	return kills * Scoring.PointValues.kill
		+ assists * Scoring.PointValues.assist
		+ deaths * Scoring.PointValues.death
		+ captures * Scoring.PointValues.flagCapture
		+ returns * Scoring.PointValues.flagReturn
		+ wins * Scoring.PointValues.win
		+ losses * Scoring.PointValues.loss
		+ ties * Scoring.PointValues.tie
end

---@param score integer
---@return integer
function Scoring.getRank(score)
	return math.floor(score / 75) + 1
end

---@param rank integer
---@return integer
function Scoring.getScoreNeededForRank(rank)
	return (rank - 1) * 75
end

function Scoring.capture(player)
	local score = Scoring:getOrCreate(player)
	score.captures = score.captures + 1
	Scoring:updateScore(player.phoneNumber)
end

function Scoring.returnFlag(player)
	local score = Scoring:getOrCreate(player)
	score.returns = score.returns + 1
	Scoring:updateScore(player.phoneNumber)
end

---@param attacker Player
---@param victim Player
---@param type 'weapon' | 'vehicle' | 'grenade'
---@param assists Player[]
hook.add("PlayerKill", "Scoring", function(attacker, victim, type, assists)
	if not attacker or not victim then
		return
	end

	local attackerScore = Scoring:getOrCreate(attacker)
	local victimScore = Scoring:getOrCreate(victim)

	attackerScore.kills = attackerScore.kills + 1
	victimScore.deaths = victimScore.deaths + 1

	if assists then
		for i, player in ipairs(assists) do
			if player.index == attacker.index then
				goto continue
			end

			local assistScore = Scoring:getOrCreate(player)
			assistScore.assists = assistScore.assists + 1

			Scoring:updateScore(player.phoneNumber)
			::continue::
		end
	end

	Scoring:updateScore(attacker.phoneNumber)
	Scoring:updateScore(victim.phoneNumber)
end)

return Scoring
