local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.standard_exp'

local SRS = Ruleset:extend()

SRS.name = "Guideline SRS"
SRS.hash = "Standard"
SRS.softdrop_lock = false
SRS.harddrop_lock = true

SRS.MANIPULATIONS_MAX = 15

function SRS:onPieceDrop(piece, grid)
	self:checkNewLow(piece)
	if piece.manipulations >= self.MANIPULATIONS_MAX and piece:isDropBlocked(grid) then
		piece.locked = true
	else
		piece.lock_delay = 0 -- step reset
	end
end

function SRS:onPieceMove(piece, grid)
	piece.lock_delay = 0 -- move reset
	if piece:isDropBlocked(grid) then
		piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= SRS.MANIPULATIONS_MAX then
			piece.locked = true
		end
	end
end

function SRS:onPieceRotate(piece, grid)
	piece.lock_delay = 0 -- rotate reset
	self:checkNewLow(piece)
	piece.manipulations = piece.manipulations + 1
	if piece:isDropBlocked(grid) then
		if piece.manipulations >= SRS.MANIPULATIONS_MAX then
			piece.locked = true
		end
	end
end

return SRS
