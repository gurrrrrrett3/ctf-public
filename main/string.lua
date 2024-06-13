---@class StringUtil
local stringUtil = {}

---Left pad a string with a character to a certain length
---@param str string
---@param length number
---@param char string
---@return string
function stringUtil.leftPad(str, length, char)
	return string.rep(char, length - #str) .. str
end

---Right pad a string with a character to a certain length
---@param str string
---@param length number
---@param char string
---@return string
function stringUtil.rightPad(str, length, char)
	return str .. string.rep(char, length - #str)
end

---Split a string by a delimiter
---@param str string
---@param delimiter string
---@return string[]
function stringUtil.split(str, delimiter)
	local result = {}
	for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

---join a table of strings with a delimiter
---@param tbl string[]
---@param delimiter string
---@return string
function stringUtil.join(tbl, delimiter)
	return table.concat(tbl, delimiter)
end

---Wrap text to a certain width, optionally wrapping at a delimiter
---@param text string
---@param width number
---@param wrap boolean
---@param wrapAtDelim string
---@return string[]
function stringUtil.wrapText(text, width, wrap, wrapAtDelim)
	if not wrap then
		return { text }
	end

	local lines = {}
	local line = ""
	for word in text:gmatch("%S+") do
		if #line + #word > width then
			table.insert(lines, line)
			line = ""
		end
		line = line .. word .. " "
	end
	table.insert(lines, line)

	if wrapAtDelim then
		for i = 1, #lines do
			local line = lines[i]
			local newLines = stringUtil.split(line, wrapAtDelim)
			lines[i] = newLines[1]
			for j = 2, #newLines do
				table.insert(lines, i + j - 1, newLines[j])
			end
		end
	end

	return lines
end

function stringUtil.endsWith(str, ending)
	return ending == "" or string.sub(str, -string.len(ending)) == ending
end

return stringUtil
