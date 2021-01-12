local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.ti_srs'

local SRS = Ruleset:extend()

SRS.name = "ACE-SRS"
SRS.hash = "ACE Standard"

SRS.MANIPULATIONS_MAX = 128

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
