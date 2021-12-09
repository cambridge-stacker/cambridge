local Randomizer = require 'tetris.randomizers.randomizer'

local Bag7NoSZOStartRandomizer = Randomizer:extend()

function Bag7NoSZOStartRandomizer:shuffleBag()
	local b = self.bag
	local ln = #b
	for i = 1, ln do
		local j = love.math.random(i, ln)
		b[i], b[j] = b[j], b[i]
	end
end

local function isnotSZO(x) return not(x == "S" or x == "Z" or x == "O") end 

function Bag7NoSZOStartRandomizer:initialize()
	self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
	repeat
		self:shuffleBag()
	until isnotSZO(self.bag[7])
end

function Bag7NoSZOStartRandomizer:generatePiece()
	if #self.bag == 0 then
		self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
		self:shuffleBag()
	end
	return table.remove(self.bag)
end

return Bag7NoSZOStartRandomizer
