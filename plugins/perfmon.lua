---@type Plugin
local plugin = ...
plugin.name = "perfmon"
plugin.author = "gart"
plugin.description = "Plugin performance monitor, requires modded main.hook and main.plugins"

plugin.defaultConfig = {
	-- Interval for logging in seconds
	interval = 1,
}

local lastLogTime
local startEpoch

---@type table<string, number>	
local keyIndex = {}
local indexSize = 0

plugin:addEnableHandler(function()
	if os.createDirectory("perfmon") then
		plugin:print("Created perfmon data directory")
	end

	local keyIndexFile = io.open("perfmon/keyIndex.txt", "r")
	if keyIndexFile then
		local index = 1
		for line in keyIndexFile:lines() do
			keyIndex[line] = index
			index = index + 1
			indexSize = indexSize + 1
		end
		keyIndexFile:close()
	else
		plugin:print("Created key index file")
		io.open("perfmon/keyIndex.txt", "w")
	end

	lastLogTime = 0
	startEpoch = os.time()

    hook._monitoringEnabled = true
end)

plugin:addDisableHandler(function()
	lastLogTime = nil
	startEpoch = nil

    hook._monitoringEnabled = false
end)

plugin:addHook("Logic", function()
	local now = os.realClock()
	if now - lastLogTime >= plugin.config.interval then
		lastLogTime = now

		local sdgLineData = {}
		if hook.run("AddSDGData", sdgLineData) then
			return
		end

        --- load hook data
        local hookData = hook._lastRunInfo
        
        ---@param hookInfo HookInfo
        for hookName, hookInfo in pairs(hookData) do
            local hookRuns = hookInfo.runs
            local hookTime = hookInfo.time
            local hookCount = #hookRuns

            local hookAvg = hookTime / hookCount

            sdgLineData["_total." .. hookName .. ".avg"] = hookAvg
            ---@param run HookRunInfo
            for i, run in ipairs(hookRuns) do
                sdgLineData[run.name .. "." .. hookName .. ".time"] = math.round(run.time * 10000000, 5)
            end
        end

        hook._lastRunInfo = {}

		if (not keyIndex) then return end

		local epochDelta = os.time() - startEpoch
		local line = "t=" .. epochDelta .. ","
        for k,v in pairs(sdgLineData) do

			local index = keyIndex[k]

			if not index then
				keyIndex[k] = #keyIndex + 1
				index = keyIndex[k]
				indexSize = indexSize + 1
			end

            line = line .. index .. "=" .. v .. ","
        end
        line = line:sub(1, -2)

		local file = io.open("perfmon/" .. os.date("%Y-%m-%d-%h") .. ".txt", "a")
		if (not file) then return end
		file:write(line .. "\n")
		file:close()

			local keyIndexFile = io.open("perfmon/keyIndex.txt", "w")
			if (not keyIndexFile) then return end
			for k, v in pairs(keyIndex) do
				keyIndexFile:write(k .. "\n")
			end
			keyIndexFile:close()

	end
end)

local function getKeyFromIndex(index)
	for k, v in pairs(keyIndex) do
		if v == index then
			return k
		end
	end
	
end

---@return table<{key: string, min: number, max: number, avg: number, count: number}>|nil
local function loadFileData()
	local files = os.listDirectory("perfmon")
	local file = io.open("perfmon/export.csv", "w")
	if (not file) then return end

	---@type table<string, {min: number, max: number, avg: number, count: number}>
	local hooks = {}

	for _, dataFile in ipairs(files) do 
		-- not keyIndex or export
		if dataFile.name ~= "keyIndex.txt" and dataFile.name ~= "export.csv" then
			local file = io.open("perfmon/" .. dataFile.name, "r")
			
			if not file then return end

			for line in file:lines() do
				local data = line:split(",")
				local epochData = {}

				for i = 2, #data do
					local key, value = data[i]:match("(.+)=(.+)")
					epochData[tonumber(key)] = tonumber(value)
				end

				for key, value in pairs(epochData) do
					local hookName = getKeyFromIndex(key)
					if not hooks[hookName] then
						hooks[hookName] = {
							min = value,
							max = value,
							avg = value,
							count = 1,
						}
					else
						local hook = hooks[hookName]
						hook.min = math.min(hook.min, value)
						hook.max = math.max(hook.max, value)
						hook.avg = hook.avg + value
						hook.count = hook.count + 1
					end
				end
			end

		end
	end 

	-- sort hooks by max
	local sortedHooks = {}
	for key, hook in pairs(hooks) do
		table.insert(sortedHooks, {key = key, hook = hook})
	end

	table.sort(sortedHooks, function(a, b)
		return a.hook.max > b.hook.max
	end)

	-- remove hooks with no data or invalid data (avg = 0 or inf)
	for i = #sortedHooks, 1, -1 do
		local hook = sortedHooks[i]
		if not hook.hook.avg or hook.hook.avg == 0 or hook.hook.avg == math.huge then
			table.remove(sortedHooks, i)
		end
	end

	return sortedHooks
end

plugin.commands["perfmon"] = {
	info = "perfmon plugin commands.",
	canCall = function(ply)
		return ply.isConsole or ply.isAdmin
	end,
	---@param args string[]
	call = function(args)
		local command = args[1]

		---@type table<string, fun(args: string[])>
		local commands = {
			["status"] = function (args)
				plugin:print("Monitoring: " .. (hook._monitoringEnabled and "Enabled" or "Disabled"))
				plugin:print("Interval: " .. plugin.config.interval .. "s")
				plugin:print("Key Index Size: " .. indexSize)
				plugin:print("Last Log Time: " .. lastLogTime)
				plugin:print("File Count: " .. #os.listDirectory("perfmon") - 1)
			end,
			["enable"] = function (args)
				hook._monitoringEnabled = true
				plugin:print("Enabled")
			end,
			["disable"] = function (args)
				hook._monitoringEnabled = false
			end,
			["top"] = function (args)
				local amt = tonumber(args[2]) or 10
				local sortedHooks = loadFileData()
				if not sortedHooks then return end

				for i = 1, amt do
					local hook = sortedHooks[i]
					if hook then
						plugin:print(string.format("%s: %f", hook.key, hook.hook.max))
					end
				end
			end,
			["export"] = function (args)
				
				local sortedHooks = loadFileData() 
				if not sortedHooks then return end

				local file = io.open("perfmon/export.csv", "w")
				if (not file) then return end
			
				file:write("hook,min,max,avg,count\n")

				for key, hook in pairs(sortedHooks) do
					if (hook.avg) then
						hook.avg = hook.avg / hook.count
						file:write(string.format("%s,%f,%f,%f,%d\n", hook.key, hook.hook.min, hook.hook.max, hook.avg, hook.hook.count))
					else
						file:write(string.format("%s,%f,%f,%f,%d\n", hook.key, hook.hook.min, hook.hook.max, 0, hook.hook.count))
					end
				end

				file:close()
				plugin:print("Exported to perfmon/export.csv")
			end,
			["keys"] = function (args)
				for k, _ in pairs(keyIndex) do
					plugin:print(k)
				end
			end
		}

		if commands[command] then
			commands[command](args)
		end
	end,
}
