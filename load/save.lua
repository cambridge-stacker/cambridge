local binser = require 'libs.binser'

function loadSave()
	config = loadFromFile('config.sav')
	highscores = loadFromFile('highscores.sav')
end

function loadFromFile(filename)
	local save_data, len = binser.readFile(filename)
	if save_data == nil then
		return {} -- new object
	end
	return save_data[1]
end



function saveConfig()
	binser.writeFile('config.sav', config)
end

function saveHighscores()
	binser.writeFile('highscores.sav', highscores)
end
