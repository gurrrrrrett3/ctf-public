---@type Plugin
local plugin = ...
plugin.name = "globalchat"
plugin.author = "gart"
plugin.description = "A global chat system"

plugin:addHook("EventMessage", function(speakerType, message, speakerID, volumeLevel)
    if speakerType == 1 and volumeLevel == 2 and message:trim() ~= "" then
        local player = humans[speakerID].player
        if player then
            chat.announceWrap(string.format("%s: %s", player.name, message))
        end
    end
end)
