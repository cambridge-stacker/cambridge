local Object = require "libs.classic"

Scene = Object:extend()

function Scene:new() end
function Scene:update() end
function Scene:render() end
function Scene:onInputPress() end
function Scene:onInputRelease() end

ExitScene = require "scene.exit"
GameScene = require "scene.game"
ModeSelectScene = require "scene.mode_select"
KeyConfigScene = require "scene.key_config"
StickConfigScene = require "scene.stick_config"
InputConfigScene = require "scene.input_config"
GameConfigScene = require "scene.game_config"
TuningScene = require "scene.tuning"
SettingsScene = require "scene.settings"
CreditsScene = require "scene.credits"
TitleScene = require "scene.title"
