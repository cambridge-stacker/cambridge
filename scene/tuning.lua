local TuningScene = AbstractConfigScene:extend()

TuningScene.title = "Tuning Settings"
TuningScene.config_type = "tunings"

require 'load.save'
require 'libs.simple-slider'

---@type settings_config_option[]
TuningScene.options = {
	-- Serves as a reference for the options available in the menu. Format: {name in config, name as displayed if applicable, slider name}
	{
		config_name = "das",
		display_name = "Delayed Auto Shift (DAS)",
		format = "%d frames",
		sound_effect_name = "cursor",
		min = 0,
		max = 20,
		type = "slider",
		default = 10,
		setter = function(v)
			config.das = math.floor(v)
			config.tunings.das = math.floor(v)
		end
	},
	{
		config_name = "arr",
		display_name = "Auto Repeat Rate (ARR)",
		format = "%d frames",
		sound_effect_name = "cursor",
		min = 0,
		max = 6,
		type = "slider",
		default = 2,
		setter = function(v)
			config.arr = math.floor(v)
			config.tunings.arr = math.floor(v)
		end
	},
	{
		config_name = "dcd",
		display_name = "DAS Cut Delay (DCD)",
		format = "%d frames",
		sound_effect_name = "cursor",
		min = 0,
		max = 6,
		type = "slider",
		default = 0,
		setter = function(v)
			config.dcd = math.floor(v)
			config.tunings.dcd = math.floor(v)
		end
	},
}

function TuningScene:new()
	self.spacing = 30
	self.super.new(self, 200)
	DiscordRPC:update({
		details = "In settings",
		state = "Changing tuning settings",
	})
end

function TuningScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_8x11)
	love.graphics.print("TUNING SETTINGS", 80, 43)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print("These settings will only apply to modes\nthat do not use their own tunings.", 80, 80)

	self:renderSettings()
end

return TuningScene