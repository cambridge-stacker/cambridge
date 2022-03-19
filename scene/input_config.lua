local ConfigScene = Scene:extend()

ConfigScene.title = "Input Config"

local menu_screens = {
    KeyConfigScene,
    StickConfigScene
}

function ConfigScene:new()
    self.menu_state = 1
    DiscordRPC:update({
        details = "In settings",
        state = "Changing input config",
        largeImageKey = "settings-input"
    })
end

function ConfigScene:update()
	if not love.mouse.isDown(1) or left_clicked_before then return end
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if not love.mouse.isDown(1) or left_clicked_before then return end
	if mouse_x > 20 and mouse_y > 40 and mouse_x < 70 and mouse_y < 70 then
		playSE("main_decide")
		saveConfig()
		scene = SettingsScene()
	end
    if mouse_x > 75 and mouse_x < 275 then
        if mouse_y > 170 and mouse_y < 270 then
            self.menu_state = math.floor((mouse_y - 120) / 50)
            playSE("main_decide")
            scene = menu_screens[self.menu_state]()
        end
    end
end

function ConfigScene:render()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
		backgrounds["input_config"],
		0, 0, 0,
		0.5, 0.5
    )

    love.graphics.setFont(font_3x5_4)
    love.graphics.print("INPUT CONFIG", 80, 40)
	
	local b = CursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(font_3x5_2)
    love.graphics.print("Which controls do you want to configure?", 80, 90)

    love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 75, 118 + 50 * self.menu_state, 200, 33)

    love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(menu_screens) do
		local b = CursorHighlight(80,120 + 50 * i,200,50)
		love.graphics.setColor(1,1,b,1)
		love.graphics.printf(screen.title, 80, 120 + 50 * i, 200, "left")
    end
end

function ConfigScene:changeOption(rel)
	local len = table.getn(menu_screens)
	self.menu_state = (self.menu_state + len + rel - 1) % len + 1
end

function ConfigScene:onInputPress(e)
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("main_decide")
		scene = menu_screens[self.menu_state]()
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif config.input and (
		e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete"
	) then
		scene = SettingsScene()
	end
end

return ConfigScene
