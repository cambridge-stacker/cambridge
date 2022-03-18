local ConfigScene = Scene:extend()

ConfigScene.title = "Visual Settings"

require 'load.save'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Format: {name in config, displayed name, options}
	{"display_gamemode", "Debug Info", {"On", "Off"}},
	{"smooth_movement", "Smooth Piece Drop", {"On", "Off"}},
	{"smooth_scroll", "Smooth Scrolling", {"On", "Off"}},
	{"cursor_highlight", "Cursor Highlight", {"On", "Off"}},
	{"cursor_type", "Cursor Type", {"Standard", "Tetro48's"}},
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	-- load current config
	self.config = config.input
	self.highlight = 1

	DiscordRPC:update({
		details = "In settings",
		state = "Changing visual settings",
	})
end

function ConfigScene:update()
	local x, y = getScaledPos(love.mouse.getPosition())
	--#region Mouse
	if not love.mouse.isDown(1) or left_clicked_before then return end
	for i, option in ipairs(ConfigScene.options) do
		for j, setting in ipairs(option[3]) do
			if x > 100 + 110 * j and x < 200 + 110 * j then
				if y > 100 + i * 20 and y < 120 + i * 20 then
					self.main_menu_state = math.floor((y - 280) / 20)
					playSE("cursor_lr")
					config.visualsettings[option[1]] = Mod1(j, #option[3])
				end
			end
			-- local option = ConfigScene.options[self.highlight]
		end
	end
	--#endregion
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds["game_config"],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.setFont(font_3x5_4)
	love.graphics.print("VISUAL SETTINGS", 80, 40)
	love.graphics.setFont(font_3x5_2)
	love.graphics.print("(THIS WILL NOT BE STORED IN REPLAYS)", 80, 80)
	-- love.graphics.setColor(1, 1, 1, 0.5)
	-- love.graphics.rectangle("fill", 580, 40, 60, 35)
	-- love.graphics.setColor(1, 1, 1, 1)
	-- love.graphics.setFont(font_3x5_3)
	-- love.graphics.printf("SAVE", 580, 40, 60, "center")
	-- love.graphics.setFont(font_3x5)
	-- love.graphics.printf("(MOUSE ONLY)", 580, 62, 60, "center")

	--Lazy check to see if we're on the SFX or BGM slider. Probably will need to be rewritten if more options get added.
	love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", 25, 98 + self.highlight * 20, 170, 22)

	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(option[2], 40, 100 + i * 20, 150, "left")
        for j, setting in ipairs(option[3]) do
            local b = CursorHighlight(100 + 110 * j, 100 + i * 20,100,20)
            love.graphics.setColor(1, 1, b, config.visualsettings[option[1]] == j and 1 or 0.5)
            love.graphics.printf(setting, 100 + 110 * j, 100 + i * 20, 100, "center")
        end
	end

	love.graphics.setColor(1, 1, 1, 0.75)
end

function ConfigScene:onInputPress(e)
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
        config.visualsettings[option[1]] = Mod1(config.visualsettings[option[1]]-1, #option[3])
	elseif e.input == "right" or e.scancode == "right" then
        playSE("cursor_lr")
        local option = ConfigScene.options[self.highlight]
        config.visualsettings[option[1]] = Mod1(config.visualsettings[option[1]]+1, #option[3])
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		loadSave()
		scene = SettingsScene()
	end
end

return ConfigScene
