local CreditsScene = Scene:extend()

CreditsScene.title = "Credits"

function CreditsScene:new()
    self.frames = 0
    switchBGM("credit_roll", "gm3")
end

function CreditsScene:update()
    self.frames = self.frames + 1
    if self.frames >= 4200 then
        playSE("mode_decide")
        scene = TitleScene()
    elseif self.frames == 3600 then
        fadeoutBGM(2)
    end
end

function CreditsScene:render()
    love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds[19],
		0, 0, 0,
		0.5, 0.5
    )

    love.graphics.setFont(font_3x5_4)
    love.graphics.print("Cambridge Credits", 320, 500 - self.frames / 2)
    love.graphics.print("THANK YOU\nFOR PLAYING!", 320, math.max(1500 - self.frames / 2, 240))

    love.graphics.setFont(font_3x5_3)
    love.graphics.print("Game Developers", 320, 550 - self.frames / 2)
    love.graphics.print("Project Heads", 320, 640 - self.frames / 2)
    love.graphics.print("Other Game Developers", 320, 730 - self.frames / 2)
    love.graphics.print("Special Thanks", 320, 900 - self.frames / 2)
    love.graphics.print("- SashLilac / SpinTriple", 320, math.max(2000 - self.frames / 2, 320))

    love.graphics.setFont(font_3x5_2)
    love.graphics.print("Oshisaure\nJoe Zeng", 320, 590 - self.frames / 2)
    love.graphics.print("Mizu\nHailey", 320, 680 - self.frames / 2)
    love.graphics.print("Axel Fox - Multimino\nMine - Tetra Online\nDr Ocelot - Tetra Legends\nFelicity / nightmareci - Shiromino\n2Tie - TGMsim\nPhoenix Flare - Master of Blocks", 320, 770 - self.frames / 2)
    love.graphics.print(
        "RocketLanterns\nCylinderKnot\nHammrTime\nKirby703\nMattMayuga\nMyPasswordIsWeak\n" ..
        "Nikki Karissa\noffwo\nsinefuse\nTetro48\nTimmSkiller\nuser74003\nAgentBasey\n" ..
        "CheeZed_Fish\neightsixfivezero\nEricICX\ngizmo4487\nM1ssing0\nMarkGamed7794\n" ..
        "pokemonfan1937\nSimon\nstratus\nZaptorZap\nThe Absolute PLUS Discord\nTetra Legends Discord\n" ..
        "Tetra Online Discord\nMultimino Discord\nCambridge Discord\nAnd to you, the player!",
        320, 940 - self.frames / 2
    )
end

function CreditsScene:onInputPress(e)
    if e.input == "menu_decide" or e.scancode == "return" or
       e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		scene = TitleScene()
	end
end

return CreditsScene