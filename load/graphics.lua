backgrounds = {
	[0] = love.graphics.newImage("res/backgrounds/0-quantum-foam.png"),
	love.graphics.newImage("res/backgrounds/100-big-bang.png"),
	love.graphics.newImage("res/backgrounds/200-spiral-galaxy.png"),
	love.graphics.newImage("res/backgrounds/300-sun-and-dust.png"),
	love.graphics.newImage("res/backgrounds/400-earth-and-moon.png"),
	love.graphics.newImage("res/backgrounds/500-cambrian-explosion.png"),
	love.graphics.newImage("res/backgrounds/600-dinosaurs.png"),
	love.graphics.newImage("res/backgrounds/700-asteroid.png"),
	love.graphics.newImage("res/backgrounds/800-human-fire.png"),
	love.graphics.newImage("res/backgrounds/900-early-civilization.png"),
	love.graphics.newImage("res/backgrounds/1000-vikings.png"),
	love.graphics.newImage("res/backgrounds/1100-crusades.png"),
	love.graphics.newImage("res/backgrounds/1200-genghis-khan.png"),
	love.graphics.newImage("res/backgrounds/1300-black-death.png"),
	love.graphics.newImage("res/backgrounds/1400-columbus-discovery.png"),
	love.graphics.newImage("res/backgrounds/1500-aztecas.png"),
	love.graphics.newImage("res/backgrounds/1600-telescope.png"),
	love.graphics.newImage("res/backgrounds/1700-american-revolution.png"),
	love.graphics.newImage("res/backgrounds/1800-railways.png"),
	love.graphics.newImage("res/backgrounds/1900-world-wide-web.png"),
	title = love.graphics.newImage("res/backgrounds/title_v0.1.png"),
	input_config = love.graphics.newImage("res/backgrounds/options-pcb.png"),
	game_config = love.graphics.newImage("res/backgrounds/options-gears.png"),
}

blocks = {
	["2tie"] = {
		R = love.graphics.newImage("res/img/s1.png"),
		O = love.graphics.newImage("res/img/s3.png"),
		Y = love.graphics.newImage("res/img/s7.png"),
		G = love.graphics.newImage("res/img/s6.png"),
		C = love.graphics.newImage("res/img/s2.png"),
		B = love.graphics.newImage("res/img/s4.png"),
		M = love.graphics.newImage("res/img/s5.png"),
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
		X = love.graphics.newImage("res/img/bone.png"),
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
	},
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
}