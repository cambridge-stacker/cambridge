local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.arika_srs'

local SRS = Ruleset:extend()

SRS.name = "Guideline SRS"
SRS.hash = "Standard"

SRS.enable_IRS_wallkicks = true

function SRS:check_new_low(piece)
	for _, block in pairs(piece:getBlockOffsets()) do
		local y = piece.position.y + block.y
		if y > piece.lowest_y then
			piece.manipulations = 0
			piece.lowest_y = y
		end
	end
end

function SRS:onPieceCreate(piece, grid)
	piece.manipulations = 0
	piece.lowest_y = -math.huge
end

function SRS:onPieceDrop(piece, grid)
	self:check_new_low(piece)
	if piece.manipulations >= 15 and piece:isDropBlocked(grid) then
		piece.locked = true
	else
		piece.lock_delay = 0 -- step reset
	end
end

function SRS:onPieceMove(piece, grid)
	piece.lock_delay = 0 -- move reset
	if piece:isDropBlocked(grid) then
		piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= 15 then
			piece.locked = true
		end
	end
end

function SRS:onPieceRotate(piece, grid)
	piece.lock_delay = 0 -- rotate reset
	self:check_new_low(piece)
	piece.manipulations = piece.manipulations + 1
	if piece:isDropBlocked(grid) then
		if piece.manipulations >= 15 then
			piece.locked = true
		end
	end
end

function SRS:get180RotationValue() return 2 end

return SRS
