-- A helper folder to cleanup main.lua


function recursivelyLoadFromFileTable(dest, source, blacklisted_string)
	--LOVE 12.0 will warn about require strings having forward slashes in them if this is not done.
	for index, name in ipairs(source) do
		if love.filesystem.getInfo(name, "directory") then
			dest[#dest+1] = {name = name, is_directory = true}
			recursivelyLoadFromFileTable(dest[#dest], name, blacklisted_string)
		end
        local require_string = string.gsub(name, "/", ".")
		if name ~= blacklisted_string and name:sub(-4) == ".lua" then
            if package.loaded[require_string:sub(1, -5)] ~= nil then
                package.loaded[require_string:sub(1, -5)] = nil
            end
			dest[#dest+1] = require(require_string:sub(1, -5))
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
			love.filesystem.mount(archive, path, true)
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
            if to_unmount and not config.mod_packs_applied.pack_link[key] then
                unmountAll()
            end
        end
	end
end
