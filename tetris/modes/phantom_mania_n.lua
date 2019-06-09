local PhantomManiaGame = require 'tetris.modes.phantom_mania'

local PhantomManiaNGame = PhantomManiaGame:extend()

PhantomManiaNGame.name = "Phantom Mania N"
PhantomManiaNGame.hash = "PhantomManiaN"
PhantomManiaNGame.tagline = "The old mode from Nullpomino, for Ti-ARS and SRS support."

function PhantomManiaNGame:new()
	PhantomManiaNGame.super:new()

	self.next_queue_length = 3
	self.enable_hold = true
end

return PhantomManiaNGame
