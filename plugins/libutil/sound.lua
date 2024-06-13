---@class LibUtilSound
local Sound = {}

---@param sounds integer[]
---@param position Vector
---@param volume number
---@param pitch number
function Sound.createRandom(sounds, position, volume, pitch)
	events.createSound(sounds[math.random(1, #sounds)], position, volume, pitch)
end

return Sound
