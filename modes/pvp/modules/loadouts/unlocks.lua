---@type {[integer]: string[] | string}
LOADOUT_UNLOCKS = {
	[1] = {
		"loadaoutslot",
		"loadaoutslot",
		"item:subrosa.m_16",
		"item:subrosa.m_16_magazine",

		-- WEAPONS TEST STUFF
		"loadaoutslot",
		"loadaoutslot",
		"loadaoutslot",

		"item:jpxs.weapon.burst_smg",
		"item:jpxs.ammo.smg",
		"item:jpxs.weapon.sniper",
		"item:jpxs.ammo.sniper",
	},
	[2] = {
		"item:subrosa.ak_47",
		"item:subrosa.ak_47_magazine",
	},
	[3] = {
		"item:subrosa.mp5",
		"item:subrosa.mp5_magazine",
	},
	[4] = {
		"item:subrosa.uzi",
		"item:subrosa.uzi_magazine",
	},
	[5] = {
		"item:subrosa.9mm",
		"item:subrosa.9mm_magazine",
	},
	[6] = {
		-- "item:subrosa.bandage",
	},
	[7] = {
		"item:subrosa.grenade",
	},
	[10] = {
		"loadaoutslot",
	},
	-- [13] = {
	-- 	"item:jpxs.weapon.burst_smg",
	-- 	"item:jpxs.ammo.smg",
	-- },
	-- [18] = {
	-- 	"item:jpxs.weapon.sniper",
	-- 	"item:jpxs.ammo.sniper",
	-- },
}

---@type {[integer]: string[] | string}
LOADOUT_PASS_UNLOCKS = {
	[1] = {
		"loadaoutslot",
	},
}

---@class Unlocks
local Unlocks = {
	---@type {id: string, unlockAt: integer}[]
	_itemsUnlockCache = nil,
}

---@param rank integer
---@param hasPass boolean
---@return string[]
function Unlocks.getListForRank(rank, hasPass)
	local unlocks = {}

	for i = 1, rank do
		local unlockLevel = LOADOUT_UNLOCKS[i]
		if unlockLevel then
			if type(unlockLevel) == "table" then
				for _, unlock in ipairs(unlockLevel) do
					table.insert(unlocks, unlock)
				end
			else
				table.insert(unlocks, unlockLevel)
			end
		end
	end

	if hasPass then
		for i = 1, rank do
			local unlockLevel = LOADOUT_PASS_UNLOCKS[i]
			if unlockLevel then
				if type(unlockLevel) == "table" then
					for _, unlock in ipairs(unlockLevel) do
						table.insert(unlocks, unlock)
					end
				else
					table.insert(unlocks, unlockLevel)
				end
			end
		end
	end

	return unlocks
end

---@param player Player
---@param rank integer
---@param supportLevel integer
function Unlocks.giveForRank(player, rank, supportLevel)
	local unlocks = Unlocks.getListForRank(rank, supportLevel > 0)
	local supportUnlocks = Unlocks.getSupporterBenefits(supportLevel)

	for _, unlock in ipairs(supportUnlocks) do
		table.insert(unlocks, unlock)
	end

	print("Gave " .. #unlocks .. " unlocks for rank " .. rank)

	player.data.unlocks = {}

	for _, unlock in pairs(unlocks) do
		local subTables = string.split(unlock, ":")

		if #subTables == 3 then
			local itemType = subTables[1]
			local itemSubType = subTables[2]
			local itemSubTypeValue = subTables[3]

			player.data.unlocks[itemType] = player.data.unlocks[itemType] or {}
			player.data.unlocks[itemType][itemSubType] = player.data.unlocks[itemType][itemSubType] or {}
			player.data.unlocks[itemType][itemSubType][itemSubTypeValue] = true

			-- print("Gave unlock " .. itemType .. ":" .. itemSubType .. ":" .. itemSubTypeValue)
		elseif #subTables == 2 then
			local itemType = subTables[1]
			local itemSubType = subTables[2]

			player.data.unlocks[itemType] = player.data.unlocks[itemType] or {}
			player.data.unlocks[itemType][itemSubType] = true

			-- print("Gave unlock " .. itemType .. ":" .. itemSubType)
		elseif unlock == "loadaoutslot" then
			player.data.unlocks.loadoutSlots = player.data.unlocks.loadoutSlots or 0
			player.data.unlocks.loadoutSlots = player.data.unlocks.loadoutSlots + 1
			-- print("Gave loadout slot")
		else
			player.data.unlocks[unlock] = true
			-- print("Gave unlock " .. unlock)
		end
	end
end

---@param supportLevel integer
---@return string[]
function Unlocks.getSupporterBenefits(supportLevel)
	local benefits = {}

	if supportLevel >= 1 then -- discord boost + supporter level
		for i = 1, 3 do
			table.insert(benefits, "loadaoutslot")
		end
	end

	if supportLevel >= 3 then -- alex austin level
		for i = 1, 2 do
			table.insert(benefits, "loadaoutslot")
		end
	end

	if supportLevel >= 4 then -- alex awesome level
		for i = 1, 5 do
			table.insert(benefits, "loadaoutslot")
		end
	end

	return benefits
end

function Unlocks.getUnlocks()
	---@type {id: string, unlockAt: integer}[]
	local typeUnlocks = {}

	for unlockAt, items in pairs(LOADOUT_UNLOCKS) do
		if type(items) == "table" then
			for _, item in ipairs(items) do
				table.insert(typeUnlocks, { id = item, unlockAt = unlockAt })
			end
		else
			table.insert(typeUnlocks, { id = items, unlockAt = unlockAt })
		end
	end

	return typeUnlocks
end

---@return {id: string, unlockAt: integer}[]
function Unlocks.getItemUnlocks()
	if Unlocks._itemsUnlockCache then
		return Unlocks._itemsUnlockCache
	end

	---@type {id: string, unlockAt: integer}[]
	local itemUnlocks = {}

	for unlockAt, items in pairs(LOADOUT_UNLOCKS) do
		if type(items) == "table" then
			for _, item in ipairs(items) do
				local parts = string.split(item, ":")
				if parts[1] == "item" then
					table.insert(itemUnlocks, { id = parts[2], unlockAt = unlockAt })
				end
			end
		else
			local parts = string.split(items, ":")
			if parts[1] == "item" then
				table.insert(itemUnlocks, { id = parts[2], unlockAt = unlockAt })
			end
		end
	end

	Unlocks._itemsUnlockCache = itemUnlocks

	return itemUnlocks
end

return Unlocks
