require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local DemonModeGame = GameMode:extend()

DemonModeGame.name = "Demon Mode"
DemonModeGame.hash = "DemonMode"
DemonModeGame.tagline = "Can you handle the ludicrous speed past level 20?"

function DemonModeGame:new()
	DemonModeGame.super:new()
	self.roll_frames = 0
	self.combo = 1
	self.randomizer = History6RollsRandomizer()

	self.grade = 0
	self.section_start_time = 0
	self.section_times = { [0] = 0 }
	self.section_tetris_count = 0
	self.section_tries = 0

	self.enable_hold = true
	self.lock_drop = true
	self.next_queue_length = 3
    if math.random() < 1/6.66 then
        self.rpc_details = "Suffering"
    end
end

function DemonModeGame:getARE()
	    if self.level < 500 then return 30
	elseif self.level < 600 then return 25
	elseif self.level < 700 then return 15
	elseif self.level < 800 then return 14
	elseif self.level < 900 then return 12
	elseif self.level < 1000 then return 11
	elseif self.level < 1100 then return 10
	elseif self.level < 1300 then return 8
	elseif self.level < 1400 then return 6
	elseif self.level < 1700 then return 4
	elseif self.level < 1800 then return 3
	elseif self.level < 1900 then return 2
	elseif self.level < 2000 then return 1
	else return 0 end
end

function DemonModeGame:getLineARE()
	return self:getARE()
end

function DemonModeGame:getDasLimit()
	    if self.level < 500 then return 15
	elseif self.level < 1000 then return 10
	elseif self.level < 1500 then return 5
	elseif self.level < 1700 then return 4
	elseif self.level < 1900 then return 3
	elseif self.level < 2000 then return 2
	else return 1 end
end

function DemonModeGame:getLineClearDelay()
		if self.level < 600 then return 15
	elseif self.level < 800 then return 10
	elseif self.level < 1000 then return 8
	elseif self.level < 1500 then return 5
	elseif self.level < 1700 then return 3
	elseif self.level < 1900 then return 2
	elseif self.level < 2000 then return 1
	else return 0 end
end

function DemonModeGame:getLockDelay()
		if self.level < 100 then return 30
	elseif self.level < 200 then return 25
	elseif self.level < 300 then return 22
	elseif self.level < 400 then return 20
	elseif self.level < 1000 then return 15
	elseif self.level < 1200 then return 10
	elseif self.level < 1400 then return 9
	elseif self.level < 1500 then return 8
	elseif self.level < 1600 then return 7
	elseif self.level < 1700 then return 6
	elseif self.level < 1800 then return 5
	elseif self.level < 1900 then return 4
	elseif self.level < 2000 then return 3
	else return 2 end
end

function DemonModeGame:getGravity()
	return 20
end

local function getSectionForLevel(level)
	return math.floor(level / 100) + 1
end

local cleared_row_levels = {1, 3, 6, 10}

function DemonModeGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames < 0 then
			return false
		elseif self.roll_frames >= 1337 then
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
end

function DemonModeGame:onPieceEnter()
	if (self.level % 100 ~= 99) and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function DemonModeGame:onLineClear(cleared_row_count)
	if cleared_row_count == 4 then
		self.section_tetris_count = self.section_tetris_count + 1
	end
	local advanced_levels = cleared_row_levels[cleared_row_count]
	if not self.clear then
		self:updateSectionTimes(self.level, self.level + advanced_levels)
	end
end

function DemonModeGame:updateSectionTimes(old_level, new_level)
	local section = math.floor(old_level / 100) + 1
	if math.floor(old_level / 100) < math.floor(new_level / 100) then
		-- If at least one Tetris in this section hasn't been made,
		-- deny section passage.
		if old_level > 500 then
			if self.section_tetris_count == 0 then
				self.level = 100 * math.floor(old_level / 100)
				self.section_tries = self.section_tries + 1
			else
				self.level = math.min(new_level, 2500)
				-- if this is first try (no denials, add a grade)
				if self.section_tries == 0 then
					self.grade = self.grade + 1
				end
				self.section_tries = 0
				self.section_tetris_count = 0
				-- record new section
				section_time = self.frames - self.section_start_time
				table.insert(self.section_times, section_time)
				self.section_start_time = self.frames
				-- maybe clear
				if self.level == 2500 and not self.clear then
					self.clear = true
					self.grid:clear()
					self.roll_frames = -150
				end
			end
		elseif old_level < 100 then
			-- If section time is under cutoff, skip to level 500.
			if self.frames < frameTime(1,00) then
				self.level = 500
				self.grade = 5
				self.section_tries = 0
				self.section_tetris_count = 0
			else
				self.level = math.min(new_level, 2500)
				self.skip_failed = true
				self.grade = self.grade + 1
			end
			-- record new section
			section_time = self.frames - self.section_start_time
			table.insert(self.section_times, section_time)
			self.section_start_time = self.frames
		else
			self.level = math.min(new_level, 2500)
			if self.skip_failed and new_level >= 500 then
				self.level = 500
				self.game_over = true
			end
			self.grade = math.min(self.grade + 1, 4)
		end
	else
		self.level = math.min(new_level, 2500)
	end
end

function DemonModeGame:updateScore(level, drop_bonus, cleared_lines)
	if not self.clear then
		if cleared_lines > 0 then
			self.combo = self.combo + (cleared_lines - 1) * 2
			self.score = self.score + (
				(math.ceil((level + cleared_lines) / 4) + drop_bonus) *
				cleared_lines * self.combo
			)
		else
			self.combo = 1
		end
		self.drop_bonus = 0
	end
end

local letter_grades = {
	[0] = "", "D", "C", "B", "A",
	"S", "S-A", "S-B", "S-C", "S-D",
	"X", "X-A", "X-B", "X-C", "X-D",
	"W", "W-A", "W-B", "W-C", "W-D",
	"Master", "MasterS", "MasterX", "MasterW", "Grand Master",
	"Demon Master"
}

function DemonModeGame:getLetterGrade()
	return letter_grades[self.grade]
end

function DemonModeGame:drawGrid()
	if self.clear and not (self.completed or self.game_over) then
		self.grid:drawInvisible(self.rollOpacityFunction)
	else
		self.grid:draw()
	end
end

DemonModeGame.rollOpacityFunction = function(age)
	if age > 4 then return 0
	else return 1 - age / 4 end
end

function DemonModeGame:drawScoringInfo()
	DemonModeGame.super.drawScoringInfo(self)
	
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		strTrueValues(self.prev_inputs)
	)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	if self.grade ~= 0 then love.graphics.printf("GRADE", 240, 120, 40, "left") end
	love.graphics.printf("SCORE", 240, 200, 40, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")

	-- draw section time data
	local current_section = getSectionForLevel(self.level)
	self:drawSectionTimesWithSecondary(current_section)

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.score, 240, 220, 90, "left")
	love.graphics.printf(self:getLetterGrade(), 240, 140, 90, "left")
	love.graphics.printf(string.format("%.2f", self.level / 100), 240, 340, 70, "right")
end

function DemonModeGame:getHighscoreData()
	return {
		grade = self.grade,
		level = self.level,
		frames = self.frames,
	}
end

function DemonModeGame:getBackground()
	return math.min(math.floor(self.level / 100), 19)
end

return DemonModeGame
