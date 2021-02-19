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
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds[self.game:getBackground()],
		0, 0, 0,
		0.5, 0.5
	)

	-- game frame
	if self.game.grid.width == 10 and self.game.grid.height == 24 then
		love.graphics.draw(misc_graphics["frame"], 48, 64)
	end
	
	love.graphics.setColor(0, 0, 0, 200)
	love.graphics.rectangle(
		"fill", 64, 80,
		16 * self.game.grid.width, 16 * (self.game.grid.height - 4)
	)
	
	if self.game.grid.width ~= 10 or self.game.grid.height ~= 24 then
		love.graphics.setColor(174/255, 83/255, 76/255, 1)
		love.graphics.setLineWidth(8)
		love.graphics.line(
			60,76,
			68+16*self.game.grid.width,76,
			68+16*self.game.grid.width,84+16*(self.game.grid.height-4),
			60,84+16*(self.game.grid.height-4),
			60,76
		)
		love.graphics.setColor(203/255, 137/255, 111/255, 1)
		love.graphics.setLineWidth(4)
		love.graphics.line(
			60,76,
			68+16*self.game.grid.width,76,
			68+16*self.game.grid.width,84+16*(self.game.grid.height-4),
			60,84+16*(self.game.grid.height-4),
			60,76
		)
		love.graphics.setLineWidth(1)
	end

	self.game:drawGrid()
	if self.game.lcd > 0 then self.game:drawLineClearAnimation() end
	self.game:drawPiece()
	self.game:drawNextQueue(self.ruleset)
	self.game:drawScoringInfo()

	-- ready/go graphics

	if self.game.ready_frames <= 100 and self.game.ready_frames > 52 then
		love.graphics.draw(misc_graphics["ready"], 144 - 50, 240 - 14)
	elseif self.game.ready_frames <= 50 and self.game.ready_frames > 2 then
		love.graphics.draw(misc_graphics["go"], 144 - 27, 240 - 14)
	end

	self.game:drawCustom()

	love.graphics.setFont(font_3x5_2)
	if config.gamesettings.display_gamemode == 1 then
		love.graphics.printf(self.game.name .. " - " .. self.ruleset.name, 0, 460, 640, "left")
	end

	love.graphics.setFont(font_3x5_3)
	if self.paused then love.graphics.print("PAUSED!", 80, 100) end

	if self.game.completed then
		self.game:onGameComplete()
	elseif self.game.game_over then
		self.game:onGameOver()
	end
end

function GameScene:onInputPress(e)
	if (self.game.game_over or self.game.completed) and (e.input == "menu_decide" or e.input == "menu_back" or e.input == "retry") then
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
