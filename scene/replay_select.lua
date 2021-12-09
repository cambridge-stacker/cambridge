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
		local data = love.filesystem.read("replays/"..replay_file_list[i])
		local new_replay = binser.deserialize(data)[1]
		replays[#replays + 1] = new_replay
	end
	table.sort(replays, function(a, b)
		return a["timestamp"] > b["timestamp"]
	end)
	self.display_error = false
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
	self.das = 0
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a replay",
		largeImageKey = "ingame-000"
	})
end

function ReplaySelectScene:update()
	switchBGM(nil) -- experimental
	
	if self.das_up or self.das_down or self.das_left or self.das_right then
		self.das = self.das + 1
	else
		self.das = 0
	end

	if self.das >= 15 then
		local change = 0
		if self.das_up then
			change = -1
		elseif self.das_down then
			change = 1
		elseif self.das_left then
			change = -9
		elseif self.das_right then
			change = 9
		end
		self:changeOption(change)
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
	--love.graphics.draw(misc_graphics["select_mode"], 20, 40)

	love.graphics.setFont(font_3x5_4)
	love.graphics.print("SELECT REPLAY", 20, 35)

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
	elseif self.display_error then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"You are missing this mode or ruleset.",
			80, 200, 480, "center"
		)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(
			"Come back after getting the proper mode or ruleset. " ..
			"Press any button to return to the main menu.",
			80, 250, 480, "center"
		)
		return
	end

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 3, 258, 634, 22)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	for idx, replay in ipairs(replays) do
		if(idx >= self.menu_state.replay-9 and idx <= self.menu_state.replay+9) then
			local display_string = os.date("%c", replay["timestamp"]).."  "..replay["mode"].."  "..replay["ruleset"]
			if replay["level"] ~= nil then
				display_string = display_string.."  Level: "..replay["level"]
			end
			if replay["timer"] ~= nil then
				display_string = display_string.."  Time: "..formatTime(replay["timer"])
			end
			love.graphics.printf(display_string, 6, (260 - 20*(self.menu_state.replay)) + 20 * idx, 640, "left")
		end
	end
end

function ReplaySelectScene:onInputPress(e)
	if (self.display_warning or self.display_error) and e.input then
		scene = TitleScene()
	elseif e.type == "wheel" then
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif e.input == "menu_decide" or e.scancode == "return" then
		current_replay = self.menu_state.replay
		-- Same as mode decide
		playSE("mode_decide")
		-- Get game mode and ruleset
		local mode
		local rules
		for key, value in pairs(game_modes) do
			if value.name == replays[self.menu_state.replay]["mode"] then
				mode = value
				break
			end
		end
		for key, value in pairs(rulesets) do
			if value.name == replays[self.menu_state.replay]["ruleset"] then
				rules = value
				break
			end
		end
		if mode == nil or rules == nil then
			self.display_error = true
			return
		end
		-- TODO compare replay versions to current versions for Cambridge, ruleset, and mode
		scene = ReplayScene(
			replays[self.menu_state.replay],
			mode,
			rules,
			replays[self.menu_state.replay]["secret_inputs"]
		)
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		self.das_up = true
		self.das_down = nil
		self.das_left = nil
		self.das_right = nil
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		self.das_down = true
		self.das_up = nil
		self.das_left = nil
		self.das_right = nil
	elseif e.input == "left" or e.scancode == "left" then
		self:changeOption(-9)
		self.das_left = true
		self.das_right = nil
		self.das_up = nil
		self.das_down = nil
	elseif e.input == "right" or e.scancode == "right" then
		self:changeOption(9)
		self.das_right = true
		self.das_left = nil
		self.das_up = nil
		self.das_down = nil
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		scene = TitleScene()
	end
end

function ReplaySelectScene:onInputRelease(e)
	if e.input == "up" or e.scancode == "up" then
		self.das_up = nil
	elseif e.input == "down" or e.scancode == "down" then
		self.das_down = nil
	elseif e.input == "right" or e.scancode == "right" then
		self.das_right = nil
	elseif e.input == "left" or e.scancode == "left" then
		self.das_left = nil
	end
end

function ReplaySelectScene:changeOption(rel)
	local len = table.getn(replays)
	self.menu_state.replay = Mod1(self.menu_state.replay + rel, len)
	playSE("cursor")
end

return ReplaySelectScene
