local PlayerCardScene = Scene:extend()

local PLAYER_NAME_LENGTH_LIMIT = 16
local PLAYER_ABOUT_ME_LENGTH_LIMIT = 320

local utf8 = require "utf8"

PlayerCardScene.title = "Edit Player Card"

PlayerCardScene.options = {
	{
		title = "Edit Player Name",
		action = function (self)
			player.name = player.name or ""
			self.field_edit = "name"
			self.length_limit = PLAYER_NAME_LENGTH_LIMIT
			self.is_editing = true
			love.keyboard.setKeyRepeat(true)
		end,
	},
	{
		title = "Edit About Me",
		action = function (self)
			player.about_me = player.about_me or ""
			self.field_edit = "about_me"
			self.length_limit = PLAYER_ABOUT_ME_LENGTH_LIMIT
			self.is_editing = true
			love.keyboard.setKeyRepeat(true)
		end,
	}
}

function getPlaytimeString(playtime)
	if playtime < 60 then
		return math.floor(playtime) .. "s"
	elseif playtime < 3600 then
		return math.floor(playtime / 60).."m"
	else
		return math.floor(playtime / 3600) .. "h " .. math.floor(playtime / 60)%60 .. "m"
	end
end

local function getBlinking()
	return os.clock() % 0.5 < 0.25 and "_" or ""
end

function PlayerCardScene.renderCard(x, y, is_editing, field_name)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x, y, 320, 140, 10, 10)
	love.graphics.setColor(0.9, 0.9, 0.9)
	love.graphics.rectangle("fill", x + 2, y + 2, 316, 136, 9, 9)
	love.graphics.setColor(0.75, 0.75, 0.75)
	love.graphics.rectangle("fill", x + 4, y + 4, 312, 132, 8, 8)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	local total_playtime = 0
	for key, playtime in pairs(player.playtimes) do
		total_playtime = total_playtime + playtime
	end
	drawImage(player.profile_picture or blocks.bone_classic["W"], x + 4, y + 4, 0, 64, 64)
	if is_editing and field_name == "name" then
		love.graphics.printf(player.name .. getBlinking(), x + 70, y + 10, 160, "left")
	else
		love.graphics.printf(player.name or "<INSERT NAME>", x + 70, y + 10, 160, "left")
	end
	love.graphics.setFont(font_3x5_2)
	love.graphics.printf(getPlaytimeString(total_playtime), x + 30, y + 10, 270, "right")
	if is_editing and field_name == "about_me" then
		love.graphics.printf(player.about_me .. getBlinking(), x + 70, y + 36, 240, "left")
	else
		love.graphics.printf(player.about_me or "<insert info>", x + 70, y + 36, 240, "left")
	end
	love.graphics.setFont(font_3x5)
	love.graphics.printf(string.format("%d", player.id), x + 70, y + 2, 160, "left")
end

function PlayerCardScene:new()
	self.menu_state = 1
	self.safety_frames = 2
	DiscordRPC:update({
		details = "In menus",
		state = "Editing player info",
		largeImageKey = "settings",
	})
end

function PlayerCardScene:update()
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

function PlayerCardScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground(0)

	love.graphics.setFont(font_8x11)
	love.graphics.print("EDIT PLAYER CARD", 80, 43)

	local b = cursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf(chars.big_left, 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print("To change the profile picture, you must drag-n-drop a .PNG file\ndue to the limitations of the current framework.", 80, 90)

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 75, 248 + 40 * self.menu_state, font_3x5_3:getWidth(self.options[self.menu_state].title) + 16, 33)

	PlayerCardScene.renderCard(80, 130, true, self.is_editing, self.field_edit)

	love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(self.options) do
		local b = cursorHighlight(80,240 + 40 * i,200,40)
		love.graphics.setColor(1,1,b,1)
		love.graphics.printf(screen.title, 80, 250 + 40 * i, 200, "left")
	end
end

function PlayerCardScene:changeOption(rel)
	local len = #self.options
	self.menu_state = (self.menu_state + len + rel - 1) % len + 1
	playSE("cursor")
end

function PlayerCardScene:stopEditing()
	self.is_editing = false
	if player[self.field_edit] == "" then
		player[self.field_edit] = nil
	end
	playSE("mode_decide")
	savePlayerData()
	love.keyboard.setKeyRepeat(false)
end

function PlayerCardScene:onInputPress(e)
	if e.type == "textinput" and self.is_editing then
		player[self.field_edit] = player[self.field_edit] .. e.text
		playSE("cursor")
	end
	if self.safety_frames > 0 then return end
	if self.is_editing then
		self.safety_frames = 1
		if e.type == "key" then
			if e.scancode == "backspace" then
				local byteoffset = utf8.offset(player[self.field_edit], -1)
				if byteoffset then
					player[self.field_edit] = string.sub(player[self.field_edit], 1, byteoffset - 1)
					playSE("menu_cancel")
				end
			elseif e.scancode == "escape" or e.scancode == "return" then
				self:stopEditing()
			end
		else
			if e.input == "menu_cancel" then
				self:stopEditing()
			end
		end
		return
	end
	if e.type == "mouse" then
		if cursorHoverArea(20, 40, 50, 30) then
			playSE("menu_cancel")
			saveConfig()
			scene = RecordsScene()
		end
		if cursorHoverArea(50, 280, 200, #self.options * 40) then
			self.menu_state = math.floor((e.y - 240) / 40)
			playSE("main_decide")
			self.options[self.menu_state].action(self)
		end
	end
	if e.input == "menu_decide" then
		playSE("main_decide")
		self.options[self.menu_state].action(self)
	elseif e.input == "menu_up" then
		self:changeOption(-1)
		self.das_up = true
	elseif e.input == "menu_down" then
		self:changeOption(1)
		self.das_down = true
	elseif e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete" then
		playSE("menu_cancel")
		scene = RecordsScene()
	end
end

function PlayerCardScene:onInputRelease(e)
	if e.input == "menu_up" then
		self.das_up = false
	elseif e.input == "menu_down" then
		self.das_down = false
	end
end

return PlayerCardScene