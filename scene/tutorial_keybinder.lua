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
	menu_decide = "Menu Decide",
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
	menu_decide = "Press to select menu",
	menu_back = "Press to go back",
	left = "Move a piece to the left",
	right = "Move a piece to the right",
	up = "Hard/Sonic Drop a piece",
	down = "Soft/Sonic Drop a piece",
	rotate_left = "Rotate a piece counterclockwise",
	rotate_right = "Rotate a piece clockwise",
	rotate_180 = "Rotate a piece by 180 degrees",
	hold = "Hold a piece",
	retry = "Retry a mode/replay",
	pause = "Pause the game",
	mode_exit = "Return to the mode selection menu",
}

--A list of inputs that should have keybindings distinct from other inputs.
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

local null_joystick_name = ""

function KeyConfigScene:new()
	assert(require "tetris.modes.marathon_a3", "Missing mode: marathon_a3, required for the Tutorial Keybinder.")
	assert(require "tetris.rulesets.standard", "Missing ruleset: standard, required for the Tutorial Keybinder.")
	self.input_state = 1
	self.visual_input_state = 1

	self.axis_timer = 0
	self.joystick_name = null_joystick_name

	self.set_inputs = newSetInputs()
	self.new_input = {}

	self.nested_scene = TitleScene()

	self.failed_input_assignment_time = 0

	self.transition_time = 0
	self.transitioned = true

	if not config.input then config.input = {} end

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
				self.nested_scene = GameScene(require("tetris.modes.marathon_a3"), require("tetris.rulesets.standard"), {})
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

	love.graphics.printf(self.visual_input_state > #configurable_inputs and "You're all set!" or self.failed_input_assignment_time > 0 and "Binding conflict, press something else." or input_description[configurable_inputs[self.visual_input_state]],
	80, 200, 480, "center", 0, 1, math.min(1, math.abs(self.transition_time)))
	love.graphics.setFont(font_3x5_2)
	if self.input_mode == "key" then
		love.graphics.printf("Input mode: Keyboard",
		0, 440, 635, "right")
	elseif self.input_mode == "joy" then
		love.graphics.printf("Input mode: Controller\nName: "..self.joystick_name,
		0, 420, 635, "right")
	end
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
		self.set_inputs[configurable_inputs[self.input_state]] = "<press another key>"
		return false
	end
	self.set_inputs[configurable_inputs[self.input_state]] = self:formatKey(key)
	self.new_input[configurable_inputs[self.input_state]] = key
	return true
end

function KeyConfigScene:rebindStick(binding)
	local input_type = configurable_inputs[self.input_state]
	if binding == nil then
		self.new_input[input_type] = nil
		self.set_inputs[input_type] = "erased"
		return true
	end
	local is_invalid, existing_bind = self:mutexCheck(input_type, binding)
	if is_invalid then
		self.set_inputs[input_type] = ("<%s conflicts with %s>"):format(self.formatBinding(binding), input_naming[existing_bind])
		self.error_time = buffer_sounds.error[1]:getDuration("seconds") or 0.5
		return false
	end
	self.new_input[input_type] = binding
	if input_type == "left" or input_type == "right" or input_type == "up" or input_type == "down" then
		self.new_input["menu_"..input_type] = binding
	end
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
	if not self.input_mode then
		if e.type == "key" then
			self.input_mode = "key"
		end
		if string.sub(e.type, 1, 3) == "joy" then
			self.input_mode = "joy"
			if self.joystick_name == null_joystick_name then
				self.joystick_name = e.name
				config.input.joysticks = config.input.joysticks or {}
				if config.input.joysticks[e.name] == nil then
					config.input.joysticks[e.name] = {}
				end
				self.new_input = config.input.joysticks[e.name]
			end
		end
	end
	if e.type == "key" and self.input_mode == "key" then
		-- tab is reserved and can't be remapped
		if self.input_state > #configurable_inputs then
			if not config.input then config.input = {} end
			config.input.keys = self.new_input
			inputVersioning()
			saveConfig()
			scene = self.nested_scene
		elseif e.scancode == "tab" then
			self.failed_input_assignment_time = 120
			playSE("error")
			return
		-- all other keys can be configured
		elseif self:rebindKey(e.scancode) then
			self.transition_time = -1
			if self.input_state == 1 then
				self.nested_scene = TitleScene.menu_screens[1]()
				playSE("main_decide")
			end
			if self.input_state == 2 then
				self.transitioned = false
				self.transition_time = -3
				self.nested_scene = TitleScene()
				playSE("menu_cancel")
			end
			if self.input_state > 2 and self.input_state ~= 11 and self.input_state ~= 13 then
				local input_copy = copy(e)
				input_copy.input = configurable_inputs[self.input_state]
				self.nested_scene:onInputPress(input_copy)
			elseif self.input_state == 11 then
				self.nested_scene = GameScene(require("tetris.modes.marathon_a3"), require("tetris.rulesets.standard"), {})
			elseif self.input_state == 13 then
				local keys = self.new_input
				keys.menu_left = keys.left
				keys.menu_right = keys.right
				keys.menu_up = keys.up
				keys.menu_down = keys.down
				self.nested_scene = TitleScene.menu_screens[1]()
			end
			self.input_state = self.input_state + 1
		else
			self.failed_input_assignment_time = 120
			playSE("error")
		end
	elseif string.sub(e.type, 1, 3) == "joy" and self.input_mode == "joy" then
		if self.input_state <= #configurable_inputs and self.joystick_name == e.name then
			self.safety_frames = 2
			local is_bound = false
			if e.type == "joybutton" then
				local input_result = "buttons-" .. e.button
				if self:rebindStick(input_result) then
					is_bound = true
					self.rebinding = false
				else
					self.failed_input_assignment_time = 120
					playSE("error")
				end
			elseif e.type == "joyaxis" then
				if (e.axis ~= self.last_axis or self.axis_timer > 30) and math.abs(e.value) >= 1 then

					local input_result = "axes-" .. e.axis .. "-" .. (e.value >= 1 and "positive" or "negative")
					if self:rebindStick(input_result) then
						self.rebinding = false
						is_bound = true
					else
						self.failed_input_assignment_time = 120
						playSE("error")
					end
					self.last_axis = e.axis
					self.axis_timer = 0
				end
			elseif e.type == "joyhat" then
				if e.direction ~= "c" then
					local input_result = "hat-" .. e.hat .. "-" .. e.direction
					if self:rebindStick(input_result) then
						self.rebinding = false
						is_bound = true
					else
						self.failed_input_assignment_time = 120
						playSE("error")
					end
				end
			end
			if is_bound then
				self.transition_time = -1
				if self.input_state == 1 then
					self.nested_scene = TitleScene.menu_screens[1]()
					playSE("main_decide")
				end
				if self.input_state == 2 then
					self.transitioned = false
					self.transition_time = -3
					self.nested_scene = TitleScene()
					playSE("menu_cancel")
				end
				if self.input_state > 2 and self.input_state ~= 11 and self.input_state ~= 13 then
					local input_copy = copy(e)
					input_copy.input = configurable_inputs[self.input_state]
					self.nested_scene:onInputPress(input_copy)
				elseif self.input_state == 11 then
					self.nested_scene = GameScene(require("tetris.modes.marathon_a3"), require("tetris.rulesets.standard"), {})
				elseif self.input_state == 13 then
					local keys = self.new_input
					keys.menu_left = keys.left
					keys.menu_right = keys.right
					keys.menu_up = keys.up
					keys.menu_down = keys.down
					self.nested_scene = TitleScene.menu_screens[1]()
				end
				self.input_state = self.input_state + 1
			end
		elseif self.joystick_name == e.name then
			if not config.input then config.input = {} end
			config.input.keys = {menu_decide = "return", menu_back = "escape", up = "up", down = "down", left = "left", right = "right"}
			inputVersioning()
			saveConfig()
			scene = self.nested_scene
		end
	end
end

function KeyConfigScene:onInputRelease(e)
	local input_copy = copy(e)
	input_copy.input = configurable_inputs[self.input_state - 1]
	self.nested_scene:onInputRelease(input_copy)
end

return KeyConfigScene