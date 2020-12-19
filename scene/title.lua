local TitleScene = Scene:extend()

local main_menu_screens = {
	ModeSelectScene,
	InputConfigScene,
	GameConfigScene,
	TuningScene,
	ExitScene,
}

local mainmenuidle = {
	"Idle",
	"On title screen",
	"On main menu screen",
	"Twiddling their thumbs",
	"Admiring the main menu's BG",
	"Waiting for spring to come",
	"Actually not playing",
	"Contemplating collecting stars",
	"Preparing to put the block!!",
	"Having a nap",
	"In menus",
	"Bottom text",
}

function TitleScene:new()
	self.main_menu_state = 1
	DiscordRPC:update({
		details = "In menus",
		state = mainmenuidle[math.random(#mainmenuidle)],
	})
end

function TitleScene:update()
end

function TitleScene:render()
	love.graphics.setFont(font_3x5_2)

	love.graphics.draw(
		backgrounds["title"],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 278 + 20 * self.main_menu_state, 160, 22)

	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(main_menu_screens) do
		love.graphics.printf(screen.title, 40, 280 + 20 * i, 120, "left")
	end

end

function TitleScene:changeOption(rel)
	local len = table.getn(main_menu_screens)
	self.main_menu_state = (self.main_menu_state + len + rel - 1) % len + 1
end

function TitleScene:onInputPress(e)
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("main_decide")
		scene = main_menu_screens[self.main_menu_state]()
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete" then
		love.event.quit()
	end
end

return TitleScene
