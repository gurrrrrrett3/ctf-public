---@class RotMatrixUtil
local RotMatrixUtil = {}

---gets pitch, yaw, and roll from a rotation matrix
---@param rotMatrix RotMatrix
---@return number, number, number
function RotMatrixUtil.rotMatrixToPYR(rotMatrix)
	local pitch = math.asin(-rotMatrix.x1)
	local yaw = math.atan2(rotMatrix.x2, rotMatrix.x3)
	local roll = math.atan2(rotMatrix.y1, rotMatrix.z1)
	return pitch, yaw, roll
end

return RotMatrixUtil
