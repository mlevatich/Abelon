require 'src.Util'
require 'src.Constants'

require 'src.Sounds'

MenuItem = class('MenuItem')

CONFIRM_X = VIRTUAL_WIDTH / 2 - (CHAR_WIDTH * 3 + BOX_MARGIN * 2) / 2
function CONFIRM_Y(msg)
    return (VIRTUAL_HEIGHT + TEXT_MARGIN_Y) / 2
         + (#msg/2 - 1) * LINE_HEIGHT - HALF_MARGIN
end

function MenuItem:initialize(name, children, h_desc, h_box, action, conf, p, id)

    self.name = name
    self.children = children

    -- optional, may be nil
    self.hover_desc = h_desc
    self.hover_box = h_box
    self.action = action
    self.confirm_msg = conf
    if conf then
        local cm, _ = splitByCharLimit(conf, CBOX_CHARS_PER_LINE)
        self.confirm_msg = cm
    end
    self.setPen = ite(p, p, function(g) return WHITE end)
    self.id = id
end

Menu = class('Menu')

-- Initialize a new menu
function Menu:initialize(parent, menu_items, x, y, forced, conf, clr, max_override, mute)

    -- What is the parent menu of this menu (nil if a top-level menu)
    self.parent = parent

    -- What was the selection made at this menu?
    self.selected = nil

    -- Top left corner of this menu
    self.rel_x = x
    self.rel_y = y

    -- Store menu width/height/window so they aren't re-calculated at each render
    local longest_word = max(mapf(function(e) return #e.name end, menu_items))
    self.window = ite(max_override, max_override, MAX_MENU_ITEMS)
    self.width  = CHAR_WIDTH * longest_word + BOX_MARGIN*2
    self.height = LINE_HEIGHT
                * (math.min(#menu_items, self.window))
                + BOX_MARGIN - TEXT_MARGIN_Y

    -- Is this a confirmation prompt? If so, what is the message?
    -- (optional parameter)
    self.confirm_msg = conf
    self.confirm_clr = ite(clr, clr, WHITE)

    -- Is the menu forced to stay open until an option is selected
    self.forced = forced

    -- Do sound effects play in this menu
    self.mute = mute

    -- The different options on this menu
    self.hovering = 1
    self.base = 1
    self.menu_items = menu_items
    self:initSubmenus()
end

function LevelupMenu(sp, n)

    -- Increment function
    local incrAttr = function(i)
        return function(c)
            sp.attributes[i] = sp.attributes[i] + 1
            if i == 'endurance' then sp.health = sp.health + 2 end
            if i == 'focus'     then sp.ignea  = sp.ignea  + 1 end
            c.battle.stack[#c.battle.stack]['menu'] = nil
        end
    end

    -- Menu of attribute options
    local m_items = {}
    for i = 1, #ATTRIBUTE_DESC do
        table.insert(m_items, MenuItem:new("", {},
            ATTRIBUTE_DESC[i]['desc'], nil, incrAttr(ATTRIBUTE_DESC[i]['id'])
        ))
    end
    table.insert(m_items, MenuItem:new("", {},
        "Each level up grants a skill point. Skill points can be spent in the \z
         inventory after battle to learn new skills."
    ))
    local w = VIRTUAL_WIDTH - BOX_MARGIN * 2 - 220
    local h = VIRTUAL_HEIGHT - BOX_MARGIN * 2
    local m = Menu:new(nil, m_items, (VIRTUAL_WIDTH - w) / 2, BOX_MARGIN, true)

    -- Customize
    m.width   = w
    m.height  = h
    m.window  = 7
    m.custom  = 'lvlup'
    m.sp      = sp
    m.levels  = n
    m.spacing = LINE_HEIGHT * 3 - 3

    return m
end

function initSubmenu(cur, parent)
    if next(cur.children) ~= nil then

        -- Calculate base position
        local next_x = parent.rel_x + parent.width + BOX_MARGIN/4
        local next_y = parent.rel_y

        -- Init menu and open action
        local submenu = Menu:new(parent, cur.children, 
            next_x, next_y, false, nil, nil, SUB_MENU_ITEMS
        )
        local old_action = cur.action
        cur.action = function(c)
            parent.selected = submenu
            if old_action then old_action(c) end
        end

    elseif cur.confirm_msg and cur.action then

        -- Menu item's action is forwarded to 'Yes' on the confirm screen,
        -- which is another submenu
        local w = cur.confirm_msg
        local n = MenuItem:new('No', {})
        local y = MenuItem:new('Yes', {})
        local submenu = Menu:new(parent, {n, y}, CONFIRM_X, CONFIRM_Y(w), false, w)
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
        if action then
            if not self.mute then sfx['select']:play() end
            return action(c, self.parent)
        end
    end
end

function Menu:back()
    if self.selected then
        self.selected:back()
        return false
    elseif self.parent then
        self:reset()
        self.parent.selected = nil
        sfx['cancel']:play()
        return false
    end
    return not self.forced
end

-- Called when player presses up or down while in a menu to hover a selection
function Menu:hover(dir)
    if self.selected then
        self.selected:hover(dir)
    else
        local old_h = self.hovering
        local old_b = self.base

        -- self.hovering determines where the selection arrow is rendered
        local window_height = math.min(self.window, #self.menu_items)
        local base_max = #self.menu_items - window_height + 1
        if dir == UP then
            if self.hovering == 1 and self.base == 1 then
                self.hovering = window_height
                self.base = base_max
            else
                if self.hovering == 1 then
                    self.base = math.max(1, self.base - 1)
                end
                self.hovering = math.max(1, self.hovering - 1)
            end
        elseif dir == DOWN then
            if self.hovering == window_height and self.base == base_max then
                self.hovering = 1
                self.base = 1
            else
                if self.hovering == self.window then
                    self.base = math.min(base_max, self.base + 1)
                end
                self.hovering = math.min(window_height, self.hovering + 1)
            end
        end

        if self.hovering ~= old_h or self.base ~= old_b then
            sfx['hover']:play()
        end
    end
end

function Menu:renderConfirmMessage()
    local msg = self.confirm_msg
    local longest = max(mapf(function(m) return #m end, msg))
    local cbox_w = CHAR_WIDTH * longest + BOX_MARGIN*2
    local cbox_h = LINE_HEIGHT * (#msg + 2)
                 + BOX_MARGIN*2 - TEXT_MARGIN_Y
    if #self.menu_items == 1 then cbox_h = cbox_h - LINE_HEIGHT * 2 end
    local cbox_x = VIRTUAL_WIDTH/2 - cbox_w/2
    local cbox_y = VIRTUAL_HEIGHT/2 - cbox_h/2 - HALF_MARGIN
    drawBox(cbox_x, cbox_y, cbox_w, cbox_h, {0, 0, 0, RECT_ALPHA})
    for i=1, #msg do
        local base_x = VIRTUAL_WIDTH/2
                     - (#msg[i] * CHAR_WIDTH)/2
        local base_y = cbox_y + BOX_MARGIN
                     + LINE_HEIGHT * (i-1)
        renderString(msg[i], base_x, base_y, self.confirm_clr)
    end
end

function Menu:renderHoverDescription()
    local selection = self.menu_items[self.base + self.hovering - 1]
    if selection.hover_desc then
        local desc = selection.hover_desc

        if self.custom == 'lvlup' then
            local x = self.rel_x
            local y = self.rel_y
            local desc_x = x + BOX_MARGIN
            local desc_y = y + BOX_MARGIN + LINE_HEIGHT * 7 + PORTRAIT_SIZE
            local sdesc, _ = splitByCharLimit(desc, 32)
            for i = 1, #sdesc do
                renderString(sdesc[i],
                    desc_x, desc_y + LINE_HEIGHT * (i - 1), nil, true
                )
            end
        else
            local desc_x = VIRTUAL_WIDTH - BOX_MARGIN - #desc * CHAR_WIDTH
            local desc_y = VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
            renderString(desc, desc_x, desc_y)
        end
    end
end

function Menu:renderMenuItems(x, y, g)

    if self.custom == 'lvlup' then

        -- Render header
        local b = BOX_MARGIN
        love.graphics.setColor(unpack(WHITE))
        love.graphics.draw(self.sp:getPtexture(), self.sp:getPortrait(1),
            b + x, HALF_MARGIN + y, 0, 1, 1, 0, 0
        )
        local l = self.sp.level - self.levels
        local lstr = 'Level:  ' .. l .. '  >>  ' .. (l + 1)
        renderString(lstr, b + x, b + y + PORTRAIT_SIZE, HIGHLIGHT)
        renderString(self.sp.name .. ' grows stronger!',
            b + x, b + y + LINE_HEIGHT + PORTRAIT_SIZE
        )
        renderString('Select an attribute to improve.',
            b + x, b + y + LINE_HEIGHT * 2 + PORTRAIT_SIZE
        )

        -- Render attributes
        local dist = 250
        local x_base = x + VIRTUAL_WIDTH / 2 - 100
        local y_base = y + b
        for i = 1, #ATTRIBUTE_DESC do
            local a = ATTRIBUTE_DESC[i]
            local val = self.sp.attributes[a['id']] - self.levels
            local icon = icons[str_to_icon[a['id']]]
            local y_cur = y_base + self.spacing * (i - 1)
            local incr = 1
            local pen = nil
            love.graphics.setColor(unpack(WHITE))
            love.graphics.draw(icon_texture, icon, x_base, y_cur, 0, 1, 1, 0, 0)
            if self.hovering == i then
                love.graphics.draw(icon_texture, icon, b + x,
                    b + y + LINE_HEIGHT * 5 + PORTRAIT_SIZE, 0, 1, 1, 0, 0
                )
                renderString(a['name'], b + x + 27,
                    b + y + LINE_HEIGHT * 5 + PORTRAIT_SIZE, nil, true
                )
                incr = 2
                pen = HIGHLIGHT
            end
            renderString(tostring(val), x_base + 57, y_cur + LINE_HEIGHT, pen)
            renderString(a['name'], x_base + 27, y_cur, pen)
            renderString('+' .. incr .. '  >>  ',
                x_base + dist - 100,
                y_cur + LINE_HEIGHT, pen
            )
            renderString(tostring(val + incr),
                x_base + dist - 25,
                y_cur + LINE_HEIGHT, pen
            )
        end

        -- Render skill point increase
        local val = self.sp.skill_points - self.levels
        local y_cur = y_base + self.spacing * 6
        renderString('Skill pts', x_base + 27, y_cur)
        renderString(tostring(val), x_base + 57, y_cur + LINE_HEIGHT)
        renderString('+1  >>  ',
            x_base + dist - 100,
            y_cur + LINE_HEIGHT
        )
        renderString(tostring(val + 1),
            x_base + dist - 25,
            y_cur + LINE_HEIGHT
        )

    -- If this is a confirm message with one option, it is not rendered
    elseif not (self.confirm_msg and #self.menu_items == 1) then

        -- Render each menu item
        for i=1, math.min(#self.menu_items, self.window) do
            local base_x = 5 + x + BOX_MARGIN
            local base_y = y + HALF_MARGIN + (i - 1) * LINE_HEIGHT
            local item = self.menu_items[i + self.base - 1]
            renderString(item.name, base_x, base_y, item.setPen(g))
        end
    end

    -- Render indicator of more content
    love.graphics.setColor(unpack(WHITE))
    if self.base > 1 then
        printChar("^", x + self.width - 11, y + 6)
    end
    if self.base <= #self.menu_items - self.window then
        printChar("^", x + self.width - 5, y + self.height - 6, math.pi)
    end
end

function renderRangeDiagram(x, y, skill_data)

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

function renderHoverBox(h_box, x, y, h)

    local w = h_box['w']
    local light = h_box['light']
    h_box = h_box['elements']

    -- Draw hover box
    local alpha = ite(light, RECT_ALPHA / 2, RECT_ALPHA)
    drawBox(x, y, w, h, {0, 0, 0, alpha})
    
    -- Draw elements in box relative to top left
    for i = 1, #h_box do
        local e = h_box[i]
        if e['type'] == 'text' then
            local clr = ite(e['color'], e['color'], WHITE)
            love.graphics.setColor(unpack(clr))
            local msg = e['data']
            for j = 1, #msg do
                local cy = y + e['y'] + LINE_HEIGHT * (j - 1)
                renderString(msg[j], x + e['x'], cy, clr, e['auto_color'], j ~= 1)
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
            renderRangeDiagram(x + e['x'], y + e['y'], e['data'])
        end
    end
end

function Menu:renderSelectionArrow(x, y, g)
    local arrow_y = y + HALF_MARGIN + LINE_HEIGHT * (self.hovering - 1)
    local arrow_x = x + 11
    if not self.selected then
        arrow_x = arrow_x - (math.floor(g.global_timer) % 2) * 2
    end
    if self.custom == 'lvlup' then
        arrow_x = x + VIRTUAL_WIDTH / 2 - 100 - 15
        arrow_y = y + BOX_MARGIN + 3
                + (self.hovering - 1) * self.spacing
    end
    love.graphics.setColor(unpack(WHITE))
    printChar(">", arrow_x, arrow_y)
end

function Menu:render(g)

    -- Top left of menu box
    local x = self.rel_x
    local y = self.rel_y

    -- If this is a confirmation menu, render confirmation box,
    -- otherwise render normal menu box
    if self.confirm_msg then
        self:renderConfirmMessage()
    else
        drawBox(x, y, self.width, self.height, {0, 0, 0, RECT_ALPHA})
    end

    -- Render options
    self:renderMenuItems(x, y, g)

    -- Render arrow over item being hovered (if visible)
    if not (self.confirm_msg and #self.menu_items == 1) then
        self:renderSelectionArrow(x, y, g)
    end

    -- Render child menu if there is one or hover info if this is the leaf menu
    local hbox_rendered = false
    if self.selected then
        hbox_rendered = self.selected:render(g)
    else
        self:renderHoverDescription()
    end

    -- Only render deepest hover box
    local h_box = self.menu_items[self.hovering + self.base - 1].hover_box
    if h_box and not hbox_rendered then
        renderHoverBox(h_box,
            BOX_MARGIN, VIRTUAL_HEIGHT - BOX_MARGIN - HBOX_HEIGHT, HBOX_HEIGHT
        )
        return true
    end
    return hbox_rendered
end
