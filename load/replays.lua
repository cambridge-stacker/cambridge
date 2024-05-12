---@type love.Thread
local io_thread

loaded_replays = false

function loadReplayList()
	replays = {}
	replay_tree = {{name = "All"}}
	dict_ref = {}
	loaded_replays = false
	collectgarbage("collect")

	--proper disposal to avoid some memory problems
	if io_thread then
		io_thread:release()
		love.thread.getChannel( 'replay' ):clear()
		love.thread.getChannel( 'loaded_replays' ):clear()
	end

	io_thread = love.thread.newThread( replay_load_code )
	for key, value in pairs(recursionStringValueExtract(game_modes, "is_directory")) do
		if not dict_ref[value.name] then
			dict_ref[value.name] = #replay_tree + 1
			replay_tree[#replay_tree + 1] = {name = value.name}
		end
	end
	io_thread:start()
end

function disposeReplayThread()
	if io_thread then
		io_thread:release()
	end
end

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
			for id, digit in pairs(value.digits) do
				if not value.dense or id == 1 then
					num = num .. math.floor(digit) -- lazy way of getting rid of .0$
				else
					num = num .. string.format("%07d", digit)
				end
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
		local success, new_replay = pcall(
			function() return binser.deserialize(data)[1] end
		)
		if new_replay == nil or not success then
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