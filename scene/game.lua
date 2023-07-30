local GameScene = Scene:extend()

GameScene.title = "Game"

require 'load.save'

function GameScene:new(game_mode, ruleset, inputs)
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = inputs
	self.game = game_mode(self.secret_inputs)
	self.game.secret_inputs = inputs
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
	self.game.pause_count = 0
	self.game.pause_time = 0
	DiscordRPC:update({
		details = self.game.rpc_details,
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function GameScene:update()
	if self.paused then
		self.game.pause_time = self.game.pause_time + 1
	else
		local inputs = {}
		for input, value in pairs(self.inputs) do
			inputs[input] = value
		end
		self.game:update(inputs, self.ruleset)
		self.game.grid:update()
		DiscordRPC:update({
			details = self.game.rpc_details,
			state = self.game.name,
			largeImageKey = "ingame-"..self.game:getBackground().."00"
		})
	end
end

function GameScene:render()
	self.game:draw(self.paused)
	if self.game.pause_time > 0 or self.game.pause_count > 0 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(string.format(
			"%d PAUSE%s (%s)",
			self.game.pause_count,
			self.game.pause_count == 1 and "" or "S",
			formatTime(self.game.pause_time)
		), 0, 0, 635, "right")
	end
end

function GameScene:onInputPress(e)
	if (
		self.game.game_over or self.game.completed
	) and (
		e.input == "menu_decide" or
		e.input == "menu_back" or
		e.input == "retry"
	) then
		highscore_entry = self.game:getHighscoreData()
		highscore_hash = self.game.hash .. "-" .. self.ruleset.hash
		submitHighscore(highscore_hash, highscore_entry)
		self.game:onExit()
		scene = e.input == "retry" and GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs) or ModeSelectScene()
	elseif e.input == "retry" then
		switchBGM(nil)
		pitchBGM(1)
		self.game:onExit()
		scene = GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs)
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then
			pauseBGM()
			self.game.pause_count = self.game.pause_count + 1
		else
			resumeBGM()
		end
	elseif e.input == "menu_back" then
		self.game:onExit()
		scene = ModeSelectScene()
	elseif e.input and string.sub(e.input, 1, 5) ~= "menu_" then
		self.inputs[e.input] = true
	end
end

function GameScene:onInputRelease(e)
	if e.input and string.sub(e.input, 1, 5) ~= "menu_" then
		self.inputs[e.input] = false
	end
end

function submitHighscore(hash, data)
	if not highscores[hash] then highscores[hash] = {} end
	table.insert(highscores[hash], data)
	saveHighscores()
end

return GameScene
