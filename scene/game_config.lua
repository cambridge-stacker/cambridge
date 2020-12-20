local ConfigScene = Scene:extend()

ConfigScene.title = "Game Settings"

require 'load.save'
require 'libs.simple-slider'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	{"manlock",			"Manual Locking",{"Per ruleset","Per gamemode","Harddrop", "Softdrop"}},
	{"piece_colour", "Piece Colours", {"Per ruleset","Arika"			 ,"TTC"}},
	{"world_reverse","A Button Rotation", {"Left"				 ,"Auto"		,"Right"}},
	{"display_gamemode", "Display Gamemode", {"On", "Off"}},
	{"das_last_key", "DAS Switch", {"Default", "Instant"}},
	{"smooth_movement", "Smooth Piece Drop", {"On", "Off"}},
	{"synchroes_allowed", "Synchroes", {"Per ruleset", "On", "Off"}},
	{"diagonal_input", "Diagonal Input", {"On", "Off"}}
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	-- load current config
	self.config = config.input
	self.highlight = 1
	
	DiscordRPC:update({
		details = "In menus",
		state = "Changing game settings",
	})

	self.sfxSlider = newSlider(165, 375, 225, config.sfx_volume * 100, 0, 100, function(v) config.sfx_volume = v / 100 end, {width=20})
	self.bgmSlider = newSlider(465, 375, 225, config.bgm_volume * 100, 0, 100, function(v) config.bgm_volume = v / 100 end, {width=20})
end

function ConfigScene:update()
	config["das_last_key"] = config.gamesettings.das_last_key == 2
	self.sfxSlider:update()
	self.bgmSlider:update()
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds["game_config"],
		0, 0, 0,
		0.5, 0.5
	)
	
	love.graphics.setFont(font_3x5_3)
	love.graphics.print("SFX Volume: " .. math.floor(self.sfxSlider:getValue()) .. "%", 70, 325)
	love.graphics.print("BGM Volume: " .. math.floor(self.bgmSlider:getValue()) .. "%", 370, 325)

	love.graphics.setFont(font_3x5_4)
	love.graphics.print("GAME SETTINGS", 80, 40)
	
	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 98 + self.highlight * 20, 170, 22)
	
	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(option[2], 40, 100 + i * 20, 150, "left")
		for j, setting in ipairs(option[3]) do
			love.graphics.setColor(1, 1, 1, config.gamesettings[option[1]] == j and 1 or 0.5)
			love.graphics.printf(setting, 100 + 110 * j, 100 + i * 20, 100, "center")
		end
	end

	love.graphics.setColor(1, 1, 1, 0.75)
	self.sfxSlider:draw()
	self.bgmSlider:draw()
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
		config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]-1, #option[3])
	elseif e.input == "right" or e.scancode == "right" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]+1, #option[3])
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		loadSave()
		scene = SettingsScene()
	end
end

return ConfigScene
