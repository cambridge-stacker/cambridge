local MarathonA2Game = require 'tetris.modes.marathon_a2'

local BigA2Game = MarathonA2Game:extend()

BigA2Game.name = "Big A2"
BigA2Game.hash = "BigA2"
BigA2Game.tagline = "Big blocks in the most celebrated TGM mode!"

function BigA2Game:new()
	MarathonA2Game:new()
	self.big_mode = true
end

function BigA2Game:onLineClear(cleared_row_count)
	return MarathonA2Game:onLineClear(cleared_row_count / 2)
end

function BigA2Game:updateScore(level, drop_bonus, cleared_lines)
	return MarathonA2Game:updateScore(level, drop_bonus, cleared_lines / 2)
end

return BigA2Game