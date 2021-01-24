local Object = require 'libs.classic'
local Piece = require 'tetris.components.piece'

local Ruleset = Object:extend()

Ruleset.name = ""
Ruleset.hash = ""

-- Arika-type ruleset defaults
Ruleset.world = false
Ruleset.colourscheme = {
	I = "R",
	L = "O",
	J = "B",
	S = "M",
	Z = "G",
	O = "Y",
	T = "C",
}
Ruleset.softdrop_lock = true
Ruleset.harddrop_lock = false

Ruleset.enable_IRS_wallkicks = false
Ruleset.are_cancel = false
Ruleset.are = true

Ruleset.next_sounds = {
		I = "I",
		L = "L",
		J = "J",
		S = "S",
		Z = "Z",
		O = "O",
		T = "T"
}

Ruleset.draw_offsets = {
	I = { x=0, y=0 },
	J = { x=0, y=0 },
	L = { x=0, y=0 },
	O = { x=0, y=0 },
	S = { x=0, y=0 },
	T = { x=0, y=0 },
	Z = { x=0, y=0 },
}

Ruleset.pieces = 7

-- Component functions.

function Ruleset:new()
	
	if config.gamesettings.piece_colour == 1 then
		blocks["bone"] = (not self.world) and
		{
			R = love.graphics.newImage("res/img/bone.png"),
			O = love.graphics.newImage("res/img/bone.png"),
			Y = love.graphics.newImage("res/img/bone.png"),
			G = love.graphics.newImage("res/img/bone.png"),
			C = love.graphics.newImage("res/img/bone.png"),
			B = love.graphics.newImage("res/img/bone.png"),
			M = love.graphics.newImage("res/img/bone.png"),
			F = love.graphics.newImage("res/img/bone.png"),
			A = love.graphics.newImage("res/img/bone.png"),
			X = love.graphics.newImage("res/img/bone.png"),
		} or {
			R = love.graphics.newImage("res/img/bonew.png"),
			O = love.graphics.newImage("res/img/bonew.png"),
			Y = love.graphics.newImage("res/img/bonew.png"),
			G = love.graphics.newImage("res/img/bonew.png"),
			C = love.graphics.newImage("res/img/bonew.png"),
			B = love.graphics.newImage("res/img/bonew.png"),
			M = love.graphics.newImage("res/img/bonew.png"),
			F = love.graphics.newImage("res/img/bonew.png"),
			A = love.graphics.newImage("res/img/bonew.png"),
			X = love.graphics.newImage("res/img/bonew.png"),
		}
	else
		blocks["bone"] = (config.gamesettings.piece_colour == 2) and
                {
                        R = love.graphics.newImage("res/img/bone.png"),
                        O = love.graphics.newImage("res/img/bone.png"),
                        Y = love.graphics.newImage("res/img/bone.png"),
                        G = love.graphics.newImage("res/img/bone.png"),
                        C = love.graphics.newImage("res/img/bone.png"),
                        B = love.graphics.newImage("res/img/bone.png"),
                        M = love.graphics.newImage("res/img/bone.png"),
                        F = love.graphics.newImage("res/img/bone.png"),
                        A = love.graphics.newImage("res/img/bone.png"),
                        X = love.graphics.newImage("res/img/bone.png"),
                } or {
                        R = love.graphics.newImage("res/img/bonew.png"),
                        O = love.graphics.newImage("res/img/bonew.png"),
                        Y = love.graphics.newImage("res/img/bonew.png"),
                        G = love.graphics.newImage("res/img/bonew.png"),
                        C = love.graphics.newImage("res/img/bonew.png"),
                        B = love.graphics.newImage("res/img/bonew.png"),
                        M = love.graphics.newImage("res/img/bonew.png"),
                        F = love.graphics.newImage("res/img/bonew.png"),
                        A = love.graphics.newImage("res/img/bonew.png"),
                        X = love.graphics.newImage("res/img/bonew.png"),
                }
	end
end

function Ruleset:rotatePiece(inputs, piece, grid, prev_inputs, initial)
	local new_inputs = {}

	for input, value in pairs(inputs) do
		if value and not prev_inputs[input] then
			new_inputs[input] = true
		end
	end

	local was_drop_blocked = piece:isDropBlocked(grid)

	self:attemptRotate(new_inputs, piece, grid, initial)

	if not was_drop_blocked and piece:isDropBlocked(grid) then
		playSE("bottom")
	end

	-- prev_inputs becomes the previous inputs
	for input, value in pairs(inputs) do
		prev_inputs[input] = inputs[input]
	end
end

function Ruleset:attemptRotate(new_inputs, piece, grid, initial)
	local rot_dir = 0
	
	if (new_inputs["rotate_left"] or new_inputs["rotate_left2"]) then
		rot_dir = 3
	elseif (new_inputs["rotate_right"] or new_inputs["rotate_right2"]) then
		rot_dir = 1
	elseif (new_inputs["rotate_180"]) then
		rot_dir = self:get180RotationValue()
	end

	if rot_dir == 0 then return end
    if config.gamesettings.world_reverse == 3 or (self.world and config.gamesettings.world_reverse == 2) then
        rot_dir = 4 - rot_dir
    end

	local new_piece = piece:withRelativeRotation(rot_dir)

	if (grid:canPlacePiece(new_piece)) then
		piece:setRelativeRotation(rot_dir)
		self:onPieceRotate(piece, grid)
	else
		if not(initial and self.enable_IRS_wallkicks == false) then
			self:attemptWallkicks(piece, new_piece, rot_dir, grid)
		end
	end
end

function Ruleset:attemptWallkicks(piece, new_piece, rot_dir, grid)
	-- do nothing in default ruleset
end

function Ruleset:movePiece(piece, grid, move, instant)
	local x = piece.position.x
	local was_drop_blocked = piece:isDropBlocked(grid)
	if move == "left" then
		piece:moveInGrid({x=-1, y=0}, 1, grid, false)
	elseif move == "right" then
		piece:moveInGrid({x=1, y=0}, 1, grid, false)
	elseif move == "speedleft" then
		piece:moveInGrid({x=-1, y=0}, grid.width, grid, instant)
	elseif move == "speedright" then
		piece:moveInGrid({x=1, y=0}, grid.width, grid, instant)
	end
	if piece.position.x ~= x then
		self:onPieceMove(piece, grid)
		if not was_drop_blocked and piece:isDropBlocked(grid) then
			playSE("bottom")
		end
	end
end

function Ruleset:dropPiece(
	inputs, piece, grid, gravity, drop_speed, drop_locked, hard_drop_locked,
	hard_drop_enabled, additive_gravity
)
	if piece.big then
		gravity = gravity / 2
		drop_speed = drop_speed / 2
	end

	local y = piece.position.y
	if inputs["down"] == true and drop_locked == false then
		if additive_gravity then
			piece:addGravity(gravity + drop_speed, grid)
		else
			piece:addGravity(math.max(gravity, drop_speed), grid)
		end
	elseif inputs["up"] == true and hard_drop_enabled == true then
		if hard_drop_locked == true or piece:isDropBlocked(grid) then
			piece:addGravity(gravity, grid)
		else
			piece:dropToBottom(grid)
		end
	else
		piece:addGravity(gravity, grid)
	end
	if piece.position.y ~= y then
		self:onPieceDrop(piece, grid)
	end
end

function Ruleset:lockPiece(piece, grid, lock_delay)
	if piece:isDropBlocked(grid) and piece.gravity >= 1 and piece.lock_delay >= lock_delay then
		piece.locked = true
	end
end

function Ruleset:get180RotationValue() return 2 end
function Ruleset:getDefaultOrientation() return 1 end

function Ruleset:initializePiece(
	inputs, data, grid, gravity, prev_inputs,
	move, lock_delay, drop_speed,
	drop_locked, hard_drop_locked, big, irs,
	buffer_hard_drop, buffer_soft_drop,
	lock_on_hard_drop, lock_on_soft_drop
)
	local spawn_positions
	if big then
		spawn_positions = self.big_spawn_positions
	else
		spawn_positions = self.spawn_positions
	end
	local colours = ({self.colourscheme, ColourSchemes.Arika, ColourSchemes.TTC})[config.gamesettings.piece_colour]
	
	local spawn_x
	if (grid.width ~= 10) then
		local percent = spawn_positions[data.shape].x / 10
		for i = 0, grid.width - 1 do
			if i / grid.width >= percent then
				spawn_x = i
				break
			end
		end
	end

	local spawn_dy = (
		config.gamesettings.spawn_positions == 2 and
		2 or 0
	)

	local piece = Piece(data.shape, data.orientation - 1, {
		x = spawn_x and spawn_x or spawn_positions[data.shape].x,
		y = spawn_positions[data.shape].y - spawn_dy
	}, self.block_offsets, 0, 0, data.skin, colours[data.shape], big)

	self:onPieceCreate(piece)
	if irs then
		self:rotatePiece(inputs, piece, grid, {}, true)
		if (data.orientation - 1) ~= piece.rotation then
			playSE("irs")
		end
	end
	self:dropPiece(inputs, piece, grid, gravity, drop_speed, drop_locked, hard_drop_locked)
	if (buffer_hard_drop and config.gamesettings.buffer_lock == 1) then
		piece:dropToBottom(grid)
		if lock_on_hard_drop then piece.locked = true end
	end
	if (buffer_soft_drop and lock_on_soft_drop and piece:isDropBlocked(grid) and config.gamesettings.buffer_lock == 1) then
		piece.locked = true
	end
	return piece
end

-- stuff like move count, rotate count, floorkick count go here
function Ruleset:onPieceCreate(piece) end

function Ruleset:processPiece(
	inputs, piece, grid, gravity, prev_inputs,
	move, lock_delay, drop_speed,
	drop_locked, hard_drop_locked,
	hard_drop_enabled, additive_gravity
)

	local synchroes_allowed = ({not self.world, true, false})[config.gamesettings.synchroes_allowed]

	if synchroes_allowed then
		self:rotatePiece(inputs, piece, grid, prev_inputs, false)
		self:movePiece(piece, grid, move, gravity >= 20)
	else
		self:movePiece(piece, grid, move, gravity >= 20)
		self:rotatePiece(inputs, piece, grid, prev_inputs, false)
	end
	self:dropPiece(
		inputs, piece, grid, gravity, drop_speed, drop_locked, hard_drop_locked,
		hard_drop_enabled, additive_gravity
	)
	self:lockPiece(piece, grid, lock_delay)
end

function Ruleset:onPieceMove(piece) end
function Ruleset:onPieceRotate(piece) end
function Ruleset:onPieceDrop(piece) end

return Ruleset
