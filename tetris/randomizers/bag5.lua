local Randomizer = require 'tetris.randomizers.randomizer'

local Bag5Randomizer = Randomizer:extend()

function Bag5Randomizer:initialize()
	self.bag = {"I", "J", "L", "O", "T"}
end

function Bag5Randomizer:generatePiece()
	if next(self.bag) == nil then
		self.bag = {"I", "J", "L", "O", "T"}
	end
	local x = math.random(table.getn(self.bag))
	return table.remove(self.bag, x)
end

return Bag5Randomizer
