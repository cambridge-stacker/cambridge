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
Ruleset.spawn_above_field = false

Ruleset.next_sounds = {
		I = "I",
		L = "L",
		J = "J",
		S = "S",
		Z = "Z",
		O = "O",
		T = "T"
}

Ruleset.pieces = 7

-- Component functions.

function Ruleset:new(game_mode)
	self.game = game_mode
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

	if self:canPieceRotate(piece, grid) then
		self:attemptRotate(new_inputs, piece, grid, initial)
	end

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
	if not self:canPieceMove(piece, grid) then return end
	local was_drop_blocked = piece:isDropBlocked(grid)
	local offset = ({x=0, y=0})
	local moves = 0
	if move == "left" then
		offset.x = -1
		moves = 1
	elseif move == "right" then
		offset.x = 1
		moves = 1
	elseif move == "speedleft" then
		offset.x = -1
		moves = grid.width
	elseif move == "speedright" then
		offset.x = 1
		moves = grid.width
	end
	for i = 1, moves do
		local x = piece.position.x
		if moves ~= 1 then
			piece:moveInGrid(offset, 1, grid, instant)
		else
			piece:moveInGrid(offset, 1, grid, false)
		end
		if piece.position.x ~= x then
			self:onPieceMove(piece, grid)
			if piece.locked then break end
		end
	end
	if not was_drop_blocked and piece:isDropBlocked(grid) then
		playSE("bottom")
	end
end

function Ruleset:dropPiece(
	inputs, piece, grid, gravity, drop_speed, drop_locked, hard_drop_locked,
	hard_drop_enabled, additive_gravity, classic_lock
)
	if piece.big then
		gravity = gravity / 2
		drop_speed = drop_speed / 2
	end

	local y = piece.position.y
	if inputs["down"] == true and drop_locked == false then
		if additive_gravity then
			piece:addGravity(gravity + drop_speed, grid, classic_lock)
		else
			piece:addGravity(math.max(gravity, drop_speed), grid, classic_lock)
		end
	elseif inputs["up"] == true and hard_drop_enabled == true then
		if hard_drop_locked == true or piece:isDropBlocked(grid) then
			piece:addGravity(gravity, grid, classic_lock)
		else
			piece:dropToBottom(grid)
		end
	else
		piece:addGravity(gravity, grid, classic_lock)
	end
	if piece.position.y ~= y then
		self:onPieceDrop(piece, grid)
	end
end

function Ruleset:lockPiece(piece, grid, lock_delay, classic_lock)
	if piece:isDropBlocked(grid) and (
		(classic_lock and piece.gravity >= 1) or
		(not classic_lock and piece.lock_delay >= lock_delay)
	) then
		piece.locked = true
	end
end

function Ruleset:get180RotationValue() return 2 end
function Ruleset:getDefaultOrientation() return 1 end
function Ruleset:getDrawOffset(shape, orientation) return { x=0, y=0 } end
function Ruleset:getAboveFieldOffset(shape, orientation)
	if shape == "I" then
		return 1
	else
		return 2
	end
end

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

	local colours
	if self.pieces == 7 then
		colours = ({self.colourscheme, ColourSchemes.Arika, ColourSchemes.TTC})[config.gamesettings.piece_colour]
	else
		colours = self.colourscheme
	end
	
	local spawn_x
	if (grid.width ~= 10) then
		local percent = spawn_positions[data.shape].x / 10
		for i = grid.width - 1, 0, -1 do
			if i / grid.width <= percent then
				spawn_x = i
				break
			end
		end
	end

	local spawn_dy
	if (config.gamesettings.spawn_positions == 1) then
		spawn_dy = (
			self.spawn_above_field and
			self:getAboveFieldOffset(data.shape, data.orientation) or 0
		)
	else
		spawn_dy = (
			config.gamesettings.spawn_positions == 3 and
			self:getAboveFieldOffset(data.shape, data.orientation) or 0
		)
	end

	local piece = Piece(data.shape, data.orientation - 1, {
		x = spawn_x or spawn_positions[data.shape].x,
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
	hard_drop_enabled, additive_gravity, classic_lock
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
		hard_drop_enabled, additive_gravity, classic_lock
	)
	self:lockPiece(piece, grid, lock_delay, classic_lock)
end

function Ruleset:canPieceMove(piece, grid) return true end
function Ruleset:canPieceRotate(piece, grid) return true end
function Ruleset:onPieceMove(piece) end
function Ruleset:onPieceRotate(piece) end
function Ruleset:onPieceDrop(piece) end

return Ruleset
