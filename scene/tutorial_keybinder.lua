local KeyConfigScene = Scene:extend()

KeyConfigScene.title = "Tutorial Keybinder"

require 'load.save'

local configurable_inputs = {
	"menu_decide",
	"menu_back",
	"left",
	"right",
	"up",
	"down",
	"rotate_left",
	"rotate_right",
	"rotate_180",
	"hold",
	"retry",
	"pause",
	"mode_exit"
}

local input_naming = {
	menu_decide = "Menu Decision",
	menu_back = "Menu Back",
	left = "Move Left",
	right = "Move Right",
	up = "Hard/Sonic Drop",
	down = "Soft/Sonic Drop",
	rotate_left = "Rotate CCW 1",
	rotate_right = "Rotate CW 1",
	rotate_180 = "Rotate 180",
	hold = "Hold",
	retry = "Retry",
	pause = "Pause",
	mode_exit = "Exit Mode",
}

local input_description = {
	menu_decide = "Select menu.",
	menu_back = "Go back by pressing a key.",
	left = "Move a piece to the left",
	right = "Move a piece to the right",
	up = "Hard/Sonic Drop a piece",
	down = "Soft/Sonic Drop a piece",
	rotate_left = "Rotate a piece counterclockwise",
	rotate_right = "Rotate a piece clockwise",
	rotate_180 = "Rotate a piece in 180 degrees",
	hold = "Hold a piece",
	retry = "Retry a mode/replay",
	pause = "Pause the game",
	mode_exit = "Exit the currently playing mode",
}

--A list of inputs that shouldn't have the same keybinds with the other.
local mutually_exclusive_inputs = {
	menu_decide = "menu_back",
	left = {"right", "up", "down"},
	right = {"left", "up", "down"},
	up = {"down", "left", "right"},
	down = {"left", "up", "right"},
}

function KeyConfigScene:mutexCheck(input, keybind)
	for key, value in pairs(mutually_exclusive_inputs) do
		if key == input then
			if type(value) == "table" then
				for k2, v2 in pairs(value) do
					if self.new_input[v2] == keybind then
						return true
					end
				end
			end
			if self.new_input[value] == keybind then
				return true
			end
		elseif value == input then
			if self.new_input[key] == keybind then
				return true
			end
		end
	end
	return false
end

local function newSetInputs()
	local set_inputs = {}
	for i, input in ipairs(configurable_inputs) do
		set_inputs[input] = false
	end
	return set_inputs
end

function KeyConfigScene:new()
    if (require("tetris.modes.marathon_a3") == nil) then
        error("Missing mode: marathon_a3. It's required.")
    end
    if (require("tetris.rulesets.standard") == nil) then
        error("Missing ruleset: standard. It's required.")
    end
	self.input_state = 1
    self.visual_input_state = 1

	self.set_inputs = newSetInputs()
	self.new_input = {}

    self.nested_scene = TitleScene()

    self.failed_input_assignment_time = 0

    self.transition_time = 0
    self.transitioned = true

	if not config.input then config.input = {} end
	-- if config.input.keys then
	-- 	-- self.reconfiguration = true
	-- 	self.new_input = config.input.keys
	-- 	for input_name, key in pairs(config.input.keys) do
	-- 		self.set_inputs[input_name] = self:formatKey(key)
	-- 	end
	-- end

	self.safety_frames = 0

	DiscordRPC:update({
		details = "In settings",
		state = "Changing key config",
	})
end

function KeyConfigScene:update()
    self.nested_scene:update()
	self.safety_frames = self.safety_frames - 1
    self.failed_input_assignment_time = self.failed_input_assignment_time - 1
    self.transition_time = self.transition_time + 0.066
    if self.transition_time > 0 then
        self.visual_input_state = self.input_state
        if not self.transitioned then
            self.transitioned = true
            if self.input_state == 3 then
                self.nested_scene = GameScene(require("tetris.modes.marathon_a3"), require("tetris.rulesets.standard_exp"), {})
            end
        end
    end
end

function KeyConfigScene:render()
	-- love.graphics.setColor(1, 1, 1, 1)
	-- love.graphics.draw(
	-- 	backgrounds["input_config"],
	-- 	0, 0, 0,
	-- 	0.5, 0.5
	-- )
    self.nested_scene:render()
	love.graphics.setFont(font_3x5_4)
    love.graphics.setColor(0, 0, 0, self.transitioned and 0 or (1 - math.min(1, math.abs(self.transition_time))))
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    love.graphics.setColor(1, 1, 1)
    
    love.graphics.printf(self.visual_input_state > #configurable_inputs and "You've now configured." or self.failed_input_assignment_time > 0 and "Inaccessible key." or input_description[configurable_inputs[self.visual_input_state]], 
    80, 200, 480, "center", 0, 1, math.min(1, math.abs(self.transition_time)))

	-- for i, input in ipairs(configurable_inputs) do
	-- 	if i == self.input_state then
	-- 		love.graphics.setColor(1, 1, 0, 1)
	-- 	end
	-- 	love.graphics.printf(input_naming[input], 40, 50 + i * 20, 200, "left")
	-- 	love.graphics.setColor(1, 1, 1, 1)
	-- 	if self.set_inputs[input] then
	-- 		love.graphics.printf(self.set_inputs[input], 240, 50 + i * 20, 300, "left")
	-- 	end
	-- end
	-- if self.input_state > #configurable_inputs then
	-- 	love.graphics.print("press enter to confirm, delete/backspace to retry" .. (config.input and ", escape to cancel" or ""))
	-- 	return
	-- elseif self.failed_input_assignment then
	-- 	love.graphics.printf(string.format("%s is already assigned to %s.", self.failed_input_assignment, input_naming[self.new_input[self.failed_input_assignment]]), 0, 0, 640, "left")
	-- elseif self.reconfiguration then
	-- 	if self.key_rebinding then
	-- 		love.graphics.printf("Press key input for " .. input_naming[configurable_inputs[self.input_state]] .. ", tab to erase.", 0, 0, 640, "left")
	-- 	end
	-- 	love.graphics.printf("Press escape to exit while not rebinding. Auto-saves after you rebound a key.", 0, 20, 640, "left")
	-- else
	-- 	love.graphics.printf("Press key input for " .. input_naming[configurable_inputs[self.input_state]] .. ", tab to skip.", 0, 0, 640, "left")
	-- end
	-- love.graphics.printf("function keys (F1, F2, etc.), and tab can't be changed", 0, 40, 640, "left")
end

function KeyConfigScene:formatKey(key)
	if love.keyboard.getKeyFromScancode(key) == key then
		return "key ".. key
	else
		return "scancode " .. love.keyboard.getKeyFromScancode(key) .. ", key (" .. key .. ")"
	end
end

function KeyConfigScene:rebindKey(key)
	if key == nil then
		self.new_input[configurable_inputs[self.input_state]] = nil
		self.set_inputs[configurable_inputs[self.input_state]] = "erased"
		return true
	end
	if self:mutexCheck(configurable_inputs[self.input_state], key) then
		self.set_inputs[configurable_inputs[self.input_state]] = "<press an other key>"
		return false
	end
	self.set_inputs[configurable_inputs[self.input_state]] = self:formatKey(key)
	self.new_input[configurable_inputs[self.input_state]] = key
	return true
end

function KeyConfigScene:refreshInputStates()
	for input_name, key in pairs(self.new_input) do
		self.set_inputs[input_name] = self:formatKey(key)
	end
end
function KeyConfigScene:onInputPress(e)
	if self.safety_frames > 0 or self.transition_time < 1 then
		return
	end
	self.safety_frames = 2
	if e.type == "key" then
		-- function keys, and tab are reserved and can't be remapped
		if e.scancode == "escape" and self.input_state <= #configurable_inputs then
            self.transition_time = -1
            self:rebindKey(e.scancode)
            if self.input_state == 1 then
                self.nested_scene = config.visualsettings.mode_select_type == 2 and RevModeSelectScene() or ModeSelectScene()
                playSE("main_decide")
            end
            if self.input_state == 2 then
                self.transitioned = false
                self.nested_scene = TitleScene()
            end
            if self.input_state > 2 and self.input_state ~= 11 and self.input_state ~= 13 then
                local input_copy = copy(e)
                input_copy.input = configurable_inputs[self.input_state]
                self.nested_scene:onInputPress(input_copy)
            elseif self.input_state == 11 then
                self.nested_scene = GameScene(require("tetris.modes.marathon_a3"), require("tetris.rulesets.standard"), {})
            elseif self.input_state == 13 then
                self.nested_scene = config.visualsettings.mode_select_type == 2 and RevModeSelectScene() or ModeSelectScene()
            end
			self.input_state = self.input_state + 1
		-- elseif self.reconfiguration then
		-- 	if self.key_rebinding then
		-- 		if e.scancode == "tab" then
		-- 			self:rebindKey(nil) --this is done by purpose
		-- 		else
		-- 			if self:rebindKey(e.scancode) then
		-- 				playSE("mode_decide")
		-- 				self.key_rebinding = false
		-- 			else
		-- 				playSE("erase", "single")
		-- 			end
		-- 		end
        --         config.input.keys = self.new_input
		-- 		saveConfig()
		-- 	else
		-- 		if e.scancode == "up" then
		-- 			playSE("cursor")
		-- 			self.input_state = Mod1(self.input_state - 1, #configurable_inputs)
		-- 		elseif e.scancode == "down" then
		-- 			playSE("cursor")
		-- 			self.input_state = Mod1(self.input_state + 1, #configurable_inputs)
		-- 		elseif e.scancode == "return" then
		-- 			playSE("main_decide")
		-- 			self.set_inputs[configurable_inputs[self.input_state]] = "<press a key>"
		-- 			self.key_rebinding = true
		-- 		end
		-- 		self.failed_input_assignment = nil
		-- 	end
		elseif self.input_state > #configurable_inputs then
			if e.scancode == "return" then
				-- save new input, then load next scene
				local had_config = config.input ~= nil
                if not config.input then config.input = {} end
                config.input.keys = self.new_input
				saveConfig()
				scene = config.visualsettings.mode_select_type == 2 and RevModeSelectScene() or ModeSelectScene()
			elseif e.scancode == "delete" or e.scancode == "backspace" then
				-- retry
				self.input_state = 1
				self.set_inputs = newSetInputs()
				self.new_input = {}
			end
		elseif e.scancode == "tab" then
            self.failed_input_assignment_time = 120
            playSE("erase", "single")
            return
			-- self.set_inputs[configurable_inputs[self.input_state]] = "skipped"
			-- self.input_state = self.input_state + 1
		-- all other keys can be configured
		elseif self:rebindKey(e.scancode) then
            self.transition_time = -1
            if self.input_state == 1 then
                self.nested_scene = config.visualsettings.mode_select_type == 2 and RevModeSelectScene() or ModeSelectScene()
                playSE("main_decide")
            end
            if self.input_state == 2 then
                self.transitioned = false
                self.transition_time = -3
                self.nested_scene = TitleScene()
            end
            if self.input_state > 2 and self.input_state ~= 11 and self.input_state ~= 13 then
                local input_copy = copy(e)
                input_copy.input = configurable_inputs[self.input_state]
                self.nested_scene:onInputPress(input_copy)
            elseif self.input_state == 11 then
                self.nested_scene = GameScene(require("tetris.modes.marathon_a3"), require("tetris.rulesets.standard"), {})
            elseif self.input_state == 13 then
                self.nested_scene = config.visualsettings.mode_select_type == 2 and RevModeSelectScene() or ModeSelectScene()
            end
			self.input_state = self.input_state + 1
		else
            self.failed_input_assignment_time = 120
			playSE("erase", "single")
		end
	end
end

function KeyConfigScene:onInputRelease(e)
    local input_copy = copy(e)
    input_copy.input = configurable_inputs[self.input_state - 1]
    self.nested_scene:onInputRelease(input_copy)
end

return KeyConfigScene