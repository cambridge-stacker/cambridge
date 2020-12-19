local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.arika_ti'

local ARS = Ruleset:extend()

ARS.name = "ACE-ARS"
ARS.hash = "ArikaACE"

ARS.colourscheme = {
	I = "C",
	L = "O",
	J = "B",
	S = "G",
	Z = "R",
	O = "Y",
	T = "M",
}

ARS.softdrop_lock = false
ARS.harddrop_lock = true

ARS.spawn_positions = {
	I = { x=5, y=2 },
	J = { x=4, y=3 },
	L = { x=4, y=3 },
	O = { x=5, y=3 },
	S = { x=4, y=3 },
	T = { x=4, y=3 },
	Z = { x=4, y=3 },
}

ARS.big_spawn_positions = {
	I = { x=3, y=0 },
	J = { x=2, y=1 },
	L = { x=2, y=1 },
	O = { x=3, y=1 },
	S = { x=2, y=1 },
	T = { x=2, y=1 },
	Z = { x=2, y=1 },
}

function ARS:onPieceCreate(piece, grid)
	piece.floorkick = 0
	piece.manipulations = 0
end

function ARS:onPieceMove(piece, grid)
	piece.lock_delay = 0 -- move reset
	if piece:isDropBlocked(grid) then
		piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= 128 then
			piece:dropToBottom(grid)
			piece.locked = true
		end
	end
end

function ARS:onPieceRotate(piece, grid)
	piece.lock_delay = 0 -- rotate reset
	if piece:isDropBlocked(grid) then
		piece.manipulations = piece.manipulations + 1
		if piece.manipulations >= 128 then
			piece:dropToBottom(grid)
			piece.locked = true
		end
	end
	if piece.floorkick >= 1 then
		piece.floorkick = piece.floorkick + 1
	end
end

return ARS
