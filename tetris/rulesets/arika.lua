local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.ruleset'

local ARS = Ruleset:extend()

ARS.name = "Classic ARS"
ARS.hash = "Arika"

ARS.spawn_positions = {
	I = { x=5, y=4 },
	J = { x=4, y=5 },
	L = { x=4, y=5 },
	O = { x=5, y=5 },
	S = { x=4, y=5 },
	T = { x=4, y=5 },
	Z = { x=4, y=5 },
}

ARS.block_offsets = {
	I={
		{ {x=0, y=0}, {x=-1, y=0}, {x=-2, y=0}, {x=1, y=0} },
		{ {x=0, y=0}, {x=0, y=-1}, {x=0, y=1}, {x=0, y=2} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-2, y=0}, {x=1, y=0} },
		{ {x=0, y=0}, {x=0, y=-1}, {x=0, y=1}, {x=0, y=2} },
	},
	J={
		{ {x=0, y=0}, {x=-1, y=0}, {x=1, y=0}, {x=-1, y=-1} },
		{ {x=0, y=-1}, {x=1, y=-2}, {x=0, y=-2}, {x=0, y=0} },
		{ {x=0, y=-1}, {x=-1, y=-1}, {x=1, y=-1}, {x=1, y=0} },
		{ {x=0, y=-1}, {x=0, y=-2}, {x=0, y=0}, {x=-1, y=0} },
	},
	L={
		{ {x=0, y=0}, {x=-1, y=0}, {x=1, y=0}, {x=1, y=-1} },
		{ {x=0, y=-2}, {x=0, y=-1}, {x=1, y=0}, {x=0, y=0} },
		{ {x=0, y=-1}, {x=-1, y=-1}, {x=1, y=-1}, {x=-1, y=0} },
		{ {x=0, y=-1}, {x=-1, y=-2}, {x=0, y=-2}, {x=0, y=0} },
	},
	O={
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
	},
	S={
		{ {x=1, y=-1}, {x=0, y=-1}, {x=0, y=0}, {x=-1, y=0} },
		{ {x=-1, y=-2}, {x=-1, y=-1}, {x=0, y=-1}, {x=0, y=0} },
		{ {x=1, y=-1}, {x=0, y=-1}, {x=0, y=0}, {x=-1, y=0} },
		{ {x=-1, y=-2}, {x=-1, y=-1}, {x=0, y=-1}, {x=0, y=0} },
	},
	T={
		{ {x=0, y=0}, {x=-1, y=0}, {x=1, y=0}, {x=0, y=-1} },
		{ {x=0, y=-1}, {x=0, y=0}, {x=1, y=-1}, {x=0, y=-2} },
		{ {x=0, y=-1}, {x=-1, y=-1}, {x=1, y=-1}, {x=0, y=0} },
		{ {x=0, y=-1}, {x=0, y=0}, {x=-1, y=-1}, {x=0, y=-2} },
	},
	Z={
		{ {x=0, y=-1}, {x=-1, y=-1}, {x=1, y=0}, {x=0, y=0} },
		{ {x=0, y=-1}, {x=0, y=0}, {x=1, y=-2}, {x=1, y=-1} },
		{ {x=0, y=-1}, {x=-1, y=-1}, {x=1, y=0}, {x=0, y=0} },
		{ {x=0, y=-1}, {x=0, y=0}, {x=1, y=-2}, {x=1, y=-1} },
	}
}

function ARS:attemptWallkicks(piece, new_piece, rot_dir, grid)

	-- I and O don't kick
	if (piece.shape == "I" or piece.shape == "O") then return end

	-- center column rule
	if (
		piece.shape == "J" or piece.shape == "T" or piece.shape == "L"
	) and (
		piece.rotation == 0 or piece.rotation == 2
	) and (
		grid:isOccupied(piece.position.x, piece.position.y) or
		grid:isOccupied(piece.position.x, piece.position.y - 1) or
		grid:isOccupied(piece.position.x, piece.position.y - 2)
	) then return end

	-- kick right, kick left
	if (grid:canPlacePiece(new_piece:withOffset({x=1, y=0}))) then
		piece:setRelativeRotation(rot_dir):setOffset({x=1, y=0})
		self:onPieceRotate(piece, grid)
	elseif (grid:canPlacePiece(new_piece:withOffset({x=-1, y=0}))) then
		piece:setRelativeRotation(rot_dir):setOffset({x=-1, y=0})
		self:onPieceRotate(piece, grid)
	end

end

function ARS:onPieceDrop(piece, grid)
	piece.lock_delay = 0 -- step reset
end

function ARS:get180RotationValue() return config["reverse_rotate"] and 1 or 3 end
function ARS:getDefaultOrientation() return 3 end  -- downward facing pieces by default

return ARS
