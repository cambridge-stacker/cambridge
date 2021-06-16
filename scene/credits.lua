local CreditsScene = Scene:extend()

CreditsScene.title = "Credits"

function CreditsScene:new()
    self.frames = 0
    switchBGM("credit_roll", "gm3")
end

function CreditsScene:update()
    if love.window.hasFocus() then
        self.frames = self.frames + 1
    end
    if self.frames >= 4200 then
        playSE("mode_decide")
        scene = TitleScene()
        switchBGM(nil)
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
    love.graphics.print("THANK YOU\nFOR PLAYING!", 320, math.max(1910 - self.frames / 2, 240))

    love.graphics.setFont(font_3x5_3)
    love.graphics.print("Game Developers", 320, 550 - self.frames / 2)
    love.graphics.print("Project Heads", 320, 640 - self.frames / 2)
    love.graphics.print("Notable Game Developers", 320, 730 - self.frames / 2)
    love.graphics.print("Special Thanks", 320, 950 - self.frames / 2)
    love.graphics.print("- Milla", 320, math.max(1990 - self.frames / 2, 320))

    love.graphics.setFont(font_3x5_2)
    love.graphics.print("Oshisaure\nJoe Zeng", 320, 590 - self.frames / 2)
    love.graphics.print("Mizu\nMarkGamed", 320, 680 - self.frames / 2)
    love.graphics.print(
        "2Tie - TGMsim\nAxel Fox - Multimino\nDr Ocelot - Tetra Legends\n" ..
        "Felicity/nightmareci/kdex - Shiromino\nMine - Tetra Online\n" ..
        "osk - TETR.IO\nPhoenix Flare - Master of Blocks\nRayRay26 - Spirit Drop\n" ..
        "sinefuse - stackfuse",
        320, 770 - self.frames / 2
    )
    love.graphics.print(
        "321MrHaatz\nAgentBasey\nAdventium\nArchina\nAurora\n" ..
        "Caithness\nCheez\ncolour_thief\nCommando\nCublex\n" ..
        "CylinderKnot\nEricICX\neightsixfivezero\nGesomaru\n" ..
        "gizmo4487\nJBroms\nKirby703\nKitaru\n" ..
        "M1ssing0\nMattMayuga\nMyPasswordIsWeak\n" ..
        "Nikki Karissa\noffwo\nOliver\nPyra Neoxi\n" ..
        "pokemonfan1937\nRDST64\nRocketLanterns\nRustyFoxxo\n" ..
        "saphie\nSimon\nstratus\nSuper302\n" ..
        "switchpalacecorner\nterpyderp\nTetrian22\nTetro48\n" ..
        "TimmSkiller\nTrixciel\nuser74003\nZaptorZap\nZircean\n" ..
        "All other contributors and friends!\n" ..
        "The Absolute PLUS Discord\nTetra Legends Discord\nTetra Online Discord\n" ..
        "Multimino Discord\nHard Drop Discord\nCambridge Discord\n" ..
        "And to you, the player!",
        320, 990 - self.frames / 2
    )
end

function CreditsScene:onInputPress(e)
    if e.input == "menu_decide" or e.scancode == "return" or
       e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
        scene = TitleScene()
        switchBGM(nil)
	end
end

return CreditsScene