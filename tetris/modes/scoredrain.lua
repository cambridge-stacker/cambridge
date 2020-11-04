require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls_35bag'

local ScoreDrainGame = GameMode:extend()

ScoreDrainGame.name = "Score Drain"
ScoreDrainGame.hash = "ScoreDrain"
ScoreDrainGame.tagline = "Your score goes down over time! Avoid hitting 0 points, or your game is over!"

function ScoreDrainGame:new()
	self.super:new()
	
	self.score = 2500
	self.drain_rate = 50
	self.combo = 1
	self.randomizer = History6RollsRandomizer()
	
	self.lock_drop = true
    self.lock_hard_drop = true
	self.enable_hold = true
	self.next_queue_length = 3
end

function ScoreDrainGame:getARE()
        if self.level < 700 then return 27
    elseif self.level < 800 then return 18
    elseif self.level < 1000 then return 14
    elseif self.level < 1100 then return 8
    elseif self.level < 1200 then return 7
    else return 6 end
end

function ScoreDrainGame:getLineARE()
        if self.level < 600 then return 27
    elseif self.level < 700 then return 18
    elseif self.level < 800 then return 14
    elseif self.level < 1100 then return 8
    elseif self.level < 1200 then return 7
    else return 6 end
end

function ScoreDrainGame:getDasLimit()
        if self.level < 500 then return 15
    elseif self.level < 900 then return 9
    else return 7 end
end

function ScoreDrainGame:getLineClearDelay()
        if self.level < 500 then return 40
    elseif self.level < 600 then return 25
    elseif self.level < 700 then return 16
    elseif self.level < 800 then return 12
    elseif self.level < 1100 then return 6
    elseif self.level < 1200 then return 5
    else return 4 end
end

function ScoreDrainGame:getLockDelay()
        if self.level < 900 then return 30
    elseif self.level < 1100 then return 17
    else return 15 end
end

function ScoreDrainGame:getGravity()
        if (self.level < 30)  then return 4/256
    elseif (self.level < 35)  then return 6/256
    elseif (self.level < 40)  then return 8/256
    elseif (self.level < 50)  then return 10/256
    elseif (self.level < 60)  then return 12/256
    elseif (self.level < 70)  then return 16/256
    elseif (self.level < 80)  then return 32/256
    elseif (self.level < 90)  then return 48/256
    elseif (self.level < 100) then return 64/256
    elseif (self.level < 120) then return 80/256
    elseif (self.level < 140) then return 96/256
    elseif (self.level < 160) then return 112/256
    elseif (self.level < 170) then return 128/256
    elseif (self.level < 200) then return 144/256
    elseif (self.level < 220) then return 4/256
    elseif (self.level < 230) then return 32/256
    elseif (self.level < 233) then return 64/256
    elseif (self.level < 236) then return 96/256
    elseif (self.level < 239) then return 128/256
    elseif (self.level < 243) then return 160/256
    elseif (self.level < 247) then return 192/256
    elseif (self.level < 251) then return 224/256
    elseif (self.level < 300) then return 1
    elseif (self.level < 330) then return 2
    elseif (self.level < 360) then return 3
    elseif (self.level < 400) then return 4
    elseif (self.level < 420) then return 5
    elseif (self.level < 450) then return 4
    elseif (self.level < 500) then return 3
    else return 20
    end
end

function ScoreDrainGame:advanceOneFrame()
	if self.ready_frames == 0 then
		self.frames = self.frames + 1
		self.score = math.max(0, self.score - self.drain_rate / 60)
		self.game_over = self.score <= 0 and true or false
	end
	return true
end

function ScoreDrainGame:onPieceEnter()
	if (self.level % 100 ~= 99) and self.frames ~= 0 then
        self.level = self.level + 1
    end
end

local cleared_row_levels = {1, 2, 4, 6}

function ScoreDrainGame:onLineClear(cleared_row_count)
	local new_level = self.level + cleared_row_levels[cleared_row_count]
	self.drain_rate = math.floor(self.level / 100) < math.floor(new_level / 100) and self.drain_rate * 1.5 or self.drain_rate
	self.level = new_level
end

function ScoreDrainGame:updateScore(level, drop_bonus, cleared_lines)
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

function ScoreDrainGame:drawGrid()
	self.grid:draw()
	if self.piece ~= nil and self.level < 100 then
		self:drawGhostPiece(ruleset)
	end
end

function ScoreDrainGame:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		strTrueValues(self.prev_inputs)
	)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("DRAIN RATE", 240, 90, 80, "left")
	love.graphics.printf("SCORE", 240, 170, 40, "left")
	love.graphics.printf("TIME LEFT", 240, 250, 80, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(math.floor(self.drain_rate).."/s", 240, 110, 120, "left")
	local frames_left = self.score / self.drain_rate * 60
	if frames_left <= 600 and frames_left % 4 < 2 and not self.game_over then love.graphics.setColor(1, 0.3, 0.3, 1) end
	love.graphics.printf(formatTime(frames_left), 240, 270, 120, "left")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(math.floor(self.score), 240, 190, 90, "left")
	love.graphics.printf(self.level, 240, 340, 50, "right")
	love.graphics.printf(self:getSectionEndLevel(), 240, 370, 50, "right")

	love.graphics.setFont(font_8x11)
	love.graphics.printf(formatTime(self.frames), 64, 420, 160, "center")
end

function ScoreDrainGame:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
	}
end

function ScoreDrainGame:getSectionEndLevel()
	return math.floor(self.level / 100 + 1) * 100
end

function ScoreDrainGame:getBackground()
	return math.floor(self.level / 100)
end

return ScoreDrainGame
