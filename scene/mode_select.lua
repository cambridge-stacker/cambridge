local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Game Start"

current_mode = 1
current_ruleset = 1

function ModeSelectScene:new()
	-- reload custom modules
	initModules(true)
	self.game_mode_folder = game_modes
	self.game_mode_selections = {game_modes}
	self.ruleset_folder = rulesets
	self.ruleset_folder_selections = {rulesets}
	if #game_modes == 0 or #rulesets == 0 then
		self.display_warning = true
		current_mode = 1
		current_ruleset = 1
	else
		self.display_warning = false
		if current_mode > #game_modes then
			current_mode = 1
		end
		if current_ruleset > #rulesets then
			current_ruleset = 1
		end
	end

	self.menu_state = {
		mode = current_mode,
		ruleset = current_ruleset,
		select = "mode",
	}
	self.secret_inputs = {}
	self.das = 0
	-- It's not exactly self-descriptive.
	self.menu_mode_height = 20
	-- It's not exactly self-descriptive.
	self.menu_ruleset_height = 20
	self.auto_menu_offset = 0
	self.auto_menu_state = "mode"
	self.start_frames, self.starting = 0, false
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a mode",
		largeImageKey = "ingame-000"
	})
end

local menu_DAS_hold = {["up"] = 0, ["down"] = 0, ["left"] = 0, ["right"] = 0}
local menu_DAS_frames = {["up"] = 0, ["down"] = 0, ["left"] = 0, ["right"] = 0}
local menu_ARR = {[0] = 8, 6, 5, 4, 3, 2, 2, 2, 1}
function ModeSelectScene:menuDASInput(input, input_string, das, arr_mul)
	local result = false
	arr_mul = arr_mul or 1
	local arr = self:getMenuARR(menu_DAS_hold[input_string]) * arr_mul
	if input then
		menu_DAS_frames[input_string] = menu_DAS_frames[input_string] + 1
		menu_DAS_hold[input_string] = menu_DAS_hold[input_string] + 1
		if menu_DAS_frames[input_string] > das or menu_DAS_frames[input_string] == 1 then
			menu_DAS_frames[input_string] = math.max(1, menu_DAS_frames[input_string] - arr)
			result = true
		end
	else
		menu_DAS_frames[input_string] = 0
		menu_DAS_hold[input_string] = 0
	end
	return result
end

function ModeSelectScene:getMenuARR(number)
	if number < 60 then
		if (number / 30) > #menu_ARR then
			return #menu_ARR
		else
			return menu_ARR[math.floor(number / 30)]
		end
	end
	return math.ceil(32 / math.sqrt(number))
end

function ModeSelectScene:update()
	switchBGM(nil) -- experimental

	if self.starting then
		self.start_frames = self.start_frames + 1
		if self.start_frames > 60 or config.visualsettings.mode_entry == 1 then
			self:startMode()
		end
		return
	end
	if self.das_up or self.das_down then
		self.das = self.das + 1
	else
		self.das = 0
	end
	if self.auto_menu_offset ~= 0 then
		self:changeOption(self.auto_menu_offset < 0 and -1 or 1)
		if self.auto_menu_offset > 0 then self.auto_menu_offset = self.auto_menu_offset - 1 end
		if self.auto_menu_offset < 0 then self.auto_menu_offset = self.auto_menu_offset + 1 end
	end
	if self:menuDASInput(self.das_up, "up", 12) then
		self:changeOption(-1)
	end
	if self:menuDASInput(self.das_down, "down", 12) then
		self:changeOption(1)
	end

	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a " .. self.menu_state.select,
		largeImageKey = "ingame-000"
	})
end

function ModeSelectScene:render()
	drawBackground(0)

	love.graphics.setFont(font_3x5_4)
	local b = cursorHighlight(0, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 0, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	love.graphics.draw(misc_graphics["select_mode"], 50, 44)

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

	local mode_selected, ruleset_selected = self.menu_state.mode, self.menu_state.ruleset

	local tagline_position = config.visualsettings.tagline_position

	local tagline_y = tagline_position == 1 and 5 or 435
	local render_list_size = tagline_position == 2 and 18 or 20

	if tagline_position ~= 3
	and self.game_mode_folder[self.menu_state.mode]
	and not self.game_mode_folder[self.menu_state.mode].is_directory then
		love.graphics.printf(
			"Tagline: "..(self.game_mode_folder[mode_selected].tagline or "Missing."),
			 20, tagline_y, 600, "left")
	end

	if self.menu_state.select == "mode" then
		love.graphics.setColor(1, 1, 1, 0.5)
	elseif self.menu_state.select == "ruleset" then
		love.graphics.setColor(1, 1, 1, 0.25)
	end

	self.menu_mode_height = interpolateNumber(self.menu_mode_height / 20, mode_selected) * 20
	self.menu_ruleset_height = interpolateNumber(self.menu_ruleset_height / 20, ruleset_selected) * 20


	love.graphics.rectangle("fill", 20, 258 + (mode_selected * 20) - self.menu_mode_height, 240, 22)

	if self.menu_state.select == "mode" then
		love.graphics.setColor(1, 1, 1, 0.25)
	elseif self.menu_state.select == "ruleset" then
		love.graphics.setColor(1, 1, 1, 0.5)
	end

	love.graphics.rectangle("fill", 340, 258 + (ruleset_selected * 20) - self.menu_ruleset_height, 200, 22)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	local mode_path_name = ""
	if #self.game_mode_selections > 1 then
		for index, value in ipairs(self.game_mode_selections) do
			mode_path_name = mode_path_name..(value.name or "modes").." > "
		end
		love.graphics.printf(
			"Path: "..mode_path_name:sub(1, -3),
			 40, 220 - self.menu_mode_height, 200, "left")
	end
	local ruleset_path_name = ""
	if #self.ruleset_folder_selections > 1 then
		for index, value in ipairs(self.ruleset_folder_selections) do
			ruleset_path_name = ruleset_path_name..(value.name or "rulesets").." > "
		end
		love.graphics.printf(
			"Path: "..ruleset_path_name:sub(1, -3),
			 360, 220 - self.menu_ruleset_height, 200, "left")
	end
	local fade_offset = tagline_position == 2 and -20 or 0
	if #self.game_mode_folder == 0 then
		love.graphics.printf("No modes in this folder!", 40, 280 - self.menu_mode_height, 260, "left")
	end
	if #self.ruleset_folder == 0 then
		love.graphics.printf("Empty rulesets folder!", 360, 280 - self.menu_ruleset_height, 260, "left")
	end
	for idx, mode in ipairs(self.game_mode_folder) do
		if(idx >= self.menu_mode_height / 20 - 10 and
		   idx <= self.menu_mode_height / 20 + 10) then
			local b = 1
			if mode.is_directory then
				b = 0.4
			end
			local highlight = cursorHighlight(
				0,
				(260 - self.menu_mode_height) + 20 * idx,
				320,
				20)
			if highlight < 0.5 then
				b = highlight
			end
			if idx == self.menu_state.mode and self.starting then
				b = self.start_frames % 10 > 4 and 0 or 1
			end
			love.graphics.setColor(1,1,b,fadeoutAtEdges(
				-self.menu_mode_height + 20 * idx - fade_offset,
				render_list_size * 10 - 20,
				20))
			love.graphics.printf(mode.name,
			40, (260 - self.menu_mode_height) + 20 * idx, 200, "left")
		end
	end
	for idx, ruleset in ipairs(self.ruleset_folder) do
		if(idx >= self.menu_ruleset_height / 20 - 10 and
		   idx <= self.menu_ruleset_height / 20 + 10) then
			local b = 1
			if ruleset.is_directory then
				b = 0.4
			end
			local highlight = cursorHighlight(
				320,
				(260 - self.menu_ruleset_height) + 20 * idx,
				320,
				20)
			if highlight < 0.5 then
				b = highlight
			end
			love.graphics.setColor(1, 1, b, fadeoutAtEdges(
				-self.menu_ruleset_height + 20 * idx - fade_offset,
				render_list_size * 10 - 20,
				20)
			)
			love.graphics.printf(ruleset.name,
			360, (260 - self.menu_ruleset_height) + 20 * idx, 160, "left")
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end

function ModeSelectScene:indirectStartMode()
	if self.game_mode_folder[self.menu_state.mode].is_directory then
		playSE("main_decide")
		self:menuGoForward("mode")
		self.menu_state.mode = 1
		return
	end
	if self.ruleset_folder[self.menu_state.ruleset].is_directory then
		playSE("main_decide")
		self:menuGoForward("ruleset")
		self.menu_state.ruleset = 1
		return
	end
	playSE("mode_decide")
	if config.visualsettings.mode_entry == 1 then
		self:startMode()
	else
		self.starting = true
	end
end
--Direct way of starting a mode.
function ModeSelectScene:startMode()
	if #self.game_mode_selections == 1 then
		current_mode = self.menu_state.mode
	end
	if #self.ruleset_folder_selections == 1 then
		current_ruleset = self.menu_state.ruleset
	end
	config.current_mode = current_mode
	config.current_ruleset = current_ruleset
	saveConfig()
	scene = GameScene(
		self.game_mode_folder[self.menu_state.mode],
		self.ruleset_folder[self.menu_state.ruleset],
		self.secret_inputs
	)
end

function ModeSelectScene:menuGoBack(type)
	if type == "mode" and #self.game_mode_selections > 1 then
		self.game_mode_selections[#self.game_mode_selections] = nil
		self.game_mode_folder = self.game_mode_selections[#self.game_mode_selections]
	elseif #self.ruleset_folder_selections > 1 then
		self.ruleset_folder_selections[#self.ruleset_folder_selections] = nil
		self.ruleset_folder = self.ruleset_folder_selections[#self.ruleset_folder_selections]
	end
end

function ModeSelectScene:menuGoForward(type)
	if type == "mode" then
		self.game_mode_folder = self.game_mode_folder[self.menu_state.mode]
		self.game_mode_selections[#self.game_mode_selections+1] = self.game_mode_folder
	else
		self.ruleset_folder = self.ruleset_folder[self.menu_state.ruleset]
		self.ruleset_folder_selections[#self.ruleset_folder_selections+1] = self.ruleset_folder
	end
end

function ModeSelectScene:onInputPress(e)
	if (e.input or e.scancode) and (self.display_warning or #self.game_mode_folder == 0 or #self.ruleset_folder == 0) then
		if self.display_warning then
			scene = TitleScene()
		elseif #self.game_mode_folder == 0 then
			self:menuGoBack("mode")
		else
			self:menuGoBack("ruleset")
		end
	elseif e.input == "menu_back" then
		local has_started = self.starting
		if self.starting then
			self.starting = false
			self.start_frames = 0
			return
		end
		playSE("menu_cancel")
		if self.menu_state.select == "mode" then
			if #self.game_mode_selections > 1 then
				self:menuGoBack("mode")
				self.menu_state.mode = 1
				return
			end
		else
			if #self.ruleset_folder_selections > 1 then
				self:menuGoBack("ruleset")
				self.menu_state.ruleset = 1
				return
			end
		end
		if not has_started then
			scene = TitleScene()
		end
	elseif e.type == "mouse" and e.button == 1 then
		if e.y < 80 then
			if e.x > 0 and e.y > 40 and e.x < 50 then
				playSE("menu_cancel")
				if self.menu_state.select == "mode" then
					if #self.game_mode_selections > 1 then
						self:menuGoBack("mode")
						self.menu_state.mode = 1
						return
					end
				else
					if #self.ruleset_folder_selections > 1 then
						self:menuGoBack("ruleset")
						self.menu_state.ruleset = 1
						return
					end
				end
				scene = TitleScene()
			end
			return
		end
		if #self.game_mode_folder == 0 then
			self:menuGoBack("mode")
			self.menu_state.mode = 1
			return
		end
		if #self.ruleset_folder == 0 then
			self:menuGoBack("ruleset")
			self.menu_state.ruleset = 1
			return
		end
		if e.x < 320 then
			self.auto_menu_state = "mode"
		else
			self.auto_menu_state = "ruleset"
		end
		if self.auto_menu_state ~= self.menu_state.select then
			self:switchSelect()
		end
		self.auto_menu_offset = math.floor((e.y - 260)/20)
		if self.auto_menu_offset == 0 and self.auto_menu_state == "mode" then
			if self.game_mode_folder[self.menu_state.mode].is_directory then
				playSE("main_decide")
				self:menuGoForward("mode")
				self.menu_state.mode = 1
				return
			end
			self:indirectStartMode()
		elseif self.ruleset_folder[self.menu_state.ruleset].is_directory and e.x > 320 and self.auto_menu_offset == 0 then
			playSE("main_decide")
			self:menuGoForward("ruleset")
			self.menu_state.ruleset = 1
		end
	elseif self.starting then return
	elseif e.type == "wheel" then
		if #self.ruleset_folder == 0 or #self.game_mode_folder == 0 then
			return
		end
		if e.x % 2 == 1 then
			self:switchSelect()
		end
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif e.input == "menu_decide" then
		if self.menu_state.select == "mode" and self.game_mode_folder[self.menu_state.mode].is_directory then
			playSE("main_decide")
			self:menuGoForward("mode")
			self.menu_state.mode = 1
			return
		elseif self.menu_state.select == "ruleset" and self.ruleset_folder[self.menu_state.ruleset].is_directory then
			playSE("main_decide")
			self:menuGoForward("ruleset")
			self.menu_state.ruleset = 1
			return
		end
		self:indirectStartMode()
	elseif e.input == "menu_up" then
		self.das_up = true
		self.das_down = nil
	elseif e.input == "menu_down" then
		self.das_down = true
		self.das_up = nil
	elseif e.input == "menu_left" or e.input == "menu_right" then
		self:switchSelect()
	elseif e.input then
		self.secret_inputs[e.input] = true
	end
end

function ModeSelectScene:onInputRelease(e)
	if e.input == "menu_up" then
		self.das_up = nil
	elseif e.input == "menu_down" or e.scancode == "down" then
		self.das_down = nil
	elseif e.input then
		self.secret_inputs[e.input] = false
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
	local len = #self.game_mode_folder
	self.menu_state.mode = Mod1(self.menu_state.mode + rel, len)
end

function ModeSelectScene:changeRuleset(rel)
	local len = #self.ruleset_folder
	self.menu_state.ruleset = Mod1(self.menu_state.ruleset + rel, len)
end

return ModeSelectScene