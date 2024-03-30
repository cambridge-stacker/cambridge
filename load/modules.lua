
---@param tbl table
---@param directory string
---@param blacklisted_string string
function recursivelyLoadRequireFileTable(tbl, directory, blacklisted_string)
	--LOVE 12.0 will warn about require strings having forward slashes in them if this is not done.
	local require_string = string.gsub(directory, "/", ".")
	local list = love.filesystem.getDirectoryItems(directory)
	for index, name in ipairs(list) do
		if love.filesystem.getInfo(directory.."/"..name, "directory") then
			tbl[#tbl+1] = {name = name, is_directory = true}
			recursivelyLoadRequireFileTable(tbl[#tbl], directory.."/"..name, blacklisted_string)
		end
		if name ~= blacklisted_string and name:sub(-4) == ".lua" then
			tbl[#tbl+1] = require(require_string.."."..name:sub(1, -5))
			if not (type(tbl[#tbl]) == "table" and type(tbl[#tbl].__call) == "function") then
				error("Add a return to "..directory.."/"..name..".\nMust be a table with __call function.", 1)
			end
		end
	end
end

function unloadModules()
	--module reload.
	for key, value in pairs(package.loaded) do
		if string.sub(key, 1, 7) == "tetris." then
			package.loaded[key] = nil
		end
	end
end

---This shouldn't run more than once on the same table.
---@param init table
function recursivelyTagModules(init, tbl, tag_tbl)
	if not tbl then tbl = init end
	if not tag_tbl then tag_tbl = {} end
	for k, v in pairs(tbl) do
		if type(v) == "table" and v.is_directory == true and not (v.is_tag) then
			recursivelyTagModules(init, v, tag_tbl)
		end
		if type(v) == "table" and type(v.tags) == "table" then
			for k2, v2 in pairs(v.tags) do
				tag_tbl[v2] = tag_tbl[v2] or {name = v2, is_directory = true, is_tag = true}
				table.insert(tag_tbl[v2], v)
			end
		end
	end
	if init ~= tbl then return end

	local sorted_tags = {}
	--#region Sort tag names
	for key, value in pairs(tag_tbl) do
		table.insert(sorted_tags, value)
	end
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(sorted_tags, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	--#endregion

	for key, value in ipairs(sorted_tags) do
		table.insert(init, value)
	end
end

function initModules()
	game_modes = {}
	recursivelyLoadRequireFileTable(game_modes, "tetris/modes", "gamemode.lua")
	rulesets = {}
	recursivelyLoadRequireFileTable(rulesets, "tetris/rulesets", "ruleset.lua")

	loadModpacks()

	--sort mode/rule lists
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(game_modes, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	table.sort(rulesets, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	recursivelyTagModules(game_modes)
	recursivelyTagModules(rulesets)
end

--#region Modpack handler

function recursivelyLoadFromFileTable(dest, source, blacklisted_string)
	--LOVE 12.0 will warn about require strings having forward slashes in them if this is not done.
	for index, name in ipairs(source) do
		if love.filesystem.getInfo(name, "directory") then
			dest[#dest+1] = {name = name, is_directory = true}
			recursivelyLoadFromFileTable(dest[#dest], name, blacklisted_string)
		end
		local require_string = string.gsub(name, "/", "."):sub(1, -5)
		if name ~= blacklisted_string and name:sub(-4) == ".lua" then
			if package.loaded[require_string] ~= nil then
				package.loaded[require_string] = nil
			end
			dest[#dest+1] = require(require_string)
			if not (type(dest[#dest]) == "table" and type(dest[#dest].__call) == "function") then
				error("Add a return to "..name..".\nMust be a table with __call function.", 1)
			end
		end
	end
end
function recursivelyListLuaFileTable(table, directory, truncate_first_chars)
	local list = love.filesystem.getDirectoryItems(directory)
	for index, name in ipairs(list) do
		
		if love.filesystem.getInfo(directory.."/"..name, "directory") then
			table[#table+1] = {name = name, is_directory = true}
			recursivelyListLuaFileTable(table[#table], directory.."/"..name, truncate_first_chars)
		end
		if name:sub(-4) == ".lua" then
			table[#table+1] = directory:sub(truncate_first_chars).."/"..name
		end
	end
end

function loadModpacks()
	config.mod_packs_applied = config.mod_packs_applied or {pack_link = {}}
	if type(config.mod_packs_applied) == "table" then
		local mounts = {}
		local function unmountAll()
			for key, value in pairs(mounts) do
				love.filesystem.unmount(value)
				-- mounts[key] = nil
			end
		end
		local function mount(archive, path)
			mounts[#mounts+1] = archive
			love.filesystem.mount(archive, path, false)
		end
		local pack_list = {}
		for index, value in ipairs(config.mod_packs_applied) do
			mount("modpacks/"..value, "listing")
			pack_list[#pack_list+1] = {name = value, modes = {}, rulesets = {}}
			recursivelyListLuaFileTable(pack_list[#pack_list].modes, "listing/tetris/modes", 9)
			recursivelyListLuaFileTable(pack_list[#pack_list].rulesets, "listing/tetris/rulesets", 9)
			unmountAll()
			mounts[1] = nil
		end
		for key, value in ipairs(pack_list) do
			mount("modpacks/"..value.name, "")
			local to_unmount = false
			for i = key, #config.mod_packs_applied.pack_link do
				if config.mod_packs_applied.pack_link[i] and not mounts[i+1] then
					mount("modpacks/"..value.name, "")
				else
					to_unmount = true
					break
				end
			end
			game_modes[#game_modes+1] = {name = value.name, is_directory = true, from_modpack = true}
			rulesets[#rulesets+1] = {name = value.name, is_directory = true, from_modpack = true}
			recursivelyLoadFromFileTable(game_modes[#game_modes], value.modes, "gamemode.lua")
			recursivelyLoadFromFileTable(rulesets[#rulesets], value.rulesets, "ruleset.lua")
			local function padnum(d) return ("%03d%s"):format(#d, d) end
			table.sort(game_modes[#game_modes], function(a,b)
			return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
			table.sort(rulesets[#rulesets], function(a,b)
			return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
			if to_unmount and not config.mod_packs_applied.pack_link[key] then
				unmountAll()
			end
		end
	end
end

--#endregion
