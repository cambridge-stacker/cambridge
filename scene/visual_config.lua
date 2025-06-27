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
		description = "Shows some game info.\nWhile playing (depends on gamemode): <mode_name> - <ruleset_name>\nIf enabled or on title screen: (<target_fps>) <fps> fps - <version>",
		type = "options",
		default = 1,
	},
	{
		config_name = "smooth_movement",
		display_name = "Smooth Piece Drop",
		options = {"On", "Off"},
		type = "options",
		default = 1,
	},
	{
		config_name = "smooth_scroll",
		display_name = "Smooth Scrolling",
		options = {"On", "Off"},
		description = "Lets menus and numbers smoothly interpolate if enabled.\nThis affects the interpolateNumber function internally.",
		type = "options",
		default = 1,
	},
	{
		config_name = "cursor_highlight",
		display_name = "Cursor Highlight",
		options = {"On", "Off"},
		type = "options",
		default = 1,
	},
	{
		config_name = "cursor_type",
		display_name = "Cursor Type",
		options = {"Standard", "Tetro48's"},
		description = "Standard uses the cursor of your operating system.\nTetro48's cursor is custom-made.",
		type = "options",
		default = 1,
	},
	{
		config_name = "mode_entry",
		display_name = "Mode Entry",
		options = {"Instant", "Delayed"},
		type = "options",
		default = 1,
	},
	{
		config_name = "tagline_position",
		display_name = "Desc. Position",
		options = {"Top", "Bottom", "None"},
		type = "options",
		default = 1,
	},
	{
		config_name = "offset_obscured",
		display_name = "Queue Obscuring",
		options = {"No offset", "Offset"},
		description = "Offsets the next piece position when the current piece would obscure the next piece. This is disabled when the queue is placed to the side. This checks the piece's Y coordinate on default implementation.",
		type = "options",
		default = 1,
	},
	{
		config_name = "mode_select_type",
		display_name = "Mode Select Type",
		options = {"Default", "Oshi's idea"},
		type = "options",
		default = 1,
	},
	{
		config_name = "credits_position",
		display_name = "Credits Position",
		options = {"Right", "Center"},
		type = "options",
		default = 1,
	},
	{
		config_name = "debug_level",
		display_name = "Debug Level",
		options = {"Off", "Min", "Max"},
		description = "How much debug info to display.\nMin: Lua memory usage data\nMax: Memory usage, GPU stats data and 2 true hashes stored in replays",
		type = "options",
		default = 1,
	},
	{
		config_name = "stretch_background",
		display_name = "Stretch Background",
		options = {"Off", "On"},
		description = "Whether to fit the background image to 4:3 aspect ratio, or the aspect ratio of the game window",
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
