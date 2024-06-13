local persistantStorage = require("plugins.persistantStorage.persistantStorage")
---@class Speaker_Standalone
---@field public _baseItem Item
---@field public player Player
---@field public currentPath string
---@field public encoder OpusEncoder
---@field public status SpeakerStatus
---@field public meta {title: string, author: string, duration: number, id: string}
---@field public currentDuration number
---@field public errorFrames  number
---@field public hasReloadedEncoder boolean
---@field public class string
local Speaker = {}

---@enum SpeakerStatus
Speaker.SPEAKER_STATUS = {
	["IDLE"] = 0,
	["PLAYING"] = 1,
	["PAUSED"] = 2,
	["FINISHED"] = 3,
	["DESTROYED"] = 4,
}

---@type {[integer]: Speaker_Standalone}
Speaker.speakers = {}

Speaker.__index = Speaker

---@param item Item
function Speaker.create(item)
	local newSpeaker = setmetatable({
		class = "Speaker",
		_baseItem = item,
		player = nil,
		currentPath = nil,
		encoder = nil,
		errorFrames = 0,
		hasReloadedEncoder = false,
		status = Speaker.SPEAKER_STATUS.IDLE,
		meta = { title = nil, author = nil, duration = nil, id = nil },
	}, Speaker)

	local playerIndex = Speaker.getFreePlayerIndex()
	assert(playerIndex, "No free player index")

	newSpeaker.player = players[playerIndex]

	local encoder = OpusEncoder.new()
	encoder.bitRate = 48000

	newSpeaker.encoder = encoder

	newSpeaker.player.data.isSpeaker = true
	newSpeaker._baseItem.data.Speaker = newSpeaker

	Speaker.speakers[playerIndex] = newSpeaker

	return newSpeaker
end

function Speaker.getFreePlayerIndex()
	for i = 254, 0, -1 do
		if players[i].human == nil and not players[i].data.isSpeaker then
			return i
		end
	end
end

---@param path string
function Speaker:loadAudioFile(path)
	if io.open(path, "r") == nil then
		return assert(false, "File not found")
	end
	self.encoder:open(path)
	self.currentPath = path
	self.currentDuration = 0
end

function Speaker:destroy()
	if self.status == Speaker.SPEAKER_STATUS.DESTROYED then
		return
	end

	print("destroying speaker")

	self.encoder:close()

	if self._baseItem.class == "Item" then
		self._baseItem:remove()
	else
		print("destroy tried to remove a", self._baseItem.class)
	end

	Speaker.speakers[self.player.index] = nil

	self.status = Speaker.SPEAKER_STATUS.DESTROYED
	self.player.data.isSpeaker = false
	self.player.data.oldVoice = nil
end

function Speaker:idle()
	self.status = Speaker.SPEAKER_STATUS.IDLE
	self.encoder:close()
end

function Speaker:pause()
	self.status = Speaker.SPEAKER_STATUS.PAUSED
end

function Speaker:play()
	self.status = Speaker.SPEAKER_STATUS.PLAYING
end

function Speaker:finish()
	self.status = Speaker.SPEAKER_STATUS.FINISHED
	self.hasReloadedEncoder = false

	if self.meta.duration and self.meta.duration - self.currentDuration > 5 then
		error(
			"Audio file seems to be corrupted, duration is less than expected\nExpected "
				.. self.meta.duration
				.. " seconds, but got "
				.. math.round(self.currentDuration, 2)
				.. " seconds\n Path: "
				.. self.currentPath
		)

		return false
	end

	return true
end

function Speaker:setMeta(title, author)
	self.meta.title = title
	self.meta.author = author
end

function Speaker:togglePlayback()
	if self.status == Speaker.SPEAKER_STATUS.PLAYING then
		self:pause()
	else
		self:play()
	end
end

---Get the closest speaker to a player
---@param ply Player
function Speaker.getClosestSpeaker(ply)
	local closest = nil
	local closestDist = math.huge
	if not ply.human then
		return nil
	end

	for _, speaker in pairs(Speaker.speakers) do
		local dist = speaker._baseItem.pos:dist(ply.human.pos)
		if speaker.status == speaker.SPEAKER_STATUS.PLAYING and dist < closestDist then
			closest = speaker
			closestDist = dist
		end
	end

	return closest
end

--Save player's voice table to reload
---@param player Player
---@return string[]
function Speaker.saveVoice(player)
	local ret = {}

	for i = 0, 63 do
		ret[i] = player.voice:getFrame(i)
		player.voice:setFrame(i, "", 2)
	end

	return ret
end

---Reload player's voice table
---@param player Player
---@param voice string[]
function Speaker.loadVoice(player, voice)
	for i = 0, 63 do
		player.voice:setFrame(i, voice[i], 2)
	end
end

function Speaker:__tostring()
	return "Speaker(" .. self.player.index .. ")"
end

local skipCounter = 0
hook.add("PostServerReceive", "Speaker", function()
	skipCounter = (skipCounter + 1) % 5
	if skipCounter == 0 then
		return
	end

	for _, speaker in pairs(Speaker.speakers) do
		if speaker.status == Speaker.SPEAKER_STATUS.DESTROYED ~= true and not speaker._baseItem.isActive then
			speaker:destroy()
			return
		end

		local voice = speaker.player.voice

		if speaker.status == Speaker.SPEAKER_STATUS.PAUSED then
			voice.isSilenced = false
			voice.volumeLevel = 0

			speaker.player.data.oldVoice = Speaker.saveVoice(speaker.player)
			return
		elseif speaker.status == Speaker.SPEAKER_STATUS.PLAYING then
			local frame = speaker.encoder:encodeFrame()
			if not frame then
				speaker.errorFrames = speaker.errorFrames + 1
				if speaker.errorFrames > 10 then
					speaker:finish()
				end
				return
			end

			speaker.errorFrames = 0
			speaker.currentDuration = speaker.currentDuration + 0.02
			voice.currentFrame = (voice.currentFrame + 1) % 64
			voice:setFrame(voice.currentFrame, frame, 2)
			voice.isSilenced = false
			voice.volumeLevel = 2
		elseif speaker.status == Speaker.SPEAKER_STATUS.FINISHED then
			speaker:idle()
		end
	end
end)

hook.add(
	"PostCalculateEarShots",
	"Speaker",
	---@param connection Connection
	---@param ply Player
	function(connection, ply)
		local musicEnabled = persistantStorage.get(connection.player, "musicEnabled") == "true"
		if not musicEnabled then
			return
		end

		local shot = connection:getEarShot(7)
		local speaker = Speaker.getClosestSpeaker(ply)
		if speaker and speaker.status == Speaker.SPEAKER_STATUS.PLAYING then
			shot.isActive = true
			shot.player = speaker.player
			shot.human = nil
			shot.receivingItem = speaker._baseItem
			shot.distance = 1
			shot.volume = 1
		end
	end
)

hook.add("ResetGame", "Speaker", function()
	for _, speaker in pairs(Speaker.speakers) do
		speaker:destroy()
	end
end)

return Speaker
