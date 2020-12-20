local TuningScene = Scene:extend()

TuningScene.title = "Tuning Settings"

require 'load.save'
require 'libs.simple-slider'

function TuningScene:new()
    DiscordRPC:update({
        details = "In menus",
        state = "Changing tuning settings",
    })

    self.dasSlider = newSlider(290, 225, 400, config.das, 0, 20, function(v) config.das = math.floor(v) end, {width=20})
    self.arrSlider = newSlider(290, 325, 400, config.arr, 0, 6, function(v) config.arr = math.floor(v) end, {width=20})
end

function TuningScene:update()
    self.dasSlider:update()
    self.arrSlider:update()
end

function TuningScene:render()
    love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds["game_config"],
		0, 0, 0,
		0.5, 0.5
    )
    
    love.graphics.setFont(font_3x5_4)
    love.graphics.print("TUNING SETTINGS", 80, 40)
    
    love.graphics.setFont(font_3x5_2)
    love.graphics.print("These settings will only apply to modes\nthat do not use their own tunings.", 80, 90)
    
    love.graphics.setFont(font_3x5_3)
    love.graphics.print("Delayed Auto-Shift (DAS): " .. math.floor(self.dasSlider:getValue()) .. "F", 80, 175)
    love.graphics.print("Auto-Repeat Rate (ARR): " .. math.floor(self.arrSlider:getValue()) .. "F", 80, 275)

    love.graphics.setColor(1, 1, 1, 0.75)
    self.dasSlider:draw()
    self.arrSlider:draw()
end

function TuningScene:onInputPress(e)
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("mode_decide")
		saveConfig()
		scene = SettingsScene()
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		loadSave()
		scene = SettingsScene()
	end
end

return TuningScene