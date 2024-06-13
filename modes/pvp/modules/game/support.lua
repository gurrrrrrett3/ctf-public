local json = require("main.json")

---@class Support
local Support = {}

Support.symbols = {
	[0] = "",
	[1] = string.char(0x0c),
	[2] = string.char(0x0c),
	[3] = string.char(0x0c),
	[4] = string.char(0x0c),
	[5] = string.char(0x0c),
	-- [1] = "1",
	-- [2] = "2",
	-- [3] = "3",
	-- [4] = "4",
	-- [5] = "5",
}

---@param level integer
function Support.getSupportSymbol(level)
	return Support.symbols[level] or Support.symbols[0]
end

---@param level integer
---@return string
function Support.getSupportText(level)
	return tostring(PVP_lang["support_lv_" .. level] or PVP_lang["support_lv_0"])
end

---@param id integer
---@param cb fun(supportLevel: integer)
function Support.getSupportLevel(id, cb)
	local player = players.getByPhone(id)
	if player and player.data.jpxsSupportLevel then
		cb(player.data.jpxsSupportLevel)
		return
	end

	http.get("https://jpxs.io", "/api/player/" .. id, {}, function(response)
		if response and response.status == 200 then
			local data = json.decode(response.body)

			if not data then
				print("Failed to decode JSON")
				return
			end

			local supportLevel = data.players[1].jpxsSupportLevel
			if player then
				player.data.jpxsSupportLevel = supportLevel
			end

			cb(supportLevel)
		end
	end)
end

return Support
