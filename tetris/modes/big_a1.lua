local MarathonA1Game = require 'tetris.modes.marathon_a1'

local BigA1Game = MarathonA1Game:extend()

BigA1Game.name = "Big A1"
BigA1Game.hash = "BigA1"
BigA1Game.tagline = "Can you survive the awkward big blocks to reach the title of Grand Master?"
BigA1Game.tags = {"Arika", "Marathon"}

function BigA1Game:new(secret_inputs)
	BigA1Game.super.new(self, secret_inputs)
	self.big_mode = true
	self.half_block_mode = true
	self.piece_spawn_offset.x = -1
end

return BigA1Game