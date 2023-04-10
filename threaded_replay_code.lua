replay_load_code = [[
	function setState(string)
		print(string)
		love.thread.getChannel( 'load_state' ):clear()
		love.thread.getChannel( 'load_state' ):push(string)
	end
	local function toFormattedValue(value)
	
		if type(value) == "table" and value.digits and value.sign then
			local num = ""
			if value.sign == "-" then
				num = "-"
			end
			for _, digit in pairs(value.digits) do
				num = num .. math.floor(digit) -- lazy way of getting rid of .0$
			end
			return num
		end
		return value
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
			for key, value in pairs(new_replay) do
				new_replay[key] = toFormattedValue(value)
			end
			if new_replay.highscore_data then 
				for key, value in pairs(new_replay.highscore_data) do
					new_replay.highscore_data[key] = toFormattedValue(value)
				end
			end
			love.thread.getChannel('replay'):push(new_replay)
		end
	end
    love.thread.getChannel( 'replay_tree' ):push( replay_tree )
    love.thread.getChannel( 'loaded_replays' ):push( true )
	print("Loaded replays.")
]]