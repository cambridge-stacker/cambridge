named_backgrounds = {
	"title", "title_no_icon", "title_night",
	"snow", "options_input", "options_game"
}
current_playing_bgs = {}
extended_bgs = {}
image_formats = {".png", ".jpg"}
bgpath = "res/backgrounds/"
dir = love.filesystem.getDirectoryItems(bgpath)

local backgrounds = {}

local function loadExtendedBgs()
	extended_bgs = require("res.backgrounds.extend_section_bg")
end

-- error handling for if there is no extend_section_bg
if pcall(loadExtendedBgs) then end

-- helper method to populate backgrounds
local function createBackgroundIfExists(name, file_name)
	local format_index = 1

	-- see if background is an extension of another background
	if extended_bgs[file_name] ~= nil then
		copy_bg = extended_bgs[file_name]
		copy_bg = copy_bg / 100
		backgrounds[name] = backgrounds[copy_bg]
		return true
	end

	-- try creating image backgrounds
	while format_index <= #image_formats do
		for num, existing_file in pairs(dir) do
			if existing_file == (file_name..image_formats[format_index]) then
				local tempBgPath = bgpath .. file_name .. image_formats[format_index]
				backgrounds[name] = love.graphics.newImage(tempBgPath)
				return true
			end
		end
		format_index = format_index + 1
	end

	-- try creating video background
	if love.filesystem.getInfo(bgpath .. file_name .. ".ogv") then
		for num, existing_file in pairs(dir) do
			if existing_file == (file_name..".ogv") then
				local tempBgPath = bgpath .. file_name .. ".ogv"
				backgrounds[name] = love.graphics.newVideo(
					tempBgPath, {["audio"] = false}
				)
				-- you can set audio to true, but the video will not loop
				-- properly if audio extends beyond video frames
				return true
			end
		end
	end
	return false
end

local function stopOtherBgs(bg)
	if #current_playing_bgs == 0 and bg:typeOf("Video") then
		current_playing_bgs[#current_playing_bgs+1] = bg
	end

	if #current_playing_bgs >= 1 then
		while current_playing_bgs[1] ~= bg and #current_playing_bgs >= 1 do
			current_playing_bgs[1]:pause()
			current_playing_bgs[1]:rewind()
			table.remove(current_playing_bgs, 1)
		end
	end

end

function fetchBackgroundAndLoop(id)
	bg = backgrounds[id]

	if bg:typeOf("Video") and not bg:isPlaying() then
		bg:rewind()
		bg:play()
	end

	stopOtherBgs(bg)

	return bg
end

-- create section backgrounds
local section = 0
while (createBackgroundIfExists(section, section*100)) do
	section = section + 1
end

-- create named backgrounds
local nbgIndex = 1
while nbgIndex <= #named_backgrounds do
	createBackgroundIfExists(
		named_backgrounds[nbgIndex],
		string.gsub(named_backgrounds[nbgIndex], "_", "-")
	)
	nbgIndex = nbgIndex + 1
end

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
	santa = love.graphics.newImage("res/img/santa.png"),
	icon = love.graphics.newImage("res/img/cambridge_transparent.png")
}