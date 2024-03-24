local ConfigScene = Scene:extend()
require 'load.save'



function ConfigScene:new()
end

function ConfigScene:update()
end

function ConfigScene:render()
end

function ConfigScene:changeOption(rel)
	local len = #main_menu_screens
	self.main_menu_state = (self.main_menu_state + len + rel - 1) % len + 1
end

function ConfigScene:onInputPress(e)
end

return ConfigScene

