---@class VectorUtil
local VectorUtil = {}

---@param a Vector
---@param b Vector
---@return Vector
function VectorUtil.mid(a, b)
	return Vector((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2)
end

---@param v Vector
---@return number
function VectorUtil.length2D(v)
	return math.sqrt(v.x * v.x + v.z * v.z)
end

---@param a Vector
---@param b Vector
---@return RotMatrix
function VectorUtil.lookAt(a, b)
	local dir = b - a
	local yaw = math.atan2(dir.x, dir.z)
	local pitch = math.atan2(dir.y, VectorUtil.length2D(dir))
	return eulerAnglesToRotMatrix(pitch, yaw, 0)
end

return VectorUtil
