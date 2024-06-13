local ItemUtil = require("plugins.libutil.item")
local LibPacket = require("plugins.libpacket.libpacket")
local Team = require("modes.pvp.modules.game.team")

---@class Disk
---@field class "Disk"
---@field _baseItem Item
---@field teamIndex integer
---@field isStatic boolean
---@field Disk Disk
---@field isBeingHeld boolean
---@field resetTimer integer
---@field spawnPos Vector
---@field lastHeldBy integer
---@field isAtPedestal boolean
---@field hasExploded boolean
local Disk = {}

Disk.__index = Disk

---@param teamIndex integer
---@param pos Vector
function Disk.create(teamIndex, pos)
	local itemId = Disk.getDiskIdByIndex(teamIndex)

	local item = ItemUtil.createStaticItem(itemId, pos, orientations.n)

	assert(item, string.format("Disk item is nil for team %d", teamIndex))

	local self = setmetatable({
		_baseItem = item,
		teamIndex = teamIndex,
		isStatic = true,
		resetTimer = 0,
		spawnPos = pos:clone(),
		isAtPedestal = true,
		hasExploded = false,
	}, Disk)

	item.data.Disk = self

	return self
end

---@param index integer
function Disk.getDiskIdByIndex(index)
	local diskIds = {
		[1] = enum.item.disk_red,
		[2] = enum.item.disk_blue,
		[3] = enum.item.disk_green,
		[4] = enum.item.disk_gold,
	}

	assert(diskIds[index], "Invalid disk index")

	return diskIds[index]
end

function Disk:reset(sendMessage)
	self._baseItem.pos = self.spawnPos:clone()
	self._baseItem.rigidBody.pos = self.spawnPos:clone()
	self.isStatic = true
	self.isBeingHeld = false
	self.isAtPedestal = true
	self.hasExploded = false
	self.resetTimer = 0
	self._baseItem.hasPhysics = false
	self._baseItem.isStatic = true

	if (sendMessage == true or sendMessage == nil) then
		events.createMessage(
			3,
			string.format("The %s team's disk has been reset!", Team.getTeamNameByIndex(self.teamIndex)),
			-1,
			2
		)
	end
end

return Disk
