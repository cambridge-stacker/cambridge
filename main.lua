function love.load()
	math.randomseed(os.time())
	highscores = {}
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

function love.draw()
	love.graphics.setCanvas(GLOBAL_CANVAS)
	love.graphics.clear()

	love.graphics.push()

	-- get offset matrix
	love.graphics.setDefaultFilter("linear", "nearest")
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local scale_factor = math.min(width / 640, height / 480)
	love.graphics.translate(
		(width - scale_factor * 640) / 2,
		(height - scale_factor * 480) / 2
	)
	love.graphics.scale(scale_factor)
		
	scene:render()

	if config.gamesettings.display_gamemode == 1 or scene.title == "Title" then
		love.graphics.setFont(font_3x5_2)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(version, 0, 460, 635, "right")
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
	elseif scancode == "f2" and scene.title ~= "Input Config" and scene.title ~= "Game" then
		scene = InputConfigScene()
		switchBGM(nil)
	-- secret sound playing :eyes:
	elseif scancode == "f8" and scene.title == "Title" then
		config.secret = not config.secret
		saveConfig()
		scene.restart_message = true
		if config.secret then playSE("mode_decide")
		else playSE("erase") end
		-- f12 is reserved for saving screenshots
		elseif scancode == "f12" then
				local ss_name = os.date("ss/%Y-%m-%d_%H-%M-%S.png")
		local info = love.filesystem.getInfo("ss", "directory")
		if not info then
			love.filesystem.remove("ss")
			love.filesystem.createDirectory("ss")
		end
		print("Saving screenshot as "..ss_name)
		GLOBAL_CANVAS:newImageData():encode("png", ss_name)
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- escape is reserved for menu_back
	elseif scancode == "escape" then
		scene:onInputPress({input="menu_back", type="key", key=key, scancode=scancode})
	-- pass any other key to the scene, with its configured mapping
	else
		local input_pressed = nil
		if config.input and config.input.keys then
			input_pressed = config.input.keys[scancode]
		end
		scene:onInputPress({input=input_pressed, type="key", key=key, scancode=scancode})
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
		local input_released = nil
		if config.input and config.input.keys then
			input_released = config.input.keys[scancode]
		end
		scene:onInputRelease({input=input_released, type="key", key=key, scancode=scancode})
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
		end
		last_time = love.timer.getTime()
	end
end
