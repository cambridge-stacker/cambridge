local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.arika_ace2'

local ARS = Ruleset:extend()

ARS.name = "ARS-X"
ARS.hash = "ArikaEXP"
ARS.description = "ARS, but with 180 spins."

ARS.MANIPULATIONS_MAX = 24
ARS.ROTATIONS_MAX = 12

function ARS:onPieceCreate(piece, grid)
	piece.manipulations = 0
	piece.rotations = 0
	piece.lowest_y = -math.huge
end

function ARS:checkNewLow(piece)
	for _, block in pairs(piece:getBlockOffsets()) do
		local y = piece.position.y + block.y
		if y > piece.lowest_y then
			piece.manipulations = 0
			piece.rotations = 0
			piece.lowest_y = y
		end
	end
end

function ARS:onPieceMove(piece, grid)
	piece.lock_delay = 0 -- move reset
	if piece:isDropBlocked(grid) then
		piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= ARS.MANIPULATIONS_MAX then
			piece.locked = true
		end
	end
end

function ARS:onPieceRotate(piece, grid, upward)
	piece.lock_delay = 0 -- rotate reset
	if upward or piece:isDropBlocked(grid) then
        piece.rotations = piece.rotations + 1
		if piece.rotations >= ARS.ROTATIONS_MAX and piece:isDropBlocked(grid) then
			piece.locked = true
		end
	end
end

return ARS