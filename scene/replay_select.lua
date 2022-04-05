local ReplaySelectScene = Scene:extend()

ReplaySelectScene.title = "Replays"

local binser = require 'libs.binser'

local current_replay = 1

function ReplaySelectScene:new()
	-- reload custom modules
	initModules()
	-- load replays

	-- -- it's unused to avoid IO inconvenience.
	-- replays = {}
	-- replay_tree = {}
	-- dict_ref = {}
	-- for key, value in pairs(game_modes) do
	-- 	dict_ref[value.name] = key
	-- 	replay_tree[key] = {name = value.name}
	-- end
	-- local replay_file_list = love.filesystem.getDirectoryItems("replays")
	-- for i=1,#replay_file_list do
	-- 	local data = love.filesystem.read("replays/"..replay_file_list[i])
	-- 	local new_replay = binser.deserialize(data)[1]
	-- 	local mode_name = self.nilCheck(new_replay, {mode = "znil"}).mode
	-- 	replays[#replays+1] = new_replay
	-- 	if dict_ref[mode_name] ~= nil and mode_name ~= "znil" then
	-- 		table.insert(replay_tree[dict_ref[mode_name]], #replays)
	-- 	end
	-- end
	-- local function padnum(d) return ("%03d%s"):format(#d, d) end
	-- table.sort(replay_tree, function(a,b)
	-- return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	-- for key, submenu in pairs(replay_tree) do
	-- 	table.sort(submenu, function(a, b)
	-- 		return replays[a]["timestamp"] > replays[b]["timestamp"]
	-- 	end)
	-- end
	self.display_error = false
	if table.getn(replays) == 0 then
		self.display_warning = true
		current_replay = 1
	else
		self.display_warning = false
	end

	self.menu_state = {
		submenu = 0,
		replay = current_replay,
	}
	self.das = 0
	self.height_offset = 0
	self.auto_menu_offset = 0
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a replay",
		largeImageKey = "ingame-000"
	})
end


function ReplaySelectScene.nilCheck(input, default)
	if input == nil then
		return default
	end
	return input
end

function ReplaySelectScene:update()
	switchBGM(nil) -- experimental
	
	if self.das_up or self.das_down or self.das_left or self.das_right then
		self.das = self.das + 1
	else
		self.das = 0
	end

	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if love.mouse.isDown(1) and not left_clicked_before then
		if self.display_error or self.display_warning then
			scene = TitleScene()
			return
		end
		self.auto_menu_offset = math.floor((mouse_y - 260)/20)
		if self.auto_menu_offset == 0 then
			self:startReplay()
		end
	end
	if self.auto_menu_offset ~= 0 then
		self:changeOption(self.auto_menu_offset < 0 and -1 or 1)
		if self.auto_menu_offset > 0 then self.auto_menu_offset = self.auto_menu_offset - 1 end
		if self.auto_menu_offset < 0 then self.auto_menu_offset = self.auto_menu_offset + 1 end
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
	
	self.height_offset = interpolateListHeight(self.height_offset / 20, self.menu_state.replay) * 20

	-- Same graphic as mode select
	--love.graphics.draw(misc_graphics["select_mode"], 20, 40)

	love.graphics.setFont(font_3x5_4)
	if self.menu_state.submenu > 0 then
		love.graphics.print("SELECT REPLAY", 20, 35)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("MODE: "..replay_tree[self.menu_state.submenu].name, 300, 35, 320, "right")
	else
		love.graphics.print("SELECT MODE TO REPLAY", 20, 35)
	end

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
	love.graphics.rectangle("fill", 3, 258 + (self.menu_state.replay * 20) - self.height_offset, 634, 22)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	if self.menu_state.submenu == 0 then
		for idx, branch in ipairs(replay_tree) do
			if(idx >= self.height_offset/20-10 and idx <= self.height_offset/20+10) then
				local b = CursorHighlight(0, (260 - self.height_offset) + 20 * idx, 640, 20)
				love.graphics.setColor(1,1,b,FadeoutAtEdges((-self.height_offset) + 20 * idx, 180, 20))
				love.graphics.printf(branch.name, 6, (260 - self.height_offset) + 20 * idx, 640, "left")	
			end
		end
	else
		if #replay_tree[self.menu_state.submenu] == 0 then
			love.graphics.setFont(font_3x5_2)
			love.graphics.printf(
				"This submenu doesn't contain replays of this mode. ",
				80, 250, 480, "center"
			)
			return
		end
		for idx, replay_idx in ipairs(replay_tree[self.menu_state.submenu]) do
			if(idx >= self.height_offset/20-10 and idx <= self.height_offset/20+10) then
				local replay = replays[replay_idx]
				local display_string
				if replay_tree[self.menu_state.submenu].name == "Every thing" then
					display_string = os.date("%c", replay["timestamp"]).." - ".. replay["mode"].." - "..replay["ruleset"]
				else
					display_string = os.date("%c", replay["timestamp"]).." - "..replay["ruleset"]
				end
				if replay["level"] ~= nil then
					display_string = display_string.." - Level: "..replay["level"]
				end
				if replay["timer"] ~= nil then
					display_string = display_string.." - Time: "..formatTime(replay["timer"])
				end
				if #display_string > 78 then
					display_string = display_string:sub(1, 75) .. "..."
				end
				local b, g = CursorHighlight(0, (260 - self.height_offset) + 20 * idx, 640, 20), 1
				if replay["toolassisted"] then
					g = 0
					b = 0
				end
				love.graphics.setColor(1,g,b,FadeoutAtEdges((-self.height_offset) + 20 * idx, 180, 20))
				love.graphics.printf(display_string, 6, (260 - self.height_offset) + 20 * idx, 640, "left")
			end
		end
	end
end

function ReplaySelectScene:startReplay()
	if self.menu_state.submenu == 0 then
		self.menu_state.submenu = self.menu_state.replay
		self.menu_state.replay = 1
		self.height_offset = 0
		playSE("main_decide")
		return
	elseif self.menu_state.submenu > 0 then
		if #replay_tree[self.menu_state.submenu] == 0 then
			self.menu_state.submenu = 0
			self.menu_state.replay = 1
			return
		end
	end
	current_replay = self.menu_state.replay
	-- Same as mode decide
	playSE("mode_decide")
	-- Get game mode and ruleset
	local mode
	local rules
	local pointer = replay_tree[self.menu_state.submenu][self.menu_state.replay]
	for key, value in pairs(game_modes) do
		if value.name == replays[pointer]["mode"] then
			mode = value
			break
		end
	end
	for key, value in pairs(rulesets) do
		if value.name == replays[pointer]["ruleset"] then
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
		replays[pointer],
		mode,
		rules
	)
end


function ReplaySelectScene:onInputPress(e)
	if (self.display_warning or self.display_error) and e.input then
		scene = TitleScene()
	elseif e.type == "wheel" then
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif e.input == "menu_decide" or e.scancode == "return" then
		self:startReplay()
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
		if self.menu_state.submenu ~= 0 then
			self.menu_state.submenu = 0
			self.menu_state.replay = 1
			return
		end
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
	local len
	if self.menu_state.submenu == 0 then
		len = table.getn(replay_tree)
	else
		len = table.getn(replay_tree[self.menu_state.submenu])
	end
	self.menu_state.replay = Mod1(self.menu_state.replay + rel, len)
	playSE("cursor")
end

return ReplaySelectScene
