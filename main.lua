function love.load()
	math.randomseed(os.time())
	highscores = {}
	require "load.rpc"
	require "load.graphics"
	require "load.fonts"
	require "load.sounds"
	require "load.bgm"
	require "load.save"
	loadSave()
	require "scene"
	config["side_next"] = false
	config["reverse_rotate"] = true
	config["fullscreen"] = false

	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable = true});

    if not config.gamesettings then config.gamesettings = {} end
    for _, option in ipairs(GameConfigScene.options) do
        if not config.gamesettings[option[1]] then
            config.gamesettings[option[1]] = 1
        end
    end
    
	if not config.input then
		config.input = {}
		scene = InputConfigScene()
	else
		if config.current_mode then current_mode = config.current_mode end
		if config.current_ruleset then current_ruleset = config.current_ruleset end
		scene = TitleScene()
	end
end

local TARGET_FPS = 60
local SAMPLE_SIZE = 60

local rolling_samples = {}
local rolling_total = 0
local average_n = 0
local frame = 0

function getSmoothedDt(dt)
	rolling_total = rolling_total + dt
	frame = frame + 1
	if frame > SAMPLE_SIZE then frame = frame - SAMPLE_SIZE end
	if average_n == SAMPLE_SIZE then
		rolling_total = rolling_total - rolling_samples[frame]
	else
		average_n = average_n + 1
	end
	rolling_samples[frame] = dt
	return rolling_total / average_n
end

local update_time = 0.52

function love.update(dt)
	processBGMFadeout(dt)
	local old_update_time = update_time
	update_time = update_time + getSmoothedDt(dt) * TARGET_FPS
	updates = 0
	while (update_time >= 1.02) do
		scene:update()
		updates = updates + 1
		update_time = update_time - 1
	end
	if math.abs(update_time - old_update_time) < 0.02 then
		update_time = old_update_time
	end
end

function love.draw()
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
	love.graphics.pop()
end

function love.keypressed(key, scancode, isrepeat)
	-- global hotkeys
	if scancode == "f4" then
		config["fullscreen"] = not config["fullscreen"]
		love.window.setFullscreen(config["fullscreen"])
	else
		scene:onKeyPress({key=key, scancode=scancode, isRepeat=isrepeat})
	end
end

function love.focus(f)
	if f then
		resumeBGM()
	else
		pauseBGM()
	end
end
