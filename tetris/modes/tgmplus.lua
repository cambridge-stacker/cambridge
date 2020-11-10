require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local TGMPlusGame = GameMode:extend()

TGMPlusGame.name = "Marathon A2+"
TGMPlusGame.hash = "A2Plus"
TGMPlusGame.tagline = "The garbage rises steadily! Can you make it to level 999?"

function TGMPlusGame:new()
	TGMPlusGame.super:new()

	self.roll_frames = 0
	self.combo = 1
	
		self.SGnames = {
			"9", "8", "7", "6", "5", "4", "3", "2", "1",
			"S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9",
			"GM"
		}
	
	self.randomizer = History6RollsRandomizer()

		self.lock_drop = false
	self.enable_hold = false
	self.next_queue_length = 1

	self.garbage_queue = 0
	self.garbage_pos = 0
	self.garbage_rows = {
		[0] = 
		{"e", "b", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"e", "b", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"e", "b", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"e", "b", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "b", "e"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "b", "e"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "b", "e"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "b", "e"},
		{"e", "e", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"e", "b", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"e", "b", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "e", "e"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "b", "e"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "b", "e"},
		{"b", "b", "e", "b", "b", "b", "b", "b", "b", "b"},
		{"b", "e", "e", "b", "b", "b", "b", "b", "b", "b"},
		{"b", "e", "b", "b", "b", "b", "b", "b", "b", "b"},
		{"b", "b", "b", "b", "b", "b", "b", "e", "b", "b"},
		{"b", "b", "b", "b", "b", "b", "b", "e", "e", "b"},
		{"b", "b", "b", "b", "b", "b", "b", "b", "e", "b"},
		{"b", "b", "b", "b", "e", "e", "b", "b", "b", "b"},
		{"b", "b", "b", "b", "e", "e", "b", "b", "b", "b"},
		{"b", "b", "b", "b", "e", "b", "b", "b", "b", "b"},
		{"b", "b", "b", "e", "e", "e", "b", "b", "b", "b"},
	}
end

function TGMPlusGame:getARE() return 25 end
function TGMPlusGame:getDasLimit() return 15 end
function TGMPlusGame:getLockDelay() return 30 end
function TGMPlusGame:getLineClearDelay() return 40 end

function TGMPlusGame:getGravity()
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

function TGMPlusGame:getGarbageLimit() return 13 - math.floor(self.level / 100) end

function TGMPlusGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames > 3694 then
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function TGMPlusGame:onPieceEnter()
	if (self.level % 100 ~= 99 and self.level ~= 998) and not self.clear and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function TGMPlusGame:onPieceLock(piece, cleared_row_count)
	self.super:onPieceLock()
	if cleared_row_count == 0 then self:advanceBottomRow() end
end

function TGMPlusGame:onLineClear(cleared_row_count)
	self.level = math.min(self.level + cleared_row_count, 999)
	if self.level == 999 and not self.clear then self.clear = true end
	if self.level >= 900 then self.lock_drop = true end
end

function TGMPlusGame:advanceBottomRow()
	self.garbage_queue = self.garbage_queue + 1
	if self.garbage_queue >= self:getGarbageLimit() then
		self.grid:garbageRise(self.garbage_rows[self.garbage_pos])
		self.garbage_queue = 0
		self.garbage_pos = (self.garbage_pos + 1) % 24
	end
end

function TGMPlusGame:updateScore(level, drop_bonus, cleared_lines)
	if not self.clear then
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
	end
end

function TGMPlusGame:drawGrid(ruleset)
	self.grid:draw()
	if self.piece ~= nil and self.level < 100 then
		self:drawGhostPiece(ruleset)
	end
end

function TGMPlusGame:getHighscoreData()
	return {
		score = self.score,
		level = self.level,
		frames = self.frames,
	}
end

function TGMPlusGame:getSectionEndLevel()
	if self.level >= 900 then return 999
	else return math.floor(self.level / 100 + 1) * 100 end
end

function TGMPlusGame:getBackground()
	return math.floor(self.level / 100)
end

function TGMPlusGame:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		strTrueValues(self.prev_inputs)
	)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("SCORE", 240, 200, 40, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")
	local sg = self.grid:checkSecretGrade()
	if sg >= 5 then 
		love.graphics.printf("SECRET GRADE", 240, 430, 180, "left")
	end

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.score, 240, 220, 90, "left")
	love.graphics.printf(self.level, 240, 340, 40, "right")
	love.graphics.printf(self:getSectionEndLevel(), 240, 370, 40, "right")
	if sg >= 5 then
		love.graphics.printf(self.SGnames[sg], 240, 450, 180, "left")
	end

	love.graphics.setFont(font_8x11)
	love.graphics.printf(formatTime(self.frames), 64, 420, 160, "center")
end


return TGMPlusGame
