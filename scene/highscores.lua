local HighscoreScene = Scene:extend()

HighscoreScene.title = "Highscores"

--#region Custom mouse code

--This is for mouse. Can be removed only if the code in Mouse Controls region is removed.
local left_clicked_before = true
local mouse_idle = 0
local prev_cur_pos_x, prev_cur_pos_y = 0, 0


-- For when mouse controls are part of menu controls
local function getScaledPos(cursor_x, cursor_y)
	local screen_x, screen_y = love.graphics.getDimensions()
	local scale_factor = math.min(screen_x / 640, screen_y / 480)
	return (cursor_x - (screen_x - scale_factor * 640) / 2)/scale_factor, (cursor_y - (screen_y - scale_factor * 480) / 2)/scale_factor
end

local function CursorHighlight(x,y,w,h)
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if mouse_idle > 2 or config.visualsettings.cursor_highlight ~= 1 then
		return 1
	end
	if mouse_x > x and mouse_x < x+w and mouse_y > y and mouse_y < y+h then
		if setSystemCursorType then setSystemCursorType("hand") end
		return 0
	else
		return 1
	end
end
--Interpolates in a smooth fashion unless the visual setting for scrolling is nil or off.
local function interpolateListPos(input, from)
	if config.visualsettings["smooth_scroll"] == 2 or config.visualsettings["smooth_scroll"] == nil then
		return from
	end
	if from > input then
		input = input + (from - input) / 4
		if input > from - 0.02 then
			input = from
		end
	elseif from < input then
		input = input + (from - input) / 4
		if input < from + 0.02 then
			input = from
		end
	end
	return input
end
--#endregion

function HighscoreScene:new()
    self.hash_table = {}
    for hash, value in pairs(highscores) do
        table.insert(self.hash_table, hash)
    end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(self.hash_table, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
    self.hash = nil
    self.hash_highscore = nil
    self.hash_id = 1
    self.list_pointer = 1
	self.das = 0
	self.menu_hash_y = 20
	self.menu_list_y = 20
	self.auto_menu_offset = 0

    --It's here to avoid some seems-to-be bug with the scene's built-in mouse controls.
    left_clicked_before = true
end
function HighscoreScene:update()
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
    --#region Mouse controls.
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if love.mouse.isDown(1) and not left_clicked_before then
        if self.hash == nil then
            self.auto_menu_offset = math.floor((mouse_y - 260)/20)
            if self.auto_menu_offset == 0 then
                playSE("main_decide")
                self:selectHash()
            end
        end
        if mouse_x > 20 and mouse_y > 40 and mouse_x < 70 and mouse_y < 70 then
            playSE("main_decide")
            self:back()
        end
    end
    left_clicked_before = love.mouse.isDown(1) or mouse_idle > 2
    if prev_cur_pos_x == love.mouse.getX() and prev_cur_pos_y == love.mouse.getY() then
        mouse_idle = mouse_idle + love.timer.getDelta()
    else
        mouse_idle = 0
    end
    prev_cur_pos_x, prev_cur_pos_y = love.mouse.getPosition()
    --#endregion
end
function HighscoreScene:selectHash()
    self.list_pointer = 1
    self.hash = self.hash_table[self.hash_id]
    self.hash_highscore = highscores[self.hash]
end
function HighscoreScene:render()
	love.graphics.draw(
		backgrounds[0],
		0, 0, 0,
		0.5, 0.5
	)

    love.graphics.setFont(font_3x5_4)
	local highlight = CursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, highlight, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

	if self.hash ~= nil then
		love.graphics.print("HIGHSCORE", 80, 40)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("HASH: "..self.hash, 300, 40, 320, "right")
	else
		love.graphics.print("SELECT HIGHSCORE HASH", 80, 40)
	end

    love.graphics.setFont(font_3x5_2)
    if self.hash_highscore ~= nil then
        self.menu_list_y = interpolateListPos(self.menu_list_y / 20, self.list_pointer) * 20
        love.graphics.printf("num", 20, 100, 100)
		if #self.hash_highscore > 17 then
			if self.list_pointer == #self.hash_highscore - 17 then
				love.graphics.printf("^^", 5, 450, 15)
			else
				love.graphics.printf("v", 5, 460, 15)
			end
			if self.list_pointer == 1 then
				love.graphics.printf("vv", 5, 100, 15)
			else
				love.graphics.printf("^", 5, 110, 15)
			end
		end
        for key, slot in pairs(self.hash_highscore) do
            local idx = 1
            for name, value in pairs(slot) do
                if key == 1 then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.printf(name, -20 + idx * 100, 100, 100)
                end
				love.graphics.setColor(1, 1, 1, FadeoutAtEdges((-self.menu_list_y - 170) + 20 * key, 170, 20))
                love.graphics.printf(tostring(value), -20 + idx * 100, 120 + 20 * key - self.menu_list_y, 100)
                idx = idx + 1
            end
			love.graphics.setColor(1, 1, 1, FadeoutAtEdges((-self.menu_list_y - 170) + 20 * key, 170, 20))
            love.graphics.printf(tostring(key), 20, 120 + 20 * key - self.menu_list_y, 100)
        end
    else
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", 3, 258 + (self.hash_id * 20) - self.menu_hash_y, 634, 22)
        self.menu_hash_y = interpolateListPos(self.menu_hash_y / 20, self.hash_id) * 20
        for idx, value in ipairs(self.hash_table) do
			if(idx >= self.menu_hash_y/20-10 and idx <= self.menu_hash_y/20+10) then
				local b = CursorHighlight(0, (260 - self.menu_hash_y) + 20 * idx, 640, 20)
				love.graphics.setColor(1, 1, b, FadeoutAtEdges((-self.menu_hash_y) + 20 * idx, 180, 20))
				love.graphics.printf(value, 6, (260 - self.menu_hash_y) + 20 * idx, 640, "left")	
			end
        end
    end
end

function HighscoreScene:onInputPress(e)
	if (self.display_warning or self.display_error) and e.input then
        scene = TitleScene()
	elseif e.type == "wheel" then
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif (e.input == "menu_decide" or e.scancode == "return") and self.hash == nil then
		playSE("main_decide")
		self:selectHash()
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
        self:back()
	end
end

function HighscoreScene:back()
    if self.hash then
        self.hash = nil
        self.hash_highscore = nil
    else
        scene = TitleScene()
    end
end

function HighscoreScene:onInputRelease(e)
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

function HighscoreScene:changeOption(rel)
	local len
	local old_value
	if self.hash_highscore == nil then
		len = #self.hash_table
		old_value = self.hash_id
        self.hash_id = Mod1(self.hash_id + rel, len)
		if old_value ~= self.hash_id then
			playSE("cursor")
		end
	else
		len = #self.hash_highscore
		len = math.max(len-17, 1)
		old_value = self.list_pointer
        self.list_pointer = Mod1(self.list_pointer + rel, len)
		if old_value ~= self.list_pointer then
			playSE("cursor")
		end
	end
end
return HighscoreScene