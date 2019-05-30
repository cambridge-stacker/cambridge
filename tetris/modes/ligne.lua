require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local LigneGame = GameMode:extend()

LigneGame.name = "Ligne"
LigneGame.hash = "Ligne"
LigneGame.tagline = "How fast can you clear 40 lines?"




function LigneGame:new()
	LigneGame.super:new()

	self.lines = 0
	self.line_goal = 40
	self.pieces = 0
	self.randomizer = History6RollsRandomizer()

	self.roll_frames = 0
	
	self.lock_drop = true
	self.lock_hard_drop = true
	self.instant_hard_drop = true
	self.instant_soft_drop = false
	self.enable_hold = true
	self.next_queue_length = 3
end

function LigneGame:getDropSpeed()
	return 20
end

function LigneGame:getARR()
	return 0
end

function LigneGame:getARE()
	return 0
end

function LigneGame:getLineARE()
	return self:getARE()
end

function LigneGame:getDasLimit()
	return 6
end

function LigneGame:getLineClearDelay()
	return 0
end

function LigneGame:getLockDelay()
	return 15
end

function LigneGame:getGravity()
	return 1/64
end

function LigneGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames > 150 then
			self.completed = true
		end
		return false
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function LigneGame:onPieceLock()
	self.pieces = self.pieces + 1
end

function LigneGame:onLineClear(cleared_row_count)
	if not self.clear then
		self.lines = self.lines + cleared_row_count
		if self.lines >= self.line_goal then
			self.clear = true
		end
	end
end

function LigneGame:drawGrid(ruleset)
	self.grid:draw()
	if self.piece ~= nil then
		self:drawGhostPiece(ruleset)
	end
end

function LigneGame:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
	}
end

function LigneGame:drawScoringInfo()
	LigneGame.super.drawScoringInfo(self)
	love.graphics.setColor(1, 1, 1, 1)

	local text_x = config["side_next"] and 320 or 240
	
	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("LINES", text_x, 320, 40, "left")
	love.graphics.printf("line/min", text_x, 160, 80, "left")
	love.graphics.printf("piece/sec", text_x, 220, 80, "left")

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(string.format("%.02f", self.lines / math.max(1, self.frames) * 3600), text_x, 180, 80, "left")
	love.graphics.printf(string.format("%.04f", self.pieces / math.max(1, self.frames) * 60), text_x, 240, 80, "left")

	love.graphics.setFont(font_3x5_4)
	love.graphics.printf(math.max(0, self.line_goal - self.lines), text_x, 340, 40, "left")
end

function LigneGame:getBackground()
	return 2
end

return LigneGame
