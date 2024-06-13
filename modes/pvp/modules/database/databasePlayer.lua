---@class DatabasePlayer
---@field public id integer
---@field public name string
---@field public gamesPlayed integer
---@field public gamesWon integer
---@field public gamesLost integer
---@field public gamesTied integer
---@field public kills integer
---@field public assists integer
---@field public deaths integer
---@field public captures integer
---@field public returns integer
---@field public score integer
---@field public rank integer
---@field public supportLevel integer
DatabasePlayer = {}

DatabasePlayer.__index = DatabasePlayer

---@param player Player
function DatabasePlayer.create(player)
	local self = setmetatable({
		class = "DatabasePlayer",
		id = player.phoneNumber,
		name = player.name,
		gamesPlayed = 0,
		gamesWon = 0,
		gamesLost = 0,
		gamesTied = 0,
		kills = 0,
		assists = 0,
		deaths = 0,
		captures = 0,
		returns = 0,
		score = 0,
		rank = 1,
		supportLevel = 0,
	}, DatabasePlayer)
	return self
end

---@param id integer
---@param name string
---@param gamesPlayed integer
---@param gamesWon integer
---@param gamesLost integer
---@param gamesTied integer
---@param kills integer
---@param assists integer
---@param deaths integer
---@param captures integer
---@param returns integer
---@param score integer
---@param rank integer
---@param supportLevel integer
function DatabasePlayer.load(
	id,
	name,
	gamesPlayed,
	gamesWon,
	gamesLost,
	gamesTied,
	kills,
	assists,
	deaths,
	captures,
	returns,
	score,
	rank,
	supportLevel
)
	local self = setmetatable({
		id = id,
		name = name,
		gamesPlayed = gamesPlayed,
		gamesWon = gamesWon,
		gamesLost = gamesLost,
		gamesTied = gamesTied,
		kills = kills,
		assists = assists,
		deaths = deaths,
		captures = captures,
		returns = returns,
		score = score,
		rank = rank,
		supportLevel = supportLevel,
	}, DatabasePlayer)
	return self
end

return DatabasePlayer
