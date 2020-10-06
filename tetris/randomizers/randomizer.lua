local Object = require 'libs.classic'

local Randomizer = Object:extend()

function Randomizer:new()
	self:initialize()
end

function Randomizer:nextPiece()
	return self:generatePiece()
end

function Randomizer:initialize()
	-- do nothing
end

local shapes = {"I", "J", "L", "O", "S", "T", "Z"}

function Randomizer:generatePiece()
	return shapes[math.random(7)]
end

return Randomizer
