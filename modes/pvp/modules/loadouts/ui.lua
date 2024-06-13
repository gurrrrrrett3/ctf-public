local LibComputerItem = require("plugins.libcomputer.item")
local Loadouts = require("modes.pvp.modules.loadouts.loadouts")
local ComputerControls = require("plugins.libinput.computerControls")
local Unlocks = require("modes.pvp.modules.loadouts.unlocks")
local PointValues = require("modes.pvp.modules.loadouts.pointValues")

---@class LoadoutUI
local LoadoutUI = {}

---@param pcs LibComputerItem[]
function LoadoutUI.ui(pcs)
	for _, pc in ipairs(pcs) do
		local parentHuman = pc._baseItem.parentHuman
		local player = parentHuman and parentHuman.player
		if player then
			LoadoutUI.draw(pc, player)
		else
			LoadoutUI.drawEmpty(pc)
		end
	end
end

---@param pc LibComputerItem
---@param player Player
function LoadoutUI.draw(pc, player)
	local tabIndex = pc._baseItem.data.tabIndex or 1
	local tab = LoadoutUI.tabs[tabIndex]

	if not player.data.unlocks then
		Unlocks.giveForRank(player, player.data.db.rank or 1, player.data.db.supportLevel or 1)
	end

	if not pc._baseItem.data.dontClear then
		pc:clear(enum.color.computer.black)
	end

	if pc._baseItem.data.popup then
		LoadoutUI.drawPopup(pc, player)
	else
		LoadoutUI.drawHeader(pc, player)
		if tab.call then
			tab.call(pc, player)
		else
			error("No tab call for " .. tab.name)
		end
	end

	pc:refresh()
end

---@param pc LibComputerItem
function LoadoutUI.drawEmpty(pc)
	pc:clear(enum.color.computer.black)
	pc:addText(1, 1, PVP_lang.lobby_loadout_header, enum.color.computer.black, enum.color.computer.white)
	pc:addText(1, 3, PVP_lang.lobby_loadout_attract, enum.color.computer.black, enum.color.computer.white)
	pc:refresh()
end

---@param pc LibComputerItem
---@param player Player
function LoadoutUI.drawHeader(pc, player)
	local tabIndex = pc._baseItem.data.tabIndex or 1

	-- button indicators
	pc:addText(1, 1, PVP_lang.lobby_loadout_key_tab_left, enum.color.computer.black, enum.color.computer.green_light)
	pc:addText(
		pc.width,
		1,
		PVP_lang.lobby_loadout_key_tab_right,
		enum.color.computer.black,
		enum.color.computer.green_light
	)

	-- tabs
	for i, tab in pairs(LoadoutUI.tabs) do
		local color = enum.color.computer.white
		local bgColor = enum.color.computer.black

		if i == tabIndex then
			color = enum.color.computer.green_light
			bgColor = enum.color.computer.black
		end

		local x = 3 + (i - 1) * 10
		pc:addText(x, 1, tab.name, bgColor, color, false)
	end
end

---@param pc LibComputerItem
---@param player Player
function LoadoutUI.loadoutTab(pc, player)
	local loadoutData = Loadouts.getPlayerLoadouts(player)
	local selectionMode = pc._baseItem.data.selectionMode or "loadoutList"
	local selectionIndex = pc._baseItem.data.selectionIndex or 1
	local currentLoadoutId = pc._baseItem.data.currentLoadoutId
	local loadoutSlots = player.data.unlocks.loadoutSlots or 1
	local newLoadoutButtonPresent = false
	-- loadout list

	local y = 3
	-- loadout tab: select loadout
	if selectionMode == "loadoutList" then
		pc._baseItem.data.selectionMode = "loadoutList"
		local loadoutIndex = 1
		for _, loadout in pairs(loadoutData) do
			pc:addText(
				1,
				y,
				loadout.name,
				enum.color.computer.black,
				selectionIndex == loadoutIndex and enum.color.computer.green_light or enum.color.computer.white,
				false
			)
			y = y + 1
			loadoutIndex = loadoutIndex + 1
		end

		if loadoutIndex <= loadoutSlots then
			pc:addText(
				1,
				y,
				PVP_lang.lobby_loadout_new_loadout,
				enum.color.computer.black,
				selectionIndex == loadoutIndex and enum.color.computer.green_light or enum.color.computer.blue_light,
				false
			)

			newLoadoutButtonPresent = true
		else
			pc:addText(
				1,
				y,
				PVP_lang.lobby_loadout_no_slots,
				enum.color.computer.black,
				enum.color.computer.red_light,
				false
			)
		end

		pc._baseItem.data.maxSelectionIndex = dictLength(loadoutData) + (newLoadoutButtonPresent and 1 or 0)

		-- select loadout
		pc._baseItem.data.currentAction = function(pc, player)
			local loadoutIndex = 1
			for loadoutId, _ in pairs(loadoutData) do
				if selectionIndex == loadoutIndex then
					-- swap to loadout edit
					pc._baseItem.data.selectionMode = "loadoutEdit"
					pc._baseItem.data.currentLoadoutId = loadoutId
					pc._baseItem.data.selectionIndex = 1
					LoadoutUI.draw(pc, player)
					return
				end
				loadoutIndex = loadoutIndex + 1
			end

			-- new loadout
			if selectionIndex == loadoutIndex then
				-- swap to loadout name input
				pc._baseItem.data.selectionMode = "loadoutNameInput"
				pc._baseItem.data.currentLoadoutId = nil
				pc._baseItem.data.selectionIndex = 1
				LoadoutUI.draw(pc, player)
			end
		end

		-- footer
		pc:addTextArray(
			1,
			pc.height - 3,
			PVP_lang.lobby_loadout_loadout_select_tip_lines,
			enum.color.computer.black,
			enum.color.computer.white
		)

		-- loadout tab: loadout edit
	elseif selectionMode == "loadoutEdit" then
		local loadout = loadoutData[currentLoadoutId]

		if not loadout then
			-- invalid loadout selected, fallback to loadout list
			pc._baseItem.data.selectionMode = "loadoutList"
			LoadoutUI.draw(pc, player)
			return
		end

		pc._baseItem.data.maxSelectionIndex = 10
		pc:addText(
			1,
			y,
			string.format(PVP_lang.lobby_loadout_edit_loadout_header, loadout.name),
			enum.color.computer.black,
			enum.color.computer.white,
			false
		)
		pc:addText(
			30,
			8,
			pc._baseItem.data.saveState or "",
			enum.color.computer.black,
			pc._baseItem.data.saveStateColor or enum.color.computer.gray_light,
			false
		)

		y = y + 2

		-- draw vertical list of items
		for i = 0, 9 do
			local item = loadout.items[i]
			local itemData = ItemManager.getItem(item)
			local itemCost = PointValues.get(item)
			local itemName = itemData and itemData.name or PVP_lang.lobby_loadout_edit_loadout_empty_slot
			pc:addText(
				1,
				y,
				string.format(
					PVP_lang.lobby_loadout_edit_loadout_item_cost_format,
					itemCost == 0 and PVP_lang.lobby_loadout_edit_loadout_empty_slot_cost or itemCost,
					itemName
				),
				enum.color.computer.black,
				selectionIndex == i + 1 and enum.color.computer.green_light or enum.color.computer.white,
				false
			)
			y = y + 1
		end

		-- draw inventory slots
		local slotX = 2
		local slotY = y + 2
		local slotWidth = 11
		local slotHeight = 3

		for i = 0, 4 do
			pc:addText(slotX, slotY - 1, tostring(i + 1), enum.color.computer.black, enum.color.computer.white, false)
			pc:drawRect(slotX, slotY, slotWidth, slotHeight, enum.color.computer.dark_gray)

			local topLoadoutItem = loadout.items[i * 2]
			local bottomLoadoutItem = loadout.items[i * 2 + 1]

			local topItemName = topLoadoutItem and ItemManager.getItem(topLoadoutItem).name
				or PVP_lang.lobby_loadout_edit_loadout_empty_slot
			local bottomItemName = bottomLoadoutItem and ItemManager.getItem(bottomLoadoutItem).name
				or PVP_lang.lobby_loadout_edit_loadout_empty_slot

			pc:addText(
				slotX + 1,
				slotY,
				topItemName:sub(1, slotWidth - 2),
				enum.color.computer.dark_gray,
				selectionIndex - 1 == i * 2 and enum.color.computer.green_light or enum.color.computer.white
			)
			pc:addText(
				slotX + 1,
				slotY + 1,
				bottomItemName:sub(1, slotWidth - 2),
				enum.color.computer.dark_gray,
				selectionIndex - 1 == i * 2 + 1 and enum.color.computer.green_light or enum.color.computer.white
			)

			slotX = slotX + slotWidth + 1
		end

		-- calculate loadout cost
		local loadoutCost = PointValues.getLoadoutPoints(loadout.items)
		local totalCost = PointValues.totalCost

		pc:bigFont(
			30,
			9,
			string.format(PVP_lang.lobby_loadout_edit_loadout_loadout_cost_format, loadoutCost, totalCost),
			totalCost - loadoutCost >= 0 and enum.color.computer.green_light or enum.color.computer.red_light
		)

		pc._baseItem.data.currentAction = function(pc, player)
			local currentSlot = pc._baseItem.data.selectionIndex - 1

			if currentSlot < 0 then
				pc._baseItem.data.selectionMode = "loadoutList"
				LoadoutUI.draw(pc, player)
				return
			end

			local currentLoadout = loadoutData[currentLoadoutId]

			if not currentLoadout then
				pc._baseItem.data.selectionMode = "loadoutList"
				LoadoutUI.draw(pc, player)
				return
			end

			pc._baseItem.data.selectionMode = "loadoutItems"
			pc._baseItem.data.selectionIndex = 1
			pc._baseItem.data.dontClear = true
			pc._baseItem.data.currentSlot = currentSlot
			LoadoutUI.draw(pc, player)
		end

		-- footer
		pc:addTextArray(
			1,
			pc.height - 1,
			PVP_lang.lobby_loadout_edit_loadout_tip_lines,
			enum.color.computer.black,
			enum.color.computer.white,
			false
		)

		-- loadout tab: slot item selection
	elseif selectionMode == "loadoutItems" then
		-- calculate loadout cost
		local loadout = loadoutData[currentLoadoutId]
		if not loadout then
			pc._baseItem.data.selectionMode = "loadoutList"
			LoadoutUI.draw(pc, player)
			return
		end

		local loadoutCost = PointValues.getLoadoutPoints(loadout.items)
		local totalCost = PointValues.totalCost
		local currentSlotCost = PointValues.get(loadout.items[pc._baseItem.data.currentSlot])

		pc:drawRect(42, 3, 20, 20, enum.color.computer.dark_gray)

		if pc._baseItem.data.currentSlot then
			pc:addText(
				42,
				3,
				string.format(PVP_lang.lobby_loadout_edit_loadout_slot_header, pc._baseItem.data.currentSlot),
				enum.color.computer.dark_gray,
				enum.color.computer.white
			)
		else
			pc:addText(
				42,
				3,
				PVP_lang.lobby_loadout_edit_loadout_slot_header_fallback,
				enum.color.computer.dark_gray,
				enum.color.computer.white
			)
		end

		y = 5
		local unlockedItems = player.data.unlocks.item or {}
		local shownItemCount = 1

		pc:addText(
			43,
			4,
			string.format(
				PVP_lang.lobby_loadout_edit_loadout_item_cost_format,
				PVP_lang.lobby_loadout_edit_loadout_empty_slot_cost,
				PVP_lang.lobby_loadout_edit_loadout_empty_slot
			),
			enum.color.computer.dark_gray,
			selectionIndex == 1 and enum.color.computer.green_light or enum.color.computer.white
		)

		if selectionIndex == 1 then
			pc._baseItem.data.currentSelectedItem = nil
		end

		for itemId, _ in pairs(unlockedItems) do
			local item = ItemManager.getItem(itemId)
			local slotIndex = pc._baseItem.data.currentSlot
			if item and ((item.isWeapon and slotIndex < 2) or (not item.isWeapon and slotIndex >= 2)) then
				local itemCost = PointValues.get(itemId)
				pc:addText(
					43,
					y,
					string.format(
						PVP_lang.lobby_loadout_edit_loadout_item_cost_format,
						itemCost == 0 and PVP_lang.lobby_loadout_edit_loadout_empty_slot_cost or itemCost,
						item.name
					),
					enum.color.computer.dark_gray,
					selectionIndex == y - 3 and enum.color.computer.green_light
						or itemCost + loadoutCost - currentSlotCost <= totalCost and enum.color.computer.white
						or enum.color.computer.gray_light,
					false
				)

				if selectionIndex == y - 3 then
					pc._baseItem.data.currentSelectedItem = itemId
				end

				y = y + 1
				shownItemCount = shownItemCount + 1
			end
		end

		pc._baseItem.data.maxSelectionIndex = shownItemCount

		pc._baseItem.data.currentAction = function(pc, player)
			local selectionItem = pc._baseItem.data.currentSelectedItem

			local currentLoadoutId = pc._baseItem.data.currentLoadoutId
			local loadout = loadoutData[currentLoadoutId]

			if selectionItem then
				local currentSlot = pc._baseItem.data.currentSlot

				if not loadout then
					pc._baseItem.data.selectionMode = "loadoutList"
					pc._baseItem.data.dontClear = false
					LoadoutUI.draw(pc, player)
					return
				end

				loadout.items[currentSlot] = selectionItem
				pc._baseItem.data.selectionItem = nil
				pc._baseItem.data.selectionMode = "loadoutEdit"
				pc._baseItem.data.selectionIndex = currentSlot + 1
				pc._baseItem.data.dontClear = false

				local loadoutCost = PointValues.getLoadoutPoints(loadout.items)
				local totalCost = PointValues.totalCost

				if loadoutCost > totalCost then
					pc._baseItem.data.saveState = PVP_lang.lobby_loadout_edit_loadout_save_over_budget_error
					pc._baseItem.data.saveStateColor = enum.color.computer.red_light
				else
					pc._baseItem.data.saveState = PVP_lang.lobby_loadout_edit_loadout_save_success
					pc._baseItem.data.saveStateColor = enum.color.computer.green_light
					Loadouts.savePlayerLoadouts(player)
				end

				LoadoutUI.draw(pc, player)
			elseif selectionIndex == 1 then
				local loadout = loadoutData[currentLoadoutId]
				if not loadout then
					pc._baseItem.data.selectionMode = "loadoutList"
					pc._baseItem.data.dontClear = false
					LoadoutUI.draw(pc, player)
					return
				end

				loadout.items[pc._baseItem.data.currentSlot] = nil
				pc._baseItem.data.selectionMode = "loadoutEdit"
				pc._baseItem.data.selectionIndex = (pc._baseItem.data.currentSlot or 0) + 1
				pc._baseItem.data.dontClear = false

				local loadoutCost = PointValues.getLoadoutPoints(loadout.items)
				local totalCost = PointValues.totalCost

				if loadoutCost > totalCost then
					pc._baseItem.data.saveState = PVP_lang.lobby_loadout_edit_loadout_save_over_budget_error
					pc._baseItem.data.saveStateColor = enum.color.computer.red_light
				else
					pc._baseItem.data.saveState = PVP_lang.lobby_loadout_edit_loadout_save_success
					pc._baseItem.data.saveStateColor = enum.color.computer.green_light
					Loadouts.savePlayerLoadouts(player)
				end

				LoadoutUI.draw(pc, player)
			end
		end

		pc:addTextArray(
			1,
			pc.height - 1,
			PVP_lang.lobby_loadout_edit_loadout_slot_tip_lines,
			nil,
			enum.color.computer.white
		)

		-- loadout tab: new loadout name input
	elseif pc._baseItem.data.selectionMode == "loadoutNameInput" then
		pc:addText(
			1,
			3,
			PVP_lang.lobby_loadout_new_loadout_prompt,
			enum.color.computer.black,
			enum.color.computer.white
		)

		pc._baseItem.data.inputText = pc._baseItem.data.inputText or ""
		pc:addText(
			1,
			5,
			pc._baseItem.data.inputText or "type!",
			enum.color.computer.black,
			pc._baseItem.data.inputText == nil and enum.color.computer.dark_gray or enum.color.computer.white,
			false
		)

		pc._baseItem.data.currentAction = function(pc, player)
			---@type string
			local loadoutName = pc._baseItem.data.inputText

			local invalidMatches = {
				"DROP",
				"DELETE",
				"UPDATE",
				"INSERT",
				"SELECT",
			}

			if loadoutName and loadoutName:len() > 0 then
				for _, match in pairs(invalidMatches) do
					if loadoutName:upper():find(match) then
						pc._baseItem.data.dontClear = true
						pc._baseItem.data.popup = PVP_lang.lobby_loadout_new_loadout_sql_injection_error
						LoadoutUI.draw(pc, player)
						return
					end
				end

				local loadoutId = Loadouts.createLoadout(player, loadoutName)
				Loadouts.loadPlayer(player)
				pc._baseItem.data.selectionMode = "loadoutEdit"
				pc._baseItem.data.currentLoadoutId = loadoutId
				pc._baseItem.data.selectionIndex = 1
				pc._baseItem.data.dontClear = false
				LoadoutUI.draw(pc, player)
				return
			end

			pc._baseItem.data.dontClear = true
			pc._baseItem.data.popup = PVP_lang.lobby_loadout_new_loadout_invalid_name_error
			LoadoutUI.draw(pc, player)
		end
	end
end

-- ---@param pc LibComputerItem
-- ---@param player Player
-- function LoadoutUI.posesTab(pc, player)
-- 	pc:addText(1, 3, "Poses | Coming soon!", enum.color.computer.black, enum.color.computer.white, false)
-- end

-- ---@param pc LibComputerItem
-- ---@param player Player
-- function LoadoutUI.emotesTab(pc, player)
-- 	pc:addText(1, 3, "Emotes | Coming soon!", enum.color.computer.black, enum.color.computer.white, false)
-- end

-- ---@param pc LibComputerItem
-- ---@param player Player
-- function LoadoutUI.hatsTab(pc, player)
-- 	pc:addText(1, 3, "Hats | Coming soon!", enum.color.computer.black, enum.color.computer.white, false)
-- end

---@param pc LibComputerItem
---@param player Player
function LoadoutUI.passTab(pc, player)
	pc:addText(1, 3, "JPXS Pass", enum.color.computer.black, enum.color.computer.white)
	pc:addText(25, 3, "JPXS Pass +", enum.color.computer.black, enum.color.computer.white)

	local hasPass = player.data.db.supportLevel or 0 > 2

	local scrollIndex = pc._baseItem.data.selectionIndex or 1
	pc._baseItem.data.maxSelectionIndex = 100
	local itemsOnScreen = 5
	local itemUnlocks = Unlocks.getItemUnlocks()
	local blockHeight = 3

	---@type {[integer]: string[]}
	local passItems = {}

	for _, item in pairs(itemUnlocks) do
		local unlockAt = item.unlockAt
		local itemId = item.id

		passItems[unlockAt] = passItems[unlockAt] or {}
		table.insert(passItems[unlockAt], itemId)
	end

	for i = scrollIndex, scrollIndex + itemsOnScreen do
		local items = passItems[i]

		local y = 5 + (i - scrollIndex) * blockHeight
		pc:addText(1, y, string.char(0xaf):rep(20), enum.color.computer.black, enum.color.computer.white)
		pc:addText(
			1,
			y + 1,
			tostring(i),
			enum.color.computer.black,
			player.data.db.rank >= i and enum.color.computer.green_light or enum.color.computer.white
		)

		if not items then
			goto continue
		end

		for j, itemId in pairs(items) do
			local item = ItemManager.getItem(itemId)
			if item then
				pc:addText(5, y + j, item.name, enum.color.computer.black, enum.color.computer.white)
			end
		end

		::continue::
	end

	local color = hasPass and enum.color.computer.cyan_light or enum.color.computer.gray_light
	for i = scrollIndex, scrollIndex + itemsOnScreen do
		local y = 5 + (i - scrollIndex) * blockHeight
		pc:addText(25, y, string.char(0xaf):rep(20), enum.color.computer.black, color)

		::continue::
	end
end

---@param pc LibComputerItem
---@param player Player
function LoadoutUI.drawPopup(pc, player)
	local popup = pc._baseItem.data.popup
	local popupX = 10
	local popupY = 10
	local popupWidth = pc.width - 20
	local popupHeight = 3

	pc:drawRect(popupX, popupY, popupWidth, popupHeight, enum.color.computer.dark_gray)
	local lines = string.split(popup, "\n")

	for i, line in pairs(lines) do
		pc:addText(popupX + 1, popupY + i, line, enum.color.computer.dark_gray, enum.color.computer.white, false)
	end

	pc._baseItem.data.popupTime = (pc._baseItem.data.popupTime or 8) - 1

	pc._baseItem.data.currentAction = function(pc, player)
		pc._baseItem.data.popup = nil
		pc._baseItem.data.popupTime = nil
		pc._baseItem.data.dontClear = false
		LoadoutUI.draw(pc, player)
	end

	if pc._baseItem.data.popupTime <= 0 then
		pc._baseItem.data.popup = nil
		pc._baseItem.data.popupTime = nil
		pc._baseItem.data.dontClear = false
		LoadoutUI.draw(pc, player)
	end
end

LoadoutUI.tabs = {
	{
		name = PVP_lang.lobby_loadout_tab_loadout,
		call = LoadoutUI.loadoutTab,
	},
	-- {
	-- 	name = "Poses",
	-- 	call = LoadoutUI.posesTab,
	-- },
	-- {
	-- 	name = "Emotes",
	-- 	call = LoadoutUI.emotesTab,
	-- },
	-- {
	-- 	name = "Hats",
	-- 	call = LoadoutUI.hatsTab,
	-- },
	{
		name = PVP_lang.lobby_loadout_tab_pass,
		call = LoadoutUI.passTab,
	},
}

---@param player Player
---@param computer Item
---@param key string
hook.add("PlayerComputerInputPress", "LoadoutUI", function(player, computer, key)
	local pc = LibComputerItem.getFromBaseItem(computer)

	if not pc._baseItem.data.computerId or not pc._baseItem.data.computerId:startsWith("loadout") then
		return
	end

	if pc._baseItem.data.selectionMode and pc._baseItem.data.selectionMode == "loadoutNameInput" then
		if key:lower():match("arrow") then
			return
		end

		if key:lower() == "backspace" then
			pc._baseItem.data.inputText = pc._baseItem.data.inputText:sub(1, -2)
			return
		end

		if key:lower() == "enter" then
			pc._baseItem.data.currentAction(pc, player)
			return
		end

		if key:lower() == "space" then
			key = " "
		end

		if pc._baseItem.data.inputText and #pc._baseItem.data.inputText < 20 then
			pc._baseItem.data.inputText = pc._baseItem.data.inputText .. key
		end

		LoadoutUI.draw(pc, player)
	else
		if key == "q" then
			local tabIndex = pc._baseItem.data.tabIndex or 1
			tabIndex = tabIndex - 1
			if tabIndex < 1 then
				tabIndex = #LoadoutUI.tabs
			end
			pc._baseItem.data.tabIndex = tabIndex
			LoadoutUI.draw(pc, player)
		elseif key == "e" then
			local tabIndex = pc._baseItem.data.tabIndex or 1
			tabIndex = tabIndex + 1
			if tabIndex > #LoadoutUI.tabs then
				tabIndex = 1
			end
			pc._baseItem.data.tabIndex = tabIndex
			LoadoutUI.draw(pc, player)
		elseif ComputerControls.isUp(key) then
			local selectionIndex = pc._baseItem.data.selectionIndex or 1
			local maxSelectionIndex = pc._baseItem.data.maxSelectionIndex
			selectionIndex = selectionIndex - 1
			if selectionIndex < 1 then
				selectionIndex = 1
			end

			if maxSelectionIndex and selectionIndex > maxSelectionIndex then
				selectionIndex = maxSelectionIndex
			end

			pc._baseItem.data.selectionIndex = selectionIndex
			LoadoutUI.draw(pc, player)
		elseif ComputerControls.isDown(key) then
			local selectionIndex = pc._baseItem.data.selectionIndex or 1
			local maxSelectionIndex = pc._baseItem.data.maxSelectionIndex
			selectionIndex = selectionIndex + 1
			if selectionIndex > maxSelectionIndex then
				selectionIndex = maxSelectionIndex
			end

			pc._baseItem.data.selectionIndex = selectionIndex
			LoadoutUI.draw(pc, player)
		elseif ComputerControls.isInteract(key) then
			if pc._baseItem.data.currentAction then
				pc._baseItem.data.currentAction(pc, player)
			end
		elseif ComputerControls.isBack(key) then
			if pc._baseItem.data.selectionMode == "loadoutItems" then
				pc._baseItem.data.selectionMode = "loadoutEdit"
				pc._baseItem.data.dontClear = false
				LoadoutUI.draw(pc, player)
			elseif pc._baseItem.data.selectionMode == "loadoutEdit" then
				pc._baseItem.data.selectionMode = "loadoutList"
				pc._baseItem.data.dontClear = false
				LoadoutUI.draw(pc, player)
			end
		elseif key == "k" then
			if pc._baseItem.data.selectionMode == "loadoutList" then
				local loadoutData = Loadouts.getPlayerLoadouts(player)
				local selectionIndex = pc._baseItem.data.selectionIndex or 1
				local loadoutIndex = 1
				for loadoutId, _ in pairs(loadoutData) do
					if loadoutIndex == selectionIndex then
						Loadouts.deleteLoadout(player, loadoutId)
						Loadouts.loadPlayer(player)
						pc._baseItem.data.dontClear = true
						pc._baseItem.data.popup = "Loadout deleted"
						LoadoutUI.draw(pc, player)
						return
					end
					loadoutIndex = loadoutIndex + 1
				end
			end
		end
	end
end)

return LoadoutUI
