local Sequence = require 'tetris.randomizers.fixed_sequence'

local ReplayScene = Scene:extend()

ReplayScene.title = "Replay"

function ReplayScene:new(replay, game_mode, ruleset)
	config.gamesettings = replay["gamesettings"]
	if replay["delayed_auto_shift"] then config.das = replay["delayed_auto_shift"] end
	if replay["auto_repeat_rate"] then config.arr = replay["auto_repeat_rate"] end
	if replay["das_cut_delay"] then config.dcd = replay["das_cut_delay"] end
	love.math.setRandomSeed(replay["random_low"], replay["random_high"])
	love.math.setRandomState(replay["random_state"])
	self.retry_replay = replay
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = replay["secret_inputs"]
	self.game = game_mode(self.secret_inputs)
	self.game.save_replay = false
	self.ruleset = ruleset(self.game)
	self.game:initialize(self.ruleset)
	self.inputs = {
		left=false,
		right=false,
		up=false,
		down=false,
		rotate_left=false,
		rotate_left2=false,
		rotate_right=false,
		rotate_right2=false,
		rotate_180=false,
		hold=false,
	}
	self.paused = false
	self.game.pause_count = replay["pause_count"]
	self.game.pause_time = replay["pause_time"]
	self.replay = deepcopy(replay)
	self.replay_index = 1
	self.replay_speed = 1
	self.show_invisible = false
	self.frame_steps = 0
	DiscordRPC:update({
		details = "Viewing a replay",
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function ReplayScene:update()
	local frames_left = self.replay_speed
	if not self.paused or self.frame_steps > 0 then
		if self.frame_steps > 0 then
			self.frame_steps = self.frame_steps - 1
		end
		while frames_left > 0 do
			frames_left = frames_left - 1
			self.inputs = self.replay["inputs"][self.replay_index]["inputs"]
			self.replay["inputs"][self.replay_index]["frames"] = self.replay["inputs"][self.replay_index]["frames"] - 1
			if self.replay["inputs"][self.replay_index]["frames"] == 0 and self.replay_index < table.getn(self.replay["inputs"]) then
				self.replay_index = self.replay_index + 1
			end
			local input_copy = {}
			for input, value in pairs(self.inputs) do
				input_copy[input] = value
			end
			self.game:update(input_copy, self.ruleset)
			self.game.grid:update()
		end
		DiscordRPC:update({
			details = "Viewing a replay",
			state = self.game.name,
			largeImageKey = "ingame-"..self.game:getBackground().."00"
		})
	end
end

function ReplayScene:render()
	self.game:draw(self.paused)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	love.graphics.printf("REPLAY", 0, 0, 635, "right")
	local pauses_y_coordinate = 23
	if self.replay_speed > 1 then
		pauses_y_coordinate = pauses_y_coordinate + 20
		love.graphics.printf(self.replay_speed.."X", 0, 20, 635, "right")
	end
	love.graphics.setFont(font_3x5_2)
	if self.game.pause_time and self.game.pause_count then
		if self.game.pause_time > 0 or self.game.pause_count > 0 then
			love.graphics.printf(string.format(
				"%d PAUSE%s (%s)",
				self.game.pause_count,
				self.game.pause_count == 1 and "" or "S",
				formatTime(self.game.pause_time)
			), 0, pauses_y_coordinate, 635, "right")
		end
	else
		love.graphics.printf("?? PAUSES (--:--.--)", 0, pauses_y_coordinate, 635, "right")
	end
	if self.show_invisible then 
		self.game.grid:draw()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("SHOW INVIS", 64, 60, 160, "center")
	end
end

function ReplayScene:onInputPress(e)
	if (
		e.input == "menu_back" or
		e.input == "menu_decide" or
		e.input == "retry"
 	) then
		switchBGM(nil)
		pitchBGM(1)
		self.game:onExit()
		loadSave()
		love.math.setRandomSeed(os.time())
		scene = (
			(e.input == "retry") and
			ReplayScene(
				self.retry_replay, self.retry_mode,
				self.retry_ruleset, self.secret_inputs
			) or ReplaySelectScene()
	 	)
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then pauseBGM()
		else resumeBGM() end
	--frame step
	elseif e.input == "rotate_left" then
		self.frame_steps = self.frame_steps + 1
	elseif e.input == "left" then
		self.replay_speed = self.replay_speed - 1
		if self.replay_speed < 1 then
			self.replay_speed = 1
		end
		pitchBGM(self.replay_speed)
	elseif e.input == "right" then
		self.replay_speed = self.replay_speed + 1
		if self.replay_speed > 99 then
			self.replay_speed = 99
		end
		pitchBGM(self.replay_speed)
	elseif e.input == "hold" then
		self.show_invisible = not self.show_invisible
	end
end

return ReplayScene
