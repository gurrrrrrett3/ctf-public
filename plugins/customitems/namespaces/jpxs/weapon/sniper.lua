local CustomWeapon = require("plugins.customitems.classes.CustomWeapon")

local Sniper = CustomWeapon:new("Sniper Rifle", enum.item.m16)

Sniper:allowReloadItem("jpxs.ammo.sniper")

Sniper.maxAmmo = 6
Sniper.bulletType = enum.bullet.m16
Sniper.bulletVelocity = 50
Sniper.bulletSpread = 0.005
Sniper.sound = enum.sound.weapon.m16
Sniper.soundPitch = 0.3
Sniper.soundVolume = 3
Sniper.fireRate = 120

Sniper:onWeapon("weaponPlayerFire", function(item, player)
	local fireCooldown = item.data.fireCooldown or 0

	if fireCooldown > 0 then
		local mag = item:getChildItem(0)
		mag.bullets = mag.bullets + 1
		return
	end

	Sniper:fireBullet(item, player, 0, true)
	item.data.fireCooldown = Sniper.fireRate
end)

Sniper:onWeapon("weaponPlayerReload", function(item, player)
	item.bullets = 0
end)

Sniper:on("logic", function(item)
	if item.data.fireCooldown and item.bullets ~= 0 then
		if item.data.fireCooldown > 0 then
			item.data.fireCooldown = item.data.fireCooldown - 1
		else
			events.createSound(enum.sound.weapon.mag_load, item.pos:clone(), 1, 0.7)
			item.data.fireCooldown = nil
		end
	end
end)

return Sniper
