print("Loading discord RPC...")
DiscordRPC = {
    loaded = false
}
local success, RPC = pcall(require, "libs.discordRPC")
if success then
    DiscordRPC.loaded = true
    DiscordRPC.appId = "599778517789573120"

    function RPC.ready(userId, username, discriminator, avatar)
        print(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
    end

    function RPC.disconnected(errorCode, message)
        print(string.format("Discord: disconnected (%d: %s)", errorCode, message))
    end

    function RPC.errored(errorCode, message)
        print(string.format("Discord: error (%d: %s)", errorCode, message))
    end

    function RPC.joinGame(joinSecret)
        print(string.format("Discord: join (%s)", joinSecret))
    end

    function RPC.spectateGame(spectateSecret)
        print(string.format("Discord: spectate (%s)", spectateSecret))
    end

    function RPC.joinRequest(userId, username, discriminator, avatar)
        print(string.format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator, avatar))
        RPC.respond(userId, "yes")
    end

    RPC.initialize(DiscordRPC.appId, true)
    local now = os.time(os.date("*t"))
	RPC.updatePresence({
            startTimestamp = now,
            details = "Loading game...",
            state = "",
            largeImageKey = "icon2",
            largeImageText = "Original game by Joe Zeng",
            smallImageKey = "",
            smallImageText = ""
    })
    
    DiscordRPC.RPC = RPC
    print("DiscordRPC successfully loaded.")
else
    print("DiscordRPC failed to load!")
    print(RPC)
end

function DiscordRPC:update(newstuff)
    if self.loaded then self.RPC.updatePresence(newstuff) end
end