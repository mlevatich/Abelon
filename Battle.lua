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
    self.assists = {}
end

function Battle:init(battle_id, player, chapter)

    self.id = battle_id
    self.chapter = chapter

    -- Tracking state
    self.turn = 1

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

    -- Put participants on grid
    local readEntities = function(idx)
        local t = {}
        for k,v in pairs(readDict(data[idx], ARR, nil, tonumber)) do
            local sp = self.chapter:getSprite(k)
            table.insert(t, sp)
            self.grid[v[2]][v[1]] = GridSpace(sp)
            self.status[sp:getId()] = {
                ['team']     = ite(idx == 4, ALLY, ENEMY),
                ['alive']    = true,
                ['acted']    = false,
                ['location'] = { v[1], v[2] },
                ['effects']  = {}
            }
            local x_tile = self.origin_x + v[1]
            local y_tile = self.origin_y + v[2]
            local x, y = self.chapter:getMap():tileToPixels(x_tile, y_tile)
            sp:resetPosition(x, y)
        end
        return t
    end

    -- Participants and statuses
    self.player = player
    self.status = {}
    self.participants = concat(readEntities(4), readEntities(5))

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
    self.action_in_progress = nil

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
            { BEFORE, TEMP, function() self:renderMovementHover() end },
            { BEFORE, PERSIST, function() self:renderAssistSpaces() end }
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
    while self.stack[#self.stack]['stage'] == STAGE_BUBBLE do
        table.remove(self.stack, #self.stack)
    end
end

function Battle:getCursor(n)
    c = nil
    found = 0
    n = ite(n, n, 1)
    for i = 1, #self.stack do
        if self.stack[#self.stack - i + 1]['cursor'] then
            c = self.stack[#self.stack - i + 1]['cursor']
            found = found + 1
            if found == n then
                return c
            end
        end
    end
    return nil
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
    for i = 1, #self.stack do
        if self.stack[#self.stack - i + 1]['sk'] then
            return self.stack[#self.stack - i + 1]['sk']
        end
    end
end

function Battle:moveCursor(x, y)
    local c = self:getCursor()
    if self.grid[y] and self.grid[y][x] then
        c[1] = x
        c[2] = y
    end
end

function Battle:moveSprite(sp, x, y)
    local old_y, old_x = self:findSprite(sp:getId())
    self.status[sp:getId()]['location'] = { x, y }
    self.grid[old_y][old_x].occupied = nil
    self.grid[y][x].occupied = sp
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

function Battle:playAction()

    -- Skills used
    local sp     = self:getSprite()
    local attack = self.stack[4]['sk']
    local assist = self.stack[7]['sk']

    -- Cursor locations
    local c_sp     = self.stack[1]['cursor']
    local c_move1  = self.stack[2]['cursor']
    local c_attack = self.stack[4]['cursor']
    local c_move2  = self.stack[5]['cursor']
    local c_assist = self.stack[7]['cursor']

    -- Derive directions from cursor locations
    local computeDir = function(c1, c2)
        if     c1[1] - c2[1] ==  1 then return RIGHT
        elseif c1[1] - c2[1] == -1 then return LEFT
        elseif c1[2] - c2[2] ==  1 then return DOWN
        else                            return UP
        end
    end
    local attack_dir = UP
    if attack and attack.aim == DIRECTIONAL_AIM then
        attack_dir = computeDir(c_attack, c_move1)
    end
    local assist_dir = UP
    if assist and assist.aim == DIRECTIONAL_AIM then
        assist_dir = computeDir(c_assist, c_move2)
    end

    -- Register behavior sequence with sprite
    sp:behaviorSequence({
        function(d)
            return sp:walkToBehaviorGeneric(
                function()
                    self:moveSprite(sp, c_move1[1], c_move1[2])
                    d()
                end,
                self.origin_x + c_move1[1],
                self.origin_y + c_move1[2]
            )
        end,
        function(d)
            if attack then
                return sp:skillBehaviorGeneric(
                    function()
                        local hurt, dead = self:useAttack(sp,
                            attack, attack_dir, c_attack
                        )
                        for i = 1, #hurt do
                            if hurt[i] ~= sp then
                                hurt[i]:behaviorSequence({
                                    function(d)
                                        hurt[i]:fireAnimation('hurt',
                                            function()
                                                hurt[i]:changeBehavior('battle')
                                            end
                                        )
                                        return pass
                                    end
                                }, pass)
                            end
                        end
                        for i = 1, #dead do
                            dead[i]:behaviorSequence({
                                function(d)
                                    dead[i]:fireAnimation('death',
                                        function()
                                            dead[i]:resetPosition(0, 0)
                                            dead[i]:changeBehavior('battle')
                                        end
                                    )
                                    return pass
                                end
                            }, pass)
                            self:kill(dead[i])
                        end
                        d()
                    end,
                    attack,
                    attack_dir,
                    c_attack[1] + self.origin_x,
                    c_attack[2] + self.origin_y
                )
            else
                return sp:waitBehaviorGeneric(d, 'combat', 1)
            end
        end,
        function(d)
            return sp:walkToBehaviorGeneric(
                function()
                    self:moveSprite(sp, c_move2[1], c_move2[2])
                    d()
                end,
                self.origin_x + c_move2[1],
                self.origin_y + c_move2[2])
        end,
        function(d)
            if assist then
                return sp:skillBehaviorGeneric(
                    function()
                        local t = self:skillRange(assist,
                            assist_dir, c_assist)
                        for i = 1, #t do
                            local as = self.grid[t[i][1]][t[i][2]].assists
                            table.insert(as, assist)
                        end
                        d()
                    end,
                    assist,
                    assist_dir,
                    c_assist[1] + self.origin_x,
                    c_assist[2] + self.origin_y
                )
            else
                return sp:waitBehaviorGeneric(d, 'combat', 1)
            end
        end
    },  function()
            self.action_in_progress = nil
            sp:changeBehavior('battle')
        end
    )

    -- Process other battle results of actions
    c_sp[1] = c_move2[1]
    c_sp[2] = c_move2[2]

    -- Force player to watch the action
    self.action_in_progress = sp
    self:push({
        ['stage'] = STAGE_WATCH,
        ['sp'] = sp,
        ['views'] = {}
    })

    -- (print debug info)
    -- local dirStr = function(d)
    --     return ite(d == UP, 'UP',
    --                ite(d == DOWN, 'DOWN',
    --                    ite(d == RIGHT, 'RIGHT', 'LEFT')))
    -- end
    -- print("Sprite action of: " .. sp.name)
    -- print("Start at: (" .. c_sp[1] .. ", " .. c_sp[2] .. ")")
    -- print("Move to: (" .. c_move1[1] .. ", " .. c_move1[2] .. ")")
    -- if c_attack then
    --     print("Cast " .. attack.name ..
    --           " at (" .. c_attack[1] .. ", " .. c_attack[2] ..
    --           ") with direction " .. dirStr(attack_dir))
    -- else
    --     print("Skip attack")
    -- end
    -- print("Move to: (" .. c_move2[1] .. ", " .. c_move2[2] .. ")")
    -- if c_assist then
    --     print("Cast " .. assist.name ..
    --           " at (" .. c_assist[1] .. ", " .. c_assist[2] ..
    --           ") with direction " .. dirStr(assist_dir))
    -- else
    --     print("Skip assist")
    -- end
    -- print("Action ends")
end

function Battle:endAction(used_assist)
    local sp = self:getSprite()
    local end_menu = MenuItem('Confirm end', {},
        "Confirm " .. sp.name .. "'s actions this turn", nil,
        function(c) self:playAction() end
    )
    local views = {}
    if used_assist then
        views = {{ BEFORE, TEMP, function()
            self:renderSkillRange({ 0, 1, 0 })
        end }}
    end
    self:openMenu(Menu(nil, { end_menu }, BOX_MARGIN, BOX_MARGIN), views)
end

function Battle:begin()

    -- Participants to battle behavior
    for i = 1, #self.participants do
        self.participants[i]:changeBehavior('battle')
    end
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
            local cclr = ite(sk.type == ASSIST, { 0.4, 1, 0.4, 1 },
                                                { 1, 0.4, 0.4, 1 })
            local new_c = { cx, cy, c[3], cclr }
            local zclr = ite(sk.type == ASSIST, { 0, 1, 0 }, { 1, 0, 0 })
            self:push({
                ['stage'] = STAGE_TARGET,
                ['cursor'] =  new_c,
                ['sp'] = sp,
                ['sk'] = sk,
                ['views'] = {
                    { BEFORE, TEMP, function()
                        self:renderSkillRange(zclr)
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
        'Skip ' .. sp.name .. "'s attack", nil, function(c)
            self:push({
                ['stage'] = STAGE_BUBBLE,
                ['cursor'] = { 1, 1, false, { 0, 0, 0, 0 }},
                ['views'] = {}
            })
            self:selectTarget()
        end
    )
    local skills_menu = sp:mkSkillsMenu(true)
    local weapon = skills_menu.children[1]
    local spell = skills_menu.children[2]
    for i = 1, #weapon.children do self:mkUsable(sp, weapon.children[i]) end
    for i = 1, #spell.children do self:mkUsable(sp, spell.children[i]) end
    local opts = { attributes, weapon, spell, wait }
    self:openMenu(Menu(nil, opts, BOX_MARGIN, BOX_MARGIN), {
        { BEFORE, TEMP, function() self:renderMovementFrom() end }
    })
end

function Battle:openAssistMenu(sp)
    local attributes = MenuItem('Attributes', {}, nil, {
        ['elements'] = sp:buildAttributeBox(),
        ['w'] = HBOX_WIDTH
    })
    local wait = MenuItem('Skip', {},
        'Skip ' .. sp.name .. "'s assist", nil, function(c)
            self:endAction(false)
        end
    )
    local skills_menu = sp:mkSkillsMenu(true)
    local assist = skills_menu.children[3]
    for i = 1, #assist.children do self:mkUsable(sp, assist.children[i]) end
    local opts = { attributes, assist, wait }
    local c = self:getCursor(3)
    self:openMenu(Menu(nil, opts, BOX_MARGIN, BOX_MARGIN), {
        { BEFORE, TEMP, function() self:renderMovementFrom(c[1], c[2]) end }
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
    local loc = self.status[sp_id]['location']
    return loc[2], loc[1]
end

function Battle:isAlly(sp)
    return self.status[sp:getId()]['team'] == ALLY
end

function Battle:selectAlly(sp)
    local c = self:getCursor()
    local new_c = { c[1], c[2], c[3], { 0.4, 0.4, 1, 1 } }
    self:push({
        ['stage'] = STAGE_MOVE,
        ['sp'] = sp,
        ['cursor'] = new_c,
        ['views'] = {
            { BEFORE, TEMP, function() self:renderMovementFrom() end },
            { AFTER, PERSIST, function()
                local y, x = self:findSprite(sp:getId())
                self:renderSpriteImage(new_c[1], new_c[2], x, y, sp)
            end }
        }
    })
end

function Battle:selectTarget()
    local sp = self:getSprite()
    local c = self:getCursor(2)
    local nc = { c[1], c[2], c[3], { 0.6, 0.4, 0.8, 1 } }
    self:push({
        ['stage'] = STAGE_MOVE,
        ['sp'] = sp,
        ['cursor'] = nc,
        ['views'] = {
            { BEFORE, TEMP, function()
                self:renderMovementFrom(c[1], c[2])
            end },
            { AFTER, PERSIST, function()
                self:renderSpriteImage(nc[1], nc[2], c[1], c[2], sp)
            end }
        }
    })
end

function Battle:useAttack(sp, attack, attack_dir, c_attack)
    local i, j = self:findSprite(sp:getId())
    local sp_a = self.grid[i][j].assists
    local t = self:skillRange(attack, attack_dir, c_attack)
    local ts = {}
    local ts_a = {}
    for i = 1, #t do
        local space = self.grid[t[i][1]][t[i][2]]
        local target = space.occupied
        if target then
            table.insert(ts, target)
            table.insert(ts_a, ite(self:isAlly(target), space.assists, {}))
        end
    end
    return attack.use(sp, sp_a, ts, ts_a, self.status)
end

function Battle:kill(sp)
    local i, j = self:findSprite(sp:getId())
    self.grid[i][j].occupied = nil
    self.status[sp:getId()]['alive'] = false
end

function Battle:skillRange(sk, dir, c)
    local scale = #sk.range
    local tiles = {}
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
                table.insert(tiles, {gi, gj})
            end
        end
    end
    return tiles
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
            local o = space.occupied
            if not o then
                self:openOptionsMenu()
            elseif self:isAlly(o) then
                if not self.status[o:getId()]['acted'] then
                    self:selectAlly(o)
                end
            else
                self:openEnemyMenu(o)
            end
        end

    elseif s == STAGE_MOVE then

        local sp = self:getSprite()
        local c = self:getCursor(3)
        if d then
            self:pop()
        else
            -- Move a sprite to a new location
            local y1, x1 = self:findSprite(sp:getId())
            local movement = sp:getMovement()
            if c then
                movement = movement - abs(c[1] - x1) - abs(c[2] - y1)
                x1 = c[1]
                y1 = c[2]
            end
            local x2, y2 = self:newCursorPosition(up, down, left, right)
            if abs(x2 - x1) + abs(y2 - y1) <= movement then
                self:moveCursor(x2, y2)
            end
        end

        c_cur = self:getCursor()
        space = self.grid[c_cur[2]][c_cur[1]].occupied
        if f and not (space and space ~= sp) then
            if not c then
                self:openAttackMenu(sp)
            else
                self:openAssistMenu(sp)
            end
        end

    elseif s == STAGE_TARGET then

        local sp = self:getSprite()
        local sk = self:getSkill()
        if d then
            self:pop()
        else
            local c = self:getCursor(2)
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
            if sk.type ~= ASSIST then
                self:selectTarget()
            else
                self:endAction(true)
            end
        end
    elseif s == STAGE_WATCH then

        -- Clean up after actions are performed
        if not self.action_in_progress then
            local sp = self:getSprite()
            self.status[sp:getId()]['acted'] = true
            self.stack = { self.stack[1] }
        end
    end

    -- Update battle camera position
    local focus = self.action_in_progress
    if focus then
        local x, y = focus:getPosition()
        local w, h = focus:getDimensions()
        self.battle_cam_x = x + w/2 - VIRTUAL_WIDTH / 2
        self.battle_cam_y = y + h/2 - VIRTUAL_HEIGHT / 2
    else
        local c = self:getCursor()
        self.battle_cam_x = (c[1] + self.origin_x)
                          * TILE_WIDTH - VIRTUAL_WIDTH / 2 - TILE_WIDTH / 2
        self.battle_cam_y = (c[2] + self.origin_y)
                          * TILE_HEIGHT - VIRTUAL_HEIGHT / 2 - TILE_HEIGHT / 2
    end

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

function Battle:shadeSquare(i, j, clr, alpha)
    if self.grid[i] and self.grid[i][j] then
        local x = (self.origin_x + j - 1) * TILE_WIDTH
        local y = (self.origin_y + i - 1) * TILE_HEIGHT
        love.graphics.setColor(clr[1], clr[2], clr[3], self.shading * alpha)
        love.graphics.rectangle('fill',
            x + 2, y + 2,
            TILE_WIDTH - 4, TILE_HEIGHT - 4
        )
    end
end

function Battle:renderAssistSpaces()
    for i = 1, self.grid_h do
        for j = 1, self.grid_w do
            if self.grid[i][j] then
                local n = #self.grid[i][j].assists
                if n > 0 then
                    local clr = { 0, 1, 0 }
                    if n == 1 then
                        clr = { 0.7, 1, 0.7 }
                    elseif n == 2 then
                        clr = { 0.4, 1, 0.4 }
                    elseif n == 3 then
                        clr = { 0.2, 1, 0.2}
                    end
                    self:shadeSquare(i, j, clr, 0.75)
                end
            end
        end
    end
end

function Battle:renderSkillRange(clr)

    -- Get skill and cursor info
    local c = self:getCursor()
    local sk = self:getSkill()

    -- Get direction to point the skill
    local dir = UP
    if sk.aim == DIRECTIONAL_AIM then
        local o = self:getCursor(2)
        dir = ite(c[1] > o[1], RIGHT,
                  ite(c[1] < o[1], LEFT,
                      ite(c[2] > o[2], DOWN, UP)))
    end

    -- Render red squares given by the skill range
    local tiles = self:skillRange(sk, dir, c)
    for i = 1, #tiles do
        self:shadeSquare(tiles[i][1], tiles[i][2], clr, 1)
    end
end

function Battle:renderMovement(x, y, sp, full)
    local row, col = self:findSprite(sp:getId())
    local move = sp:getMovement() - abs(col - x) - abs(row - y)
    local clr = { 0, 0, 1 }
    self:shadeSquare(y, x, clr, full)
    for i = 1, move do
        self:shadeSquare(y + i, x, clr, full)
        self:shadeSquare(y - i, x, clr, full)
        self:shadeSquare(y, x + i, clr, full)
        self:shadeSquare(y, x - i, clr, full)
        for j = 1, move - i do
            self:shadeSquare(y + i, x + j, clr, full)
            self:shadeSquare(y - i, x + j, clr, full)
            self:shadeSquare(y + i, x - j, clr, full)
            self:shadeSquare(y - i, x - j, clr, full)
        end
    end
end

function Battle:renderMovementHover()
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    if sp and not self.status[sp:getId()]['acted'] then
        local y, x = self:findSprite(sp:getId())
        self:renderMovement(x, y, sp, 0.5)
    end
end

function Battle:renderMovementFrom(x, y)
    local sp = self:getSprite()
    if x and y then
        self:renderMovement(x, y, sp, 1)
    else
        local sp_y, sp_x = self:findSprite(sp:getId())
        self:renderMovement(sp_x, sp_y, sp, 1)
    end
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

    -- Render views over grid if we aren't watching a scene
    if self:getStage() ~= STAGE_WATCH then

        -- Render active views below the cursor, in stack order
        self:renderViews(BEFORE)

        -- Draw cursors always
        self:renderCursors()

        -- Render active views above the cursor, in stack order
        self:renderViews(AFTER)
    end
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
    for i = 1, #self.participants do
        self:renderHealthbar(self.participants[i])
    end

    -- Render battle hover box
    local s = self:getStage()
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    local str_size = 100
    local box_x = cam_x + VIRTUAL_WIDTH - BOX_MARGIN * 2 - str_size
    local box_y = cam_y + BOX_MARGIN
    local box_w = str_size + BOX_MARGIN
    local box_h = BOX_MARGIN + LINE_HEIGHT * 3 + 6
    local hover_str = "View battle options"
    if s ~= STAGE_WATCH then
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
    end

    -- Render battle menu or battle text
    if s == STAGE_MOVE then
        hover_str = 'Select a space to move to'
    elseif s == STAGE_TARGET then
        hover_str = 'Select a target for ' .. self:getSkill().name
    end
    if s == STAGE_MENU then
        self:getMenu():render(cam_x, cam_y, self.chapter)
    elseif s ~= STAGE_WATCH then
        local x = cam_x + VIRTUAL_WIDTH - BOX_MARGIN - #hover_str * CHAR_WIDTH
        local y = cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
        renderString(hover_str, x, y)
    end
end
