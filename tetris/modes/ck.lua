require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls_35bag'

local SurvivalCKGame = GameMode:extend()

SurvivalCKGame.name = "Survival CK"
SurvivalCKGame.hash = "SurvivalCK"
SurvivalCKGame.tagline = "An endurance mode created by CylinderKnot! Watch out for the fading pieces..."

function SurvivalCKGame:new()
	SurvivalCKGame.super:new()

	self.garbage = 0
	self.roll_frames = 0
	self.combo = 1
	self.grade = 0
	self.level = 0

	self.randomizer = History6RollsRandomizer()

	self.lock_drop = true
	self.enable_hold = true
	self.next_queue_length = 3

	self.coolregret_timer = 0
end

function SurvivalCKGame:getARE()
		if self.level < 100  then return 15
	elseif self.level < 200  then return 14
	elseif self.level < 300  then return 13
	elseif self.level < 400  then return 12
	elseif self.level < 500  then return 11
	elseif self.level < 600  then return 10
	elseif self.level < 700  then return 9
	elseif self.level < 800  then return 8
	elseif self.level < 900  then return 7
	elseif self.level < 1000 then return 6
	elseif self.level < 2500 then return 5
	else return 7 end
end


function SurvivalCKGame:getLineARE()
	return SurvivalCKGame:getARE()
end

function SurvivalCKGame:getDasLimit()
		if self.level < 700  then return 10
	elseif self.level < 900  then return 9
	elseif self.level < 1100 then return 8
	elseif self.level < 1300 then return 7
	elseif self.level < 1600 then return 6
	else return 5 end
end

function SurvivalCKGame:getLineClearDelay()
		if self.level < 100 then return 10
	elseif self.level < 200 then return 8
	elseif self.level < 300 then return 7
	elseif self.level < 400 then return 6
	else return 5 end
end

function SurvivalCKGame:getLockDelay()
		if self.level < 600  then return 20
	elseif self.level < 700  then return 19
	elseif self.level < 800  then return 18
	elseif self.level < 900  then return 17
	elseif self.level < 1000 then return 16
	elseif self.level < 1200 then return 15
	elseif self.level < 1400 then return 14
	elseif self.level < 1700 then return 13
	elseif self.level < 2100 then return 12
	elseif self.level < 2200 then return 11
	elseif self.level < 2300 then return 10
	elseif self.level < 2400 then return 9
	elseif self.level < 2500 then return 8
	else return 15 end
end

function SurvivalCKGame:getGravity()
	return 20
end

function SurvivalCKGame:getGarbageLimit()
		if self.level < 1000 then return 20
	elseif self.level < 1100 then return 17
	elseif self.level < 1200 then return 14
	elseif self.level < 1300 then return 11
	else return 8 end
end

function SurvivalCKGame:getRegretTime()
		if self.level < 500  then return frameTime(0,55)
	elseif self.level < 1000 then return frameTime(0,50)
	elseif self.level < 1500 then return frameTime(0,40)
	elseif self.level < 2000 then return frameTime(0,35)
	else return frameTime(0,30) end
end

function SurvivalCKGame:getNextPiece(ruleset)
	return {
		skin = self.level >= 2000 and "bone" or "2tie",
		shape = self.randomizer:nextPiece(),
		orientation = ruleset:getDefaultOrientation(),
	}
end

local torikan_times = {300, 330, 360, 390, 420, 450, 478, 504, 528, 550, 570}

function SurvivalCKGame:hitTorikan(old_level, new_level)
	for i = 1, 11 do
		if old_level < (900 + i * 100) and new_level >= (900 + i * 100) and self.frames > torikan_times[i] * 60 then
			self.level = 900 + i * 100
			return true
		end
	end
	return false
end

function SurvivalCKGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames < 0 then
			if self.roll_frames + 1 == 0 then
				switchBGM("credit_roll", "gm3")
				return true
			end
			return false
		elseif self.roll_frames > 3238 then
			switchBGM(nil)
			if self.grade ~= 20 then self.grade = self.grade + 1 end
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function SurvivalCKGame:onPieceEnter()
	if (self.level % 100 ~= 99) and not self.clear and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function SurvivalCKGame:onLineClear(cleared_row_count)
	if not self.clear then
		local new_level = self.level + cleared_row_count * 2
		self:updateSectionTimes(self.level, new_level)
		if new_level >= 2500 or self:hitTorikan(self.level, new_level) then
			self.clear = true
			if new_level >= 2500 then
				self.level = 2500
				self.grid:clear()
				self.big_mode = true
				self.roll_frames = -150
			end
		else
			self.level = math.min(new_level, 2500)
		end
		self:advanceBottomRow(-cleared_row_count)
	end
end

function SurvivalCKGame:onPieceLock(piece, cleared_row_count)
	if cleared_row_count == 0 then self:advanceBottomRow(1) end
end

function SurvivalCKGame:updateScore(level, drop_bonus, cleared_lines)
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

function SurvivalCKGame:updateSectionTimes(old_level, new_level)
	if math.floor(old_level / 100) < math.floor(new_level / 100) then
		local section = math.floor(old_level / 100) + 1
		section_time = self.frames - self.section_start_time
		table.insert(self.section_times, section_time)
		self.section_start_time = self.frames
		if section_time <= self:getRegretTime(self.level) then
			self.grade = self.grade + 1
		else
			self.coolregret_message = "REGRET!!"
			self.coolregret_timer = 300
		end
	end
end

function SurvivalCKGame:advanceBottomRow(dx)
	if self.level >= 1000 and self.level < 1500 then
		self.garbage = math.max(self.garbage + dx, 0)
		if self.garbage >= self:getGarbageLimit() then
			self.grid:copyBottomRow()
			self.garbage = 0
		end
	end
end

function SurvivalCKGame:drawGrid()
	if self.level >= 1500 and self.level < 1600 then
		self.grid:drawInvisible(self.rollOpacityFunction1)
	elseif self.level >= 1600 and self.level < 1700 then
		self.grid:drawInvisible(self.rollOpacityFunction2)
	elseif self.level >= 1700 and self.level < 1800 then
		self.grid:drawInvisible(self.rollOpacityFunction3)
	elseif self.level >= 1800 and self.level < 1900 then
		self.grid:drawInvisible(self.rollOpacityFunction4)
	elseif self.level >= 1900 and self.level < 2000 then
		self.grid:drawInvisible(self.rollOpacityFunction5)
	else
		self.grid:draw()
	end
end

-- screw trying to make this work efficiently
-- lua function variables are so garbage

SurvivalCKGame.rollOpacityFunction1 = function(age)
	if age < 420 then return 1
	elseif age > 480 then return 0
	else return 1 - (age - 420) / 60 end
end

SurvivalCKGame.rollOpacityFunction2 = function(age)
		if age < 360 then return 1
		elseif age > 420 then return 0
		else return 1 - (age - 360) / 60 end
end

SurvivalCKGame.rollOpacityFunction3 = function(age)
		if age < 300 then return 1
		elseif age > 360 then return 0
		else return 1 - (age - 300) / 60 end
end

SurvivalCKGame.rollOpacityFunction4 = function(age)
		if age < 240 then return 1
		elseif age > 300 then return 0
		else return 1 - (age - 240) / 60 end
end

SurvivalCKGame.rollOpacityFunction5 = function(age)
		if age < 180 then return 1
		elseif age > 240 then return 0
		else return 1 - (age - 180) / 60 end
end

local master_grades = { "M", "MK", "MV", "MO", "MM" }

function SurvivalCKGame:getLetterGrade()
	if self.grade == 0 then
		return "1"
	elseif self.grade < 10 then
		return "S" .. tostring(self.grade)
	elseif self.grade < 21 then
		return "m" .. tostring(self.grade - 9)
	elseif self.grade < 26 then
		return master_grades[self.grade - 20]
	else
		return "GM"
	end
end

function SurvivalCKGame:drawScoringInfo()
	SurvivalCKGame.super.drawScoringInfo(self)

	love.graphics.setColor(1, 1, 1, 1)

	local text_x = config["side_next"] and 320 or 240

	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("GRADE", text_x, 120, 40, "left")
	love.graphics.printf("SCORE", text_x, 200, 40, "left")
	love.graphics.printf("LEVEL", text_x, 320, 40, "left")
	
	if (self.coolregret_timer > 0) then
		love.graphics.printf(self.coolregret_message, 64, 400, 160, "center")
		self.coolregret_timer = self.coolregret_timer - 1
	end

	local current_section = math.floor(self.level / 100) + 1
	self:drawSectionTimesWithSplits(current_section)

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self:getLetterGrade(self.grade), text_x, 140, 90, "left")
	love.graphics.printf(self.score, text_x, 220, 90, "left")
	love.graphics.printf(self.level, text_x, 340, 50, "right")
	if self.clear then
		love.graphics.printf(self.level, text_x, 370, 50, "right")
	else
		love.graphics.printf(math.floor(self.level / 100 + 1) * 100, text_x, 370, 50, "right")
	end
end

function SurvivalCKGame:getHighscoreData()
	return {
		grade = self.grade,
		level = self.level,
		frames = self.frames,
	}
end

function SurvivalCKGame:getSectionEndLevel()
	return math.floor(self.level / 100 + 1) * 100
end

function SurvivalCKGame:getBackground()
	return math.min(math.floor(self.level / 100), 19)
end

return SurvivalCKGame
