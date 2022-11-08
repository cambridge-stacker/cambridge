local SettingsScene = Scene:extend()

SettingsScene.title = "Settings"

local menu_screens = {
    InputConfigScene,
    GameConfigScene,
    VisualConfigScene,
	AudioConfigScene,
    TuningScene
}

local settingsidle = {
  "Tweaking some knobs",
  "Tuning up",
  "Adjusting options",
  "Setting up",
  "Setting the settings"
}

function SettingsScene:new()
    self.menu_state = 1
    DiscordRPC:update({
        details = "In settings",
        state = settingsidle[love.math.random(#settingsidle)],
        largeImageKey = "settings",
    })
end

function SettingsScene:update()
end

function SettingsScene:render()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
		backgrounds["game_config"],
		0, 0, 0,
		0.5, 0.5
    )

    love.graphics.setFont(font_3x5_4)
    love.graphics.print("SETTINGS", 80, 40)
    
	local b = CursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(font_3x5_2)
    love.graphics.print("Here, you can change some settings that change\nthe look and feel of the game.", 80, 90)

    love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 75, 118 + 50 * self.menu_state, 200, 33)

    love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(menu_screens) do
		local b = CursorHighlight(80,110 + 50 * i,200,50)
		love.graphics.setColor(1,1,b,1)
		love.graphics.printf(screen.title, 80, 120 + 50 * i, 200, "left")
    end
end

function SettingsScene:changeOption(rel)
	local len = #menu_screens
	self.menu_state = (self.menu_state + len + rel - 1) % len + 1
end

function SettingsScene:onInputPress(e)
	if e.type == "mouse" then
		if e.x > 20 and e.y > 40 and e.x < 70 and e.y < 70 then
			playSE("main_decide")
			saveConfig()
			scene = TitleScene()
		end
		if e.x > 75 and e.x < 275 then
			if e.y > 160 and e.y < 160 + #menu_screens * 50 then
				self.menu_state = math.floor((e.y - 110) / 50)
				playSE("main_decide")
				scene = menu_screens[self.menu_state]()
			end
		end
	end
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("main_decide")
		scene = menu_screens[self.menu_state]()
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete" then
		scene = TitleScene()
	end
end

return SettingsScene
