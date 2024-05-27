sound_paths = {
	blocks = {
		I = "res/se/piece_i.wav",
		J = "res/se/piece_j.wav",
		L = "res/se/piece_l.wav",
		O = "res/se/piece_o.wav",
		S = "res/se/piece_s.wav",
		T = "res/se/piece_t.wav",
		Z = "res/se/piece_z.wav"
	},
	move = "res/se/move.wav",
	rotate = "res/se/rotate.wav",
	kick = "res/se/kick.wav",
	bottom = "res/se/bottom.wav",
	cursor = "res/se/cursor.wav",
	cursor_lr = "res/se/cursor_lr.wav",
	main_decide = "res/se/main_decide.wav",
	menu_cancel = "res/se/menu_cancel.wav",
	mode_decide = "res/se/mode_decide.wav",
	lock = "res/se/lock.wav",
	hold = "res/se/hold.wav",
	erase = {
		single = "res/se/single.wav",
		double = "res/se/double.wav",
		triple = "res/se/triple.wav",
		quad = "res/se/quad.wav"
	},
	error = "res/se/error.wav",
	screenshot = "res/se/screenshot.wav",
	fall = "res/se/fall.wav",
	ready = "res/se/ready.wav",
	go = "res/se/go.wav",
	irs = "res/se/irs.wav",
	ihs = "res/se/ihs.wav",
	bell = "res/se/bell.wav",
	cool = "res/se/cool.wav",
	game_clear = "res/se/game_clear.wav",
	game_over = "res/se/game_over.wav",
	excellent = "res/se/excellent.wav",
	next_section = "res/se/next_section.wav",
	grade_up = "res/se/grade_up.wav",
	-- a secret sound!
	welcome = "res/se/welcomeToCambridge.wav",
}

sounds = {}
sounds_played = {}
buffer_sounds = {}
for k,v in pairs(sound_paths) do
	--a compatibility patch for subsound modding. Missing that was an oversight.
	if(type(v) == "table") then
		sounds[k] = {}
	end
end

-- This supports resource pack system. This shouldn't run every frame.
---@param path string
---@param sound string
---@param subsound any
function loadSound(path, sound, subsound)
	if love.filesystem.getInfo(applied_packs_path..path) then
		path = applied_packs_path..path
	end
	if(love.filesystem.getInfo(path)) then
		-- this file exists
		buffer_sounds[sound] = buffer_sounds[sound] or {}
		local buffer_tbl_ref = buffer_sounds[sound]
		if subsound then
			buffer_sounds[sound][subsound] = {}
			sounds_played[sound] = sounds_played[sound] or {}
			sounds_played[sound][subsound] = 0
			buffer_tbl_ref = buffer_tbl_ref[subsound]
		else
			sounds_played[sound] = 0
		end
		local sound_data = love.sound.newSoundData(path)
		for k3 = 1, config.sound_sources do
			buffer_tbl_ref[k3] = love.audio.newSource(sound_data)
		end
	end
end

---@param sound string
---@param tbl table
function loadSoundsFromTable(sound, tbl)
	for key, value in pairs(tbl) do
		loadSound(value, sound, key)
	end
end

-- Replace each sound effect string with its love audiosource counterpart, but only if it exists. This lets the game handle missing SFX.
function generateSoundTable()
	if config.sound_sources == nil then config.sound_sources = 1 end
	-- buffer_sounds = {}
	for k,v in pairs(sound_paths) do
		if(type(v) == "table") then
			-- list of subsounds
			for k2,v2 in pairs(v) do
				loadSound(v2, k, k2)
			end
		else
			loadSound(v, k)
		end
	end
end

local function playRawSE(audio_source)
	if type(audio_source) == "table" then
		error("Tried to play a table.")
	end
	audio_source:setVolume(config.sfx_volume)
	if audio_source:isPlaying() then
		audio_source:stop()
	end
	audio_source:play()
end

local function playRawSEOnce(audio_source)
	if type(audio_source) == "table" then
		error("Tried to play a table.")
	end
	audio_source:setVolume(config.sfx_volume)
	if audio_source:isPlaying() then
		return
	end
	audio_source:play()
end

function playSE(sound, subsound)
	if config and config.sfx_volume <= 0 then return end
	if sound ~= nil then
		if sounds[sound] then
			if subsound ~= nil then
				if sounds[sound][subsound] then
					playRawSE(sounds[sound][subsound])
					return
				end
			else
				playRawSE(sounds[sound])
				return
			end
		end
	end
	if type(buffer_sounds[sound]) == "table" then
		if subsound ~= nil then
			if type(buffer_sounds[sound][subsound]) == "table" then
				sounds_played[sound][subsound] = sounds_played[sound][subsound] + 1
				local index = Mod1(sounds_played[sound][subsound], config.sound_sources)
				playRawSE(buffer_sounds[sound][subsound][index])
				return
			end
		else
			sounds_played[sound] = sounds_played[sound] + 1
			local index = Mod1(sounds_played[sound], config.sound_sources)
			playRawSE(buffer_sounds[sound][index])
			return
		end
	end
end

function playSEOnce(sound, subsound)
	if config and config.sfx_volume <= 0 then return end
	if sound ~= nil then
		if sounds[sound] then
			if subsound ~= nil then
				if sounds[sound][subsound] then
					playRawSEOnce(sounds[sound][subsound])
					return
				end
			else
				playRawSEOnce(sounds[sound])
				return
			end
		end
	end
	if type(buffer_sounds[sound]) == "table" then
		if subsound ~= nil then
			if type(buffer_sounds[sound][subsound]) == "table" then
				local index = Mod1(sounds_played[sound][subsound], config.sound_sources)
				playRawSEOnce(buffer_sounds[sound][subsound][index])
				return
			end
		else
			local index = Mod1(sounds_played[sound], config.sound_sources)
			playRawSEOnce(buffer_sounds[sound][index])
			return
		end
	end
end