---@diagnostic disable: lowercase-global

---@class main.input.KeyBind
---@field name string Unique name of bind.
---@field callback function Func to call on bind trigger.
---@field toggle boolean Whether the bind is a toggle (only fired once on press/release) or not (fired every tick while holding)
---@field priority integer Lower priority binds are executed sooner.
---@field key integer Actual keycode input flag.

---@class main.input.InputLib
---@field private _keyBinds { [string]: main.input.KeyBind }
---@field private _sortedBinds { [integer]: string[] }
input = {
	_keyBinds = {},
	_sortedBinds = {},
}

---Sorts the keybind table.
---@param key integer Keycode input flag.
---@private
function input:_sortBindsForKey(key)
	table.sort(self._sortedBinds[key], function(a, b)
		local sortBind = input._keyBinds[a]
		local sortOtherBind = input._keyBinds[b]
		assert(sortBind and sortOtherBind, "keybinds in sort table non-existent")

		return sortBind.priority < sortOtherBind.priority
	end)
end

---Sorts a new keybind into the sorted binds dict.
---@param name string Unique name of the bind.
---@private
function input:_sortNewBind(name)
	local bindData = self._keyBinds[name]
	assert(bindData, "newly inserted keybind not inserted")

	if not self._sortedBinds[bindData.key] then
		self._sortedBinds[bindData.key] = {}
	end

	table.insert(self._sortedBinds[bindData.key], name)
	self:_sortBindsForKey(bindData.key)
end

---Removes a keybind from the sorted table.
---@param name string Unique name of the bind.
---@private
function input:_sortRemoveBind(name)
	local bindData = self._keyBinds[name]
	assert(bindData, "attempted to remove nonexistent bind from sorter")

	for k, v in pairs(self._sortedBinds[bindData.key]) do
		if v == name then
			table.remove(self._sortedBinds[bindData.key], k)
			break
		end
	end
end

---Adds a new keybind to be handled.
---@param name string Unique name of the bind.
---@param key integer Keycode input flag.
---@param callback fun(ply: Player, toggle: boolean?) Function to call when key is triggered. Toggle only present if bind is a toggle.
---@param priority integer? Lower priority keybinds are executed first before other keybinds on the same key.
---@param toggle boolean? Whether the bind should be a toggle or not.
function input:bind(name, key, callback, toggle, priority)
	assert(not self._keyBinds[name], "bind with the name " .. name .. " already exists!")
	if toggle == nil then
		toggle = true
	end

	---@type main.input.KeyBind
	local newBind = {
		name = name,
		callback = callback,
		toggle = toggle,
		priority = priority or 100,
		key = key,
	}
	self._keyBinds[name] = newBind
	self:_sortNewBind(name)
end

---Removes a keybind from the handler.
---@param name string Unique name of the bind.
function input:removeBind(name)
	if not self._keyBinds[name] then
		return
	end
	self:_sortRemoveBind(name)
	self._keyBinds[name] = nil
end

---@param key integer
---@param toggle boolean
---@param ply Player
local function triggerToggleBindsForKey(key, toggle, ply)
	for _, bind in pairs(input._sortedBinds[key]) do
		local bindData = input._keyBinds[bind]
		if bindData.toggle then
			bindData.callback(ply, toggle)
		end
	end
end

---@param key integer
---@param ply Player
local function triggerBindsForKey(key, ply)
	for _, bind in pairs(input._sortedBinds[key]) do
		local bindData = input._keyBinds[bind]
		if not bindData.toggle then
			bindData.callback(ply)
		end
	end
end

---@param ply Player
local function handleInputForPlayer(ply)
	for key, binds in pairs(input._sortedBinds) do
		if #binds <= 0 then
			goto continue
		end

		local currentPressing = bit.band(ply.inputFlags, key)
		local lastPressing = bit.band(ply.lastInputFlags, key)
		if currentPressing == key then
			triggerBindsForKey(key, ply)
			if lastPressing ~= key then
				-- We are currently pressing the key, but weren't last tick.
				triggerToggleBindsForKey(key, true, ply)
			end
		end
		if lastPressing == key and currentPressing ~= key then
			-- We were pressing the key last tick, but aren't now.
			triggerToggleBindsForKey(key, false, ply)
		end

		::continue::
	end
end

hook.add("PostServerReceive", "main.input", function()
	for _, ply in pairs(players.getNonBots()) do
		handleInputForPlayer(ply)
	end
end)
