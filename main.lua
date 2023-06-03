function love.load()
	love.graphics.setDefaultFilter("linear", "nearest")
	require "load.fonts"
	love.graphics.setFont(font_3x5_4)
	love.graphics.printf("Please wait...\nLoading...", 160, 160, 320, "center")
	love.graphics.present()
	love.graphics.clear()
	math.randomseed(os.time())
	highscores = {}
	require "load.rpc"
	require "load.graphics"
	require "load.sounds"
	require "load.bgm"
	require "load.save"
	require "load.bigint"
	require "load.version"
	loadSave()
	require "funcs"
	require "scene"

	require "threaded_replay_code"
	
	--config["side_next"] = false
	--config["reverse_rotate"] = true
	--config["das_last_key"] = false
	--config["fullscreen"] = false

		
	-- used for screenshots
	GLOBAL_CANVAS = love.graphics.newCanvas()

	-- init config
	initConfig()

	love.window.setFullscreen(config["fullscreen"])

	-- import custom modules
	initModules()

	loadResourcePacks()

	generateSoundTable()

	-- this is executed after the sound table is generated. why is that is unknown.
	if config.secret then playSE("welcome") end
end
---@param table table
---@param directory string
---@param blacklisted_string string
function recursivelyLoadRequireFileTable(table, directory, blacklisted_string)
	--LOVE 12.0 will warn about require strings having forward slashes in them if this is not done.
	local require_string = string.gsub(directory, "/", ".")
	local list = love.filesystem.getDirectoryItems(directory)
	for index, name in ipairs(list) do
		
		if love.filesystem.getInfo(directory.."/"..name, "directory") then
			table[#table+1] = {name = name, is_directory = true}
			recursivelyLoadRequireFileTable(table[#table], directory.."/"..name, blacklisted_string)
		end
		if name ~= blacklisted_string and name:sub(-4) == ".lua" then
			table[#table+1] = require(require_string.."."..name:sub(1, -5))
			if not (type(table[#table]) == "table" and type(table[#table].__call) == "function") then
				error("Add a return to "..directory.."/"..name..".\nMust be a table with __call function.", 1)
			end
		end
	end
end

local initial_resources
local previous_resources
local previous_selected_packs

function loadResourcePacks()
	previous_resources = {
		backgrounds_paths = deepcopy(backgrounds_paths),
		blocks_paths = deepcopy(blocks_paths),
		misc_graphics_paths = deepcopy(misc_graphics_paths),
		sound_paths = deepcopy(sound_paths),
	}
	if not initial_resources then
		initial_resources = {
			backgrounds_paths = deepcopy(backgrounds_paths),
			blocks_paths = deepcopy(blocks_paths),
			misc_graphics_paths = deepcopy(misc_graphics_paths),
			sound_paths = deepcopy(sound_paths),
		}
		previous_selected_packs = copy(config.resource_packs_applied)
	else
		backgrounds_paths = deepcopy(initial_resources.backgrounds_paths)
		blocks_paths = deepcopy(initial_resources.blocks_paths)
		misc_graphics_paths = deepcopy(initial_resources.misc_graphics_paths)
		sound_paths = deepcopy(initial_resources.sound_paths)
	end
	local valid_resource_packs = {}
	local resource_pack_indexes = {}
    local resource_packs = love.filesystem.getDirectoryItems("resourcepacks")
    for key, value in pairs(resource_packs) do
        if value:sub(-4) == ".zip" and love.filesystem.getInfo("resourcepacks/"..value, "file") then
            valid_resource_packs[key] = value
			resource_pack_indexes[value] = key
        end
    end
	if type(config.resource_packs_applied) == "table" then
		for k, v in pairs(config.resource_packs_applied) do
			if resource_pack_indexes[v] then
				love.filesystem.mount("resourcepacks/"..v, "packs/", true)
			else
				table.remove(config.resource_packs_applied, k)
			end
		end
	end
	local image_formats = {"png", "jpg", "bmp", "tga"}
	local function prefixPathsIfExistsRecursively(paths, prefix, is_images)
		for key, value in pairs(paths) do
			if type(value) == "table" then
				prefixPathsIfExistsRecursively(paths[key], prefix, is_images)
			end
			if is_images then
				for _, v2 in pairs(image_formats) do
					if type(value) == "string" and love.filesystem.getInfo(prefix..value.."."..v2, "file") then
						paths[key] = prefix..value
						break
					end
				end
			else
				if type(value) == "string" and love.filesystem.getInfo(prefix..value, "file") then
					paths[key] = prefix..value
				end
			end
		end
	end
	local function makeDiffTable(left, right)
		local diff_table = {}
		for key, value in pairs(left) do
			if type(value) == "table" then
				diff_table[key] = makeDiffTable(right[key], value)
			elseif value ~= right[key] then
				diff_table[key] = value
			end
		end
		for key, value in pairs(right) do
			if type(value) == "table" then
				diff_table[key] = makeDiffTable(left[key], value)
			elseif value ~= left[key] then
				diff_table[key] = value
			end
		end
		return diff_table
	end
	local image_formats = {"png", "jpg", "bmp", "tga"}
	local function loadImageTableRecursively(image_table, path_table)
		for k,v in pairs(path_table) do
			if type(v) == "table" then
				loadImageTableRecursively(image_table[k], v)
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
	prefixPathsIfExistsRecursively(backgrounds_paths, "packs/", true)
	prefixPathsIfExistsRecursively(blocks_paths, "packs/", true)
	prefixPathsIfExistsRecursively(misc_graphics_paths, "packs/", true)
	prefixPathsIfExistsRecursively(sound_paths, "packs/")
	local bg_diff = makeDiffTable(previous_resources.backgrounds_paths, backgrounds_paths)
	local blocks_diff = makeDiffTable(previous_resources.blocks_paths, blocks_paths)
	local misc_graphics_diff = makeDiffTable(previous_resources.misc_graphics_paths, misc_graphics_paths)
	loadImageTableRecursively(backgrounds, bg_diff)
	loadImageTableRecursively(blocks, blocks_diff)
	loadImageTableRecursively(misc_graphics, misc_graphics_diff)
	if not table.equalvalues(previous_resources.sound_paths, sound_paths) then
		buffer_sounds = {}
		generateSoundTable()
	end
	if type(config.resource_packs_applied) == "table" then
		for k, v in pairs(config.resource_packs_applied) do
			if resource_pack_indexes[v] and not (previous_selected_packs and previous_selected_packs[k] == v) then
				love.filesystem.unmount("resourcepacks/"..v)
			end
		end
	end
	previous_selected_packs = copy(config.resource_packs_applied)
end

---@param reload boolean|nil
function initModules(reload)
	--module reload.
	if reload then
		for key, value in pairs(package.loaded) do
			if string.sub(key, 1, 7) == "tetris." then
				package.loaded[key] = nil
			end
		end
	end
	game_modes = {}
	recursivelyLoadRequireFileTable(game_modes, "tetris/modes", "gamemode.lua")
	-- mode_list = love.filesystem.getDirectoryItems("tetris/modes")
	-- for i=1,#mode_list do
	-- 	if(mode_list[i] ~= "gamemode.lua" and string.sub(mode_list[i], -4) == ".lua") then
	-- 		game_modes[#game_modes+1] = require ("tetris.modes."..string.sub(mode_list[i],1,-5))
	-- 	end
	-- end
	rulesets = {}
	recursivelyLoadRequireFileTable(rulesets, "tetris/rulesets", "ruleset.lua")
	-- rule_list = love.filesystem.getDirectoryItems("tetris/rulesets")
	-- for i=1,#rule_list do
	-- 	if(rule_list[i] ~= "ruleset.lua" and string.sub(rule_list[i], -4) == ".lua") then
	-- 		rulesets[#rulesets+1] = require ("tetris.rulesets."..string.sub(rule_list[i],1,-5))
	-- 	end
	-- end

	--sort mode/rule lists
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(game_modes, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	table.sort(rulesets, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
end

--#region Tetro48's code


---@param tbl table
---@param key_check any
---@return table
local function recursionStringValueExtract(tbl, key_check)
	local result = {}
	for key, value in pairs(tbl) do
		if type(value) == "table" and (key_check == nil or value[key_check]) then
			local recursion_result = recursionStringValueExtract(value, key_check)
			for k2, v2 in pairs(recursion_result) do
				table.insert(result, v2)
			end
		elseif tostring(value) == "Object" then
			table.insert(result, value)
		end
	end
	return result
end

local io_thread

function loadReplayList()
	replays = {}
	replay_tree = {{name = "All"}}
	dict_ref = {}
	loaded_replays = false
	collectgarbage("collect")

	--proper disposal to avoid some memory problems
	if io_thread then
		io_thread:release()
		love.thread.getChannel( 'replay' ):clear()
		love.thread.getChannel( 'loaded_replays' ):clear()
	end

	io_thread = love.thread.newThread( replay_load_code )
	for key, value in pairs(recursionStringValueExtract(game_modes, "is_directory")) do
		dict_ref[value.name] = key + 1
		replay_tree[key + 1] = {name = value.name}
	end
	io_thread:start()
end

is_cursor_visible = true
mouse_idle = 0
TAS_mode = false
frame_steps = 0
loaded_replays = false
local prev_cur_pos_x, prev_cur_pos_y = 0, 0
local system_cursor_type = "arrow"
local screenshot_images = {}

---@param type love.CursorType
function setSystemCursorType(type)
	system_cursor_type = type
end

-- For when you need to convert given coordinate to where it'd be in scaled 640x480 equivalent.
---@param x number
---@param y number
function getScaledPos(x, y)
	local screen_x, screen_y = love.graphics.getDimensions()
	local scale_factor = math.min(screen_x / 640, screen_y / 480)
	return (x - (screen_x - scale_factor * 640) / 2)/scale_factor, (y - (screen_y - scale_factor * 480) / 2)/scale_factor
end


---@param x number
---@param y number
---@param w number
---@param h number
---@return integer
function CursorHighlight(x,y,w,h)
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if mouse_idle > 2 or config.visualsettings.cursor_highlight ~= 1 then
		return 1
	end
	if mouse_x > x and mouse_x < x+w and mouse_y > y and mouse_y < y+h then
		setSystemCursorType("hand")
		return 0
	else
		return 1
	end
end
--Interpolates in a smooth fashion.
---@param input number
---@param from number
---@return number
function interpolateListPos(input, from)
	if config.visualsettings["smooth_scroll"] == 2 then
		return from
	end
	if from > input then
		input = input + (from - input) / 4
		if input > from - 0.02 then
			input = from
		end
	elseif from < input then
		input = input + (from - input) / 4
		if input < from + 0.02 then
			input = from
		end
	end
	return input
end
---@param x number
---@param y number
---@param a number
function drawT48Cursor(x, y, a)
	if a <= 0 then return end
    love.graphics.setColor(1,1,1,a)
    love.graphics.polygon("fill", x + 5, y + 0, x + 0, y + 10, x + 5, y + 8, x + 8, y + 20, x + 12, y + 18, x + 10, y + 7, x + 15, y + 5)
    love.graphics.setColor(0,0,0,a)
    love.graphics.polygon("line", x + 5, y + 0, x + 0, y + 10, x + 5, y + 8, x + 8, y + 20, x + 12, y + 18, x + 10, y + 7, x + 15, y + 5)
    love.graphics.setColor(1,1,1,a)
end

---@param image love.ImageData
local function screenshotFunction(image)
	playSE("screenshot")
	screenshot_images[#screenshot_images+1] = {image = love.graphics.newImage(image), time = 0, y_position = #screenshot_images * 260}
end

local function drawTASWatermark()
	love.graphics.setFont(font_3x5_4)
	love.graphics.setColor(1, 1, 1, 0.2)
	love.graphics.printf(
		"T A S", -300, 100, 150, "center", 0, 8, 8
	)
end

local function drawWatermarks()
	local is_TAS_used = false
	if scene.replay then
		if scene.replay["toolassisted"] == true then
			is_TAS_used = true
		end
	end

	if scene.game then
		if scene.game.ineligible then
			is_TAS_used = true
		end
	end

	if TAS_mode then
		if scene.title == "Game" or scene.title == "Replay" and not scene.replay["toolassisted"] == true then
			is_TAS_used = true
		end
		love.graphics.setColor(1, 1, 1, love.timer.getTime() % 2 < 1 and 1 or 0)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"TAS MODE ON", 240, 0, 160, "center"
		)
	end
	if is_TAS_used then
		drawTASWatermark()
	end
end
local last_time = 0
local function getDeltaTime()
	local time = love.timer.getTime()
	local dt = time - last_time
	last_time = time
	return dt
end
local time_table = {}
local last_fps = 0
local function getMeanDelta()
	if #time_table > 24 then
		table.remove(time_table, 1)
	end
	local dt = getDeltaTime()
	table.insert(time_table, dt)
	local acc = 0
	for i = 1, #time_table do
		acc = acc + time_table[i]
	end
	if math.floor(love.timer.getTime()) + dt > love.timer.getTime() then
		last_fps = acc / #time_table
	end
	return last_fps
end

--What a mess trying to do something with it
local function drawScreenshotPreviews()
	local accumulated_y = 0
	for idx, value in ipairs(screenshot_images) do
		local image_x, image_y = value.image:getDimensions()
		local local_scale_factor = math.min(image_x / 640, image_y / 480)
		value.time = value.time + math.max(value.time < 300 and 4 or 1, value.time / 10 - 30)
		value.y_position = interpolateListPos(value.y_position, accumulated_y)
		local scaled_width, scaled_zero = getScaledPos(love.graphics.getWidth(), 0)
		local x = (scaled_width) - ((image_x / 4) / local_scale_factor) + math.max(0, value.time - 300)
		local rect_x, rect_y, rect_w, rect_h = x - 1, scaled_zero + value.y_position - 1, ((image_x / 4) / local_scale_factor) + 2, ((image_y / 4) / local_scale_factor) + 2
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", rect_x, rect_y, rect_w, rect_h)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(value.image, x, scaled_zero + value.y_position, 0, 0.25 / local_scale_factor, 0.25 / local_scale_factor)
		love.graphics.setColor(1, 1, 1, math.max(0, 1 - (value.time / 60)))
		love.graphics.rectangle("fill", rect_x, rect_y, rect_w, rect_h)
		if value.time > (image_x / local_scale_factor) + 100 then
			value.image:release()
			table.remove(screenshot_images, idx)
		end
		accumulated_y = accumulated_y + (image_y / local_scale_factor / 4) + 5
	end
end

local utf8 = require("utf8")

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
	msg = tostring(msg)

	local errored_filename = msg:sub(1, msg:find(':') -1)
	local substring = msg:sub(msg:find(':') +1)
	local line_error = tonumber(substring:sub(1, substring:find(':') - 1), 10)

	if love.filesystem.isFused() then
		local source_dir = love.filesystem.getSourceBaseDirectory()
		love.filesystem.mount(source_dir, "")
	end

	local str_data = love.filesystem.read("string", errored_filename)

	local lua_file_content = {}
	for v in string.gmatch(str_data, "([^\r\n]*)\r\n?") do
		lua_file_content[#lua_file_content+1] = v
	end

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	local font = love.graphics.newFont(14)
	love.graphics.setFont(font)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, "Error\n")
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(89/255, 157/255, 220/255)
		love.graphics.printf("Cambridge Crashed!", pos, pos-40, love.graphics.getWidth() - pos, "center")
		for i = 1, 7 do
			local local_line = line_error-4+i
			if local_line > 0 and local_line <= #lua_file_content then
				love.graphics.print(local_line.. ": " .. lua_file_content[local_line] .. (local_line == line_error and " <---" or "") , pos, pos + (i * 15) - 5)
			end
		end
		love.graphics.printf(p, pos, pos + 120, love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

end
--#endregion

function love.draw()
	local mean_delta = getMeanDelta()
	love.graphics.setCanvas(GLOBAL_CANVAS)
	love.graphics.clear()

	love.graphics.push()

	-- get offset matrix
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local scale_factor = math.min(width / 640, height / 480)
	love.graphics.translate(
		(width - scale_factor * 640) / 2,
		(height - scale_factor * 480) / 2
	)
	love.graphics.scale(scale_factor)
		
	scene:render()

	drawWatermarks()

	local bottom_right_corner_y_offset = 0
	love.graphics.setFont(font_3x5_2)
	love.graphics.setColor(1, 1, 1, 1)
	if config.visualsettings.display_gamemode == 1 or scene.title == "Title" then
		bottom_right_corner_y_offset = bottom_right_corner_y_offset + 20
		love.graphics.printf(
			string.format("(%g) %.2f fps - %s", getTargetFPS(), 1.0 / mean_delta, version),
			0, 480 - bottom_right_corner_y_offset, 635, "right"
		)
	end
	if config.visualsettings.debug_level > 1 then
		bottom_right_corner_y_offset = bottom_right_corner_y_offset + 18
		love.graphics.printf(
			string.format("Lua memory use: %.1fKB", collectgarbage("count")),
			0, 480 - bottom_right_corner_y_offset, 635, "right"
		)
	end

	if scene.title == "Game" or scene.title == "Replay" then
		-- if config.visualsettings.cursor_type ~= 1 then
		-- 	is_cursor_visible = true
		-- else
		-- 	is_cursor_visible = love.mouse.isVisible()
		-- end
		-- config.visualsettings.cursor_type = 0
		-- love.mouse.setVisible(is_cursor_visible)
	else
		love.mouse.setVisible(config.visualsettings.cursor_type == 1)
		if config.visualsettings.cursor_type ~= 1 then
			local lx, ly = getScaledPos(love.mouse.getPosition())
			drawT48Cursor(lx, ly, 9 - mouse_idle * 4)
		end
	end
	
	love.graphics.pop()
		
	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(GLOBAL_CANVAS)
	
	love.graphics.translate(
		(width - scale_factor * 640) / 2,
		(height - scale_factor * 480) / 2
	)
	love.graphics.scale(scale_factor)
	drawScreenshotPreviews()
	love.graphics.setColor(1, 1, 1, 1)
	if config.visualsettings.debug_level > 2 then
		bottom_right_corner_y_offset = bottom_right_corner_y_offset + 113
		local stats = love.graphics.getStats()
		love.graphics.printf(
			string.format("GPU stats:\nDraw calls: %d\nTexture Memory: %dKB\n"..(stats.textures and "Textures" or "Images").." loaded: %d\nFonts loaded: %d\nBatched draw calls: %d", stats.drawcalls + 1, stats.texturememory / 1024, (stats.images or stats.textures), stats.fonts, stats.drawcallsbatched),
			0, 480 - bottom_right_corner_y_offset, 635, "right"
		)
	end
end

local function multipleInputs(input_table, input)
	local result_inputs = {}
	for input_type, value in pairs(input_table) do
		if input == value then
			table.insert(result_inputs, input_type)
		end
	end
	return result_inputs
end

---@param file love.File
function love.filedropped(file)
	file:open("r")
	local data = file:read()
	local raw_file_directory = file:getFilename()
	if raw_file_directory:sub(-4) ~= ".lua" and raw_file_directory:sub(-4) ~= ".crp" then
		love.window.showMessageBox(love.window.getTitle(), "This file is not a Lua nor replay file.", "warning")
		file:close()
		return
	end
	local char_pos = raw_file_directory:gsub("\\", "/"):reverse():find("/")
	local filename = raw_file_directory:sub(-char_pos+1)
	local final_directory
	local msgbox_choice = 0
	if raw_file_directory:sub(-4) == ".lua" then
		msgbox_choice = love.window.showMessageBox(love.window.getTitle(), "Where do you put "..filename.."?", { "Cancel", "Rulesets", "Modes"}, "info")
		if msgbox_choice == 0 or msgbox_choice == 1 then
			file:close()
			return
		end
		local directory_string = "rulesets/"
		if msgbox_choice == 3 then
			directory_string = "modes/"
		end
		final_directory = "tetris/"..directory_string
	else
		msgbox_choice = love.window.showMessageBox(love.window.getTitle(), "Do you want to insert replay "..filename.."?", {"No", "Yes"})
		if msgbox_choice < 2 then
			return
		end
		final_directory = "replays/"
	end
	local do_write = 2
	if love.filesystem.getInfo(final_directory..filename) then
		do_write = love.window.showMessageBox(love.window.getTitle(), "This file ("..filename..") already exists! Do you want to override it?", {"No", "Yes"}, "warning")
	end

	if do_write == 2 then
		love.filesystem.createDirectory(final_directory)
		love.filesystem.write(final_directory..filename, data)
		if final_directory ~= "replays/" then
			loaded_replays = false
		else
			local binser = require "libs.binser"
			local replay = binser.deserialize(data)
			insertReplay(replay)
			sortReplays()
		end
	end
	file:close()
end

---@param dir string
function love.directorydropped(dir)
	local msgbox_choice = love.window.showMessageBox(love.window.getTitle(), "Do you want to insert a directory ("..dir..") as a mod pack?", {"No", "Yes"}, "info")
	if msgbox_choice <= 1 then
		return
	end
	local success = love.filesystem.mount(dir, "directory_dropped")
	if not success then
		error("Unsuccessful mount on "..dir.."!")
	end
	copyDirectoryRecursively("directory_dropped", "", true)
	love.filesystem.unmount(dir)
end

---@param key string|nil
---@param scancode string|nil
function love.keypressed(key, scancode)
	-- global hotkeys
	if scancode == "f11" then
		config["fullscreen"] = not config["fullscreen"]
		saveConfig()
		love.window.setFullscreen(config["fullscreen"])
	elseif scancode == "f1" then
		TAS_mode = not TAS_mode
	elseif scancode == "f2" and scene.title ~= "Input Config" and scene.title ~= "Game" and scene.title ~= "Replay" then
		scene = InputConfigScene()
		switchBGM(nil)
		loadSave()
	elseif scancode == "f3" then
		print("The old way of framestepping is deprecated!")
	-- load state tool
	elseif scancode == "f4" and TAS_mode and (scene.title == "Replay") then
		love.thread.getChannel("savestate"):push( "save" )
	elseif scancode == "f5" and TAS_mode and (scene.title == "Replay") then
		love.thread.getChannel("savestate"):push( "load" )
	-- secret sound playing :eyes:
	elseif scancode == "f8" and scene.title == "Title" then
		config.secret = not config.secret
		saveConfig()
		scene.restart_message = true
		if config.secret then playSE("mode_decide")
		else playSE("erase", "single") end
	-- f12 is reserved for saving screenshots
	elseif scancode == "f12" then
		local ss_name = os.date("ss/%Y-%m-%d_%H-%M-%S.png")
		local info = love.filesystem.getInfo("ss", "directory")
		if not info then
			love.filesystem.remove("ss")
			love.filesystem.createDirectory("ss")
		end
		print("Saving screenshot as "..love.filesystem.getSaveDirectory().."/"..ss_name)
		local image = GLOBAL_CANVAS:newImageData()
		image:encode("png", ss_name)
		screenshotFunction(image)
		image:release()
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- escape is reserved for menu_back except in modes
	elseif scancode == "escape" and not scene.game then
		scene:onInputPress({input="menu_back", type="key", key=key, scancode=scancode})
	-- pass any other key to the scene, with its configured mapping
	else
		local result_inputs = {}
		if config.input and config.input.keys then
			result_inputs = multipleInputs(config.input.keys, scancode)
			for _, input in pairs(result_inputs) do
				scene:onInputPress({input=input, type="key", key=key, scancode=scancode})
				key = nil
				scancode = nil
			end
		end
		if #result_inputs == 0 then
			scene:onInputPress({type="key", key=key, scancode=scancode})
		end
	end
end

---@param key string|nil
---@param scancode string|nil
function love.keyreleased(key, scancode)
	-- escape is reserved for menu_back
	if scancode == "escape" then
		scene:onInputRelease({input="menu_back", type="key", key=key, scancode=scancode})
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- handle all other keys; tab is reserved, but the input config scene keeps it from getting configured as a game input, so pass tab to the scene here
	else
		local result_inputs = {}
		if config.input and config.input.keys then
			result_inputs = multipleInputs(config.input.keys, scancode)
			for _, input in pairs(result_inputs) do
				scene:onInputRelease({input=input, type="key", key=key, scancode=scancode})
				key = nil
				scancode = nil
			end
		end
		if #result_inputs == 0 then
			scene:onInputRelease({type="key", key=key, scancode=scancode})
		end
	end
end

---@param joystick love.Joystick
---@param button integer
function love.joystickpressed(joystick, button)
	local result_inputs = {}
	if config.input and config.input.joysticks then
		if config.input.joysticks[joystick:getName()] then
			result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "buttons-"..button)
		end
		for _, input in pairs(result_inputs) do
			scene:onInputPress({input=input, type="joybutton", name=joystick:getName(), button=button})
		end
	end
	if #result_inputs == 0 then
		scene:onInputPress({type="joybutton", name=joystick:getName(), button=button})
	end
	-- scene:onInputPress({input=input_pressed, type="joybutton", name=joystick:getName(), button=button})
end

---@param joystick love.Joystick
---@param button integer
function love.joystickreleased(joystick, button)
	local result_inputs = {}
	if config.input and config.input.joysticks then
		if config.input.joysticks[joystick:getName()] then
			result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "buttons-"..button)
		end
		for _, input in pairs(result_inputs) do
			scene:onInputRelease({input=input, type="joybutton", name=joystick:getName(), button=button})
		end
	end
	if #result_inputs == 0 then
		scene:onInputRelease({type="joybutton", name=joystick:getName(), button=button})
	end
end

---@param joystick love.Joystick
---@param axis number
---@param value number
function love.joystickaxis(joystick, axis, value)
	local input_pressed = nil
	local result_inputs = {}
	if math.abs(value) >= 1 then
		if config.input and config.input.joysticks and config.input.joysticks[joystick:getName()] then
			result_inputs = multipleInputs(config.input.joysticks[joystick:getName()],"axes-"..axis.."-"..(value >= 1 and "positive" or "negative"))
			for _, input in pairs(result_inputs) do
				scene:onInputPress({input=input, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
			-- scene:onInputPress({input=input_pressed, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		end
		if #result_inputs == 0 then
			scene:onInputPress({type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		end
	else
		if config.input and config.input.joysticks and config.input.joysticks[joystick:getName()] then
			for input_type, v in pairs(config.input.joysticks[joystick:getName()]) do
				if "axes-"..axis.."-".."negative" == v then
					table.insert(result_inputs, input_type)
				end
				if "axes-"..axis.."-".."positive" == v then
					table.insert(result_inputs, input_type)
				end
			end
			for _, input in pairs(result_inputs) do
				scene:onInputRelease({input=input, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
		end
		if #result_inputs == 0 then
			scene:onInputRelease({type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		end
	end
end

local last_hat_direction = ""
local directions = {
	["u"] = "up",
	["d"] = "down",
	["l"] = "left",
	["r"] = "right",
}

--wtf
---@param joystick love.Joystick
---@param hat number
---@param direction string
function love.joystickhat(joystick, hat, direction)
	local input_pressed = nil
	local has_hat = false
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()]
	then
		input_pressed = direction ~= "c"
		has_hat = true
	end
	if input_pressed then
		for i = 1, #direction do
			local char = direction:sub(i, i)
			local _, count = last_hat_direction:gsub(char, char)
			if count == 0 then
				local result_inputs = {}
				for input_type, value in pairs(config.input.joysticks[joystick:getName()]) do
					if "hat-"..hat.."-"..directions[char] == value then
						table.insert(result_inputs, input_type)
					end
				end
				for _, input in pairs(result_inputs) do
					scene:onInputPress({input=input, type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
				if #result_inputs == 0 then
					scene:onInputPress({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
				--scene:onInputPress({input=config.input.joysticks[joystick:getName()].hats[hat][char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		for i = 1, #last_hat_direction do
			local char = last_hat_direction:sub(i, i)
			local _, count = direction:gsub(char, char)
			if count == 0 then
				local result_inputs = {}
				for input_type, value in pairs(config.input.joysticks[joystick:getName()]) do
					if "hat-"..hat.."-"..directions[char] == value then
						table.insert(result_inputs, input_type)
					end
				end
				for _, input in pairs(result_inputs) do
					scene:onInputRelease({input=input, type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
				if #result_inputs == 0 then
					scene:onInputRelease({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
				-- scene:onInputRelease({input=config.input.joysticks[joystick:getName()].hats[hat][char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		last_hat_direction = direction
	elseif has_hat then
		--why redefine the local variable?
		for i, fdirection in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			local result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "hat-"..hat.."-"..(directions[fdirection] or "nil"))
			for _, input in pairs(result_inputs) do
				scene:onInputRelease({input=input, type="joyhat", name=joystick:getName(), hat=hat, direction=fdirection})
			end
			if #result_inputs == 0 then
				scene:onInputRelease({input=directions[fdirection] or nil, type="joyhat", name=joystick:getName(), hat=hat, direction=fdirection})
			end
			-- scene:onInputRelease({input=config.input.joysticks[joystick:getName()].hats[hat][direction], type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
		end
		last_hat_direction = ""
	elseif direction ~= "c" then
		for i = 1, #direction do
			local char = direction:sub(i, i)
			local _, count = last_hat_direction:gsub(char, char)
			if count == 0 then
				scene:onInputPress({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		for i = 1, #last_hat_direction do
			local char = last_hat_direction:sub(i, i)
			local _, count = direction:gsub(char, char)
			if count == 0 then
				scene:onInputRelease({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		last_hat_direction = direction
	else
		for i, fdirection in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			scene:onInputRelease({input=directions[fdirection], type="joyhat", name=joystick:getName(), hat=hat, direction=fdirection})
		end
		last_hat_direction = ""
	end
end

---@param x number
---@param y number
---@param button integer
---@param istouch boolean
---@param presses integer
function love.mousepressed(x, y, button, istouch, presses)
	if mouse_idle > 2 then return end
	local screen_x, screen_y = love.graphics.getDimensions()
	local scale_factor = math.min(screen_x / 640, screen_y / 480)
	local local_x, local_y = (x - (screen_x - scale_factor * 640) / 2)/scale_factor, (y - (screen_y - scale_factor * 480) / 2)/scale_factor
	scene:onInputPress({input=nil, type="mouse", x=local_x, y=local_y, button=button, istouch=istouch, presses=presses})
end

---@param x number
---@param y number
---@param button integer
---@param istouch boolean
---@param presses integer
function love.mousereleased(x, y, button, istouch, presses)
	if mouse_idle > 2 then return end
	local screen_x, screen_y = love.graphics.getDimensions()
	local scale_factor = math.min(screen_x / 640, screen_y / 480)
	local local_x, local_y = (x - (screen_x - scale_factor * 640) / 2)/scale_factor, (y - (screen_y - scale_factor * 480) / 2)/scale_factor
	scene:onInputRelease({input=nil, type="mouse", x=local_x, y=local_y, button=button, istouch=istouch, presses=presses})
end

---@param x number
---@param y number
function love.wheelmoved(x, y)
	scene:onInputPress({input=nil, type="wheel", x=x, y=y})
end

function love.focus(f)
	if f then
		resumeBGM(true)
	else
		pauseBGM(true)
	end
end

---@param w integer
---@param h integer
function love.resize(w, h)
		GLOBAL_CANVAS:release()
		GLOBAL_CANVAS = love.graphics.newCanvas(w, h)
end

local TARGET_FPS = 60
local FRAME_DURATION = 1.0 / TARGET_FPS

---@param fps number
function setTargetFPS(fps)
	if fps == -1 then
		TARGET_FPS = -1
		return
	end
	if fps <= 0 then
		error("Illegal target FPS.")
	end
	TARGET_FPS = fps
	FRAME_DURATION = 1.0 / TARGET_FPS
end

function getTargetFPS()
	return TARGET_FPS
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	if love.timer then love.timer.step() end

	local dt = 0

	local last_time = love.timer.getTime()
	local time_accumulator = 0.0
	return function()
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						if io_thread then io_thread:release() end
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		if love.timer then
			processBGMFadeout(love.timer.step())
		end
		
		if scene and scene.update and love.timer then
			scene:update()

			if time_accumulator < FRAME_DURATION or TARGET_FPS == -1 then
				if love.graphics and love.graphics.isActive() and love.draw then
					love.graphics.origin()
					love.graphics.clear(love.graphics.getBackgroundColor())
					love.draw()
					love.graphics.present()
				end
				if love.mouse then
					if prev_cur_pos_x == love.mouse.getX() and prev_cur_pos_y == love.mouse.getY() then
						mouse_idle = mouse_idle + love.timer.getDelta()
					else
						mouse_idle = 0
					end
					prev_cur_pos_x, prev_cur_pos_y = love.mouse.getPosition()
					love.mouse.setCursor(love.mouse.getSystemCursor(system_cursor_type))
					if system_cursor_type ~= "arrow" then
						system_cursor_type = "arrow"
					end
				end
				if TARGET_FPS ~= -1 then
					-- request 1ms delays first but stop short of overshooting, then do "0ms" delays without overshooting (0ms requests generally do a delay of some nonzero amount of time, but maybe less than 1ms)
					for milliseconds=0.001,0.000,-0.001 do
						local max_delay = 0.0
						while max_delay < FRAME_DURATION do
							local delay_start_time = love.timer.getTime()
							if delay_start_time - last_time < FRAME_DURATION - max_delay then
								love.timer.sleep(milliseconds)
								local last_delay = love.timer.getTime() - delay_start_time
								if last_delay > max_delay then
									max_delay = last_delay
								end
							else
								break
							end
						end
					end
					while love.timer.getTime() - last_time < FRAME_DURATION do
						-- busy loop, do nothing here until delay is finished; delays above stop short of finishing, so this part can finish it off precisely
					end
				end
			end

			local finish_delay_time = love.timer.getTime()
			local real_frame_duration = finish_delay_time - last_time
			time_accumulator = time_accumulator + real_frame_duration - FRAME_DURATION
			last_time = finish_delay_time
		end
	end
end
