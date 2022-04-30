replay_load_code = [[
	
	function nilCheck(input, default)
		if input == nil then
			return default
		end
		return input
	end
	local mode_names = ...
	local replays = {}
	local replay_tree = {{name = "All"}}
	local dict_ref = {}
	for key, value in pairs(mode_names) do
		dict_ref[value] = key + 1
		replay_tree[key + 1] = {name = value}
	end
	local replay_file_list = love.filesystem.getDirectoryItems("replays")
	local binser = require "libs/binser"
	require "funcs"
	print("some io")
	for i=1, #replay_file_list do
		local data = love.filesystem.read("replays/"..replay_file_list[i])
		local new_replay = binser.deserialize(data)[1]
		local mode_name = nilCheck(new_replay, {mode = "znil"}).mode
		replays[#replays+1] = new_replay
		if dict_ref[mode_name] ~= nil and mode_name ~= "znil" then
			table.insert(replay_tree[dict_ref[mode_name] ], #replays)
		end
		table.insert(replay_tree[1], #replays)
	end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(replay_tree, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	for key, submenu in pairs(replay_tree) do
		table.sort(submenu, function(a, b)
			return replays[a]["timestamp"] > replays[b]["timestamp"]
		end)
	end
	print("load")
    love.thread.getChannel( 'replays' ):push( replays )
    love.thread.getChannel( 'replay_tree' ):push( replay_tree )
    love.thread.getChannel( 'dict_ref' ):push( dict_ref )
    love.thread.getChannel( 'loaded_replays' ):push( true )
]]