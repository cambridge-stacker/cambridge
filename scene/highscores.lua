local HighscoreScene = Scene:extend()

HighscoreScene.title = "Highscores"

function HighscoreScene:new()
    self.hash_table = {}
    for hash, value in pairs(highscores) do
        table.insert(self.hash_table, hash)
    end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(self.hash_table, function(a,b)
	return tostring(a):gsub("%d+",padnum) < tostring(b):gsub("%d+",padnum) end)
    self.hash = nil
    self.hash_highscore = nil
    self.hash_id = 1
    self.list_pointer = 1
	self.das = 0
	self.menu_hash_y = 20
	self.menu_list_y = 20
	self.auto_menu_offset = 0

	DiscordRPC:update({
		details = "In menus",
		state = "Peeking their own highscores",
		largeImageKey = "ingame-000"
	})
end
function HighscoreScene:update()
	if self.auto_menu_offset ~= 0 then
		self:changeOption(self.auto_menu_offset < 0 and -1 or 1)
		if self.auto_menu_offset > 0 then self.auto_menu_offset = self.auto_menu_offset - 1 end
		if self.auto_menu_offset < 0 then self.auto_menu_offset = self.auto_menu_offset + 1 end
	end
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
end
function HighscoreScene:selectHash()
    self.list_pointer = 1
    self.hash = self.hash_table[self.hash_id]
    self.hash_highscore = highscores[self.hash]
end
--Takes cares of both normal numbers and bigints.
local function toFormattedValue(value)
	
	if type(value) == "table" and value.digits and value.sign then
		local num = ""
		if value.sign == "-" then
			num = "-"
		end
		for id, digit in pairs(value.digits) do
			if not value.dense or id == 1 then
				num = num .. math.floor(digit) -- lazy way of getting rid of .0$
			else
                num = num .. string.format("%07d", digit)
			end
		end
		return num
	end
	return tostring(value)
end
function HighscoreScene:render()
	drawBackground(0)

    love.graphics.setFont(font_3x5_4)
	local highlight = cursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, highlight, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(font_8x11)
	if self.hash ~= nil then
		love.graphics.print("HIGHSCORE", 80, 43)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("HASH: "..self.hash, 300, 43, 320, "right")
	else
		love.graphics.print("SELECT HIGHSCORE HASH", 80, 43)
	end

    love.graphics.setFont(font_3x5_2)
    if self.hash_highscore ~= nil then
        self.menu_list_y = interpolateNumber(self.menu_list_y / 20, self.list_pointer) * 20
        love.graphics.printf("num", 20, 100, 100)
		if #self.hash_highscore > 18 then
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
				love.graphics.setColor(1, 1, 1, fadeoutAtEdges((-self.menu_list_y - 170) + 20 * key, 170, 20))
				local formatted_string = toFormattedValue(value)
				if love.graphics.getFont():getWidth(formatted_string) > 100 then
					formatted_string = formatted_string:sub(1, 6-math.floor(math.log10(#formatted_string))).."...".."("..#formatted_string..")"
				end
                love.graphics.printf(formatted_string, -20 + idx * 100, 120 + 20 * key - self.menu_list_y, 100)
                idx = idx + 1
            end
			love.graphics.setColor(1, 1, 1, fadeoutAtEdges((-self.menu_list_y - 170) + 20 * key, 170, 20))
            love.graphics.printf(tostring(key), 20, 120 + 20 * key - self.menu_list_y, 100)
        end
    else
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", 3, 258 + (self.hash_id * 20) - self.menu_hash_y, 634, 22)
        self.menu_hash_y = interpolateNumber(self.menu_hash_y / 20, self.hash_id) * 20
        for idx, value in ipairs(self.hash_table) do
			if(idx >= self.menu_hash_y/20-10 and idx <= self.menu_hash_y/20+10) then
				local b = cursorHighlight(0, (260 - self.menu_hash_y) + 20 * idx, 640, 20)
				love.graphics.setColor(1, 1, b, fadeoutAtEdges((-self.menu_hash_y) + 20 * idx, 180, 20))
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
	elseif e.type == "mouse" and e.button == 1 then
        if self.hash == nil then
            self.auto_menu_offset = math.floor((e.y - 260)/20)
            if self.auto_menu_offset == 0 then
                playSE("main_decide")
                self:selectHash()
            end
        end
        if e.x > 20 and e.y > 40 and e.x < 70 and e.y < 70 then
            self:back()
        end
	elseif (e.input == "menu_decide") and self.hash == nil then
		playSE("main_decide")
		self:selectHash()
	elseif e.input == "menu_up" then
		self:changeOption(-1)
		self.das_up = true
		self.das_down = nil
		self.das_left = nil
		self.das_right = nil
	elseif e.input == "menu_down" then
		self:changeOption(1)
		self.das_down = true
		self.das_up = nil
		self.das_left = nil
		self.das_right = nil
	elseif e.input == "menu_left" then
		self:changeOption(-9)
		self.das_left = true
		self.das_right = nil
		self.das_up = nil
		self.das_down = nil
	elseif e.input == "menu_right" then
		self:changeOption(9)
		self.das_right = true
		self.das_left = nil
		self.das_up = nil
		self.das_down = nil
	elseif e.input == "menu_back" then
        self:back()
	end
end

function HighscoreScene:back()
	playSE("menu_cancel")
    if self.hash then
		self.menu_list_y = 20
        self.hash = nil
        self.hash_highscore = nil
    else
        scene = TitleScene()
    end
end

function HighscoreScene:onInputRelease(e)
	if e.input == "menu_up" then
		self.das_up = nil
	elseif e.input == "menu_down" then
		self.das_down = nil
	elseif e.input == "menu_right" then
		self.das_right = nil
	elseif e.input == "menu_left" then
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