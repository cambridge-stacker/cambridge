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
	mode_decide = "res/se/mode_decide.wav",
	lock = "res/se/lock.wav",
	hold = "res/se/hold.wav",
	erase = {
		single = "res/se/single.wav",
		double = "res/se/double.wav",
		triple = "res/se/triple.wav",
		quad = "res/se/quad.wav"
	},
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
-- Replace each sound effect string with its love audiosource counterpart, but only if it exists. This lets the game handle missing SFX.
function generateSoundTable()
	if config.sound_sources == nil then config.sound_sources = 1 end
	sounds = {}
	for k,v in pairs(sound_paths) do
		if(type(v) == "table") then
			-- list of subsounds
			for k2,v2 in pairs(v) do
				if(love.filesystem.getInfo(sound_paths[k][k2])) then
					-- this file exists
					sounds[k] = sounds[k] or {}
					sounds[k][k2] = {}
					sounds_played[k] = sounds_played[k] or {}
					sounds_played[k][k2] = 0
					for k3 = 1, config.sound_sources do
						sounds[k][k2][k3] = love.audio.newSource(sound_paths[k][k2], "static")
					end
				end
			end
		else
			if(love.filesystem.getInfo(sound_paths[k])) then
				-- this file exists
				sounds[k] = {}
				print("path:"..sound_paths[k])
				for k2 = 1, config.sound_sources do
					sounds[k][k2] = love.audio.newSource(sound_paths[k], "static")
				end
				sounds_played[k] = 0
			end
		end
	end
end

function playSE(sound, subsound)
	if sound ~= nil then
		if sounds[sound] then
			if subsound ~= nil then
				sounds_played[sound][subsound] = sounds_played[sound][subsound] + 1
				local index = Mod1(sounds_played[sound][subsound], config.sound_sources)
				local indexed_sound = sounds[sound][subsound][index]
				local compat_sound = sounds[sound][subsound]
				if indexed_sound then
					indexed_sound:setVolume(config.sfx_volume)
					if indexed_sound:isPlaying() then
						indexed_sound:stop()
					end
					indexed_sound:play()
				elseif compat_sound then
					compat_sound:setVolume(config.sfx_volume)
					if compat_sound:isPlaying() then
						compat_sound:stop()
					end
					compat_sound:play()
				end
			else
				sounds_played[sound] = sounds_played[sound] + 1
				local index = Mod1(sounds_played[sound], config.sound_sources)
				local indexed_sound = sounds[sound][index]
				local compat_sound = sounds[sound]
				if indexed_sound then
					indexed_sound:setVolume(config.sfx_volume)
					if indexed_sound:isPlaying() then
						indexed_sound:stop()
					end
					indexed_sound:play()
				elseif compat_sound ~= nil and type(compat_sound) ~= "table" then
					compat_sound:setVolume(config.sfx_volume)
					if compat_sound:isPlaying() then
						compat_sound:stop()
					end
					compat_sound:play()
				end
			end
		end
	end
end

function playSEOnce(sound, subsound)
	if sound ~= nil then
		if sounds[sound] then
			if subsound ~= nil then
				if sounds[sound][subsound][1] then
					if sounds[sound][subsound][1] then
						sounds[sound][subsound][1]:setVolume(config.sfx_volume)
						if sounds[sound][subsound][1]:isPlaying() then
							return
						end
						sounds[sound][subsound][1]:play()
					end
				elseif sounds[sound][subsound] then
					if sounds[sound][subsound] then
						sounds[sound][subsound]:setVolume(config.sfx_volume)
						if sounds[sound][subsound]:isPlaying() then
							return
						end
						sounds[sound][subsound]:play()
					end
				end
			else
				if sounds[sound][1] then
					sounds[sound][1]:setVolume(config.sfx_volume)
					if sounds[sound][1]:isPlaying() then
						return
					end
					sounds[sound][1]:play()
				elseif sounds[sound] ~= nil and type(sounds[sound]) ~= "table" then
					sounds[sound]:setVolume(config.sfx_volume)
					if sounds[sound]:isPlaying() then
						return
					end
					sounds[sound]:play()
				end
			end
		end
	end
end