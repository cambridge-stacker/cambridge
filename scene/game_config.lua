local ConfigScene = AbstractConfigScene:extend()

ConfigScene.title = "Game Settings"
ConfigScene.config_type = "gamesettings"

---@type settings_config_option[]
ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Format: {name in config, displayed name, uses slider?, options OR slider name}
	{
		config_name = "manlock",
		display_name = "Manual Locking",
		options = {"Per ruleset", "Per gamemode", "Hard Drop", "Soft Drop"},
		description = [[
Changes whether pieces lock on hard/soft drop.
Per ruleset/gamemode: Behaviour is dependent on ruleset/gamemode.
Hard Drop: Hard drops lock the piece; soft drops do not lock.
Soft Drop: Soft drops lock the piece; hard drops do not lock.
]],
		type = "options",
		default = 1,
	},
	{
		config_name = "piece_colour",
		display_name = "Piece Colours",
		options = {"Per ruleset", "Arika", "TTC"},
		description = [[
Changes the colours of each piece.
Per ruleset: Piece colours are dependent on ruleset.
Arika: Piece colours are as they are in Arika games (red I, cyan T, etc.)
TTC: Piece colours are as they are in TTC games (cyan I, purple T, etc.)]],
		type = "options",
		default = 1,
	},
	{
		config_name = "world_reverse",
		display_name = "A Button Rotation",
		options = {"Left", "Auto", "Right"},
		description = [[
Changes whether or not to swap rotation directions.
Left: Rotations are always normal.
Auto: Rotations are swapped for World-type rulesets (e.g. Ti-World).
Right: Rotations are always swapped.]],
		type = "options",
		default = 1,
	},
	{
		config_name = "spawn_positions",
		display_name = "Spawn Positions",
		options = {"Per ruleset", "In field", "Out of field"},
		description = [[
Changes the vertical position that pieces spawn at.
Per ruleset: Behaviour is dependent on ruleset.
In field: Pieces spawn as high as they can inside of the field.
Out of field: Pieces spawn as low as they can above of the field.]],
		type = "options",
		default = 1,
	},
	{
		config_name = "save_replay",
		display_name = "Save Replays",
		options = {"On", "Off"},
		description = "Whether or not to save replays.",
		type = "options",
		default = 1,
	},
	{
		config_name = "diagonal_input",
		display_name = "Movement Type",
		options = {"Standard", "4-way Abs.", "4-way LICP", "8-way LICP"},
		description = [[
Changes the behaviour of diagonal inputs.
None: No input filtering is done.
4-Way: Only one direction (up/down/left/right) can be pressed at a time.
8-Way: Diagonals are allowed, but no opposing directions (U+D or L+R).
LICP: Last Input Controlled Priority. If two directions are held at once, the first pressed direction has priority.]],
		type = "options",
		default = 1,
	},
	{
		config_name = "das_last_key",
		display_name = "DAS Last Key",
		options = {"Off", "On"},
		description = "When charging DAS during spawn delay, whether or not the direction is determined by the first key held (off) or the last key held (on).",
		type = "options",
		default = 1,
	},
	{
		config_name = "buffer_lock",
		display_name = "Buffer Drop Type",
		options = {"Off", "Hold", "Tap"},
		description = [[
Whether or not hard drops can be buffered.
Off: Hard drops cannot be buffered.
Hold: Hard drops are buffered if the button is held during piece spawn.
Tap: Hard drops are buffered if the button is tapped at any point during ARE.]],
		type = "options",
		default = 1,
	},
	{
		config_name = "synchroes_allowed",
		display_name = "Synchroes",
		options = {"Per ruleset", "On", "Off"},
		description = [[
Determines the behaviour of synchroes.
Per ruleset: Behaviour is dependent on ruleset.
On: Rotations happen before movement (synchroes enabled).
Off: Rotations happen after movement (synchroes disabled).
]],
		type = "options",
		default = 1,
	},
	{
		config_name = "next_position",
		display_name = "Next Position",
		options = {"Top", "Side"},
		description = [[
Changes the position of the next queue around the game board.
Top: The next piece is above the board; additional previews go right.
Side: The next piece is to the right of the board; additional previews go downwards.]],
		setter = function (a)
			config.side_next = a == 2
			config.gamesettings.next_position = a
		end,
		type = "options",
		default = 1,
	},
	{
		config_name = "replay_name",
		display_name = "Replay File Name",
		options = {"Full", "Date"},
		description = [[
Changes the filename format that replays are saved with.
Full: <mode_name> - <ruleset_name> - <date_time>.crp
Date: <date_time>.crp]],
		type = "options",
		default = 1,
	},
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	ConfigScene.super.new(self)

	DiscordRPC:update({
		details = "In settings",
		state = "Changing game settings",
	})
end

function ConfigScene:changeHighlight(rel)
	playSE("cursor")
	self.highlight = Mod1(self.highlight+rel, optioncount)
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

	love.graphics.setFont(font_8x11)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("GAME SETTINGS", 80, 43)

	self:renderSettings()
end

return ConfigScene
