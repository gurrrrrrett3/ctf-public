--- all hooks
--- @type table<string, table<string, function>>
local _hooks = {}

--- all temporary hooks, for hook.once
--- @type table<string, function[]>
local _tempHooks = {}

--- Cache of enabled hooks
--- @type table<string, function[]>
local _cache = {}

---@class FunctionData
---@field name string
---@field eventName string

--- keeps name of each function for debugging
--- @type table<function, FunctionData>
hook._functionData = {}

---@class HookRunInfo
---@field time number
---@field name string

--- @class HookInfo
---@field time number
---@field runs table<string, HookRunInfo>

---keeps track of last run info
--- @type table<string, table<HookInfo>>
hook._lastRunInfo = {}

local IS_DEBUG = true

local pairs = pairs
local ipairs = ipairs

local CONTINUE = 1
local OVERRIDE = 2

---Stops further hooks of this type from running.
hook.continue = CONTINUE
---Stops further hooks and overrides default game functionality.
hook.override = OVERRIDE

---The currently loaded plugins.
---@type table<string, Plugin>
hook.plugins = {}

---Regenerate the cache of enabled hooks.
function hook.resetCache()
	hook.clear()
	_cache = {}

	local enable = hook.enable

	for event, funcs in pairs(_hooks) do
		enable(event)
		_cache[event] = {}
		for _, func in pairs(funcs) do
			table.insert(_cache[event], func)
		end
	end

	local sortingHooks = {}

	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			for event, func in pairs(plugin.hooks) do
				if _cache[event] == nil then
					enable(event)
					_cache[event] = {}
				end
				table.insert(_cache[event], func)
			end

			for event, infos in pairs(plugin.polyHooks) do
				if sortingHooks[event] == nil then
					sortingHooks[event] = {}
				end

				for _, info in ipairs(infos) do
					table.insert(sortingHooks[event], info)

					if IS_DEBUG then
						hook._functionData[info.func] = {
							name = info.name,
							eventName = event,
						}

						-- print('Added hook', info.name, 'for event', event)
					end
				end
			end
		end
	end

	for event, infos in pairs(sortingHooks) do
		if _cache[event] == nil then
			enable(event)
			_cache[event] = {}
		end

		table.sort(infos, function(a, b)
			return a.priority < b.priority
		end)

		for _, info in ipairs(infos) do
			table.insert(_cache[event], info.func)
		end
	end
end

---@class HookGlobal
---For full hook documentation, see the docs at https://github.com/jpxs-intl/RosaServer/wiki/Hooks.
---@field add fun(eventName: "AccountDeathTax", name: string, func: hooks.AccountDeathTax)
---@field add fun(eventName: "AccountTicketBegin", name: string, func: hooks.AccountTicketBegin)
---@field add fun(eventName: "AccountTicketFound", name: string, func: hooks.AccountTicketFound)
---@field add fun(eventName: "AccountsSave", name: string, func: hooks.AccountsSave)
---@field add fun(eventName: "AreaCreateBlock", name: string, func: hooks.AreaCreateBlock)
---@field add fun(eventName: "AreaDeleteBlock", name: string, func: hooks.AreaDeleteBlock)
---@field add fun(eventName: "BulletCreate", name: string, func: hooks.BulletCreate)
---@field add fun(eventName: "BulletHitHuman", name: string, func: hooks.BulletHitHuman)
---@field add fun(eventName: "BulletMayHit", name: string, func: hooks.BulletMayHit)
---@field add fun(eventName: "BulletMayHitHuman", name: string, func: hooks.BulletMayHitHuman)
---@field add fun(eventName: "CalculateEarShots", name: string, func: hooks.CalculateEarShots)
---@field add fun(eventName: "CollideBodies", name: string, func: hooks.CollideBodies)
---@field add fun(eventName: "ConsoleAutoComplete", name: string, func: hooks.ConsoleAutoComplete)
---@field add fun(eventName: "ConsoleInput", name: string, func: hooks.ConsoleInput)
---@field add fun(eventName: "CreateTraffic", name: string, func: hooks.CreateTraffic)
---@field add fun(eventName: "EconomyCarMarket", name: string, func: hooks.EconomyCarMarket)
---@field add fun(eventName: "EventBullet", name: string, func: hooks.EventBullet)
---@field add fun(eventName: "EventBulletHit", name: string, func: hooks.EventBulletHit)
---@field add fun(eventName: "EventUpdateElimState", name: string, func: hooks.EventUpdateElimState)
---@field add fun(eventName: "EventMessage", name: string, func: hooks.EventMessage)
---@field add fun(eventName: "EventSound", name: string, func: hooks.EventSound)
---@field add fun(eventName: "EventUpdateItemInfo", name: string, func: hooks.EventUpdateItemInfo)
---@field add fun(eventName: "EventUpdatePlayerFinance", name: string, func: hooks.EventUpdatePlayerFinance)
---@field add fun(eventName: "EventUpdatePlayer", name: string, func: hooks.EventUpdatePlayer)
---@field add fun(eventName: "EventUpdateVehicle", name: string, func: hooks.EventUpdateVehicle)
---@field add fun(eventName: "GrenadeExplode", name: string, func: hooks.GrenadeExplode)
---@field add fun(eventName: "HumanCollisionVehicle", name: string, func: hooks.HumanCollisionVehicle)
---@field add fun(eventName: "HumanCreate", name: string, func: hooks.HumanCreate)
---@field add fun(eventName: "HumanDamage", name: string, func: hooks.HumanDamage)
---@field add fun(eventName: "HumanDelete", name: string, func: hooks.HumanDelete)
---@field add fun(eventName: "HumanLimbInverseKinematics", name: string, func: hooks.HumanLimbInverseKinematics)
---@field add fun(eventName: "InterruptSignal", name: string, func: hooks.InterruptSignal)
---@field add fun(eventName: "ItemComputerInput", name: string, func: hooks.ItemComputerInput)
---@field add fun(eventName: "ItemCreate", name: string, func: hooks.ItemCreate)
---@field add fun(eventName: "ItemDelete", name: string, func: hooks.ItemDelete)
---@field add fun(eventName: "ItemLink", name: string, func: hooks.ItemLink)
---@field add fun(eventName: "LineIntersectHuman", name: string, func: hooks.LineIntersectHuman)
---@field add fun(eventName: "LogicCoop", name: string, func: hooks.LogicCoop)
---@field add fun(eventName: "LogicRace", name: string, func: hooks.LogicRace)
---@field add fun(eventName: "LogicRound", name: string, func: hooks.LogicRound)
---@field add fun(eventName: "LogicTerminator", name: string, func: hooks.LogicTerminator)
---@field add fun(eventName: "LogicVersus", name: string, func: hooks.LogicVersus)
---@field add fun(eventName: "LogicWorld", name: string, func: hooks.LogicWorld)
---@field add fun(eventName: "Logic", name: string, func: hooks.Logic)
---@field add fun(eventName: "PacketBuilding", name: string, func: hooks.PacketBuilding)
---@field add fun(eventName: "PhysicsBullets", name: string, func: hooks.PhysicsBullets)
---@field add fun(eventName: "Physics", name: string, func: hooks.Physics)
---@field add fun(eventName: "PhysicsRigidBodies", name: string, func: hooks.PhysicsRigidBodies)
---@field add fun(eventName: "PlayerAI", name: string, func: hooks.PlayerAI)
---@field add fun(eventName: "PlayerActions", name: string, func: hooks.PlayerActions)
---@field add fun(eventName: "PlayerChat", name: string, func: hooks.PlayerChat)
---@field add fun(eventName: "PlayerCreate", name: string, func: hooks.PlayerCreate)
---@field add fun(eventName: "PlayerDeathTax", name: string, func: hooks.PlayerDeathTax)
---@field add fun(eventName: "PlayerDelete", name: string, func: hooks.PlayerDelete)
---@field add fun(eventName: "PlayerGiveWantedLevel", name: string, func: hooks.PlayerGiveWantedLevel)
---@field add fun(eventName: "PostAccountDeathTax", name: string, func: hooks.PostAccountDeathTax)
---@field add fun(eventName: "PostAccountTicket", name: string, func: hooks.PostAccountTicket)
---@field add fun(eventName: "PostAccountsSave", name: string, func: hooks.PostAccountsSave)
---@field add fun(eventName: "PostAreaCreateBlock", name: string, func: hooks.PostAreaCreateBlock)
---@field add fun(eventName: "PostAreaDeleteBlock", name: string, func: hooks.PostAreaDeleteBlock)
---@field add fun(eventName: "PostBulletCreate", name: string, func: hooks.PostBulletCreate)
---@field add fun(eventName: "PostCalculateEarShots", name: string, func: hooks.PostCalculateEarShots)
---@field add fun(eventName: "PostEconomyCarMarket", name: string, func: hooks.PostEconomyCarMarket)
---@field add fun(eventName: "PostEventBullet", name: string, func: hooks.PostEventBullet)
---@field add fun(eventName: "PostEventBulletHit", name: string, func: hooks.PostEventBulletHit)
---@field add fun(eventName: "PostEventUpdateElimState", name: string, func: hooks.PostEventUpdateElimState)
---@field add fun(eventName: "PostEventMessage", name: string, func: hooks.PostEventMessage)
---@field add fun(eventName: "PostEventSound", name: string, func: hooks.PostEventSound)
---@field add fun(eventName: "PostEventUpdateItemInfo", name: string, func: hooks.PostEventUpdateItemInfo)
---@field add fun(eventName: "PostEventUpdatePlayerFinance", name: string, func: hooks.PostEventUpdatePlayerFinance)
---@field add fun(eventName: "PostEventUpdatePlayer", name: string, func: hooks.PostEventUpdatePlayer)
---@field add fun(eventName: "PostEventUpdateVehicle", name: string, func: hooks.PostEventUpdateVehicle)
---@field add fun(eventName: "PostGrenadeExplode", name: string, func: hooks.PostGrenadeExplode)
---@field add fun(eventName: "PostHumanCollisionVehicle", name: string, func: hooks.PostHumanCollisionVehicle)
---@field add fun(eventName: "PostHumanCreate", name: string, func: hooks.PostHumanCreate)
---@field add fun(eventName: "PostHumanDamage", name: string, func: hooks.PostHumanDamage)
---@field add fun(eventName: "PostHumanDelete", name: string, func: hooks.PostHumanDelete)
---@field add fun(eventName: "PostHumanLimbInverseKinematics", name: string, func: hooks.PostHumanLimbInverseKinematics)
---@field add fun(eventName: "PostInterruptSignal", name: string, func: hooks.PostInterruptSignal)
---@field add fun(eventName: "PostItemComputerInput", name: string, func: hooks.PostItemComputerInput)
---@field add fun(eventName: "PostItemCreate", name: string, func: hooks.PostItemCreate)
---@field add fun(eventName: "PostItemDelete", name: string, func: hooks.PostItemDelete)
---@field add fun(eventName: "PostItemLink", name: string, func: hooks.PostItemLink)
---@field add fun(eventName: "PostLevelCreate", name: string, func: hooks.PostLevelCreate)
---@field add fun(eventName: "PostLineIntersectHuman", name: string, func: hooks.PostLineIntersectHuman)
---@field add fun(eventName: "PostLogicCoop", name: string, func: hooks.PostLogicCoop)
---@field add fun(eventName: "PostLogicRace", name: string, func: hooks.PostLogicRace)
---@field add fun(eventName: "PostLogicRound", name: string, func: hooks.PostLogicRound)
---@field add fun(eventName: "PostLogicTerminator", name: string, func: hooks.PostLogicTerminator)
---@field add fun(eventName: "PostLogicVersus", name: string, func: hooks.PostLogicVersus)
---@field add fun(eventName: "PostLogicWorld", name: string, func: hooks.PostLogicWorld)
---@field add fun(eventName: "PostLogic", name: string, func: hooks.PostLogic)
---@field add fun(eventName: "PostPacketBuilding", name: string, func: hooks.PostPacketBuilding)
---@field add fun(eventName: "PostPhysicsBullets", name: string, func: hooks.PostPhysicsBullets)
---@field add fun(eventName: "PostPhysics", name: string, func: hooks.PostPhysics)
---@field add fun(eventName: "PostPhysicsRigidBodies", name: string, func: hooks.PostPhysicsRigidBodies)
---@field add fun(eventName: "PostPlayerAI", name: string, func: hooks.PostPlayerAI)
---@field add fun(eventName: "PostPlayerActions", name: string, func: hooks.PostPlayerActions)
---@field add fun(eventName: "PostPlayerChat", name: string, func: hooks.PostPlayerChat)
---@field add fun(eventName: "PostPlayerCreate", name: string, func: hooks.PostPlayerCreate)
---@field add fun(eventName: "PostPlayerDeathTax", name: string, func: hooks.PostPlayerDeathTax)
---@field add fun(eventName: "PostPlayerDelete", name: string, func: hooks.PostPlayerDelete)
---@field add fun(eventName: "PostPlayerGiveWantedLevel", name: string, func: hooks.PostPlayerGiveWantedLevel)
---@field add fun(eventName: "PostPacketReceive", name: string, func: hooks.PostPacketReceive)
---@field add fun(eventName: "PostResetGame", name: string, func: hooks.PostResetGame)
---@field add fun(eventName: "PostSendConnectResponse", name: string, func: hooks.PostSendConnectResponse)
---@field add fun(eventName: "PostSendPacket", name: string, func: hooks.PostSendPacket)
---@field add fun(eventName: "PostServerReceive", name: string, func: hooks.PostServerReceive)
---@field add fun(eventName: "PostServerSend", name: string, func: hooks.PostServerSend)
---@field add fun(eventName: "PostTrafficCarAI", name: string, func: hooks.PostTrafficCarAI)
---@field add fun(eventName: "PostTrafficCarDestination", name: string, func: hooks.PostTrafficCarDestination)
---@field add fun(eventName: "PostTrafficSimulation", name: string, func: hooks.PostTrafficSimulation)
---@field add fun(eventName: "PostVehicleCreate", name: string, func: hooks.PostVehicleCreate)
---@field add fun(eventName: "PostVehicleDamage", name: string, func: hooks.PostVehicleDamage)
---@field add fun(eventName: "PostVehicleDelete", name: string, func: hooks.PostVehicleDelete)
---@field add fun(eventName: "PacketReceive", name: string, func: hooks.PacketReceive)
---@field add fun(eventName: "ResetGame", name: string, func: hooks.ResetGame)
---@field add fun(eventName: "SendConnectResponse", name: string, func: hooks.SendConnectResponse)
---@field add fun(eventName: "SendPacket", name: string, func: hooks.SendPacket)
---@field add fun(eventName: "ServerReceive", name: string, func: hooks.ServerReceive)
---@field add fun(eventName: "ServerSend", name: string, func: hooks.ServerSend)
---@field add fun(eventName: "TrafficCarAI", name: string, func: hooks.TrafficCarAI)
---@field add fun(eventName: "TrafficCarDestination", name: string, func: hooks.TrafficCarDestination)
---@field add fun(eventName: "TrafficSimulation", name: string, func: hooks.TrafficSimulation)
---@field add fun(eventName: "VehicleCreate", name: string, func: hooks.VehicleCreate)
---@field add fun(eventName: "VehicleDamage", name: string, func: hooks.VehicleDamage)
---@field add fun(eventName: "VehicleDelete", name: string, func: hooks.VehicleDelete)
---@field add fun(eventName: string, name: string, func: function)

---Add a generic named hook. For full hook documentation, see the docs at https://github.com/jpxs-intl/RosaServer/wiki/Hooks.
---@param eventName string The name of the event to be hooked.
---@param name string The unique name of the new hook.
---@param func function The function to be called when the hook runs.
function hook.add(eventName, name, func)
	assert(type(eventName) == "string")
	assert(type(func) == "function")

	if _hooks[eventName] == nil then
		_hooks[eventName] = {}
	end

	_hooks[eventName][name] = func
	if IS_DEBUG then
		hook._functionData[func] = {
			name = name,
			eventName = eventName,
		}
	end

	hook.resetCache()
end

---Add a generic hook to be run once.
---@param eventName string The name of the event to be hooked.
---@param func function The function to be called once when the hook runs.
function hook.once(eventName, func)
	assert(type(eventName) == "string")
	assert(type(func) == "function")

	if _tempHooks[eventName] == nil then
		_tempHooks[eventName] = {}
	end

	table.insert(_tempHooks[eventName], func)
	hook.enable(eventName)
end

---Remove a generic named hook.
---@param eventName string The name of the event to be hooked.
---@param name string The unique name of the hook to remove.
function hook.remove(eventName, name)
	assert(type(eventName) == "string")
	if _hooks[eventName] == nil then
		return
	end

	_hooks[eventName][name] = nil
	hook.resetCache()
end

---Run a hook.
---@param eventName string The name of the event.
---@vararg any The arguments to pass to the hook functions.
---@return boolean override Whether default behaviour should be overridden, if applicable.
function hook.run(eventName, ...)
	local hadTemp = false

	local hookInfo = {
		eventName = eventName,
		arguments = { ... },
		runs = {},
	}

	local hookTotalStart = os.clock()
	if _tempHooks[eventName] ~= nil then
		local _tempOverride = false
		for _, tempHookFunc in ipairs(_tempHooks[eventName]) do
			local hookStart = os.clock()

			local isOverride = tempHookFunc(...)

			local diff = os.clock() - hookStart

			local funcInfo = hook._functionData[tempHookFunc]

			table.insert(hookInfo.runs, {
				time = diff,
				name = funcInfo and funcInfo.name or "unknown",
			})

			if isOverride then
				_tempOverride = true
				break
			end
		end
		_tempHooks[eventName] = nil
		if _tempOverride then
			return true
		end
		hadTemp = true
	end

	local cache = _cache[eventName]
	if cache ~= nil then
		for _, hookFunc in pairs(cache) do
			local hookStart = os.clock()

			local res = hookFunc(...)

			local diff = os.clock() - hookStart

			local funcInfo = hook._functionData[hookFunc]

			table.insert(hookInfo.runs, {
				time = diff,
				name = funcInfo and funcInfo.name or "unknown",
			})

			if res == CONTINUE then
				return false
			end
			if res == OVERRIDE then
				return true
			end
		end

		local diff = os.clock() - hookTotalStart

		hook._lastRunInfo[eventName] = {
			time = diff,
			runs = hookInfo.runs,
		}
	elseif hadTemp then
		hook.disable(eventName)
	end

	return false
end

---Check whether someone is allowed to run a command.
---@param name string The name of the command.
---@param command Command The command table.
---@param plyOrArgs Player|table The calling player, or a table of arguments if it is a console command.
---@return boolean canCall Whether the command can be called given the conditions.
function hook.canCallCommand(name, command, plyOrArgs)
	if not name:startsWith("/") then
		-- This is a console-only command
		return type(plyOrArgs) == "table"
	else
		if command.canCall then
			return command.canCall(plyOrArgs)
		else
			return true
		end
	end
end

---@param command Command
local function callCommand(name, command, plyOrArgs, ...)
	if not hook.canCallCommand(name, command, plyOrArgs) then
		error("Access denied")
	end

	command.call(plyOrArgs, ...)
end

---Get all enabled commands.
---@return table commands The name of each command mapped to their command table.
function hook.getCommands()
	local commands = {}

	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			for name, command in pairs(plugin.commands) do
				commands[name] = command
			end
		end
	end

	return commands
end

---Find a command by its name or alias.
---@param name string The name or alias of the command to find.
---@return table? command The found command, if any.
function hook.findCommand(name)
	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			local command = plugin.commands[name]
			if command then
				return command
			end

			for _, c in pairs(plugin.commands) do
				if c.alias and table.contains(c.alias, name) then
					return c
				end
			end
		end
	end

	return nil
end

local function commandNameStartsWith(name, beginning)
	if name:startsWith(beginning) then
		return true
	end

	if name:startsWith("/") then
		return name:sub(2):startsWith(beginning)
	end

	return false
end

---Auto complete a command by its name or alias.
---@param beginning string The name to auto complete.
---@return string? name The full name of the found command, if any.
---@return table? command The found command, if any.
function hook.autoCompleteCommand(beginning)
	--- Check raw names first
	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			for name, c in pairs(plugin.commands) do
				if commandNameStartsWith(name, beginning) then
					return name, c
				end
			end
		end
	end

	--- Check aliases, auto complete with raw name anyway
	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			for name, c in pairs(plugin.commands) do
				if c.alias then
					for _, alias in ipairs(c.alias) do
						if commandNameStartsWith(alias, beginning) then
							return name, c
						end
					end
				end
			end
		end
	end

	return nil, nil
end

---Auto complete a plugin by its file name or alias.
---@param beginning string The name to auto complete.
---@param nameSpace string? The plugin name space to limit the search to.
---@return string? name The full file name of the found plugin, if any.
---@return Plugin? plugin The found plugin, if any.
function hook.autoCompletePlugin(beginning, nameSpace)
	beginning = beginning:lower()

	for _, plugin in pairs(hook.plugins) do
		if (not nameSpace or plugin.nameSpace == nameSpace) and plugin.fileName:lower():startsWith(beginning) then
			return plugin.fileName, plugin
		end
	end

	return nil, nil
end

---Find a plugin by its file name.
---@param name string The name of the desired plugin.
---@param nameSpace string? The plugin name space to limit the search to.
---@return Plugin? plugin The found plugin, if any.
function hook.getPluginByName(name, nameSpace)
	name = name:lower()

	for _, plugin in pairs(hook.plugins) do
		if (not nameSpace or plugin.nameSpace == nameSpace) and plugin.fileName:lower() == name then
			return plugin
		end
	end

	return nil
end

---Run a command.
---@param name string The name of the command being passed.
---@param command table? The command to run, usually the result of hook.findCommand.
---@vararg any The rest of the parameters the command expects.
---@see hook.findCommand
function hook.runCommand(name, command, ...)
	if command ~= nil then
		callCommand(name, command, ...)
		return true
	end

	return false
end
