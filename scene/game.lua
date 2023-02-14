local sha2 = require "libs.sha2"
local binser = require "libs.binser"
local GameScene = Scene:extend()

GameScene.title = "Game"

require 'load.save'

function GameScene:new(game_mode, ruleset, inputs)
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = inputs
	self.sha_tbl = {mode = sha2.sha256(binser.s(game_mode)), ruleset = sha2.sha256(binser.s(ruleset))}
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
	DiscordRPC:update({
		details = self.game.rpc_details,
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function GameScene:update()
	if love.window.hasFocus() and (not self.paused or frame_steps > 0) then
		if frame_steps > 0 then
			self.game.ineligible = true
			frame_steps = frame_steps - 1
		end
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
end

local movement_directions = {"left", "right", "down", "up"}

function GameScene:onInputPress(e)
	if (
		self.game.game_over or self.game.completed
	) and (
		e.input == "menu_decide" or
		e.input == "menu_back" or
		e.input == "retry"
	) then
		local highscore_entry = self.game:getHighscoreData()
		local highscore_hash = self.game.hash .. "-" .. self.ruleset.hash
		submitHighscore(highscore_hash, highscore_entry)
		self.game:onExit()
		loaded_replays = false
		scene = e.input == "retry" and GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs) or
				config.visualsettings.mode_select_type == 1 and ModeSelectScene() or RevModeSelectScene()
	elseif e.input == "frame_step" and TAS_mode then
		frame_steps = frame_steps + 1
	elseif e.input == "retry" then
		switchBGM(nil)
		self.game:onExit()
		scene = GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs)
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then pauseBGM()
		else resumeBGM() end
	elseif e.input == "mode_exit" then
		self.game:onExit()
		if config.visualsettings.mode_select_type == 1 then
			scene = ModeSelectScene()
		else
			scene = RevModeSelectScene()
		end
	elseif e.input and string.sub(e.input, 1, 5) ~= "menu_" and e.input ~= "frame_step" then
		self.inputs[e.input] = true
		if config.gamesettings["diagonal_input"] == 3 then
			if (e.input == "left" or e.input == "right" or e.input == "down" or e.input == "up") then
				for key, value in pairs(movement_directions) do
					if value ~= e.input then
						self.inputs[value] = false
					end
				end
				self.first_input = self.first_input or e.input
			end
		end
	end
end

function GameScene:onInputRelease(e)
	if e.input and string.sub(e.input, 1, 5) ~= "menu_" then
		self.inputs[e.input] = false
		if config.gamesettings["diagonal_input"] == 3 then
			if (e.input == "left" or e.input == "right" or e.input == "down" or e.input == "up") then
				
				if self.first_input ~= nil and self.first_input ~= e.input then
					self.inputs[self.first_input] = true
				end
				if self.first_input == e.input then
					self.first_input = nil
				end
			end
		end
	end
end

function submitHighscore(hash, data)
	if not highscores[hash] then highscores[hash] = {} end
	table.insert(highscores[hash], data)
	saveHighscores()
end

return GameScene
