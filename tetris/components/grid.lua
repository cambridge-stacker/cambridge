local Object = require 'libs.classic'

local Grid = Object:extend()

local empty = { skin = "", colour = "" }
local oob = { skin = "", colour = "" }
local block = { skin = "2tie", colour = "A" }

function Grid:new()
	self.grid = {}
	self.grid_age = {}
	for y = 1, 24 do
		self.grid[y] = {}
		self.grid_age[y] = {}
		for x = 1, 10 do
			self.grid[y][x] = empty
			self.grid_age[y][x] = 0
		end
	end
end

function Grid:clear()
	for y = 1, 24 do
		for x = 1, 10 do
			self.grid[y][x] = empty
			self.grid_age[y][x] = 0
		end
	end
end

function Grid:getCell(x, y)
	if x < 1 or x > 10 or y > 24 then return oob
	elseif y < 1 then return empty
	else return self.grid[y][x]
	end
end

function Grid:isOccupied(x, y)
	return self:getCell(x+1, y+1) ~= empty
end

function Grid:isRowFull(row)
	for index, square in pairs(self.grid[row]) do
		if square == empty then return false end
	end
	return true
end

function Grid:canPlacePiece(piece)
	if piece.big then
		return self:canPlaceBigPiece(piece)
	end

	local offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local x = piece.position.x + offset.x
		local y = piece.position.y + offset.y
		if self:isOccupied(x, y) then
			return false
		end
	end
	return true
end

function Grid:canPlaceBigPiece(piece)
	local offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local x = piece.position.x + offset.x
		local y = piece.position.y + offset.y
		if (
		   self:isOccupied(x * 2 + 0, y * 2 + 0)
		or self:isOccupied(x * 2 + 1, y * 2 + 0)
		or self:isOccupied(x * 2 + 0, y * 2 + 1)
		or self:isOccupied(x * 2 + 1, y * 2 + 1)
		) then
			return false
		end
	end
	return true
end

function Grid:canPlacePieceInVisibleGrid(piece)
	if piece.big then
		return self:canPlaceBigPiece(piece)
		-- forget canPlaceBigPieceInVisibleGrid for now
	end

	local offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local x = piece.position.x + offset.x
		local y = piece.position.y + offset.y
		if y < 4 or self:isOccupied(x, y) ~= empty then
			return false
		end
	end
	return true
end

function Grid:getClearedRowCount()
	local count = 0
	for row = 1, 24 do
		if self:isRowFull(row) then
			count = count + 1
		end
	end
	return count
end

function Grid:markClearedRows()
	for row = 1, 24 do
		if self:isRowFull(row) then
			for x = 1, 10 do
				self.grid[row][x] = {
					skin = self.grid[row][x].skin,
					colour = "X"
				}
				self.grid_age[row][x] = 0
			end
		end
	end
	return true
end

function Grid:clearClearedRows()
	for row = 1, 24 do
		if self:isRowFull(row) then
			for above_row = row, 2, -1 do
				self.grid[above_row] = self.grid[above_row - 1]
				self.grid_age[above_row] = self.grid_age[above_row - 1]
			end
			self.grid[1] = {empty, empty, empty, empty, empty, empty, empty, empty, empty, empty}
			self.grid_age[1] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		end
	end
	return true
end

function Grid:copyBottomRow()
	for row = 1, 23 do
		self.grid[row] = self.grid[row+1]
		self.grid_age[row] = self.grid_age[row+1]
	end
	self.grid[24] = {empty, empty, empty, empty, empty, empty, empty, empty, empty, empty}
	self.grid_age[24] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	for col = 1, 10 do
		self.grid[24][col] = (self.grid[23][col] == empty) and empty or block
	end
	return true
end

function Grid:garbageRise(row_vals)
		for row = 1, 23 do
				self.grid[row] = self.grid[row+1]
				self.grid_age[row] = self.grid_age[row+1]
		end
		self.grid[24] = {empty, empty, empty, empty, empty, empty, empty, empty, empty, empty}
		self.grid_age[24] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	for col = 1, 10 do
		self.grid[24][col] = (row_vals[col] == "e") and empty or block
	end
end

function Grid:applyFourWide()
		for row = 1, 24 do
				local x = self.grid[row]
				x[1] = x[1]~=block and block or x[1]
				x[2] = x[2]~=block and block or x[2]
				x[3] = x[3]~=block and block or x[3]
				x[8] = x[8]~=block and block or x[8]
				x[9] = x[9]~=block and block or x[9]
				x[10] = x[10]~=block and block or x[10]
		end
end

function Grid:applyCeiling(lines)
	for row = 1, lines do
		for col = 1, 9 do
			self.grid[row][col] = block
		end
	end
end

function Grid:clearSpecificRow(row)
	for col = 1, 10 do
		self.grid[row][col] = empty
	end
end

function Grid:applyPiece(piece)
	if piece.big then
		self:applyBigPiece(piece)
		return
	end
	offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		x = piece.position.x + offset.x
		y = piece.position.y + offset.y
		if y + 1 > 0 and y < 24 then
			self.grid[y+1][x+1] = {
				skin = piece.skin,
				colour = piece.colour
			}
		end
	end
end

function Grid:applyBigPiece(piece)
	offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		x = piece.position.x + offset.x
		y = piece.position.y + offset.y
		for a = 1, 2 do
			for b = 1, 2 do
				if y*2+a > 0 then
					self.grid[y*2+a][x*2+b] = {
						skin = piece.skin,
						colour = piece.colour
					}
				end
			end
		end
	end
end

function Grid:checkForBravo(cleared_row_count)
	for i = 0, 23 - cleared_row_count do
				for j = 0, 9 do
						if self:isOccupied(j, i) then return false end
				end
		end
	return true
end

function Grid:checkStackHeight()
	for i = 0, 23 do
		for j = 0, 9 do
			if self:isOccupied(j, i) then return 24 - i end
		end
	end
	return 0
end

function Grid:checkSecretGrade()
	local sgrade = 0
	for i=23,5,-1 do
		local validLine = true
		local emptyCell = 0
		if i > 13 then
			emptyCell = 23-i
		end
		if i <= 13 then
			emptyCell = i-5
		end
		for j=0,9 do
			if (not self:isOccupied(j,i) and j ~= emptyCell) or (j == emptyCell and self:isOccupied(j,i)) then
				validLine = false
			end
		end
		if not self:isOccupied(emptyCell,i-1) then
			validLine = false
		end
		if(validLine) then
				sgrade = sgrade + 1
		else
				return sgrade
		end
	end
	--[[
	if(sgrade == 0) then return ""
	elseif(sgrade < 10) then return 10-sgrade
	elseif(sgrade < 19) then return "S"..(sgrade-9) end
	return "GM"
	--]]
	return sgrade
end

function Grid:hasGemBlocks()
	for y = 1, 24 do
		for x = 1, 10 do
			if self.grid[y][x].skin == "gem" then
				return true
			end
		end
	end
	return false
end

function Grid:mirror()
	local new_grid = {}
	for y = 1, 24 do
		new_grid[y] = {}
		for x = 1, 10 do
			new_grid[y][x] = empty
		end
	end

	for y = 1, 24 do
		for x = 1, 10 do
			new_grid[y][x] = self.grid[y][11 - x]
		end
	end
	self.grid = new_grid
end

function Grid:applyMap(map)
	for y, row in pairs(map) do
		for x, block in pairs(row) do
			self.grid_age[y][x] = 0
			self.grid[y][x] = block
		end
	end
end

function Grid:update()
	for y = 1, 24 do
		for x = 1, 10 do
			if self.grid[y][x] ~= empty then
				self.grid_age[y][x] = self.grid_age[y][x] + 1
			end
		end
	end
end

function Grid:draw()
	for y = 5, 24 do
		for x = 1, 10 do
			if self.grid[y][x] ~= empty then
				if self.grid_age[y][x] < 2 then
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.draw(blocks[self.grid[y][x].skin]["F"], 48+x*16, y*16)
				else
					if self.grid[y][x].skin == "bone" then
						love.graphics.setColor(1, 1, 1, 1)
					elseif self.grid[y][x].colour == "X" then
						love.graphics.setColor(0.5, 0.5, 0.5, 1 - self.grid_age[y][x] / 15)
					else
						love.graphics.setColor(0.5, 0.5, 0.5, 1)
					end
					love.graphics.draw(blocks[self.grid[y][x].skin][self.grid[y][x].colour], 48+x*16, y*16)
				end
				if self.grid[y][x].skin ~= "bone" and self.grid[y][x].colour ~= "X" then
					love.graphics.setColor(0.8, 0.8, 0.8, 1)
					love.graphics.setLineWidth(1)
					if y > 1 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
						love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
					end
					if y < 24 and self.grid[y+1][x] == empty or
					(y + 1 > 24 or self.grid[y+1][x].colour == "X") then
						love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
					end
					if x > 1 and self.grid[y][x-1] == empty then
						love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
					end
					if x < 10 and self.grid[y][x+1] == empty then
						love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
					end
				end
			end
		end
	end
end

function Grid:drawOutline()
	for y = 5, 24 do
		for x = 1, 10 do
			if self.grid[y][x] ~= empty and self.grid[y][x].colour ~= "X" then
				love.graphics.setColor(0.8, 0.8, 0.8, 1)
				love.graphics.setLineWidth(1)
				if y > 1 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
					love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
				end
				if y < 24 and self.grid[y+1][x] == empty or
				(y + 1 > 24 or self.grid[y+1][x].colour == "X") then
					love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
				end
				if x > 1 and self.grid[y][x-1] == empty then
					love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
				end
				if x < 10 and self.grid[y][x+1] == empty then
					love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
				end
			end
		end
	end
end

function Grid:drawInvisible(opacity_function, garbage_opacity_function, lock_flash, brightness)
	lock_flash = lock_flash == nil and true or lock_flash
	brightness = brightness == nil and 0.5 or brightness
	for y = 5, 24 do
		for x = 1, 10 do
			if self.grid[y][x] ~= empty then
				if self.grid[y][x].colour == "X" then
					opacity = 1 - self.grid_age[y][x] / 15
				elseif garbage_opacity_function and self.grid[y][x].colour == "A" then
					opacity = garbage_opacity_function(self.grid_age[y][x])
				else
					opacity = opacity_function(self.grid_age[y][x])
				end
				love.graphics.setColor(brightness, brightness, brightness, opacity)
				love.graphics.draw(blocks[self.grid[y][x].skin][self.grid[y][x].colour], 48+x*16, y*16)
				if lock_flash then
					if opacity > 0 and self.grid[y][x].colour ~= "X" then
						love.graphics.setColor(0.64, 0.64, 0.64)
						love.graphics.setLineWidth(1)
						if y > 1 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
							love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
						end
						if y < 24 and self.grid[y+1][x] == empty or
						(y + 1 > 24 or self.grid[y+1][x].colour == "X") then
							love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
						end
						if x > 1 and self.grid[y][x-1] == empty then
							love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
						end
						if x < 10 and self.grid[y][x+1] == empty then
							love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
						end
					end
				end
			end
		end
	end
end

function Grid:drawCustom(colour_function, gamestate)
    --[[
        colour_function: (game, block, x, y, age) -> (R, G, B, A, outlineA)
        When called, calls the supplied function on every block passing the block itself as argument
        as well as coordinates and the grid_age value of the same cell.
        Should return a RGBA colour for the block, as well as the opacity of the stack outline (0 for no outline).
        
        gamestate: the gamemode instance itself to pass in colour_function
    ]]
	for y = 5, 24 do
		for x = 1, 10 do
            local block = self.grid[y][x]
			if block ~= empty then
                local R, G, B, A, outline = colour_function(gamestate, block, x, y, self.grid_age[y][x])
				if self.grid[y][x].colour == "X" then
					A = 1 - self.grid_age[y][x] / 15
				end
				love.graphics.setColor(R, G, B, A)
				love.graphics.draw(blocks[self.grid[y][x].skin][self.grid[y][x].colour], 48+x*16, y*16)
                if outline > 0 and self.grid[y][x].colour ~= "X" then
                    love.graphics.setColor(0.64, 0.64, 0.64, outline)
                    love.graphics.setLineWidth(1)
                    if y > 1 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
						love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
					end
					if y < 24 and self.grid[y+1][x] == empty or
					(y + 1 > 24 or self.grid[y+1][x].colour == "X") then
						love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
					end
					if x > 1 and self.grid[y][x-1] == empty then
						love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
					end
					if x < 10 and self.grid[y][x+1] == empty then
						love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
					end
                end
			end
		end
	end
end

return Grid
