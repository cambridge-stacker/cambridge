backgrounds = {
	[0] = love.graphics.newImage("res/backgrounds/0.png"),
	love.graphics.newImage("res/backgrounds/100.png"),
	love.graphics.newImage("res/backgrounds/200.png"),
	love.graphics.newImage("res/backgrounds/300.png"),
	love.graphics.newImage("res/backgrounds/400.png"),
	love.graphics.newImage("res/backgrounds/500.png"),
	love.graphics.newImage("res/backgrounds/600.png"),
	love.graphics.newImage("res/backgrounds/700.png"),
	love.graphics.newImage("res/backgrounds/800.png"),
	love.graphics.newImage("res/backgrounds/900.png"),
	love.graphics.newImage("res/backgrounds/1000.png"),
	love.graphics.newImage("res/backgrounds/1100.png"),
	love.graphics.newImage("res/backgrounds/1200.png"),
	love.graphics.newImage("res/backgrounds/1300.png"),
	love.graphics.newImage("res/backgrounds/1400.png"),
	love.graphics.newImage("res/backgrounds/1500.png"),
	love.graphics.newImage("res/backgrounds/1600.png"),
	love.graphics.newImage("res/backgrounds/1700.png"),
	love.graphics.newImage("res/backgrounds/1800.png"),
	love.graphics.newImage("res/backgrounds/1900.png"),
	title = love.graphics.newImage("res/backgrounds/title.png"),
	snow = love.graphics.newImage("res/backgrounds/snow.png"),
	input_config = love.graphics.newImage("res/backgrounds/options-input.png"),
	game_config = love.graphics.newImage("res/backgrounds/options-game.png"),
}

-- in order, the colors are:
-- red, orange, yellow, green, cyan, blue
-- magenta (or purple), white, black
-- the next three don't have colors tied to them
-- F is used for lock flash
-- A is a garbage block
-- X is an invisible "block"
-- don't use these for piece colors when making a ruleset
-- all the others are fine to use
blocks = {
	["2tie"] = {
		R = love.graphics.newImage("res/img/s1.png"),
		O = love.graphics.newImage("res/img/s3.png"),
		Y = love.graphics.newImage("res/img/s7.png"),
		G = love.graphics.newImage("res/img/s6.png"),
		C = love.graphics.newImage("res/img/s2.png"),
		B = love.graphics.newImage("res/img/s4.png"),
		M = love.graphics.newImage("res/img/s5.png"),
		W = love.graphics.newImage("res/img/s9.png"),
		D = love.graphics.newImage("res/img/s8.png"),
		F = love.graphics.newImage("res/img/s9.png"),
		A = love.graphics.newImage("res/img/s8.png"),
		X = love.graphics.newImage("res/img/s9.png"),
	},
	["bone"] = {
		R = love.graphics.newImage("res/img/bone.png"),
		O = love.graphics.newImage("res/img/bone.png"),
		Y = love.graphics.newImage("res/img/bone.png"),
		G = love.graphics.newImage("res/img/bone.png"),
		C = love.graphics.newImage("res/img/bone.png"),
		B = love.graphics.newImage("res/img/bone.png"),
		M = love.graphics.newImage("res/img/bone.png"),
		W = love.graphics.newImage("res/img/bone.png"),
		D = love.graphics.newImage("res/img/bone.png"),
		F = love.graphics.newImage("res/img/bone.png"),
		A = love.graphics.newImage("res/img/bone.png"),
		X = love.graphics.newImage("res/img/bone.png"),
	},
	["gem"] = {
		R = love.graphics.newImage("res/img/gem1.png"),
		O = love.graphics.newImage("res/img/gem3.png"),
		Y = love.graphics.newImage("res/img/gem7.png"),
		G = love.graphics.newImage("res/img/gem6.png"),
		C = love.graphics.newImage("res/img/gem2.png"),
		B = love.graphics.newImage("res/img/gem4.png"),
		M = love.graphics.newImage("res/img/gem5.png"),
		W = love.graphics.newImage("res/img/gem9.png"),
		D = love.graphics.newImage("res/img/gem9.png"),
		F = love.graphics.newImage("res/img/gem9.png"),
		A = love.graphics.newImage("res/img/gem9.png"),
		X = love.graphics.newImage("res/img/gem9.png"),
	},
	["square"] = {
		W = love.graphics.newImage("res/img/squares.png"),
		Y = love.graphics.newImage("res/img/squareg.png"),
		F = love.graphics.newImage("res/img/squares.png"),
		X = love.graphics.newImage("res/img/squares.png"),
	}
}

ColourSchemes = {
	Arika = {
		I = "R",
		L = "O",
		J = "B",
		S = "M",
		Z = "G",
		O = "Y",
		T = "C",
	},
	TTC = {
		I = "C",
		L = "O",
		J = "B",
		S = "G",
		Z = "R",
		O = "Y",
		T = "M",
	}
}

for name, blockset in pairs(blocks) do
	for shape, image in pairs(blockset) do
		image:setFilter("nearest")
	end
end

misc_graphics = {
	frame = love.graphics.newImage("res/img/frame.png"),
	ready = love.graphics.newImage("res/img/ready.png"),
	go = love.graphics.newImage("res/img/go.png"),
	select_mode = love.graphics.newImage("res/img/select_mode.png"),
	strike = love.graphics.newImage("res/img/strike.png"),
	santa = love.graphics.newImage("res/img/santa.png")
}