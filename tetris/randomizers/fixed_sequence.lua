local Randomizer = require 'tetris.randomizers.randomizer'

local Sequence = Randomizer:extend()

function Sequence:initialize()
    self.sequence = "IJLOT"
    self.counter = 0
end

function Sequence:generatePiece()
    local piece = string.sub(self.sequence, self.counter + 1, self.counter + 1)
    self.counter = (self.counter + 1) % string.len(self.sequence)
    return piece
end

return Sequence