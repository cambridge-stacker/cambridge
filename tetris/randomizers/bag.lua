local Randomizer = require 'tetris.randomizers.randomizer'

local BagRandomizer = Randomizer:extend()

function BagRandomizer:new(pieces)
    self.bag = {}
    self.pieces = pieces
    for i = 1, self.pieces do
        table.insert(self.bag, i)
    end
end

function BagRandomizer:generatePiece()
	if next(self.bag) == nil then
		for i = 1, self.pieces do
            table.insert(self.bag, i)
        end
	end
	local x = math.random(table.getn(self.bag))
	return table.remove(self.bag, x)
end

return BagRandomizer
