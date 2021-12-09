local TitleScene = Scene:extend()

TitleScene.title = "Title"
TitleScene.restart_message = false

local main_menu_screens = {
	ModeSelectScene,
	ReplaySelectScene,
	SettingsScene,
	CreditsScene,
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
	"Trying to see all the funny rpc messages (maybe)",
	"Not not not playing",
	"AFK",
	"Preparing for their next game",
	"Who are those people on that boat?",
	"Welcome to Cambridge!",
	"who even reads these",
	"Made with love in LOVE!",
	"This is probably the longest RPC string out of every possible RPC string that can be displayed."
}

function TitleScene:new()
	self.main_menu_state = 1
	self.frames = 0
	self.snow_bg_opacity = 0
	self.y_offset = 0
	self.text = ""
	self.text_flag = false
	DiscordRPC:update({
		details = "In menus",
		state = mainmenuidle[love.math.random(#mainmenuidle)],
		largeImageKey = "icon2",
		largeImageText = version
	})
end

function TitleScene:update()
	if self.text_flag then
		self.frames = self.frames + 1
		self.snow_bg_opacity = self.snow_bg_opacity + 0.01
	end
	if self.frames < 125 then self.y_offset = self.frames
	elseif self.frames < 185 then self.y_offset = 125
	else self.y_offset = 310 - self.frames end
end

function TitleScene:render()
	love.graphics.setFont(font_3x5_4)
	love.graphics.setColor(1, 1, 1, 1 - self.snow_bg_opacity)
	love.graphics.draw(
		backgrounds["title"], -- title_night
		0, 0, 0,
		0.5, 0.5
	)
	--[[
	love.graphics.draw(
		misc_graphics["icon"],
		460, 170, 0,
		2, 2
	)
	]]
	--love.graphics.printf("Thanks for 1 year!", 430, 280, 160, "center")

	love.graphics.setFont(font_3x5_2)
	love.graphics.setColor(1, 1, 1, self.snow_bg_opacity)
	love.graphics.draw(
		backgrounds["snow"],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.draw(
		misc_graphics["santa"],
		400, -205 + self.y_offset,
		0, 0.5, 0.5
	)
	love.graphics.print("Happy Holidays!", 320, -100 + self.y_offset)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.restart_message and "Restart Cambridge..." or "", 0, 0)

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
	else
		self.text = self.text .. (e.scancode or "")
		if self.text == "ffffff" then
			self.text_flag = true
			DiscordRPC:update({
				largeImageKey = "snow"
			})
		end
	end
end

return TitleScene
