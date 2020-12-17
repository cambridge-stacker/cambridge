local Object = require 'libs.classic'

local Piece = Object:extend()

function Piece:new(shape, rotation, position, block_offsets, gravity, lock_delay, skin, colour, big)
	self.shape = shape
	self.rotation = rotation
	self.position = position
	self.block_offsets = block_offsets
	self.gravity = gravity
	self.lock_delay = lock_delay
	self.skin = skin
	self.colour = colour
	self.ghost = false
	self.locked = false
	self.big = big
end

-- Functions that return a new piece to test in rotation systems.

function Piece:withOffset(offset)
	return Piece(
		self.shape, self.rotation,
		{x = self.position.x + offset.x, y = self.position.y + offset.y},
		self.block_offsets, self.gravity, self.lock_delay, self.skin, self.colour, self.big
	)
end

function Piece:withRelativeRotation(rot)
	local new_rot = self.rotation + rot
	while new_rot < 0 do new_rot = new_rot + 4 end
	while new_rot >= 4 do new_rot = new_rot - 4 end
	return Piece(
		self.shape, new_rot, self.position,
		self.block_offsets, self.gravity, self.lock_delay, self.skin, self.colour, self.big
	)
end

-- Functions that return predicates relative to a grid.

function Piece:getBlockOffsets()
	return self.block_offsets[self.shape][self.rotation + 1]
end

function Piece:occupiesSquare(x, y)
	local offsets = self:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local new_offset = {x = self.position.x + offset.x, y = self.position.y + offset.y}
		if new_offset.x == x and new_offset.y == y then
			return true
		end
	end
	return false
end

function Piece:isMoveBlocked(grid, offset)
	local moved_piece = self:withOffset(offset)
	return not grid:canPlacePiece(moved_piece)
end

function Piece:isDropBlocked(grid)
	return self:isMoveBlocked(grid, { x=0, y=1 })
end

-- Procedures to actually do stuff to pieces.

function Piece:setOffset(offset)
	self.position.x = self.position.x + offset.x
	self.position.y = self.position.y + offset.y
	return self
end

function Piece:setRelativeRotation(rot)
	new_rot = self.rotation + rot
	while new_rot < 0 do new_rot = new_rot + 4 end
	while new_rot >= 4 do new_rot = new_rot - 4 end
	self.rotation = new_rot
	return self
end

function Piece:moveInGrid(step, squares, grid, instant)
	local moved = false
	for x = 1, squares do
		if grid:canPlacePiece(self:withOffset(step)) then
			moved = true
			self:setOffset(step)
			if instant then
				self:dropToBottom(grid)
			end
		else
			break
		end
	end
	if moved and step.y == 0 then playSE("move") end
	return self
end

function Piece:dropSquares(dropped_squares, grid)
	self:moveInGrid({ x = 0, y = 1 }, dropped_squares, grid)
end

function Piece:dropToBottom(grid)
	local piece_y = self.position.y
	self:dropSquares(math.huge, grid)
	self.gravity = 0
	if self.position.y > piece_y then
		-- if it got dropped any, also reset lock delay
		if self.ghost == false then playSE("bottom") end
		self.lock_delay = 0
	end
	return self
end

function Piece:lockIfBottomed(grid)
	if self:isDropBlocked(grid) then
		self.locked = true
	end
	return self
end

function Piece:addGravity(gravity, grid)
	local new_gravity = self.gravity + gravity
	if self:isDropBlocked(grid) then
		self.gravity = math.min(1, new_gravity)
		self.lock_delay = self.lock_delay + 1
	else
		local dropped_squares = math.floor(new_gravity)
		local new_frac_gravity = new_gravity - dropped_squares
		self.gravity = new_frac_gravity
		self:dropSquares(dropped_squares, grid)
		if self:isDropBlocked(grid) then
			playSE("bottom")
		end
	end
	return self
end

-- Procedures for drawing.

function Piece:draw(opacity, brightness, grid, partial_das)
	if opacity == nil then opacity = 1 end
	if brightness == nil then brightness = 1 end
	love.graphics.setColor(brightness, brightness, brightness, opacity)
	local offsets = self:getBlockOffsets()
	local gravity_offset = 0
	if config.gamesettings.smooth_movement == 1 and 
	   grid ~= nil and not self:isDropBlocked(grid) then
		gravity_offset = self.gravity * 16
	end
	if partial_das == nil then partial_das = 0 end
	for index, offset in pairs(offsets) do
		local x = self.position.x + offset.x
		local y = self.position.y + offset.y
		if self.big then
			love.graphics.draw(
				blocks[self.skin][self.colour],
				64+x*32+partial_das*2, 16+y*32+gravity_offset*2,
				0, 2, 2
			)
		else
			love.graphics.draw(
				blocks[self.skin][self.colour],
				64+x*16+partial_das, 16+y*16+gravity_offset
			)
		end
	end
	return false
end

return Piece
