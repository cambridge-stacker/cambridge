local Sequence = require 'tetris.randomizers.fixed_sequence'
local binser   = require 'libs.binser'
local sha2     = require 'libs.sha2'

local ReplayScene = Scene:extend()

ReplayScene.title = "Replay"

local savestate_frames = nil
local state_loaded = false

function ReplayScene:new(replay, game_mode, ruleset)
	config.gamesettings = replay["gamesettings"]
	if replay["delayed_auto_shift"] then config.das = replay["delayed_auto_shift"] end
	if replay["auto_repeat_rate"] then config.arr = replay["auto_repeat_rate"] end

	if replay["das_cut_delay"] then config.dcd = replay["das_cut_delay"] end
	love.math.setRandomSeed(replay["random_low"], replay["random_high"])
	love.math.setRandomState(replay["random_state"])
	self.sha_tbl = {mode = sha2.sha256(binser.s(game_mode)), ruleset = sha2.sha256(binser.s(ruleset))}
	self.retry_replay = replay
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = replay["secret_inputs"]
	self.replay = deepcopy(replay)
	self.game = game_mode(self.secret_inputs, self.replay.properties)
	self.game.save_replay = false
	self.ruleset = ruleset(self.game)
	self.game:initialize(self.ruleset)
	self.inputs = {
		left=false,
		right=false,
		up=false,
		down=false,
		rotate_left=false,
		rotate_left2=false,
		rotate_right=false,
		rotate_right2=false,
		rotate_180=false,
		hold=false,
	}
	self.paused = false
	self.replay_index = 1
	self.replay_speed = 1
	self.frames = 0
	self.relative_frames = 0
	DiscordRPC:update({
		details = "Viewing a replay",
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function ReplayScene:replayCutoff()
	self.retry_replay["inputs"][self.replay_index]["frames"] = self.relative_frames
	for i = self.replay_index + 1, #self.retry_replay["inputs"] do
		self.retry_replay.inputs[i] = nil
	end
end

function ReplayScene:update()
	local frames_left = self.replay_speed
	local pre_sfx_volume
	if TAS_mode and state_loaded then
		pre_sfx_volume = config.sfx_volume
		config.sfx_volume = 0	--This is to stop blasting your ears every time you load a state.
		frames_left = savestate_frames
	end
	if love.window.hasFocus() and (not self.paused or frame_steps > 0) and (TAS_mode or not self.rerecord) then
		if frame_steps > 0 then
			self.game.ineligible = self.rerecord or self.game.ineligible
			frame_steps = frame_steps - 1
		end
		while frames_left > 0 do
			frames_left = frames_left - 1
			self.inputs = self.replay["inputs"][self.replay_index]["inputs"]
			self.replay["inputs"][self.replay_index]["frames"] = self.replay["inputs"][self.replay_index]["frames"] - 1
			self.relative_frames = self.relative_frames + 1
			self.frames = self.frames + 1
			if self.replay["inputs"][self.replay_index]["frames"] == 0 and self.replay_index < #self.replay["inputs"] then
				self.replay_index = self.replay_index + 1
				self.relative_frames = 1
			end
			local input_copy = {}
			for input, value in pairs(self.inputs) do
				input_copy[input] = value
			end
			self.game:update(input_copy, self.ruleset)
			self.game.grid:update()
		end
	elseif self.rerecord and not self.paused then
		local input_copy = {}
		for input, value in pairs(self.inputs) do
			input_copy[input] = value
		end
		self.frames = self.frames + 1
		self.game:update(input_copy, self.ruleset)
		self.game.grid:update()
	end
	if state_loaded then
		state_loaded = false
		config.sfx_volume = pre_sfx_volume --Returns the volume to normal.
		self.paused = true
	end
	DiscordRPC:update({
		details = self.rerecord and self.game.rpc_details or ("Viewing a".. (self.replay["toolassisted"] and " tool-assisted" or "") .." replay"),
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
	
	if love.thread.getChannel("savestate"):peek() == "save" then
		love.thread.getChannel("savestate"):clear()
		savestate_frames = self.frames
		print("State saved at frame "..self.frames)
	end

	if love.thread.getChannel("savestate"):peek() == "load" then
		love.thread.getChannel("savestate"):clear()
		if savestate_frames == nil then
			print("Load the state first. Press F4 for that. Alt-F4 will close the game, so, keep that in mind.")
			return
		end
		--restarts like usual, but not really.
		self.game:onExit()
		scene = ReplayScene(
			self.retry_replay, self.retry_mode,
			self.retry_ruleset, self.secret_inputs
		)
		state_loaded = true
	end
end

function ReplayScene:render()
	self.game:draw(self.paused)
	if self.rerecord then
		return
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	if self.replay["toolassisted"] then
		love.graphics.printf("TAS REPLAY", 0, 0, 635, "right")
	else
		love.graphics.printf("REPLAY", 0, 0, 635, "right")
	end
	if self.replay_speed > 1 then
		love.graphics.printf(self.replay_speed.."X", 0, 20, 635, "right")
	end
end

function ReplayScene:onInputPress(e)
	if (
		e.input == "menu_back" or
		e.input == "menu_decide" or
		e.input == "mode_exit" or
		e.input == "retry"
 	) then
		self.game:onExit()
		loadSave()
		love.math.setRandomSeed(os.time())
		-- quite dependent on async replay loading
		if self.rerecord then loadReplayList() end
		scene = (
			(e.input == "retry") and
			ReplayScene(
				self.retry_replay, self.retry_mode,
				self.retry_ruleset, self.secret_inputs
			) or ReplaySelectScene()
	 	)
		savestate_frames = nil
	elseif e.input == "frame_step" and (TAS_mode or not self.rerecord) then
		frame_steps = frame_steps + 1
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then pauseBGM()
		else resumeBGM() end
	elseif e.input and string.sub(e.input, 1, 5) ~= "menu_" and self.rerecord and e.input ~= "frame_step" then
		self.inputs[e.input] = true
	elseif e.input == "hold" then
		self.rerecord = true
		savestate_frames = self.frames
		self:replayCutoff()
		self.replay_speed = 1
		self.game.save_replay = config.gamesettings.save_replay == 1
		self.game.replay_inputs = self.retry_replay.inputs
		self.paused = true
	elseif e.input == "left" then
		self.replay_speed = self.replay_speed - 1
		if self.replay_speed < 1 then
			self.replay_speed = 1
		end
	elseif e.input == "right" then
		self.replay_speed = self.replay_speed + 1
		if self.replay_speed > 99 then
			self.replay_speed = 99
		end
	end
end

function ReplayScene:onInputRelease(e)
	if e.input and string.sub(e.input, 1, 5) ~= "menu_" and self.rerecord then
		self.inputs[e.input] = false
	end
end

return ReplayScene
