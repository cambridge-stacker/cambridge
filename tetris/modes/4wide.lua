require 'funcs'

local SurvivalA3Game = require 'tetris.modes.survival_a3'

local FourWideGame = SurvivalA3Game:extend()

FourWideGame.name = "4-wide Simulator"
FourWideGame.hash = "4wide"
FourWideGame.tagline = "The board has gotten narrower! Can you survive the increasing speeds?"

function FourWideGame:initialize(ruleset)
	self.super:initialize(ruleset)
	self.grid:applyFourWide()
end

local cleared_row_levels = {1, 2, 4, 6}

function FourWideGame:onLineClear(cleared_row_count)
	if not self.clear then
		local new_level = self.level + cleared_row_levels[cleared_row_count]
		self:updateSectionTimes(self.level, new_level)
		if new_level >= 1300 or self:hitTorikan(self.level, new_level) then
					self.clear = true
			if new_level >= 1300 then
				self.level = 1300
						self.grid:clear()
						self.roll_frames = -150
					else
						self.game_over = true
			end
		else
			self.level = math.min(new_level, 1300)
		end
		self:advanceBottomRow(-cleared_row_count)
	end
	self.grid:applyFourWide()
end

return FourWideGame
