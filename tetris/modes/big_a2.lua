local GameMode = require 'tetris.modes.gamemode'
local MarathonA2Game = require 'tetris.modes.marathon_a2'

local BigA2Game = MarathonA2Game:extend()

BigA2Game.name = "Big A2"
BigA2Game.hash = "BigA2"
BigA2Game.tagline = "Big blocks in the most celebrated TGM mode!"

function BigA2Game:new()
	BigA2Game.super:new()
	self.big_mode = true
end

function BigA2Game:updateScore(level, drop_bonus, cleared_lines)
	cleared_lines = cleared_lines / 2
	if not self.clear then
		self:updateGrade(cleared_lines)
		if cleared_lines >= 4 then
			self.tetris_count = self.tetris_count + 1
		end
		if self.grid:checkForBravo(cleared_lines) then self.bravo = 4 else self.bravo = 1 end
		if cleared_lines > 0 then
			self.combo = self.combo + (cleared_lines - 1) * 2
			self.score = self.score + (
				(math.ceil((level + cleared_lines) / 4) + drop_bonus) *
				cleared_lines * self.combo * self.bravo
			)
		else
			self.combo = 1
		end
		self.drop_bonus = 0
	else self.lines = self.lines + cleared_lines end
end

function BigA2Game:onLineClear(cleared_row_count)
	cleared_row_count = cleared_row_count / 2
	self:updateSectionTimes(self.level, self.level + cleared_row_count)
	self.level = math.min(self.level + cleared_row_count, 999)
	if self.level == 999 and not self.clear then
		self.clear = true
		self.grid:clear()
		if self:qualifiesForMRoll() then self.grade = 32 end
		self.roll_frames = -150
	end
	self.lock_drop = self.level >= 900
	self.lock_hard_drop = self.level >= 900
end

return BigA2Game