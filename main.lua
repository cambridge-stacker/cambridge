
-- Pre-load aliases
random = love.math.random
math.random = love.math.random
math.randomseed = love.math.setRandomSeed
local GLOBAL_STATE = "INIT"

-- This translates and scales the screen into specified dimensions.
---@type function
local scaleToResolution

function love.load(args)
	love.graphics.setDefaultFilter("linear", "nearest")
	require "load.fonts"
	love.graphics.setFont(font_3x5_4)
	love.graphics.printf("Please wait...\nLoading...", 160, 160, 320, "center")
	love.graphics.present()
	love.graphics.clear()
	math.randomseed(os.time())
	highscores = {}
	require "load.filesystem"
	require "load.rpc"
	require "load.graphics"
	require "load.resources"
	require "load.sounds"
	require "load.bgm"
	require "load.save"
	require "load.bigint"
	require "load.modules"
	require "load.replays"
	require "load.version"
	loadSave()
	require "funcs"
	require "scene"
	
	if table.contains(args, "--tempIdentity") then
		love.filesystem.setIdentity(love.filesystem.getIdentity() .. "-temp")
		saveConfig()
	end
	--config["side_next"] = false
	--config["reverse_rotate"] = true
	--config["das_last_key"] = false
	--config["fullscreen"] = false

		
	-- used for screenshots
	GLOBAL_CANVAS = love.graphics.newCanvas()

	-- init config
	initConfig()

	love.window.setFullscreen(config["fullscreen"])


	-- loads game graphics and sounds.
	loadResources()

	-- import custom modules
	initModules()

	-- this is executed after the sound table is generated. why is that is unknown.
	if config.secret then playSE("welcome") end
end

function scaleToResolution(width, height)
	local screen_width, screen_height = love.graphics.getDimensions()
	local scale_factor = math.min(screen_width / width, screen_height / height)
	love.graphics.translate(
		(screen_width - scale_factor * width) / 2,
		(screen_height - scale_factor * height) / 2
	)
	love.graphics.scale(scale_factor)
end

mouse_idle = 0
TAS_mode = false
local system_cursor_type = "arrow"
local screenshot_images = {}

---@param type love.CursorType
function setSystemCursorType(type)
	system_cursor_type = type
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
	local image_x, image_y = image:getDimensions()
	local local_scale_factor = math.min(image_x / 640, image_y / 480)
	local width = image_x / local_scale_factor / 3 + 30
	local height = image_y / local_scale_factor / 3 + 30
	createToast("Screenshot taken!", love.graphics.newImage(image), {width = width, height = height})
end

local last_render_time = 0
local render_dt = 0
--- Measures the time between two frames.
--- Calling this changes getDeltaTime() on the render side.
local function stepRenderTime()
	local time = love.timer.getTime()
	local dt = time - last_render_time
	render_dt = dt
	last_render_time = time
	return dt
end
local time_table = {}
local last_fps = 0
local function getAvgDelta()
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

--#region Toasts

---@class toast
---@field title string
---@field message string|love.Image
---@field time number
---@field params toast_params
---@field y number
---@field back boolean?

---@class toast_params
---@field width number?
---@field height number?
---@field title_offset number?
---@field message_offset number?
---@field title_color {[1]:number,[2]:number,[3]:number}?
---@field message_color {[1]:number,[2]:number,[3]:number}?
---@field force_sequence boolean?

---@type toast[]
local toasts = {}

---@type toast[]
local queued_toasts = {}

---@param param_table toast_params?
function createToast(title, message, param_table)
	param_table = param_table or {}
	param_table.width = param_table.width or 200
	param_table.height = param_table.height or 40

	local message_lines = 0
	if type(message) == "string" then
		local _, wrapped_message = font_3x5_2:getWrap(message, param_table.width - 30)
		message_lines = #wrapped_message
	end
	local _, wrapped_title = font_3x5_2:getWrap(title, param_table.width - 30)
	local title_lines = #wrapped_title
	local half_toast_height = param_table.height / 2
	
	local title_offset = 0
	local message_offset = half_toast_height
	local font_height = font_3x5_2:getHeight()
	if font_height * (title_lines + message_lines) > param_table.height then
		title_offset = half_toast_height - title_lines * font_height / 2
		message_offset = half_toast_height - message_lines * font_height / 2
	end
	if message == nil then
		title_offset = half_toast_height - title_lines * font_height / 2
	elseif message.typeOf and message:typeOf("Texture") then
		message_offset = title_lines * font_height
	end
	param_table.title_offset = param_table.title_offset or title_offset
	param_table.message_offset = param_table.message_offset or message_offset
	param_table.title_color = param_table.title_color or {1, 1, 0, 1}
	param_table.message_color = param_table.message_color or {1, 1, 1, 1}
	table.insert(queued_toasts, {title = title, message = message, params = param_table, time = 0})
end

local function insertToastFromQueue(height_limit)
	if #queued_toasts == 0 then return false end
	local idx, result_toast = next(queued_toasts)
	local y_pos = 0
	local total_height = result_toast.params.height
	for _, v in next, toasts do
		total_height = total_height + v.params.height
		for _, v2 in next, toasts do
			if y_pos + result_toast.params.height > v2.y and y_pos <= v2.y + v2.params.height then
				y_pos = math.max(y_pos, v2.y + v2.params.height)
			end
		end
	end
	if total_height > height_limit and (result_toast.params.height < height_limit or next(toasts)) then
		return false
	end
	result_toast.y = y_pos
	table.remove(queued_toasts, idx)
	table.insert(toasts, result_toast)
	return true
end

local function easeOutQuad(x)
	return 1 - (1 - x) * (1 - x);
end
local function drawToasts()
	while insertToastFromQueue(280) do end
	local scaled_screen_x, scaled_screen_y = getScaledDimensions(love.graphics.getDimensions())
	for idx, toast in pairs(toasts) do
		local toast_width = toast.params.width
		local toast_height = toast.params.height
		if toast.time > 300 then
			toast.back = true
			toast.time = 30
		end
		toast.time = toast.time + (toast.back and -1 or 1)
		local factor = math.min(30, toast.time) / 30
		local sliding_pos = toast_width * factor * factor
		if toast.back == true then
			sliding_pos = toast_width * easeOutQuad(factor)
		end
		love.graphics.setColor(0.4, 0.4, 0.4)
		love.graphics.rectangle("fill", scaled_screen_x - sliding_pos, toast.y, toast_width, toast_height, 2, 2)
		love.graphics.setColor(0.6, 0.6, 0.6)
		love.graphics.rectangle("line", scaled_screen_x + 2 - sliding_pos, toast.y + 2, toast_width - 4, toast_height - 4)
		love.graphics.setFont(font_3x5_2)

		local message_lines = 0
		local message = toast.message
		if type(message) == "string" then
			local _, wrapped_message = font_3x5_2:getWrap(message, toast_width - 30)
			message_lines = #wrapped_message
		end
		local _, wrapped_title = font_3x5_2:getWrap(toast.title, toast_width - 30)
		local title_lines = #wrapped_title

		local title_alpha = 1
		local message_alpha = 1
		local font_height = font_3x5_2:getHeight()
		if font_height * (title_lines + message_lines) > toast_height or toast.params.force_sequence then
			title_alpha = toast.back and 0 or math.max(0, 4 - toast.time / 30)
			message_alpha = toast.back and 1 or 1 - math.max(0, 5 - toast.time / 30)
		end
		toast.params.title_color[4] = title_alpha
		toast.params.message_color[4] = message_alpha
		local text_pos_x = scaled_screen_x + 10 - sliding_pos
		love.graphics.setColor(toast.params.title_color)
		love.graphics.printf(toast.title, text_pos_x, toast.y + toast.params.title_offset, toast_width - 20, "left")
		love.graphics.setColor(1, 1, 1, message_alpha)
		if message and message.typeOf and message:typeOf("Texture") then
			drawSizeIndependentImage(message,
				text_pos_x, toast.y + toast.params.message_offset, 0,
				toast_width - 20, toast_height - toast.params.message_offset - 10)
		elseif message then
			love.graphics.printf(tostring(message), text_pos_x, toast.y + toast.params.message_offset, toast_width - 20, "left")
		end
		if toast.time < 0 and toast.back then
			toasts[idx] = nil
		end
	end
end
--#endregion

function getDeltaTime()
	if GLOBAL_STATE == "RENDER" then
		return render_dt
	else
		return love.timer.getDelta()
	end
end

--#region Error Handler
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


	if type(config.mod_packs_applied) == "table" then
		for key, value in ipairs(config.mod_packs_applied) do
			love.filesystem.mount("modpacks/"..value, "")
		end
	end
	local lua_file_content = {}
	if love.filesystem.getInfo(errored_filename, "file") then
		local str_data = love.filesystem.read("string", errored_filename)
		for v in string.gmatch(str_data, "([^\n]*)\n?") do
			lua_file_content[#lua_file_content+1] = v
		end
	end

	if type(config.mod_packs_applied) == "table" then
		for key, value in ipairs(config.mod_packs_applied) do
			love.filesystem.unmount("modpacks/"..value)
		end
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
	local avg_delta = getAvgDelta()
	love.graphics.setCanvas(GLOBAL_CANVAS)
	love.graphics.clear()

	love.graphics.push()

	-- get offset matrix
	scaleToResolution(640, 480)
		
	scene:render()

	if TAS_mode then
		love.graphics.setColor(1, 1, 1, love.timer.getTime() % 2 < 1 and 1 or 0)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"TAS MODE ON", 240, 0, 160, "center"
		)
	end

	local background_x, background_y, background_width, background_height = getBackgroundRectDimensions()
	local bottom_right_corner_y_offset = 0
	love.graphics.setFont(font_3x5_2)
	love.graphics.setColor(1, 1, 1, 1)
	if config.visualsettings.display_gamemode == 1 or scene.title == "Title" then
		bottom_right_corner_y_offset = bottom_right_corner_y_offset + 20
		love.graphics.printf(
			string.format("(%g) %.2f fps - %s", getTargetFPS(), 1.0 / avg_delta, version),
			background_x, background_height - bottom_right_corner_y_offset, background_width - 5, "right"
		)
	end
	if config.visualsettings.debug_level > 1 then
		bottom_right_corner_y_offset = bottom_right_corner_y_offset + 18
		love.graphics.printf(
			string.format("Lua memory use: %.1fMB", collectgarbage("count")/1000),
			background_x, background_height - bottom_right_corner_y_offset, background_width - 5, "right"
		)
	end

	if scene.title == "Game" or scene.title == "Replay" then
	else
		love.mouse.setVisible(config.visualsettings.cursor_type == 1)
		if config.visualsettings.cursor_type ~= 1 then
			local lx, ly = getScaledDimensions(love.mouse.getPosition())
			drawT48Cursor(lx, ly, 9 - mouse_idle * 4)
		end
	end

	if string.sub(love.filesystem.getIdentity(), -5) == "-temp" then
		love.graphics.printf("TEMPORARY IDENTITY MODE", font_8x11_small, 0, 0, 640, "center")
	end
	
	drawToasts()

	love.graphics.pop()
		
	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(GLOBAL_CANVAS)
	
	scaleToResolution(640, 480)
	if config.visualsettings.debug_level > 2 then
		bottom_right_corner_y_offset = bottom_right_corner_y_offset + 113
		local stats = love.graphics.getStats()
		love.graphics.printf(
			string.format("GPU stats:\nDraw calls: %d\nTexture Memory: %dKB\n"..(stats.textures and "Textures" or "Images").." loaded: %d\nFonts loaded: %d\nBatched draw calls: %d", stats.drawcalls + 1, stats.texturememory / 1024, (stats.images or stats.textures), stats.fonts, stats.drawcallsbatched),
			0, 480 - bottom_right_corner_y_offset, 635, "right"
		)
	end
end

local function onInputPress(e)
	if scene.title == "Key Config" or scene.title == "Stick Config" then
		scene:onInputPress(e)
	elseif e.input == "fullscreen" then
		config["fullscreen"] = not config["fullscreen"]
		saveConfig()
		love.window.setFullscreen(config["fullscreen"])
	elseif e.input == "tas_mode" then
		TAS_mode = not TAS_mode
		return
	elseif e.input == "configure_inputs" and scene.title ~= "Input Config" and scene.title ~= "Game" and scene.title ~= "Replay" then
		scene = InputConfigScene()
		switchBGM(nil)
		loadSave()
	-- load state tool
	elseif e.input == "save_state" and TAS_mode and (scene.title == "Replay") then
		scene:onInputPress({input="save_state"})
	elseif e.input == "load_state" and TAS_mode and (scene.title == "Replay") then
		scene:onInputPress({input="load_state"})
	-- secret sound playing :eyes:
	elseif e.input == "secret" and scene.title == "Title" then
		config.secret = not config.secret
		saveConfig()
		scene.restart_message = true
		if config.secret then playSE("mode_decide")
		else playSE("erase", "single") end
	elseif e.input == "screenshot" then
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
	else
		scene:onInputPress(e)
	end
end

local function onInputRelease(e)
	scene:onInputRelease(e)
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
	file:close()
	local raw_file_directory = file:getFilename()
	local char_pos = raw_file_directory:gsub("\\", "/"):reverse():find("/")
	local filename = raw_file_directory:sub(-char_pos+1)
	local final_directory
	local msgbox_choice = 0
	local binser = require "libs.binser"
	local confirmation_buttons = {"No", "Yes", enterbutton = 2}
	if raw_file_directory:sub(-4) == ".lua" then
		msgbox_choice = love.window.showMessageBox(love.window.getTitle(), "Is "..filename.." a ruleset or a mode?", { "Cancel", "Ruleset", "Mode"}, "info")
		if msgbox_choice == 0 or msgbox_choice == 1 then
			return
		end
		local directory_string = "rulesets/"
		if msgbox_choice == 3 then
			directory_string = "modes/"
		end
		final_directory = "tetris/"..directory_string
	elseif raw_file_directory:sub(-4) == ".crp" then
		msgbox_choice = love.window.showMessageBox(love.window.getTitle(), "What option do you select for "..filename.."?", {"Insert", "View", escapebutton = 0}, "info")
		if msgbox_choice == 0 then
			return
		end
		if msgbox_choice == 1 then
			final_directory = "replays/"
		elseif msgbox_choice == 2 then
			local replay_data = binser.d(data)[1]
			displayReplayInfoBox(replay_data)
			return
		end
	elseif raw_file_directory:sub(-4) == ".zip" then
		msgbox_choice = love.window.showMessageBox(love.window.getTitle(),
		"What option do you select for "..filename.."?\n"..
		"Directory: Treat the zip archive as directory\n"..
		"Res. Pack: Install the zip file as a resource pack.\n\nPress ESC to abort.", {"Directory", "Res. Pack", escapebutton = 0}, "info")
		if msgbox_choice == 0 then
			return
		end
		if msgbox_choice == 1 then
			return love.directorydropped(raw_file_directory)
		elseif msgbox_choice == 2 then
			final_directory = "resourcepacks/"
		end
	else
		love.window.showMessageBox(love.window.getTitle(), "This file ("..filename..") is not one of these file types: .lua, .crp, .zip", "warning")
		return
	end
	local do_write = 2
	if love.filesystem.getInfo(final_directory..filename) then
		do_write = love.window.showMessageBox(love.window.getTitle(), "This file ("..filename..") already exists! Do you want to override it?", confirmation_buttons, "warning")
	end

	if do_write == 2 then
		love.filesystem.createDirectory(final_directory)
		love.filesystem.write(final_directory..filename, data)
		if loaded_replays then
			if final_directory == "replays/" then
				local replay = binser.deserialize(data)[1]
				insertReplay(replay)
				sortReplays()
			else
				refreshReplayTree()
				if final_directory == "modes/" or final_directory == "rulesets/" then
					unloadModules()
					initModules()
					playSE("ihs")
					createToast("File drag-n-drop", "Modules reloaded!")
				end
			end
		end
	end
end

---@param dir string
function love.directorydropped(dir)
	local msgbox_choice = love.window.showMessageBox(love.window.getTitle(), "Do you want to install this directory ("..dir..") as a mod pack?", {"No", "Yes"}, "info")
	if msgbox_choice <= 1 then
		return
	end
	local success = love.filesystem.mount(dir, "directory_dropped")
	assert(success, "Unsuccessful mount on "..dir.."!")
	copyDirectoryRecursively("directory_dropped", "", true)
	love.filesystem.unmount(dir)
end

---@param key string|nil
---@param scancode string|nil
function love.keypressed(key, scancode)
	local result_inputs = {}
	if config.input and config.input.keys then
		result_inputs = multipleInputs(config.input.keys, scancode)
		for _, input in pairs(result_inputs) do
			onInputPress({input=input, type="key", key=key, scancode=scancode})
			key = nil
			scancode = nil
		end
	end
	if #result_inputs == 0 then
		onInputPress({type="key", key=key, scancode=scancode})
	end
end

---@param key string|nil
---@param scancode string|nil
function love.keyreleased(key, scancode)
	local result_inputs = {}
	if config.input and config.input.keys then
		result_inputs = multipleInputs(config.input.keys, scancode)
		for _, input in pairs(result_inputs) do
			onInputRelease({input=input, type="key", key=key, scancode=scancode})
			key = nil
			scancode = nil
		end
	end
	if #result_inputs == 0 then
		onInputRelease({type="key", key=key, scancode=scancode})
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
			onInputPress({input=input, type="joybutton", name=joystick:getName(), button=button})
		end
	end
	if #result_inputs == 0 then
		onInputPress({type="joybutton", name=joystick:getName(), button=button})
	end
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
			onInputRelease({input=input, type="joybutton", name=joystick:getName(), button=button})
		end
	end
	if #result_inputs == 0 then
		onInputRelease({type="joybutton", name=joystick:getName(), button=button})
	end
end

---@param joystick love.Joystick
---@param axis number
---@param value number
function love.joystickaxis(joystick, axis, value)
	local result_inputs = {}
	local joystick_input_table = nil
	local joystick_name = joystick:getName()
	if config.input and config.input.joysticks and config.input.joysticks[joystick_name] then
		joystick_input_table = config.input.joysticks[joystick_name]
	end
	if math.abs(value) >= 1 then
		if type(joystick_input_table) == "table" then
			result_inputs = multipleInputs(joystick_input_table, "axes-"..axis.."-"..(value >= 1 and "positive" or "negative"))
			for _, input in pairs(result_inputs) do
				onInputPress({input=input, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
			local opposite_direction_inputs = multipleInputs(joystick_input_table, "axes-"..axis.."-"..(value <= -1 and "positive" or "negative"))
			for _, input in pairs(opposite_direction_inputs) do
				onInputRelease({input=input, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
		end
		if #result_inputs == 0 then
			onInputPress({type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		end
	else
		if type(joystick_input_table) == "table" then
			for input_type, v in pairs(joystick_input_table) do
				if "axes-"..axis.."-".."negative" == v then
					table.insert(result_inputs, input_type)
				end
				if "axes-"..axis.."-".."positive" == v then
					table.insert(result_inputs, input_type)
				end
			end
			for _, input in pairs(result_inputs) do
				onInputRelease({input=input, type="joyaxis", name=joystick_name, axis=axis, value=value})
			end
		end
		if #result_inputs == 0 then
			onInputRelease({type="joyaxis", name=joystick_name, axis=axis, value=value})
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
				local result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "hat-"..hat.."-"..char)
				for _, input in pairs(result_inputs) do
					onInputPress({input=input, type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
				if #result_inputs == 0 then
					onInputPress({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
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
					onInputRelease({input=input, type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
				if #result_inputs == 0 then
					onInputRelease({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
				end
			end
		end
		last_hat_direction = direction
	elseif has_hat then
		--why redefine the local variable?
		for i, fdirection in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			local result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "hat-"..hat.."-"..fdirection)
			for _, input in pairs(result_inputs) do
				onInputRelease({input=input, type="joyhat", name=joystick:getName(), hat=hat, direction=fdirection})
			end
			if #result_inputs == 0 then
				onInputRelease({input=directions[fdirection] or nil, type="joyhat", name=joystick:getName(), hat=hat, direction=fdirection})
			end
		end
		last_hat_direction = ""
	elseif direction ~= "c" then
		for i = 1, #direction do
			local char = direction:sub(i, i)
			local _, count = last_hat_direction:gsub(char, char)
			if count == 0 then
				onInputPress({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		for i = 1, #last_hat_direction do
			local char = last_hat_direction:sub(i, i)
			local _, count = direction:gsub(char, char)
			if count == 0 then
				onInputRelease({input=directions[char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		last_hat_direction = direction
	else
		for i, fdirection in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			onInputRelease({input=directions[fdirection], type="joyhat", name=joystick:getName(), hat=hat, direction=fdirection})
		end
		last_hat_direction = ""
	end
end

local mouse_buttons_pressed = {}

---@param x number
---@param y number
---@param button integer
---@param istouch boolean
---@param presses integer
function love.mousepressed(x, y, button, istouch, presses)
	if mouse_idle > 2 then return end
	mouse_buttons_pressed[button] = true
	local local_x, local_y = getScaledDimensions(x, y)
	scene:onInputPress({type="mouse", x=local_x, y=local_y, button=button, istouch=istouch, presses=presses})
end

---@param x number
---@param y number
---@param button integer
---@param istouch boolean
---@param presses integer
function love.mousereleased(x, y, button, istouch, presses)
	if mouse_idle > 2 and not mouse_buttons_pressed[button] then return end
	mouse_buttons_pressed[button] = false
	local local_x, local_y = getScaledDimensions(x, y)
	scene:onInputRelease({type="mouse", x=local_x, y=local_y, button=button, istouch=istouch, presses=presses})
end

---@param x number
---@param y number
---@param dx number
---@param dy number
---@param istouch boolean
function love.mousemoved(x, y, dx, dy, istouch)
	mouse_idle = 0
	local local_x, local_y = getScaledDimensions(x, y)
	local local_dx, local_dy = getScaledDimensions(dx, dy)
	scene:onInputMove({type="mouse", x=local_x, y=local_y, dx=local_dx, dy=local_dy, istouch=istouch})
end

---@param id lightuserdata
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param pressure number
function love.touchpressed(id, x, y, dx, dy, pressure)
	local local_x, local_y = getScaledDimensions(x, y)
	local local_dx, local_dy = getScaledDimensions(dx, dy)
	scene:onInputPress({type="touch", id=id, x=local_x, y=local_y, dx=local_dx, dy=local_dy, pressure=pressure})
end

---@param id lightuserdata
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param pressure number
function love.touchmoved(id, x, y, dx, dy, pressure)
	local local_x, local_y = getScaledDimensions(x, y)
	local local_dx, local_dy = getScaledDimensions(dx, dy)
	scene:onInputMove({type="touch", id=id, x=local_x, y=local_y, dx=local_dx, dy=local_dy, pressure=pressure})
end

---@param id lightuserdata
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param pressure number
function love.touchreleased(id, x, y, dx, dy, pressure)
	local local_x, local_y = getScaledDimensions(x, y)
	local local_dx, local_dy = getScaledDimensions(dx, dy)
	scene:onInputRelease({type="touch", id=id, x=local_x, y=local_y, dx=local_dx, dy=local_dy, pressure=pressure})
end

function love.focus(f)
	if f then
		love.audio.setVolume(config.audiosettings.master_volume / 100)
	else
		love.audio.setVolume(config.audiosettings.master_volume / 1000)
	end
end

---@param x number
---@param y number
function love.wheelmoved(x, y)
	scene:onInputPress({input=nil, type="wheel", x=x, y=y})
end

---@param w integer
---@param h integer
function love.resize(w, h)
	GLOBAL_CANVAS:release()
	GLOBAL_CANVAS = love.graphics.newCanvas(w, h)
end

-- higher values of TARGET_FPS will make the game run "faster"
-- since the game is mostly designed for 60 FPS
local TARGET_FPS = 60
local FRAME_DURATION = 1.0 / TARGET_FPS

---@param fps number
function setTargetFPS(fps)
	if fps <= 0 or fps == math.huge then
		TARGET_FPS = math.huge
		return
	end
	TARGET_FPS = fps
	FRAME_DURATION = 1.0 / TARGET_FPS
end

function getTargetFPS()
	return TARGET_FPS
end

local function recursivelyDelete( item )
	if love.filesystem.getInfo( item , "directory" ) then
		for _, child in ipairs( love.filesystem.getDirectoryItems( item )) do
			recursivelyDelete( item .. '/' .. child )
			love.filesystem.remove( item .. '/' .. child )
		end
	elseif love.filesystem.getInfo( item ) then
		love.filesystem.remove( item )
	end
	love.filesystem.remove( item )
end

-- custom run function; optimizes game by syncing draw/update calls
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
						if disposeReplayThread then disposeReplayThread() end
						if string.sub(love.filesystem.getIdentity(), -5) == "-temp" then
							recursivelyDelete('')
						end
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
			GLOBAL_STATE = "UPDATE"
			scene:update()
			if time_accumulator < FRAME_DURATION or TARGET_FPS == math.huge then
				stepRenderTime()
				if love.graphics and love.graphics.isActive() and love.draw then
					GLOBAL_STATE = "RENDER"
					love.graphics.origin()
					love.graphics.clear(love.graphics.getBackgroundColor())
					love.draw()
					love.graphics.present()
				end
				if love.mouse then
					mouse_idle = mouse_idle + love.timer.getDelta()
					love.mouse.setCursor(love.mouse.getSystemCursor(system_cursor_type))
					if system_cursor_type ~= "arrow" then
						system_cursor_type = "arrow"
					end
				end
				if TARGET_FPS ~= math.huge then
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

			if time_accumulator > 0.2 + FRAME_DURATION then
				time_accumulator = 0
			end
		end
	end
end
