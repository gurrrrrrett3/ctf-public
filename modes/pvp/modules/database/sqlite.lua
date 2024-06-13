local DatabasePlayer = require("modes.pvp.modules.database.databasePlayer")
local QB = require("main.queryBuilder")
local persistantStorage = require("plugins.persistantStorage.persistantStorage")
local Support = require("modes.pvp.modules.game.support")

---@class Database
local Database = {
	---@type SQLite
	db = nil,
}

---@param query string | SqliteQueryBuilder
function Database.query(query)
	if type(query) == "table" then
		query = query:build()
		-- print("Database: " .. query)
		local res = Database.db:query(query)

		if not res then
			error("Database query failed: " .. query)
		end
		return res
	else
		assert(type(query) == "string", "expected string, got " .. type(query))
		-- print("Database: " .. query)
		local res = Database.db:query(query)
		if not res then
			error("Database query failed: " .. query)
		end
		return res
	end
end

function Database.open()
	local dbPath = "./pvp.db"

	if not io.open(dbPath, "r") then
		local f = io.open(dbPath, "w")

		assert(f, "Failed to create database file")

		f:close()
	end

	local db = SQLite.new(dbPath)
	Database.db = db

	Database.query(QB.create():createTable("players", {
		{
			name = "id",
			type = "INTEGER",
			primaryKey = true,
		},
		{
			name = "name",
			type = "TEXT",
		},
		{
			name = "gamesPlayed",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "gamesWon",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "gamesLost",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "gamesTied",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "kills",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "assists",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "deaths",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "captures",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "returns",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "score",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "scorePenalty",
			type = "INTEGER",
			default = 0,
		},
		{
			name = "rank",
			type = "INTEGER",
			default = 1,
		},
		{
			name = "supportLevel",
			type = "INTEGER",
			default = 0,
		},
	}))

	Database.query(QB.create():createTable("matches", {
		{
			name = "id",
			type = "INTEGER",
			primaryKey = true,
			autoIncrement = true,
		},
		{
			name = "redScore",
			type = "INTEGER",
		},
		{
			name = "blueScore",
			type = "INTEGER",
		},
		{
			name = "winner",
			type = "INTEGER",
		},
		{
			name = "tie",
			type = "INTEGER",
			default = 0,
		},
	}))

	Database.query(QB.create():createTable("loadouts", {
		{
			name = "id",
			type = "INTEGER",
			primaryKey = true,
			autoIncrement = true,
		},
		{
			name = "playerId",
			type = "INTEGER",
		},
		{
			name = "name",
			type = "TEXT",
		},
	}))

	Database.query(QB.create():createTable("loadoutItems", {
		{
			name = "id",
			type = "INTEGER",
			primaryKey = true,
			autoIncrement = true,
		},
		{
			name = "loadoutId",
			type = "INTEGER",
		},
		{
			name = "itemType",
			type = "TEXT",
		},
		{
			name = "slotId",
			type = "INTEGER",
		},
	}))

	Database.query("PRAGMA journal_mode=WAL;")

	persistantStorage.init(Database.db)
end

function Database.close()
	Database.db:close()
end

---@param id integer Player phone number
---@param name? string Player name
---@return DatabasePlayer
function Database.getPlayer(id, name)
	local result = Database.query(QB.create():select():from("players"):where({
		{ column = "id", operator = "=", value = id },
	}))

	local player = result[1]

	if not player then
		print("Creating new player: " .. name)
		player = {
			id = id,
			name = name,
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
		}

		Database.query(QB.create():insert("players", player))
	end

	local dbPlayer = DatabasePlayer.load(
		player[1] or id,
		player[2] or name or "err_name",
		player[3],
		player[4],
		player[5],
		player[6],
		player[7],
		player[8],
		player[9],
		player[10],
		player[11],
		player[12],
		player[13],
		player[14]
	)

	return dbPlayer
end

---@param dbPlayer DatabasePlayer
function Database.updatePlayer(dbPlayer)
	print("Updating player: " .. dbPlayer.name)

	Database.query(QB.create():update("players", dbPlayer):where({
		{ column = "id", operator = "=", value = dbPlayer.id },
	}))
end

---@param limit integer?
---@return DatabasePlayer[]
function Database.getTop(sortBy, limit)
	local result, err =
		Database.query(QB.create():select():from("players"):orderBy(sortBy or "score", "DESC"):limit(limit or 10))

	if err then
		error(err)
	end

	assert(type(result) == "table", "expected table, got " .. type(result))

	local players = {}

	for _, player in pairs(result) do
		local dbPlayer = DatabasePlayer.load(
			player[1],
			player[2],
			player[3],
			player[4],
			player[5],
			player[6],
			player[7],
			player[8],
			player[9],
			player[10],
			player[11],
			player[12],
			player[13],
			player[14]
		)

		table.insert(players, dbPlayer)
	end

	return players
end

hook.add("AccountTicketFound", "Database", function(account)
	if not account then
		return
	end

	Support.getSupportLevel(account.phoneNumber, function(supportLevel)
		account.data.jpxsSupportLevel = supportLevel
		Database.query(QB.create():update("players", { supportLevel = supportLevel }):where({
			{ column = "id", operator = "=", value = account.phoneNumber },
		}))
	end)
end)

---@param player Player
hook.add("PlayerInit", "Database", function(player)
	print("Player init: " .. player.name)

	local dbPlayer = Database.getPlayer(player.phoneNumber, player.account and player.account.name or player.name)
	player.data.db = dbPlayer

	if not player.account or not player.account.data.jpxsSupportLevel then
		Support.getSupportLevel(player.phoneNumber, function(supportLevel)
			player.account.data.jpxsSupportLevel = supportLevel
			player.data.db.supportLevel = supportLevel

			Database.updatePlayer(player.data.db)

			print("Setting support level for " .. player.name .. " to " .. supportLevel)

			local nameToSet = string.format(
				"%s[%d] %s",
				Support.getSupportSymbol(supportLevel),
				dbPlayer.rank,
				player.account and player.account.name or player.name
			)
			player.name = nameToSet
			player:update()
		end)
	else
		local nameToSet = string.format(
			"%s[%d] %s",
			Support.getSupportSymbol(player.data.db.supportLevel),
			dbPlayer.rank or 1,
			player.account and player.account.name or player.name
		)
		player.name = nameToSet
		player:update()
	end
end)

hook.add("PostResetGame", "Database", function()
	for _, player in pairs(players.getNonBots()) do
		if not player.account then
			print("Player has no account")
			goto continue
		end
		local dbPlayer = Database.getPlayer(player.phoneNumber, player.account.name)
		player.data.db = dbPlayer

		local nameToSet = string.format(
			"%s[%d] %s",
			Support.getSupportSymbol(player.account.data.jpxsSupportLevel),
			dbPlayer.rank or 1,
			player.account and player.account.name or player.name
		)

		player.name = nameToSet
		player:update()

		::continue::
	end
end)

return Database
