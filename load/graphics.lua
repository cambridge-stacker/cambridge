local image_formats = {"png", "jpg", "bmp", "tga"}
local function loadImageTable(image_table, path_table)
	for k,v in pairs(path_table) do
		if(type(v) == "table") then
			-- list of subimages
			for k2,v2 in pairs(v) do
				for _, v3 in pairs(image_formats) do
					if(love.filesystem.getInfo(v2.."."..v3)) then
						-- this file exists
						image_table[k] = image_table[k] or {}
						image_table[k][k2] = love.graphics.newImage(v2.."."..v3)
						break
					end
				end
				if image_table[k][k2] == nil then
					error(("Image (%s) not found!"):format(v2))
				end
			end
		else
			for _, v2 in pairs(image_formats) do
				if(love.filesystem.getInfo(v.."."..v2)) then
					-- this file exists
					image_table[k] = love.graphics.newImage(v.."."..v2)
					break
				end
			end
			if image_table[k] == nil then
				error(("Image (%s) not found!"):format(v))
			end
		end
	end
end
backgrounds = {}
backgrounds_paths = {
	title = "res/backgrounds/title",
	title_no_icon = "res/backgrounds/title-no-icon",
	title_night = "res/backgrounds/title-night",
	snow = "res/backgrounds/snow",
	input_config = "res/backgrounds/options-input",
	game_config = "res/backgrounds/options-game",
}

local i = 0
local bgpath = "res/backgrounds/%d"
while love.filesystem.getInfo(bgpath:format(i*100)) do
	backgrounds_paths[i] = bgpath:format(i*100)
	i = i + 1
end

loadImageTable(backgrounds, backgrounds_paths)

-- in order, the colors are:
-- red, orange, yellow, green, cyan, blue
-- magenta (or purple), white, black
-- the next three don't have colors tied to them
-- F is used for lock flash
-- A is a garbage block
-- X is an invisible "block"
-- don't use these for piece colors when making a ruleset
-- all the others are fine to use
blocks = {}
blocks_paths = {
	["2tie"] = {
		R = "res/img/s1",
		O = "res/img/s3",
		Y = "res/img/s7",
		G = "res/img/s6",
		C = "res/img/s2",
		B = "res/img/s4",
		M = "res/img/s5",
		W = "res/img/s9",
		D = "res/img/s8",
		F = "res/img/s9",
		A = "res/img/s8",
		X = "res/img/s9",
	},
	["bone"] = {
		R = "res/img/bone",
		O = "res/img/bone",
		Y = "res/img/bone",
		G = "res/img/bone",
		C = "res/img/bone",
		B = "res/img/bone",
		M = "res/img/bone",
		W = "res/img/bone",
		D = "res/img/bone",
		F = "res/img/bone",
		A = "res/img/bone",
		X = "res/img/bone",
	},
	["gem"] = {
		R = "res/img/gem1",
		O = "res/img/gem3",
		Y = "res/img/gem7",
		G = "res/img/gem6",
		C = "res/img/gem2",
		B = "res/img/gem4",
		M = "res/img/gem5",
		W = "res/img/gem9",
		D = "res/img/gem9",
		F = "res/img/gem9",
		A = "res/img/gem9",
		X = "res/img/gem9",
	},
	["square"] = {
		W = "res/img/squares",
		Y = "res/img/squareg",
		F = "res/img/squares",
		X = "res/img/squares",
	}
}

loadImageTable(blocks, blocks_paths)
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

misc_graphics = {}
misc_graphics_paths = {
	frame = "res/img/frame",
	ready = "res/img/ready",
	go = "res/img/go",
	select_mode = "res/img/select_mode",
	strike = "res/img/strike",
	santa = "res/img/santa",
	icon = "res/img/cambridge_transparent"
}
loadImageTable(misc_graphics, misc_graphics_paths)