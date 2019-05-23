local Randomizer = require 'tetris.randomizers.randomizer'

local History6RollsRandomizer = Randomizer:extend()

function History6RollsRandomizer:initialize()
	self.history = {"Z", "S", "Z", "S"}
	self.bag_counts = {
		I = 5, J = 5, L = 5, O = 5, S = 3, T = 5, Z = 3
	}
end

function History6RollsRandomizer:getBagPiece(n)
	for shape, count in pairs(self.bag_counts) do
		n = n - count
		if n <= 0 then
			return shape
		end
	end
end

function History6RollsRandomizer:generatePiece()
	for i = 1, 6 do
		local x = self:getBagPiece(math.random(31))
		if not inHistory(x, self.history) or i == 6 then
			return self:updateHistory(x)
		end
	end
end

function History6RollsRandomizer:updateHistory(shape)
	self.bag_counts[shape] = self.bag_counts[shape] - 1
	local replaced_piece = table.remove(self.history, 1)
	table.insert(self.history, shape)
	self.bag_counts[replaced_piece] = self.bag_counts[replaced_piece] + 1
	return shape
end

function inHistory(piece, history)
	for idx, entry in pairs(history) do
		if entry == piece then
			return true
		end
	end
	return false
end

return History6RollsRandomizer
