local KeyConfigScene = Scene:extend()

KeyConfigScene.title = "Key Config"

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
	rotate_left2 = "Rotate CCW 2",
	rotate_right = "Rotate CW 1",
	rotate_right2 = "Rotate CW 2",
	rotate_180 = "Rotate 180",
	hold = "Hold",
	retry = "Retry",
	pause = "Pause",
	mode_exit = "Exit Mode",
}

local function newSetInputs()
	local set_inputs = {}
	for i, input in ipairs(configurable_inputs) do
		set_inputs[input] = false
	end
	return set_inputs
end

function KeyConfigScene:new()
	self.input_state = 1
	self.set_inputs = newSetInputs()
	self.new_input = {}

	if not config.input then config.input = {} end
	if config.input.keys then
		self.reconfiguration = true
		self.new_input = config.input.keys
		for input_name, key in pairs(config.input.keys) do
			self.set_inputs[input_name] = "key " .. love.keyboard.getKeyFromScancode(key) .. " (" .. key .. ")"
		end
	end

	DiscordRPC:update({
		details = "In settings",
		state = "Changing key config",
	})
end

function KeyConfigScene:update()
end

function KeyConfigScene:render()
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
		if self.key_rebinding then
			love.graphics.printf("Press key input for " .. input_naming[configurable_inputs[self.input_state]] .. ", tab to erase.", 0, 0, 640, "left")
		end
		love.graphics.printf("Press escape to exit while not rebinding. Auto-saves after you rebound a key.", 0, 20, 640, "left")
	else
		love.graphics.printf("Press key input for " .. input_naming[configurable_inputs[self.input_state]] .. ", tab to skip.", 0, 0, 640, "left")
	end
	love.graphics.printf("function keys (F1, F2, etc.), and tab can't be changed", 0, 40, 640, "left")
end

function KeyConfigScene:rebindKey(key)
	self.set_inputs[configurable_inputs[self.input_state]] = "key " .. love.keyboard.getKeyFromScancode(key) .. " (" .. key .. ")"
	self.new_input[configurable_inputs[self.input_state]] = key
end

function KeyConfigScene:refreshInputStates()
	for input_name, key in pairs(self.new_input) do
		self.set_inputs[input_name] = "key " .. love.keyboard.getKeyFromScancode(key) .. " (" .. key .. ")"
	end
end

function KeyConfigScene:onInputPress(e)
	if e.type == "key" then
		-- function keys, and tab are reserved and can't be remapped
		if e.scancode == "escape"  then
			self.esc_pressed = true
			if self.key_rebinding or not self.reconfiguration then
				self:rebindKey(e.scancode)
				playSE("mode_decide")
				if self.key_rebinding then
					self.key_rebinding = false
				else
					self.input_state = self.input_state + 1
				end
				config.input.keys = self.new_input
				saveConfig()
				return
			end
			if self.input_state > #configurable_inputs or self.reconfiguration then
				scene = InputConfigScene()
			end
		elseif self.reconfiguration then
			if self.key_rebinding then
				if e.scancode == "tab" then
					self:rebindKey(nil) --this is done by purpose
					self.set_inputs[configurable_inputs[self.input_state]] = "erased"
				else
					self:rebindKey(e.scancode)
					playSE("mode_decide")
				end
				self.key_rebinding = false
                config.input.keys = self.new_input
				saveConfig()
			else
				if e.scancode == "up" then
					playSE("cursor")
					self.input_state = Mod1(self.input_state - 1, #configurable_inputs)
				elseif e.scancode == "down" then
					playSE("cursor")
					self.input_state = Mod1(self.input_state + 1, #configurable_inputs)
				elseif e.scancode == "return" then
					playSE("main_decide")
					self.set_inputs[configurable_inputs[self.input_state]] = "<press a key>"
					self.key_rebinding = true
				end
				self.failed_input_assignment = nil
			end
		elseif self.input_state > #configurable_inputs then
			if e.scancode == "return" then
				-- save new input, then load next scene
				local had_config = config.input ~= nil
                if not config.input then config.input = {} end
                config.input.keys = self.new_input
				saveConfig()
				scene = had_config and InputConfigScene() or TitleScene()
			elseif e.scancode == "delete" or e.scancode == "backspace" then
				-- retry
				self.input_state = 1
				self.set_inputs = newSetInputs()
				self.new_input = {}
			end
		elseif e.scancode == "tab" then
			self.set_inputs[configurable_inputs[self.input_state]] = "skipped"
			self.input_state = self.input_state + 1
		else
			-- all other keys can be configured
			self:rebindKey(e.scancode)
            self.input_state = self.input_state + 1
		end
	end
end

return KeyConfigScene
