local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Mode list"

function ModeSelectScene:new()
	if highscores == nil then highscores = {} end
	self.game_mode_folder = game_modes
	self.game_mode_selections = {game_modes}
	self.ruleset_folder = rulesets
	self.ruleset_folder_selections = {rulesets}
	self.menu_state = {}
	if #self.game_mode_folder == 0 or #self.ruleset_folder == 0 then
		self.display_warning = true
		current_mode = 1
		current_ruleset = 1
	else
		for k, v in pairs(current_folder_selections) do
			for k2, v2 in pairs(v) do
				self.menu_state[k] = v2
				if not self:menuGoForward(k, true) then
					break
				end
			end
		end
		self.display_warning = false
		if current_mode > #self.game_mode_folder then
			current_mode = 1
		end
		if current_ruleset > #self.ruleset_folder then
			current_ruleset = 1
		end
	end
	self.menu_state = {
		mode = current_mode,
		ruleset = current_ruleset,
	}
	self.secret_inputs = {}
	self.das_x, self.das_y = 0, 0
	self.menu_mode_y = 20
	self.menu_ruleset_x = 20
	self.auto_mode_offset = 0
	self.auto_ruleset_offset = 0
	self.start_frames, self.starting = 0, false
	self.safety_frames = 0
	self:refreshHighscores()
	DiscordRPC:update({
		details = "In menus",
		state = "Chosen ??? and ???.",
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
	switchBGM(nil)
	self.safety_frames = self.safety_frames - 1
	if self.starting then
		self.start_frames = self.start_frames + 1
		if self.start_frames > 60 or config.visualsettings.mode_entry == 1 then
			self:startMode()
		end
		return
	end
	if self.das_up or self.das_down then
		self.das_y = self.das_y + 1
	else
		self.das_y = 0
	end
	if self.das_left or self.das_right then
		self.das_x = self.das_x + 1
	else
		self.das_x = 0
	end
	if self.auto_mode_offset ~= 0 then
		self:changeMode(self.auto_mode_offset < 0 and -1 or 1)
		if self.auto_mode_offset > 0 then self.auto_mode_offset = self.auto_mode_offset - 1 end
		if self.auto_mode_offset < 0 then self.auto_mode_offset = self.auto_mode_offset + 1 end
	end
	if self.auto_ruleset_offset ~= 0 then
		self:changeRuleset(self.auto_ruleset_offset < 0 and -1 or 1)
		if self.auto_ruleset_offset > 0 then self.auto_ruleset_offset = self.auto_ruleset_offset - 1 end
		if self.auto_ruleset_offset < 0 then self.auto_ruleset_offset = self.auto_ruleset_offset + 1 end
	end
	if self:menuDASInput(self.das_up, "up", 12) then
		self:changeMode(-1)
	end
	if self:menuDASInput(self.das_down, "down", 12) then
		self:changeMode(1)
	end
	if self:menuDASInput(self.das_left, "left", 15, 4) then
		self:changeRuleset(-1)
	end
	if self:menuDASInput(self.das_right, "right", 15, 4) then
		self:changeRuleset(1)
	end
	DiscordRPC:update({
		details = "In menus",
		state = "Chosen ".. ((self.game_mode_folder[self.menu_state.mode] or {name = "no mode"}).name) .." and ".. ((self.ruleset_folder[self.menu_state.ruleset] or {name = "no ruleset"}).name) ..".",
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

	self.menu_mode_y = interpolateNumber(self.menu_mode_y / 20, mode_selected) * 20
	self.menu_ruleset_x = interpolateNumber(self.menu_ruleset_x / 120, ruleset_selected) * 120

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 259 + (mode_selected * 20) - self.menu_mode_y, 240, 22)
	love.graphics.rectangle("fill", 260 + (ruleset_selected * 120) - self.menu_ruleset_x, 439, 120, 22)
	love.graphics.setColor(1, 1, 1, 1)


	if 	self.game_mode_folder[self.menu_state.mode]
	and not self.game_mode_folder[self.menu_state.mode].is_directory then
		love.graphics.printf(
			"Tagline: "..(self.game_mode_folder[mode_selected].tagline or "Missing."),
			 280, 40, 360, "left")
	end
	if type(self.mode_highscore) == "table" then
		for name, idx in pairs(self.highscore_index) do
			drawWrappingText(tostring(name), 180 + idx * 100, 100, 100, "left")
		end
		for key, slot in pairs(self.mode_highscore) do
			if key == 11 then
				break
			end
			for name, value in pairs(slot) do
				local idx = self.highscore_index[name]
				local formatted_string = toFormattedValue(value)
				drawWrappingText(tostring(formatted_string), 180 + idx * 100, 100 + 20 * key, 100, "left")
			end
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	local mode_path_name = ""
	if #self.game_mode_selections > 1 then
		for index, value in ipairs(self.game_mode_selections) do
			mode_path_name = mode_path_name..(value.name or "modes").." > "
		end
		love.graphics.setColor(1, 1, 1, fadeoutAtEdges(
			-self.menu_mode_y - 20,
			160,
			20))
		love.graphics.printf(
			self.game_mode_folder.is_tag and
			"Tag: ".. self.game_mode_folder.name or
			"Path: "..mode_path_name:sub(1, -3),
			 40, 220 - self.menu_mode_y, 200, "left")
	end
	local ruleset_path_name = ""
	if #self.ruleset_folder_selections > 1 then
		for index, value in ipairs(self.ruleset_folder_selections) do
			ruleset_path_name = ruleset_path_name..(value.name or "rulesets").." > "
		end
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(
			self.ruleset_folder.is_tag and
			"Tag: ".. self.ruleset_folder.name or
			"Path: "..ruleset_path_name:sub(1, -3),
			 360 - self.menu_ruleset_x, 420, 60 + font_3x5_2:getWidth(ruleset_path_name), "left")
	end
	love.graphics.setFont(font_3x5_2)
	if #self.game_mode_folder == 0 then
		love.graphics.printf("No modes in this folder!", 40, 280 - self.menu_mode_y, 260, "left")
	end
	if #self.ruleset_folder == 0 then
		love.graphics.printf("Empty folder!", 380 - self.menu_ruleset_x, 440, 120, "center")
	end
	for idx, mode in ipairs(self.game_mode_folder) do
		if(idx >= self.menu_mode_y / 20 - 10 and
		   idx <= self.menu_mode_y / 20 + 10) then
			local b = 1
			if mode.is_directory then
				b = 0.4
			end
			local highlight = cursorHighlight(
				0,
				(260 - self.menu_mode_y) + 20 * idx,
				260,
				20)
			local r = mode.is_tag and 0 or 1
			if highlight < 0.5 then
				r = 1-highlight
				b = highlight
			end
			if idx == self.menu_state.mode and self.starting then
				b = self.start_frames % 10 > 4 and 0 or 1
			end
			love.graphics.setColor(r, 1, b, fadeoutAtEdges(
				-self.menu_mode_y + 20 * idx + 20,
				160,
				20))
			drawWrappingText(mode.name,
			40, (260 - self.menu_mode_y) + 20 * idx, 200, "left")
		end
	end
	for idx, ruleset in ipairs(self.ruleset_folder) do
		if(idx >= self.menu_ruleset_x / 120 - 3 and
		   idx <= self.menu_ruleset_x / 120 + 3) then
			local b = 1
			if ruleset.is_directory then
				b = 0.4
			end
			local highlight = cursorHighlight(
				260 - self.menu_ruleset_x + 120 * idx, 440,
				120, 20)
			local r = ruleset.is_tag and 0 or 1
			if highlight < 0.5 then
				r = 1-highlight
				b = highlight
			end
			love.graphics.setColor(r, 1, b, fadeoutAtEdges(
				-self.menu_ruleset_x + 120 * idx,
				240,
				120)
			)
			drawWrappingText(ruleset.name,
			260 - self.menu_ruleset_x + 120 * idx, 440, 120, "center")
		end
	end
	if self.reload_time_remaining and self.reload_time_remaining > 0 then
		love.graphics.setColor(1, 1, 1, self.reload_time_remaining / 60)
		love.graphics.printf("Modules reloaded!", 0, 10, 640, "center")
		self.reload_time_remaining = self.reload_time_remaining - 1
	end
end

function ModeSelectScene:indirectStartMode()
	if self.ruleset_folder[self.menu_state.ruleset].is_directory then
		playSE("main_decide")
		self:menuGoForward("ruleset")
		self:refreshHighscores()
		return
	elseif self.game_mode_folder[self.menu_state.mode].is_directory then
		playSE("main_decide")
		self:menuGoForward("mode")
		self:refreshHighscores()
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
	current_mode = self.menu_state.mode
	current_ruleset = self.menu_state.ruleset
	config.current_mode = current_mode
	config.current_ruleset = current_ruleset
	config.current_folder_selections = current_folder_selections
	saveConfig()
	scene = GameScene(
		self.game_mode_folder[self.menu_state.mode],
		self.ruleset_folder[self.menu_state.ruleset],
		self.secret_inputs
	)
end

function ModeSelectScene:menuGoBack(menu_type)
	local selection = table.remove(current_folder_selections[menu_type], #current_folder_selections[menu_type])
	self.menu_state[menu_type] = selection
	if menu_type == "mode" and #self.game_mode_selections > 1 then
		self.menu_mode_y = selection * 20 - 20
		self.game_mode_selections[#self.game_mode_selections] = nil
		self.game_mode_folder = self.game_mode_selections[#self.game_mode_selections]
	elseif menu_type == "ruleset" and #self.ruleset_folder_selections > 1 then
		self.menu_ruleset_x = selection * 120 - 120
		self.ruleset_folder_selections[#self.ruleset_folder_selections] = nil
		self.ruleset_folder = self.ruleset_folder_selections[#self.ruleset_folder_selections]
	end
	self.mode_highscore = nil
end

function ModeSelectScene:menuGoForward(menu_type, is_load)
	if not is_load then
		table.insert(current_folder_selections[menu_type], self.menu_state[menu_type])
	end
	if menu_type == "mode" and type(self.game_mode_folder[self.menu_state.mode]) == "table" then
		self.menu_mode_y = -20
		self.game_mode_folder = self.game_mode_folder[self.menu_state.mode]
		self.game_mode_selections[#self.game_mode_selections+1] = self.game_mode_folder
		self.menu_state.mode = 1
		return true
	elseif menu_type == "ruleset" and type(self.ruleset_folder[self.menu_state.ruleset]) == "table" then
		self.menu_ruleset_x = -20
		self.ruleset_folder = self.ruleset_folder[self.menu_state.ruleset]
		self.ruleset_folder_selections[#self.ruleset_folder_selections+1] = self.ruleset_folder
		self.menu_state.ruleset = 1
		return true
	end
end

function ModeSelectScene:exitScene()
	current_mode = self.menu_state.mode
	current_ruleset = self.menu_state.ruleset
	config.current_mode = current_mode
	config.current_ruleset = current_ruleset
	config.current_folder_selections = current_folder_selections
	scene = TitleScene()
end

function ModeSelectScene:onInputPress(e)
	if self.safety_frames > 0 then
		return
	end
	if e.scancode == "lctrl" or e.scancode == "rctrl" then
		self.ctrl_held = true
	end
	if e.scancode == "r" and self.ctrl_held then
		-- reload custom modules
		unloadModules()
		initModules()
		scene = ModeSelectScene()
		scene.reload_time_remaining = 90
		playSE("ihs")
	end
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
		if #self.game_mode_selections > 1 then
			self:menuGoBack("mode")
			return
		end
		if #self.ruleset_folder_selections > 1 then
			self:menuGoBack("ruleset")
			return
		end
		if not has_started then
			self:exitScene()
		end
	elseif e.type == "mouse" then
		if e.y < 80 then
			if e.x > 0 and e.y > 40 and e.x < 50 then
				playSE("menu_cancel")
				if #self.game_mode_selections > 1 then
					self:menuGoBack("mode")
					return
				end
				if #self.ruleset_folder_selections > 1 then
					self:menuGoBack("ruleset")
					return
				end
				self:exitScene()
			end
			return
		end
		if #self.game_mode_folder == 0 then
			self:menuGoBack("mode")
			return
		end
		if #self.ruleset_folder == 0 then
			self:menuGoBack("ruleset")
			return
		end
		if e.y < 440 then
			if e.x < 260 then
				self.auto_mode_offset = math.floor((e.y - 260)/20)
				if self.auto_mode_offset == 0 then
					if self.game_mode_folder[self.menu_state.mode].is_directory then
						playSE("main_decide")
						self:menuGoForward("mode")
						self:refreshHighscores()
						return
					end
					self:indirectStartMode()
				end
			end
		else
			self.auto_ruleset_offset = math.floor((e.x - 260)/120)
			if self.auto_ruleset_offset == 0 and self.ruleset_folder[self.menu_state.ruleset].is_directory then
				playSE("main_decide")
				self:menuGoForward("ruleset")
				self:refreshHighscores()
			end
		end
	elseif self.starting then return
	elseif e.type == "wheel" then
		if #self.ruleset_folder == 0 or #self.game_mode_folder == 0 then
			return
		end
		if e.x ~= 0 then
			self:changeRuleset(-e.x)
		end
		if e.y ~= 0 then
			self:changeMode(-e.y)
		end
	elseif e.input == "menu_decide" then
		self:indirectStartMode()
	elseif e.input == "menu_up" then
		self.das_up = true
		self.das_down = nil
	elseif e.input == "menu_down" then
		self.das_down = true
		self.das_up = nil
	elseif e.input == "menu_left" then
		self.das_left = true
		self.das_right = nil
	elseif e.input == "menu_right" then
		self.das_right = true
		self.das_left = nil
	elseif e.input then
		self.secret_inputs[e.input] = true
	end
end

function ModeSelectScene:onInputRelease(e)
	if e.scancode == "lctrl" or e.scancode == "rctrl" then
		self.ctrl_held = false
	end
	if e.input == "menu_up" then
		self.das_up = nil
	elseif e.input == "menu_down" then
		self.das_down = nil
	elseif e.input == "menu_left" then
		self.das_left = nil
	elseif e.input == "menu_right" then
		self.das_right = nil
	elseif e.input then
		self.secret_inputs[e.input] = false
	end
end

function ModeSelectScene:refreshHighscores()
	if self.game_mode_folder[self.menu_state.mode].hash == nil or self.ruleset_folder[self.menu_state.ruleset].hash == nil then
		self.mode_highscore = nil
		return
	end
	local hash = self.game_mode_folder[self.menu_state.mode].hash .. "-" .. self.ruleset_folder[self.menu_state.ruleset].hash
	self.mode_highscore = highscores[hash]
	self.highscore_index = HighscoresScene.getHighscoreIndexing(hash)
end

function ModeSelectScene:changeMode(rel)
	local len = #self.game_mode_folder
	if len == 0 then return end
	playSE("cursor")
	self.menu_state.mode = Mod1(self.menu_state.mode + rel, len)
	self:refreshHighscores()
end

function ModeSelectScene:changeRuleset(rel)
	local len = #self.ruleset_folder
	if len == 0 then return end
	playSE("cursor_lr")
	self.menu_state.ruleset = Mod1(self.menu_state.ruleset + rel, len)
	self:refreshHighscores()
end

return ModeSelectScene