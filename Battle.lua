require 'Util'
require 'Constants'

require 'Menu'
require 'Music'

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
    self.phase = START
    self.state = nil

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

    -- Battle menu
    self.battle_menu = nil
    self.cursor = { 1, 1, false }

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
    self:begin()
end

function Battle:getId()
    return self.id
end

function Battle:getCamera()
    return self.battle_cam_x, self.battle_cam_y
end

function Battle:begin()

    -- Participants to battle behavior
    for i = 1, #self.allies  do  self.allies[i]:changeBehavior('battle') end
    for i = 1, #self.enemies do self.enemies[i]:changeBehavior('battle') end
    self.player:changeMode('battle')

    -- Cursor to Abelon
    local y, x = self:findSprite(self.player:getId())
    self.cursor = { x, y, false }

    -- Start menu open
    self:openStartMenu()
end

function Battle:nextPhase()
    if self.phase == START then
        self.phase = ALLY
        self.battle_menu = nil
        local y, x = self:findSprite(self.player:getId())
        self.cursor = { x, y, false }
    elseif self.phase == ALLY then
        self.phase = ENEMY
    else
        self.phase = START
    end
end

function Battle:openStartMenu()
    local die = function(c) love.event.quit(0) end
    local next = function(c) self:nextPhase() end
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
    self.battle_menu = Menu(nil, m, BOX_MARGIN, BOX_MARGIN)
end

function Battle:openAttackMenu(sp)

end

function Battle:openAssistMenu(sp)

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
    self.battle_menu = Menu(nil, opts, BOX_MARGIN, BOX_MARGIN)
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
    self.battle_menu = Menu(nil, m, BOX_MARGIN, BOX_MARGIN)
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

function Battle:update(keys, dt)

    -- Navigate the battle menu if it is open
    if self.battle_menu then
        local done = false
        if keys['d'] then
            done = self.battle_menu:back()
        elseif keys['f'] then
            self.battle_menu:forward(self.chapter)
        elseif keys['up'] ~= keys['down'] then
            self.battle_menu:hover(ite(keys['up'], UP, DOWN))
        end

        if done and self.phase ~= START then
            self.battle_menu = nil
        end
    else
        -- Move cursor during the ally phase if no menu is open
        local i = self.cursor[2]
        local j = self.cursor[1]
        if self.phase == ALLY then
            if keys['left'] and not keys['right'] and
               j - 1 >= 1 and self.grid[i][j - 1] then
                self.cursor[1] = self.cursor[1] - 1
            end
            if keys['right'] and not keys['left'] and
               j + 1 <= self.grid_w and self.grid[i][j + 1] then
                self.cursor[1] = self.cursor[1] + 1
            end
            if keys['up'] and not keys['down'] and
               i - 1 >= 1 and self.grid[i - 1][j] then
                self.cursor[2] = self.cursor[2] - 1
            end
            if keys['down'] and not keys['up'] and
               i + 1 <= self.grid_h and self.grid[i + 1][j] then
                self.cursor[2] = self.cursor[2] + 1
            end

            if keys['f'] then
                local space = self.grid[i][j]
                if not space.occupied then
                    self:openOptionsMenu()
                elseif self:isAlly(space.occupied) then
                    pass()
                else
                    self:openEnemyMenu(space.occupied)
                end
            end
        end
    end

    -- Advance render timers
    self.pulse_timer = self.pulse_timer + dt
    while self.pulse_timer > PULSE do
        self.pulse_timer = self.pulse_timer - PULSE
        self.cursor[3] = not self.cursor[3]
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

function Battle:renderCursor()

    -- Cursor position
    local x_tile = self.origin_x + self.cursor[1]
    local y_tile = self.origin_y + self.cursor[2]
    local x, y = self.chapter:getMap():tileToPixels(x_tile, y_tile)
    local shift = ite(self.cursor[3], 2, 3)
    local fx = x + TILE_WIDTH - shift
    local fy = y + TILE_HEIGHT - shift
    x = x + shift
    y = y + shift
    local len = 10 - shift
    love.graphics.setColor(unpack(HIGHLIGHT))
    love.graphics.line(x, y, x + len, y)
    love.graphics.line(x, y, x, y + len)
    love.graphics.line(fx, y, fx - len, y)
    love.graphics.line(fx, y, fx, y + len)
    love.graphics.line(x, fy, x, fy - len)
    love.graphics.line(x, fy, x + len, fy)
    love.graphics.line(fx, fy, fx - len, fy)
    love.graphics.line(fx, fy, fx, fy - len)
end

function Battle:shadeSquare(i, j, clr)
    if self.grid[i] and self.grid[i][j] then
        local x = (self.origin_x + j - 1) * TILE_WIDTH
        local y = (self.origin_y + i - 1) * TILE_HEIGHT
        love.graphics.setColor(clr[1], clr[2], clr[3], self.shading)
        love.graphics.rectangle('fill',
            x + 2, y + 2,
            TILE_WIDTH - 4, TILE_HEIGHT - 4
        )
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

    -- Render movement range
    local row = self.cursor[2]
    local col = self.cursor[1]
    local sp = self.grid[row][col].occupied
    if sp then
        local move = math.floor(sp.attributes['agility'] / 5)
        local clr = { 0, 0, 1 }
        self:shadeSquare(row, col, clr)
        for i = 1, move do
            self:shadeSquare(row + i, col, clr)
            self:shadeSquare(row - i, col, clr)
            self:shadeSquare(row, col + i, clr)
            self:shadeSquare(row, col - i, clr)
            for j = 1, move - i do
                self:shadeSquare(row + i, col + j, clr)
                self:shadeSquare(row - i, col + j, clr)
                self:shadeSquare(row + i, col - j, clr)
                self:shadeSquare(row - i, col - j, clr)
            end
        end
    end

    -- Draw cursor always
    self:renderCursor()
end

function Battle:renderOverlay(cam_x, cam_y)

    -- Render battle hover box
    local sp = self.grid[self.cursor[2]][self.cursor[1]].occupied
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
    if self.battle_menu then
        self.battle_menu:render(cam_x, cam_y, self.chapter)
    else
        local x = cam_x + VIRTUAL_WIDTH - BOX_MARGIN - #hover_str * CHAR_WIDTH
        local y = cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
        renderString(hover_str, x, y)
    end
end
