local GameScene = Scene:extend()

GameScene.title = "Game"

require 'load.save'

function GameScene:new(game_mode, ruleset)
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.game = game_mode()
	self.ruleset = ruleset()
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
	DiscordRPC:update({
		details = self.game.rpc_details,
		state = self.game.name,
	})
end

function GameScene:update()
	if love.window.hasFocus() then
		local inputs = {}
		for input, value in pairs(self.inputs) do
			inputs[input] = value
		end
		self.game:update(inputs, self.ruleset)
	end

	self.game.grid:update()
end

function GameScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds[self.game:getBackground()],
		0, 0, 0,
		0.5, 0.5
	)

	-- game frame
	love.graphics.draw(misc_graphics["frame"], 48, 64)
	love.graphics.setColor(0, 0, 0, 200)
	love.graphics.rectangle("fill", 64, 80, 160, 320)

	self.game:drawGrid()
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
end

function GameScene:onInputPress(e)
	if self.game.completed and (e.input == "menu_decide" or e.input == "menu_back" or e.input == "retry") then
		highscore_entry = self.game:getHighscoreData()
		highscore_hash = self.game.hash .. "-" .. self.ruleset.hash
		submitHighscore(highscore_hash, highscore_entry)
		scene = e.input == "retry" and GameScene(self.retry_mode, self.retry_ruleset) or ModeSelectScene()
	elseif e.input == "retry" then
		scene = GameScene(self.retry_mode, self.retry_ruleset)
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
