function copy(t)
	-- returns deep copy of t (as opposed to the shallow copy you get from var = t)
	if type(t) ~= "table" then return t end
	local meta = getmetatable(t)
	local target = {}
	for k, v in pairs(t) do target[k] = v end
	setmetatable(target, meta)
	return target
end

function strTrueValues(tbl)
	-- returns a concatenation of all the keys in tbl with value true, separated with spaces
	str = ""
	for k, v in pairs(tbl) do
		if v == true then
			str = str .. k .. " "
		end
	end
	return str
end

function frameTime(min, sec, hth)
	-- returns a time in frames from a time in minutes-seconds-hundredths format
	if min == nil then min = 0 end
	if sec == nil then sec = 0 end
	if hth == nil then hth = 0 end
	return min*3600 + sec*60 + math.ceil(hth * 0.6)
end

function vAdd(v1, v2)
	-- returns the sum of vectors v1 and v2
	return {
		x = v1.x + v2.x,
		y = v1.y + v2.y
	}
end

function vNeg(v)
	-- returns the opposite of vector v
	return {
		x = -v.x,
		y = -v.y
	}
end

function formatTime(frames)
	-- returns a mm:ss:hh (h=hundredths) representation of the time in frames given 
	if frames < 0 then return formatTime(0) end
	local min, sec, hund
	min  = math.floor(frames/3600)
	sec  = math.floor(frames/60) % 60
	hund = math.floor(frames/.6) % 100
	str = string.format("%02d:%02d.%02d", min, sec, hund)
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

function Mod1(n, m)
	-- returns a number congruent to n modulo m in the range [1;m] (as opposed to [0;m-1])
	return ((n-1) % m) + 1
end

function table.contains(table, element)
	for _, value in pairs(table) do
	  if value == element then
		return true
	  end
	end
	return false
  end