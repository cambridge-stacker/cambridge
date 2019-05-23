local Object = require 'libs.classic'

local Randomizer = Object:extend()

function Randomizer:new()
	self:initialize()
	self.next_queue = {}
	for i = 1, 30 do
		table.insert(self.next_queue, self:generatePiece())
	end
end

function Randomizer:nextPiece()
	table.insert(self.next_queue, self:generatePiece())
	return table.remove(self.next_queue, 1)
end

function Randomizer:initialize()
	-- do nothing
end

local shapes = {"I", "J", "L", "O", "S", "T", "Z"}

function Randomizer:generatePiece()
	return shapes[math.random(7)]
end

return Randomizer
