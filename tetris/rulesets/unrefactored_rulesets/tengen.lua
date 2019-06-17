local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.ruleset'

local Tengen = Ruleset:extend()

Tengen.name = "Tengen"
Tengen.hash = "Tengen"

Tengen.spawn_positions = {
	I = { x=3, y=4 },
	J = { x=4, y=4 },
	L = { x=4, y=4 },
	O = { x=5, y=4 },
	S = { x=4, y=4 },
	T = { x=4, y=4 },
	Z = { x=4, y=4 },
}

Tengen.block_offsets = {
	I={
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
	},
	J={
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=2, y=1} },
		{ {x=1, y=0}, {x=1, y=1}, {x=1, y=2}, {x=0, y=2} },
		{ {x=0, y=0}, {x=0, y=1}, {x=1, y=1}, {x=2, y=1} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=1, y=0} },
	},
	L={
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=0, y=1} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=1, y=2} },
		{ {x=2, y=0}, {x=0, y=1}, {x=1, y=1}, {x=2, y=1} },
		{ {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=1, y=2} },
	},
	O={
		{ {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=0, y=1} },
		{ {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=0, y=1} },
		{ {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=0, y=1} },
		{ {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=0, y=1} },
	},
	-- up to here
	S={
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
	},
	T={
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
	},
	Z={
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
		{ {x=0, y=0}, {x=1, y=0}, {x=2, y=0}, {x=3, y=0} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=2}, {x=0, y=3} },
	}
}


-- Component functions.

function Tengen:attemptWallkicks(piece, new_piece, rot_dir, grid)

	-- O doesn't kick
	if (piece.shape == "O") then return end

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

	if piece.shape == "I" then
		-- special kick rules for I
		if new_piece.rotation == 0 or new_piece.rotation == 2 then
			-- kick right, right2, left
			if grid:canPlacePiece(new_piece:withOffset({x=1, y=0})) then
				piece:setRelativeRotation(rot_dir):setOffset({x=1, y=0})
				self:onPieceRotate(piece, grid)
			elseif grid:canPlacePiece(new_piece:withOffset({x=2, y=0})) then
				piece:setRelativeRotation(rot_dir):setOffset({x=2, y=0})
				self:onPieceRotate(piece, grid)
			elseif grid:canPlacePiece(new_piece:withOffset({x=-1, y=0})) then
				piece:setRelativeRotation(rot_dir):setOffset({x=-1, y=0})
				self:onPieceRotate(piece, grid)
			end
		elseif piece:isDropBlocked(grid) and (new_piece.rotation == 1 or new_piece.rotation == 3) and piece.floorkick == 0 then
			-- kick up, up2
			if grid:canPlacePiece(new_piece:withOffset({x=0, y=-1})) then
				piece:setRelativeRotation(rot_dir):setOffset({x=0, y=-1})
				self:onPieceRotate(piece, grid)
				piece.floorkick = 1
			elseif grid:canPlacePiece(new_piece:withOffset({x=0, y=-2})) then
				piece:setRelativeRotation(rot_dir):setOffset({x=0, y=-2})
				self:onPieceRotate(piece, grid)
				piece.floorkick = 1
			end
		end
	elseif piece.shape ~= "I" then
			-- kick right, kick left
			if (grid:canPlacePiece(new_piece:withOffset({x=1, y=0}))) then
				piece:setRelativeRotation(rot_dir):setOffset({x=1, y=0})
			elseif (grid:canPlacePiece(new_piece:withOffset({x=-1, y=0}))) then
				piece:setRelativeRotation(rot_dir):setOffset({x=-1, y=0})
			end
		else
	end

end

function Tengen:onPieceCreate(piece, grid)
	piece.floorkick = 0
end

function Tengen:onPieceDrop(piece, grid)
	piece.lock_delay = 0 -- step reset
end

function Tengen:get180RotationValue() return config["reverse_rotate"] and 1 or 3 end
function Tengen:getDefaultOrientation() return 3 end  -- downward facing pieces by default

return Tengen
