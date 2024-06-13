---@class StaticLibPacketEvents
local LibPacketEvents = {
	_v = "v2ctf",
}
---@type ClientEvent[]
local clientEvents = {}

---@class VirtualEvent
---@field type integer
---@field tickCreated integer
---@field vectorA Vector
---@field vectorB Vector
---@field a integer
---@field b integer
---@field c integer
---@field d integer
---@field floatA number
---@field floatB number
---@field message string

---@class ClientEvent
---@field affectedPlayerIndexes integer[]
---@field event VirtualEvent
---@field nullifiedEvent VirtualEvent
---@field actualEvent Event
---@field actualEventIndex integer

---@param event Event
---@param players Player|Player[]
function LibPacketEvents.createClientEvent(event, players)
	players = type(players) == "table" and players or { players }
	if event and players then
		---@type {[integer]: boolean}
		local indexes = {}

		for _, player in pairs(players) do
			indexes[player.index] = true
		end

		---@type ClientEvent
		local newClientEvent = {
			affectedPlayerIndexes = indexes,
			event = {
				type = event.type,
				tickCreated = event.tickCreated,
				vectorA = event.vectorA,
				vectorB = event.vectorB,
				a = event.a,
				b = event.b,
				c = event.c,
				d = event.d,
				floatA = event.floatA,
				floatB = event.floatB,
				message = event.message,
			},
			nullifiedEvent = {
				type = -1,
				tickCreated = -1,
				vectorA = Vector(),
				vectorB = Vector(),
				a = -1,
				b = -1,
				c = -1,
				d = -1,
				floatA = -1,
				floatB = -1,
				message = "",
			},
			actualEvent = event,
			actualEventIndex = event.index,
		}

		table.insert(clientEvents, newClientEvent)
	end
end

---@param plugin Plugin
function LibPacketEvents.load(plugin)
	hook.add("PacketBuilding", "LibPacketEvents", function(connection)
		if not connection.player then
			return
		end

		for index, clientEvent in pairs(clientEvents) do
			if not clientEvent.actualEvent then
				return
			end

			if clientEvent.affectedPlayerIndexes[connection.player.index] then
				createVirtualTable(clientEvent.event, clientEvent.actualEvent)
			else
				createVirtualTable(clientEvent.nullifiedEvent, clientEvent.actualEvent)
			end
		end
	end)

	hook.add("ResetGame", "LibPacketEvents", function()
		clientEvents = {}
	end)

	plugin:addDisableHandler(function()
		clientEvents = {}
	end)
end

---Show the eliminator ESP box.
---@param player Player The player to show the box to.
---@param pos Vector The position of the box.
---@param color integer The color of the box. 0 = no box, 1 = Red, 2 = Green
function LibPacketEvents.showEliminatorESP(player, pos, color)
	player.team = color
	local event = player:update()
	-- event.b = player.human.index
	player:updateElimState(1, color, player, pos)
end

---Hide the eliminator ESP box.
---@param player Player The player to hide the box from.
function LibPacketEvents.hideEliminatorESP(player)
	player.team = 0
	local event = player:update()
	-- event.b = player.human.index
	player:updateElimState(0, 0, player, Vector())
end

---Creates a chat message only specified players can see.
---@param speakerType integer The type of message. 0 = Chat Announce, 1 = Human Chatting, 2 = Item Chatting, 3 = Eliminator Announcement, 4 = Admin Chat, 5 = ALPHA_25 Billboard, 6 = Red Message.
---@param message string The message to send. Max length 63.
---@param speakerIndex integer The index of the speaker object of the corresponding type, if applicable, or -1.
---@param volumeLevel integer The volume to speak at. 0 = whisper, 1 = normal, 2 = yell.
---@param players table A table containing player(s) that should see the desired message.
function LibPacketEvents.createClientMessage(speakerType, message, speakerIndex, volumeLevel, players)
	LibPacketEvents.createClientEvent(
		events.createMessage(speakerType, message, speakerIndex, volumeLevel),
		type(players) == "table" and players or { players }
	)
end

---Play a sound only specified players can see.
---@param soundType integer The type of the sound.
---@param position Vector The position of the sound.
---@param volume number The volume of the sound, where 1.0 is standard.
---@param pitch number The pitch of the sound, where 1.0 is standard.
---@param players table A table containing player(s) that should hear the desired sound.
function LibPacketEvents.createClientSound(soundType, position, volume, pitch, players)
	LibPacketEvents.createClientEvent(
		events.createSound(soundType, position, volume, pitch),
		type(players) == "table" and players or { players }
	)
end

hook.add("PostResetGame", "LibPacketEvents", function(reason)
	LibPacketEvents._clientEvents = {}
end)

return LibPacketEvents
