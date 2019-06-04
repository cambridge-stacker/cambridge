local Randomizer = require 'tetris.randomizers.randomizer'

local AlwaysRandomizer = Randomizer:extend()

function AlwaysRandomizer:new(piece)
	self.piece = piece
	self:initialize()
	self.next_queue = {}
	for i = 1, 30 do
		table.insert(self.next_queue, self:generatePiece())
	end
end

function AlwaysRandomizer:generatePiece()
	return self.piece
end

return AlwaysRandomizer
