local ArcadeScene = Scene:extend()

ArcadeScene.title = "Arcade"

function ArcadeScene:new()
	self.frames = 0
    DiscordRPC:update({
		details = "In menus",
		state = "Waiting for a credit",
		largeImageKey = "icon2",
		largeImageText = version
	})
end

local block_offsets = {
	{color = "M", x = 0, y = 0},
	{color = "G", x = 32, y = 0},
	{color = "Y", x = 64, y = 0},
	{color = "B", x = 0, y = 32},
	{color = "O", x = 0, y = 64},
	{color = "C", x = 32, y = 64},
	{color = "R", x = 64, y = 64}
}

function ArcadeScene:update()
    self.frames = self.frames + 1
end

function ArcadeScene:render()
	love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds["title_no_icon"],
		0, 0, 0,
		0.5, 0.5
	)

    for _, b in ipairs(block_offsets) do
		love.graphics.draw(
			blocks["2tie"][b.color],
			272 + b.x, 144 + b.y, 0,
			2, 2
		)
	end

    love.graphics.printf("CAMBRIDGE: THE OPEN SOURCE ARCADE STACKER", 0, 256, 640, "center")
    love.graphics.setFont(font_3x5_2)
    love.graphics.setColor(1, 1, 1, 1 - (math.floor(self.frames / 60) % 2))
    love.graphics.printf("Insert 1 credit(s)", 0, 416, 640, "center")
end

return ArcadeScene