require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local PacerTest = GameMode:extend()

PacerTest.name = "TetrisGram™ Pacer Test"
PacerTest.hash = "PacerTest"
PacerTest.tagline = ""




local function getLevelFrames(level)
	if level == 1 then return 72 * 60 / 8.0
	else return 72 * 60 / (8 + level * 0.5)
	end
end

local level_end_sections = {
	7, 15, 23, 32, 41, 51, 61, 72, 83, 94,
	106, 118, 131, 144, 157, 171, 185, 200,
	215, 231, 247
}

function PacerTest:new()
	PacerTest.super:new()

	self.ready_frames = 2430
	self.clear_frames = 0
	self.randomizer = History6RollsRandomizer()

	self.level = 1
	self.section = 0
	self.level_frames = 0

	self.section_lines = 0
	self.section_clear = false
	self.strikes = 0

	self.lock_drop = true
	self.lock_hard_drop = true
	self.enable_hold = true
	self.instant_hard_drop = true
	self.instant_soft_drop = false
	self.next_queue_length = 3
end

function PacerTest:initialize(ruleset)
	for i = 1, 30 do
		table.insert(self.next_queue, self:getNextPiece(ruleset))
	end
	self.level_frames = getLevelFrames(1)
	switchBGM("pacer_test")
end

function PacerTest:getARE()
	return 0
end

function PacerTest:getLineARE()
	return 0
end

function PacerTest:getDasLimit()
	return 8
end

function PacerTest:getLineClearDelay()
	return 6
end

function PacerTest:getLockDelay()
	return 30
end

function PacerTest:getGravity()
	return 1/64
end

function PacerTest:getSection()
	return math.floor(level / 100) + 1
end

function PacerTest:advanceOneFrame()
	if self.clear then
		self.clear_frames = self.clear_frames + 1
		if self.clear_frames > 600 then
			self.completed = true
		end
		return false
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
		self.level_frames = self.level_frames - 1
		if self.level_frames <= 0 then
			self:checkSectionStatus()
			self.section = self.section + 1
			if self.section >= level_end_sections[self.level] then
				self.level = self.level + 1
			end
			self.level_frames = self.level_frames + getLevelFrames(self.level)
		end
	end
	return true
end

function PacerTest:checkSectionStatus()
	if self.section_clear then
		self.strikes = 0
		self.section_clear = false
	else
		self.strikes = self.strikes + 1
		if self.strikes >= 2 then
			self.game_over = true
			fadeoutBGM(2.5)
		end
	end
	self.section_lines = 0
end

function PacerTest:onLineClear(cleared_row_count)
	self.section_lines = self.section_lines + cleared_row_count
	if self.section_lines >= 3 then
		self.section_clear = true
	end
end

function PacerTest:drawGrid(ruleset)
	self.grid:draw()
	if self.piece ~= nil then
		self:drawGhostPiece(ruleset)
	end
end

function PacerTest:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
	}
end

function PacerTest:drawScoringInfo()
	PacerTest.super.drawScoringInfo(self)
	love.graphics.setColor(1, 1, 1, 1)

	local text_x = config["side_next"] and 320 or 240

	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("LINES", text_x, 224, 70, "left")
	love.graphics.printf("LEVEL", text_x, 320, 40, "left")

	for i = 1, math.min(self.strikes, 3) do
		love.graphics.draw(misc_graphics["strike"], text_x + (i - 1) * 30, 280)
	end

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.section_lines .. "/3", text_x, 244, 40, "left")
	love.graphics.printf(self.level, text_x, 340, 40, "right")
	love.graphics.printf(self.section, text_x, 370, 40, "right")
end

function PacerTest:getBackground()
	return math.min(self.level - 1, 19)
end

return PacerTest
