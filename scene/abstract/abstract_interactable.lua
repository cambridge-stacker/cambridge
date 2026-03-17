local AbstractInteractableScene = Scene:extend()
AbstractInteractableScene.title = "Interactable"

---@class INTERACTABLE
---@field x number
---@field y number
---@field w number
---@field h number
---@field onInteract function
---@field onRelease function?
---@field onUpdate fun(self:INTERACTABLE, is_selected:boolean, is_hovered:boolean)
---@field onRender fun(self:INTERACTABLE, is_selected:boolean, is_highlighted:boolean)
local LLS_INTERACTABLE_METADATA

function AbstractInteractableScene:new()
	---@type INTERACTABLE[]
	self.interactables = {}
	---@type INTERACTABLE
	self.current_selected_interactable = nil
end

function AbstractInteractableScene:update()
	for key, value in pairs(self.interactables) do
		local is_selected = self.current_selected_interactable == value
		local is_hovered = cursorHoverArea(value.x, value.y, value.w, value.h)
		value:onUpdate(is_selected, is_hovered)
	end
end

function AbstractInteractableScene:render()
	drawBackground(self:getBackgroundID())
	for key, value in pairs(self.interactables) do
		love.graphics.push("all")
		local is_selected = self.current_selected_interactable == value
		local is_hovered = cursorHighlight(value.x, value.y, value.w, value.h) == 1
		love.graphics.rectangle("line", value.x, value.y, value.w, value.h)
		value:onRender(is_selected, is_hovered)
		love.graphics.pop()
	end
end

function AbstractInteractableScene:getBackgroundID()
	return 0
end

function AbstractInteractableScene:onMenuBack()
	
end

local function sqDistance(x, y)
	return math.sqrt(x*x + y*y)
end

---@param x number
---@param y number
function AbstractInteractableScene:selectInteractableNearCoordinates(x, y)
	local distance_away_from_point = math.huge
	---@type INTERACTABLE
	local nearest_interactable
	for key, value in pairs(self.interactables) do
		local interactable_distance = sqDistance(value.x - x, value.y - y)
		if not nearest_interactable or interactable_distance < distance_away_from_point then
			nearest_interactable = value
			distance_away_from_point = interactable_distance
		end
	end
	self.current_selected_interactable = nearest_interactable
end
function AbstractInteractableScene:moveInteractableSelector(dx, dy)
	if self.current_selected_interactable == nil then return end
	---@type INTERACTABLE[]
	local interactables_copy = copy(self.interactables)
	if dx > 0 and dy == 0 then
		table.sort(interactables_copy, function (a, b)
			return a.x > b.x or a.x > self.current_selected_interactable.x
		end)
	elseif dx == 0 and dy > 0 then
		table.sort(interactables_copy, function (a, b)
			return a.y > b.y or a.y > self.current_selected_interactable.y
		end)
	elseif dx < 0 and dy == 0 then
		table.sort(interactables_copy, function (a, b)
			return a.x < b.x or a.x < self.current_selected_interactable.x
		end)
	elseif dx == 0 and dy < 0 then
		table.sort(interactables_copy, function (a, b)
			return a.y < b.y or a.y < self.current_selected_interactable.y
		end)
	end
	return interactables_copy[1]
end

---@param interactable INTERACTABLE
function AbstractInteractableScene:addNewInteractable(interactable)
	assert(type(interactable.x) == "number", "X is not a number!")
	assert(type(interactable.y) == "number", "Y is not a number!")
	assert(type(interactable.w) == "number", "W is not a number!")
	assert(type(interactable.h) == "number", "H is not a number!")
	assert(type(interactable.onRender) == "function", "onRender is not a function!")
	assert(type(interactable.onInteract) == "function", "onInteract is not a function!")
	assert(type(interactable.onUpdate) == "function", "onUpdate is not a function!")
	table.insert(self.interactables, interactable)
end


function AbstractInteractableScene:onInputPress(e)
	if e.input == "menu_decide" then
		if self.current_selected_interactable then
			self.current_selected_interactable:onInteract()
		end
	elseif e.input == "menu_back" then
		self:onMenuBack()
	elseif e.input == "menu_left" then
		self.current_selected_interactable = self:moveInteractableSelector(-1, 0)
	elseif e.input == "menu_right" then
		self.current_selected_interactable = self:moveInteractableSelector(1, 0)
	elseif e.input == "menu_up" then
		self.current_selected_interactable = self:moveInteractableSelector(0, -1)
	elseif e.input == "menu_down" then
		self.current_selected_interactable = self:moveInteractableSelector(0, 1)
	elseif e.type == "key" then
	elseif e.type == "mouse" then
		for key, value in pairs(self.interactables) do
			if e.x > value.x and e.x < value.x + value.w and e.y > value.y and e.y < value.y + value.h then
				value:onInteract()
				print("interact found!")
				return
			end
		end
	end
end



return AbstractInteractableScene