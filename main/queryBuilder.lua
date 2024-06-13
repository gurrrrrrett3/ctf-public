-- really shitty query builder for sqlite that I wrote in an hour
-- it's not perfect but it works for what I need it to do

-- gart 2024

---@class SqliteQueryBuilder
---@field private _columns table
---@field private _table string
---@field private _conditions SQLCondition
---@field private _limit integer
---@field private _orderBy string
---@field private _direction string
---@field private _query string
local SqliteQueryBuilder = {}

---@class SQLCondition
---@field column string
---@field operator string
---@field value string | number

---@class SQLColumn
---@field name string
---@field type string
---@field default (string | number)?
---@field primaryKey boolean?
---@field autoIncrement boolean?
---@field notNull boolean?

SqliteQueryBuilder.__index = SqliteQueryBuilder

---@return SqliteQueryBuilder
function SqliteQueryBuilder.create()
	local self = setmetatable({}, SqliteQueryBuilder)
	return self
end

---@param self SqliteQueryBuilder
---@param columns string[]?
---@return SqliteQueryBuilder
SqliteQueryBuilder.select = function(self, columns)
	self._columns = columns or { "*" }
	return self
end

---@param self SqliteQueryBuilder
---@param table string
---@return SqliteQueryBuilder
SqliteQueryBuilder.from = function(self, table)
	self._table = table
	return self
end

---@param self SqliteQueryBuilder
---@param conditions SQLCondition[] | string
---@return SqliteQueryBuilder
SqliteQueryBuilder.where = function(self, conditions)
	if type(conditions) == "table" then
		local conditionStr = ""

		if #conditions == 0 then
			conditions = { conditions }
		end

		for i, condition in pairs(conditions) do
			conditionStr = conditionStr
				.. condition.column
				.. " "
				.. condition.operator
				.. " "
				.. (
					type(condition.value) == "string" and "'" .. condition.value:gsub("'", "''") .. "'"
					or condition.value
				)

			if i < #conditions then
				conditionStr = conditionStr .. " AND "
			end
		end

		self._conditions = conditionStr
	else
		assert(type(conditions) == "string", "expected string or table, got " .. type(conditions))
		---@diagnostic disable-next-line: assign-type-mismatch
		self._conditions = conditions
	end

	return self
end

---@param self SqliteQueryBuilder
---@param limit integer
---@return SqliteQueryBuilder
SqliteQueryBuilder.limit = function(self, limit)
	self._limit = limit
	return self
end

---@param self SqliteQueryBuilder
---@param orderBy string
---@param direction "ASC" | "DESC"
---@return SqliteQueryBuilder
SqliteQueryBuilder.orderBy = function(self, orderBy, direction)
	self._orderBy = orderBy
	self._direction = direction
	return self
end

---@param self SqliteQueryBuilder
---@return string
SqliteQueryBuilder.build = function(self)
	if self._query then -- insert
		if self._conditions then
			self._query = self._query .. " WHERE " .. self._conditions
		end

		return self._query
	else
		local query = "SELECT " .. table.concat(self._columns, ", ") .. " FROM " .. self._table

		if self._conditions then
			query = query .. " WHERE " .. self._conditions
		end

		if self._orderBy then
			query = query .. " ORDER BY " .. self._orderBy .. " " .. self._direction
		end

		if self._limit then
			query = query .. " LIMIT " .. self._limit
		end

		return query
	end
end

---@param self SqliteQueryBuilder
---@param table string
---@param columns SQLColumn[]
---@return string
SqliteQueryBuilder.createTable = function(self, table, columns)
	local query = "CREATE TABLE IF NOT EXISTS " .. table .. " ("

	for i, column in ipairs(columns) do
		query = query .. column.name .. " " .. column.type

		if column.primaryKey then
			query = query .. " PRIMARY KEY"
		end

		if column.autoIncrement then
			query = query .. " AUTOINCREMENT"
		end

		if column.notNull then
			query = query .. " NOT NULL"
		end

		if column.default then
			query = query .. " DEFAULT " .. tostring(column.default)
		end

		if i < #columns then
			query = query .. ", "
		end
	end

	query = query .. ")"

	return query
end

---@param self SqliteQueryBuilder
---@param tableName string
---@param columns string[]
---@return string
SqliteQueryBuilder.createIndex = function(self, tableName, columns)
	local query = "CREATE INDEX IF NOT EXISTS "
		.. tableName
		.. " ON "
		.. tableName
		.. " ("
		.. table.concat(columns, ", ")
		.. ")"

	return query
end

---@param self SqliteQueryBuilder
---@param tableName string
---@param values {[string]: string | number}
---@return string
SqliteQueryBuilder.insert = function(self, tableName, values)
	local columns = {}
	local valueStr = {}

	for key, value in pairs(values) do
		table.insert(columns, key)
		local val = type(value) == "string" and "'" .. value:gsub("'", "''") .. "'" or value
		table.insert(valueStr, val)
	end

	return "INSERT INTO "
		.. tableName
		.. " ("
		.. table.concat(columns, ", ")
		.. ") VALUES ("
		.. table.concat(valueStr, ", ")
		.. ")"
end

---@param self SqliteQueryBuilder
---@param tableName string
---@param values {[string]: string | number}
---@return SqliteQueryBuilder
SqliteQueryBuilder.update = function(self, tableName, values)
	local query = "UPDATE OR REPLACE " .. tableName .. " SET "

	local valueStr = {}

	for key, value in pairs(values) do
		local val = type(value) == "string" and "'" .. value .. "'" or value
		table.insert(valueStr, key .. " = " .. val)
	end

	query = query .. table.concat(valueStr, ", ")

	self._query = query

	return self
end

---@param self SqliteQueryBuilder
---@param tableName string
SqliteQueryBuilder.delete = function(self, tableName)
	self._query = "DELETE FROM " .. tableName
	return self
end

return SqliteQueryBuilder
