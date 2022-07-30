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
	self.replay = deepcopy(replay)
	self.replay_index = 1
	self.replay_speed = 1
	DiscordRPC:update({
		details = "Viewing a replay",
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function ReplayScene:update()
	local frames_left = self.replay_speed
	if love.window.hasFocus() and not self.paused and not self.rerecord then
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
	elseif self.rerecord and not self.paused then
		local input_copy = {}
		for input, value in pairs(self.inputs) do
			input_copy[input] = value
		end
		self.game:update(input_copy, self.ruleset)
		self.game.grid:update()
	end
	DiscordRPC:update({
		details = "Viewing a".. (self.replay["toolassisted"] and " tool-assisted" or "") .." replay",
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function ReplayScene:render()
	self.game:draw(self.paused)
	if self.rerecord then
		return
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	if self.replay["toolassisted"] then
		love.graphics.printf("TAS REPLAY", 0, 0, 635, "right")
	else
		love.graphics.printf("REPLAY", 0, 0, 635, "right")
	end
	if self.replay_speed > 1 then
		love.graphics.printf(self.replay_speed.."X", 0, 15, 635, "right")
	end
end

function ReplayScene:onInputPress(e)
	if (
		e.input == "menu_back" or
		e.input == "menu_decide" or
		e.input == "retry"
 	) then
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
	elseif e.input and string.sub(e.input, 1, 5) ~= "menu_" and self.rerecord then
		self.inputs[e.input] = true
	elseif e.input == "hold" then
		self.rerecord = true
		self.replay_speed = 1
		self.paused = true
	elseif e.input == "left" then
		self.replay_speed = self.replay_speed - 1
		if self.replay_speed < 1 then
			self.replay_speed = 1
		end
	elseif e.input == "right" then
		self.replay_speed = self.replay_speed + 1
		if self.replay_speed > 99 then
			self.replay_speed = 99
		end
	end
end

function ReplayScene:onInputRelease(e)
	if e.input and string.sub(e.input, 1, 5) ~= "menu_" and self.rerecord then
		self.inputs[e.input] = false
	end
end

return ReplayScene
