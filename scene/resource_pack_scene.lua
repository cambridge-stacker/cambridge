local ResourcePackScene = Scene:extend()

ResourcePackScene.title = "Resource Packs"

function ResourcePackScene:new()
    config.resource_packs_applied = config.resource_packs_applied or {}
    self.valid_resource_packs = {}
    self.resource_pack_index = {}
    ---@type {[...]:string}
    local resource_packs = love.filesystem.getDirectoryItems("resourcepacks")
    for key, value in pairs(resource_packs) do
        print(value, value:sub(-4), value:sub(-4) == ".zip")
        if value:sub(-4) == ".zip" and love.filesystem.getInfo("resourcepacks/"..value, "file") then
            self.valid_resource_packs[#self.valid_resource_packs+1] = value
            self.resource_pack_index[value] = #self.valid_resource_packs
        end
    end
    self.left_menu_height = 0
    self.right_menu_height = 0
    self.selection_index = 1
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
    local indexes = table.keys(config.resource_packs_applied)

end

function ResourcePackScene:update()
    
end

function ResourcePackScene:render()
    drawSizeIndependentImage(backgrounds["input_config"], 0, 0, 0, 640, 480)
    love.graphics.print("WIP THIS IS NOT DONE.\nInput schema: Shift-Up/Down to move selected active resource pack up or down.\nTab to swap selection.\nMenu Decision - Activate or deactivate a resource pack.")
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.rectangle("fill", self.selection_type == 0 and 55 or 355, 155 - (self.selection_type == 0 and self.left_menu_height or self.right_menu_height) + 40 * self.selection_index, 250, 40)
    love.graphics.setColor(1,1,1,1)
    for key, value in pairs(self.selected_resource_packs) do
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(value, 60, 160 - self.left_menu_height + 40 * key, 240, "left")
    end
    for key, value in pairs(self.unselected_resource_packs) do
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(value, 360, 160 - self.right_menu_height + 40 * key, 240, "left")
    end
end

function ResourcePackScene:onInputPress(e)
    if e.input == "menu_decide" then
        if self.selection_type == 0 then
            table.remove(config.resource_packs_applied, #self.selected_resource_packs - self.selection_index + 1)
            self:refreshPackSelection()
        else
            table.insert(config.resource_packs_applied, self.unselected_resource_packs[self.selection_index])
            self:refreshPackSelection()
        end
    end
    local dividend = (self.selection_type == 0 and #self.selected_resource_packs or #self.unselected_resource_packs)
    if dividend < 1 then
        dividend = 1
    end
    if e.input == "up" then
        self.selection_index = Mod1(self.selection_index - 1, dividend)
    end
    if e.input == "down" then
        self.selection_index = Mod1(self.selection_index + 1, dividend)
        
    end
    if e.scancode == "tab" then
        self.selection_type = 1 - self.selection_type
        self.selection_index = 1
    end
    if e.scancode == "escape" or e.input == "menu_back" then
        playSE("mode_decide")
        saveConfig()
        loadResourcePacks()
        scene = SettingsScene()
    end
end

function ResourcePackScene:onInputRelease(e)
    
end

return ResourcePackScene