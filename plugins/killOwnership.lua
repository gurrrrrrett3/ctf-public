---@type Plugin
local plugin = ...
plugin.name = "Kill Ownership"
plugin.author = "gart"

---@class KillOwnershipData
---@field lastAttacker Player
---@field lastAttackedAt integer
---@field playerDamage {[integer]: {damage: integer, time: integer}}
---@field lastHealth integer
---@field justHitByVehicle boolean
---@field hasShownDeathMessage boolean

local deathMessages = {
	weapon = {
		"%v% was killed by %a%",
		"%v% was shot by %a%",
		"%v% was sniped by %a%",
		"%v% was beamed by %a%",
		"%v% was lasered by %a%",
		"%a% beamed %v%",
		"%a% lasered %v%",
		"%a% shot %v%",
		"%a% RDMed %v%",
		"%v% got %a%'d",
	},
	vehicle = {
		"%v% was run over by %a%",
		"%v% was splattered by %a%",
		"%v% was crushed by %a%",
		"%v% was roadkilled by %a%",
		"%v% was pancaked by %a%",
		"%v% was pancaked by %a%",
		"%a% pancaked %v%",
		"%a% roadkilled %v%",
		"%a% splattered %v%",
		"%a% ran over %v%",
	},
	grenade = {
		"%v% was blown up by %a%",
		"%v% was grenaded by %a%",
		"%v% was naded by %a%",
		"%v% was exploded by %a%",
		"%v% was blown to bits by %a%",
		"%v% was blown to pieces by %a%",
		"%a% grenaded %v%",
		"%a% naded %v%",
		"%a% exploded %v%",
		"%a% blew up %v%",
	},
	killSteal = {
		"%a% stole %a2%'s kill on %v%",
	},
}

---@param attacker Player
---@param victim Player
---@param type 'weapon' | 'vehicle' | 'grenade'
local function handleKill(attacker, victim, type)
	if not attacker or not victim or victim.human.data.killOwnership.hasShownDeathMessage then
		return
	end

	---@type Player[]
	local assists = {}

	for playerIdx, damageData in pairs(victim.human.data.killOwnership.playerDamage) do
		if damageData.time > os.time() - 10 then
			table.insert(assists, players[playerIdx])
		end
	end

	-- sort by damage dealt
	table.sort(assists, function(a, b)
		return victim.human.data.killOwnership.playerDamage[a.index].damage
			> victim.human.data.killOwnership.playerDamage[b.index].damage
	end)

	-- kill stealing: if the killer did less than 25 damage, and the victim was damaged by someone else

	-- if attacker and attacker.human and attacker.human.data.killOwnership and
	--     attacker.human.data.killOwnership.lastAttackedAt + 10 > os.time() and
	--     victim.human.data.killOwnership.playerDamage[attacker.index].damage < 25 then
	--     local ko = attacker.human.data.killOwnership

	--     local lastAttacker = ko.lastAttacker
	--     if lastAttacker and lastAttacker.index ~= attacker.index then
	--         local lastDamage = victim.human.data.killOwnership.playerDamage[lastAttacker.index].damage
	--         if lastDamage > 25 then
	--             local message = deathMessages.killSteal[math.random(#deathMessages.killSteal)]
	--             message = message:gsub("%%v%%", victim.account.name)
	--             message = message:gsub("%%a%%", attacker.account.name)
	--             message = message:gsub("%%a2%%", lastAttacker.account.name)

	--             chat.announceWrap(message)

	--             attacker.human.data.killOwnership.hasShownDeathMessage = true
	--         end
	--     end
	-- else

	local message = deathMessages[type][math.random(#deathMessages[type])]
	message = message:gsub("%%v%%", victim.account and victim.account.name or ("Bot " .. tostring(victim.index)))
	message = message:gsub("%%a%%", attacker.account and attacker.account.name or ("Bot " .. tostring(attacker.index)))

	chat.announceWrap(message)

	victim.human.data.killOwnership.hasShownDeathMessage = true
	-- end

	hook.run("PlayerKill", attacker, victim, type, assists)

	-- print(attacker.name .. " killed " .. victim.name .. " with " .. type)
	-- for i = 1, #assists do
	-- 	print(
	-- 		"\tAssist: "
	-- 			.. assists[i].name
	-- 			.. " with "
	-- 			.. victim.human.data.killOwnership.playerDamage[assists[i].index].damage
	-- 	)
	-- end

	if victim and victim.human then
		victim.human.data.killOwnership = victim.human.data.killOwnership
			or {
				lastAttacker = nil,
				lastAttackedAt = 0,
				playerDamage = {},
			}

		local ko = victim.human.data.killOwnership

		ko.hasShownDeathMessage = true
		ko.playerDamage = {}
		ko.lastAttacker = nil
		ko.lastAttackedAt = 0

		victim.human.data.killOwnership = ko
	end
end

plugin:addHook("PostHumanCreate", function(human)
	human.data.killOwnership = human.data.killOwnership
		or {
			lastAttacker = nil,
			lastAttackedAt = 0,
			playerDamage = {},
		}
end)

plugin:addHook("BulletHitHuman", function(human, bullet)
	human.data.killOwnership = human.data.killOwnership
		or {
			lastAttacker = nil,
			lastAttackedAt = 0,
			playerDamage = {},
		}

	---@type KillOwnershipData
	local ko = human.data.killOwnership
	local attacker = bullet.player

	if not attacker or not human.player or attacker.index == human.player.index then
		return
	end

	ko.lastAttacker = attacker
	ko.lastHealth = human.health

	human.data.killOwnership = ko
end)

plugin:addHook("HumanCollisionVehicle", function(human, vehicle)
	human.data.killOwnership = human.data.killOwnership
		or {
			lastAttacker = nil,
			lastAttackedAt = 0,
			playerDamage = {},
		}

	---@type KillOwnershipData
	local ko = human.data.killOwnership
	local attacker = vehicle.lastDriver

	if not human.isAlive or not attacker or (human.player and attacker.index == human.player.index) then
		return
	end

	ko.lastAttacker = attacker
	ko.justHitByVehicle = true

	human.data.killOwnership = ko
end)

plugin:addHook("PostHumanCollisionVehicle", function(human, vehicle)
	if not human.data.killOwnership then
		return
	end

	---@type KillOwnershipData
	local ko = human.data.killOwnership

	if not human.isAlive and ko.justHitByVehicle then
		ko.justHitByVehicle = false
		ko.lastAttackedAt = os.time()

		ko.justHitByVehicle = false

		if
			vehicle
			and vehicle.lastDriver
			and vehicle.lastDriver.human
			and vehicle.lastDriver.human.vehicle
			and vehicle.lastDriver.human.vehicle.index == vehicle.index
		then
			ko.lastAttacker = vehicle.lastDriver

			handleKill(vehicle.lastDriver, human.player, "vehicle")
		end
	end

	human.data.killOwnership = ko
end)

plugin:addHook("PostGrenadeExplode", function(grenade)
	for i = 0, #humans do
		local victim = humans[i]
		if not victim then
			goto continue
		end
		if
			victim.pos:distSquare(grenade.pos) < 110
			and grenade.grenadePrimer
			and grenade.grenadePrimer.human
			and not victim.isAlive
		then
			local attacker = grenade.grenadePrimer.human

			if attacker then
				victim.data.killOwnership = victim.data.killOwnership
					or {
						lastAttacker = nil,
						lastAttackedAt = 0,
						playerDamage = {},
					}
				victim.data.killOwnership.lastAttacker = attacker
				victim.data.killOwnership.lastAttackedAt = os.time()

				if not victim.isAlive then
					handleKill(attacker.player, victim.player, "grenade")
				end
			end
		end
		::continue::
	end
end)

plugin:addHook("HumanDamage", function(human, bone, damage)
	if human.player and human.player.isBot then
		human:speak(tostring(damage), 2)
		-- return hook.override
	end

	if not human.data.killOwnership then
		return
	end

	---@type KillOwnershipData
	local ko = human.data.killOwnership

	local attacker = ko.lastAttacker

	if not attacker then
		return
	end

	ko.playerDamage[attacker.index] = ko.playerDamage[attacker.index] or { damage = 0, time = 0 }

	ko.playerDamage[attacker.index].damage = human.data.killOwnership.playerDamage[attacker.index].damage + damage
	ko.playerDamage[attacker.index].time = os.time()
	ko.lastAttackedAt = os.time()

	if not human.isAlive then
		handleKill(attacker, human.player, "weapon")
	end

	human.data.killOwnership = ko
end)

plugin:addHook("AccountDeathTax", function(account)
	local human = players.getByPhone(account.phoneNumber).human
	if not human or not human.data.killOwnership then
		return
	end

	local ko = human.data.killOwnership

	if ko.lastAttacker and ko.lastAttackedAt + 10 > os.realClock() then
		handleKill(ko.lastAttacker, human.player, "weapon")
	end
end)

plugin:addHook("PlayerDeathTax", function(player)
	local human = player.human
	if not human or not human.data.killOwnership then
		return
	end

	local ko = human.data.killOwnership

	if ko.lastAttacker and ko.lastAttackedAt + 10 > os.realClock() then
		handleKill(ko.lastAttacker, human.player, "weapon")
	end
end)
