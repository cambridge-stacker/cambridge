
print("Loading Discord GameSDK...")
DiscordGameSDK = {
	loaded = false
}
local success, libDiscordGameSDK = pcall(require, "libs.discordGameSDK")
if success then
	DiscordGameSDK.loaded = true

	print("Discord GameSDK successfully loaded")
else
	print("Discord GameSDK failed to load!")
end