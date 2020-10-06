require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local KonohaRandomizer = require 'tetris.randomizers.bag_konoha'

local KonohaGame = GameMode:extend()

KonohaGame.name = "All Clear A4"
KonohaGame.hash = "AllClearA4"
KonohaGame.tagline = "Get as many bravos as you can under the time limit!"

function KonohaGame:new()
	KonohaGame.super:new()

	self.randomizer = KonohaRandomizer()
	self.bravos = 0
	self.time_limit = 10800
	self.big_mode = true
	
	self.enable_hold = true
	self.next_queue_length = 3
end

function KonohaGame:getARE()
	    if self.level < 300  then return 30
	elseif self.level < 400  then return 25
	elseif self.level < 500  then return 20
	elseif self.level < 600  then return 17
	elseif self.level < 800  then return 15
	elseif self.level < 900  then return 13
	elseif self.level < 1000 then return 10
	elseif self.level < 1300 then return 8
	else return 6 end
end

function KonohaGame:getLineARE()
	return self:getARE()
end

function KonohaGame:getDasLimit()
	    if self.level < 500  then return 10
	elseif self.level < 800  then return 9
	elseif self.level < 1000 then return 8
	else return 7 end
end

function KonohaGame:getLineClearDelay()
	    if self.level < 200  then return 14
	elseif self.level < 500  then return 9
	elseif self.level < 800  then return 8
	elseif self.level < 1000 then return 7
	else return 6 end
end

function KonohaGame:getLockDelay()
	    if self.level < 500  then return 30
	elseif self.level < 600  then return 25
	elseif self.level < 700  then return 23
	elseif self.level < 800  then return 20
	elseif self.level < 900  then return 17
	elseif self.level < 1000 then return 15
	elseif self.level < 1200 then return 13
	elseif self.level < 1300 then return 10
	else return 8 end
end

function KonohaGame:getGravity()
	    if (self.level < 30)  then return 4/256
	elseif (self.level < 35)  then return 8/256
	elseif (self.level < 40)  then return 12/256
	elseif (self.level < 50)  then return 16/256
	elseif (self.level < 60)  then return 32/256
	elseif (self.level < 70)  then return 48/256
	elseif (self.level < 80)  then return 64/256
	elseif (self.level < 90)  then return 128/256
	elseif (self.level < 100) then return 192/256
	elseif (self.level < 120) then return 1
	elseif (self.level < 140) then return 2
	elseif (self.level < 160) then return 3
	elseif (self.level < 170) then return 4
	elseif (self.level < 200) then return 5
	else return 20 end
end

function KonohaGame:getSection()
	return math.floor(level / 100) + 1
end

function KonohaGame:getSectionEndLevel()
	return math.floor(self.level / 100 + 1) * 100
end

function KonohaGame:advanceOneFrame()
	if self.ready_frames == 0 then
		self.time_limit = self.time_limit - 1
		self.frames = self.frames + 1
	end
	if self.time_limit <= 0 then
		self.game_over = true
	end
end

function KonohaGame:onPieceEnter()
	if (self.level % 100 ~= 99) and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function KonohaGame:drawGrid(ruleset)
	self.grid:draw()
	if self.piece ~= nil and self.level < 100 then
		self:drawGhostPiece(ruleset)
	end
end

local cleared_row_levels = {2, 4, 6, 12}
local bravo_bonus = {300, 480, 660, 900}
local non_bravo_bonus = {0, 0, 20, 40}
local bravo_ot_bonus = {0, 60, 120, 180}

function KonohaGame:onLineClear(cleared_row_count)
	self.level = self.level + cleared_row_levels[cleared_row_count / 2]
	self.bravo = true
	for i = 0, 23 - cleared_row_count do
		for j = 0, 9 do
			if self.grid:isOccupied(j, i) then
				self.bravo = false
			end
		end
	end
	if self.bravo then
		self.bravos = self.bravos + 1
		if self.level < 1000 then self.time_limit = self.time_limit + bravo_bonus[cleared_row_count / 2]
		else self.time_limit = self.time_limit + bravo_ot_bonus[cleared_row_count / 2]
		end
		if self.bravos == 11 then self.randomizer.allowrepeat = true end
	elseif self.level < 1000 then
		self.time_limit = self.time_limit + non_bravo_bonus[cleared_row_count / 2]
	end
end

function KonohaGame:getBackground()
	return math.min(math.floor(self.level / 100), 9)
end

function KonohaGame:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		strTrueValues(self.prev_inputs)
	)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("TIME LIMIT", 240, 120, 120, "left")
	love.graphics.printf("BRAVOS", 240, 200, 50, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")
	
	love.graphics.setFont(font_3x5_3)
	if not self.game_over and self.time_limit < frameTime(0,10) and self.time_limit % 4 < 2 then
                love.graphics.setColor(1, 0.3, 0.3, 1)
        end
	love.graphics.printf(formatTime(self.time_limit), 240, 140, 120, "left")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self.bravos, 240, 220, 90, "left")
	love.graphics.printf(self.level, 240, 340, 50, "right")
	love.graphics.printf(self:getSectionEndLevel(), 240, 370, 50, "right")

	love.graphics.setFont(font_8x11)
	love.graphics.printf(formatTime(self.frames), 64, 420, 160, "center")
end

function KonohaGame:getHighscoreData()
	return {
		bravos = self.bravos,
		level = self.level,
		frames = self.frames,
	}
end

return KonohaGame
