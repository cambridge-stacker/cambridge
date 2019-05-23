local Randomizer = require 'tetris.randomizers.randomizer'

local AlwaysORandomizer = Randomizer:extend()

function AlwaysORandomizer:generatePiece()
	return "O"
end

return AlwaysORandomizer
