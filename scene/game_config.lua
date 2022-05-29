local ConfigScene = Scene:extend()

ConfigScene.title = "Game Settings"

require 'load.save'
require 'libs.simple-slider'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Format: {name in config, displayed name, uses slider?, options OR slider name}
	{"manlock", "Manual Locking", false, {"Per ruleset", "Per gamemode", "Harddrop", "Softdrop"}},
	{"piece_colour", "Piece Colours", false, {"Per ruleset", "Arika", "TTC"}},
	{"world_reverse", "A Button Rotation", false, {"Left", "Auto", "Right"}},
	{"spawn_positions", "Spawn Positions", false, {"Per ruleset", "In field", "Out of field"}},
	{"save_replay", "Save Replays", false, {"On", "Off"}},
	{"diagonal_input", "Diagonal Input", false, {"On", "Off"}},
	{"das_last_key", "DAS Last Key", false, {"Off", "On"}},
	{"buffer_lock", "Buffer Drop Type", false, {"Off", "Hold", "Tap"}},
	{"synchroes_allowed", "Synchroes", false, {"Per ruleset", "On", "Off"}},
	{"replay_name", "Replay file name", false, {"Full", "Date"}},
	{"sfx_volume", "SFX", true, "sfxSlider"},
	{"bgm_volume", "BGM", true, "bgmSlider"},
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

	self.sfxSlider = newSlider(165, 420, 225, config.sfx_volume * 100, 0, 100, function(v) config.sfx_volume = v / 100 end, {width=20, knob="circle", track="roundrect"})
	self.bgmSlider = newSlider(465, 420, 225, config.bgm_volume * 100, 0, 100, function(v) config.bgm_volume = v / 100 end, {width=20, knob="circle", track="roundrect"})
end

function ConfigScene:update()
	local x, y = getScaledPos(love.mouse.getPosition())
	self.sfxSlider:update(x,y)
	self.bgmSlider:update(x,y)
	--#region Mouse
	if not love.mouse.isDown(1) or left_clicked_before then return end
	if x > 20 and y > 40 and x < 70 and y < 70 then
		playSE("mode_decide")
		saveConfig()
		scene = SettingsScene()
	end
	for i, option in ipairs(ConfigScene.options) do
		if not option[3] then
		for j, setting in ipairs(option[4]) do
			if x > 100 + 110 * j and x < 200 + 110 * j then
				if y > 100 + i * 20 and y < 120 + i * 20 then
					self.main_menu_state = math.floor((y - 280) / 20)
					playSE("cursor_lr")
					config.gamesettings[option[1]] = Mod1(j, #option[4])
				end
			end
			-- local option = ConfigScene.options[self.highlight]
		end end
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
	love.graphics.print("GAME SETTINGS", 80, 40)
	local b = CursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

	--Lazy check to see if we're on the SFX or BGM slider. Probably will need to be rewritten if more options get added.
	love.graphics.setColor(1, 1, 1, 0.5)
	if not ConfigScene.options[self.highlight][3] then
		love.graphics.rectangle("fill", 25, 98 + self.highlight * 20, 170, 22)
	else
		love.graphics.rectangle("fill", 65 + (1+self.highlight-#self.options) * 300, 362, 215, 33)
	end

	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
		if not option[3] then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf(option[2], 40, 100 + i * 20, 150, "left")
			for j, setting in ipairs(option[4]) do
				local b = CursorHighlight(100 + 110 * j, 100 + i * 20,100,20)
				love.graphics.setColor(1, 1, b, config.gamesettings[option[1]] == j and 1 or 0.5)
				love.graphics.printf(setting, 100 + 110 * j, 100 + i * 20, 100, "center")
			end
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	love.graphics.print("SFX Volume: " .. math.floor(self.sfxSlider:getValue()) .. "%", 75, 365)
	love.graphics.print("BGM Volume: " .. math.floor(self.bgmSlider:getValue()) .. "%", 375, 365)

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
		if not self.options[self.highlight][3] then
			playSE("cursor_lr")
			local option = ConfigScene.options[self.highlight]
			config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]-1, #option[4])
		else
			local sld = self[self.options[self.highlight][4]]
			sld.value = math.max(sld.min, math.min(sld.max, (sld:getValue() - 5) / (sld.max - sld.min)))
			sld:update()
			playSE("cursor")
		end
	elseif e.input == "right" or e.scancode == "right" then
		if not self.options[self.highlight][3] then
			playSE("cursor_lr")
			local option = ConfigScene.options[self.highlight]
			config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]+1, #option[4])
		else
			local sld = self[self.options[self.highlight][4]]
			sld.value = math.max(sld.min, math.min(sld.max, (sld:getValue() + 5) / (sld.max - sld.min)))
			sld:update()
			playSE("cursor")
		end
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		loadSave()
		scene = SettingsScene()
	end
end

return ConfigScene
