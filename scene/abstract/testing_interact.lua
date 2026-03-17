local TestingInteract = AbstractInteractableScene:extend()
TestingInteract.title = "Test"

function TestingInteract:new()
	self.super.new(self)
	AbstractInteractableScene.addNewInteractable(self, {
		x = 30,
		y = 20,
		w = 60,
		h = 20,
		onRender = function (this, is_selected, is_hovered)
			if is_hovered then
				love.graphics.setColor(1, 1, 0, 1)
			end
			love.graphics.print("Interactable Testing 1", this.x, this.y)
		end,
		onInteract = function ()
			playSE("erase", "single")
		end,
		onUpdate = function (this, is_selected, is_hovered)
			this.x = math.sin(love.timer.getTime()) * 40 + 320
		end
	})
	AbstractInteractableScene.addNewInteractable(self, {
		x = 80,
		y = 20,
		w = 60,
		h = 20,
		onRender = function (this, is_selected, is_hovered)
			if is_hovered then
				love.graphics.setColor(1, 1, 0, 1)
			end
			love.graphics.print("Interactable Testing bla", this.x, this.y)
		end,
		onInteract = function ()
			playSE("erase", "triple")
		end,
		onUpdate = function (this, is_selected, is_hovered)
			if is_hovered then return end
			this.y = math.sin(love.timer.getTime()) * 60 + 240
		end
	})
	self:selectInteractableNearCoordinates(50, 20)
end


function TestingInteract:onMenuBack()
	scene = TitleScene()
	playSE("menu_cancel")
end


return TestingInteract