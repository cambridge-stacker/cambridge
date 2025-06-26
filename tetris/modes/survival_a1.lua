require 'funcs'

local MarathonA1Game = require 'tetris.modes.marathon_a1'
local Piece = require 'tetris.components.piece'

local History4RollsRandomizer = require 'tetris.randomizers.history_4rolls'

local SurvivalA1Game = MarathonA1Game:extend()

SurvivalA1Game.name = "Survival A1"
SurvivalA1Game.hash = "SurvivalA1"
SurvivalA1Game.tagline = "A constant high-speed marathon!"
SurvivalA1Game.tags = {"Survival", "Arika"}

function SurvivalA1Game:getGravity()
	return 20
end

return SurvivalA1Game
