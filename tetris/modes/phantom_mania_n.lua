local PhantomManiaGame = require 'tetris.modes.phantom_mania'

local PhantomManiaNGame = PhantomManiaGame:extend()

PhantomManiaNGame.name = "Phantom Mania N"
PhantomManiaNGame.hash = "PhantomManiaN"
PhantomManiaNGame.tagline = "The old mode from Nullpomino, for Ti-ARS and SRS support."

function PhantomManiaNGame:new()
	PhantomManiaNGame.super:new()
	
	self.SGnames = {
		"M1",  "M2",  "M3",  "M4",  "M5",  "M6",  "M7",  "M8",  "M9",
		"M10", "M11", "M12", "M13", "M14", "M15", "M16", "M17", "M18",
		"GM"
	}

	self.next_queue_length = 3
	self.enable_hold = true
end

return PhantomManiaNGame
