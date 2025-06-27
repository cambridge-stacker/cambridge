local Piece = require 'tetris.components.piece'
local Ruleset = require 'tetris.rulesets.arika_ace2'

local ARS = Ruleset:extend()

ARS.name = "ACE-ARS"
ARS.hash = "ArikaACE"
ARS.description = "A modified version of ARS that integrates SRS-like locking behaviour, from TGM ACE."

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
