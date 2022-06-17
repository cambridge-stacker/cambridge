local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Mode list"

--#region Custom mouse code

--This is for mouse. Can be removed only if the code in Mouse Controls region is removed.
local left_clicked_before = true
local mouse_idle = 0
local prev_cur_pos_x, prev_cur_pos_y = 0, 0


-- For when mouse controls are part of menu controls
local function getScaledPos(cursor_x, cursor_y)
	local screen_x, screen_y = love.graphics.getDimensions()
	local scale_factor = math.min(screen_x / 640, screen_y / 480)
	return (cursor_x - (screen_x - scale_factor * 640) / 2)/scale_factor, (cursor_y - (screen_y - scale_factor * 480) / 2)/scale_factor
end

local function CursorHighlight(x,y,w,h)
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if mouse_idle > 2 or config.visualsettings.cursor_highlight ~= 1 then
		return 1
	end
	if mouse_x > x and mouse_x < x+w and mouse_y > y and mouse_y < y+h then
		return 0
	else
		return 1
	end
end
--Interpolates in a smooth fashion unless the visual setting for scrolling is nil or off.
local function interpolateListPos(input, from, speed)
	if config.visualsettings["smooth_scroll"] == 2 or config.visualsettings["smooth_scroll"] == nil then
		return from
	end
    if speed == nil then speed = 1 end
	if from > input then
		input = input + ((from - input) / 4) * speed
		if input > from - 0.02 then
			input = from
		end
	elseif from < input then
		input = input + ((from - input) / 4) * speed
		if input < from + 0.02 then
			input = from
		end
	end
	return input
end
--#endregion

function ModeSelectScene:new()
	-- reload custom modules
	initModules()
	if highscores == nil then highscores = {} end
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
	}
	self.secret_inputs = {}
	self.das_x, self.das_y = 0, 0
	self.menu_mode_y = 20
	self.menu_ruleset_x = 20
	self.auto_mode_offset = 0
    self.auto_ruleset_offset = 0
	self.start_frames, self.starting = 0, false
	DiscordRPC:update({
		details = "In menus",
		state = "Chosen ??? and ???.",
		largeImageKey = "ingame-000"
	})

    --It's here to avoid some seems-to-be bug with the scene's built-in mouse controls.
    left_clicked_before = true
end
function ModeSelectScene:update()
	switchBGM(nil)
	if self.starting then
		self.start_frames = self.start_frames + 1
		if self.start_frames > 60 or config.visualsettings.mode_entry == 1 then
			self:startMode()
		end
		return
	end

    --#region Mouse controls.
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if love.mouse.isDown(1) and not left_clicked_before then
        if mouse_y < 440 then
            if mouse_x < 260 then
                self.auto_mode_offset = math.floor((mouse_y - 260)/20)
                if self.auto_mode_offset == 0 then
                    self:indirectStartMode()
                end
            end
        else
            self.auto_ruleset_offset = math.floor((mouse_x - 260)/120)
        end
	end
    left_clicked_before = love.mouse.isDown(1) or mouse_idle > 2
    if prev_cur_pos_x == love.mouse.getX() and prev_cur_pos_y == love.mouse.getY() then
        mouse_idle = mouse_idle + love.timer.getDelta()
    else
        mouse_idle = 0
    end
    prev_cur_pos_x, prev_cur_pos_y = love.mouse.getPosition()
    --#endregion
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
	if self.das_y >= 15 then
		self:changeMode(self.das_up and -1 or 1)
		self.das_y = self.das_y - 4
	end
	if self.das_x >= 15 then
		self:changeRuleset(self.das_left and -1 or 1)
		self.das_x = self.das_x - 15
	end
	DiscordRPC:update({
		details = "In menus",
		state = "Chosen ".. game_modes[self.menu_state.mode].name .." and ".. rulesets[self.menu_state.ruleset].name ..".",
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

	local mode_selected, ruleset_selected = self.menu_state.mode, self.menu_state.ruleset

	self.menu_mode_y = interpolateListPos(self.menu_mode_y / 20, mode_selected) * 20
	self.menu_ruleset_x = interpolateListPos(self.menu_ruleset_x / 120, ruleset_selected) * 120

    love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 258 + (mode_selected * 20) - self.menu_mode_y, 240, 22)
	love.graphics.rectangle("fill", 260 + (ruleset_selected * 120) - self.menu_ruleset_x, 440, 120, 22)
    love.graphics.setColor(1, 1, 1, 1)

    local hash = game_modes[mode_selected].hash .. "-" .. rulesets[ruleset_selected].hash
    local mode_highscore = highscores[hash]

    love.graphics.printf(
        "Tagline: "..game_modes[mode_selected].tagline,
        300, 40, 320, "left")
    if mode_highscore ~= nil then
        for key, slot in pairs(mode_highscore) do
            if key == 11 then
                break
            end
            local idx = 1
            for name, value in pairs(slot) do
                if key == 1 then
                    love.graphics.printf(name, 180 + idx * 100, 100, 100)
                end
                love.graphics.printf(tostring(value), 180 + idx * 100, 100 + 20 * key, 100)
                idx = idx + 1
            end
        end
    end

	for idx, mode in pairs(game_modes) do
		if(idx >= self.menu_mode_y / 20 - 10 and
		   idx <= self.menu_mode_y / 20 + 10) then
			local b = CursorHighlight(
				0,
				(260 - self.menu_mode_y) + 20 * idx,
				260,
				20)
			if idx == self.menu_state.mode and self.starting then
				b = self.start_frames % 10 > 4 and 0 or 1
			end
			love.graphics.setColor(1,1,b,FadeoutAtEdges(
				-self.menu_mode_y + 20 * idx + 20,
				160,
				20))
			love.graphics.printf(mode.name,
			40, (260 - self.menu_mode_y) + 20 * idx, 200, "left")
		end
	end
	for idx, ruleset in pairs(rulesets) do
		if(idx >= self.menu_ruleset_x / 120 - 3 and
		   idx <= self.menu_ruleset_x / 120 + 3) then
			local b = CursorHighlight(
				260 - self.menu_ruleset_x + 120 * idx, 440,
				120, 20)
			love.graphics.setColor(1, 1, b, FadeoutAtEdges(
				-self.menu_ruleset_x + 120 * idx,
				240,
				120)
			)
			love.graphics.printf(ruleset.name,
			260 - self.menu_ruleset_x + 120 * idx, 440, 120, "center")
		end
	end
end

function FadeoutAtEdges(input, edge_distance, edge_width)
	if input < 0 then
		input = input * -1
	end
	if input > edge_distance then
		return 1 - (input - edge_distance) / edge_width
	end
	return 1
end
function ModeSelectScene:indirectStartMode()
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
	saveConfig()
	scene = GameScene(
		game_modes[self.menu_state.mode],
		rulesets[self.menu_state.ruleset],
		self.secret_inputs
	)
end
function ModeSelectScene:onInputPress(e)
    if self.display_warning and e.input then
        scene = TitleScene()
    elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
        if self.starting then
            self.starting = false
            self.start_frames = 0
        else
            scene = TitleScene()
        end
    elseif self.starting then return
    elseif e.type == "wheel" then
        if e.x ~= 0 then
            self:changeRuleset(-e.x)
        end
        if e.y ~= 0 then
            self:changeMode(-e.y)
        end
    elseif e.input == "menu_decide" or e.scancode == "return" then
        self:indirectStartMode()
    elseif e.input == "up" or e.scancode == "up" then
        self:changeMode(-1)
        self.das_up = true
        self.das_down = nil
    elseif e.input == "down" or e.scancode == "down" then
        self:changeMode(1)
        self.das_down = true
        self.das_up = nil
    elseif e.input == "left" or e.scancode == "left" then
        self:changeRuleset(-1)
        self.das_left = true
        self.das_right = nil
    elseif e.input == "right" or e.scancode == "right" then
        self:changeRuleset(1)
        self.das_right = true
        self.das_left = nil
    elseif e.input then
        self.secret_inputs[e.input] = true
    end
end

function ModeSelectScene:onInputRelease(e)
	if e.input == "up" or e.scancode == "up" then
		self.das_up = nil
	elseif e.input == "down" or e.scancode == "down" then
		self.das_down = nil
    elseif e.input == "left" or e.scancode == "left" then
        self.das_left = nil
    elseif e.input == "right" or e.scancode == "right" then
        self.das_right = nil
	elseif e.input then
		self.secret_inputs[e.input] = false
	end
end

function ModeSelectScene:changeMode(rel)
	playSE("cursor")
	local len = #game_modes
	self.menu_state.mode = Mod1(self.menu_state.mode + rel, len)
end

function ModeSelectScene:changeRuleset(rel)
	playSE("cursor_lr")
	local len = #rulesets
	self.menu_state.ruleset = Mod1(self.menu_state.ruleset + rel, len)
end

return ModeSelectScene