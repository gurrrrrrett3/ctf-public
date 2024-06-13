---@class Enum
enum = {}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound
enum.sound = {}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.misc
enum.sound.misc = {
	glass_break = 25,
	whistle = 47,
	explosion = 48,
}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon
enum.sound.weapon = {
	mag_load = 39,
	shell_bounce = 40,
}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.ricochet
enum.sound.weapon.ricochet = { 11, 12, 13, 14, 15, 16, 17, 18 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.bullet
enum.sound.weapon.bullet = {
	hit_body1 = 21,
	hit_body2 = 22,
	hit_metal1 = 23,
	hit_metal2 = 24,
}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.ak47
enum.sound.weapon.ak47 = { 71, 72, 73, 74, 75, 76 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.m16
enum.sound.weapon.m16 = { 77, 78, 79, 80, 81, 82 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.mp5
enum.sound.weapon.mp5 = { 83, 84, 85, 86, 87, 88 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.uzi
enum.sound.weapon.uzi = { 89, 90, 91, 92, 93, 94 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.weapon.pistol
enum.sound.weapon.pistol = { 95, 96, 97, 98, 99, 100 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.computer
enum.sound.computer = {
	dialup = 49,
	disk_drive = 50,
}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.phone
enum.sound.phone = {
	ring = 27,
	busy = 38,
}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.phone.buttons
---Sounds in order from 0-9.
enum.sound.phone.buttons = { 28, 29, 30, 31, 32, 33, 34, 35, 36, 37 }

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.vehicle
enum.sound.vehicle = {
	engine = 8,
	drift = 10,
	crash1 = 19,
	crash2 = 20,
	gear_shift = 41,
	helicopter_engine = 42,
	train_engine1 = 43,
	train_engine2 = 44,
	train_engine3 = 45,
	train_engine4 = 46,
}

---@see events.createSound
---@see Item.sound
---@enum Enum.sound.vehicle.train
enum.sound.vehicle.train = { 43, 44, 45, 46 }

---@see items.create
---@enum Enum.item
enum.item = {
	auto_5 = 0,
	ak47 = 1,
	ak47_mag = 2,
	m16 = 3,
	m16_mag = 4,
	magnum = 5,
	magnum_mag = 6,
	mp5 = 7,
	mp5_mag = 8,
	uzi = 9,
	uzi_mag = 10,
	pistol = 11,
	pistol_mag = 12,
	grenade = 13,
	bandage = 14,
	briefcase = 15,
	briefcase_open = 16,
	cash_round = 17,
	cash_world = 18,
	disk_black = 19,
	disk_green = 20,
	disk_blue = 21,
	disk_white = 22,
	disk_gold = 23,
	disk_red = 24,
	phone = 25,
	radio = 26,
	key = 27,
	door = 28,
	paper_world = 29,
	memo_world = 29,
	burger = 30,
	desk = 31,
	lamp = 32,
	phone_pay = 33,
	paper = 34,
	memo = 34,
	soccer_ball = 35,
	rope = 36,
	box = 37,
	plank = 38,
	computer = 39,
	arcade = 40,
	table = 41,
	table_test = 42,
	wall = 43,
	bottle = 44,
	melon = 45,
}

---@see items.create
---@enum Enum.item.disks
enum.item.disks = {
	black = 19,
	green = 20,
	blue = 21,
	white = 22,
	gold = 23,
	red = 24,
}

---@see items.create
---@enum Enum.item.weapons
enum.item.weapons = {
	auto_5 = 0,
	ak47 = 1,
	m16 = 3,
	magnum = 5,
	mp5 = 7,
	uzi = 9,
	pistol = 11,
	grenade = 13,
}

---@see items.create
---@enum Enum.item.ammo
enum.item.ammo = {
	ak47_mag = 2,
	m16_mag = 4,
	magnum_mag = 6,
	mp5_mag = 8,
	uzi_mag = 10,
	pistol_mag = 12,
}

---@see events.createBullet
---@enum Enum.bullet
enum.bullet = {
	ak47 = 0,
	m16 = 1,
	pistols = 2,
	magnum = 3,
}

enum.color = {}

---@see Item.computerSetLineColors
---@enum Enum.color.computer
enum.color.computer = {
	black = 0,
	blue = 1,
	green = 2,
	cyan = 3,
	red = 4,
	magenta = 5,
	brown = 6,
	gray_light = 7,
	dark_gray = 8,
	blue_light = 9,
	green_light = 10,
	cyan_light = 11,
	red_light = 12,
	magenta_light = 13,
	yellow = 14,
	white = 15,
}

---@see Vehicle.color
---@enum Enum.color.vehicle
enum.color.vehicle = {
	black = 0,
	red = 1,
	blue = 2,
	grey = 3,
	white = 4,
	golden = 5,
	broken = 6,
}

---@see Human.suitColor
---@enum Enum.color.shirt
enum.color.shirt = {
	white = 0,
	pink = 1,
	yellow = 2,
	green = 3,
	cyan = 4,
	red = 5,
	black = 9,
	blue = 10,
	green_bright = 11,
}

---@see Human.suitColor
---@enum Enum.color.suit
enum.color.suit = {
	brown = 0,
	black = 1,
	gray = 2,
	turquoise = 3,
	green = 4,
	pink = 5,
	gold = 6,
	white = 7,
	red = 8,
	purple = 9,
	blue = 10,
	gray_dark = 11,
}

---@see Human.tieColor
---@enum Enum.color.tie
enum.color.tie = {
	none = 0,
	green = 1,
	gold = 2,
	red = 3,
	pink = 4,
	dred = 5,
	white = 6,
	gray = 7,
	black = 8,
	cyan = 9,
	purple = 10,
}

---@see Human.hairColor
---@enum Enum.color.hair
enum.color.hair = {
	black = 0,
	brown = 1,
	brown_light = 2,
	orange_light = 3,
	yellow = 4,
	orange = 5,
	gray = 6,
	white = 7,
	blue = 8,
	pink = 9,
	turquoise = 10,
	green = 11,
}

---@see Human.model
---@enum Enum.clothing
enum.clothing = {
	casual = 0,
	suit = 1,
}

---@see Human.necklace
---@enum Enum.clothing.necklace
enum.clothing.necklace = {
	none = 0,
	small = 1,
	big = 2,
}

---@see vehicles.create
---@enum Enum.vehicle
enum.vehicle = {
	town_car = 0,
	town_car_old = 1,
	metro = 2,
	limo = 3,
	turbo = 4,
	turbo_s = 5,
	beamer = 6,
	van = 7,
	van_test = 8,
	minivan = 9,
	truck = 10,
	trailer = 11,
	helicopter = 12,
	train = 13,
	noclip = 14,
	hatchback = 15,
	turbo_test = 16,
}

---@see Human.getRigidBody
---@see Human.getBone
---@enum Enum.body
enum.body = {
	pelvis = 0,
	stomach = 1,
	torso = 2,
	head = 3,
	shoulder_left = 4,
	forearm_left = 5,
	hand_left = 6,
	shoulder_right = 7,
	forearm_right = 8,
	hand_right = 9,
	thigh_left = 10,
	shin_left = 11,
	foot_left = 12,
	thigh_right = 13,
	shin_right = 14,
	foot_right = 15,
}

---@see Human.movementState
---@enum Enum.movement
enum.movement = {
	standing = 0,
	air = 1,
	sliding = 2,
	floating = 3,
	vehicle = 4,
	laying_down = 5,
	straight_legs = 6,
}

---@see Human.movementState
---@enum Enum.input
enum.input = {
	lmb = 2 ^ 0,
	rmb = 2 ^ 1,
	space = 2 ^ 2,
	ctrl = 2 ^ 3,
	shift = 2 ^ 4,
	q = 2 ^ 5,
	e = 2 ^ 11,
	r = 2 ^ 12,
	f = 2 ^ 13,
	del = 2 ^ 18,
	z = 2 ^ 19,
}

---@see corporations
---@enum Enum.corporation
enum.corporation = {
	goldmen = 0,
	monsota = 1,
	oxs = 2,
	nexaco = 3,
	pentacom = 4,
	prodocon = 5,
	megacorp = 6,
	civilian = 17,
}

---@see Server.type
---@enum Enum.gamemode
enum.gamemode = {
	practice = 0,
	driving = 1,
	racing = 2,
	round = 3,
	world = 4,
	eliminator = 5,
	coop = 6,
	versus = 7,
	none = 8,
}

---@see Server.state
---@enum Enum.state
enum.state = {
	idle = 0,
	intermission = 1,
	ingame = 2,
	restarting = 3,
	paused = 4,
}

---@see Player.menuTab
---@enum Enum.menu
enum.menu = {
	none = 0,
	enter_city = 1,
	lobby = 2,
	empty_base = 3,
	car_shop = 9,
	gun_store = 10,
	store = 11,
	bank = 12,
	bank_two = 13,
	weapons_round = 14,
	ammo_round = 15,
	equipment_round = 16,
	vehicles_round = 17,
	stocks_round = 18,
	empty_base_world = 19,
	application_world = 20,
	hiring_world = 22,
	firing_world = 23,
	team_world = 24,
	requisition_world = 25,
}

enum.mission = {}

---@see Mission.location
---@enum Enum.mission.location
enum.mission.location = {
	hondo_park = 0,
	rio_granary = 1,
	burgers = 2,
	kamel_bldg = 3,
	museum = 4,
	mall = 5,
	gas_station = 6,
	red_cube_park = 7,
}

---@see Mission.type
---@enum Enum.mission.type
enum.mission.type = {
	building_acquisition = 0,
	towncar_acquisition = 1,
	trade_sell = 2,
	trade_buy = 3,
	trade_buy_anymeans = 4,
	threeway_buy = 5,
	threeway_buy_anymeans = 6,
	double_disk_sell = 7,
	double_disk_buy = 8,
	double_disk_buy_anymeans = 9,
}
