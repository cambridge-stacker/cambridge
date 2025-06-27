require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local StrategyGame = GameMode:extend()

StrategyGame.name = "Strategy"
StrategyGame.hash = "Strategy"
StrategyGame.description = "You have lots of time to think! Can you use it to place a piece fast?"
StrategyGame.tags = {"Strategy", "Cambridge"}

function StrategyGame:new()
	StrategyGame.super:new()
	self.clear = false
	self.completed = false
	self.roll_frames = 0
	self.combo = 1
	self.randomizer = History6RollsRandomizer()

	self.enable_hold = false
	self.next_queue_length = 1
end

function StrategyGame:getARE()
		if self.level < 100 then return 60
	elseif self.level < 200 then return 54
	elseif self.level < 300 then return 48
	elseif self.level < 400 then return 42
	elseif self.level < 500 then return 36
	elseif self.level < 600 then return 30
	elseif self.level < 700 then return 24
	elseif self.level < 800 then return 21
	elseif self.level < 900 then return 18
	else return 15 end
end

function StrategyGame:getLineARE()
	return self:getARE()
end

function StrategyGame:getDasLimit()
	return 6
end

function StrategyGame:getLineClearDelay()
	return self:getARE()
end

function StrategyGame:getLockDelay()
	if self.level < 700 then return 8
	else return 6 end
end

function StrategyGame:getGravity()
	return 20
end

function StrategyGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames > 1936 then
			switchBGM(nil)
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function StrategyGame:onPieceEnter()
	if (self.level % 100 ~= 99 and self.level ~= 998) and not self.clear and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function StrategyGame:onLineClear(cleared_row_count)
	if not self.clear then
		self.level = math.min(999, self.level + cleared_row_count)
		if self.level == 999 then
			self.clear = true
		end
	end
end

function StrategyGame:updateScore(level, drop_bonus, cleared_lines)
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

function StrategyGame:setNextOpacity(i)
	if self.are == 0 then love.graphics.setColor(1, 1, 1, 1)
	else love.graphics.setColor(1, 1, 1, self.are / self:getARE())
	end
end

function StrategyGame:drawGrid()
	self.grid:draw()
end

function StrategyGame:drawScoringInfo()
	StrategyGame.super.drawScoringInfo(self)

	love.graphics.setColor(1, 1, 1, 1)

	local text_x = config["side_next"] and 320 or 240

	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("SCORE", text_x, 200, 40, "left")
	love.graphics.printf("LEVEL", text_x, 320, 40, "left")

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.score, text_x, 220, 90, "left")
	love.graphics.printf(self.level, text_x, 340, 40, "right")
	if self.clear then
		love.graphics.printf(self.level, text_x, 370, 40, "right")
	else
		love.graphics.printf(self.level < 900 and math.floor(self.level / 100 + 1) * 100 or 999, text_x, 370, 40, "right")
	end
end

function StrategyGame:getBackground()
	return math.floor(self.level / 100)
end

function StrategyGame:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
	}
end

return StrategyGame
