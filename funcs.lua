---@return any
function copy(t)
	-- returns top-layer shallow copy of t
	if type(t) ~= "table" then return t end
	local target = {}
	for k, v in next, t do target[k] = v end
	setmetatable(target, getmetatable(t))
	return target
end

---@return any
function deepcopy(t)
    -- returns infinite-layer deep copy of t
	if type(t) ~= "table" then return t end
	local target = {}
	for k, v in next, t do
		target[deepcopy(k)] = deepcopy(v)
	end
	setmetatable(target, deepcopy(getmetatable(t)))
	return target
end

---@param image love.Image
---@param origin_x integer
---@param origin_y integer
---@param draw_width integer
---@param draw_height integer
function drawSizeIndependentImage(image, origin_x, origin_y, r, draw_width, draw_height)
	local width, height = image:getDimensions()
	local width_scale_factor = width / draw_width
	local height_scale_factor = height / draw_height
	love.graphics.draw(image, origin_x, origin_y, r, 1/width_scale_factor, 1/height_scale_factor)
end

---@param h number
---@param s number
---@param v number
function HSVToRGB(h, s, v)
    if s <= 0 then return v,v,v end
    h = h*6
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r+m, g+m, b+m
end

---@param string string
function rainbowString(string)
	local tbl = {}
	local char = ''
    for i = 1, #string do
        char = string.char(string:byte(i)) or ' '
		local r, g, b = HSVToRGB(((love.timer.getTime() / 4) + i / #string) % 1, 1, 1)
		-- print(r, g, b, a, (love.timer.getTime() + i / 20) % 1)
		table.insert(tbl, {r, g, b, 1})
		table.insert(tbl, char)
    end
	return tbl
end

---@param tbl table
function strTrueValues(tbl)
	-- returns a concatenation of all the keys in tbl with value true, separated with spaces
	local str = ""
	for k, v in pairs(tbl) do
		if v == true then
			str = str .. k .. " "
		end
	end
	return str
end

---@param min integer
---@param sec integer|nil
---@param hth integer|nil
function frameTime(min, sec, hth)
	-- returns a time in frames from a time in minutes-seconds-hundredths format
	if min == nil then min = 0 end
	if sec == nil then sec = 0 end
	if hth == nil then hth = 0 end
	return min*3600 + sec*60 + math.ceil(hth * 0.6)
end

---@param v1 table
---@param v2 table
function vAdd(v1, v2)
	-- returns the sum of vectors v1 and v2
	return {
		x = v1.x + v2.x,
		y = v1.y + v2.y
	}
end

---@param v table
function vNeg(v)
	-- returns the opposite of vector v
	return {
		x = -v.x,
		y = -v.y
	}
end

---@param frames number
function formatTime(frames)
	-- returns a mm:ss:hh (h=hundredths) representation of the time in frames given 
	if frames < 0 then return formatTime(0) end
	local min, sec, hund
	min  = math.floor(frames/3600)
	sec  = math.floor(frames/60) % 60
	hund = math.floor(frames/.6) % 100
	local str = string.format("%02d:%02d.%02d", min, sec, hund)
	return str
end

function formatBigNum(number)
	-- returns a string representing a number with commas as thousands separator (e.g. 12,345,678)
	local s
	if type(number) == "number" then
		s = string.format("%d", number)
	elseif type(number) == "string" then
		if not tonumber(number) then
			return
		else
			s = number
		end
	else
		return
	end
	local pos = Mod1(string.len(s), 3)
	return string.sub(s, 1, pos)
		.. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
end

---@param n number
---@param m number
function Mod1(n, m)
	-- returns a number congruent to n modulo m in the range [1;m] (as opposed to [0;m-1])
	return ((n-1) % m) + 1
end

---@param table table
---@param element any
---@return boolean
function table.contains(table, element)
	for _, value in pairs(table) do
	  	if value == element then
			return true
	  	end
	end
	return false
end

---@param table table
---@return table
function table.keys(table)
	local target = {}
	for key in pairs(table) do
		target[#target+1] = key
	end
	return target
end

---@param table table
function table.numkeys(table)
	local count = 0
	for k in pairs(table) do
		count = count + 1
	end
	return count
end

function equals(x, y)
	if type(x) ~= "table" or type(y) ~= "table" then
		return x == y
	else
		for k in pairs(x) do
			if not equals(x[k], y[k]) then return false end
		end
		for k in pairs(y) do
			if not equals(x[k], y[k]) then return false end
		end
		return true
	end
end

function table.equalvalues(t1, t2)
	if table.numkeys(t1) ~= table.numkeys(t2) then
		return false
	else
		for _, v in pairs(t2) do
			if not table.contains(t1, v) then return false end
		end
		return true
	end
end

---@param x number
---@param min number
---@param max number
function clamp(x, min, max)
	if max < min then
		min, max = max, min
	end
	return x < min and min or (x > max and max or x)
end
