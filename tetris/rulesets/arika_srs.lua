local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.ti_srs'

local SRS = Ruleset:extend()

SRS.name = "ACE-SRS"
SRS.hash = "ACE Standard"

SRS.MANIPULATIONS_MAX = 128

SRS.spawn_positions = {
	I = { x=5, y=2 },
	J = { x=4, y=3 },
	L = { x=4, y=3 },
	O = { x=5, y=3 },
	S = { x=4, y=3 },
	T = { x=4, y=3 },
	Z = { x=4, y=3 },
}

SRS.big_spawn_positions = {
	I = { x=3, y=0 },
	J = { x=2, y=1 },
	L = { x=2, y=1 },
	O = { x=3, y=1 },
	S = { x=2, y=1 },
	T = { x=2, y=1 },
	Z = { x=2, y=1 },
}

function SRS:onPieceRotate(piece, grid)
	piece.lock_delay = 0 -- rotate reset
	if piece:isDropBlocked(grid) then
        piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= self.MANIPULATIONS_MAX then
			piece.locked = true
		end
	end
end

return SRS
