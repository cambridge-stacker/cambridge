local SettingsScene = Scene:extend()

SettingsScene.title = "Settings"

local menu_screens = {
    InputConfigScene,
    GameConfigScene,
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

function SettingsScene:update() end

function SettingsScene:render()
    love.graphics.setColor(1, 1, 1, 1)
    drawBackground("options_game")

    love.graphics.setFont(font_3x5_4)
    love.graphics.print("SETTINGS", 80, 40)

    love.graphics.setFont(font_3x5_2)
    love.graphics.print("Here, you can change some settings that change\nthe look and feel of the game.", 80, 90)

    love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 75, 118 + 50 * self.menu_state, 200, 33)

    love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(menu_screens) do
		love.graphics.printf(screen.title, 80, 120 + 50 * i, 200, "left")
    end
end

function SettingsScene:changeOption(rel)
	local len = table.getn(menu_screens)
	self.menu_state = (self.menu_state + len + rel - 1) % len + 1
end

function SettingsScene:onInputPress(e)
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
