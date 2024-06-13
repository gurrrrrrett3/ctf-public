local Radio = require("plugins.radio.radio")
local Speaker = require("plugins.libaudio.speaker")

---@type Plugin
local plugin = ...
plugin.name = "Radio"
plugin.author = "gart"
plugin.description = "Just makes a little radio"

-- ptero sftp details
local sftpDetails = {
	host = "dedi.gart.sh",
	port = 2022,
	serverId = "0e6de839",
	username = "sftp",
	password = "randompassword",
}

Radio.setSftpDetails(sftpDetails)

---@param item Item
---@param ply Player
plugin:addHook("ItemLink", function(item, ply)
	if item.data.speaker then
		item.data.speaker:togglePlayback()

		if item.data.speaker.status == Speaker.SPEAKER_STATUS.PLAYING then
			events.createMessage(2, "Resuming", item.index, 1)
		else
			events.createMessage(2, "Pausing", item.index, 1)
		end

		return hook.override
	end
end)

plugin.commands["/play"] = {
	info = "Play a song from youtube",
	usage = "<query>",
	canCall = function(ply)
		return ply.isAdmin
	end,
	call = function(ply, man, args)
		local query = table.concat(args, " ")
		Radio.createAndSearch(query, ply.human.pos, yawToRotMatrix(ply.human.viewYaw))
	end,
}
