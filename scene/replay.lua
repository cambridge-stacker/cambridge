local Sequence = require 'tetris.randomizers.fixed_sequence'

local ReplayScene = Scene:extend()

ReplayScene.title = "Replay"

function ReplayScene:new(replay, game_mode, ruleset, inputs)
	config.gamesettings = replay["gamesettings"]
	love.math.setRandomSeed(replay["random_low"], replay["random_high"])
	love.math.setRandomState(replay["random_state"])
	self.retry_replay = replay
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = inputs
	self.game = game_mode(self.secret_inputs)
	self.ruleset = ruleset(self.game)
	self.game:initialize(self.ruleset, true)
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
	DiscordRPC:update({
		details = "Viewing a replay",
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function ReplayScene:update()
	if love.window.hasFocus() and not self.paused then
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
		DiscordRPC:update({
			largeImageKey = "ingame-"..self.game:getBackground().."00"
		})
	end
end

function ReplayScene:render()
	self.game:draw(self.paused)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	love.graphics.printf("REPLAY", 0, 0, 635, "right")
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
	end
end

return ReplayScene
