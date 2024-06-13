---@type Plugin
local plugin = ...
plugin.name = "libinput"
plugin.author = "gart"

local codes = require("plugins.libinput.computerCodes")

---@param player Player
plugin:addHook("PlayerLogic", function(player)
	local inputFlags = player.inputFlags
	player.data.input = player.data.input or {}
	local lastInputFlags = player.data.input.lastInputFlags or 0

	if inputFlags ~= lastInputFlags then
		local tempFlags = lastInputFlags
		local override = false

		for keyName, key in pairs(enum.input) do
			local flag = bit32.band(inputFlags, key)

			if flag ~= bit32.band(tempFlags, key) then
				if flag == key then
					player.data.input[keyName] = true
					override = hook.run(string.format("PlayerInputPress[%s]", keyName), player) == hook.override
						or override
				else
					player.data.input[keyName] = false
					override = hook.run(string.format("PlayerInputRelease[%s]", keyName), player) == hook.override
						or override
				end
			end
		end

		player.data.input.lastInputFlags = inputFlags
		return override and hook.override or hook.continue
	end
end)

plugin:addHook("ItemComputerInput", function(computer, character)
	if not computer.parentHuman or not computer.parentHuman.player then
		return hook.override
	end

	local player = computer.parentHuman.player
	assert(player, "Computer has no parent player (should not happen)")

	player.data.input = player.data.input or {}
	player.data.computerInput = player.data.computerInput or {}

	local key = codes.getKey(character, player.data.input.shift or false)

	if key then
		hook.run("PlayerComputerInputPress", player, computer, key)
		hook.run(string.format("PlayerComputerInputPress[%s]", key), player, computer)
	end

	return hook.override
end)
