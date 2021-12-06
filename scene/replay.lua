local ReplayScene = Scene:extend()

ReplayScene.title = "Replay"

function ReplayScene:new(replay, game_mode, ruleset, inputs)
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
	self.replay = replay
	self.replay_index = 1
	DiscordRPC:update({
		details = self.game.rpc_details,
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
end

function ReplayScene:onInputPress(e)
	if (e.input == "menu_back") then
		self.game:onExit()
		scene = ReplaySelectScene()
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then pauseBGM()
		else resumeBGM() end
	end
end

return ReplayScene
