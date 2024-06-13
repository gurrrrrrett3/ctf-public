LOADOUT_POINT_VALUES = {
	["subrosa.m_16"] = 6,
	["subrosa.m_16_magazine"] = 1,
	["subrosa.ak_47"] = 5,
	["subrosa.ak_47_magazine"] = 1,
	["subrosa.mp5"] = 4,
	["subrosa.mp5_magazine"] = 1,
	["subrosa.uzi"] = 3,
	["subrosa.uzi_magazine"] = 1,
	["subrosa.9mm"] = 2,
	["subrosa.9mm_magazine"] = 1,
	-- ["subrosa.bandage"] = 1,
	["subrosa.grenade"] = 3,
	["jpxs.weapon.burst_smg"] = 5,
	["jpxs.ammo.smg"] = 1,
	["jpxs.weapon.sniper"] = 6,
	["jpxs.ammo.sniper"] = 1,
}

---@class PointValues
local PointValues = {}

PointValues.totalCost = 15

---@param item string
---@return integer
function PointValues.get(item)
	return LOADOUT_POINT_VALUES[item] or 0
end

---@param loadoutItems {[integer]: string}
---@return integer
function PointValues.getLoadoutPoints(loadoutItems)
	local points = 0

	for _, item in pairs(loadoutItems) do
		points = points + PointValues.get(item)
	end

	return points
end

return PointValues
