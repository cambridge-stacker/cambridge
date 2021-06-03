local binser = require 'libs.binser'

function loadSave()
	local info = love.filesystem.getInfo(
		love.filesystem.getSaveDirectory(), "directory"
	)
	if not info then
		love.filesystem.remove(love.filesystem.getSaveDirectory())
		love.filesystem.createDirectory(love.filesystem.getSaveDirectory())
	end
	config = loadFromFile(
		love.filesystem.getSaveDirectory() .. '/config.sav'
	)
	highscores = loadFromFile(
		love.filesystem.getSaveDirectory() .. '/highscores.sav'
	)
end

function loadFromFile(filename)
	local save_data, len = binser.readFile(filename)
	if save_data == nil then
		return {} -- new object
	end
	return save_data[1]
end

function initConfig()
	if not config.das then config.das = 10 end
	if not config.arr then config.arr = 2 end
	if not config.dcd then config.dcd = 0 end
	if not config.sfx_volume then config.sfx_volume = 0.5 end
	if not config.bgm_volume then config.bgm_volume = 0.5 end
	
	if config.fullscreen == nil then config.fullscreen = false end
	if config.secret == nil then config.secret = false end

	if not config.gamesettings then config.gamesettings = {} end
	for _, option in ipairs(GameConfigScene.options) do
		if not config.gamesettings[option[1]] then
			config.gamesettings[option[1]] = 1
		end
	end
	
	if not config.input then
		scene = InputConfigScene()
	else
		if config.current_mode then current_mode = config.current_mode end
		if config.current_ruleset then current_ruleset = config.current_ruleset end
		scene = TitleScene()
	end
end

function saveConfig()
	binser.writeFile(
		love.filesystem.getSaveDirectory() .. '/config.sav', config
	)
end

function saveHighscores()
	binser.writeFile(
		love.filesystem.getSaveDirectory() .. '/highscores.sav', highscores
	)
end
