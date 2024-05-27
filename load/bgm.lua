bgm_paths = {
	"res/bgm/track1.mp3",
	"res/bgm/track2.mp3",
	"res/bgm/track3.mp3",
	"res/bgm/track4.mp3",
	"res/bgm/track5.mp3",
	"res/bgm/track6.mp3",
	"res/bgm/track7.mp3",
	"res/bgm/track8.mp3",
	"res/bgm/track9.mp3",
	"res/bgm/track10.mp3",
	credit_roll = {
		gm3 = "res/bgm/tgm_credit_roll.mp3",
	},
	a3 = {
		track1 = "res/bgm/a3_track1.mp3",
		track2 = "res/bgm/a3_track2.mp3",
		track3 = "res/bgm/a3_track3.mp3",
		track4 = "res/bgm/a3_track4.mp3",
		track5 = "res/bgm/a3_track5.mp3",
		track6 = "res/bgm/a3_track6.mp3",
		credit_roll = "res/bgm/tgm_credit_roll.mp3",
	},
	pacer_test = "res/bgm/pacer_test.mp3",
}

bgm = {}

function loadBGM(path, sound, subsound)
	if love.filesystem.getInfo(applied_packs_path..path) then
		path = applied_packs_path..path
	end
	if(love.filesystem.getInfo(path)) then
		-- this file exists
		if subsound then
			bgm[sound] = bgm[sound] or {}
			bgm[sound][subsound] = love.audio.newSource(path, "stream")
		else
			bgm[sound] = love.audio.newSource(path, "stream")
		end
	end
end

---@param sound string
---@param tbl table
function loadBGMsFromTable(sound, tbl)
	for key, value in pairs(tbl) do
		loadBGM(value, sound, key)
	end
end

function generateBGMTable()
	for k,v in pairs(bgm_paths) do
		if(type(v) == "table") then
			-- list of subsounds
			for k2,v2 in pairs(v) do
				loadBGM(v2, k, k2)
			end
		else
			if(love.filesystem.getInfo(v)) then
				loadBGM(v, k)
			end
		end
	end
end


local current_bgm = nil
local pitch = 1
local bgm_locked = false

function switchBGM(sound, subsound)
	if bgm_locked then
		return
	end
	if current_bgm ~= nil then
		current_bgm:stop()
	end
	if config.bgm_volume <= 0 then
		current_bgm = nil
	elseif sound ~= nil then
		if bgm[sound] ~= nil then
			if subsound ~= nil then
				if bgm[sound][subsound] ~= nil then
					current_bgm = bgm[sound][subsound]
				end
			else
				if type(bgm[sound]) == "table" then
					error("Tried to play a table.")
				end
				current_bgm = bgm[sound]
			end
		end
	else
		current_bgm = nil
	end
	if current_bgm ~= nil then
		resetBGMFadeout()
	end
end

function switchBGMLoop(sound, subsound)
	switchBGM(sound, subsound)
	if current_bgm then current_bgm:setLooping(true) end
end

function lockBGM()
	bgm_locked = true
end

function unlockBGM()
	bgm_locked = false
end

local fading_bgm = false
local fadeout_time = 0
local total_fadeout_time = 0

function fadeoutBGM(time)
	if fading_bgm == false then
		fading_bgm = true
		fadeout_time = time
		total_fadeout_time = time
	end
end

function resetBGMFadeout(time)
	current_bgm:setVolume(config.bgm_volume)
	fading_bgm = false
	resumeBGM()
end

function processBGMFadeout(dt)
	if current_bgm and fading_bgm then
		fadeout_time = fadeout_time - dt
		if fadeout_time < 0 then
			fadeout_time = 0
			fading_bgm = false
		end
		current_bgm:setVolume(
			fadeout_time * config.bgm_volume / total_fadeout_time
		)
	end
end

function pauseBGM()
	if current_bgm ~= nil then
		current_bgm:pause()
	end
end

function resumeBGM()
	if current_bgm ~= nil then
		current_bgm:play()
		current_bgm:setPitch(pitch)
	end
end

function pitchBGM(new_pitch)
	pitch = new_pitch
	if current_bgm ~= nil then
		current_bgm:setPitch(pitch)
	end
end
