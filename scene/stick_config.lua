local StickConfigScene = Scene:extend()

StickConfigScene.title = "Joystick Config"

require 'load.save'

local configurable_inputs = {
	"menu_decide",
	"menu_back",
	"left",
	"right",
	"up",
	"down",
	"rotate_left",
	"rotate_left2",
	"rotate_right",
	"rotate_right2",
	"rotate_180",
	"hold",
	"retry",
	"pause",
	"mode_exit",
}
local input_naming = {
	menu_decide = "Menu Decision",
	menu_back = "Menu Back",
	left = "Move Left",
	right = "Move Right",
	up = "Hard/Sonic Drop",
	down = "Soft/Sonic Drop",
	rotate_left = "Rotate CCW 1",
	rotate_left2 = "Rotate CCW 2",
	rotate_right = "Rotate CW 1",
	rotate_right2 = "Rotate CW 2",
	rotate_180 = "Rotate 180",
	hold = "Hold",
	retry = "Retry",
	pause = "Pause",
	mode_exit = "Exit Mode",
}
--A list of inputs that shouldn't have the same keybinds with the other.
local mutually_exclusive_inputs = {
	menu_decide = "menu_back"
}

function StickConfigScene:mutexCheck(input, binding)
	for key, value in pairs(mutually_exclusive_inputs) do
		if key == input then
			if self.new_input[value] == binding then
				return true
			end
		else
			if self.new_input[key] == binding then
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

function StickConfigScene:new()
	self.input_state = 1
	self.set_inputs = newSetInputs()
	self.new_input = {}
	self.axis_timer = 0

	if not config.input then config.input = {} end
	if config.input.joysticks then
		self.reconfiguration = true
		self.new_input = config.input.joysticks
		for input_name, binding in pairs(config.input.joysticks) do
			self.set_inputs[input_name] = self:formatBinding(binding)
		end
	end

	self.safety_frames = 0

	DiscordRPC:update({
		details = "In settings",
		state = "Changing joystick config",
	})
end
--too many impl details and substrings
function StickConfigScene:formatBinding(binding)
	local joy_name = binding:sub(1, binding:find("-") - 1)
	local substring = binding:sub(binding:find("-") + 1, #binding)
	local secondmid_substring = substring:sub(1, substring:find("-") - 1)
	local second_substring = substring:sub(substring:find("-") + 1, #substring)
	if secondmid_substring == "buttons" then
		return "Button " ..
		second_substring ..
		" " .. joy_name
	elseif secondmid_substring == "hat" then
		local thirdmid_substring = second_substring:sub(1, second_substring:find("-") - 1)
		local third_substring = second_substring:sub(second_substring:find("-") + 1)
		return "Hat " ..
		thirdmid_substring .. " " .. third_substring ..
		" " .. joy_name
	elseif secondmid_substring == "axes" then
		local third_substring = second_substring:sub(1, second_substring:find("-") - 1)
		return "Axis " ..
		(second_substring == "positive" and "+" or "-") .. second_substring ..
		" " .. joy_name
	end
	return "Missing"
end

function StickConfigScene:update()
	self.safety_frames = self.safety_frames - 1
end

function StickConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds["input_config"],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.setFont(font_3x5_2)
	for i, input in ipairs(configurable_inputs) do
		if i == self.input_state then
			love.graphics.setColor(1, 1, 0, 1)
		end
		love.graphics.printf(input_naming[input], 40, 50 + i * 20, 200, "left")
		love.graphics.setColor(1, 1, 1, 1)
		if self.set_inputs[input] then
			love.graphics.printf(self.set_inputs[input], 240, 50 + i * 20, 300, "left")
		end
	end
	if self.input_state > #configurable_inputs then
		love.graphics.print("press enter to confirm, delete/backspace to retry" .. (config.input and ", escape to cancel" or ""))
		return
	elseif self.failed_input_assignment then
		love.graphics.printf(string.format("%s is already assigned to %s.", self.failed_input_assignment, input_naming[self.new_input[self.failed_input_assignment]]), 0, 0, 640, "left")
	elseif self.reconfiguration then
		if self.rebinding then
			love.graphics.printf("Press joystick input for " .. input_naming[configurable_inputs[self.input_state]] .. ", tab to erase.", 0, 0, 640, "left")
		end
		love.graphics.printf("Press escape to exit while not rebinding. Auto-saves after you rebound an input.", 0, 20, 640, "left")
	else
		love.graphics.printf("Press joystick input for " .. input_naming[configurable_inputs[self.input_state]] .. ", tab to skip.", 0, 0, 640, "left")
	end

	self.axis_timer = self.axis_timer + 1
end

function StickConfigScene:rebind(binding)
	if binding == nil then
		self.new_input[configurable_inputs[self.input_state]] = nil
		self.set_inputs[configurable_inputs[self.input_state]] = "erased"
		return true
	end
	if self:mutexCheck(configurable_inputs[self.input_state], binding) then
		self.set_inputs[configurable_inputs[self.input_state]] = "<provide an other joystick input>"
		return false
	end
	self.set_inputs[configurable_inputs[self.input_state]] = self:formatBinding(binding)
	self.new_input[configurable_inputs[self.input_state]] = binding
	return true
end

local function addJoystick(input, name)
	if not input[name] then
		input[name] = {}
	end
end

function StickConfigScene:onInputPress(e)
	if self.safety_frames > 0 then
		return
	end
	self.safety_frames = 2
	if e.type == "key" then
		-- function keys, escape, and tab are reserved and can't be remapped
		if e.scancode == "escape" then
			scene = InputConfigScene()
		elseif self.input_state > #configurable_inputs then
			if e.scancode == "return" then
				-- save new input, then load next scene
				local had_config = config.input ~= nil
                if not config.input then config.input = {} end
                config.input.joysticks = self.new_input
				saveConfig()
				scene = had_config and InputConfigScene() or TitleScene()
			elseif e.scancode == "delete" or e.scancode == "backspace" then
				-- retry
				self.input_state = 1
				self.set_inputs = newSetInputs()
				self.new_input = {}
			end
		elseif self.reconfiguration then
			if self.rebinding then
				if e.scancode == "tab" then
					self:rebind(nil) --this is done on purpose
				end
			else
				if e.scancode == "up" or e.direction == "u" then
					playSE("cursor")
					self.input_state = Mod1(self.input_state - 1, #configurable_inputs)
				elseif e.scancode == "down" or e.direction == "d" then
					playSE("cursor")
					self.input_state = Mod1(self.input_state + 1, #configurable_inputs)
				elseif e.scancode == "return" then
					playSE("main_decide")
					self.set_inputs[configurable_inputs[self.input_state]] = "<provide joystick input>"
					self.rebinding = true
				end
				self.failed_input_assignment = nil
			end
		elseif e.scancode == "tab" then
			self.set_inputs[configurable_inputs[self.input_state]] = "skipped"
			self.input_state = self.input_state + 1
        end
	elseif string.sub(e.type, 1, 3) == "joy" then
		if self.input_state <= #configurable_inputs and (not self.reconfiguration or self.rebinding) then
			if e.type == "joybutton" then
				-- if not self.new_input[e.name].buttons then
				-- 	self.new_input[e.name].buttons = {}
				-- end
				-- if self.new_input[e.name].buttons[e.button] then return end
				local input_result = e.name .. "-buttons-" .. e.button
				if self:rebind(input_result) then
					playSE("mode_decide")
					self.rebinding = false
				else
					playSE("erase", "single")
				end
				if not self.reconfiguration then
					self.input_state = self.input_state + 1
				end
			elseif e.type == "joyaxis" then
				if (e.axis ~= self.last_axis or self.axis_timer > 30) and math.abs(e.value) >= 1 then
					-- if not self.new_input[e.name].axes then
					-- 	self.new_input[e.name].axes = {}
					-- end
					-- if not self.new_input[e.name].axes[e.axis] then
					-- 	self.new_input[e.name].axes[e.axis] = {}
					-- end
					-- if (
					-- 	self.new_input[e.name].axes[e.axis][e.value >= 1 and "positive" or "negative"]
					-- ) then return end

					local input_result = e.name .. "-axes-" .. e.axis .. "-" .. (e.value >= 1 and "positive" or "negative")
					if self:rebind(input_result) then
						playSE("mode_decide")
						self.rebinding = false
					else
						playSE("erase", "single")
					end
					if not self.reconfiguration then
						self.input_state = self.input_state + 1
					end
					self.last_axis = e.axis
					self.axis_timer = 0
				end
			elseif e.type == "joyhat" then
				if e.direction ~= "c" then
					self.set_inputs[configurable_inputs[self.input_state]] =
						"Hat " ..
						e.hat .. " " .. e.direction ..
						" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
					local input_result = e.name .. "-hat-" .. e.hat .. "-" .. e.direction
					if self:rebind(input_result) then
						playSE("mode_decide")
						self.rebinding = false
					else
						playSE("erase", "single")
					end
					if not self.reconfiguration then
						self.input_state = self.input_state + 1
					end
				end
			end
		end
	end
end

return StickConfigScene
