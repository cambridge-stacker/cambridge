local MarathonA1Game = require 'tetris.modes.marathon_a1'

local BigA1Game = MarathonA1Game:extend()

BigA1Game.name = "Big A1"
BigA1Game.hash = "BigA1"
BigA1Game.tagline = "Big blocks in the most celebrated TGM mode!"

function BigA1Game:new()
	BigA1Game.super:new()
	self.big_mode = true
	self.half_block_mode = true
	self.piece_spawn_offset.x = -1
end

return BigA1Game