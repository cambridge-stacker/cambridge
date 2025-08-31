local ConfigScene = AbstractConfigScene:extend()

ConfigScene.title = "Audio Settings"
ConfigScene.config_type = "audiosettings"

require 'load.save'

---@type settings_config_option[]
ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Option types: slider, options
	-- Format if type is options:	{name in config, displayed name, type, description, options}
	-- Format if otherwise:			{name in config, displayed name, type, description, min, max, increase by, string format, sound effect name, rounding type}
	{
		config_name = "master_volume",
		display_name = "Master Volume",
		type = "slider",
		description = "The overall volume of all sound effects and music.",
		default = 100,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		sound_effect_name = "cursor",
		setter = function(v)
			love.audio.setVolume(v/100)
			config.master_volume = v/100
			config.audiosettings.master_volume = v
		end,
	},
	{
		config_name = "sfx_volume",
		display_name = "SFX Volume",
		type = "slider",
		description = "The volume of sound effects (e.g. line clears, movement, menu scrolling).",
		default = 50,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		sound_effect_name = "cursor",
		setter = function(v)
			config.sfx_volume = v/100
			config.audiosettings.sfx_volume = v
		end,
	},
	{
		config_name = "bgm_volume",
		display_name = "BGM Volume",
		type = "slider",
		description = "The volume of background music (if the gamemode supports it).",
		default = 50,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		sound_effect_name = "cursor",
		setter = function(v)
			config.bgm_volume = v/100
			config.audiosettings.bgm_volume = v
		end,
	},
	{
		config_name = "sound_sources",
		display_name = "Simult. SFX sources",
		type = "slider",
		description = [[
The amount of instances of the same sound effect that may be played at once. High values may result in high memory consumption.
(There are some exceptions in which this slider has no effect: for instance, SFX added through modes or rulesets.)]],
		default = 10,
		min = 1,
		max = 30,
		increase_by = 1,
		format = "%0d",
		sound_effect_name = "cursor",
		setter = function(v)
			config.audiosettings.sound_sources = math.floor(v)
		end,
	},
	{
		config_name = "next_piece_sound",
		display_name = "Next Piece Sound",
		type = "options",
		description = "Whether or not to play next piece sounds. May be overridden by certain modes.",
		default = 1,
		options = {"On", "Off"}
	},
	{
		config_name = "starting_piece_sound",
		display_name = "Starting Piece Sound",
		type = "options",
		description = "Whether or not to play the starting piece sound. May be overridden by certain modes.",
		default = 1,
		options = {"On", "Off"}
	}
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	self.spacing = 25
	ConfigScene.super.new(self, 170)
	DiscordRPC:update({
		details = "In settings",
		state = "Changing audio settings",
	})
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

	love.graphics.setFont(font_8x11)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("AUDIO SETTINGS", 80, 43)
	local b = cursorHighlight(20, 40, 50, 30)
	love.graphics.setFont(font_3x5_2)
	love.graphics.print("(THIS WILL NOT BE STORED IN REPLAYS)", 80, 80)

	self:renderSettings()
end

function ConfigScene:onConfirm()
	if config.sound_sources ~= config.audiosettings.sound_sources then
		config.sound_sources = config.audiosettings.sound_sources
		--why is this necessary???
		generateSoundTable()
	end
end

function ConfigScene:onCancel()
	love.audio.setVolume(config.master_volume)
end

return ConfigScene
