local CreditsScene = Scene:extend()

CreditsScene.title = "Credits"

function CreditsScene:new()
    self.frames = 0
    -- higher = slower
    self.scroll_speed = 1.9
    switchBGM("credit_roll", "gm3")
end

function CreditsScene:update()
    if love.window.hasFocus() then
        self.frames = self.frames + 1
    end
    if self.frames >= 2100 * self.scroll_speed then
        playSE("mode_decide")
        scene = TitleScene()
        switchBGM(nil)
    elseif self.frames == math.floor(1950 * self.scroll_speed) then
        fadeoutBGM(2)
    end
end

function CreditsScene:render()
    local offset = self.frames / self.scroll_speed
    
    love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds[19],
		0, 0, 0,
		0.5, 0.5
    )

    love.graphics.setFont(font_3x5_4)
    love.graphics.print("Cambridge Credits", 320, 500 - offset)
    love.graphics.print("THANK YOU\nFOR PLAYING!", 320, math.max(2010 - offset, 240))

    love.graphics.setFont(font_3x5_3)
    love.graphics.print("Game Developers", 320, 550 - offset)
    love.graphics.print("Project Heads", 320, 640 - offset)
    love.graphics.print("Notable Game Developers", 320, 730 - offset)
    love.graphics.print("Special Thanks", 320, 980 - offset)
    love.graphics.print("- Milla", 320, math.max(2090 - offset, 320))

    love.graphics.setFont(font_3x5_2)
    love.graphics.print("Oshisaure\nJoe Zeng", 320, 590 - offset)
    love.graphics.print("Mizu\nMarkGamed", 320, 680 - offset)
    love.graphics.print(
        "2Tie - TGMsim\nAxel Fox - Multimino\nDr Ocelot - Tetra Legends\n" ..
        "Electra - ZTrix\nFelicity/nightmareci/kdex - Shiromino\n" ..
        "Mine - Tetra Online\nMrZ - Techmino\nosk - TETR.IO\n" ..
        "Phoenix Flare - Master of Blocks\nRayRay26 - Spirit Drop\n" ..
        "sinefuse - stackfuse",
        320, 770 - offset
    )
    love.graphics.print(
        "321MrHaatz\nAdventium\nAgentBasey\nArchina\nAurora\n" ..
        "Caithness\nCheez\ncolour_thief\nCommando\nCublex\n" ..
        "CylinderKnot\neightsixfivezero\nEricICX\nGesomaru\n" ..
        "gizmo4487\nJBroms\nKirby703\nKitaru\n" ..
        "M1ssing0\nMattMayuga\nMyPasswordIsWeak\n" ..
        "Nikki Karissa\noffwo\nOliver\nPineapple\npokemonfan1937\n" ..
        "Pyra Neoxi\nRDST64\nRocketLanterns\nRustyFoxxo\n" ..
        "saphie\nShelleloch\nSimon\nstratus\nSuper302\n" ..
        "switchpalacecorner\nterpyderp\nTetrian22\nTetro48\nThatCookie\n" ..
        "TimmSkiller\nTrixciel\nuser74003\nZaptorZap\nZircean\n" ..
        "All other contributors and friends!\nThe Absolute PLUS Discord\n" ..
        "Tetra Legends Discord\nTetra Online Discord\nMultimino Discord\n" ..
        "Hard Drop Discord\nRusty's Systemspace\nCambridge Discord\n" ..
        "And to you, the player!",
        320, 1020 - offset
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