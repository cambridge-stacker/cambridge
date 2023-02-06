replay_load_code = [[
	
	function nilCheck(input, default)
		if input == nil then
			return default
		end
		return input
	end
	function setState(string)
		print(string)
		love.thread.getChannel( 'load_state' ):clear()
		love.thread.getChannel( 'load_state' ):push(string)
	end
	setState("Loading replay file list")
	local replay_file_list = love.filesystem.getDirectoryItems("replays")
	local binser = require "libs.binser"
	require "funcs"
	setState("Loading replay contents")
	for i=1, #replay_file_list do
		local data = love.filesystem.read("replays/"..replay_file_list[i])
		local new_replay = binser.deserialize(data)[1]
		if new_replay == nil then
			love.filesystem.remove("replays/"..replay_file_list[i])
			print ("The replay at replays/"..replay_file_list[i].." is corrupted or has no data, thus, deleted.")
		else
			love.thread.getChannel('replay'):push(new_replay)
		end
	end
    love.thread.getChannel( 'replay_tree' ):push( replay_tree )
    love.thread.getChannel( 'loaded_replays' ):push( true )
	print("Loaded replays.")
]]