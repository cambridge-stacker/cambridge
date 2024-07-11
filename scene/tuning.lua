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
		description = "Set it too fast, and you'd slip. Set it too slow, you'd feel sluggish.",
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
		description = "This changes how fast you move pieces, only if",
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
	{
		config_name = "menu_das",
		display_name = "DAS in menus",
		description = "Delayed Auto Shift, in menus.\nSet it too fast, and you'd slip. Set it too slow, you'd feel sluggish.",
		format = "%d frames",
		sound_effect_name = "cursor",
		min = 3,
		max = 20,
		type = "slider",
		default = 15,
	},
	{
		config_name = "menu_arr",
		display_name = "ARR in menus",
		description = "This changes how quickly you scroll.",
		format = "%d frames",
		sound_effect_name = "cursor",
		min = 1,
		max = 8,
		type = "slider",
		default = 4,
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
	love.graphics.print("These settings will only apply to modes that do not use their\nown tunings. Menu tunings are separate from gameplay tunings.", 80, 80)

	self:renderSettings()
end

function TuningScene:onConfirm()
	config.menu_das = config.tunings.menu_das
	config.menu_arr = config.tunings.menu_arr
end

return TuningScene