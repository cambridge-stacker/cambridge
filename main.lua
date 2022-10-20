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

	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable = true});
		
	-- used for screenshots
	GLOBAL_CANVAS = love.graphics.newCanvas()

	-- init config
	initConfig()

	love.window.setFullscreen(config["fullscreen"])

	-- import custom modules
	initModules()

	generateSoundTable()

	loadReplayList()

	-- this is executed after the sound table is generated. why is that is unknown.
	if config.secret then playSE("welcome") end
end
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
		end
	end
end
function initModules()
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


local function recursionStringValueExtract(tbl, get_from, key_check)
	local result = {}
	for key, value in pairs(tbl) do
		print(value, get_from, key_check)
		if type(value) == "table" and (key_check == nil or value[key_check]) then
			local recursion_result = recursionStringValueExtract(value, get_from, key_check)
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

	--proper disposal to avoid some memory problems
	if io_thread then
		io_thread:release()
		love.thread.getChannel( 'replays' ):clear()
		love.thread.getChannel( 'replay_tree' ):clear()
		love.thread.getChannel( 'dict_ref' ):clear()
		love.thread.getChannel( 'loaded_replays' ):clear()
	end

	io_thread = love.thread.newThread( replay_load_code )
	local mode_names = {}
	for key, value in pairs(recursionStringValueExtract(game_modes, "name", "is_directory")) do
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

local highlights = 0

function CursorHighlight(x,y,w,h)
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if mouse_idle > 2 or config.visualsettings.cursor_highlight ~= 1 then
		return 1
	end
	if mouse_x > x and mouse_x < x+w and mouse_y > y and mouse_y < y+h then
		highlights = highlights + 1
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
	acc = acc / #time_table
	if math.floor(love.timer.getTime()) + dt > love.timer.getTime() then
		last_fps = acc
	end
	return last_fps
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

	drawWatermarks()

	if config.visualsettings.display_gamemode == 1 or scene.title == "Title" then
		love.graphics.setFont(font_3x5_2)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(
			string.format("%.2f", 1.0 / getMeanDelta()) ..
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

local function multipleInputs(input_table, input)
	local result_inputs = {}
	for input_type, value in pairs(input_table) do
		if input == value then
			table.insert(result_inputs, input_type)
		end
	end
	return result_inputs
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
			local result_inputs = multipleInputs(config.input.keys, scancode)
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
			local result_inputs = multipleInputs(config.input.keys, scancode)
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
	if config.input and config.input.joysticks then
		local result_inputs = {}
		if config.input.joysticks[joystick:getName()] then
			result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "buttons-"..button)
		end
		for _, input in pairs(result_inputs) do
			scene:onInputPress({input=input, type="joybutton", name=joystick:getName(), button=button})
		end
		if #result_inputs == 0 then
			scene:onInputPress({type="joybutton", name=joystick:getName(), button=button})
		end
	end
	-- scene:onInputPress({input=input_pressed, type="joybutton", name=joystick:getName(), button=button})
end

function love.joystickreleased(joystick, button)
	local input_released = nil
	if config.input and config.input.joysticks then
		local result_inputs = {}
		if config.input.joysticks[joystick:getName()] then
			result_inputs = multipleInputs(config.input.joysticks[joystick:getName()], "buttons-"..button)
		end
		for _, input in pairs(result_inputs) do
			scene:onInputRelease({input=input, type="joybutton", name=joystick:getName(), button=button})
		end
		if #result_inputs == 0 then
			scene:onInputRelease({type="joybutton", name=joystick:getName(), button=button})
		end
	end
	-- scene:onInputRelease({input=input_released, type="joybutton", name=joystick:getName(), button=button})
end

function love.joystickaxis(joystick, axis, value)
	local input_pressed = nil
	if config.input and config.input.joysticks then
		if math.abs(value) >= 1 then
			local result_inputs = {}
			if config.input.joysticks[joystick:getName()] then
				result_inputs = multipleInputs(config.input.joysticks[joystick:getName()],"axes-"..axis.."-"..(value >= 1 and "positive" or "negative"))
				for _, input in pairs(result_inputs) do
					scene:onInputPress({input=input, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
				end
			end
			if #result_inputs == 0 then
				scene:onInputPress({type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
			-- scene:onInputPress({input=input_pressed, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		else
			local result_inputs = {}
			if config.input.joysticks[joystick:getName()] then
				for input_type, v in pairs(config.input.joysticks[joystick:getName()]) do
					if "axes-"..axis.."-".."negative" == v then
						table.insert(result_inputs, input_type)
					end
					if "axes-"..axis.."-".."positive" == v then
						table.insert(result_inputs, input_type)
					end
				end
			end
			for _, input in pairs(result_inputs) do
				scene:onInputRelease({input=input, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
			if #result_inputs == 0 then
				scene:onInputRelease({type="joyaxis", name=joystick:getName(), axis=axis, value=value})
			end
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
		for i, direction in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			scene:onInputRelease({input=directions[direction], type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
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
local FRAME_DURATION = 1.0 / TARGET_FPS

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

			if time_accumulator < FRAME_DURATION then
				if love.graphics and love.graphics.isActive() and love.draw then
					love.graphics.origin()
					love.graphics.clear(love.graphics.getBackgroundColor())
					love.draw()
					love.graphics.present()
				end

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

			local finish_delay_time = love.timer.getTime()
			local real_frame_duration = finish_delay_time - last_time
			time_accumulator = time_accumulator + real_frame_duration - FRAME_DURATION
			last_time = finish_delay_time
		end
	end
end
