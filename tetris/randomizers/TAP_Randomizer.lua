local Randomizer = require 'tetris.randomizers.randomizer'

local TAPRandomizer = Randomizer:extend()
local seed

-- TGM's LCG. used for every TGM game's history based randomizer.

local function lcg()
    seed = (129749 * seed)%(2^32) -- can overflow max safe integer range if we don't break this up and apply overflow here.
    seed = (seed * 8505 +12345) % (2^32)    -- second overflow check, just in case.
    return math.floor(seed / (2 ^ 10)) % 32768     -- mulitple of 3 bits used minimizes modulo bias for 7 to lowest possible. 0 and 32767 are both I.
end

local function lcgRandom(n)           -- usable for any number of pieces
    return lcg() % n + 1              -- adds one to convert from normal LCG to LOVE
end

function TAPRandomizer:initialize()
	self.history = {"Z", "S", "S", "Z"}
	self.first = true
	seed = love.math.random(0, 0xFFFFFFFF) -- use LOVE to set initial seed so replays will sync. 
end

function TAPRandomizer:generatePiece()
	local shapes = {"I", "Z", "S", "J", "L", "O", "T"} -- corrected to actual order for TAP.
	local index, x
	if self.first then
		while self.first do
			index=lcgRandom(7)
			x = shapes[index]  -- get piece.
		        if x == "I" then          -- if an I
		            self.first = false    -- accept
		        end
		        if x == "L" then          -- if an L
		            self.first = false    -- accept
		        end
		        if x == "J" then          -- if an J
		            self.first = false    -- accept
		        end
		        if x == "T" then          -- if an T
		            self.first = false    -- accept
		        end
			-- otherwise loop around again.
		end
		return self:updateHistory(x) -- found first piece not SZO
	else
		-- original program bug.  local x = lcgRandom(7) should be on this line instead.
		for i = 1, 5 do  
			index = lcgRandom(7)  -- this line should be empty
			if not self:inHistory(shapes[index]) then
	                	break         -- leave loop if we found apiece
        		end
			index = lcgRandom(7)  -- if we didn't, roll again in case we fall out.
		end
		return self:updateHistory(shapes[index]) -- either we fell out or not, return piece and update history.

	end
end

function TAPRandomizer:updateHistory(shape)
	table.remove(self.history, 1)
	table.insert(self.history, shape)
	return shape
end

function TAPRandomizer:inHistory(piece)
	for idx, entry in pairs(self.history) do
		if entry == piece then
			return true
		end
	end
	return false
end

return TAPRandomizer
