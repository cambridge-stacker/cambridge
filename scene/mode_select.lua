local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Game Start"

current_mode = 1
current_ruleset = 1

function ModeSelectScene:new()
	self.menu_state = {
		mode = current_mode,
		ruleset = current_ruleset,
		select = "mode",
	}
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a mode",
	})
end

function ModeSelectScene:update()
end

function ModeSelectScene:render()
	love.graphics.draw(
		backgrounds[0],
		0, 0, 0,
		0.5, 0.5
	)

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

	love.graphics.draw(misc_graphics["select_mode"], 20, 40)

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
	if e.input == "menu_decide" then
		current_mode = self.menu_state.mode
		current_ruleset = self.menu_state.ruleset
		config.current_mode = current_mode
		config.current_ruleset = current_ruleset
		playSE("mode_decide")
		saveConfig()
		scene = GameScene(game_modes[self.menu_state.mode], rulesets[self.menu_state.ruleset])
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif e.input == "left" or e.input == "right" or e.scancode == "left" or e.scancode == "right" then
		self:switchSelect()
		playSE("cursor_lr")
	elseif e.input == "menu_back" then
		scene = TitleScene()
	end
end

function ModeSelectScene:changeOption(rel)
	if self.menu_state.select == "mode" then
		self:changeMode(rel)
	elseif self.menu_state.select == "ruleset" then
		self:changeRuleset(rel)
	end
end

function ModeSelectScene:switchSelect(rel)
	if self.menu_state.select == "mode" then
		self.menu_state.select = "ruleset"
	elseif self.menu_state.select == "ruleset" then
		self.menu_state.select = "mode"
	end
end

function ModeSelectScene:changeMode(rel)
	local len = table.getn(game_modes)
	self.menu_state.mode = (self.menu_state.mode + len + rel - 1) % len + 1
end

function ModeSelectScene:changeRuleset(rel)
	local len = table.getn(rulesets)
	self.menu_state.ruleset = (self.menu_state.ruleset + len + rel - 1) % len + 1
end

return ModeSelectScene
