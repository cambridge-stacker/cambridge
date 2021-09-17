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
-- Replace each sound effect string with its love audiosource counterpart, but only if it exists. This lets the game handle missing SFX.
for k,v in pairs(sound_paths) do
	if(type(v) == "table") then
		-- list of subsounds
		for k2,v2 in pairs(v) do
			if(love.filesystem.getInfo(sound_paths[k][k2])) then
				-- this file exists
				sounds[k] = sounds[k] or {}
				sounds[k][k2] = love.audio.newSource(sound_paths[k][k2], "static")
			end
		end
	else
		if(love.filesystem.getInfo(sound_paths[k])) then
			-- this file exists
			sounds[k] = love.audio.newSource(sound_paths[k], "static")
		end
	end
end

function playSE(sound, subsound)
	if sound ~= nil then
		if sounds[sound] then
			if subsound ~= nil then
				if sounds[sound][subsound] then
					sounds[sound][subsound]:setVolume(config.sfx_volume)
					if sounds[sound][subsound]:isPlaying() then
						sounds[sound][subsound]:stop()
					end
					sounds[sound][subsound]:play()
				end
			else
				sounds[sound]:setVolume(config.sfx_volume)
				if sounds[sound]:isPlaying() then
					sounds[sound]:stop()
				end
				sounds[sound]:play()
			end
		end
	end
end

function playSEOnce(sound, subsound)
	if sound ~= nil then
		if sounds[sound] then
			if subsound ~= nil then
				if sounds[sound][subsound] then
					sounds[sound][subsound]:setVolume(config.sfx_volume)
					if sounds[sound][subsound]:isPlaying() then
						return
					end
					sounds[sound][subsound]:play()
				end
			else
				sounds[sound]:setVolume(config.sfx_volume)
				if sounds[sound]:isPlaying() then
					return
				end
				sounds[sound]:play()
			end
		end
	end
end