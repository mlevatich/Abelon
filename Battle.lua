require 'Util'
require 'Constants'

require 'Menu'

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
    local grid_index = 11
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
    self.pulse_timer = 0

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
    for i = 1, #self.allies  do  self.allies[i]:changeBehavior('battle') end
    for i = 1, #self.enemies do self.enemies[i]:changeBehavior('battle') end
    self.player:changeMode('battle')
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
    local begin = MenuItem('Begin turn', {}, nil, nil, next)
    local restart1 = MenuItem('Restart battle', {}, nil, nil, pass,
        "Start the battle over from the beginning?"
    )
    local restart2 = MenuItem('Restart chapter', {}, nil, nil, pass,
        "Are you SURE you want to restart the chapter? You will lose ALL \z
         progress made during the chapter."
    )
    local quit = MenuItem('Save and quit', {}, nil, nil, die,
        "Save current progress and close the game?")
    local m = { begin, restart1, restart2, quit }
    self.battle_menu = Menu(nil, m, BOX_MARGIN, BOX_MARGIN)
end

function Battle:openAttackMenu()

end

function Battle:openAssistMenu()

end

function Battle:openEnemyMenu()

end

function Battle:openOptionsMenu()

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
        if keys['d'] then
            self.battle_menu:back()
        elseif keys['f'] then
            self.battle_menu:forward(self.chapter)
        elseif keys['up'] ~= keys['down'] then
            self.battle_menu:hover(ite(keys['up'], UP, DOWN))
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
        end
    end

    -- Advance render timers
    self.pulse_timer = self.pulse_timer + dt
    while self.pulse_timer > PULSE do
        self.pulse_timer = self.pulse_timer - PULSE
        self.cursor[3] = not self.cursor[3]
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

    -- Draw cursor if not in a menu
    if not self.battle_menu then
        self:renderCursor()
    end
end

function Battle:renderOverlay(cam_x, cam_y)

    if self.battle_menu then
        self.battle_menu:render(cam_x, cam_y, self.chapter)
    end
    -- TODO: healthbars, ignea, status, etc.
end
