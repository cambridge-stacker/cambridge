local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Game Start"

current_mode = 1
current_ruleset = 1

function ModeSelectScene:new()
	-- reload custom modules
	initModules()
	if table.getn(game_modes) == 0 or table.getn(rulesets) == 0 then
		self.display_warning = true
		current_mode = 1
		current_ruleset = 1
	else
		self.display_warning = false
		if current_mode > table.getn(game_modes) then
			current_mode = 1
		end
		if current_ruleset > table.getn(rulesets) then
			current_ruleset = 1
		end
	end

	self.menu_state = {
		mode = current_mode,
		ruleset = current_ruleset,
		select = "mode",
	}
	self.secret_inputs = {
		rotate_left = false,
		rotate_left2 = false,
		rotate_right = false,
		rotate_right2 = false,
		rotate_180 = false,
		hold = false,
	}
	self.das = 0
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a mode",
		largeImageKey = "ingame-000"
	})
end

function ModeSelectScene:update()
	switchBGM(nil) -- experimental

	if self.das_up or self.das_down then
		self.das = self.das + 1
	else
		self.das = 0
	end

	if self.das >= 15 then
		self:changeOption(self.das_up and -1 or 1)
		self.das = self.das - 4
	end

	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a " .. self.menu_state.select,
		largeImageKey = "ingame-000"
	})
end

function ModeSelectScene:render()
	love.graphics.draw(
		backgrounds[0],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.draw(misc_graphics["select_mode"], 20, 40)

	if self.display_warning then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"You have no modes or rulesets.",
			80, 200, 480, "center"
		)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(
			"Come back to this menu after getting more modes or rulesets. " ..
			"Press any button to return to the main menu.",
			80, 250, 480, "center"
		)
		return
	end

	if self.menu_state.select == "mode" then
		love.graphics.setColor(1, 1, 1, 0.5)
	elseif self.menu_state.select == "ruleset" then
		love.graphics.setColor(1, 1, 1, 0.25)
	end
	love.graphics.rectangle("fill", 20, 258, 240, 22)

	if self.menu_state.select == "mode" then
		love.graphics.setColor(1, 1, 1, 0.25)
	elseif self.menu_state.select == "ruleset" then
		love.graphics.setColor(1, 1, 1, 0.5)
	end
	love.graphics.rectangle("fill", 340, 258, 200, 22)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	for idx, mode in pairs(game_modes) do
		if(idx >= self.menu_state.mode-9 and idx <= self.menu_state.mode+9) then
			love.graphics.printf(mode.name, 40, (260 - 20*(self.menu_state.mode)) + 20 * idx, 200, "left")
		end
	end
	for idx, ruleset in pairs(rulesets) do
		if(idx >= self.menu_state.ruleset-9 and idx <= self.menu_state.ruleset+9) then
			love.graphics.printf(ruleset.name, 360, (260 - 20*(self.menu_state.ruleset)) + 20 * idx, 160, "left")
		end
	end
end

function ModeSelectScene:onInputPress(e)
	if self.display_warning and e.input then
		scene = TitleScene()
	elseif e.type == "wheel" then
		if e.x % 2 == 1 then
			self:switchSelect()
		end
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif e.input == "menu_decide" or e.scancode == "return" then
		current_mode = self.menu_state.mode
		current_ruleset = self.menu_state.ruleset
		config.current_mode = current_mode
		config.current_ruleset = current_ruleset
		playSE("mode_decide")
		saveConfig()
		scene = GameScene(
			game_modes[self.menu_state.mode],
			rulesets[self.menu_state.ruleset],
			self.secret_inputs
		)
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		self.das_up = true
		self.das_down = nil
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		self.das_down = true
		self.das_up = nil
	elseif e.input == "left" or e.input == "right" or e.scancode == "left" or e.scancode == "right" then
		self:switchSelect()
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		scene = TitleScene()
	elseif e.input then
		self.secret_inputs[e.input] = true
	end
end

function ModeSelectScene:onInputRelease(e)
	if e.input == "hold" or (e.input and string.sub(e.input, 1, 7) == "rotate_") then
		self.secret_inputs[e.input] = false
	elseif e.input == "up" or e.scancode == "up" then
		self.das_up = nil
	elseif e.input == "down" or e.scancode == "down" then
		self.das_down = nil
	end
end

function ModeSelectScene:changeOption(rel)
	if self.menu_state.select == "mode" then
		self:changeMode(rel)
	elseif self.menu_state.select == "ruleset" then
		self:changeRuleset(rel)
	end
	playSE("cursor")
end

function ModeSelectScene:switchSelect()
	if self.menu_state.select == "mode" then
		self.menu_state.select = "ruleset"
	elseif self.menu_state.select == "ruleset" then
		self.menu_state.select = "mode"
	end
	playSE("cursor_lr")
end

function ModeSelectScene:changeMode(rel)
	local len = table.getn(game_modes)
	self.menu_state.mode = Mod1(self.menu_state.mode + rel, len)
end

function ModeSelectScene:changeRuleset(rel)
	local len = table.getn(rulesets)
	self.menu_state.ruleset = Mod1(self.menu_state.ruleset + rel, len)
end

return ModeSelectScene
