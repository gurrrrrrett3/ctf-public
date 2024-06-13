---@diagnostic disable: lowercase-global
---@class main.DataTyper
data = {}

-- Formatted with class, type as strings
local dataFormat = "_typed_%s_%s"

---@generic T
---@param object Player|Human|Item|Vehicle|RigidBody|Account Object to access data from.
---@param dataType `T` Type of data to access in object.
---@return T data Returned data.
function data.get(object, dataType)
	local index = string.format(dataFormat, object.class, dataType)
	if not object.data[index] then
		object.data[index] = {}
	end

	return object.data[index]
end

---@generic T
---@param object Player|Human|Item|Vehicle|RigidBody|Account Object to set data for.
---@param dataType `T` Type of data to access in object.
---@param toSet table Data to set in object.
function data.set(object, dataType, toSet)
	local index = string.format(dataFormat, object.class, dataType)
	object.data[index] = toSet
end

---@generic T
---@param object Player|Human|Item|Vehicle|RigidBody|Account
---@param dataType `T` Type of data to access in object.
---@param key any Key to set in object data.
---@param value any Value to set in object data.
function data.setValue(object, dataType, key, value)
	local index = string.format(dataFormat, object.class, dataType)
	if not object.data[index] then
		object.data[index] = {}
	end

	object.data[index][key] = value
end
