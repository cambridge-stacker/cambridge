local ConfigScene = Scene:extend()

ConfigScene.title = "Game Settings"

require 'load.save'
require 'libs.simple-slider'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Format: {name in config, displayed name, uses slider?, options OR slider name}
	{
		config_name = "manlock",
		display_name = "Manual Locking",
		options = {"Per ruleset", "Per gamemode", "Harddrop", "Softdrop"}
	},
	{
		config_name = "piece_colour",
		display_name = "Piece Colours",
		options = {"Per ruleset", "Arika", "TTC"}
	},
	{
		config_name = "world_reverse",
		display_name = "A Button Rotation",
		options = {"Left", "Auto", "Right"}
	},
	{
		config_name = "spawn_positions",
		display_name = "Spawn Positions",
		options = {"Per ruleset", "In field", "Out of field"}
	},
	{
		config_name = "save_replay",
		display_name = "Save Replays",
		options = {"On", "Off"}
	},
	{
		config_name = "diagonal_input",
		display_name = "Movement Type",
		options = {"Standard", "4-way Abs.", "4-way LICP", "8-way LICP"}
	},
	{
		config_name = "das_last_key",
		display_name = "DAS Last Key",
		options = {"Off", "On"}
	},
	{
		config_name = "buffer_lock",
		display_name = "Buffer Drop Type",
		options = {"Off", "Hold", "Tap"}
	},
	{
		config_name = "synchroes_allowed",
		display_name = "Synchroes",
		options = {"Per ruleset", "On", "Off"}
	},
	{
		config_name = "replay_name",
		display_name = "Replay file name",
		options = {"Full", "Date"}
	},
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	-- load current config
	self.config = config.input
	self.highlight = 1

	DiscordRPC:update({
		details = "In settings",
		state = "Changing game settings",
	})
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

    love.graphics.setFont(font_8x11)
	love.graphics.print("GAME SETTINGS", 80, 43)
	local b = cursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", font_3x5_4, 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 25, 98 + self.highlight * 20, 170, 22)

	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(option.display_name, 40, 100 + i * 20, 150, "left")
		for j, setting in ipairs(option.options) do
			local b = cursorHighlight(100 + 110 * j, 100 + i * 20,100,20)
			love.graphics.setColor(1, 1, b, config.gamesettings[option.config_name] == j and 1 or 0.5)
			love.graphics.printf(setting, 100 + 110 * j, 100 + i * 20, 100, "center")
		end
	end
end

function ConfigScene:onInputPress(e)
	if e.type == "mouse" then
		if e.x > 20 and e.y > 40 and e.x < 70 and e.y < 70 then
			playSE("mode_decide")
			saveConfig()
			scene = SettingsScene()
		end
		for i, option in ipairs(ConfigScene.options) do
			for j, setting in ipairs(option.options) do
				if e.x > 100 + 110 * j and e.x < 200 + 110 * j then
					if e.y > 100 + i * 20 and e.y < 120 + i * 20 then
						self.main_menu_state = math.floor((e.y - 280) / 20)
						playSE("cursor_lr")
						config.gamesettings[option.config_name] = Mod1(j, #option.options)
					end
				end
			end
		end
	end
	if e.input == "menu_decide" then
		playSE("mode_decide")
		saveConfig()
		scene = SettingsScene()
	elseif e.input == "menu_up" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight-1, optioncount)
	elseif e.input == "menu_down" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight+1, optioncount)
	elseif e.input == "menu_left" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option.config_name] = Mod1(config.gamesettings[option.config_name]-1, #option.options)
	elseif e.input == "menu_right" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option.config_name] = Mod1(config.gamesettings[option.config_name]+1, #option.options)
	elseif e.input == "menu_back" then
		playSE("menu_cancel")
		loadSave()
		scene = SettingsScene()
	end
end

return ConfigScene
