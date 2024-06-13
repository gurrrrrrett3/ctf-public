local Speaker = require("plugins.libaudio.speaker")
local LibUtilItem = require("plugins.libutil.item")
local json = require("main.json")

---@class Radio
---@field speaker Speaker_Standalone
---@field requester Player?
---@field class string
local Radio = {}

---@type Radio[]
Radio.radios = {}

Radio.queueTimer = 0

---@type {id: string, pos: Vector, rot: RotMatrix, radio: Radio}[]
Radio.statusQueue = {}

---@type {host: string, port: integer, username: string, password: string, path: string}
Radio.sftpDetails = {}

Radio.serverHost = "https://srradio.gart.sh"

Radio.__index = Radio

function Radio.create()
	local newRadio = setmetatable({
		class = "Radio",
		speaker = nil,
		requester = nil,
	}, Radio)

	table.insert(Radio.radios, newRadio)

	return newRadio
end

---@param id string
---@return {id: string, title: string, author: string, duration: number}?
function Radio.readMetaFile(id)
	local metaPath = "./plugins/radio/audio/" .. id .. ".meta"
	local metaFile = io.open(metaPath, "r")

	if metaFile then
		---@type string
		local content = metaFile:read("*all")
		local lines = {}
		for line in content:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		metaFile:close()
		return {
			id = id,
			title = lines[2],
			author = lines[3],
			duration = tonumber(lines[4]),
		}
	end

	return nil
end

---@param details {host: string, port: integer, username: string, password: string, path: string}
function Radio.setSftpDetails(details)
	Radio.sftpDetails = details
end

---@param query string
---@param cb fun(data: any)
function Radio.request(query, cb)
	http.post(
		Radio.serverHost,
		"/request",
		{},
		json.encode({ query = query, creds = Radio.sftpDetails }),
		"application/json",
		function(response)
			if response and response.status == 200 then
				local data = json.decode(response.body)
				cb(data)
			else
				cb({ error = "Something went wrong", videoId = nil })
			end
		end
	)
end

---@param id string
---@param cb fun(data: {done: boolean})
function Radio.status(id, cb)
	local path = "/status/" .. id

	http.get(Radio.serverHost, path, {}, function(response)
		if response and response.status == 200 then
			local data = json.decode(response.body)
			cb(data)
		else
			print("Something went wrong")
		end
	end)
end

---@param pos Vector
---@param rot RotMatrix
---@param itemId Enum.item
function Radio:createSpeaker(pos, rot, itemId)
	if self.speaker then
		self.speaker:destroy()
	end

	local item = LibUtilItem.createStaticItem(itemId, pos, rot)
	assert(item, "Failed to create item")
	self.speaker = Speaker.create(item)
end

---@param id string
---@param requester Player?
function Radio:play(id, requester)
	local meta = Radio.readMetaFile(id)
	assert(meta, "Failed to read meta file")
	assert(self.speaker, "Speaker not created")
	self.speaker:loadAudioFile("./plugins/radio/audio/" .. id .. ".pcm")
	self.speaker.meta.title = meta.title
	self.speaker.meta.author = meta.author
	self.speaker.meta.duration = meta.duration
	self.speaker.meta.id = id
	self.requester = requester
	self.speaker:play()

	print(
		string.format(
			"Playing %s by %s (%02d:%02d)",
			meta.title or "unknown",
			meta.author or "unknown",
			math.floor((meta.duration / 60) or 0),
			(meta.duration or 0) % 60
		)
	)
end

---@param query string
---@param pos Vector
---@param rot RotMatrix
---@param radio Radio?
function Radio.createAndSearch(query, pos, rot, radio)
	local radioObj = radio or Radio.create()
	radioObj:createSpeaker(pos, rot, enum.item.box)
	radioObj:search(query)
end

---@param query string
function Radio:search(query)
	assert(self.speaker, "Speaker not created")
	Radio.request(query, function(data)
		local id = data.videoId

		if id == nil then
			error("No results found for " .. query)
			return
		end

		-- check for meta file
		local metaFile = io.open("./plugins/radio/audio/" .. id .. ".meta", "r")
		local pcmFile = io.open("./plugins/radio/audio/" .. id .. ".pcm", "r")

		if metaFile and pcmFile then
			metaFile:close()
			pcmFile:close()

			assert(self.speaker, "Speaker not created")
			self:play(id, self.requester)
		else
			table.insert(Radio.statusQueue, {
				id = id,
				pos = self.speaker._baseItem.pos:clone(),
				rot = self.speaker._baseItem.rot:clone(),
				radio = self,
			})
		end
	end)
end

hook.add("Logic", "Radio", function()
	for _, speaker in pairs(Speaker.speakers) do
		speaker._baseItem.despawnTime = 100
	end

	Radio.queueTimer = Radio.queueTimer + 1

	if Radio.queueTimer > 60 then
		Radio.queueTimer = 0

		if Radio.statusQueue and #Radio.statusQueue > 0 then
			local id = Radio.statusQueue[1].id
			local pos = Radio.statusQueue[1].pos
			local rot = Radio.statusQueue[1].rot
			local radio = Radio.statusQueue[1].radio
			table.remove(Radio.statusQueue, 1)
			Radio.status(id, function(data)
				if data.done then
					if not radio.speaker then
						radio:createSpeaker(pos, rot, enum.item.box)
					end

					radio:play(id)
				else
					table.insert(Radio.statusQueue, {
						id = id,
						pos = pos,
						rot = rot,
						radio = radio,
					})
				end
			end)
		end
	end
end)

return Radio
