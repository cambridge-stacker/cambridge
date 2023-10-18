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
	screenshot = "res/se/screenshot.wav",
	fall = "res/se/fall.wav",
	ready = "res/se/ready.wav",
	go = "res/se/go.wav",
	irs = "res/se/irs.wav",
	ihs = "res/se/ihs.wav",
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
-- Replace each sound effect string with its love audiosource counterpart, but only if it exists. This lets the game handle missing SFX.
function generateSoundTable()
	if config.sound_sources == nil then config.sound_sources = 1 end
	buffer_sounds = {}
	for k,v in pairs(sound_paths) do
		if(type(v) == "table") then
			-- list of subsounds
			for k2,v2 in pairs(v) do
				local path = v2
				if love.filesystem.getInfo(applied_packs_path..path) then
					path = applied_packs_path..path
				end
				if(love.filesystem.getInfo(path)) then
					-- this file exists
					buffer_sounds[k] = buffer_sounds[k] or {}
					buffer_sounds[k][k2] = {}
					sounds_played[k] = sounds_played[k] or {}
					sounds_played[k][k2] = 0
					local sound_data = love.sound.newSoundData(path)
					for k3 = 1, config.sound_sources do
						buffer_sounds[k][k2][k3] = love.audio.newSource(sound_data)
					end
				end
			end
		else
			local path = v
			if love.filesystem.getInfo(applied_packs_path..path) then
				path = applied_packs_path..path
			end
			if(love.filesystem.getInfo(path)) then
				-- this file exists
				buffer_sounds[k] = {}
				local sound_data = love.sound.newSoundData(path)
				for k2 = 1, config.sound_sources do
					buffer_sounds[k][k2] = love.audio.newSource(sound_data)
				end
				sounds_played[k] = 0
			end
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
	audio_source:setVolume(config.sfx_volume)
	if audio_source:isPlaying() then
		return
	end
	audio_source:play()
end

function playSE(sound, subsound)
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
		if type(buffer_sounds[sound][subsound]) == "table" then
			sounds_played[sound][subsound] = sounds_played[sound][subsound] + 1
			local index = Mod1(sounds_played[sound][subsound], config.sound_sources)
			playRawSE(buffer_sounds[sound][subsound][index])
			return
		end
		sounds_played[sound] = sounds_played[sound] + 1
		local index = Mod1(sounds_played[sound], config.sound_sources)
		playRawSE(buffer_sounds[sound][index])
		return
	end
end

function playSEOnce(sound, subsound)
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
		if type(buffer_sounds[sound][subsound]) == "table" then
			local index = Mod1(sounds_played[sound][subsound], config.sound_sources)
			playRawSEOnce(buffer_sounds[sound][subsound][index])
			return
		end
		local index = Mod1(sounds_played[sound], config.sound_sources)
		playRawSEOnce(buffer_sounds[sound][index])
		return
	end
end