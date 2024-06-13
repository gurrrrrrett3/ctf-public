---@class Loader
local Loader = {}

---@param filePath string
function Loader:recursiveLoad(filePath)
	local res = {}

	local files = os.listDirectory(filePath)

	for i, v in pairs(files) do
		if v.isDirectory then
			res[v.name] = self:recursiveLoad(filePath .. "/" .. v.name)
		else
			local path = filePath .. "/" .. v.name
			local name = path:gsub(".lua", "")
			local module = require(name)
			res[v.name] = module
		end
	end

	return res
end

---@generic T : any
---@param filePath string
---@param class? `T`
---@return {[string]: T}
function Loader:flatRecursiveLoad(filePath, class)
	return self:_internalFlatRecursiveLoad(filePath, {}, "")
end

---@private
---@param filePath string
---@param table {[string]: any}
---@param prefix string
function Loader:_internalFlatRecursiveLoad(filePath, table, prefix)
	local files = os.listDirectory(filePath)

	for i, v in pairs(files) do
		if v.isDirectory then
			self:_internalFlatRecursiveLoad(filePath .. "/" .. v.name, table, prefix .. v.name .. ".")
		else
			local path = filePath .. "/" .. v.name
			local name = path:gsub(".lua", "")
			local module = require(name)
			table[prefix .. v.name:gsub(".lua", "")] = module
		end
	end

	return table
end

---@param filePath string
---@return {[string]: Image}
function Loader:flatRecursiveLoadImages(filePath, class)
	return self:_internalFlatRecursiveLoadImages(filePath, {}, "")
end

---@private
---@param filePath string
---@param table {[string]: Image}
---@param prefix string
function Loader:_internalFlatRecursiveLoadImages(filePath, table, prefix)
	local files = os.listDirectory(filePath)

	for i, v in pairs(files) do
		if v.isDirectory then
			self:_internalFlatRecursiveLoadImages(filePath .. "/" .. v.name, table, prefix .. v.name .. ".")
		else
			local path = filePath .. "/" .. v.name
			local name = v.name:gsub(".png", "")
			local image = Image.new()
			image:loadFromFile(path)
			table[prefix .. name] = image
		end
	end

	return table
end

return Loader
