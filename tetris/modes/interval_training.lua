require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local IntervalTrainingGame = GameMode:extend()

IntervalTrainingGame.name = "Interval Training"
IntervalTrainingGame.hash = "IntervalTraining"
IntervalTrainingGame.tagline = "Can you clear the time hurdles when the game goes this fast?"




function IntervalTrainingGame:new()
	IntervalTrainingGame.super:new()
	self.roll_frames = 0
	self.combo = 1
	self.randomizer = History6RollsRandomizer()
	self.section_time_limit = 1800
	self.section_start_time = 0
	self.section_times = { [0] = 0 }
	self.lock_drop = true
	self.enable_hold = true
	self.next_queue_length = 3
end

function IntervalTrainingGame:getARE()
	return 4
end

function IntervalTrainingGame:getLineARE()
	return 4
end

function IntervalTrainingGame:getDasLimit()
	return 6
end

function IntervalTrainingGame:getLineClearDelay()
	return 6
end

function IntervalTrainingGame:getLockDelay()
	return 15
end

function IntervalTrainingGame:getGravity()
	return 20
end

function IntervalTrainingGame:getSection()
	return math.floor(level / 100) + 1
end

function IntervalTrainingGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames > 2968 then
			self.completed = true
		end
		return false
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
		if self:getSectionTime() >= self.section_time_limit then
			self.game_over = true
		end
	end
	return true
end

function IntervalTrainingGame:onPieceEnter()
	if (self.level % 100 ~= 99 or self.level == 998) and not self.clear and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function IntervalTrainingGame:onLineClear(cleared_row_count)
	if not self.clear then
		local new_level = self.level + cleared_row_count
		self:updateSectionTimes(self.level, new_level)
		self.level = math.min(new_level, 999)
		if self.level == 999 then
			self.clear = true
		end
	end
end

function IntervalTrainingGame:getSectionTime()
	return self.frames - self.section_start_time
end

function IntervalTrainingGame:updateSectionTimes(old_level, new_level)
	if math.floor(old_level / 100) < math.floor(new_level / 100) then
		-- record new section
		table.insert(self.section_times, self:getSectionTime())
		self.section_start_time = self.frames
	else
		self.level = math.min(new_level, 999)
	end
end

function IntervalTrainingGame:drawGrid(ruleset)
	self.grid:draw()
end

function IntervalTrainingGame:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
	}
end

function IntervalTrainingGame:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		st(self.prev_inputs)
	)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("TIME LEFT", 240, 250, 80, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")

	local current_section = math.floor(self.level / 100) + 1
	self:drawSectionTimesWithSplits(current_section)

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.level, 240, 340, 40, "right")

	-- draw time left, flash red if necessary
	local time_left = self.section_time_limit - math.max(self:getSectionTime(), 0)
	if not self.game_over and not self.clear and time_left < sp(0,10) and time_left % 4 < 2 then
		love.graphics.setColor(1, 0.3, 0.3, 1)
	end
	love.graphics.printf(formatTime(time_left), 240, 270, 160, "left")

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self:getSectionEndLevel(), 240, 370, 40, "right")
end

function IntervalTrainingGame:getSectionEndLevel()
	if self.level > 900 then return 999
	else return math.floor(self.level / 100 + 1) * 100 end
end

function IntervalTrainingGame:getBackground()
	return math.floor(self.level / 100)
end

return IntervalTrainingGame
