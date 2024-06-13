local CustomWeapon = require("plugins.customitems.classes.CustomWeapon")

local BurstSMG = CustomWeapon:new("Burst SMG", enum.item.uzi)

BurstSMG:allowReloadItem("jpxs.ammo.smg")

BurstSMG.maxAmmo = 24
BurstSMG.bulletType = enum.bullet.m16
BurstSMG.bulletVelocity = 8
BurstSMG.bulletSpread = 0.05
BurstSMG.sound = enum.sound.weapon.m16
BurstSMG.soundPitch = 0.7

local burstSize = 3
local burstDelay = 5
local postBurstCooldown = 20

BurstSMG:onWeapon("weaponPlayerFire", function(item, player)
	local burstShotsRemaining = item.data.burstShotsRemaining or 2

	if item.data.isBursting or item.data.burstCooldown then
		local mag = item:getChildItem(0)
		mag.bullets = mag.bullets + 1
		return
	else
		item.data.isBursting = true
		item.data.bursts = burstSize
	end

	if burstShotsRemaining > 0 then
		item.data.burstShotsRemaining = burstShotsRemaining - 1
	else
		item.data.burstShotsRemaining = 2
	end
end)

BurstSMG:onWeapon("weaponPlayerReload", function(item, player)
	item.bullets = 0 -- prevent extra bullet in gun (causes uneven burst)
end)

BurstSMG:on("logic", function(item)
	if item.data.isBursting then
		item.data.burstTimer = item.data.burstTimer or burstDelay
		item.data.burstTimer = item.data.burstTimer - 1

		if item.data.burstTimer <= 0 and item.parentHuman and item.parentHuman.player then
			item.data.bursts = item.data.bursts - 1

			if item.data.bursts <= 0 then
				item.data.isBursting = false
				item.data.burstTimer = nil
				item.data.burstCooldown = postBurstCooldown
			else
				item.data.burstTimer = burstDelay
			end

			BurstSMG:fireBullet(item, item.parentHuman.player, item.data.bursts == burstSize - 1 and 1 or 0)
		end
	end

	if item.data.burstCooldown then
		item.data.burstCooldown = item.data.burstCooldown - 1

		if item.data.burstCooldown <= 0 then
			item.data.burstCooldown = nil
		end
	end
end)

return BurstSMG
