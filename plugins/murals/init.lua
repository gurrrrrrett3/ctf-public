---@type Plugin
local plugin = ...
plugin.name = "Murals"
plugin.author = "gart"

local Loader = require("main.loader")

local images = Loader:flatRecursiveLoadImages("plugins/murals/images")

---@type {v: Vector, n: Vector}[]
local bulletsToCreate = {}

---@param folder string
---@return string
function GetRandomMuralFromFolder(folder)
	---@type string[]
	local allowedMurals = {}

	for image, _ in pairs(images) do
		if image:startsWith(folder .. ".") then
			table.insert(allowedMurals, image)
		end
	end

	return allowedMurals[math.random(1, #allowedMurals)]
end

---@param name string
---@param pos Vector
---@param yaw number
---@param maxDim number?
---@param step number?
---@param threshold number?
---@param useHeight boolean?
function QueueMural(name, pos, yaw, maxDim, step, threshold, useHeight)
	if not images[name] then
		return assert(false, "Image not found")
	end

	step = step or 0.1

	local image = images[name]
	local width = image.width
	local height = image.height

	maxDim = maxDim or width

	local scale = maxDim / (useHeight and height or width)

	local x = pos.x
	local y = pos.y
	local z = pos.z

	local dx = math.cos(yaw) * step
	local dz = math.sin(yaw) * step

	local normal = yawToRotMatrix(yaw):forwardUnit()
	local hitCount = 0

	local scaledWidth = width * scale
	local scaledHeight = height * scale

	for iy = 0, scaledHeight - 1 do
		for ix = 0, scaledWidth - 1 do
			local sx = math.floor(ix / scale)
			local sy = math.floor(iy / scale)

			local r, g, b, a = image:getRGBA(sx, sy)
			local l = a == 0 and 1 or ((r * 0.299 + g * 0.587 + b * 0.114) / 255)

			if l < (threshold or 0.5) then
				hitCount = hitCount + 1
				table.insert(bulletsToCreate, {
					v = Vector(x, y, z),
					n = normal,
				})
			end

			x = x + dx
			z = z + dz
		end
		x = pos.x
		y = y - step
		z = pos.z
	end
end

---@param name string
---@param pos Vector
---@param normal Vector
---@param maxDim number?
---@param step number?
---@param threshold number?
---@param useHeight boolean?
function QueueMuralAdv(name, pos, normal, maxDim, step, threshold, useHeight)
	if not images[name] then
		return assert(false, "Image not found")
	end

	step = step or 0.1

	local image = images[name]
	local width = image.width
	local height = image.height

	maxDim = maxDim or width

	local scale = maxDim / (useHeight and height or width)

	local x = pos.x
	local y = pos.y
	local z = pos.z

	local pitch = math.asin(normal.y)
	local yaw = math.atan2(normal.x, normal.z)

	local dx = math.cos(yaw) * step
	local dy = math.sin(pitch) * step
	local dz = math.sin(yaw) * step

	print("pitch", pitch, "yaw", yaw)
	print("dx", dx, "dy", dy, "dz", dz)

	local hitCount = 0

	local scaledWidth = width * scale
	local scaledHeight = height * scale

	for iy = 0, scaledHeight - 1 do
		for ix = 0, scaledWidth - 1 do
			local sx = math.floor(ix / scale)
			local sy = math.floor(iy / scale)

			local r, g, b, a = image:getRGBA(sx, sy)
			local l = a == 0 and 1 or ((r * 0.299 + g * 0.587 + b * 0.114) / 255)

			if l < (threshold or 0.5) then
				hitCount = hitCount + 1
				table.insert(bulletsToCreate, {
					v = Vector(x, y, z),
					n = normal,
				})
			end

			x = x + dx
			y = y + dy
			z = z + dz
		end
		x = pos.x
		y = pos.y
		z = pos.z
	end
end

function BuildQueue()
	for i = 1, #bulletsToCreate do
		local j = math.random(i, #bulletsToCreate)
		bulletsToCreate[i], bulletsToCreate[j] = bulletsToCreate[j], bulletsToCreate[i]
	end

	for i = 1, #bulletsToCreate do
		local bullet = bulletsToCreate[i]
		events.createBulletHit(0, bullet.v, bullet.n)
	end

	local count = #bulletsToCreate

	bulletsToCreate = {}

	return count
end

---@param name string
---@param pos Vector
---@param yaw number
---@param maxWidth number?
---@param step number?
---@param threshold number?
function BuildMural(name, pos, yaw, maxWidth, step, threshold)
	QueueMural(name, pos, yaw, maxWidth, step, threshold)
	BuildQueue()
end

plugin.commands["/mural"] = {
	info = "Build a mural",
	canCall = function(ply)
		return ply.isAdmin
	end,
	call = function(player, human, args)
		if not args[1] then
			player:sendMessage("Usage: /mural <name>")
			return
		end

		if not human then
			player:sendMessage("not spawned in.")
			return
		end

		BuildMural(args[1], player.human.pos:clone(), math.rad(180), nil, 0.05)
	end,
}
