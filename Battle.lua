require 'Util'
require 'Constants'

require 'Menu'

Battle = Class{}

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

    -- Battle participants
    local getSp = function(sp) return self.chapter:getSprite(sp) end
    self.player = player
    self.allies = readArray(data[4], getSp)
    self.enemies = readArray(data[5], getSp)

    -- Win conditions and loss conditions TODO: initialize
    self.wincon = function(b) return true end
    self.losscon = function(b) return false end

    -- Get base tile of the top left of the grid
    local tile_origin = readArray(data[3], tonumber)
    self.origin_x = tile_origin[1]
    self.origin_y = tile_origin[2]

    -- Initialize grid
    local grid_index = 11
    local grid_dim = readArray(data[grid_index], tonumber)
    self.grid_w = grid_dim[1]
    self.grid_h = grid_dim[2]
    self.grid = {}
    for i = 1, self.grid_h do
        local row_str = data[grid_index + i]
        self.grid[i] = {}
        for j = 1, self.grid_w do
            self.grid[i][j] = ite(row_str:sub(j, j) == 'T', T, F)
        end
    end

    -- Battle cam starting location
    self.battle_cam_x = (self.origin_x - 1) * TILE_WIDTH
                      + (self.grid_w * TILE_WIDTH - VIRTUAL_WIDTH) / 2
    self.battle_cam_y = (self.origin_y - 1) * TILE_HEIGHT
                      + (self.grid_h * TILE_HEIGHT - VIRTUAL_HEIGHT) / 2

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
    self:openStartMenu()
end

function Battle:nextPhase()
    -- Close player's open menu? potentially.
end

function Battle:openStartMenu()
    local die = function(c) love.event.quit(0) end
    local next = function(c) self:nextPhase() end
    local begin = MenuItem('Begin turn', {}, nil, nil, next)
    local restart = MenuItem('Restart battle', {}, nil, nil, pass,
        "Start the battle over from the beginning?"
    )
    local quit = MenuItem('Save and quit', {}, nil, nil, die,
        "Save current progress and close the game?")
    self.player:openMenu({ begin, restart, quit })
end

function Battle:openAttackMenu()

end

function Battle:openAssistMenu()

end

function Battle:openEnemyMenu()

end

function Battle:openOptionsMenu()

end

function Battle:update(dt)
    -- TODO: update progress of renders like "player phase start" and such
end

function Battle:renderGrid()

    -- Draw grid at fixed position
    love.graphics.setColor(1, 1, 1, 0.4)
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
end

function Battle:renderOverlay(cam_x, cam_y)
    -- TODO: healthbars, ignea, status, etc.
end
