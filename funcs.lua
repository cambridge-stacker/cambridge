function copy(t)
	if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do target[k] = v end
    setmetatable(target, meta)
    return target
end

function st(tbl)
	str = ""
	for k, v in pairs(tbl) do
		if v == true then
			str = str .. k .. " "
		end
	end
	return str
end

function sp(m, s, f)
	if m == nil then m = 0 end
	if s == nil then s = 0 end
	if f == nil then f = 0 end
	return m*3600 + s*60 + math.ceil(f * 0.6)
end

function vAdd(v1, v2)
	return {
		x = v1.x + v2.x,
		y = v1.y + v2.y
	}
end

function vNeg(v)
	return {
		x = -v.x,
		y = -v.y
	}
end

function formatTime(frames)
	if frames < 0 then return formatTime(0) end
	str = string.format("%02d", math.floor(frames / 3600)) .. ":"
		.. string.format("%02d", math.floor(frames / 60) % 60) .. "."
		.. string.format("%02d", math.floor(frames / 0.6) % 100)
	return str
end

function formatBigNum(number)
	local s = string.format("%d", number)
	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	return string.sub(s, 1, pos)
		.. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
end