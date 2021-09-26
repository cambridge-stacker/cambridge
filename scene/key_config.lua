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
		love.graphics.printf(input, 40, 50 + i * 20, 200, "left")
		if self.set_inputs[input] then
			love.graphics.printf(self.set_inputs[input], 240, 50 + i * 20, 300, "left")
		end
	end
	if self.input_state > table.getn(configurable_inputs) then
		love.graphics.print("press enter to confirm, delete/backspace to retry" .. (config.input and ", escape to cancel" or ""))
	else
		love.graphics.print("press key input for " .. configurable_inputs[self.input_state] .. ", tab to skip, escape to cancel", 0, 0)
		love.graphics.print("function keys (F1, F2, etc.), escape, and tab can't be changed", 0, 20)
	end
end

function KeyConfigScene:onInputPress(e)
	if e.type == "key" then
		-- function keys, escape, and tab are reserved and can't be remapped
		if e.scancode == "escape" then
			scene = InputConfigScene()
		elseif self.input_state > table.getn(configurable_inputs) then
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
		elseif e.scancode ~= "escape" and not self.new_input[e.scancode] then
			-- all other keys can be configured
			self.set_inputs[configurable_inputs[self.input_state]] = "key " .. love.keyboard.getKeyFromScancode(e.scancode) .. " (" .. e.scancode .. ")"
			self.new_input[e.scancode] = configurable_inputs[self.input_state]
            self.input_state = self.input_state + 1
		end
	end
end

return KeyConfigScene
