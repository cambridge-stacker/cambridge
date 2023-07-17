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
	options_input = "res/backgrounds/options-input",
	options_game = "res/backgrounds/options-game",
}
named_backgrounds = {
	"title", "title_no_icon", "title_night",
	"snow", "options_input", "options_game"
}
current_playing_bgs = {}
extended_bgs = {}

local previous_bg_index = 0
local bg_index = 0
local bgpath = "res/backgrounds/%s"
while true do
	local formatted_bgpath = bgpath:format(tostring(bg_index*100))
	for key, value in pairs(image_formats) do
		if love.filesystem.getInfo(formatted_bgpath.."."..value) then
			backgrounds_paths[bg_index] = formatted_bgpath
			bg_index = bg_index + 1
			break
		end
	end
	if previous_bg_index == bg_index then
		break
	end
	previous_bg_index = bg_index
end

local function loadExtendedBgs()
	extended_bgs = require("res.backgrounds.extend_section_bg")
end

-- error handling for if there is no extend_section_bg
if pcall(loadExtendedBgs) then end

-- helper method to populate backgrounds
local function createBackgroundIfExists(name, file_name)
	local formatted_bgpath = bgpath:format(tostring(file_name))

	-- see if background is an extension of another background
	if extended_bgs[file_name] ~= nil then
		copy_bg = extended_bgs[file_name]
		copy_bg = copy_bg / 100
		backgrounds[name] = backgrounds[copy_bg]
		return true
	end

	--loadImageTable already deals with loading images.
	if backgrounds[name] ~= nil then
		return true
	end
	-- try creating video background
	if love.filesystem.getInfo(formatted_bgpath .. ".ogv") then
		local tempBgPath = formatted_bgpath .. ".ogv"
		backgrounds[name] = love.graphics.newVideo(
			tempBgPath, {["audio"] = false}
		)
		-- you can set audio to true, but the video will not loop
		-- properly if audio extends beyond video frames
		return true
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
	local bg = backgrounds[id]

	if bg:typeOf("Video") and not bg:isPlaying() then
		bg:rewind()
		bg:play()
	end

	stopOtherBgs(bg)

	return bg
end

loadImageTable(backgrounds, backgrounds_paths)

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

-- utility function to allow any size background to be used
-- this will stretch the background to 4:3 aspect ratio
function drawBackground(id)
	local bg_object = fetchBackgroundAndLoop(id)
	drawSizeIndependentImage(bg_object, 0, 0, 0, 640, 480)
end