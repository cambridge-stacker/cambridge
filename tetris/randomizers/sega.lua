local Randomizer = require 'tetris.randomizers.randomizer'

local SegaRandomizer = Randomizer:extend()

function SegaRandomizer:initialize()
	self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
	self.sequence = {}
	for i = 1, 1000 do
		self.sequence[i] = self.bag[math.random(table.getn(self.bag))]
	end
	self.counter = 0
end

function SegaRandomizer:generatePiece()
	self.counter = self.counter + 1
	return self.sequence[self.counter % 1000 + 1]
end

return SegaRandomizer
