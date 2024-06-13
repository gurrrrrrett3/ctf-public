local json = require("main.json")

--- Handles downloading avatars for pedistals
---@class Avatars
local Avatars = {
	avatarCache = {},
}

---Represents an avatar from the JPXS API
---@class Avatar
---@field public gender integer
---@field public head integer
---@field public skinColor integer
---@field public hairColor integer
---@field public hair integer
---@field public eyeColor integer

---Gets the avatar for a given phone number
---@param phoneNumber integer
---@param cb fun(avatar: Avatar?)
function Avatars.getAvatar(phoneNumber, cb)
	local cachedAvatar = Avatars.avatarCache[phoneNumber]
	if cachedAvatar then
		cb(cachedAvatar)
		return
	end

	http.get("https://jpxs.io", "/api/player/" .. phoneNumber, {
		["Accept"] = "application/json",
	}, function(res)
		if res and res.status == 200 then
			local data = json.decode(res.body)

			local currentAvatarId = data.players[1].avatar.id
			local avatarData = nil

			for _, history in pairs(data.players[1].avatarHistory) do
				if history.avatar.id == currentAvatarId then
					avatarData = history.avatar
					break
				end
			end

			if not avatarData then
				cb(nil)
				return
			end

			---@type Avatar
			local avatar = {
				gender = avatarData.sex,
				head = avatarData.head,
				skinColor = avatarData.skin,
				hairColor = avatarData.hairColor,
				hair = avatarData.hair,
				eyeColor = avatarData.eyes,
			}

			Avatars.avatarCache[phoneNumber] = avatar

			cb(avatar)
		end
	end)
end

return Avatars
