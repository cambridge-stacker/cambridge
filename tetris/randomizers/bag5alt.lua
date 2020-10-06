local Randomizer = require 'tetris.randomizers.randomizer'

local Bag5AltRandomizer = Randomizer:extend()

function Bag5AltRandomizer:initialize()
	self.bag = {"I", "J", "L", "O", "T"}
	self.prev = "O"
end

function Bag5AltRandomizer:generatePiece()
	if next(self.bag) == nil then
		self.bag = {"I", "J", "L", "O", "T"}
	end
	local x = math.random(table.getn(self.bag))
	local temp = table.remove(self.bag, x)
	if temp == self.prev then
		local y = math.random(table.getn(self.bag))
		temp = table.remove(self.bag, y)
	end
	self.prev = temp
	return temp
end

return Bag5AltRandomizer
