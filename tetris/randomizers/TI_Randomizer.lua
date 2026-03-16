-- This is the Ti randomizer.
-- Now contains the TGM LGC, and chooses the actual first piece with infinite rerolls like the real game does.

local Randomizer = require 'tetris.randomizers.randomizer'

local TIRandomizer = Randomizer:extend()

local seed

-- TGM's LCG.  used by every history based randomizer in every TGM game.

local function lcg()
    seed = (129749 * seed)%(2^32) -- can overflow max safe integer range if we don't break this up and apply overflow here.
    seed = (seed * 8505 +12345) % (2^32)    -- second overflow check, just in case.
    return math.floor(seed / (2 ^ 10)) % 32768     -- slight I bias for modulo 7, cuz 32767 is an I.
end

local function lcgRandom(n)
    return lcg() % n + 1
end

function TIRandomizer:initialize()
    self.first = true
    self.history = { "Z", "S", "S", "Z" }
    self.pool = {
        "I", "I", "I", "I", "I",
        "Z", "Z", "Z", "Z", "Z",
        "S", "S", "S", "S", "S",
        "J", "J", "J", "J", "J",
        "L", "L", "L", "L", "L",
        "O", "O", "O", "O", "O",
        "T", "T", "T", "T", "T",  -- thtis is the correct intial seed.
    }
    self.droughts = {
        I = 4,
        Z = 4,
        S = 4,
        J = 4,
        L = 4,
        O = 4,
        T = 4, -- starting drought counters.
    }
    self.piece_index = {
        "I",
        "Z",
        "S",
        "J",
        "L",
        "O",
        "T",
    }
    seed = love.math.random(0, 0xFFFFFFFF) -- pick random 32 bit unsigned starting seed in replay compatible fashion.  not sure if all of these are usable by TI
end

function TIRandomizer:generatePiece()
    local index, x, highscore, didreroll, didfirst
    didreroll = false         -- did we reroll
    didfirst = false          -- did we just do the first piece
    if self.first then
	while self.first do
            index = lcgRandom(35) -- hack removed.  infinite rerolls to pick first piece
            x = self.pool[index]  -- get piece.
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
            didfirst = true           -- regardless once done rerolling, didfirst is true, safe to set it here.
        end
    else
        for i = 1, 5 do					   -- no, this is not an error in my implementation. the cocde does 1, 3, 5 7 9, or 10 rolls.  these correspond to 1 2 3 4 5 6
            index = lcgRandom(#self.pool)  -- this pair of lines was probably ment to be above the loop
            x = self.pool[index]           -- if it were, no rolls would be wasted, but their sequences wouldn't match the real game.
            if not self:inHistory(x) then
                break
            end
            didreroll = true                                -- checked later
            self.pool[index] = self:GetMostDroughtedPiece() -- update the bag. yes if you have to reroll a piece the peice you jsut rolled is now less likely to repeat.
            index = lcgRandom(#self.pool)                   -- reroll in case we are about to fall out
            x = self.pool[index]                            -- yes, this burns an extra number from the rng most of the time.
        end
    end
    highscore = self:CheckHighDroughtCount() -- check drought count before updating histogram so we can implement the bug
    self:UpdateHistory(x)                    --  update the history even on first piece
    self:UpdateHistogram(x)                  -- update the histogram even on first piece
    -- we only update the bag sometimes, due to a bug in TI
    if didfirst then
        return x  -- first piece never updates the bag. not part of the bug.
    end

    -- we should always update the bag here, but we only update it in two cases.
    if highscore < self:CheckHighDroughtCount() then
        self.pool[index] = self:GetMostDroughtedPiece() -- do update if the high drought count went up
    end
    if not didreroll then
        self.pool[index] = self:GetMostDroughtedPiece() -- do update if there was no reroll.
    end
    -- if neither happened, the bag does NOT get updated now. 
    -- to remove the bug, comment ouut both ifs and one of the updates above, so the bag always updates except for first piece
    return x
end

function TIRandomizer:UpdateHistory(shape)
    table.remove(self.history, 1)
    table.insert(self.history, shape)
end

function TIRandomizer:CheckHighDroughtCount()
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

function TIRandomizer:GetMostDroughtedPiece()
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

function TIRandomizer:UpdateHistogram(shape)
    for k, v in pairs(self.piece_index) do
        if v == shape then
            self.droughts[v] = 0
        else
            self.droughts[v] = self.droughts[v] + 1
        end
    end
end

function TIRandomizer:inHistory(piece)
    for idx, entry in pairs(self.history) do
        if entry == piece then
            return true
        end
    end
    return false
end

return TIRandomizer
