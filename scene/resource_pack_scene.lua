local ResourcePackScene = Scene:extend()

ResourcePackScene.title = "Resource Packs"

function ResourcePackScene:new()
    config.resource_packs_applied = config.resource_packs_applied or {}
    self.old_scene = scene
    self.valid_resource_packs = {}
    self.resource_pack_index = {}
    ---@type {[...]:string}
    local resource_packs = love.filesystem.getDirectoryItems("resourcepacks")
    for key, value in pairs(resource_packs) do
        if value:sub(-4) == ".zip" and love.filesystem.getInfo("resourcepacks/"..value, "file") then
            self.valid_resource_packs[#self.valid_resource_packs+1] = value
            self.resource_pack_index[value] = #self.valid_resource_packs
        end
    end
    self.left_menu_height = 0
    self.left_menu_height_shift = 0
    self.right_menu_height = 0
    self.right_menu_height_shift = 0
    self.left_selection_index = 1
    self.right_selection_index = 1
    self.selection_type = 0
    self:refreshPackSelection()
end

function ResourcePackScene:refreshPackSelection()
    self.selected_resource_packs = {}
    self.unselected_resource_packs = {}
    for key, value in pairs(config.resource_packs_applied) do
        self.selected_resource_packs[#config.resource_packs_applied - key + 1] = value
    end
    for key, value in pairs(self.valid_resource_packs) do
        if not table.contains(config.resource_packs_applied, value) then
            self.unselected_resource_packs[#self.unselected_resource_packs+1] = value
        end
    end
end

function ResourcePackScene:update()
    if self.left_selection_index > (self.left_menu_height_shift / 40) + 6 then
        self.left_menu_height_shift = self.left_menu_height_shift + 40
    end
    if self.right_selection_index > (self.right_menu_height_shift / 40) + 6 then
        self.right_menu_height_shift = self.right_menu_height_shift + 40
    end
    if self.left_selection_index < (self.left_menu_height_shift / 40) + 2 then
        self.left_menu_height_shift = self.left_menu_height_shift - 40
    end
    if self.right_selection_index < (self.right_menu_height_shift / 40) + 2 then
        self.right_menu_height_shift = self.right_menu_height_shift - 40
    end
end

function ResourcePackScene:render()
    drawBackground("options_input")
    local alpha = 1
    if self.selection_type ~= 1 then
        alpha = 0.5
    end
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.setLineWidth(2)
    alpha = 0.5
    love.graphics.rectangle("line", 55, 55 - self.left_menu_height + 40 * self.left_selection_index, 250, 40)
    if self.selection_type == 2 then
        alpha = 1
    end
    self.left_menu_height = interpolateListPos(self.left_menu_height, math.max(self.left_menu_height_shift, 0))
    self.right_menu_height = interpolateListPos(self.right_menu_height, math.max(self.right_menu_height_shift, 0))
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.rectangle("line", 355, 55 - self.right_menu_height + 40 * self.right_selection_index, 250, 40)
    alpha = 0.5
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Select Resource Packs", 0, 10, 640, "center")
    love.graphics.setColor(1,1,1,FadeoutAtEdges(
        -(self.left_menu_height + 160),
        160,
        40))
    love.graphics.printf("Available", 100, 40 - self.left_menu_height, 160, "center")
    love.graphics.printf("_________", 100, 44 - self.left_menu_height, 160, "center")
    love.graphics.setColor(1,1,1,FadeoutAtEdges(
        -(self.right_menu_height + 160),
        160,
        40))
    love.graphics.printf("Selected", 400, 40 - self.right_menu_height, 160, "center")
    love.graphics.printf("________", 400, 44 - self.right_menu_height, 160, "center")
    -- love.graphics.setCanvas(self.left_canvas)
    for key, value in pairs(self.unselected_resource_packs) do
        
        love.graphics.setColor(1,1,1,FadeoutAtEdges(
            -(self.left_menu_height + 160) + 40 * key,
            120,
            40))
        love.graphics.printf(value, 60, 60 - self.left_menu_height + 40 * key, 240, "left")
    end
    for key, value in pairs(self.selected_resource_packs) do
        love.graphics.setColor(1,1,1,FadeoutAtEdges(
            -(self.right_menu_height + 160) + 40 * key,
            120,
            40))
        love.graphics.printf(value, 360, 60 - self.right_menu_height + 40 * key, 240, "left")
    end

    if self.selection_type == 3 then
        alpha = 1
    end
    love.graphics.setColor(1,1,1,alpha)
    alpha = 0.5
    love.graphics.rectangle("line", 80, 400, 160, 30)
    if self.selection_type == 4 then
        alpha = 1
    end
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.rectangle("line", 400, 400, 160, 30)
    love.graphics.setLineWidth(1)

    local b = CursorHighlight(80, 400, 160, 30)
    love.graphics.setColor(1,1,b,1)
    love.graphics.printf("Open Pack Folder", 80, 405, 160, "center")
    b = CursorHighlight(400, 400, 160, 30)
    love.graphics.setColor(1,1,b,1)
    love.graphics.printf("Done", 400, 405, 160, "center")
end

function ResourcePackScene:onInputPress(e)
    if e.type == "mouse" then
        if e.x > 80 and e.y > 400 and e.x < 240 and e.y < 430 then
            playSE("main_decide")
            love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/resourcepacks/")
        end
        if e.x > 400 and e.y > 400 and e.x < 560 and e.y < 430 then
            playSE("mode_decide")
            saveConfig()
            loadResourcePacks()
            scene = self.old_scene
        end
    end
    if e.input == "hold" then
        self.hold_swap = true
    end
    if e.input == "menu_decide" then
        
        if self.selection_type == 1 then
            table.insert(config.resource_packs_applied, self.unselected_resource_packs[self.left_selection_index])
            self.left_selection_index = math.max(self.left_selection_index - 1, 1)
            self:refreshPackSelection()
        elseif self.selection_type == 2 then
            table.remove(config.resource_packs_applied, #self.selected_resource_packs - self.right_selection_index + 1)
            self.right_selection_index = math.max(self.right_selection_index - 1, 1)
            self:refreshPackSelection()
        elseif self.selection_type == 3 then
            playSE("main_decide")
            love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/resourcepacks/")
        end
    end
    local dividend = (self.selection_type == 2 and #self.selected_resource_packs or #self.unselected_resource_packs)
    if dividend < 1 then
        dividend = 1
    end
    local old_right_selection_index = self.right_selection_index
    if e.input == "up" or e.input == "down" then
        if self.selection_type == 0 then
            self.selection_type = 1
            return
        end
        local inc_or_dec = (e.input == "down" and 1 or -1)
        if self.selection_type == 1 then
            if self.left_selection_index + inc_or_dec > dividend then
                self.selection_type = 3
                return
            end
            self.left_selection_index = math.max(self.left_selection_index + inc_or_dec, 1)
        elseif self.selection_type == 2 then
            if self.right_selection_index + inc_or_dec > dividend then
                self.selection_type = 4
                return
            end
            self.right_selection_index = math.max(self.right_selection_index + inc_or_dec, 1)
        elseif self.selection_type > 2 and e.input == "up" then
            self.selection_type = self.selection_type - 2
        end
    end
    if e.input == "left" then
        if self.selection_type == 0 then
            self.selection_type = 1
            return
        end
        if self.selection_type % 2 == 0 then
            self.selection_type = self.selection_type - 1
        end
    end
    if e.input == "right" then
        if self.selection_type == 0 then
            self.selection_type = 1
            return
        end
        if self.selection_type % 2 == 1 then
            self.selection_type = self.selection_type + 1
        end
    end
    if self.hold_swap and old_right_selection_index ~= self.right_selection_index then
        local old_index = #self.selected_resource_packs - old_right_selection_index + 1
        local new_index = #self.selected_resource_packs - self.right_selection_index + 1
        local temp_value = config.resource_packs_applied[new_index]
        config.resource_packs_applied[new_index] = config.resource_packs_applied[old_index]
        config.resource_packs_applied[old_index] = temp_value
        self:refreshPackSelection()
    end
    if e.scancode == "tab" then
        self.selection_type = Mod1(self.selection_type + 1, 4)
    end
    if e.scancode == "escape" or e.input == "menu_back" or (self.selection_type == 4 and e.input == "menu_decide") then
        playSE("mode_decide")
        saveConfig()
        loadResourcePacks()
        scene = self.old_scene
    end
end

function ResourcePackScene:onInputRelease(e)
    if e.input == "hold" then
        self.hold_swap = false
    end
end

return ResourcePackScene