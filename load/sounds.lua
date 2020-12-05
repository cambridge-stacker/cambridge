sounds = {
	blocks = {
		I = love.audio.newSource("res/se/piece_i.wav", "static"),
		J = love.audio.newSource("res/se/piece_j.wav", "static"),
		L = love.audio.newSource("res/se/piece_l.wav", "static"),
		O = love.audio.newSource("res/se/piece_o.wav", "static"),
		S = love.audio.newSource("res/se/piece_s.wav", "static"),
		T = love.audio.newSource("res/se/piece_t.wav", "static"),
		Z = love.audio.newSource("res/se/piece_z.wav", "static")
	},
	move = love.audio.newSource("res/se/move.wav", "static"),
	bottom = love.audio.newSource("res/se/bottom.wav", "static"),
	cursor = love.audio.newSource("res/se/cursor.wav", "static"),
	cursor_lr = love.audio.newSource("res/se/cursor_lr.wav", "static"),
	main_decide = love.audio.newSource("res/se/main_decide.wav", "static"),
	mode_decide = love.audio.newSource("res/se/mode_decide.wav", "static"),
	lock = love.audio.newSource("res/se/lock.wav", "static"),
	hold = love.audio.newSource("res/se/hold.wav", "static"),
	erase = love.audio.newSource("res/se/erase.wav", "static"),
	fall = love.audio.newSource("res/se/fall.wav", "static"),
	ready = love.audio.newSource("res/se/ready.wav", "static"),
	go = love.audio.newSource("res/se/go.wav", "static"),
}

function playSE(sound, subsound)
	if subsound == nil then
		sounds[sound]:setVolume(0.5)
		if sounds[sound]:isPlaying() then
			sounds[sound]:stop()
		end
		sounds[sound]:play()
	else
		sounds[sound][subsound]:setVolume(1)
		if sounds[sound][subsound]:isPlaying() then
			sounds[sound][subsound]:stop()
		end
		sounds[sound][subsound]:play()
	end
end

function playSEOnce(sound, subsound)
	if subsound == nil then
		sounds[sound]:setVolume(0.5)
		if sounds[sound]:isPlaying() then
			return
		end
		sounds[sound]:play()
	else
		sounds[sound][subsound]:setVolume(0.5)
		if sounds[sound][subsound]:isPlaying() then
			return
		end
		sounds[sound][subsound]:play()
	end
end