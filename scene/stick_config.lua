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
}

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

	DiscordRPC:update({
		details = "In menus",
		state = "Changing joystick config",
	})
end

function StickConfigScene:update()
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
		love.graphics.printf(input, 40, 50 + i * 20, 200, "left")
		if self.set_inputs[input] then
			love.graphics.printf(self.set_inputs[input], 240, 50 + i * 20, 300, "left")
		end
	end
	if self.input_state > table.getn(configurable_inputs) then
		love.graphics.print("press enter to confirm, delete/backspace to retry" .. (config.input and ", escape to cancel" or ""))
	else
		love.graphics.print("press joystick input for " .. configurable_inputs[self.input_state] .. ", tab to skip" .. (config.input and ", escape to cancel" or ""), 0, 0)
	end

	self.axis_timer = self.axis_timer + 1
end

local function addJoystick(input, name)
	if not input[name] then
		input[name] = {}
	end
end

function StickConfigScene:onInputPress(e)
	if e.type == "key" then
		-- function keys, escape, and tab are reserved and can't be remapped
		if e.scancode == "escape" then
			scene = InputConfigScene()
		elseif self.input_state > table.getn(configurable_inputs) then
			if e.scancode == "return" then
				-- save new input, then load next scene
				config.input.joysticks = self.new_input
				saveConfig()
				scene = InputConfigScene()
			elseif e.scancode == "delete" or e.scancode == "backspace" then
				-- retry
				self.input_state = 1
				self.set_inputs = newSetInputs()
				self.new_input = {}
			end
		elseif e.scancode == "tab" then
			self.set_inputs[configurable_inputs[self.input_state]] = "skipped"
			self.input_state = self.input_state + 1
        end
	elseif string.sub(e.type, 1, 3) == "joy" then
		if self.input_state <= table.getn(configurable_inputs) then
			if e.type == "joybutton" then
				addJoystick(self.new_input, e.name)
				if not self.new_input[e.name].buttons then
					self.new_input[e.name].buttons = {}
				end
				self.set_inputs[configurable_inputs[self.input_state]] =
					"jbtn " ..
					e.button ..
					" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
				self.new_input[e.name].buttons[e.button] = configurable_inputs[self.input_state]
				self.input_state = self.input_state + 1
			elseif e.type == "joyaxis" then
				if (e.axis ~= self.last_axis or self.axis_timer > 30) and math.abs(e.value) >= 1 then
					addJoystick(self.new_input, e.name)
					if not self.new_input[e.name].axes then
						self.new_input[e.name].axes = {}
					end
					if not self.new_input[e.name].axes[e.axis] then
						self.new_input[e.name].axes[e.axis] = {}
					end
					self.set_inputs[configurable_inputs[self.input_state]] =
						"jaxis " ..
						(e.value >= 1 and "+" or "-") .. e.axis ..
						" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
					self.new_input[e.name].axes[e.axis][e.value >= 1 and "positive" or "negative"] = configurable_inputs[self.input_state]
					self.input_state = self.input_state + 1
					self.last_axis = e.axis
					self.axis_timer = 0
				end
			elseif e.type == "joyhat" then
				if e.direction ~= "c" then
					addJoystick(self.new_input, e.name)
					if not self.new_input[e.name].hats then
						self.new_input[e.name].hats = {}
					end
					if not self.new_input[e.name].hats[e.hat] then
						self.new_input[e.name].hats[e.hat] = {}
					end
					self.set_inputs[configurable_inputs[self.input_state]] =
						"jhat " ..
						e.hat .. " " .. e.direction ..
						" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
					self.new_input[e.name].hats[e.hat][e.direction] = configurable_inputs[self.input_state]
					self.input_state = self.input_state + 1
				end
			end
		end
	end
end

return StickConfigScene
