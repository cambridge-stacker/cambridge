local ReplaySelectScene = Scene:extend()

ReplaySelectScene.title = "Replays"

local binser = require 'libs.binser'

current_replay = 1

function ReplaySelectScene:new()
	-- reload custom modules
	initModules()
	-- load replays
	replays = {}
	replay_file_list = love.filesystem.getDirectoryItems("replays")
	for i=1,#replay_file_list do
		replays[i] = binser.deserialize(love.filesystem.read("replays/"..replay_file_list[i]))
	end
	-- TODO sort replays list
	if table.getn(replays) == 0 then
		self.display_warning = true
		current_replay = 1
	else
		self.display_warning = false
		if current_replay > table.getn(replays) then
			current_replay = 1
		end
	end

	self.menu_state = {
		replay = current_replay,
	}
	self.secret_inputs = {}
	self.das = 0
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a replay",
		largeImageKey = "ingame-000"
	})
end

function ReplaySelectScene:update()
	switchBGM(nil) -- experimental

	if self.das_up or self.das_down then
		self.das = self.das + 1
	else
		self.das = 0
	end

	if self.das >= 15 then
		self:changeOption(self.das_up and -1 or 1)
		self.das = self.das - 4
	end

	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a replay",
		largeImageKey = "ingame-000"
	})
end

function ReplaySelectScene:render()
	love.graphics.draw(
		backgrounds[0],
		0, 0, 0,
		0.5, 0.5
	)

	-- Same graphic as mode select
	love.graphics.draw(misc_graphics["select_mode"], 20, 40)

	if self.display_warning then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"You have no replays.",
			80, 200, 480, "center"
		)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(
			"Come back to this menu after playing some games. " ..
			"Press any button to return to the main menu.",
			80, 250, 480, "center"
		)
		return
	end

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 258, 240, 22)

	love.graphics.setFont(font_3x5_2)
	for idx, replay in pairs(replays) do
		if(idx >= self.menu_state.replay-9 and idx <= self.menu_state.replay+9) then
			local display_string = replay["mode"].." "..replay["ruleset"].." "..replay["timer"].." "..replay["level"].." "..os.date("%c", replay["timestamp"])
			love.graphics.printf(display_string, 40, (260 - 20*(self.menu_state.replay)) + 20 * idx, 200, "left")
		end
	end
end

function ReplaySelectScene:onInputPress(e)
	if self.display_warning and e.input then
		scene = TitleScene()
	elseif e.type == "wheel" then
		if e.x % 2 == 1 then
			self:switchSelect()
		end
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif e.input == "menu_decide" or e.scancode == "return" then
		current_replay = self.menu_state.replay
		-- Same as mode decide
		playSE("mode_decide")
		scene = ReplayScene(
			replays[self.menu_state.replay],
			self.secret_inputs
		)
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		self.das_up = true
		self.das_down = nil
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		self.das_down = true
		self.das_up = nil
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		scene = TitleScene()
	elseif e.input then
		self.secret_inputs[e.input] = true
	end
end

function ReplaySelectScene:onInputRelease(e)
	if e.input == "up" or e.scancode == "up" then
		self.das_up = nil
	elseif e.input == "down" or e.scancode == "down" then
		self.das_down = nil
	elseif e.input then
		self.secret_inputs[e.input] = false
	end
end

function ReplaySelectScene:changeOption(rel)
	local len = table.getn(replays)
	self.menu_state.replay = Mod1(self.menu_state.replay + rel, len)
	playSE("cursor")
end

return ReplaySelectScene
