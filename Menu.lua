require 'Util'
require 'Constants'

require 'Scene'

Menu = Class{}

-- Initialize a new menu
function Menu:init(parent, children_data, x, y)

    -- What is the parent menu of this menu (nil if a top-level menu)
    self.parent = parent

    -- What was the selection made at this menu?
    self.child = nil

    -- Top left corner of this menu
    self.rel_x = x
    self.rel_y = y

    -- Store menu width and height so they aren't re-calculated at each render
    local longest_word = max(mapf(function(s) return #s end, mapf(function(e) return e['name'] end, children_data)))
    self.width = (FONT_SIZE + TEXT_MARGIN_X) * longest_word + BOX_MARGIN*2
    self.height = (FONT_SIZE + TEXT_MARGIN_Y) * (#children_data) + BOX_MARGIN - TEXT_MARGIN_Y

    -- The different options on this menu
    self.hovering = 1
    self.children = {}
    self:initChildren(children_data)
end

function Menu:initChildren(children_data)

    -- Initialize all sub-menus
    for i=1, #children_data do
        local cur = children_data[i]
        local child = { ['name'] = cur['name'], ['action'] = cur['action'] }
        if not cur['action'] then

            -- Calculate base position
            local child_x = self.rel_x + self.width + BOX_MARGIN/4
            local child_y = self.rel_y

            -- Init menu and open action
            child['menu'] = Menu(self, cur['children'], child_x, child_y)
            child['action'] = function()
                self.child = child['menu']
            end

        end
        self.children[#self.children+1] = child
    end
end

function Menu:reset()
    if self.child then
        self.child:reset()
    end
    self.child = nil
    self.hovering = 1
end

function Menu:forward()
    if self.child then
        self.child:forward()
    else
        self.children[self.hovering]['action']()
    end
end

function Menu:back()
    if self.child then
        self.child:back()
    elseif self.parent then
        self:reset()
        self.parent.child = nil
    end
end

-- Called when player presses up or down while in a menu to hover a selection
function Menu:hover(dir)
    if self.child then
        self.child:hover(dir)
    else
        -- self.hovering determines where the selection arrow is rendered
        if dir == UP then
            self.hovering = math.max(1, self.hovering - 1)
        elseif dir == DOWN then
            self.hovering = math.min(#self.children, self.hovering + 1)
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
    for i=1, #self.children do
        local cur_y = y + BOX_MARGIN/2 + (i-1) * (FONT_SIZE + TEXT_MARGIN_Y)
        local word = self.children[i]['name']
        for j=1, #word do
            local char = word:sub(j,j)
            local cur_x = 5 + x + BOX_MARGIN + (j-1) * (FONT_SIZE + TEXT_MARGIN_X)
            love.graphics.print(char, cur_x, cur_y)
        end
    end

    -- Render selection arrow over what is being hovered, if this is the leaf menus
    local arrow_y = y + BOX_MARGIN/2 + (FONT_SIZE + TEXT_MARGIN_Y) * (self.hovering - 1)
    love.graphics.print(">", x + 10, arrow_y)

    -- Render child menu if there is one
    if self.child then
        self.child:render(cam_x, cam_y)
    end
end
