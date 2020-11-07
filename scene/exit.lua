local ExitScene = Scene:extend()
require 'load.save'

ExitScene.title = "Exit Game"

function ExitScene:new()
end

function ExitScene:update()
	love.event.quit()
end

function ExitScene:render()
end

function ExitScene:changeOption(rel)
end

function ExitScene:onKeyPress(e)
end

return ExitScene

