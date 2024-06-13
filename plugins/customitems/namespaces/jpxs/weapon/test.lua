local CustomWeapon = require("plugins.customitems.classes.CustomWeapon")

local TestWeapon = CustomWeapon:new("Test Gun", enum.item.m16)

TestWeapon:allowReloadItem("jpxs.ammo.test")
TestWeapon.maxAmmo = 30

TestWeapon:onWeapon("weaponPlayerFire", function(item, player) end)

return TestWeapon
