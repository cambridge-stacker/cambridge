local GameMode = require 'tetris.modes.gamemode'
local MarathonA2Game = require 'tetris.modes.marathon_a2'

local BigA2Game = MarathonA2Game:extend()

BigA2Game.name = "Big A2"
BigA2Game.hash = "BigA2"
BigA2Game.description = "Big blocks in the most celebrated TGM mode!"
BigA2Game.tags = {"Arika", "Marathon"}

function BigA2Game:new(secret_inputs)
	BigA2Game.super.new(self, secret_inputs)
	self.big_mode = true
	local getClearedRowCount = self.grid.getClearedRowCount
	self.grid.getClearedRowCount = function(self)
		return getClearedRowCount(self) / 2
	end
end

return BigA2Game