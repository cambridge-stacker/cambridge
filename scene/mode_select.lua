local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Game Start"

current_mode = 1
current_ruleset = 1
current_folder_selections = {
	mode = {},
	ruleset = {},
}
current_tags = {
	mode = {},
	ruleset = {},
}

function ModeSelectScene:new()
	-- reload custom modules
	initModules()
	self.game_mode_tags = self:loadTags(game_modes, "mode")
	self.game_mode_selections = {game_modes}
	self.game_mode_folder = self:getFromSelectedTags(self.game_mode_tags, "mode")
	self.ruleset_tags = self:loadTags(rulesets, "ruleset")
	self.ruleset_folder_selections = {rulesets}
	self.ruleset_folder = self:getFromSelectedTags(self.ruleset_tags, "ruleset")
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
		select = "mode",
	}
	self.secret_inputs = {}
	self.secret_sequence = {}
	self.sequencing_start_frames = 0
	self.input_timers = {}
	self.das = 0
	-- It's not exactly self-descriptive.
	self.menu_mode_height = 20
	-- It's not exactly self-descriptive.
	self.menu_ruleset_height = 20
	self.auto_menu_offset = 0
	self.auto_menu_state = "mode"
	self.start_frames, self.starting = 0, false
	self.safety_frames = 2
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a mode",
		largeImageKey = "ingame-000"
	})
end

function ModeSelectScene:loadTags(folder, tag_type)
	local tags = {}
	for key, value in ipairs(folder) do
		for k2, v2 in pairs(current_tags[tag_type]) do
			if (table.contains(value, v2.name) and value.is_tag) then
				tags[k2] = value
			end
		end
	end
	return tags
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
	if config.tunings.mode_dynamic_arr == 2 then
		return config.menu_arr
	end
	return 32 / (number ^ 0.45)
end

function ModeSelectScene:update()
	switchBGM(nil) -- experimental
	for key, value in pairs(self.input_timers) do
		self.input_timers[key] = value - 1
		if value < 0 then
			self.input_timers[key] = nil
		end
	end
	if self.input_timers["reload"] == 0 then
		unloadModules()
		scene = ModeSelectScene()
		scene.reload_time_remaining = 90
		playSE("ihs")
	end
	if self.input_timers["secret_sequencing"] == 0 then
		self.is_sequencing = true
		self.first_input = true
	end
	if self.input_timers["stop_sequencing"] == 0 then
		self.is_sequencing = false
	end
	if self.input_timers["reset_tags"] == 0 then
		self.game_mode_tags = {}
		self.ruleset_tags = {}
		self.game_mode_folder = self.game_mode_selections[#self.game_mode_selections]
		self.ruleset_folder = self.ruleset_folder_selections[#self.ruleset_folder_selections]
		playSE("ihs")
		self.text_tag_unselect_timer = 60
	end

	if self.is_sequencing then
		self.sequencing_start_frames = math.min(self.sequencing_start_frames + 1, 20)
	else
		self.sequencing_start_frames = math.max(self.sequencing_start_frames - 1, 0)
	end

	self.safety_frames = self.safety_frames - 1
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
	if self:menuDASInput(self.das_up, "up", config.menu_das, config.menu_arr / 4) then
		self:changeOption(-1)
	end
	if self:menuDASInput(self.das_down, "down", config.menu_das, config.menu_arr / 4) then
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

	local sequencing_start_frames = self.sequencing_start_frames

	local tagline_y = tagline_position == 1 and (5 - sequencing_start_frames * 5) or 420
	local render_list_size = tagline_position == 2 and 18 or 20

	if tagline_position ~= 3
	and self.game_mode_folder[self.menu_state.mode]
	and not self.game_mode_folder[self.menu_state.mode].is_directory then
		love.graphics.printf(
			"Tagline: "..(self.game_mode_folder[mode_selected].tagline or "Missing."),
			 10, tagline_y, 620, "left")
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
			local r = mode.is_tag and 0 or 1
			if highlight < 0.5 then
				r = 1-highlight
				b = highlight
			end
			if idx == self.menu_state.mode and self.starting then
				b = self.start_frames % 10 > 4 and 0 or 1
			end
			love.graphics.setColor(r,1,b,fadeoutAtEdges(
				-self.menu_mode_height + 20 * idx - fade_offset,
				render_list_size * 10 - 20,
				20))
			drawWrappingText(mode.name,
			40, (260 - self.menu_mode_height) + 20 * idx, 200, "left")
			if table.contains(self.game_mode_tags, mode) then
				love.graphics.rectangle("fill", 20, (259 - self.menu_mode_height) + 20 * idx, 10, 20)
			end
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
			local r = ruleset.is_tag and 0 or 1
			if highlight < 0.5 then
				r = 1-highlight
				b = highlight
			end
			love.graphics.setColor(r, 1, b, fadeoutAtEdges(
				-self.menu_ruleset_height + 20 * idx - fade_offset,
				render_list_size * 10 - 20,
				20)
			)
			drawWrappingText(ruleset.name,
			360, (260 - self.menu_ruleset_height) + 20 * idx, 160, "left")
			if table.contains(self.ruleset_tags, ruleset) then
				love.graphics.rectangle("fill", 340, (259 - self.menu_ruleset_height) + 20 * idx, 10, 20)
			end
		end
	end
	if self.game_mode_folder[self.menu_state.mode]
	and self.game_mode_folder[self.menu_state.mode].ruleset_override then
		love.graphics.setColor(0, 0, 0, 0.75)
		love.graphics.rectangle("fill", 330, 80, 240, 380, 5, 5)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("This mode overrides the chosen ruleset!", 340, 240, 220, "center")
	end

	if sequencing_start_frames > 0 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Secret sequence: " .. self:getSequenceShorthand(), 10, -95 + sequencing_start_frames * 5, 620, "left")
	end
	local function drawFadingTextNearHeader(timer, string, decay_time)
		if timer then
			love.graphics.setColor(1, 1, 1, 1 - timer / decay_time)
			love.graphics.printf(string, 320, 40, 320, "center")
		end
	end
	drawFadingTextNearHeader(60 - (self.reload_time_remaining or 0), "Modules reloaded!", 60)
	if self.reload_time_remaining then self.reload_time_remaining = self.reload_time_remaining - 1 end
	drawFadingTextNearHeader(self.input_timers["reload"], "Keep holding Generic 1 to reload modules...", 40)
	drawFadingTextNearHeader(self.input_timers["secret_sequencing"], "Keep holding Generic 2 to input secret sequences...", 40)
	drawFadingTextNearHeader(self.input_timers["stop_sequencing"], "Keep holding to stop sequencing...", 40)
	drawFadingTextNearHeader(self.input_timers["reset_tags"], "Keep holding Generic 3 to reset all tag selections....", 40)
	drawFadingTextNearHeader(60 - (self.text_tag_unselect_timer or 0), "You've unselected all tags.", 60)
	if self.text_tag_unselect_timer then self.text_tag_unselect_timer = self.text_tag_unselect_timer - 1 end
	love.graphics.setColor(1, 1, 1, 1)
end

local INPUT_SHORTHANDS = {
	left = "<-",
	right = "->",
	up = "^",
	down = "v",
	rotate_left = "L1",
	rotate_left2 = "L2",
	rotate_right = "R1",
	rotate_right2 = "R2",
	rotate_180 = "180",
	hold = "H",
	generic_1 = "G1",
	generic_2 = "G2",
	generic_3 = "G3",
	generic_4 = "G4",
}
function ModeSelectScene:getSequenceShorthand()
	local shorthands = {}
	for index, value in ipairs(self.secret_sequence) do
		if INPUT_SHORTHANDS[value] then
			table.insert(shorthands, INPUT_SHORTHANDS[value])
		else
			table.insert(shorthands, value)
		end
	end
	return table.concat(shorthands, " ")
end

function ModeSelectScene:injectSecretSequenceOnMatch(mode)
	if type(mode.sequences) == "table" then
		for name, sequence in pairs(mode.sequences) do
			if type(sequence) == "table" then
				local matches_required = #sequence
				local matches_found = 0
				for k2, v2 in pairs(self.secret_sequence) do
					if sequence[matches_found+1] == v2 then
						matches_found = matches_found + 1
					elseif matches_found < matches_required then
						matches_found = sequence[1] == v2 and 1 or 0
					end
				end
				if matches_found >= matches_required then
					self.secret_inputs[name] = true
				end
			end
		end
	end
end

function ModeSelectScene:handleTagSelection(select_type)
	local selected_tag = false
	local tag_select_type
	if self.ruleset_folder[self.menu_state.ruleset].is_tag and select_type == "ruleset" then
		tag_select_type = self.handleTagFolder(self.ruleset_folder, self.ruleset_tags, self.menu_state.ruleset)
		self.ruleset_folder = self:getFromSelectedTags(self.ruleset_tags, "ruleset")
		selected_tag = true
	elseif self.game_mode_folder[self.menu_state.mode].is_tag then
		tag_select_type = self.handleTagFolder(self.game_mode_folder, self.game_mode_tags, self.menu_state.mode)
		self.game_mode_folder = self:getFromSelectedTags(self.game_mode_tags, "mode")
		selected_tag = true
	elseif self.ruleset_folder[self.menu_state.ruleset].is_tag and select_type == "mode" then
		tag_select_type = self.handleTagFolder(self.ruleset_folder, self.ruleset_tags, self.menu_state.ruleset)
		self.ruleset_folder = self:getFromSelectedTags(self.ruleset_tags, "ruleset")
		selected_tag = true
	end
	if selected_tag then
		if tag_select_type then
			playSE("main_decide")
		else
			playSE("menu_cancel")
		end
	end
	return selected_tag
end

function ModeSelectScene:indirectStartMode()
	if self:handleTagSelection(self.menu_state.select) then
		return
	end
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
	current_mode = self.menu_state.mode
	current_ruleset = self.menu_state.ruleset
	current_tags = {mode = self.game_mode_tags, ruleset = self.ruleset_tags}
	config.current_mode = current_mode
	config.current_ruleset = current_ruleset
	config.current_folder_selections = current_folder_selections
	config.current_tags = current_tags
	saveConfig()
	self:injectSecretSequenceOnMatch(self.game_mode_folder[self.menu_state.mode])
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
		self.menu_mode_height = selection * 20 - 20
		self.game_mode_selections[#self.game_mode_selections] = nil
		self.game_mode_folder = self.game_mode_selections[#self.game_mode_selections]
	elseif menu_type == "ruleset" and #self.ruleset_folder_selections > 1 then
		self.menu_ruleset_height = selection * 20 - 20
		self.ruleset_folder_selections[#self.ruleset_folder_selections] = nil
		self.ruleset_folder = self.ruleset_folder_selections[#self.ruleset_folder_selections]
	end
end

function ModeSelectScene.handleTagFolder(folder, tags, state)
	local toggle = false
	if folder[state].is_tag then
		local name = folder[state].name
		if tags[name] == nil then
			tags[name] = folder[state]
			toggle = true
		else
			tags[name] = nil
		end
	end
	return toggle
end


function ModeSelectScene:getFromSelectedTags(selected_tags, select_type)
	local root_folder = game_modes
	if select_type == "ruleset" then
		root_folder = rulesets
	end
	if next(selected_tags) == nil then
		return select_type == "ruleset" and self.ruleset_folder_selections[#self.ruleset_folder_selections] or self.game_mode_selections[#self.game_mode_selections]
	end
	local result_folder = {}
	for k, v in pairs(selected_tags) do
		for k2, v2 in pairs(v) do
			if not table.contains(result_folder, v2) and type(v2) == "table" then
				table.insert(result_folder, v2)
			end
		end
	end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(result_folder, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	for index, value in ipairs(root_folder) do
		if value.is_tag and not value.tags then
			table.insert(result_folder, index, value)
		end
	end
	return result_folder
end

function ModeSelectScene:menuGoForward(menu_type, is_load)
	if not is_load then
		table.insert(current_folder_selections[menu_type], self.menu_state[menu_type])
	end
	if menu_type == "mode" and type(self.game_mode_folder[self.menu_state.mode]) == "table" then
		self.menu_mode_height = -20
		self.game_mode_folder = self.game_mode_folder[self.menu_state.mode]
		self.game_mode_selections[#self.game_mode_selections+1] = self.game_mode_folder
		self.secret_sequence = {}
		return true
	elseif menu_type == "ruleset" and type(self.ruleset_folder[self.menu_state.ruleset]) == "table" then
		self.menu_ruleset_height = -20
		self.ruleset_folder = self.ruleset_folder[self.menu_state.ruleset]
		self.ruleset_folder_selections[#self.ruleset_folder_selections+1] = self.ruleset_folder
		return true
	end
end

function ModeSelectScene:exitScene()
	current_mode = self.menu_state.mode
	current_ruleset = self.menu_state.ruleset
	current_tags = {mode = self.game_mode_tags, ruleset = self.ruleset_tags}
	config.current_mode = current_mode
	config.current_ruleset = current_ruleset
	config.current_folder_selections = current_folder_selections
	config.current_tags = current_tags
	scene = TitleScene()
end

local SYSTEM_INPUTS = {
	menu_decide = true,
	menu_back = true,
	menu_left = true,
	menu_right = true,
	menu_up = true,
	menu_down = true,
	mode_exit = true,
	retry = true,
	pause = true,
	frame_step = true,
}

function ModeSelectScene:onInputPress(e)
	if self.safety_frames > 0 then
		return
	end
	if (e.input or e.scancode) and (self.display_warning or #self.game_mode_folder == 0 or #self.ruleset_folder == 0) then
		if self.display_warning then
			scene = TitleScene()
		elseif #self.game_mode_folder == 0 then
			self:menuGoBack("mode")
		else
			self:menuGoBack("ruleset")
		end
	elseif self.is_sequencing and e.type ~= "wheel" then
		self.input_timers["stop_sequencing"] = 60
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
				return
			end
		else
			if #self.ruleset_folder_selections > 1 then
				self:menuGoBack("ruleset")
				return
			end
		end
		if not has_started then
			self:exitScene()
		end
	elseif e.type == "mouse" and e.button == 1 then
		if e.y < 80 then
			if e.x > 0 and e.y > 40 and e.x < 50 then
				playSE("menu_cancel")
				if self.menu_state.select == "mode" then
					if #self.game_mode_selections > 1 then
						self:menuGoBack("mode")
						return
					end
				else
					if #self.ruleset_folder_selections > 1 then
						self:menuGoBack("ruleset")
						return
					end
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
			self:indirectStartMode()
		elseif self.ruleset_folder[self.menu_state.ruleset].is_directory and e.x > 320 and self.auto_menu_offset == 0 then
			if self:handleTagSelection("ruleset") then
				return
			end
			playSE("main_decide")
			self:menuGoForward("ruleset")
			self.menu_state.ruleset = 1
		end
	elseif self.starting then return
	elseif e.type == "wheel" and not self.is_sequencing then
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
	
	if not self.is_sequencing then
		if e.input == "generic_1" then
			self.input_timers["reload"] = 60
		elseif e.input == "generic_2" then
			self.input_timers["secret_sequencing"] = 60
		elseif e.input == "generic_3" then
			self.input_timers["reset_tags"] = 60
		end
	end
end

function ModeSelectScene:onInputRelease(e)
	if self.is_sequencing then
		self.input_timers["stop_sequencing"] = nil
		if not self.first_input and not SYSTEM_INPUTS[e.input] then
			table.insert(self.secret_sequence, e.input)
		end
		self.first_input = false
	elseif e.input == "generic_1" then
		self.input_timers["reload"] = nil
	elseif e.input == "generic_2" then
		self.input_timers["secret_sequencing"] = nil
	elseif e.input == "generic_3" then
		self.input_timers["reset_tags"] = nil
	end
	if e.input == "menu_up" then
		self.das_up = nil
	elseif e.input == "menu_down" then
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
	if len == 0 then return end
	self.menu_state.mode = Mod1(self.menu_state.mode + rel, len)
	self.secret_sequence = {}
end

function ModeSelectScene:changeRuleset(rel)
	local len = #self.ruleset_folder
	if len == 0 then return end
	self.menu_state.ruleset = Mod1(self.menu_state.ruleset + rel, len)
end

return ModeSelectScene