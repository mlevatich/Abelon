require 'Util'
require 'Constants'

MenuItem = Class{}

function MenuItem:init(name, children, h_desc, h_render, action, confirm)

    self.name = name
    self.children = children

    -- optional, may be nil
    self.hover_desc = h_desc
    self.hover_render = h_render
    self.action = action
    self.confirm_msg = confirm

end

Menu = Class{}

-- Initialize a new menu
function Menu:init(parent, menu_items, x, y)

    -- What is the parent menu of this menu (nil if a top-level menu)
    self.parent = parent

    -- What was the selection made at this menu?
    self.selected = nil

    -- Top left corner of this menu
    self.rel_x = x
    self.rel_y = y

    -- Store menu width and height so they aren't re-calculated at each render
    local longest_word = max(mapf(function(e) return #e.name end, menu_items))
    self.width  = (FONT_SIZE + TEXT_MARGIN_X) * longest_word + BOX_MARGIN*2
    self.height = (FONT_SIZE + TEXT_MARGIN_Y)
                * (math.min(#menu_items, MAX_MENU_ITEMS))
                + BOX_MARGIN - TEXT_MARGIN_Y

    -- The different options on this menu
    self.hovering = 1
    self.base = 1
    self.menu_items = menu_items
    self:initSubmenus()
end

function Menu:initSubmenus()

    -- Initialize all sub-menus
    for i=1, #self.menu_items do
        local cur = self.menu_items[i]
        if next(cur.children) ~= nil then

            -- Calculate base position
            local next_x = self.rel_x + self.width + BOX_MARGIN/4
            local next_y = self.rel_y

            -- Init menu and open action
            local submenu = Menu(self, cur.children, next_x, next_y)
            local old_action = cur.action
            cur.action = function(c)
                self.selected = submenu
                if old_action then
                    old_action(c)
                end
            end

        end
    end
end

function Menu:reset()
    if self.selected then
        self.selected:reset()
    end
    self.selected = nil
    self.hovering = 1
    self.base = 1
end

function Menu:forward(c)
    if self.selected then
        self.selected:forward(c)
    else
        local action = self.menu_items[self.hovering + self.base - 1].action
        if action then action(c) end
    end
end

function Menu:back()
    if self.selected then
        self.selected:back()
        return false
    elseif self.parent then
        self:reset()
        self.parent.selected = nil
        return false
    end
    return true
end

-- Called when player presses up or down while in a menu to hover a selection
function Menu:hover(dir)
    if self.selected then
        self.selected:hover(dir)
    else
        -- self.hovering determines where the selection arrow is rendered
        if dir == UP then
            if self.hovering == 1 then
                self.base = math.max(1, self.base - 1)
            end
            self.hovering = math.max(1, self.hovering - 1)
        elseif dir == DOWN then
            if self.hovering == MAX_MENU_ITEMS then
                self.base = math.min(
                    #self.menu_items - MAX_MENU_ITEMS + 1,
                    self.base + 1
                )
            end
            self.hovering = math.min(
                math.min(MAX_MENU_ITEMS, #self.menu_items),
                self.hovering + 1
            )
        end
    end
end

function Menu:render(cam_x, cam_y)

    -- Top left of box
    local x = cam_x + self.rel_x
    local y = cam_y + self.rel_y

    -- Render black menu box
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x, y, self.width, self.height)

    -- Render options
    love.graphics.setColor(1, 1, 1, 1)
    for i=1, math.min(#self.menu_items, MAX_MENU_ITEMS) do
        local cur_y = y + BOX_MARGIN/2 + (i-1) * (FONT_SIZE + TEXT_MARGIN_Y)
        local word = self.menu_items[i + self.base - 1].name
        for j=1, #word do
            local char = word:sub(j,j)
            local cur_x = 5 + x + BOX_MARGIN + (j-1) * (FONT_SIZE + TEXT_MARGIN_X)
            love.graphics.print(char, cur_x, cur_y)
        end
    end

    -- Render indicator of more content
    if self.base > 1 then
        love.graphics.print("^", x + self.width - 11, y + 6)
    end
    if self.base <= #self.menu_items - MAX_MENU_ITEMS then
        love.graphics.print("^", x + self.width - 5, y + self.height - 6, math.pi)
    end

    -- Render selection arrow over what is being hovered, if this is the leaf menus
    local arrow_y = y + BOX_MARGIN/2
                  + (FONT_SIZE + TEXT_MARGIN_Y)
                  * (self.hovering - 1)
    love.graphics.print(">", x + 10, arrow_y)

    -- Render child menu if there is one
    if self.selected then
        self.selected:render(cam_x, cam_y)
    end
end
