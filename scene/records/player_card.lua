local PlayerCardScene = Scene:extend()

local PLAYER_NAME_LENGTH_LIMIT = 16
local PLAYER_ABOUT_ME_LENGTH_LIMIT = 200

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
	},
	{
		title = "Edit Card Sections",
		action = function (self)
			scene = CardSectionEditorScene()
		end
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

-- this is incredibly hacky. what the hell, girl?
function getTimestampDifference(timestamp)
	local difftime = os.difftime(os.time(), timestamp)
	local osdate_table = os.date("!*t", difftime)
	if difftime < 120 then
		return "Just now"
	elseif difftime < 120 * 60 then
		return math.floor(difftime / 60) .. " minutes ago"
	elseif difftime < 120 * 60 * 24 then
		return math.floor(difftime / 3600) .. " hours ago"
	elseif difftime < 120 * 60 * 24 * 60 then
		return math.floor(difftime / 86400) .. " days ago"
	elseif osdate_table.year < 1971 then
		return math.floor(osdate_table.month-1) .. " months ago"
	else
		return string.format("%d year%s ago", math.floor(osdate_table.year - 1970), math.floor(osdate_table.year - 1970) > 1 and "s" or "")
	end

end

print(getTimestampDifference(os.time() - 160000000))

local function getBlinking()
	return os.clock() % 0.5 < 0.25 and "_" or " "
end

function PlayerCardScene.renderCardSection(x, y, section, highlighted, alpha)
	alpha = alpha or 1
	love.graphics.setColor(0.5, 0.5, 0.5, alpha ^ 3)
	love.graphics.rectangle("fill", x, y, 160, 35, 3, 3)
	love.graphics.setColor(0.6, 0.6, 0.6, alpha ^ 3)
	love.graphics.rectangle("fill", x + 1, y + 1, 158, 33, 2, 2)
	love.graphics.setColor(0.75, 0.75, 0.75, alpha ^ 3)
	love.graphics.rectangle("fill", x + 2, y + 2, 156, 31, 1, 1)
	if section == nil then
		love.graphics.setFont(font_3x5_2)
		love.graphics.setColor(0.5, 0.5, highlighted and 0 or 0.5, alpha)
		love.graphics.print("<INSERT HERE>", x + 4, y + 4)
	else
		love.graphics.setColor(1, 1, highlighted and 0 or 1, alpha)
		love.graphics.setFont(font_3x5_2)
		drawWrappingText(section.display_info, x, y + 8, 160, "center")
		love.graphics.setColor(0.8, 0.8, highlighted and 0 or 0.8, alpha)
		love.graphics.setFont(font_3x5)
		drawWrappingText(section.mode_name or "???", x + 1, y + 1, 78, "left")
		drawWrappingText(section.ruleset_name or "???", x + 80, y + 1, 78, "right")
		drawWrappingText(getTimestampDifference(section.timestamp), x, y + 25, 160, "center")
	end
end

function PlayerCardScene.renderCard(x, y, is_editing, field_name, section_highlight)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x, y, 340, 156, 10, 10)
	love.graphics.setColor(0.9, 0.9, 0.9)
	love.graphics.rectangle("fill", x + 2, y + 2, 336, 152, 9, 9)
	love.graphics.setColor(0.75, 0.75, 0.75)
	love.graphics.rectangle("fill", x + 4, y + 4, 332, 148, 8, 8)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	local total_playtime = 0
	for key, playtime in pairs(player.playtimes) do
		total_playtime = total_playtime + playtime
	end
	local total_runs = 0
	for key, runs in pairs(player.run_counts) do
		total_runs = total_runs + runs
	end
	drawImage(player.profile_picture or blocks.bone_classic["W"], x + 4, y + 4, 0, 64, 64)
	local _, wraps = love.graphics.getFont():getWrap(player.name, 240)
	local width_last_line = love.graphics.getFont():getWidth(wraps[#wraps])
	local last_line_y = love.graphics.getFont():getHeight() * (#wraps - 1)
	if is_editing and field_name == "name" then
		love.graphics.printf(getBlinking(), x + 70 + width_last_line, y + 12 + last_line_y, 250, "left")
	end
	love.graphics.printf(player.name or "<INSERT NAME>", x + 70, y + 12, 240, "left")
	love.graphics.setFont(font_3x5_2)
	love.graphics.printf(getPlaytimeString(total_playtime) .. "\n" .. total_runs .. " att.", x + 30, y + 5, 300, "right")
	local section_positions = {{x = 10, y = 80, section = player.mode_sections["BigA1-Standard"]}, {x = 170, y = 80}, {x = 10, y = 115}, {x = 170, y = 115}}
	for key, value in pairs(section_positions) do
		PlayerCardScene.renderCardSection(x + value.x, y + value.y, player.mode_sections[player.selected_sections[key]], key == section_highlight)
	end
	love.graphics.setFont(font_3x5_2)
	love.graphics.setColor(1, 1, 1)
	_, wraps = font_3x5_2:getWrap(player.about_me, 265)
	if #wraps > 2 then
		love.graphics.setFont(font_3x5)
	end
	_, wraps = love.graphics.getFont():getWrap(player.about_me, 265)
	width_last_line = love.graphics.getFont():getWidth(wraps[#wraps])
	last_line_y = love.graphics.getFont():getHeight() * (#wraps - 1)
	if is_editing and field_name == "about_me" then
		love.graphics.print(getBlinking(), x + 70 + width_last_line, y + 40 + last_line_y)
	end
	love.graphics.printf(player.about_me or "<insert info>", x + 70, y + 40, 265, "left")
	love.graphics.setFont(font_3x5)
	love.graphics.printf(string.format("%d", player.id), x + 70, y + 2, 160, "left")
end

function PlayerCardScene.renderMiniCard(x, y, alignment)
	local player_name_string = player.name or "<INSERT NAME>"
	local player_rpc_details = DiscordRPC.presence.details or ""
	local name_width = math.max(font_3x5_2:getWidth(player_name_string),font_3x5_2:getWidth(player_rpc_details))
	local x_offset = alignment == "right" and (-name_width - 40) or alignment == "center" and (-name_width / 2 - 20) or 0
	x = x + x_offset
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x, y, 40 + name_width, 36, 3, 3)
	love.graphics.setColor(0.9, 0.9, 0.9)
	love.graphics.rectangle("fill", x + 1, y + 1, 38 + name_width, 34, 2, 2)
	love.graphics.setColor(0.75, 0.75, 0.75)
	love.graphics.rectangle("fill", x + 2, y + 2, 36 + name_width, 32, 1, 1)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	drawImage(player.profile_picture or blocks.bone_classic["W"], x + 2, y + 2, 0, 32, 32)
	love.graphics.print(player_name_string, x + 36, y + 3)
	love.graphics.print(player_rpc_details, x + 36, y + 18)
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

	PlayerCardScene.renderCard(80, 130, self.is_editing, self.field_edit)

	love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(self.options) do
		local b = cursorHighlight(80,240 + 40 * i,200,40)
		love.graphics.setColor(1,1,b,1)
		love.graphics.print(screen.title, 80, 250 + 40 * i)
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
		if utf8.len(player[self.field_edit]) < self.length_limit then
			player[self.field_edit] = player[self.field_edit] .. e.text
			playSE("cursor")
		else
			playSE("error")
		end
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