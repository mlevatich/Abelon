require 'Util'
require 'Constants'

require 'Menu'
require 'Music'
require 'Skill'

Battle = Class{}

GridSpace = Class{}

local PULSE = 0.4

function GridSpace:init(sp)
    self.occupied = nil
    if sp then
        self.occupied = sp
    end
end

function Battle:init(battle_id, player, chapter)

    self.id = battle_id
    self.chapter = chapter

    -- Tracking battle and chapter state
    self.turn = 1
    self.state = {}

    -- Data file
    local data_file = 'Abelon/data/battles/' .. self.id .. '.txt'
    local data = readLines(data_file)

    -- Get base tile of the top left of the grid
    local tile_origin = readArray(data[3], tonumber)
    self.origin_x = tile_origin[1]
    self.origin_y = tile_origin[2]

    -- Battle grid
    local grid_index = 12
    local grid_dim = readArray(data[grid_index], tonumber)
    self.grid_w = grid_dim[1]
    self.grid_h = grid_dim[2]
    self.grid = {}
    for i = 1, self.grid_h do
        local row_str = data[grid_index + i]
        self.grid[i] = {}
        for j = 1, self.grid_w do
            self.grid[i][j] = ite(row_str:sub(j, j) == 'T', GridSpace(), F)
        end
    end

    -- Battle participants
    local readEntities = function(idx)
        local t = {}
        for k,v in pairs(readDict(data[idx], ARR, nil, tonumber)) do
            local sp = self.chapter:getSprite(k)
            table.insert(t, sp)
            self.grid[v[2]][v[1]] = GridSpace(sp)
            local x_tile = self.origin_x + v[1]
            local y_tile = self.origin_y + v[2]
            local x, y = self.chapter:getMap():tileToPixels(x_tile, y_tile)
            sp:resetPosition(x, y)
        end
        return t
    end
    self.player = player
    self.allies = readEntities(4)
    self.enemies = readEntities(5)

    -- Win conditions and loss conditions
    self.wincon = function(b) return true end
    self.losscon = function(b) return false end

    -- Battle cam starting location
    self.battle_cam_x = (self.origin_x) * TILE_WIDTH
                      + (self.grid_w * TILE_WIDTH - VIRTUAL_WIDTH) / 2
    self.battle_cam_y = (self.origin_y) * TILE_HEIGHT
                      + (self.grid_h * TILE_HEIGHT - VIRTUAL_HEIGHT) / 2
    self.battle_cam_speed = 170

    -- Render timers
    self.pulse_timer = 0
    self.shading = 0.2
    self.shade_dir = 1

    -- Music
    self.prev_music = self.chapter.current_music
    if self.prev_music then
        self.prev_music:stop()
    end
    self.chapter.current_music = Music(readField(data[8]))

    -- Start the battle!
    self.stack = {{
        ['stage'] = STAGE_FREE,
        ['cursor'] = { 1, 1, false, { HIGHLIGHT } },
        ['views'] = {
            { BEFORE, TEMP, function() self:renderMovementHover() end }
        }
    }}
    self:begin()
end

function Battle:getId()
    return self.id
end

function Battle:getCamera()
    return self.battle_cam_x, self.battle_cam_y, self.battle_cam_speed
end

function Battle:push(e)
    for i = 1, #self.stack do
        if self.stack[i]['cursor'] then
            self.stack[i]['cursor'][3] = false
        end
    end
    self.stack[#self.stack + 1] = e
end

function Battle:pop()
    table.remove(self.stack, #self.stack)
end

function Battle:getCursor()
    top = nil
    for i = 1, #self.stack do
        if self.stack[i]['cursor'] then
            top = self.stack[i]['cursor']
        end
    end
    return top
end

function Battle:getPrevCursor()
    prev = nil
    found = 0
    for i = 1, #self.stack do
        if self.stack[#self.stack - i + 1]['cursor'] then
            prev = self.stack[#self.stack - i + 1]['cursor']
            found = found + 1
            if found == 2 then
                return prev
            end
        end
    end
end

function Battle:getMenu()
    return self.stack[#self.stack]['menu']
end

function Battle:getSprite()
    top = nil
    for i = 1, #self.stack do
        if self.stack[i]['sp'] then
            top = self.stack[i]['sp']
        end
    end
    return top
end

function Battle:getSkill()
    return self.stack[#self.stack]['sk']
end

function Battle:moveCursor(x, y)
    local c = self:getCursor()
    c[1] = x
    c[2] = y
end

function Battle:openMenu(m, views)
    self:push({
        ['stage'] = STAGE_MENU,
        ['menu'] = m,
        ['views'] = views
    })
end

function Battle:closeMenu()
    if self.stack[#self.stack]['stage'] == STAGE_MENU then
        self:pop()
    end
end

function Battle:getStage()
    return self.stack[#self.stack]['stage']
end

function Battle:setStage(s)
    self.stack[#self.stack]['stage'] = s
end

function Battle:begin()

    -- Participants to battle behavior
    for i = 1, #self.allies  do  self.allies[i]:changeBehavior('battle') end
    for i = 1, #self.enemies do self.enemies[i]:changeBehavior('battle') end
    self.player:changeMode('battle')

    -- Cursor to Abelon
    local y, x = self:findSprite(self.player:getId())
    self:moveCursor(x, y)

    -- Start menu open
    self:openStartMenu()
end

function Battle:openStartMenu()
    local die = function(c) love.event.quit(0) end
    local next = function(c) self:closeMenu() end
    local begin = MenuItem('Begin turn', {}, "Begin your turn", nil, next)
    local wincon = MenuItem('Objectives', {},
        'View victory and defeat conditions'
    )
    local restart1 = MenuItem('Restart battle', {}, 'Start the battle over',
        nil, pass,
        "Start the battle over from the beginning?"
    )
    local restart2 = MenuItem('Restart chapter', {}, 'Start the chapter over',
        nil, pass,
        "Are you SURE you want to restart the chapter? You will lose ALL \z
         progress made during the chapter."
    )
    local quit = MenuItem('Save and quit', {}, 'Quit the game', nil, die,
        "Save current progress and close the game?"
    )
    local m = { begin, wincon, restart1, restart2, quit }
    self:openMenu(Menu(nil, m, BOX_MARGIN, BOX_MARGIN), {{}})
end

function Battle:mkUsable(sp, sk_menu)
    local sk = skills[sk_menu.id]
    sk_menu.hover_desc = 'Use ' .. sk_menu.name
    if sp.ignea >= sk.cost then
        sk_menu.setPen = function(c) love.graphics.setColor(1, 1, 1, 1) end
        sk_menu.action = function(c)
            local c = self:getCursor()
            local cx = c[1]
            local cy = c[2]
            if sk.aim['type'] ~= SELF_CAST then
                if self.grid[cy][cx + 1] then
                    cx = cx + 1
                elseif self.grid[cy][cx - 1] then
                    cx = cx - 1
                elseif self.grid[cy + 1][cx] then
                    cy = cy + 1
                else
                    cy = cy - 1
                end
            end
            local new_c = { cx, cy, c[3], {1, 0.4, 0.4, 1} }
            self:push({
                ['stage'] = STAGE_TARGET,
                ['cursor'] =  new_c,
                ['sp'] = sp,
                ['sk'] = sk,
                ['views'] = {
                    { BEFORE, TEMP, function()
                        self:renderAttackRange()
                    end }
                }
            })
        end
    else
        sk_menu.setPen = function(c) love.graphics.setColor(unpack(DISABLE)) end
    end
end

function Battle:openAttackMenu(sp)
    local attributes = MenuItem('Attributes', {}, nil, {
        ['elements'] = sp:buildAttributeBox(),
        ['w'] = HBOX_WIDTH
    })
    local wait = MenuItem('Skip', {},
        'Skip ' .. sp.name .. "'s attack", nil, pass
    )
    local skills_menu = sp:mkSkillsMenu()
    local weapon = skills_menu.children[1]
    local spell = skills_menu.children[2]
    for i = 1, #weapon.children do self:mkUsable(sp, weapon.children[i]) end
    for i = 1, #spell.children do self:mkUsable(sp, spell.children[i]) end
    local opts = { attributes, weapon, spell, wait }
    self:openMenu(Menu(nil, opts, BOX_MARGIN, BOX_MARGIN), {
        { BEFORE, TEMP, function() self:renderMovementActive() end }
    })
end

function Battle:openEnemyMenu(sp)
    local attributes = MenuItem('Attributes', {}, nil, {
        ['elements'] = sp:buildAttributeBox(),
        ['w'] = 380
    })
    local readying = MenuItem('Next Attack', {}, nil, {
        ['elements'] = self:buildReadyingBox(sp),
        ['w'] = HBOX_WIDTH
    })
    -- TODO: For each skill, add targeting info
    local skills = sp:mkSkillsMenu(false)
    local opts = { attributes, readying, skills }
    self:openMenu(Menu(nil, opts, BOX_MARGIN, BOX_MARGIN), {
        { BEFORE, TEMP, function() self:renderMovementHover() end }
    })
end

function Battle:buildReadyingBox(sp)
    -- TODO index on readying skill (not 1), and add targeting info
    return sp.skills[1]:mkSkillBox(sp.itex, sp.icons, false)
end

function Battle:openOptionsMenu()
    local die = function(c) love.event.quit(0) end
    local wincon = MenuItem('Objectives', {},
        'View victory and defeat conditions'
    )
    local end_turn = MenuItem('End turn', {},
        'End your turn', nil, pass,
        "End your turn early? Some of your allies can still act."
    )
    local settings = self.player:mkSettingsMenu()
    local restart = MenuItem('Restart battle', {},
        'Start the battle over', nil, pass,
        "Start the battle over from the beginning?"
    )
    local quit = MenuItem('Save and quit', {}, 'Quit the game', nil, die,
        "Save battle state and close the game?"
    )
    local m = { wincon, end_turn, settings, restart, quit }
    self:openMenu(Menu(nil, m, BOX_MARGIN, BOX_MARGIN), {{}})
end

function Battle:findSprite(sp_id)
    for i = 1, self.grid_h do
        for j = 1, self.grid_w do
            if self.grid[i][j] and
               self.grid[i][j].occupied and
               self.grid[i][j].occupied:getId() == sp_id then
                return i, j
            end
        end
    end
end

function Battle:isAlly(sp)
    return find(self.allies, sp)
end

function Battle:selectAlly(sp)
    local c = self:getCursor()
    local new_c = { c[1], c[2], c[3], {0.4, 0.4, 1, 1} }
    self:push({
        ['stage'] = STAGE_MOVE,
        ['sp'] = sp,
        ['cursor'] = new_c,
        ['views'] = {
            { BEFORE, TEMP, function() self:renderMovementActive() end },
            { AFTER, PERSIST, function()
                self:findSprite(sp:getId())
                local y, x = self:findSprite(sp:getId())
                self:renderSpriteImage(new_c[1], new_c[2], x, y, sp)
            end }
        }
    })
end

function Battle:newCursorMove(up, down, left, right)
    local c = self:getCursor()
    local i = c[2]
    local j = c[1]
    local x_move = 0
    local y_move = 0
    if left and not right and j - 1 >= 1 and self.grid[i][j - 1] then
        x_move = -1
    end
    if right and not left and j + 1 <= self.grid_w and self.grid[i][j + 1] then
        x_move = 1
    end
    if up and not down and i - 1 >= 1 and self.grid[i - 1][j] then
        y_move = -1
    end
    if down and not up and i + 1 <= self.grid_h and self.grid[i + 1][j] then
        y_move = 1
    end
    return x_move, y_move
end

function Battle:newCursorPosition(up, down, left, right)
    local x_move, y_move = self:newCursorMove(up, down, left, right)
    local c = self:getCursor()
    local i = c[2]
    local j = c[1]
    return j + x_move, i + y_move
end

function Battle:update(keys, dt)

    -- Control determined by stage
    local s     = self:getStage()
    local d     = keys['d']
    local f     = keys['f']
    local up    = keys['up']
    local down  = keys['down']
    local left  = keys['left']
    local right = keys['right']

    if s == STAGE_MENU then

        -- Menu navigation
        local m = self:getMenu()
        local done = false
        if d then
            done = m:back()
        elseif f then
            m:forward(self.chapter)
        elseif up ~= down then
            m:hover(ite(up, UP, DOWN))
        end

        if done then self:closeMenu() end

    elseif s == STAGE_FREE then

        -- Free map navagation
        local x, y = self:newCursorPosition(up, down, left, right)
        self:moveCursor(x, y)

        if f then
            local space = self.grid[y][x]
            if not space.occupied then
                self:openOptionsMenu()
            elseif self:isAlly(space.occupied) then
                self:selectAlly(space.occupied)
            else
                self:openEnemyMenu(space.occupied)
            end
        end

    elseif s == STAGE_MOVE then

        local sp = self:getSprite()
        if d then
            self:pop()
        else
            -- Move a sprite to a new location
            local y1, x1 = self:findSprite(sp:getId())
            local x2, y2 = self:newCursorPosition(up, down, left, right)
            if abs(x2 - x1) + abs(y2 - y1) <= sp:getMovement() then
                self:moveCursor(x2, y2)
            end
        end

        if f then
            self:openAttackMenu(sp)
        end

    elseif s == STAGE_TARGET then
        local sp = self:getSprite()
        local sk = self:getSkill()
        if d then
            self:pop()
        else
            local c = self:getPrevCursor()
            local x_move, y_move = self:newCursorMove(up, down, left, right)
            if sk.aim['type'] == DIRECTIONAL then
                if x_move == 1 then
                    self:moveCursor(c[1] + 1, c[2])
                elseif x_move == -1 then
                    self:moveCursor(c[1] - 1, c[2])
                elseif y_move == 1 then
                    self:moveCursor(c[1], c[2] + 1)
                elseif y_move == -1 then
                    self:moveCursor(c[1], c[2] - 1)
                end
            elseif sk.aim['type'] == FREE then
                local scale = sk.aim['scale']
                local c_cur = self:getCursor()
                if abs(c_cur[1] + x_move - c[1]) +
                   abs(c_cur[2] + y_move - c[2]) <= scale then
                    self:moveCursor(c_cur[1] + x_move, c_cur[2] + y_move)
                end
            end
        end

        if f then
            -- TODO: move2
        end
    end

    -- Update battle camera position
    local c = self:getCursor()
    self.battle_cam_x = (c[1] + self.origin_x)
                      * TILE_WIDTH - VIRTUAL_WIDTH / 2
    self.battle_cam_y = (c[2] + self.origin_y)
                      * TILE_WIDTH - VIRTUAL_HEIGHT / 2

    -- Advance render timers
    self.pulse_timer = self.pulse_timer + dt
    while self.pulse_timer > PULSE do
        self.pulse_timer = self.pulse_timer - PULSE
        c[3] = not c[3]
    end
    self.shading = self.shading + self.shade_dir * dt / 3
    if self.shading > 0.4 then
        self.shading = 0.4
        self.shade_dir = -1
    elseif self.shading < 0.2 then
        self.shading = 0.2
        self.shade_dir = 1
    end
end

function Battle:renderCursors()
    for i = 1, #self.stack do
        local c = self.stack[i]['cursor']
        if c then
            local x_tile = self.origin_x + c[1]
            local y_tile = self.origin_y + c[2]
            local x, y = self.chapter:getMap():tileToPixels(x_tile, y_tile)
            local shift = ite(c[3], 2, 3)
            local fx = x + TILE_WIDTH - shift
            local fy = y + TILE_HEIGHT - shift
            x = x + shift
            y = y + shift
            local len = 10 - shift
            love.graphics.setColor(unpack(c[4]))
            love.graphics.line(x, y, x + len, y)
            love.graphics.line(x, y, x, y + len)
            love.graphics.line(fx, y, fx - len, y)
            love.graphics.line(fx, y, fx, y + len)
            love.graphics.line(x, fy, x, fy - len)
            love.graphics.line(x, fy, x + len, fy)
            love.graphics.line(fx, fy, fx - len, fy)
            love.graphics.line(fx, fy, fx, fy - len)
        end
    end
end

function Battle:shadeSquare(i, j, clr, full)
    if self.grid[i] and self.grid[i][j] then
        local x = (self.origin_x + j - 1) * TILE_WIDTH
        local y = (self.origin_y + i - 1) * TILE_HEIGHT
        local shade = ite(full, self.shading, self.shading / 3)
        love.graphics.setColor(clr[1], clr[2], clr[3], shade)
        love.graphics.rectangle('fill',
            x + 2, y + 2,
            TILE_WIDTH - 4, TILE_HEIGHT - 4
        )
    end
end

function Battle:renderAttackRange()

    -- Get skill and cursor info
    local c = self:getCursor()
    local sk = self:getSkill()
    local scale = #sk.range
    local clr = { 1, 0, 0 }
    local dir = UP

    -- Get direction to point the skill
    if sk.aim == DIRECTIONAL_AIM then
        local o = self:getPrevCursor()
        dir = ite(c[1] > o[1], RIGHT,
                  ite(c[1] < o[1], LEFT,
                      ite(c[2] > o[2], DOWN, UP)))
    end

    -- Render red squares based on direction
    for i = 1, scale do
        for j = 1, scale do
            local toGrid = function(x, k, flip)
                local g = c[k] - (scale + 1) / 2 + x
                if flip then
                    g = c[k] + (scale + 1) / 2 - x
                end
                return g
            end
            local gi = toGrid(i, 2, false)
            local gj = toGrid(j, 1, false)
            if dir == DOWN then
                gi = toGrid(i, 2, true)
                gj = toGrid(j, 1, false)
            elseif dir == LEFT then
                gi = toGrid(j, 2, false)
                gj = toGrid(i, 1, false)
            elseif dir == RIGHT then
                gi = toGrid(j, 2, false)
                gj = toGrid(i, 1, true)
            end
            if sk.range[i][j] and self.grid[gi] and self.grid[gi][gj] then
                self:shadeSquare(gi, gj, clr, true)
            end
        end
    end
end

function Battle:renderMovement(sp, full)
    local move = sp:getMovement()
    local row, col = self:findSprite(sp:getId())
    local clr = { 0, 0, 1 }
    self:shadeSquare(row, col, clr)
    for i = 1, move do
        self:shadeSquare(row + i, col, clr, full)
        self:shadeSquare(row - i, col, clr, full)
        self:shadeSquare(row, col + i, clr, full)
        self:shadeSquare(row, col - i, clr, full)
        for j = 1, move - i do
            self:shadeSquare(row + i, col + j, clr, full)
            self:shadeSquare(row - i, col + j, clr, full)
            self:shadeSquare(row + i, col - j, clr, full)
            self:shadeSquare(row - i, col - j, clr, full)
        end
    end
end

function Battle:renderSpriteImage(cx, cy, x, y, sp)
    if cx ~= x or cy ~= y then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(
            sp.sheet,
            sp.on_frame,
            TILE_WIDTH * (cx + self.origin_x - 1) + sp.w / 2,
            TILE_HEIGHT * (cy + self.origin_y - 1) + sp.h / 2,
            0,
            sp.dir,
            1,
            sp.w / 2,
            sp.h / 2
        )
    end
end

function Battle:renderMovementHover()
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    if sp then self:renderMovement(sp, false) end
end

function Battle:renderMovementActive()
    self:renderMovement(self:getSprite(), true)
end

function Battle:renderViews(depth)
    for i = 1, #self.stack do
        local views = self.stack[i]['views']
        for j = 1, #views do
            if views[j][1] == depth
            and (views[j][2] == PERSIST or i == #self.stack) then
                views[j][3]()
            end
        end
    end
end

function Battle:renderGrid()

    -- Draw grid at fixed position
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    for i = 1, self.grid_h do
        for j = 1, self.grid_w do
            if self.grid[i][j] then
                love.graphics.rectangle('line',
                    (self.origin_x + j - 1) * TILE_WIDTH,
                    (self.origin_y + i - 1) * TILE_HEIGHT,
                    TILE_WIDTH,
                    TILE_HEIGHT
                )
            end
        end
    end

    -- Render active views below the cursor, in stack order
    self:renderViews(BEFORE)

    -- Draw cursors always
    self:renderCursors()

    -- Render active views above the cursor, in stack order
    self:renderViews(AFTER)
end

function Battle:renderHealthbar(sp)
    local x, y = sp:getPosition()
    local ratio = sp.health / sp.attributes['endurance']
    local c = self:getCursor()
    y = y + sp.h + ite(c[3], 0, -1) - 1
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x + 3, y, sp.w - 6, 3)
    love.graphics.setColor(0.4, 0, 0.2, 1)
    love.graphics.rectangle('fill', x + 3, y, (sp.w - 6) * ratio, 3)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('line', x + 3, y, sp.w - 6, 3)
end

function Battle:renderOverlay(cam_x, cam_y)

    -- Render healthbars below each sprite
    for i = 1, #self.allies do self:renderHealthbar(self.allies[i]) end
    for i = 1, #self.enemies do self:renderHealthbar(self.enemies[i]) end

    -- Render battle hover box
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    local str_size = 100
    local box_x = cam_x + VIRTUAL_WIDTH - BOX_MARGIN * 2 - str_size
    local box_y = cam_y + BOX_MARGIN
    local box_w = str_size + BOX_MARGIN
    local box_h = BOX_MARGIN + LINE_HEIGHT * 3 + 6
    local hover_str = "View battle options"
    if sp then
        local name_str = sp.name
        local hp_str = sp.health .. "/" .. sp.attributes['endurance']
        local ign_str = sp.ignea .. "/" .. sp.attributes['focus']
        if self:isAlly(sp) then
            hover_str = "Move " .. sp.name
            love.graphics.setColor(0, 0.1, 0, RECT_ALPHA)
        else
            hover_str = "Examine " .. sp.name
            love.graphics.setColor(0.1, 0, 0, RECT_ALPHA)
        end
        love.graphics.rectangle('fill', box_x, box_y, box_w, box_h)
        renderString(name_str, box_x + HALF_MARGIN, box_y + HALF_MARGIN)
        renderString(hp_str,
            box_x + box_w - HALF_MARGIN - #hp_str * CHAR_WIDTH,
            box_y + HALF_MARGIN + LINE_HEIGHT + 3
        )
        renderString(ign_str,
            box_x + box_w - HALF_MARGIN - #ign_str * CHAR_WIDTH,
            box_y + HALF_MARGIN + LINE_HEIGHT * 2 + 9
        )
        love.graphics.draw(sp.itex, sp.icons[str_to_icon['endurance']],
            box_x + HALF_MARGIN,
            box_y + HALF_MARGIN + LINE_HEIGHT,
            0, 1, 1, 0, 0
        )
        love.graphics.draw(sp.itex, sp.icons[str_to_icon['focus']],
            box_x + HALF_MARGIN,
            box_y + HALF_MARGIN + LINE_HEIGHT * 2 + 6,
            0, 1, 1, 0, 0
        )
    else
        love.graphics.setColor(0, 0, 0, RECT_ALPHA)
        love.graphics.rectangle('fill', box_x, box_y, box_w,
            BOX_MARGIN + LINE_HEIGHT
        )
        renderString('Empty', box_x + HALF_MARGIN, box_y + HALF_MARGIN)
    end

    -- Render battle menu or battle text
    local s = self:getStage()
    if s == STAGE_MOVE then
        hover_str = 'Select a space to move to'
    elseif s == STAGE_TARGET then
        hover_str = 'Select a target for ' .. self:getSkill().name
    end
    if s == STAGE_MENU then
        self:getMenu():render(cam_x, cam_y, self.chapter)
    else
        local x = cam_x + VIRTUAL_WIDTH - BOX_MARGIN - #hover_str * CHAR_WIDTH
        local y = cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
        renderString(hover_str, x, y)
    end
end
