---@class ComputerControls
local ComputerControls = {}

function ComputerControls.isUp(key)
	return table.contains({ "w", "ArrowUp" }, key)
end

function ComputerControls.isDown(key)
	return table.contains({ "s", "ArrowDown" }, key)
end

function ComputerControls.isLeft(key)
	return table.contains({ "a", "ArrowLeft" }, key)
end

function ComputerControls.isRight(key)
	return table.contains({ "d", "ArrowRight" }, key)
end

function ComputerControls.isInteract(key)
	return table.contains({ "Enter", "Space" }, key)
end

function ComputerControls.isBack(key)
	return table.contains({ "Backspace" }, key)
end

return ComputerControls
