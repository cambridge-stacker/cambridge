local Object = require 'libs.classic'
require 'funcs'

local Grid = require 'tetris.components.grid'
local Randomizer = require 'tetris.randomizers.randomizer'

local GameMode = Object:extend()

GameMode.rollOpacityFunction = function(age) return 0 end

function GameMode:new()
	self.grid = Grid()
	self.randomizer = Randomizer()
	self.piece = nil
	self.ready_frames = 100
	self.frames = 0
	self.game_over_frames = 0
	self.score = 0
	self.level = 0
	self.lines = 0
	self.drop_bonus = 0
	self.are = 0
	self.lcd = 0
	self.das = { direction = "none", frames = -1 }
	self.move = "none"
	self.prev_inputs = {}
	self.next_queue = {}
	self.game_over = false
	self.clear = false
	self.completed = false
	-- configurable parameters
	self.lock_drop = false
	self.lock_hard_drop = false
	self.instant_hard_drop = false
	self.instant_soft_drop = true
	self.enable_hold = false
	self.enable_hard_drop = true
	self.next_queue_length = 1
	self.additive_gravity = true
	self.draw_section_times = false
	self.draw_secondary_section_times = false
	self.big_mode = false
    self.rpc_details = "In game"
	-- variables related to configurable parameters
	self.drop_locked = false
	self.hard_drop_locked = false
    self.lock_on_soft_drop = false
    self.lock_on_hard_drop = false
	self.hold_queue = nil
	self.held = false
	self.section_start_time = 0
	self.section_times = { [0] = 0 }
	self.secondary_section_times = { [0] = 0 }
end

function GameMode:getARR() return 1 end
function GameMode:getDropSpeed() return 1 end
function GameMode:getARE() return 25 end
function GameMode:getLineARE() return 25 end
function GameMode:getLockDelay() return 30 end
function GameMode:getLineClearDelay() return 40 end
function GameMode:getDasLimit() return 15 end

function GameMode:getNextPiece(ruleset)
    
	return {
		skin = "2tie",
		shape = self.randomizer:nextPiece(),
		orientation = ruleset:getDefaultOrientation(),
	}
end

function GameMode:initialize(ruleset)
	-- generate next queue
    self:new()
	for i = 1, self.next_queue_length do
		table.insert(self.next_queue, self:getNextPiece(ruleset))
	end
    self.lock_on_soft_drop = ({ruleset.softdrop_lock, self.instant_soft_drop, false, true })[config.gamesettings.manlock]
    self.lock_on_hard_drop = ({ruleset.harddrop_lock, self.instant_hard_drop, true,  false})[config.gamesettings.manlock]
end

function GameMode:update(inputs, ruleset)
	if self.game_over then 
		self.game_over_frames = self.game_over_frames + 1
		if self.game_over_frames >= 60 then
			self.completed = true
		end
		return
	end
	if self.completed then return end

	-- advance one frame
	if self:advanceOneFrame(inputs) == false then return end

	self:chargeDAS(inputs, self:getDasLimit(), self.getARR())

	if self.piece == nil then
		self:processDelays(inputs, ruleset)
	else
		-- perform active frame actions such as fading out the next queue
		self:whilePieceActive()
		local gravity = self:getGravity()

		if self.enable_hold and inputs["hold"] == true and self.held == false then
			self:hold(inputs, ruleset)
			self.prev_inputs = inputs
			return
		end

		if self.lock_drop and inputs["down"] ~= true then
			self.drop_locked = false
		end

		if self.lock_hard_drop and inputs["up"] ~= true then
			self.hard_drop_locked = false
		end

		local piece_y = self.piece.position.y

		ruleset:processPiece(
			inputs, self.piece, self.grid, self:getGravity(), self.prev_inputs,
			self.move, self:getLockDelay(), self:getDropSpeed(),
			self.drop_locked, self.hard_drop_locked,
			self.enable_hard_drop, self.additive_gravity
		)

		local piece_dy = self.piece.position.y - piece_y

		if inputs["up"] == true and
			self.piece:isDropBlocked(self.grid) and
			not self.hard_drop_locked then
			self:onHardDrop(piece_dy)
			if self.lock_on_hard_drop then
				self.piece.locked = true
			end
		end

		if inputs["down"] == true then
			self:onSoftDrop(piece_dy)
			if self.piece:isDropBlocked(self.grid) and
				not self.drop_locked and
				self.lock_on_soft_drop
			then
				self.piece.locked = true
			end
		end

		if self.piece.locked == true then
			self.grid:applyPiece(self.piece)
			self.grid:markClearedRows()

			local cleared_row_count = self.grid:getClearedRowCount()

			self:onPieceLock(self.piece, cleared_row_count)
			self:updateScore(self.level, self.drop_bonus, cleared_row_count)

			self.piece = nil
			if self.enable_hold then
				self.held = false
			end

			if cleared_row_count > 0 then
				self.lcd = self:getLineClearDelay()
				self.are = self:getLineARE()
				if self.lcd == 0 then
					self.grid:clearClearedRows()
					if self.are == 0 then
						self:initializeOrHold(inputs, ruleset)
					end
				end
				self:onLineClear(cleared_row_count)
			else
				if self:getARE() == 0 then
					self:initializeOrHold(inputs, ruleset)
				else
					self.are = self:getARE()
				end
			end
		end
	end
	self.prev_inputs = inputs
end

function GameMode:updateScore() end

function GameMode:advanceOneFrame()
	if self.clear then
		self.completed = true
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
end

-- event functions
function GameMode:whilePieceActive() end
function GameMode:onPieceLock(piece, cleared_row_count) end
function GameMode:onLineClear(cleared_row_count) end
function GameMode:onPieceEnter() end
function GameMode:onHold() end

function GameMode:onSoftDrop(dropped_row_count)
	self.drop_bonus = self.drop_bonus + 1 * dropped_row_count
end

function GameMode:onHardDrop(dropped_row_count)
	self.drop_bonus = self.drop_bonus + 2 * dropped_row_count
end

function GameMode:onGameOver()
	switchBGM(nil)
end

function GameMode:chargeDAS(inputs)
	if inputs[self.das.direction] == true then
		local das_frames = self.das.frames + 1
		if das_frames >= self:getDasLimit() then
			if self.das.direction == "left" then
				self.move = (self:getARR() == 0 and "speed" or "") .. "left"
				self.das.frames = self:getDasLimit() - self:getARR()
			elseif self.das.direction == "right" then
				self.move = (self:getARR() == 0 and "speed" or "") .. "right"
				self.das.frames = self:getDasLimit() - self:getARR()
			end
		else
			self.move = "none"
			self.das.frames = das_frames
		end
	elseif inputs["right"] == true then
		self.move = "right"
		self.das = { direction = "right", frames = 0 }
	elseif inputs["left"] == true then
		self.move = "left"
		self.das = { direction = "left", frames = 0 }
	else
		self.move = "none"
		self.das = { direction = "none", frames = -1 }
	end
end

function GameMode:processDelays(inputs, ruleset, drop_speed)
	if self.ready_frames > 0 then
		self.ready_frames = self.ready_frames - 1
		if self.ready_frames == 0 then
			self:initializeOrHold(inputs, ruleset)
		end
	elseif self.lcd > 0 then
		self.lcd = self.lcd - 1
		if self.lcd == 0 then
			self.grid:clearClearedRows()
			if self.are == 0 then
				self:initializeOrHold(inputs, ruleset)
			end
		end
	elseif self.are > 0 then
		self.are = self.are - 1
		if self.are == 0 then
			self:initializeOrHold(inputs, ruleset)
		end
	end
end

function GameMode:initializeOrHold(inputs, ruleset)
	if self.enable_hold and inputs["hold"] == true then
		self:hold(inputs, ruleset)
	else
		self:initializeNextPiece(inputs, ruleset, self.next_queue[1])
	end
	self:onPieceEnter()
	if not self.grid:canPlacePiece(self.piece) then
		self:onGameOver()
		self.game_over = true
	end
end

function GameMode:hold(inputs, ruleset)
	local data = copy(self.hold_queue)
	if self.piece == nil then
		self.hold_queue = self.next_queue[1]
		table.remove(self.next_queue, 1)
		table.insert(self.next_queue, self:getNextPiece(ruleset))
	else
		self.hold_queue = {
			skin = self.piece.skin,
			shape = self.piece.shape,
			orientation = ruleset:getDefaultOrientation(),
		}
	end
	if data == nil then
		self:initializeNextPiece(inputs, ruleset, self.next_queue[1])
	else
		self:initializeNextPiece(inputs, ruleset, data, false)
	end
	self.held = true
	self:onHold()
end

function GameMode:initializeNextPiece(inputs, ruleset, piece_data, generate_next_piece)
	local gravity = self:getGravity()
	self.piece = ruleset:initializePiece(
		inputs, piece_data, self.grid, gravity,
		self.prev_inputs, self.move,
		self:getLockDelay(), self:getDropSpeed(),
		self.lock_drop, self.lock_hard_drop, self.big_mode
	)
	if self.lock_drop then
		self.drop_locked = true
	end
	if self.lock_hard_drop then
		self.hard_drop_locked = true
	end
	if generate_next_piece == nil then
		table.remove(self.next_queue, 1)
		table.insert(self.next_queue, self:getNextPiece(ruleset))
	end
	self:playNextSound()
end

function GameMode:playNextSound()
	playSE("blocks", self.next_queue[1].shape)
end

function GameMode:getHighScoreData()
	return {
		score = self.score
	}
end

function GameMode:drawPiece()
	if self.piece ~= nil then
		self.piece:draw(
			1,
			self:getLockDelay() == 0 and 1 or
			(0.25 + 0.75 * math.max(1 - self.piece.gravity, 1 - (self.piece.lock_delay / self:getLockDelay()))),
			self.grid
		)
	end
end

function GameMode:drawGhostPiece(ruleset)
	if self.piece == nil then return end
	local ghost_piece = self.piece:withOffset({x=0, y=0})
	ghost_piece.ghost = true
	ghost_piece:dropToBottom(self.grid)
	ghost_piece:draw(0.5)
end

function GameMode:drawNextQueue(ruleset)
    local colourscheme = ({ruleset.colourscheme, ColourSchemes.Arika, ColourSchemes.TTC})[config.gamesettings.piece_colour]
	function drawPiece(piece, skin, offsets, pos_x, pos_y)
		for index, offset in pairs(offsets) do
			local x = offset.x + ruleset.spawn_positions[piece].x
			local y = offset.y + 4.7
			love.graphics.draw(blocks[skin][colourscheme[piece]], pos_x+x*16, pos_y+y*16)
		end
	end
	for i = 1, self.next_queue_length do
		self:setNextOpacity(i)
		local next_piece = self.next_queue[i].shape
		local skin = self.next_queue[i].skin
		local rotation = self.next_queue[i].orientation
		if config.side_next then -- next at side
			drawPiece(next_piece, skin, ruleset.block_offsets[next_piece][rotation], 192, -16+i*48)
		else -- next at top
			drawPiece(next_piece, skin, ruleset.block_offsets[next_piece][rotation], -16+i*80, -32)
		end
	end
	if self.hold_queue ~= nil then
		self:setHoldOpacity()
		drawPiece(
			self.hold_queue.shape, 
			self.hold_queue.skin, 
			ruleset.block_offsets[self.hold_queue.shape][self.hold_queue.orientation],
			-16, -32
		)
	end
	return false
end

function GameMode:setNextOpacity(i) love.graphics.setColor(1, 1, 1, 1) end
function GameMode:setHoldOpacity() love.graphics.setColor(1, 1, 1, 1) end

function GameMode:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)

	if config["side_next"] then
		love.graphics.printf("NEXT", 240, 72, 40, "left")
	else
		love.graphics.printf("NEXT", 64, 40, 40, "left")
	end

	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		strTrueValues(self.prev_inputs) ..
		self.drop_bonus
	)

	love.graphics.setFont(font_8x11)
	love.graphics.printf(formatTime(self.frames), 64, 420, 160, "center")
end

function GameMode:drawSectionTimes(current_section)
	local section_x = 530

	for section, time in pairs(self.section_times) do
		if section > 0 then
			love.graphics.printf(formatTime(time), section_x, 40 + 20 * section, 90, "left")
		end
	end

	love.graphics.printf(formatTime(self.frames - self.section_start_time), section_x, 40 + 20 * current_section, 90, "left")
end

function GameMode:drawSectionTimesWithSecondary(current_section)
	local section_x = 530
	local section_secondary_x = 440

	for section, time in pairs(self.section_times) do
		if section > 0 then
			love.graphics.printf(formatTime(time), section_x, 40 + 20 * section, 90, "left")
		end
	end

	for section, time in pairs(self.secondary_section_times) do
		if section > 0 then
			love.graphics.printf(formatTime(time), section_secondary_x, 40 + 20 * section, 90, "left")
		end
	end

	local current_x
	if table.getn(self.section_times) < table.getn(self.secondary_section_times) then
		current_x = section_x
	else
		current_x = section_secondary_x
	end

	love.graphics.printf(formatTime(self.frames - self.section_start_time), current_x, 40 + 20 * current_section, 90, "left")
end

function GameMode:drawSectionTimesWithSplits(current_section)
	local section_x = 440
	local split_x = 530

	local split_time = 0

	for section, time in pairs(self.section_times) do
		if section > 0 then
			love.graphics.printf(formatTime(time), section_x, 40 + 20 * section, 90, "left")
			split_time = split_time + time
			love.graphics.printf(formatTime(split_time), split_x, 40 + 20 * section, 90, "left")
		end
	end
	
	love.graphics.printf(formatTime(self.frames - self.section_start_time), section_x, 40 + 20 * current_section, 90, "left")
	love.graphics.printf(formatTime(self.frames), split_x, 40 + 20 * current_section, 90, "left")
end

function GameMode:drawCustom() end

return GameMode
