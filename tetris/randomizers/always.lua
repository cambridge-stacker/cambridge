local Randomizer = require 'tetris.randomizers.randomizer'

local AlwaysRandomizer = Randomizer:extend()

function AlwaysRandomizer:generatePiece()
	return "I"
end

return AlwaysRandomizer
