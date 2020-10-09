local Randomizer = require 'tetris.randomizers.randomizer'

local History6RollsRandomizer = Randomizer:extend()

function History6RollsRandomizer:initialize()
	self.history = {"Z", "S", "Z", "S"}
    self.first = true
end

function History6RollsRandomizer:generatePiece()
    if self.first then
        self.first = false
        return self:updateHistory(({"L", "J", "I", "T"})[math.random(4)])
    else
        local shapes = {"I", "J", "L", "O", "S", "T", "Z"}
        for i = 1, 6 do
            local x = math.random(7)
            if not inHistory(shapes[x], self.history) or i == 6 then
                return self:updateHistory(shapes[x])
            end
        end
    end
end

function History6RollsRandomizer:updateHistory(shape)
	table.remove(self.history, 1)
	table.insert(self.history, shape)
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
