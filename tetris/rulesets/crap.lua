local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.ruleset'

local CRAP = Ruleset:extend()

CRAP.name = "C.R.A.P."
CRAP.hash = "Completely Random Auto-Positioner"
CRAP.world = true
CRAP.colors={"C","O","M","R","G","Y","B"}
CRAP.colourscheme = {
    I = CRAP.colors[math.ceil(math.random(7))],
    L = CRAP.colors[math.ceil(math.random(7))],
    J = CRAP.colors[math.ceil(math.random(7))],
    S = CRAP.colors[math.ceil(math.random(7))],
    Z = CRAP.colors[math.ceil(math.random(7))],
    O = CRAP.colors[math.ceil(math.random(7))],
    T = CRAP.colors[math.ceil(math.random(7))],
}
CRAP.softdrop_lock = true
CRAP.harddrop_lock = false

CRAP.enable_IRS_wallkicks = true

CRAP.spawn_positions = {
	I = { x=5, y=4 },
	J = { x=4, y=5 },
	L = { x=4, y=5 },
	O = { x=5, y=5 },
	S = { x=4, y=5 },
	T = { x=4, y=5 },
	Z = { x=4, y=5 },
}

CRAP.big_spawn_positions = {
	I = { x=3, y=2 },
	J = { x=2, y=3 },
	L = { x=2, y=3 },
	O = { x=3, y=3 },
	S = { x=2, y=3 },
	T = { x=2, y=3 },
	Z = { x=2, y=3 },
}

CRAP.block_offsets = {
	I={
		{ {x=0, y=0}, {x=-1, y=0}, {x=-2, y=0}, {x=1, y=0} },
		{ {x=0, y=0}, {x=0, y=-1}, {x=0, y=1}, {x=0, y=2} },
		{ {x=0, y=1}, {x=-1, y=1}, {x=-2, y=1}, {x=1, y=1} },
		{ {x=-1, y=0}, {x=-1, y=-1}, {x=-1, y=1}, {x=-1, y=2} },
	},
	J={
		{ {x=0, y=0}, {x=-1, y=0}, {x=1, y=0}, {x=-1, y=-1} },
		{ {x=0, y=0}, {x=0, y=-1}, {x=0, y=1} , {x=1, y=-1} },
		{ {x=0, y=0}, {x=1, y=0}, {x=-1, y=0}, {x=1, y=1} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=-1}, {x=-1, y=1} },
	},
	L={
		{ {x=0, y=0}, {x=-1, y=0}, {x=1, y=0}, {x=1, y=-1} },
		{ {x=0, y=0}, {x=0, y=-1}, {x=0, y=1}, {x=1, y=1} },
		{ {x=0, y=0}, {x=1, y=0}, {x=-1, y=0}, {x=-1, y=1} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=-1}, {x=-1, y=-1} },
	},
	O={
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=-1, y=0}, {x=-1, y=-1}, {x=0, y=-1} },
	},
	S={
		{ {x=1, y=-1}, {x=0, y=-1}, {x=0, y=0}, {x=-1, y=0} },
		{ {x=1, y=1}, {x=1, y=0}, {x=0, y=0}, {x=0, y=-1} },
		{ {x=-1, y=1}, {x=0, y=1}, {x=0, y=0}, {x=1, y=0} },
		{ {x=-1, y=-1}, {x=-1, y=0}, {x=0, y=0}, {x=0, y=1} },
	},
	T={
		{ {x=0, y=0}, {x=-1, y=0}, {x=1, y=0}, {x=0, y=-1} },
		{ {x=0, y=0}, {x=0, y=-1}, {x=0, y=1}, {x=1, y=0} },
		{ {x=0, y=0}, {x=1, y=0}, {x=-1, y=0}, {x=0, y=1} },
		{ {x=0, y=0}, {x=0, y=1}, {x=0, y=-1}, {x=-1, y=0} },
	},
	Z={
		{ {x=-1, y=-1}, {x=0, y=-1}, {x=0, y=0}, {x=1, y=0} },
		{ {x=1, y=-1}, {x=1, y=0}, {x=0, y=0}, {x=0, y=1} },
		{ {x=1, y=1}, {x=0, y=1}, {x=0, y=0}, {x=-1, y=0} },
		{ {x=-1, y=1}, {x=-1, y=0}, {x=0, y=0}, {x=0, y=-1} },
	}
}

-- Component functions.

function CRAP:attemptRotate(new_inputs, piece, grid, initial)
	local rot_dir = 0
	
	if (new_inputs["rotate_left"] or new_inputs["rotate_left2"]) then
		rot_dir = 3
	elseif (new_inputs["rotate_right"] or new_inputs["rotate_right2"]) then
		rot_dir = 1
	elseif (new_inputs["rotate_180"]) then
		rot_dir = self:get180RotationValue()
	end

	if rot_dir == 0 then return end
    if self.world and config.gamesettings.world_reverse == 2 then
        rot_dir = 4 - rot_dir
    end
	
	local new_piece = piece:withRelativeRotation(rot_dir)
	
	self:attemptWallkicks(piece, new_piece, rot_dir, grid)
end

function CRAP:attemptWallkicks(piece, new_piece, rot_dir, grid)

	for i=1,20 do
		dx=math.floor(math.random(11))-5
		dy=math.floor(math.random(11))-5
		if grid:canPlacePiece(new_piece:withOffset({x=dx, y=dy})) then
			piece:setRelativeRotation(rot_dir):setOffset({x=dx, y=dy})
			self:onPieceRotate(piece, grid)
			return
		end
	end
	
end

function CRAP:onPieceCreate(piece, grid)
	CRAP:randomizeColours()
	piece.manipulations = 0
	piece.rotations = 0
end

function CRAP:onPieceDrop(piece, grid)
	CRAP:randomizeColours()
	piece.lock_delay = 0 -- step reset
end

function CRAP:onPieceMove(piece, grid)
	CRAP:randomizeColours()
	piece.lock_delay = 0 -- move reset
	if piece:isDropBlocked(grid) then
		piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= 10 then
			piece.locked = true
		end
	end
end

function CRAP:onPieceRotate(piece, grid)
	CRAP:randomizeColours()
	piece.lock_delay = 0 -- rotate reset
	if piece:isDropBlocked(grid) then
		piece.rotations = piece.rotations + 1
		if piece.rotations >= 8 then
			piece.locked = true
		end
	end
end

function CRAP:get180RotationValue() return 2 end

function CRAP:randomizeColours()
	CRAP.colourscheme = {
		I = CRAP.colors[math.ceil(math.random(7))],
		L = CRAP.colors[math.ceil(math.random(7))],
		J = CRAP.colors[math.ceil(math.random(7))],
		S = CRAP.colors[math.ceil(math.random(7))],
		Z = CRAP.colors[math.ceil(math.random(7))],
		O = CRAP.colors[math.ceil(math.random(7))],
		T = CRAP.colors[math.ceil(math.random(7))],
	}
end

return CRAP
