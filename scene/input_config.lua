local ConfigScene = Scene:extend()

ConfigScene.title = "Input Config"

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
}

local function newSetInputs()
	local set_inputs = {}
	for i, input in ipairs(configurable_inputs) do
		set_inputs[input] = false
	end
	return set_inputs
end

function ConfigScene:new()
	self.input_state = 1
	self.set_inputs = newSetInputs()
	self.new_input = {}
	self.axis_timer = 0

	DiscordRPC:update({
		details = "In menus",
		state = "Changing input config",
	})
end

function ConfigScene:update()
end

function ConfigScene:render()
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
		love.graphics.print("press key or joystick input for " .. configurable_inputs[self.input_state] .. ", tab to skip" .. (config.input and ", escape to cancel" or ""), 0, 0)
		love.graphics.print("function keys (F1, F2, etc.), escape, and tab can't be changed", 0, 20)
	end

	self.axis_timer = self.axis_timer + 1
end

local function addJoystick(input, name)
	if not input.joysticks then
		input.joysticks = {}
	end
	if not input.joysticks[name] then
		input.joysticks[name] = {}
	end
end

function ConfigScene:onInputPress(e)
	if e.type == "key" then
		-- function keys, escape, and tab are reserved and can't be remapped
		if e.scancode == "escape" and config.input then
			-- cancel only if there was an input config already
			scene = TitleScene()
		elseif self.input_state > table.getn(configurable_inputs) then
			if e.scancode == "return" then
				-- save new input, then load next scene
				config.input = self.new_input
				saveConfig()
				scene = TitleScene()
			elseif e.scancode == "delete" or e.scancode == "backspace" then
				-- retry
				self.input_state = 1
				self.set_inputs = newSetInputs()
				self.new_input = {}
			end
		elseif e.scancode == "tab" then
			self.set_inputs[configurable_inputs[self.input_state]] = "skipped"
			self.input_state = self.input_state + 1
		elseif e.scancode ~= "escape" then
			-- all other keys can be configured
			if not self.new_input.keys then
				self.new_input.keys = {}
			end
			self.set_inputs[configurable_inputs[self.input_state]] = "key " .. love.keyboard.getKeyFromScancode(e.scancode) .. " (" .. e.scancode .. ")"
			self.new_input.keys[e.scancode] = configurable_inputs[self.input_state]
			self.input_state = self.input_state + 1
		end
	elseif string.sub(e.type, 1, 3) == "joy" then
		if self.input_state <= table.getn(configurable_inputs) then
			if e.type == "joybutton" then
				addJoystick(self.new_input, e.name)
				if not self.new_input.joysticks[e.name].buttons then
					self.new_input.joysticks[e.name].buttons = {}
				end
				self.set_inputs[configurable_inputs[self.input_state]] =
					"jbtn " ..
					e.button ..
					" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
				self.new_input.joysticks[e.name].buttons[e.button] = configurable_inputs[self.input_state]
				self.input_state = self.input_state + 1
			elseif e.type == "joyaxis" then
				if (e.axis ~= self.last_axis or self.axis_timer > 30) and math.abs(e.value) >= 1 then
					addJoystick(self.new_input, e.name)
					if not self.new_input.joysticks[e.name].axes then
						self.new_input.joysticks[e.name].axes = {}
					end
					if not self.new_input.joysticks[e.name].axes[e.axis] then
						self.new_input.joysticks[e.name].axes[e.axis] = {}
					end
					self.set_inputs[configurable_inputs[self.input_state]] =
						"jaxis " ..
						(e.value >= 1 and "+" or "-") .. e.axis ..
						" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
					self.new_input.joysticks[e.name].axes[e.axis][e.value >= 1 and "positive" or "negative"] = configurable_inputs[self.input_state]
					self.input_state = self.input_state + 1
					self.last_axis = e.axis
					self.axis_timer = 0
				end
			elseif e.type == "joyhat" then
				if e.direction ~= "c" then
					addJoystick(self.new_input, e.name)
					if not self.new_input.joysticks[e.name].hats then
						self.new_input.joysticks[e.name].hats = {}
					end
					if not self.new_input.joysticks[e.name].hats[e.hat] then
						self.new_input.joysticks[e.name].hats[e.hat] = {}
					end
					self.set_inputs[configurable_inputs[self.input_state]] =
						"jhat " ..
						e.hat .. " " .. e.direction ..
						" " .. string.sub(e.name, 1, 10) .. (string.len(e.name) > 10 and "..." or "")
					self.new_input.joysticks[e.name].hats[e.hat][e.direction] = configurable_inputs[self.input_state]
					self.input_state = self.input_state + 1
				end
			end
		end
	end
end

return ConfigScene
