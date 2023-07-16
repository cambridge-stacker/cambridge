local TuningScene = Scene:extend()

TuningScene.title = "Tuning Settings"

require 'load.save'
require 'libs.simple-slider'

TuningScene.options = {
	-- Serves as a reference for the options available in the menu. Format: {name in config, name as displayed if applicable, slider name}
	{"das", "DAS", "dasSlider"},
	{"arr", "ARR", "arrSlider"},
	{"dcd", "DCD", "dcdSlider"},
}

local optioncount = #TuningScene.options

function TuningScene:new()
    DiscordRPC:update({
        details = "In settings",
        state = "Changing tuning settings",
    })
    self.highlight = 1

    self.dasSlider = newSlider(290, 225, 400, config.das, 0, 20, function(v) config.das = math.floor(v) end, {width=20, knob="circle", track="roundrect"})
	self.arrSlider = newSlider(290, 300, 400, config.arr, 0, 6, function(v) config.arr = math.floor(v) end, {width=20, knob="circle", track="roundrect"})
	self.dcdSlider = newSlider(290, 375, 400, config.dcd, 0, 6, function(v) config.dcd = math.floor(v) end, {width=20, knob="circle", track="roundrect"})
end

function TuningScene:update()
    self.dasSlider:update()
	self.arrSlider:update()
	self.dcdSlider:update()
end

function TuningScene:render()
    love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", 75, 98 + self.highlight * 75, 400, 33)

    love.graphics.setColor(1, 1, 1, 1)
    
    love.graphics.setFont(font_3x5_4)
    love.graphics.print("TUNING SETTINGS", 80, 40)
    
    love.graphics.setFont(font_3x5_2)
    love.graphics.print("These settings will only apply to modes\nthat do not use their own tunings.", 80, 90)
    
    love.graphics.setFont(font_3x5_3)
    love.graphics.print("Delayed Auto-Shift (DAS): " .. math.floor(self.dasSlider:getValue()) .. "F", 80, 175)
	love.graphics.print("Auto-Repeat Rate (ARR): " .. math.floor(self.arrSlider:getValue()) .. "F", 80, 250)
	love.graphics.print("DAS Cut Delay (DCD): " .. math.floor(self.dcdSlider:getValue()) .. "F", 80, 325)

    love.graphics.setColor(1, 1, 1, 0.75)
    self.dasSlider:draw()
	self.arrSlider:draw()
	self.dcdSlider:draw()
end

function TuningScene:onInputPress(e)
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
		playSE("cursor")
		sld = self[self.options[self.highlight][3]]
		sld.value = math.max(sld.min, math.min(sld.max, (sld:getValue() - 1) / (sld.max - sld.min)))
	elseif e.input == "right" or e.scancode == "right" then
		playSE("cursor")
		sld = self[self.options[self.highlight][3]]
		sld.value = math.max(sld.min, math.min(sld.max, (sld:getValue() + 1) / (sld.max - sld.min)))
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		loadSave()
		scene = SettingsScene()
	end
end

return TuningScene