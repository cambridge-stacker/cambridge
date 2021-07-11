local GameScene = Scene:extend()

GameScene.title = "Game"

require 'load.save'

function GameScene:new(game_mode, ruleset, inputs)
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = inputs
	self.game = game_mode(self.secret_inputs)
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
	DiscordRPC:update({
		details = self.game.rpc_details,
		state = self.game.name,
	})
end

function GameScene:update()
	if love.window.hasFocus() and not self.paused then
		local inputs = {}
		for input, value in pairs(self.inputs) do
			inputs[input] = value
		end
		self.game:update(inputs, self.ruleset)
		self.game.grid:update()
	end
end

function GameScene:render()
	self.game:draw(self.paused)
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
		self.game:onExit()
		scene = GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs)
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then pauseBGM()
		else resumeBGM() end
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
