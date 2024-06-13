---@class MapSpawnConditions
local MapSpawnConditions = {}

---@TODO this seems to be broken
---@param minTeamSize integer
---@return fun(game: Game, team: Team): boolean
function MapSpawnConditions.teamSizeGreaterThan(minTeamSize)
	return function(game, team)
		return team:getPlayerCount() >= minTeamSize
	end
end

return MapSpawnConditions
