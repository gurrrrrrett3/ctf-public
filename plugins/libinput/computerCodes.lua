---@class ComputerKeyCodes
local ComputerKeyCodes = {
	["Backspace"] = 8,
	["Enter"] = 10,
	["ArrowUp"] = 16,
	["ArrowDown"] = 17,
	["ArrowLeft"] = 18,
	["ArrowRight"] = 19,
	["Space"] = 32,
	["!"] = 33,
	['"'] = 34,
	["#"] = 35,
	["$"] = 36,
	["%"] = 37,
	["&"] = 38,
	["'"] = 39,
	["("] = 40,
	[")"] = 41,
	["*"] = 42,
	["+"] = 43,
	[","] = 44,
	["-"] = 45,
	["."] = 46,
	["/"] = 47,
	["0"] = 48,
	["1"] = 49,
	["2"] = 50,
	["3"] = 51,
	["4"] = 52,
	["5"] = 53,
	["6"] = 54,
	["7"] = 55,
	["8"] = 56,
	["9"] = 57,
	[":"] = 58,
	[";"] = 59,
	["<"] = 60,
	["="] = 61,
	[">"] = 62,
	["?"] = 63,
	["@"] = 64,
	["a"] = 65,
	["b"] = 66,
	["c"] = 67,
	["d"] = 68,
	["e"] = 69,
	["f"] = 70,
	["g"] = 71,
	["h"] = 72,
	["i"] = 73,
	["j"] = 74,
	["k"] = 75,
	["l"] = 76,
	["m"] = 77,
	["n"] = 78,
	["o"] = 79,
	["p"] = 80,
	["q"] = 81,
	["r"] = 82,
	["s"] = 83,
	["t"] = 84,
	["u"] = 85,
	["v"] = 86,
	["w"] = 87,
	["x"] = 88,
	["y"] = 89,
	["z"] = 90,
	["["] = 91,
	["\\"] = 92,
	["]"] = 93,
	["^"] = 94,
	["_"] = 95,
	["`"] = 96,
}

local function createReverseTable()
	local reverse = {}
	for key, value in pairs(ComputerKeyCodes) do
		reverse[value] = key
	end
	return reverse
end

---@type table<number, string>
local reverseTable = createReverseTable()

---@param key string
function ComputerKeyCodes.getCode(key)
	return ComputerKeyCodes[key]
end

---@param code number
---@param shift boolean
function ComputerKeyCodes.getKey(code, shift)
	local key = reverseTable[code]
	if shift then
		if key:match("%a") then
			return key:upper()
		end
		return key
	end
	return key
end

return ComputerKeyCodes
