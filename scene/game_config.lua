local ConfigScene = Scene:extend()

ConfigScene.title = "Game Settings"

require 'load.save'

ConfigScene.options = {
    -- this serves as reference to what the options' values mean i guess?
    {"manlock",      "Manual locking", {"Per gamemode","Per ruleset","Harddrop", "Softdrop"}},
    {"piece_colour", "Piece Colours",  {"Per ruleset", "Arika",      "TTC"}},
    {"world_reverse", "World Reverse", {"No",          "Yes"}},
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	-- load current config
	self.config = config.input
	self.highlight = 1

	presence.details = "In menus"
	presence.state = "Changing game config"
	discordRPC.updatePresence(presence)
end

function ConfigScene:update()
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
end

function ConfigScene:onKeyPress(e)
	if e.scancode == "return" and e.isRepeat == false then
		playSE("mode_decide")
		saveConfig()
		scene = TitleScene()
	elseif (e.scancode == config.input["up"] or e.scancode == "up") and e.isRepeat == false then
		playSE("cursor")
		self.highlight = Mod1(self.highlight-1, optioncount)
	elseif (e.scancode == config.input["down"] or e.scancode == "down") and e.isRepeat == false then
		playSE("cursor")
		self.highlight = Mod1(self.highlight+1, optioncount)
	elseif (e.scancode == config.input["left"] or e.scancode == "left") and e.isRepeat == false then
		playSE("cursor_lr")
        local option = ConfigScene.options[self.highlight]
        config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]-1, #option[3])
	elseif (e.scancode == config.input["right"] or e.scancode == "right") and e.isRepeat == false then
		playSE("cursor_lr")
        local option = ConfigScene.options[self.highlight]
        config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]+1, #option[3])
    elseif e.scancode == "escape" then
        loadSave()
        scene = TitleScene()
	end
end

return ConfigScene
