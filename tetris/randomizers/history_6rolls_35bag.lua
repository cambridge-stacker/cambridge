local Randomizer = require 'tetris.randomizers.randomizer'

local History6Rolls35PoolRandomizer = Randomizer:extend()

function History6Rolls35PoolRandomizer:initialize()
	self.first = true
	self.history = {"Z", "S", "Z", "S"}
	self.pool = {
		"I", "I", "I", "I", "I",
		"T", "T", "T", "T", "T",
		"L", "L", "L", "L", "L",
		"J", "J", "J", "J", "J",
		"S", "S", "S", "S", "S",
		"Z", "Z", "Z", "Z", "Z",
		"O", "O", "O", "O", "O",
	}
	self.droughts = {  -- don't ask me why TI does this, but it does. :)
		I = 4,
		T = 4,
		L = 4,
		J = 4,
		S = 4,
		Z = 4,
		O = 4,
	}
	self.piece_index = {
		"I",
		"T",
		"L",
		"J",
		"S",
		"Z",
		"O",
	}
end

function History6Rolls35PoolRandomizer:generatePiece()
	local index, x, highscore, didreroll, didfirst
	didreroll = false -- did we reroll
	didfirst = false -- did we just do the first piece
	if self.first then
		index = love.math.random(20) -- hack to pick non S Z O first try every time.
		x = self.pool[index]	     -- not actually how thwe real thing works, but close enough.
		self.first = false
		didfirst = true
	else
		for i = 1, 6 do			 
			index = love.math.random(#self.pool)
			x = self.pool[index]
			if not self:inHistory(x) then
				break
			end
			didrerool=true -- checked leater
			self.pool[index]=self.GetMostDroughtedPiece()   -- update the bag
			index = love.math.random(#self.pool)		-- reroll in case we are about to fall out
			x = self.pool[index]				-- yes, this burns an extra number from the rng most of the time.
		end
	end
	highscore=self.CheckHighDroughtCount()  -- check drought count before updating histogram so we can implement the bug
	self.UpdateHistory(x)			--  update the history even on first piece
	self.UpdateHistogram(x)			-- update the histogram even on first piece
	-- we only update the bag sometimes, due to a bug in TI
	if didfirst then
		return x -- don't update for first piece, skip the other two tests. this is not the bug, as the first piece was not drawn from the bag.
	end
	-- we should always update the bag here, but we only update it in two cases.
	if highscore < self.CheckHighDroughtCount() then
		self.pool[index]=self.GetMostDroughtedPiece()  -- do update if the high drought count went up
	end
	if not didreroll
		self.pool[index]=self.GetMostDroughtedPiece() -- do update if there was no reroll.
	end
	-- if neither happened, the bag does NOT get updated now. to remove the bug, comment ouut both ifs and one of the updates above, so the bag always updates except for first piece
	return x
end

function History6Rolls35PoolRandomizer:updateHistory(shape)
	table.remove(self.history, 1)
	table.insert(self.history, shape)
end
function History6Rolls35PoolRandomizer:CheckHighDroughtCount()

	local highdrought
	local highdroughtcount = 0
	for k, v in pairs(self.piece_index) do
			if self.droughts[v] >= highdroughtcount then
				highdrought = v
				highdroughtcount = self.droughts[v]
			end
	end
	return highdroughtcount
end
function History6Rolls35PoolRandomizer:GetMostDroughtedPiece()

	local highdrought
	local highdroughtcount = 0
	for k, v in pairs(self.piece_index) do
			if self.droughts[v] >= highdroughtcount then
				highdrought = v
				highdroughtcount = self.droughts[v]
			end
	end
	return highdrought
end
function History6Rolls35PoolRandomizer:UpdateHistogram(shape)

	for k, v in pairs(self.piece_index) do
		if v == shape then
			self.droughts[v] = 0
		else
			self.droughts[v] = self.droughts[v] + 1
		end
	end
end

function History6Rolls35PoolRandomizer:inHistory(piece)
	for idx, entry in pairs(self.history) do
		if entry == piece then
			return true
		end
	end
	return false
end

return History6Rolls35PoolRandomizer
