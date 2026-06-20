---@type love.Thread
local io_load_thread
---@type love.Thread
local io_sort_thread

loaded_replays = false

function initReplayList()
	replays = {}
	replay_tree = {{name = "All"}}
	dict_ref = {}
	loaded_replays = false
	collectgarbage("collect")
	for key, value in pairs(recursionStringValueExtract(game_modes, "is_directory")) do
		if not dict_ref[value.name] then
			dict_ref[value.name] = #replay_tree + 1
			replay_tree[#replay_tree + 1] = {name = value.name}
		end
	end
	local directories = love.filesystem.getDirectoryItems("replays")
	for idx, folder_name in pairs(directories) do
		if love.filesystem.getInfo("replays/"..folder_name, "directory") then
			local files = love.filesystem.getDirectoryItems("replays/"..folder_name)
			for k2, file in pairs(files) do
				local file_path = "replays/"..folder_name.."/"..file
				local file_info = love.filesystem.getInfo(file_path)
				replays[#replays+1] = {placeholder = true, timestamp = file_info.modtime, file_path = file_path, folder_name = folder_name}
			end
		end
	end
end

function sortReplayFolder()
	io_sort_thread = love.thread.newThread(replay_sort_code)
	io_sort_thread:start()
end

function loadReplaysInFolder(folder_name)
	if io_load_thread and io_load_thread:isRunning() then
		io_load_thread:wait()
		io_load_thread:release()
		love.thread.getChannel( 'loaded_replays' ):clear()
	end	
	loaded_replays = false
	if not io_load_thread then
		io_load_thread = love.thread.newThread(replay_load_code)
	end
	io_load_thread:start(folder_name)
end

local function putReplayIntoTree(replay, ptr)
	
	local mode_name = replay.mode
	if dict_ref[mode_name] ~= nil and mode_name ~= "znil" then
		table.insert(replay_tree[dict_ref[mode_name] ], ptr)
	end
	local branch_index = 0
	for index, value in ipairs(replay_tree) do
		if value.name == "All" then
			branch_index = index
			for k2, v2 in ipairs(value) do
				if type(v2) == "table" and v2.file_path == replay.file_path then
					value[k2] = replay
				end
			end
			break
		end
	end
	table.insert(replay_tree[branch_index], ptr)
end

function insertReplay(replay)
	for key, value in pairs(replay) do
		replay[key] = toFormattedValue(value)
	end
	if replay.highscore_data then
		for key, value in pairs(replay.highscore_data) do
			replay.highscore_data[key] = toFormattedValue(value)
		end
	end
	local does_placeholder_exist = false
	for ptr, value in pairs(replays) do
		if value.file_path == replay.file_path then
			replays[ptr] = replay
			does_placeholder_exist = true
		end
	end
	if not does_placeholder_exist then
		replays[#replays+1] = replay
	end
	putReplayIntoTree(replay, #replays)
end

function refreshReplayTree()
	replay_tree = {{name = "All", all_files = true}}
	dict_ref = {}
	for key, value in pairs(recursionStringValueExtract(game_modes, "is_directory")) do
		if not dict_ref[value.name] then
			dict_ref[value.name] = #replay_tree + 1
			replay_tree[#replay_tree + 1] = {name = value.name}
		end
	end
	for ptr, replay in pairs(replays) do
		putReplayIntoTree(replay, ptr)
	end
	sortReplays()
end

function sortReplays()
	if not replay_tree then return end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(replay_tree, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	for key, submenu in pairs(replay_tree) do
		table.sort(submenu, function(a, b)
			return replays[a]["timestamp"] > replays[b]["timestamp"]
		end)
	end
end

function disposeReplayThread()
	if io_load_thread then
		io_load_thread:release()
	end
	if io_sort_thread then
		io_sort_thread:release()
	end
end

replay_sort_code = [[
	function setState(string)
		print(string)
		love.thread.getChannel( 'load_state' ):clear()
		love.thread.getChannel( 'load_state' ):push(string)
	end
	setState("Loading replay file list")
	local replay_file_list = love.filesystem.getDirectoryItems("replays")
	local binser = require "libs.binser"
	require "funcs"
	setState("Loading and sorting replay contents")
	for i=1, #replay_file_list do
		local old_replay_path = "replays/"..replay_file_list[i]
		if love.filesystem.getInfo(old_replay_path, "file") then
			local data = love.filesystem.read(old_replay_path)
			local success, new_replay = pcall(
				function() return binser.deserialize(data)[1] end
			)
			if new_replay == nil or not success then
				love.filesystem.remove(old_replay_path)
				print("The replay at ".. old_replay_path .." is corrupted or has no data. It has thus been deleted.")
			else
				local item_info = love.filesystem.getInfo(old_replay_path)
				if item_info.type == "file" then
					-- it grabs the mode name, since it's in every replay since 6th of December, 2021
					local folder_name = new_replay.mode or "undefined"
					if not love.filesystem.getInfo("replays/"..folder_name, "directory") then
						love.filesystem.createDirectory("replays/"..folder_name)
					end
					local new_replay_path = "replays/"..folder_name.."/"..replay_file_list[i]
					local write_success, message = love.filesystem.write(new_replay_path, data)
					if not write_success then
						love.filesystem.remove(new_replay_path)
						assert(write_success, "Failed to save file: "..new_replay_path..". Error message: "..(message or "nil"))
					else
						love.filesystem.remove(old_replay_path)
					end
				end
			end
			love.thread.getChannel('progress'):push(i)
		end
	end
	love.thread.getChannel( 'loaded_replays' ):push(true)
	print("Sorted replays.")
]]

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
	local folder_name = ({...})[1]
	setState("Loading replay file list")
	local replay_file_list = love.filesystem.getDirectoryItems("replays/"..folder_name)
	local binser = require "libs.binser"
	require "funcs"
	setState("Loading replay contents")
	for i=1, #replay_file_list do
		local replay_path = "replays/"..folder_name.."/"..replay_file_list[i]
		local data = love.filesystem.read(replay_path)
		local success, new_replay = pcall(
			function() return binser.deserialize(data)[1] end
		)
		if new_replay == nil or not success then
			love.filesystem.remove(replay_path)
			print("The replay at ".. replay_path .." is corrupted or has no data. It has thus been deleted.")
		else
			for key, value in pairs(new_replay) do
				new_replay[key] = toFormattedValue(value)
			end
			if new_replay.highscore_data then 
				for key, value in pairs(new_replay.highscore_data) do
					new_replay.highscore_data[key] = toFormattedValue(value)
				end
			end
			new_replay.file_path = replay_path
			love.thread.getChannel('replay'):push(new_replay)
		end
	end
	love.thread.getChannel( 'loaded_replays' ):push(true)
	print("Loaded replays.")
]]