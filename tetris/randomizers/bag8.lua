local Randomizer = require 'tetris.randomizers.randomizer'

local Bag7Randomizer = Randomizer:extend()

function Bag7Randomizer:initialize()
	self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
	self.extra = {"I", "J", "L", "O", "S", "T", "Z"}
	table.insert(self.bag, table.remove(self.extra, math.random(table.getn(self.extra))))
end

function Bag7Randomizer:generatePiece()
	if next(self.extra) == nil then
		self.extra = {"I", "J", "L", "O", "S", "T", "Z"}
	end
	if next(self.bag) == nil then
		self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
		table.insert(self.bag, table.remove(self.extra, math.random(table.getn(self.extra))))
	end
	local x = math.random(table.getn(self.bag))
	--print("Bag: "..table.concat(self.bag, ", ").." | Extra: "..table.concat(self.extra, ", "))
	return table.remove(self.bag, x)
end

return Bag7Randomizer
