require 'Util'
require 'Constants'

MenuItem = Class{}

function MenuItem:init(name, children, h_desc, h_box, action, confirm, p, id)

    self.name = name
    self.children = children

    -- optional, may be nil
    self.hover_desc = h_desc
    self.hover_box = h_box
    self.action = action
    self.confirm_msg = confirm
    if confirm then
        local cm, _ = splitByCharLimit(confirm, CBOX_CHARS_PER_LINE)
        self.confirm_msg = cm
    end
    self.setPen = ite(p, p, function(c) love.graphics.setColor(unpack(WHITE)) end)
    self.id = id
end

Menu = Class{}

-- Initialize a new menu
function Menu:init(parent, menu_items, x, y, confirm_msg)

    -- What is the parent menu of this menu (nil if a top-level menu)
    self.parent = parent

    -- What was the selection made at this menu?
    self.selected = nil

    -- Top left corner of this menu
    self.rel_x = x
    self.rel_y = y

    -- Store menu width and height so they aren't re-calculated at each render
    local longest_word = max(mapf(function(e) return #e.name end, menu_items))
    self.width  = CHAR_WIDTH * longest_word + BOX_MARGIN*2
    self.height = LINE_HEIGHT
                * (math.min(#menu_items, MAX_MENU_ITEMS))
                + BOX_MARGIN - TEXT_MARGIN_Y

    -- Is this a confirmation prompt? If so, what is the message?
    -- (optional parameter)
    self.confirm_msg = confirm_msg


    -- The different options on this menu
    self.hovering = 1
    self.base = 1
    self.menu_items = menu_items
    self:initSubmenus()
end

function initSubmenu(cur, parent)
    if next(cur.children) ~= nil then

        -- Calculate base position
        local next_x = parent.rel_x + parent.width + BOX_MARGIN/4
        local next_y = parent.rel_y

        -- Init menu and open action
        local submenu = Menu(parent, cur.children, next_x, next_y)
        local old_action = cur.action
        cur.action = function(c)
            parent.selected = submenu
            if old_action then old_action(c) end
        end

    elseif cur.confirm_msg and cur.action then

        -- Base position of confirm message
        local msg = cur.confirm_msg
        local next_x = VIRTUAL_WIDTH/2
                     - (CHAR_WIDTH * 3 + BOX_MARGIN*2)/2

        -- Witchcraft
        local next_y = (VIRTUAL_HEIGHT + TEXT_MARGIN_Y) / 2
                     + (#msg/2 - 1) * LINE_HEIGHT
                     - HALF_MARGIN

        -- Menu item's action is forwarded to 'Yes' on the confirm screen,
        -- which is another submenu
        local n = MenuItem('No', {})
        local y = MenuItem('Yes', {})
        local submenu = Menu(parent, {n, y}, next_x, next_y, msg)
        local inherited_action = cur.action
        n.action = function(c) submenu:back() end
        y.action = function(c, m)
            submenu:back()
            inherited_action(c, m)
        end
        cur.action = function(c)
            parent.selected = submenu
        end
    end
end

function Menu:initSubmenus()

    -- Initialize all sub-menus
    for i=1, #self.menu_items do
        initSubmenu(self.menu_items[i], self)
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
        if action then action(c, self.parent) end
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

function Menu:renderConfirmMessage(cam_x, cam_y)
    local msg = self.confirm_msg
    local longest = max(mapf(function(m) return #m end, msg))
    local cbox_w = CHAR_WIDTH * longest + BOX_MARGIN*2
    local cbox_h = LINE_HEIGHT * (#msg + 2)
                 + BOX_MARGIN*2 - TEXT_MARGIN_Y
    local cbox_x = cam_x + VIRTUAL_WIDTH/2 - cbox_w/2
    local cbox_y = cam_y + VIRTUAL_HEIGHT/2 - cbox_h/2 - HALF_MARGIN
    love.graphics.setColor(0, 0, 0, RECT_ALPHA)
    love.graphics.rectangle('fill', cbox_x, cbox_y, cbox_w, cbox_h)
    for i=1, #msg do
        local base_x = cam_x + VIRTUAL_WIDTH/2
                     - (#msg[i] * CHAR_WIDTH)/2
        local base_y = cbox_y + BOX_MARGIN
                     + LINE_HEIGHT * (i-1)
        renderString(msg[i], base_x, base_y)
    end
end

function Menu:renderHoverDescription(cam_x, cam_y)

    love.graphics.setColor(unpack(WHITE))
    local selection = self.menu_items[self.base + self.hovering - 1]
    if selection.hover_desc then
        local desc = selection.hover_desc

        local desc_x_base = cam_x + VIRTUAL_WIDTH - BOX_MARGIN
                          - #desc * CHAR_WIDTH
        local desc_y_base = cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
        renderString(desc, desc_x_base, desc_y_base)
    end
end

function Menu:renderMenuItems(x, y, c)


    for i=1, math.min(#self.menu_items, MAX_MENU_ITEMS) do
        local base_x = 5 + x + BOX_MARGIN
        local base_y = y + HALF_MARGIN + (i - 1) * LINE_HEIGHT
        local item = self.menu_items[i + self.base - 1]
        item.setPen(c)
        renderString(item.name, base_x, base_y, true)
    end

    -- Render indicator of more content
    love.graphics.setColor(unpack(WHITE))
    if self.base > 1 then
        love.graphics.print("^", x + self.width - 11, y + 6)
    end
    if self.base <= #self.menu_items - MAX_MENU_ITEMS then
        love.graphics.print("^", x + self.width - 5, y + self.height - 6, math.pi)
    end
end

function Menu:renderRangeDiagram(x, y, skill_data)

    -- Data
    local shape = skill_data[1]
    local aim = skill_data[2]
    local type = skill_data[3]
    local DIAGRAM_DIM = 105
    local GRID_DIM = 7
    local rect_dim = (DIAGRAM_DIM / GRID_DIM)

    -- Render grid
    for i = 0, GRID_DIM do
        local factor = i * rect_dim
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.line(x + factor, y, x + factor, y + DIAGRAM_DIM)
        love.graphics.line(x, y + factor, x + DIAGRAM_DIM, y + factor)
    end

    -- Render skill
    local size = #shape
    local shape_base = (size - GRID_DIM) / 2
    for i = 1, GRID_DIM do
        for j = 1, GRID_DIM do
            local si = i + shape_base
            local sj = j + shape_base
            if si > 0 and si <= size and sj > 0 and sj <= size then

                -- Render a square in the aoe zone
                local x_tile = j - 1
                local y_tile = i - 1
                local x_offset = x_tile * rect_dim
                local y_offset = y_tile * rect_dim
                if shape[si][sj] then
                    local clr = ite(type == ASSIST,
                        {0, 0.6, 0, 0.5},
                        {0.6, 0, 0, 0.5}
                    )
                    love.graphics.setColor(unpack(clr))
                    love.graphics.rectangle('fill',
                        x + x_offset + 1,
                        y + y_offset + 1,
                        rect_dim - 2,
                        rect_dim - 2
                    )
                end

                -- Render cursor on the center of the aoe
                if i == (GRID_DIM + 1)/2 and j == (GRID_DIM + 1)/2 then

                    -- If FREE and aim target = enemy, add enemy circle
                    -- If FREE And aim target = ally, add ally circle

                    local clr = ite(type == ASSIST, {0, 1, 0, 1}, {1, 0, 0, 1})
                    love.graphics.setColor(unpack(clr))
                    love.graphics.rectangle('line',
                        x + x_offset + 1,
                        y + y_offset + 1,
                        rect_dim - 2,
                        rect_dim - 2
                    )
                end
            end
        end
    end

    -- Render caster
    local c_x_tile = (GRID_DIM - 1) / 2
    local c_y_tile = (GRID_DIM - 1) / 2
    if aim['type'] == DIRECTIONAL then
        c_y_tile = c_y_tile + 1
    elseif aim['type'] == FREE then
        c_y_tile = c_y_tile + 2
    end
    local c_x = c_x_tile * rect_dim
    local c_y = c_y_tile * rect_dim
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.ellipse('fill',
        x + c_x + rect_dim/2,
        y + c_y + rect_dim/2,
        rect_dim/2 - 2,
        rect_dim/2 - 2
    )
end

function Menu:renderHoverBox(cam_x, cam_y, h_box)

    local w = h_box['w']
    h_box = h_box['elements']

    -- Hover box top left
    local x = cam_x + BOX_MARGIN
    local y = cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - HBOX_HEIGHT

    -- Draw hover box
    love.graphics.setColor(0, 0, 0, RECT_ALPHA)
    love.graphics.rectangle('fill', x, y, w, HBOX_HEIGHT)

    -- Draw elements in box relative to top left
    for i = 1, #h_box do
        local e = h_box[i]
        if e['type'] == 'text' then
            local clr = ite(e['color'], e['color'], WHITE)
            love.graphics.setColor(unpack(clr))
            local msg = e['data']
            for j = 1, #msg do
                local cy = y + e['y'] + LINE_HEIGHT * (j-1)
                renderString(msg[j], x + e['x'], cy, true)
            end
        elseif e['type'] == 'image' then
            love.graphics.setColor(unpack(WHITE))
            love.graphics.draw(
                e['texture'],
                e['data'],
                x + e['x'],
                y + e['y'],
                0, 1, 1, 0, 0
            )
        elseif e['type'] == 'range' then
            self:renderRangeDiagram(x + e['x'], y + e['y'], e['data'])
        end
    end
end

function Menu:renderSelectionArrow(x, y)
    local arrow_y = y + HALF_MARGIN + LINE_HEIGHT * (self.hovering - 1)
    love.graphics.setColor(unpack(WHITE))
    love.graphics.print(">", x + 10, arrow_y)
end

function Menu:render(cam_x, cam_y, c)

    -- Top left of menu box
    local x = cam_x + self.rel_x
    local y = cam_y + self.rel_y

    -- If this is a confirmation menu, render confirmation box,
    -- otherwise render normal menu box
    if self.confirm_msg then
        self:renderConfirmMessage(cam_x, cam_y)
    else
        love.graphics.setColor(0, 0, 0, RECT_ALPHA)
        love.graphics.rectangle('fill', x, y, self.width, self.height)
    end

    -- Render options
    self:renderMenuItems(x, y, c)

    -- Render arrow over item being hovered
    self:renderSelectionArrow(x, y)

    -- Render child menu if there is one or hover info if this is the leaf menu
    local hbox_rendered = false
    if self.selected then
        hbox_rendered = self.selected:render(cam_x, cam_y, c)
    else
        self:renderHoverDescription(cam_x, cam_y)
    end

    -- Only render deepest hover box
    local h_box = self.menu_items[self.hovering + self.base - 1].hover_box
    if h_box and not hbox_rendered then
        self:renderHoverBox(cam_x, cam_y, h_box)
        return true
    end
    return hbox_rendered
end
