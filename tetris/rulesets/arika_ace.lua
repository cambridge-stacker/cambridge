local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.arika_ace2'

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

return ARS
