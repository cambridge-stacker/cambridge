local Object = require 'libs.classic'

local Randomizer = Object:extend()

function Randomizer:new()
	self.possible_pieces = {"I", "J", "L", "O", "S", "T", "Z"}
	self:initialize()
end

function Randomizer:nextPiece()
	return self:generatePiece()
end

function Randomizer:initialize()
	-- do nothing
end

function Randomizer:generatePiece()
	return self.possible_pieces[math.random(7)]
end

return Randomizer
