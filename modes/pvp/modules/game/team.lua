---@class Team
---@field index integer
---@field players Player[]
---@field disk Disk
---@field score integer
local Team = {}

Team.__index = Team

---@param index integer
---@return Team
function Team.create(index)
	local self = setmetatable({
		index = index,
		disk = nil,
		players = {},
		score = 0,
	}, Team)

	return self
end

---@param disk Disk
function Team:setDisk(disk)
	self.disk = disk
end

function Team:getPlayerCount()
	local count = 0
	for _, player in pairs(self.players) do
		count = count + 1
	end

	return count
end

---@param index integer
function Team.getTeamNameByIndex(index)
	local teamNames = {
		[1] = PVP_lang.team_red,
		[2] = PVP_lang.team_blue,
		[3] = PVP_lang.team_green,
		[4] = PVP_lang.team_yellow,
	}

	assert(teamNames[index], "Invalid team index")

	return teamNames[index]
end

return Team
