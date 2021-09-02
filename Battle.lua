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
    self.n_assists = 0
end

function Battle:init(battle_id, player, chapter)

    self.id = battle_id
    self.chapter = chapter

    -- Tracking state
    self.turn = 0

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
                ['sp']       = sp,
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
    self.enemy_queue = {}

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

    -- Graphics
    self.status_tex = self.chapter.itex
    self.status_icons = getSpriteQuads({0, 1, 2, 3}, self.status_tex, 8, 8, 23)

    -- Start the battle!
    self.stack = { self:stackBase() }
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

function Battle:stackBase()
    return {
        ['stage'] = STAGE_FREE,
        ['cursor'] = { 1, 1, false, { HIGHLIGHT } },
        ['views'] = {
            { BEFORE, TEMP, function() self:renderMovementHover() end },
            { BEFORE, PERSIST, function() self:renderAssistSpaces() end }
        }
    }
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
    local st = self.stack[#self.stack]
    return st['menu'], st['forced']
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

function Battle:openMenu(m, views, forced)
    self:push({
        ['stage'] = STAGE_MENU,
        ['menu'] = m,
        ['views'] = views,
        ['forced'] = forced
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
                self.origin_y + c_move1[2],
                true
            )
        end,
        function(d)
            if attack then
                return sp:skillBehaviorGeneric(
                    function()
                        local hurt, dead = self:useAttack(sp,
                            attack, attack_dir, c_attack
                        )
                        sp.ignea = sp.ignea - attack.cost
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
                return sp:waitBehaviorGeneric(d, 'combat', 0.2)
            end
        end,
        function(d)
            return sp:walkToBehaviorGeneric(
                function()
                    self:moveSprite(sp, c_move2[1], c_move2[2])
                    d()
                end,
                self.origin_x + c_move2[1],
                self.origin_y + c_move2[2],
                true
            )
        end,
        function(d)
            if assist then
                return sp:skillBehaviorGeneric(
                    function()
                        sp.ignea = sp.ignea - assist.cost
                        local t = self:skillRange(assist,
                            assist_dir, c_assist)
                        for i = 1, #t do

                            -- Get the buffs this assist will confer, based on
                            -- the sprite's attributes
                            local buffs = assist.use(self:getTmpAttributes(sp))

                            -- Put the buffs on the grid
                            local g = self.grid[t[i][1]][t[i][2]]
                            for j = 1, #buffs do
                                table.insert(g.assists, buffs[j])
                            end
                            g.n_assists = g.n_assists + 1
                        end
                        d()
                    end,
                    assist,
                    assist_dir,
                    c_assist[1] + self.origin_x,
                    c_assist[2] + self.origin_y
                )
            else
                return sp:waitBehaviorGeneric(d, 'combat', 0.2)
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
        ['views'] = {
            { BEFORE, TEMP, function() self:renderAssistSpaces() end }
        }
    })
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

function Battle:endTurn()

    -- Allies have their actions refreshed
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if self:isAlly(sp) then
            self.status[sp:getId()]['acted'] = false
        end
    end

    -- Construct a queue of stacks. One stack per enemy,
    -- representing that enemy's action
    self:planEnemyPhase()

    -- Let the first enemy go, if one exists
    if next(self.enemy_queue) then
        self.stack = table.remove(self.enemy_queue)
        self:playAction()
    else
        -- If there are no enemies, it's immediately the ally phase
        self:beginTurn()
    end
end

function Battle:begin()

    -- Participants to battle behavior
    for i = 1, #self.participants do
        self.participants[i]:changeBehavior('battle')
    end
    self.player:changeMode('battle')

    -- Start the first turn
    self:beginTurn()
end

function Battle:beginTurn()

    -- Increment turn count
    self.turn = self.turn + 1

    -- Decrement/clear statuses
    for _, v in pairs(self.status) do
        local es = v['effects']
        local i = 1
        while i <= #es do
            if es[i].duration > 1 then
                es[i].duration = es[i].duration - 1
                i = i + 1
            else
                table.remove(es, i)
            end
        end
    end

    -- Clear all assists from the field
    for i = 1, #self.grid do
        for j = 1, #self.grid[i] do
            if self.grid[i][j] then
                self.grid[i][j].assists = {}
                self.grid[i][j].n_assists = 0
            end
        end
    end

    -- Cursor to Abelon
    local y, x = self:findSprite(self.player:getId())
    self:moveCursor(x, y)

    -- Start menu open
    self:openStartMenu()
end

function Battle:openStartMenu()
    local die = function(c) love.event.quit(0) end
    local refresh = function()
        for i = 1, #self.participants do
            self.status[self.participants[i]:getId()]['acted'] = false
        end
    end
    local next = function(c)
        refresh()
        self:closeMenu()
    end
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
    self:openMenu(Menu(nil, m, BOX_MARGIN, BOX_MARGIN), {}, true)
end

function Battle:openEndTurnMenu()
    self:openMenu(Menu(nil, {
        MenuItem('End turn', {}, 'End your turn', nil,
            function(c)
                self:closeMenu()
                self:endTurn()
            end
        )
    }, BOX_MARGIN, BOX_MARGIN), {}, true)
end

function Battle:mkUsable(sp, sk_menu)
    local sk = skills[sk_menu.id]
    sk_menu.hover_desc = 'Use ' .. sk_menu.name
    local ignea_spent = sk.cost
    local sk2 = self:getSkill()
    if sk2 then ignea_spent = ignea_spent + sk2.cost end
    if sp.ignea >= ignea_spent then
        sk_menu.setPen = function(c) love.graphics.setColor(unpack(WHITE)) end
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
    local attributes = MenuItem('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
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
    local attributes = MenuItem('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
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

function Battle:openAllyMenu(sp)
    local attributes = MenuItem('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
        ['w'] = HBOX_WIDTH
    })
    local skills = sp:mkSkillsMenu(true)
    self:openMenu(Menu(nil, { attributes, skills }, BOX_MARGIN, BOX_MARGIN), {})
end

function Battle:openEnemyMenu(sp)
    local attributes = MenuItem('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
        ['w'] = 380
    })
    local readying = MenuItem('Next Attack', {},
        'Skill this enemy will use next', {
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
    local endfxn = function(c)
        self:closeMenu()
        self:endTurn()
    end
    local wincon = MenuItem('Objectives', {},
        'View victory and defeat conditions'
    )
    local end_turn = MenuItem('End turn', {},
        'End your turn', nil, endfxn,
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
    self:openMenu(Menu(nil, m, BOX_MARGIN, BOX_MARGIN), {})
end

function Battle:findSprite(sp_id)
    local loc = self.status[sp_id]['location']
    return loc[2], loc[1]
end

function Battle:isAlly(sp)
    return self.status[sp:getId()]['team'] == ALLY
end

function Battle:getTmpAttributes(sp)
    local y, x = self:findSprite(sp:getId())
    return mkTmpAttrs(
        sp.attributes,
        self.status[sp:getId()]['effects'],
        self.grid[y][x].assists
    )
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
    return attack.use(sp, sp_a, ts, ts_a, self.status, self.grid)
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
        local m, forced = self:getMenu()
        local done = false
        if d then
            done = m:back()
        elseif f then
            m:forward(self.chapter)
        elseif up ~= down then
            m:hover(ite(up, UP, DOWN))
        end

        if done and not forced then self:closeMenu() end

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
                else
                    self:openAllyMenu(o)
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
            local attrs = self:getTmpAttributes(sp)
            local movement = math.floor(attrs['agility'] / 5)
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

            -- Say this sprite acted and reset stack
            local sp = self:getSprite()
            self.status[sp:getId()]['acted'] = true
            self.stack = { self.stack[1] }

            -- If there are enemies that need to go next, have them go.
            if next(self.enemy_queue) ~= nil then
                self.stack = table.remove(self.enemy_queue)
                self:playAction()
            end

            -- If all allies have acted, switch to enemy phase
            local ally_phase_over = true
            for i = 1, #self.participants do
                local sp = self.participants[i]
                if self:isAlly(sp) and not self.status[sp:getId()]['acted'] then
                    ally_phase_over = false
                end
            end
            if ally_phase_over then
                self:openEndTurnMenu()
            else

                -- If all enemies have acted, it's time for the next turn
                local all_enemies_acted = true
                local enemies_alive = false
                for i = 1, #self.participants do
                    local sp = self.participants[i]
                    local sp_stat = self.status[sp:getId()]
                    if not self:isAlly(sp) and sp_stat['alive'] then
                        enemies_alive = true
                        if not sp_stat['acted'] then
                            all_enemies_acted = false
                        end
                    end
                end

                if all_enemies_acted and enemies_alive then
                    self:beginTurn()
                end
            end
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

-- Construct a queue of stacks. One stack per enemy,
-- representing that enemy's action
function Battle:planEnemyPhase()

    -- TODO: properly plan movement
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if not self:isAlly(sp) and self.status[sp:getId()]['alive'] then
            local y, x = self:findSprite(sp:getId())
            table.insert(self.enemy_queue, {
                self:stackBase(),
                { ['cursor'] = { x, y } },
                {},
                {}, -- TODO: attack goes here
                { ['cursor'] = { x, y }, ['sp'] = sp },
                {},
                {}
            })
        end
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
                local n = self.grid[i][j].n_assists
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
    local attrs = self:getTmpAttributes(sp)
    local move = math.floor(attrs['agility'] / 5) - abs(col - x) - abs(row - y)
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
    else
        local views = self.stack[#self.stack]['views']
        for i = 1, #views do views[i][3]() end
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

function Battle:renderStatus(sp)

    -- Get statuses
    local x, y = sp:getPosition()
    local statuses = self.status[sp:getId()]['effects']

    -- Collect what icons need to be rendered
    local buffed    = false
    local debuffed  = false
    local augmented = false
    local impaired  = false
    for i = 1, #statuses do
        local b = statuses[i].buff
        if b.attr == 'special' then
            if b.type == BUFF   then augmented = true end
            if b.type == DEBUFF then impaired  = true end
        else
            if b.type == BUFF   then buffed   = true end
            if b.type == DEBUFF then debuffed = true end
        end
    end

    -- Render icons
    local c = self:getCursor()
    local y_off = ite(c[3], 0, 1)
    if buffed then
        love.graphics.draw(self.status_tex, self.status_icons[1],
            x + TILE_WIDTH - 8, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if debuffed then
        love.graphics.draw(self.status_tex, self.status_icons[2],
            x + TILE_WIDTH - 16, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if augmented then
        love.graphics.draw(self.status_tex, self.status_icons[4],
            x + 8, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if impaired then
        love.graphics.draw(self.status_tex, self.status_icons[3],
            x, y + y_off, 0, 1, 1, 0, 0
        )
    end
end

function Battle:mkOuterHoverBox(w)

    -- Check for an ally sprite or empty space
    local c = self:getCursor()
    local g = self.grid[c[2]][c[1]]
    local sp = g.occupied
    if ((not sp) or self:isAlly(sp)) and g.n_assists > 0 then

        -- Make an element for each assist
        local eles = { mkEle('text', 'Assists', HALF_MARGIN, HALF_MARGIN) }
        for i = 1, #g.assists do
            local str = g.assists[i]:toStr()
            table.insert(eles, mkEle('text', str,
                w - #str * CHAR_WIDTH - HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT * i
            ))
        end
        return eles, LINE_HEIGHT * (#eles) + BOX_MARGIN
    end
    return {}, 0
end

function Battle:mkInnerHoverBox()

    -- Check for a sprite
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    local w = BOX_MARGIN + CHAR_WIDTH * MAX_WORD
    if sp then

        -- Box contains sprite's name and status
        local name_str = sp.name
        local hp_str = sp.health .. "/" .. sp.attributes['endurance']
        local ign_str = sp.ignea .. "/" .. sp.attributes['focus']

        -- Compute box width from longest status
        local statuses = self.status[sp:getId()]['effects']
        local longest_status = 0
        for i = 1, #statuses do

            -- Space (in characters) between two strings in hover box
            local buf = 3

            -- Length of duration string
            local d = statuses[i].duration
            local dlen = ite(d < 2, 6, ite(d < 10, 7, 8))

            -- Length of buff string
            local b = statuses[i].buff
            local blen = #b:toStr()

            -- Combine them all to get character size
            longest_status = math.max(longest_status, dlen + blen + buf)
        end
        w = math.max(w, longest_status * CHAR_WIDTH + BOX_MARGIN)

        -- Add sprite basic info
        local sp_eles = {
            mkEle('text', sp.name, HALF_MARGIN, HALF_MARGIN),
            mkEle('text', hp_str, w - HALF_MARGIN - #hp_str * CHAR_WIDTH,
                  HALF_MARGIN + LINE_HEIGHT + 3),
            mkEle('text', ign_str, w - HALF_MARGIN - #ign_str * CHAR_WIDTH,
                  HALF_MARGIN + LINE_HEIGHT * 2 + 9),
            mkEle('image', sp.icons[str_to_icon['endurance']],
                  HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT, sp.itex),
            mkEle('image', sp.icons[str_to_icon['focus']],
                  HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT * 2 + 6, sp.itex)
        }

        -- Add sprite statuses
        local stat_eles = {}
        local y = HALF_MARGIN + LINE_HEIGHT * 3 + BOX_MARGIN
        for i = 1, #statuses do
            local cy = y + LINE_HEIGHT * (i - 1)
            local b = statuses[i].buff
            local d = statuses[i].duration
            local dur = d .. ite(d > 1, ' turns', ' turn')
            table.insert(stat_eles, mkEle('text', dur,
                w - #dur * CHAR_WIDTH - HALF_MARGIN, cy
            ))
            local str = b:toStr()
            table.insert(stat_eles, mkEle('text', str, HALF_MARGIN, cy))
        end

        -- Concat info with statuses
        local h = BOX_MARGIN + HALF_MARGIN + LINE_HEIGHT
                * (#sp_eles - 2 + #stat_eles / 2)
        if next(statuses) ~= nil then
            h = h + HALF_MARGIN
        end
        local clr = ite(self:isAlly(sp), { 0, 0.1, 0.1 }, { 0.1, 0, 0 })
        return concat(sp_eles, stat_eles), w, h, clr
    else

        -- Box contains 'Empty'
        local h = BOX_MARGIN + LINE_HEIGHT
        local clr = { 0, 0, 0 }
        return { mkEle('text', 'Empty', HALF_MARGIN, HALF_MARGIN) }, w, h, clr
    end
end

function Battle:renderBoxElements(box, base_x, base_y)
    for i = 1, #box do
        local e = box[i]
        if e['type'] == 'text' then
            local clr = ite(e['color'], e['color'], WHITE)
            love.graphics.setColor(unpack(clr))
            renderString(e['data'], base_x + e['x'], base_y + e['y'], true)
        else
            love.graphics.setColor(unpack(WHITE))
            love.graphics.draw(
                e['texture'],
                e['data'],
                base_x + e['x'],
                base_y + e['y'],
                0, 1, 1, 0, 0
            )
        end
    end
end

function Battle:renderHoverBoxes(x, y, ibox, w, ih, obox, oh, clr)

    -- Base coordinates for both boxes
    local outer_x = x + VIRTUAL_WIDTH - BOX_MARGIN - w
    local inner_x = outer_x
    local inner_y = y + BOX_MARGIN
    local outer_y = inner_y + ih


    -- If there are assists
    if next(obox) ~= nil then

        -- Draw outer box
        love.graphics.setColor(0.05, 0.15, 0.05, RECT_ALPHA)
        love.graphics.rectangle('fill', outer_x, outer_y, w, oh)

        -- Draw outer box elements
        self:renderBoxElements(obox, outer_x, outer_y)
    end

    -- Draw inner box
    table.insert(clr, RECT_ALPHA)
    love.graphics.setColor(unpack(clr))
    love.graphics.rectangle('fill', inner_x, inner_y, w, ih)

    -- Draw inner box elements
    self:renderBoxElements(ibox, inner_x, inner_y)
end

function Battle:renderBattleText(cam_x, cam_y)

    -- Variables needed off stack
    local s = self:getStage()
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied

    -- Compute hover string
    local hover_str = 'View battle options'
    if s == STAGE_MOVE then
        hover_str = 'Select a space to move to'
    elseif s == STAGE_TARGET then
        hover_str = 'Select a target for ' .. self:getSkill().name
    elseif sp then
        if self:isAlly(sp) and not self.status[sp:getId()]['acted'] then
            hover_str = "Move " .. sp.name
        else
            hover_str = "Examine " .. sp.name
        end
    end

    -- Render hover string in the lower right
    local x = cam_x + VIRTUAL_WIDTH - BOX_MARGIN - #hover_str * CHAR_WIDTH
    local y = cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
    renderString(hover_str, x, y)
end

function Battle:renderOverlay(cam_x, cam_y)

    -- Render healthbars below each sprite, and status markers above
    for i = 1, #self.participants do
        self:renderHealthbar(self.participants[i])
        self:renderStatus(self.participants[i])
    end

    -- Dont render any other overlays while watching an action
    local s = self:getStage()
    if s ~= STAGE_WATCH then

        -- Make and render hover boxes
        local ibox, w, ih, clr = self:mkInnerHoverBox()
        local obox, oh = self:mkOuterHoverBox(w)
        self:renderHoverBoxes(cam_x, cam_y, ibox, w, ih, obox, oh, clr)

        -- Render menu if there is one, otherwise battle text in the lower right
        if s == STAGE_MENU then
            local m, _ = self:getMenu()
            m:render(cam_x, cam_y, self.chapter)
        else
            self:renderBattleText(cam_x, cam_y)
        end
        local turn_str = 'Turn ' .. self.turn
        renderString(turn_str,
            cam_x + VIRTUAL_WIDTH - BOX_MARGIN - #turn_str * CHAR_WIDTH,
            cam_y + VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE - LINE_HEIGHT
        )
    end
end
