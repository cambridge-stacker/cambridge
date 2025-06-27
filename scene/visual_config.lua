local ConfigScene = AbstractConfigScene:extend()

ConfigScene.title = "Visual Settings"
ConfigScene.config_type = "visualsettings"

---@type settings_config_option[]
ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Format: {name in config, displayed name, options, description}
	{
		config_name = "display_gamemode",
		display_name = "Display Info",
		options = {"On", "Off"},
		description = [[
Whether or not to display the extra info at the bottom of the screen.
If enabled, displays the framerate and game version in the bottom-right.
Additionally, when in-game, displays the current mode/ruleset combination.]],
		type = "options",
		default = 1,
	},
	{
		config_name = "smooth_movement",
		display_name = "Smooth Piece Drop",
		options = {"On", "Off"},
		description = "Whether or not the piece drops smoothly (on), or one cell at a time (off).",
		type = "options",
		default = 1,
	},
	{
		config_name = "smooth_scroll",
		display_name = "Smooth Scrolling",
		options = {"On", "Off"},
		description = "If enabled, menus scroll smoothly between options instead of instantly changing from one position to the next.",
		type = "options",
		default = 1,
	},
	{
		config_name = "cursor_highlight",
		display_name = "Cursor Highlight",
		options = {"On", "Off"},
		description = "If enabled, menu options are highlighted when hovered over by the mouse cursor.",
		type = "options",
		default = 1,
	},
	{
		config_name = "cursor_type",
		display_name = "Cursor Type",
		options = {"Standard", "Tetro48's"},
		description = "Whether or not to use the standard system cursor (Standard) or a custom-made one (Tetro48's).",
		type = "options",
		default = 1,
	},
	{
		config_name = "mode_entry",
		display_name = "Mode Entry",
		options = {"Instant", "Delayed"},
		description = "Whether or not modes start instantly when confirmed (Instant), or if there is a short delay between confirmation and the start of the mode (Delayed).",
		type = "options",
		default = 1,
	},
	{
		config_name = "tagline_position",
		display_name = "Desc. Position",
		options = {"Top", "Bottom", "None"},
		description = "Changes the position of the mode description on the mode selection screen. None means the description is not displayed.",
		type = "options",
		default = 1,
	},
	{
		config_name = "offset_obscured",
		display_name = "Next Queue Shift",
		options = {"Standard", "Shift"},
		description = [[
If set to Shift, the next queue will move out of the way to accomodate the active piece if it is above the board.
Has no effect if the next queue position is set to Side.
]],
		type = "options",
		default = 1,
	},
	{
		config_name = "mode_select_type",
		display_name = "Mode Select Type",
		options = {"Default", "Oshi's idea"},
		description = [[
Changes the layout of the mode select screen.
Default: As it appears in versions prior to v0.4.
Oshi's idea: Alternative layout proposed by Oshisaure.
]],
		type = "options",
		default = 1,
	},
	{
		config_name = "credits_position",
		display_name = "Credits Position",
		options = {"Right", "Center"},
		description = "Changes the position of the text during the credits.",
		type = "options",
		default = 1,
	},
	{
		config_name = "debug_level",
		display_name = "Debug Level",
		options = {"Off", "Min", "Max"},
		description = [[
Changes how much debug info is displayed.
Off: None
Min: Lua memory usage data
Max: Memory usage, GPU stats data, and 2 true hashes stored in replays]],
		type = "options",
		default = 1,
	},
	{
		config_name = "stretch_background",
		display_name = "Stretch Background",
		options = {"Off", "On"},
		description = "Whether to stretch the background image to 4:3 aspect ratio (on), or to the aspect ratio of the game window (off).",
		type = "options",
		default = 1,
	},
	{
		config_name = "background_brightness",
		display_name = "BG Brightness",
		description = "How bright the background should be in-game.",
		type = "slider",
		default = 100,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		setter = function(v)
			config.visualsettings.background_brightness = v
			config.background_brightness = v/100
		end,
	},
}

function ConfigScene:new()
	ConfigScene.super.new(self)

	DiscordRPC:update({
		details = "In settings",
		state = "Changing visual settings",
	})
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

	love.graphics.setFont(font_8x11)
	love.graphics.print("VISUAL SETTINGS", 80, 43)
	love.graphics.setFont(font_3x5_2)
	love.graphics.print("(THIS WILL NOT BE STORED IN REPLAYS)", 80, 80)

	self:renderSettings()
end

return ConfigScene
