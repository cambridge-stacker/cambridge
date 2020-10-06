local Randomizer = require 'tetris.randomizers.randomizer'

local BagKonoha = Randomizer:extend()

function BagKonoha:initialize()
	self.bag = {"I", "J", "L", "O", "T"}
	self.prev = nil
	self.allowrepeat = false
	self.generated = 0
end

function BagKonoha:generatePiece()
	self.generated = self.generated + 1
	if #self.bag == 0 then
		self.bag = {"I", "J", "L", "O", "T"}
	end
	local x = math.random(#self.bag)
	local temp = table.remove(self.bag, x)
	if temp == self.prev and not self.allowrepeat then
		local y = math.random(#self.bag)
		table.insert(self.bag, temp) -- should insert at the end of the bag, bag[y] doesnt change
		temp = table.remove(self.bag, y)
	end
	self.prev = temp
	return temp
end

return BagKonoha
