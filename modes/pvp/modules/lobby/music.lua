local Radio = require("plugins.radio.radio")
local Speaker = require("plugins.libaudio.speaker")
local LibCompiterItem = require("plugins.libcomputer.item")
local LibUtilItem = require("plugins.libutil.item")

---the shitty system that plays music in the lobby
---@class LobbyMusic
local LobbyMusic = {}

LobbyMusic.songs = {

	"Second Wind - Sonic Mvt.",
	"Blood Flow - Knuckles Mvt.",
	"Cyber Space 4-A: Genshi Remix",
	"insaneintherainmusic fragrance of dark coffee",
	"insaneintherainmusic green hill zone",
	"insaneintherainmusic pigstep",
	"insaneintherainmusic rosalina's comet observatory",
	"insaneintherainmusic halo 3 rain",
	"Fortnite | OG (Remix) Lobby Music (C1S6 Battle Pass)",
	-- "Debussy: Clair de Lune - ULTRAKILL Soundtrack",
	"New Super Mario Bros. Soundtrack - Overworld MinecraftMini1009 | Videogame Soundtracks",
	"Take Care (ULTRAKILL: INFINITE HYPERDEATH)",
	"Mujo - Red Mangos",
	"Is your online persona an untamed unfiltered version of yourself?",
	-- "Virtual Tears tokyopill",
	"somewhere between hello and goodbye, there was love 2 star",
	"ariaMATH xaptiox",
	"Something that leads me to you. zphr",
	-- "1553470665499594756 frxgxd",
	"why as soon as we become so close we have to say goodbye snafu",
}

LobbyMusic.currentSong = 1
LobbyMusic.isStopped = false

---@type LibComputerItem
LobbyMusic.pc = nil

---@type Radio
LobbyMusic.radio = Radio.create()

function LobbyMusic.init()
	LobbyMusic.currentSong = math.random(1, #LobbyMusic.songs)
	Radio.createAndSearch(
		LobbyMusic.songs[LobbyMusic.currentSong],
		Vector(1708.59, 50.79, 1269.87),
		orientations.n,
		LobbyMusic.radio
	)

	local pcItem = LibUtilItem.createStaticItem(enum.item.computer, Vector(1720.5, 49.2, 1287), orientations.s, true)
	assert(pcItem, "Failed to create item")
	LobbyMusic.pc = LibCompiterItem.create(pcItem)
end

function LobbyMusic.nextSong()
	if #players.getNonBots() == 0 then
		LobbyMusic.isStopped = true
		print("No players, stopping music")
		return
	end

	-- worst shuffle known to man

	local skipCount = math.random(1, #LobbyMusic.songs)

	LobbyMusic.currentSong = LobbyMusic.currentSong + skipCount
	if LobbyMusic.currentSong > #LobbyMusic.songs then
		LobbyMusic.currentSong = LobbyMusic.currentSong - #LobbyMusic.songs
	end

	LobbyMusic.radio:search(LobbyMusic.songs[LobbyMusic.currentSong])
end

---Updates the pc with current music stats
function LobbyMusic.pcUi()
	local pc = LobbyMusic.pc
	if not pc then
		return
	end

	pc:clear(enum.color.computer.black)

	pc:addText(1, 1, "Currently Playing", enum.color.computer.black, enum.color.computer.white)

	local meta = LobbyMusic.radio.speaker.meta

	if meta.title then
		local scroll = meta.title:len() > pc.width
				and math.floor(server.ticksSinceReset / 20) % (string.len(meta.title) - pc.width + 2)
			or 0
		local title = string.sub(meta.title, scroll, scroll + pc.width - 1)
		pc:addText(1, 3, title, enum.color.computer.black, enum.color.computer.white)
	end

	if meta.author then
		pc:addText(1, 4, "by " .. meta.author, enum.color.computer.black, enum.color.computer.white)
	end

	local duration = meta.duration or 0
	local currentDuration = LobbyMusic.radio.speaker.currentDuration or 0
	local progress = currentDuration / duration

	pc:addText(
		1,
		6,
		string.format("%02d:%02d / %02d:%02d", currentDuration / 60, currentDuration % 60, duration / 60, duration % 60),
		enum.color.computer.black,
		enum.color.computer.white
	)

	pc:drawHLine(1, 7, pc.width, enum.color.computer.dark_gray)
	pc:drawHLine(1, 7, progress * pc.width, enum.color.computer.green_light)

	pc:addTextArray(1, 9, PVP_lang.lobby_music_lines, enum.color.computer.black, enum.color.computer.white)

	pc:refresh()
end

hook.add("Logic", "LobbyMusic", function()
	if LobbyMusic.isStopped then
		if #players.getNonBots() > 0 then
			LobbyMusic.isStopped = false
			LobbyMusic.nextSong()
		else
			return
		end
	end

	if LobbyMusic.radio.speaker and LobbyMusic.radio.speaker.status == Speaker.SPEAKER_STATUS.FINISHED then
		LobbyMusic.nextSong()
	end

	if LobbyMusic.radio.speaker and LobbyMusic.radio.speaker._baseItem then
		LobbyMusic.radio.speaker._baseItem.rot = yawToRotMatrix(server.ticksSinceReset / 100)
	end

	if server.ticksSinceReset % 20 == 0 then
		LobbyMusic.pcUi()
	end
end)

return LobbyMusic
