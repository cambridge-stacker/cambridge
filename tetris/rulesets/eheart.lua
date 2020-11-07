local Piece = require 'tetris.components.piece'
local ARS = require 'tetris.rulesets.arika'

local EHeart = ARS:extend()

EHeart.name = "E-Heart ARS"
EHeart.hash = "EHeartARS"

function EHeart:attemptWallkicks(piece, new_piece, rot_dir, grid)

	-- I and O don't kick
	if (piece.shape == "I" or piece.shape == "O") then return end

	-- center column rule (kicks)
	local offsets = new_piece:getBlockOffsets()
		table.sort(offsets, function(A, B) return A.y < B.y or A.y == B.y and A.x < B.y end)
		for index, offset in pairs(offsets) do
			if grid:isOccupied(piece.position.x + offset.x, piece.position.y + offset.y) then
		-- individual checks for all 9 cells, in the given order
				if offset.y < 0 then
			if offset.x < 0 then self:lateralKick(1, piece, new_piece, rot_dir, grid)
			elseif offset.x == 0 then return
			elseif offset.x > 0 then self:lateralKick(-1, piece, new_piece, rot_dir, grid) end
		elseif offset.y == 0 then
			if offset.x < 0 then self:lateralKick(1, piece, new_piece, rot_dir, grid)
						elseif offset.x == 0 then return
						elseif offset.x > 0 then self:lateralKick(-1, piece, new_piece, rot_dir, grid) end
				elseif offset.y > 0 then
			if offset.x < 0 then self:lateralKick(1, piece, new_piece, rot_dir, grid)
						elseif offset.x == 0 then return
						elseif offset.x > 0 then self:lateralKick(-1, piece, new_piece, rot_dir, grid) end
				end
			end
		end

end

function EHeart:lateralKick(dx, piece, new_piece, rot_dir, grid)
	if (grid:canPlacePiece(new_piece:withOffset({x=dx, y=0}))) then
		piece:setRelativeRotation(rot_dir):setOffset({x=dx, y=0})
		self:onPieceRotate(piece, grid)
	end
end

return EHeart
