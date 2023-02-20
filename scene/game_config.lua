local ConfigScene = Scene:extend()

ConfigScene.title = "Game Settings"

require 'load.save'
require 'libs.simple-slider'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Format: {name in config, displayed name, uses slider?, options OR slider name}
	{"manlock", "Manual Locking", {"Per ruleset", "Per gamemode", "Harddrop", "Softdrop"}},
	{"piece_colour", "Piece Colours", {"Per ruleset", "Arika", "TTC"}},
	{"world_reverse", "A Button Rotation", {"Left", "Auto", "Right"}},
	{"spawn_positions", "Spawn Positions", {"Per ruleset", "In field", "Out of field"}},
	{"save_replay", "Save Replays", {"On", "Off"}},
	{"diagonal_input", "Movement Type", {"8-way", "4-way Abs.", "4-way LICP"}},
	{"das_last_key", "DAS Last Key", {"Off", "On"}},
	{"buffer_lock", "Buffer Drop Type", {"Off", "Hold", "Tap"}},
	{"synchroes_allowed", "Synchroes", {"Per ruleset", "On", "Off"}},
	{"replay_name", "Replay file name", {"Full", "Date"}},
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
	drawSizeIndependentImage(
		backgrounds["game_config"],
		0, 0, 0,
		640, 480
	)

	love.graphics.setFont(font_3x5_4)
	love.graphics.print("GAME SETTINGS", 80, 40)
	local b = CursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 25, 98 + self.highlight * 20, 170, 22)

	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(option[2], 40, 100 + i * 20, 150, "left")
		for j, setting in ipairs(option[3]) do
			local b = CursorHighlight(100 + 110 * j, 100 + i * 20,100,20)
			love.graphics.setColor(1, 1, b, config.gamesettings[option[1]] == j and 1 or 0.5)
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
			for j, setting in ipairs(option[3]) do
				if e.x > 100 + 110 * j and e.x < 200 + 110 * j then
					if e.y > 100 + i * 20 and e.y < 120 + i * 20 then
						self.main_menu_state = math.floor((e.y - 280) / 20)
						playSE("cursor_lr")
						config.gamesettings[option[1]] = Mod1(j, #option[3])
					end
				end
			end
		end
	end
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("mode_decide")
		saveConfig()
		scene = SettingsScene()
	elseif e.input == "up" or e.scancode == "up" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight-1, optioncount)
	elseif e.input == "down" or e.scancode == "down" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight+1, optioncount)
	elseif e.input == "left" or e.scancode == "left" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]-1, #option[3])
	elseif e.input == "right" or e.scancode == "right" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]+1, #option[3])
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		playSE("menu_cancel")
		loadSave()
		scene = SettingsScene()
	end
end

return ConfigScene
