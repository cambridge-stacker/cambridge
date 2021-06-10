bgm = {
	credit_roll = {
		gm3 = love.audio.newSource("res/bgm/tgm_credit_roll.mp3", "stream"),
	},
	pacer_test = love.audio.newSource("res/bgm/pacer_test.mp3", "stream"),
}

local current_bgm = nil
local bgm_locked = false

function switchBGM(sound, subsound)
	if current_bgm ~= nil then
		current_bgm:stop()
	end
	if bgm_locked or config.bgm_volume <= 0 then
		current_bgm = nil
	elseif sound ~= nil then
		if subsound ~= nil then
			current_bgm = bgm[sound][subsound]
		else
			current_bgm = bgm[sound]
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
	current_bgm:play()
end

function processBGMFadeout(dt)
	if current_bgm and fading_bgm then
		fadeout_time = fadeout_time - dt
		if fadeout_time < 0 then
			fadeout_time = 0
			fading_bgm = false
		end
		current_bgm:setVolume(fadeout_time * config.bgm_volume / total_fadeout_time)
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
	end
end
