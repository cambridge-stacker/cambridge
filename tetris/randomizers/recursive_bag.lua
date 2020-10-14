local Randomizer = require 'tetris.randomizers.randomizer'

local RecursiveRandomizer = Randomizer:extend()

function RecursiveRandomizer:initialize()
	self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
end

function RecursiveRandomizer:generatePiece()
	--if next(self.bag) == nil then
	--	self.bag = {"I", "J", "L", "O", "S", "T", "Z"}
	--end
	local x = math.random(table.getn(self.bag) + 1)
	while x == table.getn(self.bag) + 1 do
		print("Refill piece pulled")
		table.insert(self.bag, "I")
		table.insert(self.bag, "J")
		table.insert(self.bag, "L")
		table.insert(self.bag, "O")
		table.insert(self.bag, "S")
		table.insert(self.bag, "T")
		table.insert(self.bag, "Z")
		x = math.random(table.getn(self.bag) + 1)
	end
	--print("Number of pieces in bag: "..table.getn(self.bag))
	--print("Bag: "..table.concat(self.bag, ", "))
	return table.remove(self.bag, x)
end

return RecursiveRandomizer
