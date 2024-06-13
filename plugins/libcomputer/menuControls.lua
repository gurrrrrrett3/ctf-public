local LibComputerItem = require("plugins.libcomputer.item")
local ComputerControls = require("plugins.libinput.computerControls")

---@class ComputerMenuControls
local ComputerMenuControls = {}

---@param pc LibComputerItem|Item
---@param itemCount integer
function ComputerMenuControls.setItemCount(pc, itemCount)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	pc.data.ComputerMenuControls = pc.data.ComputerMenuControls or {}
	pc.data.ComputerMenuControls.itemCount = itemCount
end

---@param pc LibComputerItem|Item
function ComputerMenuControls.forceInitialize(pc)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	pc.data.ComputerMenuControls = pc.data.ComputerMenuControls or {}
	pc.data.ComputerMenuControls.isMenu = true
	pc.data.selectionIndex = 1
end

---@param pc LibComputerItem|Item
function ComputerMenuControls.initialize(pc)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	if pc.data.ComputerMenuControls then
		return
	end

	ComputerMenuControls.forceInitialize(pc)
end

---@param pc LibComputerItem|Item
function ComputerMenuControls.clear(pc)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	pc.data.ComputerMenuControls = nil
end

---@param pc LibComputerItem|Item
---@return integer
function ComputerMenuControls.getSelectionIndex(pc)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	return pc.data.selectionIndex or 1
end

---@param pc LibComputerItem|Item
---@param index integer
function ComputerMenuControls.setSelectionIndex(pc, index)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	pc.data.selectionIndex = index
end

---@param pc LibComputerItem|Item
---@param func fun(pc: LibComputerItem)
function ComputerMenuControls.onSelect(pc, func)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	pc.data.ComputerMenuControls.onSelect = func
end

---@param pc LibComputerItem|Item
---@param func fun(pc: LibComputerItem)
function ComputerMenuControls.onBack(pc, func)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	pc.data.ComputerMenuControls.onBack = func
end

---@param event 'back'|'select'
---@param pc LibComputerItem|Item
function ComputerMenuControls.run(event, pc)
	if pc.class == "LibComputerItem" then
		pc = pc._baseItem
	end

	local func = ({
		select = pc.data.ComputerMenuControls.onSelect,
		back = pc.data.ComputerMenuControls.onBack,
	})[event]

	return func and func() or nil
end

---@param player Player
---@param pc Item
---@param character string
hook.add("PlayerComputerInputPress", "ComputerMenuControls", function(player, pc, character)
	if not pc.data.ComputerMenuControls or not pc.data.ComputerMenuControls.isMenu then
		return
	end

	local lcpc = LibComputerItem.getFromBaseItem(pc)
	if not lcpc then
		return
	end

	local selectionIndex = pc.data.selectionIndex or 1
	local itemCount = pc.data.ComputerMenuControls.itemCount or 1

	if ComputerControls.isUp(character) then
		if selectionIndex > 1 then
			pc.data.selectionIndex = selectionIndex - 1
		end
	elseif ComputerControls.isDown(character) then
		if selectionIndex < itemCount then
			pc.data.selectionIndex = selectionIndex + 1
		end
	elseif ComputerControls.isBack(character) then
		ComputerMenuControls.run("back", lcpc)
	elseif ComputerControls.isInteract(character) then
		ComputerMenuControls.run("select", lcpc)
	end
end)

return ComputerMenuControls
