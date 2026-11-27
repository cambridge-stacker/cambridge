local CardSectionEditorScene = Scene:extend()

CardSectionEditorScene.title = "Edit Card Sections"

CardSectionEditorScene.options = {
	{
		title = "Edit Section 1",
		action = function (self)
			self.selecting_card_section = true
		end,
	},
	{
		title = "Edit Section 2",
		action = function (self)
			self.selecting_card_section = true
		end,
	},
	{
		title = "Edit Section 3",
		action = function (self)
			self.selecting_card_section = true
		end,
	},
	{
		title = "Edit Section 4",
		action = function (self)
			self.selecting_card_section = true
		end,
	},
}

function CardSectionEditorScene:new()
	self.menu_state = 1
	self.menu_card_state = 1
	self.safety_frames = 2
	self.selecting_card_section = false

	self.menu_card_y = 0

	self:sortCardSectionPointers()
	DiscordRPC:update({
		details = "In menus",
		state = "Editing player info",
		largeImageKey = "settings",
	})
end

function CardSectionEditorScene:sortCardSectionPointers()
	self.card_section_pointers = {}
	for key, _ in pairs(player.mode_sections) do
		table.insert(self.card_section_pointers, key)
	end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(self.card_section_pointers, function (a, b)
		return tostring(a):gsub("%d+",padnum) < tostring(b):gsub("%d+",padnum)
	end)
end

function CardSectionEditorScene:update()
	self.safety_frames = self.safety_frames - 1
	if self.das_up or self.das_down then
		self.das = self.das + 1
	else
		self.das = 0
	end
	if self.das >= config.menu_das then
		local change = 0
		if self.das_up then
			change = -1
		elseif self.das_down then
			change = 1
		end
		self:changeOption(change)
		self.das = self.das - config.menu_arr
	end
end

function CardSectionEditorScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground(0)

	love.graphics.setFont(font_8x11)
	love.graphics.print("EDIT CARD SECTIONS", 80, 43)

	local b = cursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf(chars.big_left, 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print("Pick the sections that you're proud of!", 80, 90)

	self.menu_card_y = interpolateNumber(self.menu_card_y, self.menu_card_state * 40 - 160)

	love.graphics.setColor(1, 1, 1, 0.5)
	if self.selecting_card_section then
		love.graphics.rectangle("fill", 455, 37.5 + 40 * self.menu_card_state - self.menu_card_y, 170, 40)
	else
		love.graphics.rectangle("fill", 75, 248 + 40 * self.menu_state, font_3x5_3:getWidth(self.options[self.menu_state].title) + 16, 33)
	end

	PlayerCardScene.renderCard(80, 130, nil, nil, self.menu_state)


	love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(self.options) do
		local b = cursorHighlight(80,240 + 40 * i,200,40)
		love.graphics.setColor(1,1,b,1)
		love.graphics.print(screen.title, 80, 250 + 40 * i)
	end
	PlayerCardScene.renderCardSection(460, 40 - self.menu_card_y, nil, self.selecting_card_section and (cursorHighlight(460, 40 - self.menu_card_y, 120, 40) == 0 or self.menu_card_state == 0), fadeoutAtEdges(- self.menu_card_y -220, 220, 20))
	for id, key in pairs(self.card_section_pointers) do
		PlayerCardScene.renderCardSection(460, 40 - self.menu_card_y + 40 * id, player.mode_sections[key], 
		self.selecting_card_section and (cursorHighlight(460, 40 - self.menu_card_y + 40 * id, 120, 40) == 0 or self.menu_card_state == id), fadeoutAtEdges(40 * id - self.menu_card_y - 160, 160, 20))
	end
end

function CardSectionEditorScene:changeOption(rel)
	if self.selecting_card_section then
		local len = #self.card_section_pointers
		self.menu_card_state = (self.menu_card_state + rel) % (len + 1)
	else
		local len = #self.options
		self.menu_state = (self.menu_state + len + rel - 1) % len + 1
	end
	playSE("cursor")
end

function CardSectionEditorScene:onDecide()
	playSE("main_decide")
	if self.selecting_card_section then
		self.selecting_card_section = false
		if self.menu_card_state == 0 then
			player.selected_sections[self.menu_state] = nil
			return
		end
		player.selected_sections[self.menu_state] = self.card_section_pointers[self.menu_card_state]
	else
		self.options[self.menu_state].action(self)
		if player.selected_sections[self.menu_state] == nil then
			return
		end
		for index, value in pairs(self.card_section_pointers) do
			if value == player.selected_sections[self.menu_state] then
				self.menu_card_state = index
				return
			end
		end
	end
end

function CardSectionEditorScene:onInputPress(e)
	if self.safety_frames > 0 then return end
	if e.type == "mouse" then
		if cursorHoverArea(20, 40, 50, 30) then
			playSE("menu_cancel")
			if self.selecting_card_section then
				self.selecting_card_section = false
				return
			end
			savePlayerData()
			scene = PlayerCardScene()
		end
		if self.selecting_card_section and cursorHoverArea(460, 40 - self.menu_card_y, 120, #self.card_section_pointers * 40 + 40) then
			local previous_state = self.menu_card_state
			self.menu_card_state = math.floor(((e.y + self.menu_card_y) - 40) / 40)
			if previous_state == self.menu_card_state then
				self:onDecide()
			else
				playSE("cursor")
			end
		elseif not self.selecting_card_section and cursorHoverArea(50, 280, 200, #self.options * 40) then
			self.menu_state = math.floor((e.y - 240) / 40)
			self:onDecide()
		end
	elseif e.type == "wheel" then
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	end
	if e.input == "menu_decide" then
		self:onDecide()
	elseif e.input == "menu_up" then
		self:changeOption(-1)
		self.das_up = true
	elseif e.input == "menu_down" then
		self:changeOption(1)
		self.das_down = true
	elseif e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete" then
		playSE("menu_cancel")
		if self.selecting_card_section then
			self.selecting_card_section = false
			return
		end
		savePlayerData()
		scene = PlayerCardScene()
	end
end

function CardSectionEditorScene:onInputRelease(e)
	if e.input == "menu_up" then
		self.das_up = false
	elseif e.input == "menu_down" then
		self.das_down = false
	end
end

return CardSectionEditorScene