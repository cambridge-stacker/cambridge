require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls_35bag'

local MarathonA3Game = GameMode:extend()

MarathonA3Game.name = "Marathon A3"
MarathonA3Game.hash = "MarathonA3"
MarathonA3Game.tagline = "The game gets faster way more quickly! Can you get all the Section COOLs?"




function MarathonA3Game:new()
	MarathonA3Game.super:new()

	self.speed_level = 0
	self.roll_frames = 0
	self.combo = 1
	self.grade_combo = 1
	self.grade = 0
	self.grade_points = 0
	self.roll_points = 0
	self.grade_point_decay_counter = 0
	self.section_cool_grade = 0
	--self.section_status = { [0] = "none" }
	self.section_cools = { [0] = 0 }
	self.section_regrets = { [0] = 0 }
	self.section_start_time = 0
	self.secondary_section_times = { [0] = 0 }
	self.section_times = { [0] = 0 }
	self.section_cool = false

	self.randomizer = History6RollsRandomizer()

	self.SGnames = {
		"9", "8", "7", "6", "5", "4", "3", "2", "1",
		"S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9",
		"GM"
	}

	self.additive_gravity = false
	self.lock_drop = true
	self.lock_hard_drop = true
	self.enable_hold = true
	self.next_queue_length = 3

	self.coolregret_message = "COOL!!"
	self.coolregret_timer = 0

	self.grade_up_timer = 0

	self.bgm_level = 1
	self.bgm_muted = false
	self.noti_counter_stop = true

	self.torikan_passed = false
end

function MarathonA3Game:getARE()
		if self.speed_level < 700 then return 27
	elseif self.speed_level < 800 then return 18
	elseif self.speed_level < 1000 then return 14
	elseif self.speed_level < 1100 then return 8
	elseif self.speed_level < 1200 then return 7
	else return 6 end
end

function MarathonA3Game:getLineARE()
		if self.speed_level < 600 then return 27
	elseif self.speed_level < 700 then return 18
	elseif self.speed_level < 800 then return 14
	elseif self.speed_level < 1100 then return 8
	elseif self.speed_level < 1200 then return 7
	else return 6 end
end

function MarathonA3Game:getDasLimit()
		if self.speed_level < 500 then return 15
	elseif self.speed_level < 900 then return 9
	else return 7 end
end

function MarathonA3Game:getLineClearDelay()
		if self.speed_level < 500 then return 40
	elseif self.speed_level < 600 then return 25
	elseif self.speed_level < 700 then return 16
	elseif self.speed_level < 800 then return 12
	elseif self.speed_level < 1100 then return 6
	elseif self.speed_level < 1200 then return 5
	else return 4 end
end

function MarathonA3Game:getLockDelay()
		if self.speed_level < 900 then return 30
	elseif self.speed_level < 1100 then return 17
	else return 15 end
end

function MarathonA3Game:getGravity()
		if (self.speed_level < 30)  then return 4/256
	elseif (self.speed_level < 35)  then return 6/256
	elseif (self.speed_level < 40)  then return 8/256
	elseif (self.speed_level < 50)  then return 10/256
	elseif (self.speed_level < 60)  then return 12/256
	elseif (self.speed_level < 70)  then return 16/256
	elseif (self.speed_level < 80)  then return 32/256
	elseif (self.speed_level < 90)  then return 48/256
	elseif (self.speed_level < 100) then return 64/256
	elseif (self.speed_level < 120) then return 80/256
	elseif (self.speed_level < 140) then return 96/256
	elseif (self.speed_level < 160) then return 112/256
	elseif (self.speed_level < 170) then return 128/256
	elseif (self.speed_level < 200) then return 144/256
	elseif (self.speed_level < 220) then return 4/256
	elseif (self.speed_level < 230) then return 32/256
	elseif (self.speed_level < 233) then return 64/256
	elseif (self.speed_level < 236) then return 96/256
	elseif (self.speed_level < 239) then return 128/256
	elseif (self.speed_level < 243) then return 160/256
	elseif (self.speed_level < 247) then return 192/256
	elseif (self.speed_level < 251) then return 224/256
	elseif (self.speed_level < 300) then return 1
	elseif (self.speed_level < 330) then return 2
	elseif (self.speed_level < 360) then return 3
	elseif (self.speed_level < 400) then return 4
	elseif (self.speed_level < 420) then return 5
	elseif (self.speed_level < 450) then return 4
	elseif (self.speed_level < 500) then return 3
	else return 20
	end
end

-- 1-based index. Returns nil if the index is out of bounds
-- attempt to compare nil with number cause game crash.
local bgm_mute_speed_levels = {485, 785, 99999999}

function MarathonA3Game:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		
		if self.roll_frames < 0 then
			-- game clear, before roll started(roll ready frames)
			if (self.roll_frames % 5 == 0) then
				-- Slowly clear the grid starting from the bottom.
				for i = -145, -30, 5 do
					if self.roll_frames == i then
						local rowsToClear = (150 + i) / 5
						self.grid:clearBottomRows(rowsToClear)
					end
				end
			end

			if self.lcd > 0 then
				-- perform the last line clear process during roll ready frames.
				return true
			else
				-- halt gameplay until the roll starts.
				return false
			end
		elseif self.roll_frames == 0 then
			switchBGM("a3", "credit_roll")
		elseif self.roll_frames > 3238 then
			-- roll completed
			local old_aggregate_grade = self:getAggregateGrade()

			if self:qualifiesForMRoll() then
				self.roll_points = self.roll_points + 160
			else
				self.roll_points = self.roll_points + 50
			end
			
			local new_aggregate_grade = self:getAggregateGrade()

			-- play "grade up" SE when the aggregate grade increases via roll completed
			if old_aggregate_grade < new_aggregate_grade then
				self.grade_up_timer = 120
				playSEOnce("grade_up")
			end

			switchBGM(nil)
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		-- Game started, self.ready_frames is set and remains fixed at 0
		-- only self.frames starts increasing
		self.frames = self.frames + 1
	end
	if self.frames == 1 then
		-- Play BGM from the first frame
		switchBGMLoop("a3", "track" .. self.bgm_level)
	end

	-- bgm muted when temp speed levels hit certain levels and conditions.
	local temp_speed_levels = self.section_cool and self.speed_level + 100 or self.speed_level
	if not self.bgm_muted and bgm_mute_speed_levels[self.bgm_level] <= temp_speed_levels and temp_speed_levels % 100 >= 85 then
		self.bgm_muted = true
		switchBGM(nil)
	end

	return true
end

function MarathonA3Game:onPieceEnter()
	if (self.level % 100 ~= 99) and self.level ~= 998 and self.frames ~= 0 then
		self:updateSectionTimes(self.level, self.level + 1)
		self.level = self.level + 1
		self.speed_level = self.speed_level + 1
		self.torikan_passed = self.level >= 500 and true or false
	elseif (self.level % 100 == 99 or self.level == 998) and not self.clear and self.noti_counter_stop then
		-- Play a counter stop notification sound once until line clear
		playSE("bell")
		self.noti_counter_stop = false
	end
end

local cleared_row_levels = {1, 2, 4, 6}

function MarathonA3Game:onLineClear(cleared_row_count)
	local advanced_levels = cleared_row_levels[cleared_row_count]
	self.noti_counter_stop = true
	self:updateSectionTimes(self.level, self.level + advanced_levels)
	self:playSectionChangeSound(self.level, self.level + advanced_levels)
	
	if not self.clear then
		self.level = math.min(self.level + advanced_levels, 999)
		self.speed_level = self.speed_level + advanced_levels
		
	end
	if self.level == 999 and not self.clear then
		-- game clear condition is met.
		-- reduce the line clear delay for a smoother grid clear animation.
		-- Set ARE = 1 for next blocks appear immediately after the roll starts.
		self.clear = true
		self.roll_frames = -150
		self.lcd = 4
		self.are = 1
		switchBGM(nil)
		playSE("game_clear")
	end
	if not self.torikan_passed and self.level >= 500 and self.frames >= 25200 then
	self.level = 500
	self.game_over = true
	end
end

local cool_cutoffs = {
	frameTime(0,52), frameTime(0,52), frameTime(0,49), frameTime(0,45), frameTime(0,45),
	frameTime(0,42), frameTime(0,42), frameTime(0,38), frameTime(0,38),
}

local regret_cutoffs = {
	frameTime(0,90), frameTime(0,75), frameTime(0,75), frameTime(0,68), frameTime(0,60),
	frameTime(0,60), frameTime(0,50), frameTime(0,50), frameTime(0,50), frameTime(0,50),
}

function MarathonA3Game:updateSectionTimes(old_level, new_level)
	if self.clear then return end
	local section = math.floor(old_level / 100) + 1
	if math.floor(old_level / 100) < math.floor(new_level / 100) or
	new_level >= 999 then
		-- record new section
		local section_time = self.frames - self.section_start_time
		table.insert(self.section_times, section_time)
		if new_level < 999 then self.section_start_time = self.frames end

		self.speed_level = self.section_cool and self.speed_level + 100 or self.speed_level

		if section_time > regret_cutoffs[section] then
			if self.grade > 0 then
				--this happens after the points are added, intentionally
				local currentgrade = self:getAggregateGrade()
				while self:getAggregateGrade() >= currentgrade do
					self.grade = self.grade - 1
				end
				self.grade_points = 0
			end
			table.insert(self.section_regrets, 1)
			self.coolregret_message = "REGRET!!"
			self.coolregret_timer = 300
		else
			table.insert(self.section_regrets, 0)
		end

		if self.section_cool then
			-- play "grade up" SE when the aggregate grade increases via section cool
			self.section_cool_grade = self.section_cool_grade + 1
			self.grade_up_timer = 120
			playSEOnce("grade_up")
		end

		self.section_cool = false
	elseif old_level % 100 < 70 and new_level % 100 >= 70 then
		-- record section 70 time
		local section_70_time = self.frames - self.section_start_time
		table.insert(self.secondary_section_times, section_70_time)

		if section <= 9 and self.secondary_section_times[section] < cool_cutoffs[section] and
		  (section == 1 or self.secondary_section_times[section] <= self.secondary_section_times[section - 1] + 120) then
			self.section_cool = true
			self.coolregret_message = "COOL!!"
			self.coolregret_timer = 300
			playSE("cool")
			table.insert(self.section_cools, 1)
		else
			table.insert(self.section_cools, 0)
		end
	end
end

function MarathonA3Game:playSectionChangeSound(old_level, new_level)
	if math.floor(old_level / 100) < math.floor(new_level / 100) and not self.clear then
		-- play section change SE
		playSE("level_change")

		if self.bgm_muted then
			--play the next BGM when BGM is muted and entering a new section.
			self.bgm_muted = false
			self.bgm_level = self.bgm_level + 1
			switchBGMLoop("a3", "track" .. self.bgm_level)
		end
	end
end

function MarathonA3Game:updateScore(level, drop_bonus, cleared_lines)
	local old_aggregate_grade = self:getAggregateGrade()
	self:updateGrade(cleared_lines)
	local new_aggregate_grade = self:getAggregateGrade()

	if old_aggregate_grade < new_aggregate_grade then
		-- Play "grade up" SE when the aggregate grade(not the internal grade) increases via line clear 
		self.grade_up_timer = 120
		playSEOnce("grade_up")
	end
	if not self.clear then
		if cleared_lines > 0 then
			self.combo = self.combo + (cleared_lines - 1) * 2
			if cleared_lines > 1 then
				self.grade_combo = self.grade_combo + 1
			end
			self.score = self.score + (
				(math.ceil((level + cleared_lines) / 4) + drop_bonus) *
				cleared_lines * self.combo
			)
		else
			self.combo = 1
			self.grade_combo = 1
		end
		self.drop_bonus = 0
	end
end

local grade_point_bonuses = {
	{10, 20, 40, 50},
	{10, 20, 30, 40},
	{10, 20, 30, 40},
	{10, 15, 30, 40},
	{10, 15, 20, 40},
	{5, 15, 20, 30},
	{5, 10, 20, 30},
	{5, 10, 15, 30},
	{5, 10, 15, 30},
	{5, 10, 15, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
}

local grade_point_decays = {
	125, 80, 80, 50, 45, 45, 45,
	40, 40, 40, 40, 40, 30, 30, 30,
	20, 20, 20, 20, 20,
	15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
	10, 10
}

local combo_multipliers = {
	{1.0, 1.0, 1.0, 1.0},
	{1.0, 1.2, 1.4, 1.5},
	{1.0, 1.2, 1.5, 1.8},
	{1.0, 1.4, 1.6, 2.0},
	{1.0, 1.4, 1.7, 2.2},
	{1.0, 1.4, 1.8, 2.3},
	{1.0, 1.4, 1.9, 2.4},
	{1.0, 1.5, 2.0, 2.5},
	{1.0, 1.5, 2.1, 2.6},
	{1.0, 2.0, 2.5, 3.0},
}

local roll_points = {4, 8, 12, 26}
local mroll_points = {10, 20, 30, 100}

local grade_conversion = {
	[0] = 0,
	1, 2, 3, 4, 5, 5, 6, 6, 7, 7,
	7, 8, 8, 8, 9, 9, 9, 10, 11, 12,
	12, 12, 13, 13, 14, 14, 15, 15, 16, 16,
	17
}

function MarathonA3Game:whilePieceActive()
	self.grade_point_decay_counter = self.grade_point_decay_counter + 1
	if self.grade_point_decay_counter >= grade_point_decays[self.grade + 1] then
		self.grade_point_decay_counter = 0
		self.grade_points = math.max(0, self.grade_points - 1)
	end
end

function MarathonA3Game:updateGrade(cleared_lines)
	if cleared_lines == 0 then return
	else
		if self.clear then
			-- during credit roll
			if self:qualifiesForMRoll() then
				self.roll_points = self.roll_points + mroll_points[cleared_lines]
			else
				self.roll_points = self.roll_points + roll_points[cleared_lines]
			end
		else
			-- during normal play
			self.grade_points = self.grade_points + (
				math.ceil(
					grade_point_bonuses[self.grade + 1][cleared_lines] *
					combo_multipliers[math.min(self.grade_combo, 10)][cleared_lines]
				) * (1 + math.floor(self.level / 250))
			)
			if self.grade_points >= 100 and self.grade < 31 then
				-- internal grade up
				self.grade_points = 0
				self.grade = self.grade + 1
			end
		end
	end
end

function MarathonA3Game:qualifiesForMRoll()
	return self.grade >= 27 and self.section_cool_grade >= 9
end

function MarathonA3Game:getAggregateGrade()
	return math.min(
		self.section_cool_grade +
		math.floor(self.roll_points / 100) +
		grade_conversion[self.grade]
	)
end

local master_grades = { "M", "MK", "MV", "MO", "MM" }

function MarathonA3Game:getLetterGrade()
	local grade = self:getAggregateGrade()
	if grade < 9 then
		return tostring(9 - grade)
	elseif grade < 18 then
		return "S" .. tostring(grade - 8)
	elseif grade < 27 then
		return "M" .. tostring(grade - 17)
	elseif grade < 32 then
		return master_grades[grade - 26]
	else
		return "GM"
	end
end

function MarathonA3Game:drawGrid()
	-- Set the invisible flag after the grid is completely cleared.
	if (self.clear and self.roll_frames > -30) and not (self.completed or self.game_over) then
		if self:qualifiesForMRoll() then
			self.grid:drawInvisible(self.mRollOpacityFunction)
		else
			self.grid:drawInvisible(self.rollOpacityFunction)
		end
	else
		self.grid:draw()
		if self.piece ~= nil and self.level < 100 then
			self:drawGhostPiece(ruleset)
		end
	end
end

MarathonA3Game.rollOpacityFunction = function(age)
	if age < 240 then return 1
	elseif age > 300 then return 0
	else return 1 - (age - 240) / 60 end
end

MarathonA3Game.mRollOpacityFunction = function(age)
	if age > 4 then return 0
	else return 1 - age / 4 end
end

function MarathonA3Game:sectionColourFunction(section)
	if self.section_cools[section] == 1 and self.section_regrets[section] == 1 then
		return { 1, 1, 0, 1 }
	elseif self.section_cools[section] == 1 then
		return { 0, 1, 0, 1 }
	elseif self.section_regrets[section] == 1 then
		return { 1, 0, 0, 1 }
	else
		return { 1, 1, 1, 1 }
	end
end

function MarathonA3Game:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)

	-- draw input display
	love.graphics.printf(
		self.das.direction .. " " .. self.das.frames .. " " .. strTrueValues(self.prev_inputs), 
		0, 0, 635, "left"
	)

	-- draw labels
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("GRADE", 240, 120, 40, "left")
	love.graphics.printf("SCORE", 240, 200, 40, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")
	local sg = self.grid:checkSecretGrade()
	if sg >= 5 then
		love.graphics.printf("SECRET GRADE", 240, 430, 180, "left")
	end

	-- draw section time data
	local current_section = self.level >= 999 and 11 or math.floor(self.level / 100) + 1
	self:drawSectionTimesWithSecondary(current_section, 10)

	-- draw cool or regret message
	if self.coolregret_timer > 0 then
		local coolregret_color = self.coolregret_timer % 6 < 4 and { 1, 1, 0, 1 } or { 1, 1, 1, 1 }

		love.graphics.setColor(coolregret_color[1], coolregret_color[2], coolregret_color[3], coolregret_color[4])
		love.graphics.printf(self.coolregret_message, 64, 400, 160, "center")
		love.graphics.setColor(1, 1, 1, 1)
		
		self.coolregret_timer = self.coolregret_timer - 1
	end

	-- draw score value
	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.score, 240, 220, 90, "left")

	-- draw grade value
	if self.grade_up_timer > 0 then
		local grade_up_color = self.grade_up_timer % 6 < 4 and { 1, 0, 0, 1 } or { 1, 1, 1, 1 }
		love.graphics.setColor(grade_up_color[1], grade_up_color[2], grade_up_color[3], grade_up_color[4])
		love.graphics.printf(self:getLetterGrade(), 240, 140, 90, "left")
		self.grade_up_timer = self.grade_up_timer - 1
	else
		if self.roll_frames > 3238 then love.graphics.setColor(1, 0.5, 0, 1)
		elseif self.level >= 999 then love.graphics.setColor(0, 1, 0, 1) end
		love.graphics.printf(self:getLetterGrade(), 240, 140, 90, "left")
	end

	-- draw level value
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self.level, 240, 340, 40, "right")
	love.graphics.printf(self:getSectionEndLevel(), 240, 370, 40, "right")

	-- draw secret grade value
	if sg >= 5 then
		love.graphics.printf(self.SGnames[sg], 240, 450, 180, "left")
	end

	-- draw playtime
	love.graphics.setFont(font_8x11)
	love.graphics.printf(formatTime(self.frames), 64, 420, 160, "center")
end


function MarathonA3Game:onGameComplete()
	-- custom game complete animation
	-- same game_over_frames are used upon game completion.
	switchBGM(nil)

	if self.game_over_frames == 0 then
		playSE("game_clear")
	end

	-- 5 frames text zoom out (1.05 -> 0.85, 1.2 -> 1)
	-- 4 frames(y) -> 2 frames(w) color loop
	local exc_text_scale = 1.05 - math.min(0.2, 0.05 * self.game_over_frames)
	local clear_text_scale = 1.2 - math.min(0.2, 0.05 * self.game_over_frames)

	local exc_text_color = self.game_over_frames % 6 < 4 and { 1, 1, 0, 1 } or { 1, 1, 1, 1 }

	-- Using images instead of text might help create a more natural zoom-out animation...
    love.graphics.push()
	love.graphics.setFont(font_8x11)
	love.graphics.setColor(exc_text_color[1], exc_text_color[2], exc_text_color[3], exc_text_color[4])
    love.graphics.scale(exc_text_scale, exc_text_scale)
	love.graphics.printf("EXCELLENT", 60/exc_text_scale, 140/exc_text_scale, 200, "center")
	love.graphics.pop()

	love.graphics.push()
	love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
    love.graphics.scale(clear_text_scale, clear_text_scale)
	love.graphics.printf("Marathon A3", 63/clear_text_scale, 194/clear_text_scale, 160, "center")
	love.graphics.printf("ALL CLEAR", 63/clear_text_scale, 216/clear_text_scale, 160, "center")
    love.graphics.pop()
end


function MarathonA3Game:onGameOver()
	-- custom game over animation
	switchBGM(nil)

	if not self.clear then
		-- Only a normal play top-out shows the game over animation.
		-- A top-out during the credit roll does not show the game over animation.
		local max_height = self.grid.height
		if self.game_over_frames < max_height then
			local dimmed_height = max_height - self.game_over_frames
			local dimmed_line = self.grid.grid[dimmed_height]

			if dimmed_line ~= nil then
				-- double check for safety
				for x = 1, self.grid.width do
					self.grid.grid[dimmed_height][x].colour = "A"
				end
			end
		end

		if self.game_over_frames == max_height then
			-- play game_over SE once
			playSE("game_over")
		end

		if self.game_over_frames >= max_height then
			-- draw game_over text afterward.
			love.graphics.setFont(font_8x11)
			love.graphics.printf("GAME OVER", 64, 208, 160, "center")
		end
	end
end

function MarathonA3Game:getHighscoreData()
	return {
		grade = self:getAggregateGrade(),
		level = self.level,
		frames = self.frames,
	}
end

function MarathonA3Game:getSectionEndLevel()
	if self.level >= 900 then return 999
	else return math.floor(self.level / 100 + 1) * 100 end
end

function MarathonA3Game:getBackground()
	return math.floor(self.level / 100)
end

return MarathonA3Game
