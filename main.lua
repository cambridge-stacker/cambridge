function love.load()
	math.randomseed(os.time())
	highscores = {}
	love.graphics.setDefaultFilter("linear", "nearest")
	require "load.rpc"
	require "load.graphics"
	require "load.fonts"
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

	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable = true});
		
	-- used for screenshots
	GLOBAL_CANVAS = love.graphics.newCanvas()

	-- init config
	initConfig()

	love.window.setFullscreen(config["fullscreen"])
	if config.secret then playSE("welcome") end

	-- import custom modules
	initModules()

	generateSoundTable()

	loadReplayList()
end
function initModules()
	game_modes = {}
	mode_list = love.filesystem.getDirectoryItems("tetris/modes")
	for i=1,#mode_list do
		if(mode_list[i] ~= "gamemode.lua" and string.sub(mode_list[i], -4) == ".lua") then
			game_modes[#game_modes+1] = require ("tetris.modes."..string.sub(mode_list[i],1,-5))
		end
	end
	rulesets = {}
	rule_list = love.filesystem.getDirectoryItems("tetris/rulesets")
	for i=1,#rule_list do
		if(rule_list[i] ~= "ruleset.lua" and string.sub(rule_list[i], -4) == ".lua") then
			rulesets[#rulesets+1] = require ("tetris.rulesets."..string.sub(rule_list[i],1,-5))
		end
	end
	--sort mode/rule lists
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(game_modes, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	table.sort(rulesets, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
end

--#region Tetro48's code


local io_thread

function loadReplayList()
	replays = {}
	replay_tree = {{name = "All"}}
	dict_ref = {}
	loaded_replays = false
	io_thread = love.thread.newThread( replay_load_code )
	local mode_names = {}
	for key, value in pairs(game_modes) do
		table.insert(mode_names, value.name)
	end
	io_thread:start(mode_names)
end

function nilCheck(input, default)
	if input == nil then
		return default
	end
	return input
end

function popFromChannel(channel_name)
	local load_from = love.thread.getChannel(channel_name):pop()
	if load_from then
		return load_from
	end
end

left_clicked_before = false
right_clicked_before = false
prev_cur_pos_x, prev_cur_pos_y = 0, 0
is_cursor_visible = true
mouse_idle = 0
TAS_mode = false
frame_steps = 0
loaded_replays = false

-- For when mouse controls are part of menu controls
function getScaledPos(cursor_x, cursor_y)
	local screen_x, screen_y = love.graphics.getDimensions()
	local scale_factor = math.min(screen_x / 640, screen_y / 480)
	return (cursor_x - (screen_x - scale_factor * 640) / 2)/scale_factor, (cursor_y - (screen_y - scale_factor * 480) / 2)/scale_factor
end

function CursorHighlight(x,y,w,h)
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if mouse_idle > 2 or config.visualsettings.cursor_highlight ~= 1 then
		return 1
	end
	if mouse_x > x and mouse_x < x+w and mouse_y > y and mouse_y < y+h then
		return 0
	else
		return 1
	end
end
--Interpolates in a smooth fashion.
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
function drawT48Cursor(x, y, a)
	if a <= 0 then return end
    love.graphics.setColor(1,1,1,a)
    love.graphics.polygon("fill", x + 5, y + 0, x + 0, y + 10, x + 5, y + 8, x + 8, y + 20, x + 12, y + 18, x + 10, y + 7, x + 15, y + 5)
    love.graphics.setColor(0,0,0,a)
    love.graphics.polygon("line", x + 5, y + 0, x + 0, y + 10, x + 5, y + 8, x + 8, y + 20, x + 12, y + 18, x + 10, y + 7, x + 15, y + 5)
    love.graphics.setColor(1,1,1,a)
end
--#endregion

local function drawTASWatermark()
	love.graphics.setFont(font_3x5_4)
	love.graphics.setColor(1, 1, 1, 0.2)
	love.graphics.printf(
		"T A S", -250, 550, 150, "center", -0.75, 8, 8
	)
end

function love.draw()
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

	if scene.replay then
		if scene.replay["toolassisted"] == true then
			drawTASWatermark()
		end
	end

	if TAS_mode then
		if scene.title == "Game" or scene.title == "Replay" and not scene.replay["toolassisted"] == true then
			drawTASWatermark()
		end
		love.graphics.setColor(1, 1, 1, love.timer.getTime() % 2 < 1 and 1 or 0)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"TAS MODE ON", 240, 0, 160, "center"
		)
	end
	if config.visualsettings.display_gamemode == 1 or scene.title == "Title" then
		love.graphics.setFont(font_3x5_2)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(
			string.format("%.2f", 1 / love.timer.getAverageDelta()) ..
			"fps - " .. version, 0, 460, 635, "right"
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
end

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
	elseif scancode == "f3" and TAS_mode and (scene.title == "Game" or scene.title == "Replay") then
		frame_steps = frame_steps + 1
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
		GLOBAL_CANVAS:newImageData():encode("png", ss_name)
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- escape is reserved for menu_back except in modes
	elseif scancode == "escape" and not scene.game then
		scene:onInputPress({input="menu_back", type="key", key=key, scancode=scancode})
	-- pass any other key to the scene, with its configured mapping
	else
		if config.input and config.input.keys then
			local result_inputs = {}
			for input_type, value in pairs(config.input.keys) do
				if scancode == value then
					table.insert(result_inputs, input_type)
				end
			end
			for _, input in pairs(result_inputs) do
				scene:onInputPress({input=input, type="key", key=key, scancode=scancode})
			end
			if #result_inputs == 0 then
				scene:onInputPress({type="key", key=key, scancode=scancode})
			end
		end
	end
end

function love.keyreleased(key, scancode)
	-- escape is reserved for menu_back
	if scancode == "escape" then
		scene:onInputRelease({input="menu_back", type="key", key=key, scancode=scancode})
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- handle all other keys; tab is reserved, but the input config scene keeps it from getting configured as a game input, so pass tab to the scene here
	else
		if config.input and config.input.keys then
			local result_inputs = {}
			for input_type, value in pairs(config.input.keys) do
				if scancode == value then
					table.insert(result_inputs, input_type)
				end
			end
			for _, input in pairs(result_inputs) do
				scene:onInputRelease({input=input, type="key", key=key, scancode=scancode})
			end
			if #result_inputs == 0 then
				scene:onInputRelease({type="key", key=key, scancode=scancode})
			end
		end
	end
end

function love.joystickpressed(joystick, button)
	local input_pressed = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].buttons
	then
		input_pressed = config.input.joysticks[joystick:getName()].buttons[button]
	end
	scene:onInputPress({input=input_pressed, type="joybutton", name=joystick:getName(), button=button})
end

function love.joystickreleased(joystick, button)
	local input_released = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].buttons
	then
		input_released = config.input.joysticks[joystick:getName()].buttons[button]
	end
	scene:onInputRelease({input=input_released, type="joybutton", name=joystick:getName(), button=button})
end

function love.joystickaxis(joystick, axis, value)
	local input_pressed = nil
	local positive_released = nil
	local negative_released = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].axes and
		config.input.joysticks[joystick:getName()].axes[axis] 
	then
		if math.abs(value) >= 1 then
			input_pressed = config.input.joysticks[joystick:getName()].axes[axis][value >= 1 and "positive" or "negative"]
		end
		positive_released = config.input.joysticks[joystick:getName()].axes[axis].positive
		negative_released = config.input.joysticks[joystick:getName()].axes[axis].negative
	end
	if math.abs(value) >= 1 then
		scene:onInputPress({input=input_pressed, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
	else
		scene:onInputRelease({input=positive_released, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		scene:onInputRelease({input=negative_released, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
	end
end

local last_hat_direction = ""
local directions = {
	["u"] = "up",
	["d"] = "down",
	["l"] = "left",
	["r"] = "right",
}

function love.joystickhat(joystick, hat, direction)
	local input_pressed = nil
	local has_hat = false
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].hats and
		config.input.joysticks[joystick:getName()].hats[hat]
	then
		if direction ~= "c" then
			input_pressed = config.input.joysticks[joystick:getName()].hats[hat][direction]
		end
		has_hat = true
	end
	if input_pressed then
		for i = 1, #direction do
			local char = direction:sub(i, i)
			local _, count = last_hat_direction:gsub(char, char)
			if count == 0 then
				scene:onInputPress({input=config.input.joysticks[joystick:getName()].hats[hat][char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		for i = 1, #last_hat_direction do
			local char = last_hat_direction:sub(i, i)
			local _, count = direction:gsub(char, char)
			if count == 0 then
				scene:onInputRelease({input=config.input.joysticks[joystick:getName()].hats[hat][char], type="joyhat", name=joystick:getName(), hat=hat, direction=char})
			end
		end
		last_hat_direction = direction
	elseif has_hat then
		for i, direction in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			scene:onInputRelease({input=config.input.joysticks[joystick:getName()].hats[hat][direction], type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
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
		for i, direction in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			scene:onInputRelease({input=nil, type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
		end
		last_hat_direction = ""
	end
end

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

function love.resize(w, h)
		GLOBAL_CANVAS:release()
		GLOBAL_CANVAS = love.graphics.newCanvas(w, h)
end

local TARGET_FPS = 60

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	if love.timer then love.timer.step() end

	local dt = 0

	local last_time = love.timer.getTime()
	local time_accumulator = 0
	return function()
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
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
			
			local frame_duration = 1.0 / TARGET_FPS
			if time_accumulator < frame_duration then
				if love.graphics and love.graphics.isActive() and love.draw then
					love.graphics.origin()
					love.graphics.clear(love.graphics.getBackgroundColor())
					love.draw()
					love.graphics.present()
				end
				local end_time = last_time + frame_duration
				local time = love.timer.getTime()
				while time < end_time do
					love.timer.sleep(0.001)
					time = love.timer.getTime()
				end
				time_accumulator = time_accumulator + time - last_time
			end
			time_accumulator = time_accumulator - frame_duration
			if love.mouse then 
				left_clicked_before = love.mouse.isDown(1) or mouse_idle > 2
				right_clicked_before = love.mouse.isDown(2) or mouse_idle > 2
				if prev_cur_pos_x == love.mouse.getX() and prev_cur_pos_y == love.mouse.getY() then
					mouse_idle = mouse_idle + love.timer.getDelta()
				else
					mouse_idle = 0
				end
				prev_cur_pos_x, prev_cur_pos_y = love.mouse.getPosition()
			end
		end
		last_time = love.timer.getTime()
	end
end
