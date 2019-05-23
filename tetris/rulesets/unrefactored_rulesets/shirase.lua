Piece = require("tetris.components.piece")
require("funcs")

local SRS = {}

SRS.name = "SHIRASE"
SRS.hash = "Shirase"

SRS.spawn_positions = {
	I = { x=5, y=4 },
	J = { x=4, y=5 },
	L = { x=4, y=5 },
	O = { x=5, y=5 },
	S = { x=4, y=5 },
	T = { x=4, y=5 },
	Z = { x=4, y=5 },
}

SRS.block_offsets = {
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

SRS.wallkicks_3x3 = {
	[0]={
		[1]={{x=-1, y=0}, {x=-1, y=-1}, {x=0, y=2}, {x=-1, y=2}},
		[2]={{x=0, y=1}, {x=0, y=-1}},
		[3]={{x=1, y=0}, {x=1, y=-1}, {x=0, y=2}, {x=1, y=2}},
	},
	[1]={
		[0]={{x=1, y=0}, {x=1, y=1}, {x=0, y=-2}, {x=1, y=-2}},
		[2]={{x=1, y=0}, {x=1, y=1}, {x=0, y=-2}, {x=1, y=-2}},
		[3]={{x=0, y=1}, {x=0, y=-1}},
	},
	[2]={
		[0]={{x=0, y=1}, {x=0, y=-1}},
		[1]={{x=-1, y=0}, {x=-1, y=-1}, {x=0, y=2}, {x=-1, y=2}},
		[3]={{x=1, y=0}, {x=1, y=-1}, {x=0, y=2}, {x=1, y=2}},
	},
	[3]={
		[0]={{x=-1, y=0}, {x=-1, y=1}, {x=0, y=-2}, {x=-1, y=-2}},
		[1]={{x=0, y=1}, {x=0, y=-1}},
		[2]={{x=-1, y=0}, {x=-1, y=1}, {x=0, y=-2}, {x=-1, y=-2}},
	},
};

SRS.wallkicks_line = {
	[0]={
		[1]={{x=-2, y=0}, {x=1, y=0}, {x=-2, y=1}, {x=1, y=-2}},
		[2]={},
		[3]={{x=-1, y=0}, {x=2, y=0}, {x=-1, y=-2}, {x=2, y=1}},
	},
	[1]={
		[0]={{x=2, y=0}, {x=-1, y=0}, {x=2, y=-1}, {x=-1, y=2}},
		[2]={{x=-1, y=0}, {x=2, y=0}, {x=-1, y=-2}, {x=2, y=1}},
		[3]={{x=0, y=1}, {x=0, y=-1}, {x=0, y=2}, {x=0, y=-2}},
	},
	[2]={
		[0]={},
		[1]={{x=1, y=0}, {x=-2, y=0}, {x=1, y=2}, {x=-2, y=-1}},
		[3]={{x=2, y=0}, {x=-1, y=0}, {x=2, y=-1}, {x=-1, y=2}},
	},
	[3]={
		[0]={{x=1, y=0}, {x=-2, y=0}, {x=1, y=2}, {x=-2, y=-1}},
		[1]={{x=0, y=1}, {x=0, y=-1}, {x=0, y=2}, {x=0, y=-2}},
		[2]={{x=-2, y=0}, {x=1, y=0}, {x=-2, y=1}, {x=1, y=-2}},
	},
};

local basicOffsets = {
	[0] = { x = 1, y = 0 },
	[1] = { x = 0, y = 1 },
	[2] = { x = -1, y = 0 },
	[3] = { x = 0, y = -1 }
}

-- Component functions.

local function rotatePiece(inputs, piece, grid, prev_inputs)
	local new_inputs = {}

	for input, value in pairs(inputs) do
		if value and not prev_inputs[input] then
			new_inputs[input] = true
		end
	end

	local rot_dir = 0
	if (new_inputs["rotate_left"] or new_inputs["rotate_left2"]) then
		rot_dir = 3
	elseif (new_inputs["rotate_right"] or new_inputs["rotate_right2"]) then
		rot_dir = 1
	elseif (new_inputs["rotate_180"]) then
		rot_dir = 2
	end

	while rot_dir ~= 0 do
		rotated_piece = piece:withRelativeRotation(rot_dir)
		rotation_offset = vAdd(
			basicOffsets[piece.rotation],
			vNeg(basicOffsets[rotated_piece.rotation])
		)
		new_piece = rotated_piece:withOffset(rotation_offset)

		if (grid:canPlacePiece(new_piece)) then
			piece:setRelativeRotation(rot_dir)
			piece:setOffset(rotation_offset)
			piece.lock_delay = 0 -- rotate reset
			break
		end

		if piece.shape == "I" then
			kicks = SRS.wallkicks_line[piece.rotation][new_piece.rotation]
		else
			kicks = SRS.wallkicks_3x3[piece.rotation][new_piece.rotation]
		end

		for idx, offset in pairs(kicks) do
			kicked_piece = new_piece:withOffset(offset)
			if grid:canPlacePiece(kicked_piece) then
				piece:setRelativeRotation(rot_dir)
				piece:setOffset(vAdd(offset, rotation_offset))
				piece.lock_delay = 0 -- rotate reset
				rot_dir = 0
			end
			if rot_dir == 0 then
				break
			end
		end

		rot_dir = 0
	end

	-- prev_inputs becomes the previous inputs
	for input, value in pairs(inputs) do
		prev_inputs[input] = inputs[input]
	end
end

local function movePiece(piece, grid, move)
	if move == "left" then
		if not piece:isMoveBlocked(grid, {x=-1, y=0}) then
			piece.lock_delay = 0 -- move reset
		end
		piece:moveInGrid({x=-1, y=0}, 1, grid)
	elseif move == "right" then
		if not piece:isMoveBlocked(grid, {x=1, y=0}) then
			piece.lock_delay = 0 -- move reset
		end
		piece:moveInGrid({x=1, y=0}, 1, grid)
	end
end

local function dropPiece(inputs, piece, grid, gravity, drop_speed, drop_locked)
	local y = piece.position.y
	if inputs["down"] == true and drop_locked == false then
		piece:addGravity(gravity + 1, grid):lockIfBottomed(grid)
	elseif inputs["up"] == true then
		if piece:isDropBlocked(grid) then
			return
		end
		piece:dropToBottom(grid)
	else
		piece:addGravity(gravity, grid)
	end
	if piece.position.y ~= y then -- step reset
		piece.lock_delay = 0
	end
end

local function lockPiece(piece, grid, lock_delay)
	if piece:isDropBlocked(grid) and piece.lock_delay >= lock_delay then
		piece.locked = true
	end
end

function SRS.initializePiece(inputs, data, grid, gravity, prev_inputs, move, lock_delay, drop_speed, drop_locked)
	local piece = Piece(shape, 0, {
		x = SRS.spawn_positions[shape].x,
		y = SRS.spawn_positions[shape].y
	}, SRS.block_offsets, 0, 0)
	-- have to copy that object otherwise it gets referenced
	rotatePiece(inputs, piece, grid, {})
	dropPiece(inputs, piece, grid, gravity, drop_speed, drop_locked)
	return piece
end

function SRS.processPiece(inputs, piece, grid, gravity, prev_inputs, move, lock_delay, drop_speed, drop_locked)
	rotatePiece(inputs, piece, grid, prev_inputs)
	movePiece(piece, grid, move)
	dropPiece(inputs, piece, grid, gravity, drop_speed, drop_locked)
	lockPiece(piece, grid, lock_delay)
end

return SRS
