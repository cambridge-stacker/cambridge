local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.ruleset'

local SRS = Ruleset:extend()

SRS.name = "Guideline SRS"
SRS.hash = "Standard"
SRS.softdrop_lock = false
SRS.harddrop_lock = true

SRS.MANIPULATIONS_MAX = 15

function SRS:onPieceRotate(piece, grid)
	piece.lock_delay = 0 -- rotate reset
	self:check_new_low(piece)
	piece.manipulations = piece.manipulations + 1
	if piece:isDropBlocked(grid) then
		if piece.manipulations >= SRS.MANIPULATIONS_MAX then
			piece.locked = true
		end
	end
end

return SRS
