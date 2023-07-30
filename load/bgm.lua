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
	pacer_test = "res/bgm/pacer_test.mp3",
}

bgm = {}

for k,v in pairs(bgm_paths) do
	if(type(v) == "table") then
		-- list of subsounds
		for k2,v2 in pairs(v) do
			if(love.filesystem.getInfo(v2)) then
				-- this file exists
				bgm[k] = bgm[k] or {}
				bgm[k][k2] = love.audio.newSource(v2, "stream")
			end
		end
	else
		if(love.filesystem.getInfo(v)) then
			-- this file exists
			bgm[k] = love.audio.newSource(v, "stream")
		end
	end
end


local current_bgm = nil
local bgm_locked = false
local bgm_pitch = 1

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

function setBGMPitch(pitch)
	bgm_pitch = pitch
	if current_bgm ~= nil then
		current_bgm:setPitch(pitch)
	end
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
		current_bgm:setPitch(bgm_pitch)
		current_bgm:play()
	end
end
