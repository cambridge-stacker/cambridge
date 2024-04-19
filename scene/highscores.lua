local HighscoreScene = Scene:extend()

HighscoreScene.title = "Highscores"

function HighscoreScene:new()
	self.removeEmpty()
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
	self.menu_slot_positions = {}
	self.interpolated_menu_slot_positions = {}
	self.sort_type = "<"
	self.sorted_key_id = nil
	self.auto_menu_offset = 0
	self.index_count = 0

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

function HighscoreScene.removeEmpty()
	local removed_lists_count = 0
	local removed_rows_count = 0
	for hash, tbl in pairs(highscores) do
		for i = #tbl, 1, -1 do
			if (next(tbl[i]) == nil) then
				table.remove(tbl, i)
				removed_rows_count = removed_rows_count + 1
			end
		end
		if next(tbl) == nil then
			highscores[hash] = nil
			removed_lists_count = removed_lists_count + 1
		end
	end
	if removed_rows_count > 0 then
		print(("[Highscores] Removed %d empty lists and %d empty rows"):format(removed_lists_count, removed_rows_count))
	end
end

---@return table, number
function HighscoreScene.getHighscoreIndexing(hash)
	local count = 0
	local highscore_index = {}
	local highscore_reference = highscores[hash]
	if highscore_reference == nil then
		return {}, 0
	end
	for key, value in pairs(highscore_reference) do
		for k2, v2 in pairs(value) do
			if not highscore_index[k2] then
				count = count + 1
				highscore_index[k2] = count
			end
		end
	end
	return highscore_index, count
end

---@param hash string
---@param font love.Font
---@return table
function HighscoreScene.getHighscoreColumnWidths(hash, font, width_limit)
	font = font or love.graphics.getFont()
	width_limit = width_limit or 200
	local highscore_column_widths = {}
	local highscore_reference = highscores[hash]
	if highscore_reference == nil then
		return {}
	end
	local highscore_indexing = HighscoreScene.getHighscoreIndexing(hash)
	for name, idx in pairs(highscore_indexing) do
		highscore_column_widths[name] = font:getWidth(name)
	end
	for key, value in pairs(highscore_reference) do
		for k2, v2 in pairs(value) do
			highscore_column_widths[k2] = math.max(highscore_column_widths[k2], font:getWidth(v2))
		end
	end
	for key, value in pairs(highscore_column_widths) do
		highscore_column_widths[key] = math.min(width_limit, value)
	end
	return highscore_column_widths
end

---@param widths table
---@param indexing table
---@param initial_pos number
---@return table
function HighscoreScene.getHighscoreColumnPositions(widths, indexing, initial_pos)
	local positions = {initial_pos}
	local indexed_widths = {}
	for key, value in pairs(widths) do
		indexed_widths[indexing[key]] = value
	end
	for i = 2, #indexed_widths do
		positions[i] = positions[i] or 0 + positions[i-1] + indexed_widths[i-1] + 20
	end
	return positions
end

function HighscoreScene:selectHash()
	self.list_pointer = 1
	self.selected_key_id = 1
	self.sorted_key_id = nil
	self.key_sort_string = nil
	self.sort_type = "<"
	self.key_references = {}
	self.hash = self.hash_table[self.hash_id]
	self.hash_highscore = highscores[self.hash]
	self.highscore_index, self.index_count = self.getHighscoreIndexing(self.hash)
	self.highscore_column_widths = self.getHighscoreColumnWidths(self.hash, font_3x5_2)
	self.highscore_column_positions = self.getHighscoreColumnPositions(self.highscore_column_widths, self.highscore_index, 100)
	self.id_to_key = {}
	for key, value in pairs(self.highscore_index) do
		self.id_to_key[value] = key
	end
	for key, slot in pairs(self.hash_highscore) do
		self.menu_slot_positions[key] = key * 20
		self.interpolated_menu_slot_positions[key] = 0
	end
end

function HighscoreScene:sortByKey(key)
	local table_content = {}
	for k, v in pairs(self.hash_highscore) do
		table_content[k] = {id = k, value = v}
	end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	if self.sort_type ~= "" then
		table.sort(table_content, function (a, b)
			if self.sort_type == ">" then
				return tostring(a.value[key]):gsub("%d+",padnum) < tostring(b.value[key]):gsub("%d+",padnum)
			else
				return tostring(a.value[key]):gsub("%d+",padnum) > tostring(b.value[key]):gsub("%d+",padnum)
			end
		end)
	end
	for k, v in pairs(table_content) do
		self.menu_slot_positions[v.id] = k * 20
	end
	self.key_sort_string = self.sort_type == "<" and "v" or self.sort_type == ">" and "^" or ""
	self.sort_type = self.sort_type == "<" and ">" or self.sort_type == ">" and "" or "<"
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
	if type(self.hash_highscore) == "table" then
		self.menu_list_y = interpolateNumber(self.menu_list_y / 20, self.list_pointer) * 20
		love.graphics.printf("num", 20, 100, 100)
		if #self.hash_highscore > 17 then
			if self.list_pointer == #self.hash_highscore - 16 then
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
		for name, idx in pairs(self.highscore_index) do
			local column_x = self.highscore_column_positions[idx]
			local column_w = self.highscore_column_widths[name]
			local b = cursorHighlight(-25 + column_x, 100, column_w + 20, 20)
			if self.selected_key_id == idx then
				b = 0
			end
			love.graphics.setColor(1, 1, b, 1)
			drawWrappingText(name, -20 + column_x, 100, column_w, "left")
			love.graphics.line(-25 + column_x, 100, -25 + column_x, 480)
		end
		for key, slot in pairs(self.hash_highscore) do
			self.interpolated_menu_slot_positions[key] = interpolateNumber(self.interpolated_menu_slot_positions[key], self.menu_slot_positions[key])
			local slot_y = self.interpolated_menu_slot_positions[key]
			if slot_y > -20 + self.menu_list_y and
			   slot_y < 360 + self.menu_list_y then
				local text_alpha = fadeoutAtEdges((-self.menu_list_y - 170) + slot_y, 170, 20)
				for name, value in pairs(slot) do
					local idx = self.highscore_index[name]
					love.graphics.setColor(1, 1, 1, text_alpha)
					local formatted_string = toFormattedValue(value)
					local column_x = self.highscore_column_positions[idx]
					drawWrappingText(tostring(formatted_string), -20 + column_x, 120 + slot_y - self.menu_list_y, self.highscore_column_widths[name], "left")
				end
				love.graphics.setColor(1, 1, 1, text_alpha)
				love.graphics.printf(tostring(key), 20, 120 + slot_y - self.menu_list_y, 100)
			end
		end
		love.graphics.setColor(1, 1, 1, 1)
		if type(self.sorted_key_id) == "number" then
			love.graphics.printf(self.key_sort_string, -30 + self.highscore_column_positions[self.sorted_key_id], 100, 90)
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
		else
			local old_key_id = self.sorted_key_id
			for name, idx in pairs(self.highscore_index) do
				if cursorHoverArea(self.highscore_column_positions[idx] - 25, 100, self.highscore_column_widths[name] + 20, 20) then
					playSE("cursor_lr")
					self.sorted_key_id = idx
					if self.sorted_key_id ~= old_key_id then
						self.sort_type = "<"
					end
					self:sortByKey(self.id_to_key[self.sorted_key_id])
				end
			end
		end
		if cursorHoverArea(20, 40, 50, 30) then
			self:back()
		end
	elseif (e.input == "menu_decide") and self.hash == nil then
		playSE("main_decide")
		self:selectHash()
	elseif e.input == "menu_decide" and self.hash ~= nil and self.index_count > 0 then
		playSE("cursor_lr")
		self.sorted_key_id = self.selected_key_id
		self:sortByKey(self.id_to_key[self.selected_key_id])
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
		self.menu_slot_positions = {}
		self.interpolated_menu_slot_positions = {}
		self.index_count = 0
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
	if math.abs(rel) == 9 and self.index_count > 0 then
		self.sort_type = "<"
		len = self.index_count
		old_value = self.selected_key_id
		self.selected_key_id = Mod1(self.selected_key_id + rel / 9, len)
		if old_value ~= self.selected_key_id then
			playSE("cursor")
		end
		return
	end
	if self.hash_highscore == nil then
		len = #self.hash_table
		old_value = self.hash_id
		self.hash_id = Mod1(self.hash_id + rel, len)
		if old_value ~= self.hash_id then
			playSE("cursor")
		end
	else
		len = #self.hash_highscore
		len = math.max(len-16, 1)
		old_value = self.list_pointer
		self.list_pointer = Mod1(self.list_pointer + rel, len)
		if old_value ~= self.list_pointer then
			playSE("cursor")
		end
	end
end
return HighscoreScene