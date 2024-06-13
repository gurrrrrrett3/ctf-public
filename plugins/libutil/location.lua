---@class LibLocation
local location = {
	streetNames = {
		First = 1,
		Second = 2,
		Third = 3,
		Fourth = 4,
		Fifth = 5,
		Sixth = 6,
		Seventh = 7,
		Eighth = 8,
		Ninth = 9,
	},
}

---@param pos Vector
---@return Street?
function location.getStreetUnderPosition(pos)
	for _, street in ipairs(streets.getAll()) do
		if isVectorInCuboid(pos, street.trafficCuboidA, street.trafficCuboidB) then
			return street
		end
	end
end

---@param pos Vector
---@return StreetIntersection?
---@return number?
function location.getClosestIntersection(pos)
	local lowestSquareDistance
	local closestIntersection

	for _, intersection in ipairs(intersections.getAll()) do
		local squareDistance = intersection.pos:distSquare(pos)
		if not lowestSquareDistance or squareDistance < lowestSquareDistance then
			lowestSquareDistance = squareDistance
			closestIntersection = intersection
		end
	end

	return closestIntersection, lowestSquareDistance
end

---@param intersection StreetIntersection
---@return string
function location.getIntersectionHorizontalName(intersection)
	local street = intersection.streetEast or intersection.streetWest
	return street and street.name or "n/a"
end

---@param intersection StreetIntersection
---@return string
function location.getIntersectionVerticalName(intersection)
	local street = intersection.streetNorth or intersection.streetSouth
	return street and street.name or "n/a"
end

---@param intersection StreetIntersection
function location.intersectionToString(intersection)
	return location.getIntersectionHorizontalName(intersection)
		.. " and "
		.. location.getIntersectionVerticalName(intersection)
end

---@param street Street
function location.isStreetVertical(street)
	local intersection = street.intersectionA
	if intersection.streetSouth == street or intersection.streetNorth == street then
		return true
	end
	return false
end

---@param street Street
function location.handleOnStreet(street)
	local betweenA, betweenB
	if location.isStreetVertical(street) then
		betweenA = location.getIntersectionHorizontalName(street.intersectionA)
		betweenB = location.getIntersectionHorizontalName(street.intersectionB)
	else
		betweenA = location.getIntersectionVerticalName(street.intersectionA)
		betweenB = location.getIntersectionVerticalName(street.intersectionB)
	end

	return string.format("%s between %s and %s", street.name or "n/a", betweenA, betweenB)
end

---@param intersection StreetIntersection
---@param distance number
function location.handleNearIntersection(intersection, distance)
	return string.format("%.2fm away from %s", distance, location.intersectionToString(intersection))
end

---@param pos Vector
function location.getContext(pos)
	local context = "Unknown Location"

	local onStreet = location.getStreetUnderPosition(pos)

	if onStreet then
		context = location.handleOnStreet(onStreet)
	else
		local closestIntersection, distance = location.getClosestIntersection(pos)
		if closestIntersection then
			assert(closestIntersection, "No intersections to refer to")
			assert(distance, "Distance is nil")

			context = location.handleNearIntersection(closestIntersection, math.sqrt(distance))
		end
	end

	return context
end

---@param pos Vector
function location.getContextShort(pos)
	local context = "??"

	local closestIntersection, distance = location.getClosestIntersection(pos)
	if closestIntersection then
		assert(closestIntersection, "No intersections to refer to")
		assert(distance, "Distance is nil")

		local street = closestIntersection.streetEast or closestIntersection.streetWest

		local street = street and location.streetNames[street.name:gsub(" Street", "")] or "?"
		local ave = closestIntersection.streetNorth or closestIntersection.streetSouth
		if street and ave then
			context = tostring(street) .. ave.name:sub(1, 1)
		end
	end

	return context
end

return location
