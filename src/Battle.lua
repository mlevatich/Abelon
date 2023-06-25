require 'src.Util'
require 'src.Constants'

require 'src.Menu'
require 'src.Music'
require 'src.Skill'
require 'src.Triggers'

Battle = class('Battle')

GridSpace = class('GridSpace')

PULSE = 0.4

function GridSpace:initialize(sp)
    self.occupied = nil
    if sp then
        self.occupied = sp
    end
    self.assists = {}
    self.n_assists = 0
end

function Battle:initialize(battle_id, player, chapter)

    self.id = battle_id
    self.chapter = chapter

    -- Tracking state
    self.turn = 0
    self.seen = {}

    -- Data file
    local data_file = 'Abelon/data/battles/' .. self.id .. '.txt'
    local data = readLines(data_file)

    -- Get base tile of the top left of the grid
    local tile_origin = readArray(data[3], tonumber)
    self.origin_x = tile_origin[1]
    self.origin_y = tile_origin[2]

    -- Battle grid
    local grid_index = 14
    local grid_dim = readArray(data[grid_index], tonumber)
    self.grid_w = grid_dim[1]
    self.grid_h = grid_dim[2]
    self.grid = {}
    for i = 1, self.grid_h do
        local row_str = data[grid_index + i]
        self.grid[i] = {}
        for j = 1, self.grid_w do
            self.grid[i][j] = ite(row_str:sub(j, j) == 'T', GridSpace:new(), F)
        end
    end

    -- Participants and statuses
    self.player = player
    self.status = {}
    self.enemy_order = readArray(data[6])
    self.participants = concat(
        self:readEntities(data, 4),
        self:readEntities(data, 5)
    )
    self.enemy_action = nil

    -- Win conditions and loss conditions
    self.win  = readArray(data[7], function(s) return wincons[s]  end)
    self.lose = readArray(data[8], function(s) return losscons[s] end)
    self.turnlimits = readArray(data[9], tonumber)
    if next(self.turnlimits) then table.insert(self.lose, {}) end
    self:adjustDifficultyFrom(MASTER)

    -- Battle cam starting location
    self.battle_cam_x = self.chapter.camera_x
    self.battle_cam_y = self.chapter.camera_y
    self.battle_cam_speed = 170

    -- Render timers
    self.pulse_timer = 0
    self.pulse = false
    self.shading = 0.2
    self.shade_dir = 1
    self.action_in_progress = nil
    self.skill_in_use = nil
    self.render_bexp = false
    self.levelup_queue = {}

    -- Music
    self.chapter:stopMusic()
    self.chapter.current_music = readField(data[10])

    -- Action stack
    self.suspend_stack = {}
    self.stack = {}

    -- Participants to battle behavior
    for i = 1, #self.participants do
        self.participants[i]:changeBehavior('battle')
    end
    self.player:changeMode('battle')
end

-- Put participants on grid
function Battle:readEntities(data, idx)

    local t = {}
    for k,v in pairs(readDict(data[idx], ARR, nil, tonumber)) do

        -- Put sprite on grid and into participants
        local sp = self.chapter:getSprite(k)
        table.insert(t, sp)
        self.grid[v[2]][v[1]] = GridSpace:new(sp)

        -- Initialize sprite status
        self.status[sp:getId()] = {
            ['sp']       = sp,
            ['team']     = ite(idx == 4, ALLY, ENEMY),
            ['location'] = { v[1], v[2] },
            ['effects']  = {},
            ['alive']    = true,
            ['acted']    = false,
            ['attack']   = nil,
            ['assist']   = nil,
            ['prepare']  = nil
        }
        local x_tile = self.origin_x + v[1]
        local y_tile = self.origin_y + v[2]
        local x, y = self.chapter:getMap():tileToPixels(x_tile, y_tile)
        sp:resetPosition(x, y)

        -- If an enemy, prepare their first skill
        if self.status[sp:getId()]['team'] == ENEMY then
            self:prepareSkill(sp)
        end
    end
    return t
end

function Battle:adjustDifficultyFrom(old)

    -- Adjust enemy stats
    local new = self.chapter.difficulty
    local factor = 3 * (old - new)
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if not self:isAlly(sp) then
            local attrs = sp.attributes
            local adjust = {
                'endurance', 'focus', 'force', 'affinity', 'reaction'
            }
            for j = 1, #adjust do
                local real = factor
                if adjust[j] == 'endurance' then real = 2 * (old - new) end
                attrs[adjust[j]] = math.max(0, attrs[adjust[j]] - real)
            end
            sp.health = math.min(sp.health, attrs['endurance'] * 2)
            sp.ignea = math.min(sp.ignea, attrs['focus'])
        end
    end

    -- Adjust turn limit, if there is one
    if next(self.turnlimits) then
        self.turnlimit = self.turnlimits[new]
        self.lose[#self.lose] = { self.turnlimit .. ' turns pass',
            function(b) return ite(b.turn > b.turnlimit, 'turnlimit', false) end
        }

        -- Stupid hack to refresh objectives box
        if self.stack then
            self:closeMenu()
            self:openBattleStartMenu()
            local m = self:getMenu()
            m:hover(DOWN)
            m:hover(DOWN)
            m:forward()
            m:hover(UP)
            m:forward()
            for i = 1, new - 1 do m:hover(DOWN) end
        end
    end
end

function Battle:getId()
    return self.id
end

function Battle:getCamera()
    self:updateBattleCam()
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
    local st = self.stack
    table.remove(st, #st)
    while next(st) and st[#st]['stage'] == STAGE_BUBBLE do
        table.remove(st, #st)
    end
end

function Battle:stackBase()
    return {
        ['stage'] = STAGE_FREE,
        ['cursor'] = { 1, 1, false, { HIGHLIGHT } },
        ['views'] = {
            { BEFORE, TEMP, function(b) b:renderMovementHover() end }
        }
    }
end

function Battle:stackBubble(c, moves)
    local x = 1
    local y = 1
    if c then
        x = c[1]
        y = c[2]
    end
    bubble = {
        ['stage'] = STAGE_BUBBLE,
        ['cursor'] = { x, y, false, { 0, 0, 0, 0 } },
        ['views'] = {}
    }
    if moves then bubble['moves'] = moves end
    return bubble
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
    if next(self.stack) ~= nil then
        local st = self.stack[#self.stack]
        return st['menu']
    end
    return nil
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

function Battle:getMoves()
    for i = 1, #self.stack do
        if self.stack[#self.stack - i + 1]['moves'] then
            return self.stack[#self.stack - i + 1]['moves']
        end
    end
end

function Battle:findSprite(sp_id)
    local loc = self.status[sp_id]['location']
    return loc[2], loc[1]
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
    if self.grid[y] and self.grid[y][x] and (x ~= c[1] or y ~= c[2]) then
        sfx['hover']:play()
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

function Battle:isAlly(sp)
    return self.status[sp:getId()]['team'] == ALLY
end

function Battle:getTmpAttributes(sp)
    local y, x = self:findSprite(sp:getId())
    return mkTmpAttrs(
        sp.attributes,
        self.status[sp:getId()]['effects'],
        ite(self:isAlly(sp), self.grid[y][x].assists, {})
    )
end

function Battle:getStage()
    if next(self.stack) ~= nil then
        return self.stack[#self.stack]['stage']
    end
    return nil
end

function Battle:setStage(s)
    self.stack[#self.stack]['stage'] = s
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

function Battle:checkTriggers(phase, doneAction)
    local triggers = battle_triggers[self.id][phase]
    for k, v in pairs(triggers) do
        if not self.seen[k] then
            local scene_id = v(self)
            if scene_id then
                self.seen[k] = true
                self:suspend(self.id .. '-' .. scene_id, doneAction)
                return true
            end
        end
    end
    return false
end

function Battle:endTurn()

    -- Check triggers first
    local doneAction = function() self:endTurn() end
    if self:checkTriggers(ENEMY, doneAction) then return end

    -- Allies have their actions refreshed
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if self:isAlly(sp) then
            self.status[sp:getId()]['acted'] = false
        end
    end

    -- Prepare the first enemy's action and place it in self.enemy_action
    self:planNextEnemyAction()

    -- Let the first enemy go if exists, and prepare the subsequent enemy
    if self.enemy_action then
        self.stack = self.enemy_action
        self:playAction()
    else
        -- If there are no enemies, it's immediately the ally phase
        self:beginTurn()
    end
end

function Battle:beginTurn()

    -- Increment turn count
    self.turn = self.turn + 1

    -- Check win and loss
    local battle_over = self:checkWinLose()
    if battle_over then return end

    -- Start menu open
    self:openBeginTurnMenu()
end

function Battle:turnRefresh()

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

    -- Nobody has acted
    for i = 1, #self.participants do
        self.status[self.participants[i]:getId()]['acted'] = false
    end
end

function Battle:suspend(scene_id, effects)
    self.suspend_stack = self.stack
    self.stack = {}
    local doneAction = function()
        self:restore()
        if effects then effects() end
    end
    self.chapter:launchScene(scene_id, doneAction)
end

function Battle:restore()
    self.stack = self.suspend_stack
    self.suspend_stack = {}
end

function Battle:checkWinLose()
    for i = 1, #self.lose do
        local defeat_scene = self.lose[i][2](self)
        if defeat_scene then
            -- TODO: Change to defeat music
            local scene_id = self.id .. '-' .. defeat_scene .. '-defeat'
            self:suspend(scene_id, function()
                self.stack = {}
                self.battle_cam_x = self.chapter.camera_x
                self.battle_cam_y = self.chapter.camera_y
                self:openDefeatMenu()
            end)
            return true
        end
    end
    for i = 1, #self.win do
        if self.win[i][2](self) then
            self.chapter:stopMusic()
            sfx['victory']:play()
            self.stack = {}
            self:openVictoryMenu()
            return true
        end
    end
    return false
end

function Battle:restoreIgnea()

    -- Ignea is restored by 0% on master, 25% on adept, 50% on normal
    local factor = 0.0
    if self.chapter.difficulty == ADEPT then
        factor = 0.25
    elseif self.chapter.difficulty == NORMAL then
        factor = 0.5
    end

    -- Restore to all allied participants
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if self:isAlly(sp) then
            local max_ign = sp.attributes['focus']
            sp.ignea = math.min(sp.ignea + math.floor(max_ign * factor), max_ign)
        end
    end
end

function Battle:awardBonusExp()
    local bexp = 0
    if self.turnlimit then
        bexp = bexp + (self.turnlimit - self.turn) * 15
        self.render_bexp = bexp
    end
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if self:isAlly(sp) then
            local lvlups = sp:gainExp(bexp)
            if lvlups > 0 then self.levelup_queue[sp:getId()] = lvlups end
        end
    end
    return bexp
end

function Battle:openBattleStartMenu()
    local save = function(c)
        self:closeMenu()
        c:saveAndQuit()
    end
    local next = function(c)
        self:closeMenu()
        self:beginTurn()
    end
    local begin = MenuItem:new('Begin battle', {}, "Begin the battle", nil, next)
    local wincon = MenuItem:new('Objectives', {},
        'View victory and defeat conditions', self:buildObjectivesBox()
    )
    local settings = self.player:mkSettingsMenu()
    local party = self.player:mkPartyMenu()
    local restart = MenuItem:new('Restart chapter', {}, 'Start the chapter over',
        nil, function(c) c:reloadChapter() end,
        "Are you SURE you want to restart the chapter? You will lose ALL \z
         progress made during the chapter."
    )
    local quit = MenuItem:new('Save and quit', {}, 'Quit the game', nil, save,
        "Save current progress and close the game?"
    )
    local m = { wincon, party, settings, restart, quit, begin }
    self:openMenu(Menu:new(nil, m, BOX_MARGIN, BOX_MARGIN, true), {})
end

function Battle:openVictoryMenu()
    self:awardBonusExp()
    local desc = 'Finish the battle'
    local m = { MenuItem:new('Continue', {}, desc, nil,
        function(c)
            self.render_bexp = false
            if next(self.levelup_queue) then
                self:push({
                    ['stage'] = STAGE_LEVELUP,
                    ['views'] = {}
                })
            else
                self:restoreIgnea()
                self.chapter:launchScene(self.id .. '-victory')
                self.chapter:startMapMusic()
                self.chapter.battle = nil
            end
        end
    )}
    local v = { "     V I C T O R Y     " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(v), true, v, GREEN), {})
end

function Battle:openDefeatMenu()
    local m = { MenuItem:new('Restart battle', {}, 'Start the battle over', nil,
        function(c) c:reloadBattle() end
    )}
    local d = { "     D E F E A T     " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(d), true, d, RED), {
        { AFTER, TEMP, function(b) b:renderLens({ 0.5, 0, 0 }) end }
    })
end

function Battle:openEndTurnMenu()
    self.stack = {}
    local m = { MenuItem:new('End turn', {}, 'Begin enemy phase', nil,
        function(c)
            self:closeMenu()
            self:endTurn()
        end
    )}
    local e = { "   E N E M Y   P H A S E   " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(e), true, e, RED), {})
end

function Battle:openBeginTurnMenu()
    self.stack = {}
    local m = { MenuItem:new('Begin turn', {}, 'Begin ally phase', nil,
        function(c)
            self:closeMenu()
            self:turnRefresh()
            self.stack = { self:stackBase() }
            local y, x = self:findSprite(self.player:getId())
            local c = self:getCursor()
            c[1] = x
            c[2] = y
            self:checkTriggers(ALLY)
        end
    )}
    local e = { "   A L L Y   P H A S E   " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(e), true, e, HIGHLIGHT), {})
end

function Battle:openAttackMenu(sp)
    local attributes = MenuItem:new('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
        ['w'] = HBOX_WIDTH
    })
    local wait = MenuItem:new('Skip', {},
        'Skip ' .. sp.name .. "'s attack", nil, function(c)
            self:push(self:stackBubble())
            self:selectTarget()
        end
    )
    local skills_menu = sp:mkSkillsMenu(true, false)
    local weapon = skills_menu.children[1]
    local spell = skills_menu.children[2]
    for i = 1, #weapon.children do self:mkUsable(sp, weapon.children[i]) end
    for i = 1, #spell.children do self:mkUsable(sp, spell.children[i]) end
    local opts = { attributes, weapon, spell, wait }
    local moves = self:getMoves()
    self:openMenu(Menu:new(nil, opts, BOX_MARGIN, BOX_MARGIN, false), {
        { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end }
    })
end

function Battle:openAssistMenu(sp)
    local attributes = MenuItem:new('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
        ['w'] = HBOX_WIDTH
    })
    local wait = MenuItem:new('Skip', {},
        'Skip ' .. sp.name .. "'s assist", nil, function(c)
            self:endAction(false)
        end
    )
    local skills_menu = sp:mkSkillsMenu(true, false)
    local assist = skills_menu.children[3]
    for i = 1, #assist.children do self:mkUsable(sp, assist.children[i]) end
    local opts = { attributes, assist, wait }
    local c = self:getCursor(3)
    local moves = self:getMoves()
    self:openMenu(Menu:new(nil, opts, BOX_MARGIN, BOX_MARGIN, false), {
        { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end }
    })
end

function Battle:openAllyMenu(sp)
    local attrs = MenuItem:new('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
        ['w'] = HBOX_WIDTH
    })
    local sks = sp:mkSkillsMenu(true, false)
    self:openMenu(Menu:new(nil, { attrs, sks }, BOX_MARGIN, BOX_MARGIN, false), {})
end

function Battle:openEnemyMenu(sp)
    local attributes = MenuItem:new('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(self:getTmpAttributes(sp)),
        ['w'] = 390
    })
    local readying = MenuItem:new('Next Attack', {},
        'Prepared skill and target', {
        ['elements'] = self:buildReadyingBox(sp),
        ['w'] = HBOX_WIDTH
    })
    local skills = sp:mkSkillsMenu(false, true)
    local opts = { attributes, readying, skills }
    self:openMenu(Menu:new(nil, opts, BOX_MARGIN, BOX_MARGIN, false), {
        { BEFORE, TEMP, function(b) b:renderMovementHover() end }
    })
end

function Battle:openOptionsMenu()
    local save = function(c)
        self:closeMenu()
        c:quicksave()
    end
    local endfxn = function(c)
        self:closeMenu()
        self:openEndTurnMenu()
    end
    local wincon = MenuItem:new('Objectives', {},
        'View victory and defeat conditions', self:buildObjectivesBox()
    )
    local end_turn = MenuItem:new('End turn', {}, 'End your turn', nil, endfxn)
    local settings = self.player:mkSettingsMenu()
    table.remove(settings.children)
    local restart = MenuItem:new('Restart battle', {},
        'Start the battle over', nil, function(c) c:reloadBattle() end,
        "Start the battle over from the beginning?"
    )
    local quit = MenuItem:new('Suspend game', {},
        'Suspend battle state and quit', nil, save,
        "Create a temporary save and close the game?"
    )
    local m = { wincon, settings, restart, quit, end_turn }
    self:openMenu(Menu:new(nil, m, BOX_MARGIN, BOX_MARGIN, false), {})
end

function Battle:openLevelupMenu(sp, n)
    local m = { MenuItem:new('Level up', {}, nil, nil,
        function(c)
            self.stack[#self.stack]['menu'] = LevelupMenu(sp, n)
        end
    )}
    local l = { "     L E V E L   U P     " }
    local menu = Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(l), true, l, GREEN)
    self.stack[#self.stack]['menu'] = menu
end

function Battle:endAction(used_assist)
    local sp = self:getSprite()
    local end_menu = MenuItem:new('Confirm end', {},
        "Confirm " .. sp.name .. "'s actions this turn", nil,
        function(c) self:playAction() end
    )
    local views = {}
    if used_assist then
        views = {{ BEFORE, TEMP, function(b)
            b:renderSkillRange({ 0, 1, 0 })
        end }}
    end
    self:openMenu(Menu:new(nil, { end_menu }, BOX_MARGIN, BOX_MARGIN, false), views)
end

function Battle:buildReadyingBox(sp)

    -- Start with basic skill box
    local stat = self.status[sp:getId()]
    local prep = stat['prepare']
    local hbox = prep['sk']:mkSkillBox(icon_texture, icons, false, false)

    -- Update priority for this sprite (would happen later anyway)
    if hasSpecial(stat['effects'], {}, 'enrage') then
        prep['prio'] = { FORCED, 'kath' }
    end

    -- Make prio elements
    local send = { prep['prio'][1] }
    if send[1] == FORCED then
        send[2] = self.status[prep['prio'][2]]['sp']:getName()
    end
    hbox = concat(hbox, prep['sk']:mkPrioElements(send))

    -- Add enemy order
    local o = 0
    for i = 1, #self.enemy_order do
        if self.enemy_order[i] == sp:getId() then o = i end
    end
    local s = ite(o == 1, 'st', ite(o == 2, 'nd', ite(o == 3, 'rd', 'th')))
    table.insert(hbox, mkEle('text', { 'Order: ' .. o .. s }, 415, 13))
    return hbox
end

function Battle:buildObjectivesBox()
    local joinOr = function(d)
        local res = ''
        for i = 1, #d do
            local s = d[i][1]
            res = res .. s
            if i < #d then
                res = res .. ' or '
            else
                res = res .. '.'
            end
        end
        return res:sub(1,1):upper() .. res:sub(2)
    end
    local idt     = 30
    local wstr, _ = splitByCharLimit(joinOr(self.win), HBOX_CHARS_PER_LINE)
    local lstr, _ = splitByCharLimit(joinOr(self.lose), HBOX_CHARS_PER_LINE)
    local longest = max(mapf(string.len, concat(wstr, lstr)))
    local w       = BOX_MARGIN + idt + longest * CHAR_WIDTH + BOX_MARGIN
    return {
        ['elements'] = {
            mkEle('text', {'Victory'},
                BOX_MARGIN, BOX_MARGIN, GREEN),
            mkEle('text', wstr,
                idt + BOX_MARGIN, BOX_MARGIN + LINE_HEIGHT),
            mkEle('text', {'Defeat'},
                BOX_MARGIN, BOX_MARGIN + LINE_HEIGHT * 3, RED),
            mkEle('text', lstr,
                idt + BOX_MARGIN, BOX_MARGIN + LINE_HEIGHT * 4)
        },
        ['w'] = w
    }
end

function Battle:mkUsable(sp, sk_menu)
    local sk = skills[sk_menu.id]
    sk_menu.hover_desc = 'Use ' .. sk_menu.name
    local ignea_spent = sk.cost
    local sk2 = self:getSkill()
    if sk2 then ignea_spent = ignea_spent + sk2.cost end
    local obsrv = hasSpecial(self.status[sp:getId()]['effects'], {}, 'observe')
    if sp.ignea < ignea_spent or (sk.id == 'observe' and obsrv) then
        sk_menu.setPen = function(c) love.graphics.setColor(unpack(DISABLE)) end
    else
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
                    { BEFORE, TEMP, function(b)
                        b:renderSkillRange(zclr)
                    end }
                }
            })
        end
    end
end

function Battle:selectAlly(sp)
    local c = self:getCursor()
    local new_c = { c[1], c[2], c[3], { 0.4, 0.4, 1, 1 } }
    local moves = self:validMoves(sp, c[2], c[1])
    self:push({
        ['stage'] = STAGE_MOVE,
        ['sp'] = sp,
        ['cursor'] = new_c,
        ['moves'] = moves,
        ['views'] = {
            { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end },
            { AFTER, PERSIST, function(b)
                local y, x = b:findSprite(sp:getId())
                b:renderSpriteImage(new_c[1], new_c[2], x, y, sp)
            end }
        }
    })
    self:checkTriggers(SELECT)
end

function Battle:getSpent(i, j)
    local moves = self:getMoves()
    if moves then
        for k = 1, #moves do
            if moves[k]['to'][1] == i
            and moves[k]['to'][2] == j
            then
                return moves[k]['spend']
            end
        end
    end
    return 0
end

function Battle:getMovement(sp, i, j)
    local attrs = self:getTmpAttributes(sp)
    local spent = self:getSpent(i, j)
    return math.floor(attrs['agility'] / 4) - spent
end

function Battle:validMoves(sp, i, j)

    -- Get sprite's base movement points
    local move = self:getMovement(sp, i, j)

    -- Run djikstra's algorithm on grid
    local dist, _ = sp:djikstra(self.grid, { i, j }, nil, move)

    -- Reachable nodes have distance < move
    local moves = {}
    for y = math.max(i - move, 1), math.min(i + move, #self.grid) do
        for x = math.max(j - move, 1), math.min(j + move, #self.grid[y]) do
            if dist[y][x] <= move then
                table.insert(moves,
                    { ['to'] = { y, x }, ['spend'] = dist[y][x] }
                )
            end
        end
    end
    return moves
end

function Battle:selectTarget()
    local sp = self:getSprite()
    local c = self:getCursor(2)
    local moves = self:validMoves(sp, c[2], c[1])
    if #moves <= 1 then
        self:push(self:stackBubble(c, moves))
        self:openAssistMenu(sp)
    else
        local nc = { c[1], c[2], c[3], { 0.6, 0.4, 0.8, 1 } }
        self:push({
            ['stage'] = STAGE_MOVE,
            ['sp'] = sp,
            ['cursor'] = nc,
            ['moves'] = moves,
            ['views'] = {
                { BEFORE, TEMP, function(b)
                    b:renderMovement(moves, 1)
                end },
                { AFTER, PERSIST, function(b)
                    b:renderSpriteImage(nc[1], nc[2], c[1], c[2], sp)
                end }
            }
        })
    end
end

function Battle:useAttack(sp, attack, attack_dir, c_attack, dryrun)
    local i, j = self:findSprite(sp:getId())
    local sp_a = ite(self:isAlly(sp), self.grid[i][j].assists, {})
    local t = self:skillRange(attack, attack_dir, c_attack)
    local ts = {}
    local ts_a = {}
    for k = 1, #t do
        local space = self.grid[t[k][1]][t[k][2]]
        local target = space.occupied
        if target then
            table.insert(ts, target)
            table.insert(ts_a, ite(self:isAlly(target), space.assists, {}))
        end
    end
    return attack:use(sp, sp_a, ts, ts_a, self.status, self.grid, dryrun)
end

function Battle:kill(sp)
    local i, j = self:findSprite(sp:getId())
    self.grid[i][j].occupied = nil
    self.status[sp:getId()]['alive'] = false
end

function Battle:pathToWalk(sp, path, next_sk)
    local move_seq = {}
    if #path == 0 then
        table.insert(move_seq, function(d)
            self.skill_in_use = next_sk
            d()
        end)
    end
    for i = 1, #path do
        table.insert(move_seq, function(d)
            self.skill_in_use = next_sk
            return sp:walkToBehaviorGeneric(function()
                self:moveSprite(sp, path[i][2], path[i][1])
                d()
            end, self.origin_x + path[i][2], self.origin_y + path[i][1], true)
        end)
    end
    return move_seq
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
    if attack and attack.aim['type'] == DIRECTIONAL then
        attack_dir = computeDir(c_attack, c_move1)
    end
    local assist_dir = UP
    if assist and assist.aim['type'] == DIRECTIONAL then
        assist_dir = computeDir(c_assist, c_move2)
    end

    -- Shorthand
    local ox = self.origin_x
    local oy = self.origin_y
    local sp_y, sp_x = self:findSprite(sp:getId())

    -- Make behavior sequence

    -- Move 1
    local move1_path = sp:djikstra(self.grid,
        { sp_y, sp_x },
        { c_move1[2], c_move1[1] }
    )
    local seq = self:pathToWalk(sp, move1_path, attack)

    -- Attack
    table.insert(seq, function(d)
        if not attack then
            return sp:waitBehaviorGeneric(d, 'combat', 0.2)
        end
        return sp:skillBehaviorGeneric(function()
            local hurt, dead, lvlups = self:useAttack(sp,
                attack, attack_dir, c_attack
            )
            sp.ignea = sp.ignea - attack.cost
            for k, v in pairs(lvlups) do
                if lvlups[k] > 0 then self.levelup_queue[k] = v end
            end
            for i = 1, #hurt do
                if hurt[i] ~= sp then
                    hurt[i]:behaviorSequence({ function(d)
                        hurt[i]:fireAnimation('hurt', function()
                            hurt[i]:changeBehavior('battle')
                        end)
                        return pass
                    end }, pass)
                end
            end
            for i = 1, #dead do
                dead[i]:behaviorSequence({ function(d)
                    dead[i]:fireAnimation('death', function()
                        local did = dead[i]:getId()
                        local stat = self.status[did]
                        if stat['team'] == ENEMY then
                            self.chapter:getMap():dropSprite(did)
                        end
                    end)
                    return pass
                end }, pass)
                self:kill(dead[i])
            end
            d()
        end, attack, attack_dir, c_attack[1] + ox, c_attack[2] + oy)
    end)

    -- Move 2
    local move2_path = sp:djikstra(self.grid,
        { c_move1[2], c_move1[1] },
        { c_move2[2], c_move2[1] }
    )
    seq = concat(seq, self:pathToWalk(sp, move2_path, assist))

    -- Assist
    table.insert(seq, function(d)
        if not assist then
            return sp:waitBehaviorGeneric(d, 'combat', 0.2)
        end
        return sp:skillBehaviorGeneric(function()
            sp.ignea = sp.ignea - assist.cost
            local t = self:skillRange(assist, assist_dir, c_assist)
            for i = 1, #t do

                -- Get the buffs this assist will confer, based on
                -- the sprite's attributes
                local buffs = assist:use(self:getTmpAttributes(sp))

                -- Put the buffs on the grid
                local g = self.grid[t[i][1]][t[i][2]]
                for j = 1, #buffs do
                    table.insert(g.assists, buffs[j])
                end
                g.n_assists = g.n_assists + 1
            end
            d()
        end, assist, assist_dir, c_assist[1] + ox, c_assist[2] + oy)
    end)

    -- Register behavior sequence with sprite
    sp:behaviorSequence(seq, function()
            self.action_in_progress = nil
            self.skill_in_use = nil
            sp:changeBehavior('battle')
        end
    )

    -- Process other battle results of actions
    c_sp[1] = c_move2[1]
    c_sp[2] = c_move2[2]
    if attack then self.status[sp:getId()]['attack'] = attack end
    if assist then self.status[sp:getId()]['assist'] = assist end

    -- Force player to watch the action
    self.action_in_progress = sp
    self:push({
        ['stage'] = STAGE_WATCH,
        ['sp'] = sp,
        ['views'] = {}
    })
end

function Battle:rangeToTiles(sk, dir, c)

    local scale = #sk.range
    local toGrid = function(x, k, flip)
        local g = c[k] - (scale + 1) / 2 + x
        if flip then
            g = c[k] + (scale + 1) / 2 - x
        end
        return g
    end

    local tiles = {}
    for i = 1, scale do
        for j = 1, scale do
            if sk.range[i][j] then
                local gi = toGrid(i, 2, false)
                local gj = toGrid(j, 1, false)
                if dir == DOWN then
                    gi = toGrid(i, 2, true)
                    gj = toGrid(j, 1, true)
                elseif dir == LEFT then
                    gi = toGrid(j, 2, true)
                    gj = toGrid(i, 1, false)
                elseif dir == RIGHT then
                    gi = toGrid(j, 2, false)
                    gj = toGrid(i, 1, true)
                end
                table.insert(tiles, { gi, gj })
            end
        end
    end
    return tiles
end

function Battle:skillRange(sk, dir, c)
    return filter(
        function(t) return self.grid[t[1]] and self.grid[t[1]][t[2]] end,
        self:rangeToTiles(sk, dir, c)
    )
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

    -- Advance render timers
    local c = self:getCursor()
    self.pulse_timer = self.pulse_timer + dt
    while self.pulse_timer > PULSE do
        self.pulse_timer = self.pulse_timer - PULSE
        self.pulse = not self.pulse
        if c then c[3] = self.pulse end
    end
    self.shading = self.shading + self.shade_dir * dt / 3
    if self.shading > 0.4 then
        self.shading = 0.4
        self.shade_dir = -1
    elseif self.shading < 0.2 then
        self.shading = 0.2
        self.shade_dir = 1
    end

    -- Control determined by stage
    local s     = self:getStage()
    local m     = self:getMenu()
    local d     = keys['d']
    local f     = keys['f']
    local up    = keys['up']
    local down  = keys['down']
    local left  = keys['left']
    local right = keys['right']

    if m then

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
    end

    if s == STAGE_FREE then

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
            local x, y = self:newCursorPosition(up, down, left, right)
            self:moveCursor(x, y)

            local space = self.grid[y][x].occupied
            if f and not (space and space ~= sp) then
                local moves = self:getMoves()
                for i = 1, #moves do
                    if moves[i]['to'][1] == y and moves[i]['to'][2] == x then
                        if not c then
                            self:openAttackMenu(sp)
                        else
                            self:openAssistMenu(sp)
                        end
                        break
                    end
                end
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

            if f then
                if sk.type ~= ASSIST then
                    local c_cur = self:getCursor()
                    local t = self.grid[c_cur[2]][c_cur[1]].occupied
                    local can_obsv = t and self:isAlly(t) and t.id ~= 'elaine'
                    if not (sk.id == 'observe' and not can_obsv) then
                        self:selectTarget()
                    end
                else
                    self:endAction(true)
                end
            end
        end

    elseif s == STAGE_WATCH then

        -- Clean up after actions are performed
        if not self.action_in_progress then

            if next(self.levelup_queue) then
                self:push({
                    ['stage'] = STAGE_LEVELUP,
                    ['views'] = {}
                })
                return
            end

            -- Check triggers
            if self:checkTriggers(END_ACTION) then
                return
            end

            -- Say this sprite acted and reset stack
            local sp = self:getSprite()
            self.status[sp:getId()]['acted'] = true
            self.stack = { self.stack[1] }

            -- Check win and loss
            if self:checkWinLose() then return end

            -- If there are enemies that need to go next, have them go.
            if self.enemy_action then
                self:planNextEnemyAction()
                if self.enemy_action then
                    self.stack = self.enemy_action
                    self:playAction()
                end
            end

            -- If all allies have acted, switch to enemy phase
            local ally_phase_over = true
            for i = 1, #self.participants do
                local sp = self.participants[i]
                if self:isAlly(sp) and not self.status[sp:getId()]['acted'] then
                    ally_phase_over = false
                end
            end
            if ally_phase_over and self.chapter.turn_autoend then
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

    elseif s == STAGE_LEVELUP then

        -- Check levelups
        if not m then
            local k, v = next(self.levelup_queue)
            if k then
                self:openLevelupMenu(self.status[k]['sp'], v)
                self.levelup_queue[k] = self.levelup_queue[k] - 1
                if self.levelup_queue[k] == 0 then
                    self.levelup_queue[k] = nil
                end
            else
                self:pop()
            end
        end
    end
end

function Battle:updateBattleCam()
    local focus = self.action_in_progress
    local c = self:getCursor()
    if focus then
        local x, y = focus:getPosition()
        local w, h = focus:getDimensions()
        self.battle_cam_x = x + math.ceil(w / 2) - (VIRTUAL_WIDTH / ZOOM) / 2
        self.battle_cam_y = y + math.ceil(h / 2) - (VIRTUAL_HEIGHT / ZOOM) / 2
    elseif c then
        self.battle_cam_x = (c[1] + self.origin_x) * TILE_WIDTH 
                          - (VIRTUAL_WIDTH / ZOOM) / 2 - TILE_WIDTH / 2
        self.battle_cam_y = (c[2] + self.origin_y) * TILE_HEIGHT 
                          - (VIRTUAL_HEIGHT / ZOOM) / 2 - TILE_HEIGHT / 2
    end
end

-- Prepare this sprite's next skill
function Battle:prepareSkill(e, used)

    -- TODO: skill selection strategy
    local sk = e.skills[1]
    self.status[e:getId()]['prepare'] = { ['sk'] = sk, ['prio'] = { sk.prio } }
end

function Battle:planTarget(e, plan)

    -- Get targeting priority
    local stat = self.status[e:getId()]
    local prio = stat['prepare']['prio'][1]

    -- If the target is forced, it doesn't matter where they are. Target them.
    if prio == FORCED then
        local sp = self.status[stat['prepare']['prio'][2]]['sp']
        for i = 1, #plan['options'] do
            if sp == plan['options'][i]['sp'] then
                return plan['options'][i], nil
            end
        end
        return nil, nil
    end

    -- The set of choices is all ally sprites, unless some sprites are within
    -- striking distance, in which case only reachable sprites are considered
    local tgts = filter(function(o) return o['reachable'] end, plan['options'])
    if not next(tgts) then tgts = plan['options'] end

    -- Pick a target from the set of choices based on the sprite's priorities
    local tgt = nil -- Who to target
    local mv  = nil -- Which move to take (optional)

    if prio == CLOSEST then

        -- Target whichever sprite requires the least movement to attack
        local min_dist = math.huge
        for i = 1, #tgts do
            for j = 1, #tgts[i]['moves'] do
                local d = tgts[i]['moves'][j]['attack']['dist']
                if d <= min_dist then
                    min_dist = d
                    tgt, mv = tgts[i], tgts[i]['moves'][j]
                end
            end
        end
    elseif prio == KILL then

        -- Target whichever sprite will suffer the highest percent of their
        -- current health in damage (with 100% meaning they'd die)
        local max_percent = 0
        for i = 1, #tgts do
            for j = 1, #tgts[i]['moves'] do
                local a = tgts[i]['moves'][j]['attack']
                local d = self:useAttack(e, plan['sk'], a['dir'], a['c'], true)
                for k = 1, #d do
                    if d[k]['percent'] >= max_percent then
                        max_percent = d[k]['percent']
                        tgt, mv = tgts[i], tgts[i]['moves'][j]
                    end
                end
            end
        end
    elseif prio == DAMAGE then

        -- Target whichever sprite and move will achieve the maximum damage
        -- across all affected sprites
        local max_dmg = 0
        for i = 1, #tgts do
            for j = 1, #tgts[i]['moves'] do
                local a = tgts[i]['moves'][j]['attack']
                local d = self:useAttack(e, plan['sk'], a['dir'], a['c'], true)
                local sum = 0
                for k = 1, #d do sum = sum + d[k]['flat'] end
                if sum >= max_dmg then
                    max_dmg = sum
                    tgt, mv = tgts[i], tgts[i]['moves'][j]
                end
            end
        end
    elseif prio == STRONGEST then

        -- Target whichever sprite poses the biggest threat
        local max_attrs = 0
        for i = 1, #tgts do
            local attrs = self:getTmpAttributes(tgts[i]['sp'])
            local sum = 0
            for _,v in pairs(attrs) do sum = sum + v end
            if sum >= max_attrs then
                max_attrs = sum
                tgt, mv = tgts[i], nil
            end
        end
    end
    return tgt, mv
end

function Battle:planAction(e, plan, other_plans)

    -- Select a target and move based on skill prio and enemies in range
    local target, move = self:planTarget(e, plan)

    -- Get skill being used and suggested move
    local move = nil
    if not move then

        -- If no suggested move, compute the nearest one
        -- TODO: pick a non-interfering tile based on other_plans
        local min_dist = math.huge
        for i = 1, #target['moves'] do
            local d = target['moves'][i]['attack']['dist']
            if d < min_dist then
                min_dist = d
                move = target['moves'][i]
            end
        end
    end

    -- Return move data, and attack data if target is reachable
    if target['reachable'] then
        return move['move_c'], move['attack']['c'], target['sp']
    end
    return move['move_c'], nil, nil
end

function Battle:getAttackAngles(e, sp, sk)

    -- Initializing stuff
    local y,  x  = self:findSprite(sp:getId())
    local ey, ex = self:findSprite(e:getId())
    local g = self.grid
    local attacks = {}

    -- Tile transpose function
    local addTransposedAttack = function(c, dir)
        local ts = self:rangeToTiles(sk, ite(dir, dir, UP), c)
        for i = 1, #ts do
            local y_dst = ey + (y - ts[i][1])
            local x_dst = ex + (x - ts[i][2])
            local ac = { c[1] + (x - ts[i][2]), c[2] + (y - ts[i][1]) }
            if g[y_dst] and g[y_dst][x_dst] and (not g[y_dst][x_dst].occupied
            or g[y_dst][x_dst].occupied == e) and g[ac[2]] and g[ac[2]][ac[1]]
            then
                table.insert(attacks, {
                    ['c'] = ac,
                    ['from'] = { y_dst, x_dst },
                    ['dir'] = ite(dir, dir, UP)
                })
            end
        end
    end

    -- Add transposed attacks
    if sk.aim['type'] == DIRECTIONAL then
        addTransposedAttack({ ex, ey - 1 }, UP)
        addTransposedAttack({ ex, ey + 1 }, DOWN)
        addTransposedAttack({ ex - 1, ey }, LEFT)
        addTransposedAttack({ ex + 1, ey }, RIGHT)
    else
        addTransposedAttack({ ex, ey })
    end
    return attacks
end

function Battle:mkInitialPlan(e, sps)

    -- Get skill
    local sk = self.status[e:getId()]['prepare']['sk']

    -- Preemptively get shortest paths for the grid, and enemy movement
    local y, x = self:findSprite(e:getId())
    local paths_dist, paths_prev = e:djikstra(self.grid, { y, x })
    local movement = math.floor(self:getTmpAttributes(e)['agility'] / 4)

    -- Compute ALL movement options!
    local opts = {}
    for i = 1, #sps do

        -- Init opts for this sprite
        opts[i] = {}
        opts[i]['sp'] = sps[i]
        opts[i]['moves'] = {}
        opts[i]['reachable'] = false

        -- Get all attacks that can be made against this sprite using the skill
        local attacks = self:getAttackAngles(e, sps[i], sk)
        for j = 1, #attacks do

            -- Get distance and path to attack location
            local attack_from = attacks[j]['from']
            local dist = paths_dist[attack_from[1]][attack_from[2]]
            if dist ~= math.huge then

                -- Sprite should move to path node with dist == movement
                local move_c = { attack_from[2], attack_from[1] }
                local n = attack_from
                for k = 1, dist - movement do
                    n = paths_prev[n[1]][n[2]]
                    move_c[1] = n[2]
                    move_c[2] = n[1]
                end

                -- Candidate move
                local c = {
                    ['move_c'] = move_c,
                    ['attack'] = {
                        ['dist'] = dist,
                        ['c'] = attacks[j]['c'],
                        ['from'] = attacks[j]['from'],
                        ['dir'] = attacks[j]['dir']
                    }
                }
                local c_reachable = move_c[1] == attack_from[2]
                                and move_c[2] == attack_from[1]

                -- If candidate move is reachable, we will only accept reachable
                -- moves now. Clean out moves (all unreachable) and mark flag.
                if c_reachable and not opts[i]['reachable'] then
                    opts[i]['moves'] = {}
                    opts[i]['reachable'] = true
                end

                -- If candidate is reachable, or if we don't care whether or not
                -- it's reachable, add it to moves
                if c_reachable or not opts[i]['reachable'] then
                    table.insert(opts[i]['moves'], c)
                end
            end
        end
    end
    return { ['sk'] = sk, ['options'] = opts }
end

-- Plan the next enemy's action
function Battle:planNextEnemyAction()

    -- Clear previous action and stack
    self.enemy_action = nil

    -- Get enemies who haven't gone yet, in order of action
    local enemies = {}
    for i = 1, #self.enemy_order do
        local stat = self.status[self.enemy_order[i]]
        local prev = self:getSprite()
        if stat['alive'] and not stat['acted']
        and not (prev and prev == stat['sp'])
        then
            table.insert(enemies, stat['sp'])
        end
    end

    -- If there are no more enemies who can act, do nothing
    if not next(enemies) then return end
    local e = enemies[1]

    -- If the current enemy is stunned, it misses it's action
    local stat = self.status[e:getId()]
    if hasSpecial(stat['effects'], {}, 'stun') then
        local y, x = self:findSprite(e:getId())
        local move = { ['cursor'] = { x, y }, ['sp'] = e }
        self.enemy_action = { self:stackBase(), move, {}, {}, move, {}, {} }
        return
    end

    -- If the current enemy is enraged, force it to target Kath
    if hasSpecial(stat['effects'], {}, 'enrage') then
        stat['prepare']['prio'] = { FORCED, 'kath' }
    end

    -- For every enemy who hasn't acted, make a tentative plan for their action
    local sps = filter(function(p) return self:isAlly(p) end, self.participants)
    local plans = {}
    for i = 1, #enemies do

        -- Precompute options for targeting all ally sprites
        plans[i] = self:mkInitialPlan(enemies[i], sps)

        -- Compute this enemy's preferred action in a vacuum and add it to plan
        local pref_move, _, pref_target = self:planAction(enemies[i], plans[i])
        plans[i]['pref'] = {
            ['target'] = pref_target,
            ['move'] = pref_move
        }
    end

    -- Prepare the first enemy's action, taking into account what the
    -- following enemies are planning and would prefer
    local m_c, a_c, _ = self:planAction(e, plans[1], plans)
    self:prepareSkill(enemies[1], ite(a_c, true, false))

    -- Declare next enemy action to be played as an action stack
    local move = { ['cursor'] = m_c, ['sp'] = e }
    local attack = ite(a_c, { ['cursor'] = a_c, ['sk'] = plans[1]['sk'] }, {})
    self.enemy_action = { self:stackBase(), move, {}, attack, move, {}, {} }
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

function Battle:renderLens(clr)
    love.graphics.setColor(clr[1], clr[2], clr[3], 0.1)
    local map = self.chapter.current_map
    love.graphics.rectangle('fill', 0, 0,
        map.width * TILE_WIDTH, map.height * TILE_HEIGHT
    )
end

function Battle:renderSkillInUse()
    local sk = self.skill_in_use
    if not sk then return end
    local str_w = #sk.name * CHAR_WIDTH
    local w = str_w + 55 + BOX_MARGIN
    local h = LINE_HEIGHT + BOX_MARGIN
    local x = VIRTUAL_WIDTH - w - BOX_MARGIN
    local y = BOX_MARGIN
    love.graphics.setColor(0, 0, 0, RECT_ALPHA)
    love.graphics.rectangle('fill', x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        icon_texture,
        icons[sk:treeToIcon()],
        x + HALF_MARGIN + str_w + 8, y + HALF_MARGIN,
        0, 1, 1, 0, 0
    )
    love.graphics.draw(
        icon_texture,
        icons[sk.type],
        x + HALF_MARGIN + str_w + 33, y + HALF_MARGIN,
        0, 1, 1, 0, 0
    )
    renderString(sk.name, x + HALF_MARGIN, y + HALF_MARGIN + 3)
end

function Battle:renderSpriteImage(cx, cy, x, y, sp)
    if cx ~= x or cy ~= y then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(
            spritesheet,
            sp:getCurrentQuad(),
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

function Battle:getTargetDirection()

    -- Get skill and cursor info
    local c = self:getCursor()
    local sk = self:getSkill()

    -- Get direction to point the skill
    local dir = UP
    if sk.aim['type'] == DIRECTIONAL then
        local o = self:getCursor(2)
        dir = ite(c[1] > o[1], RIGHT,
                  ite(c[1] < o[1], LEFT,
                      ite(c[2] > o[2], DOWN, UP)))
    end
    return dir
end

function Battle:outlineTile(tx, ty, edges, clr)
    local x1 = (self.origin_x + tx - 1) * TILE_WIDTH
    local y1 = (self.origin_y + ty - 1) * TILE_HEIGHT
    local x2 = x1 + TILE_WIDTH
    local y2 = y1 + TILE_HEIGHT
    local sh = 0.3
    local newclr = { clr[1] - sh, clr[2] - sh, clr[3] - sh, 1 }
    if self.grid[ty] and self.grid[ty][tx] then
        love.graphics.setColor(unpack(newclr))
        if not next(edges) then
            if not self.grid[ty + 1] or not self.grid[ty + 1][tx] then
                love.graphics.line(x1, y2, x2, y2)
            end
            if not self.grid[ty - 1] or not self.grid[ty - 1][tx] then
                love.graphics.line(x1, y1, x2, y1)
            end
            if not self.grid[ty][tx + 1] then
                love.graphics.line(x2, y1, x2, y2)
            end
            if not self.grid[ty][tx - 1] then
                love.graphics.line(x1, y1, x1, y2)
            end
        else
            for i = 1, #edges do
                local e = edges[i]
                if     e == UP   then love.graphics.line(x1, y1, x2, y1)
                elseif e == DOWN then love.graphics.line(x1, y2, x2, y2)
                elseif e == LEFT then love.graphics.line(x1, y1, x1, y2)
                else                  love.graphics.line(x2, y1, x2, y2)
                end
            end
        end

    end
end

function Battle:renderSkillRange(clr)

    -- What skill?
    local c = self:getCursor()
    local sk = self:getSkill()

    -- Get direction to point the skill
    local dir = self:getTargetDirection()

    -- Render red squares given by the skill range
    local tiles = self:skillRange(sk, dir, c)
    for i = 1, #tiles do
        self:shadeSquare(tiles[i][1], tiles[i][2], clr, 1)
    end

    -- For bounded free aim skills, render the boundary
    if sk.aim['type'] == FREE and sk.aim['scale'] < 100 then
        local t = self:getCursor(2)
        for x = 0, sk.aim['scale'] do
            for y = 0, sk.aim['scale'] - x do
                local l = t[1] - x
                local r = t[1] + x
                local d = t[2] + y
                local u = t[2] - y
                if x + y == sk.aim['scale'] then
                    self:outlineTile(r, d, { DOWN, RIGHT }, clr)
                    self:outlineTile(l, d, { DOWN, LEFT }, clr)
                    self:outlineTile(r, u, { UP, RIGHT }, clr)
                    self:outlineTile(l, u, { UP, LEFT }, clr)
                end
                self:outlineTile(r, d, {}, clr)
                self:outlineTile(l, d, {}, clr)
                self:outlineTile(r, u, {}, clr)
                self:outlineTile(l, u, {}, clr)
            end
        end
    end
end

function Battle:renderMovement(moves, full)
    for i = 1, #moves do
        self:shadeSquare(moves[i]['to'][1], moves[i]['to'][2], {0, 0, 1}, full)
    end
end

function Battle:renderMovementHover()
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    if sp and not self.status[sp:getId()]['acted'] then
        local i, j = self:findSprite(sp:getId())
        self:renderMovement(self:validMoves(sp, i, j), 0.5)
    end
end

function Battle:renderViews(depth)
    for i = 1, #self.stack do
        local views = self.stack[i]['views']
        for j = 1, #views do
            if views[j][1] == depth
            and (views[j][2] == PERSIST or i == #self.stack) then
                views[j][3](self)
            end
        end
    end
end

function Battle:renderHealthbar(sp)
    local x, y = sp:getPositionOnScreen()
    local ratio = sp.health / (sp.attributes['endurance'] * 2)
    y = y + sp.h + ite(self.pulse, 0, -1) - 1
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x + 3, y, sp.w - 6, 3)
    love.graphics.setColor(0.4, 0, 0.2, 1)
    love.graphics.rectangle('fill', x + 3, y, (sp.w - 6) * ratio, 3)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('line', x + 3, y, sp.w - 6, 3)
end

function Battle:renderStatus(sp)

    -- Get statuses
    local x, y = sp:getPositionOnScreen()
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
    local y_off = ite(self.pulse, 0, 1)
    if buffed then
        love.graphics.draw(icon_texture, status_icons[1],
            x + TILE_WIDTH - 8, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if debuffed then
        love.graphics.draw(icon_texture, status_icons[2],
            x + TILE_WIDTH - 16, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if augmented then
        love.graphics.draw(icon_texture, status_icons[4],
            x + 8, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if impaired then
        love.graphics.draw(icon_texture, status_icons[3],
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
                w - #str * CHAR_WIDTH - HALF_MARGIN,
                HALF_MARGIN + LINE_HEIGHT * i
            ))
        end
        return eles, LINE_HEIGHT * (#eles) + BOX_MARGIN
    end
    return {}, 0
end

function Battle:mkTileHoverBox(tx, ty)
    local sp = self.grid[ty][tx].occupied
    if not sp then return nil, nil, nil, nil end
    local w = BOX_MARGIN + CHAR_WIDTH * MAX_WORD

    -- Box contains sprite's name and status
    local name_str = sp.name
    local hp_str = sp.health .. "/" .. (sp.attributes['endurance'] * 2)
    local ign_str = sp.ignea .. "/" .. sp.attributes['focus']

    -- Compute box width from longest status
    local statuses = self.status[sp:getId()]['effects']
    local longest_status = 0
    for i = 1, #statuses do

        -- Space (in characters) between two strings in hover box
        local buf = 3

        -- Length of duration string
        local d = statuses[i].duration
        local dlen = ite(d == math.huge, 0, ite(d < 2, 6, ite(d < 10, 7, 8)))

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
        mkEle('image', icons[str_to_icon['endurance']],
              HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT, icon_texture),
        mkEle('image', icons[str_to_icon['focus']],
              HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT * 2 + 6, icon_texture)
    }

    -- Add sprite statuses
    local stat_eles = {}
    local y = HALF_MARGIN + LINE_HEIGHT * 3 + BOX_MARGIN
    for i = 1, #statuses do
        local cy = y + LINE_HEIGHT * (i - 1)
        local b = statuses[i].buff
        local d = statuses[i].duration
        local dur = ''
        if d ~= math.huge then
            dur = d .. ite(d > 1, ' turns', ' turn')
        end
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
end

function Battle:mkInnerHoverBox()
    local c = self:getCursor()
    local hbox, bw, bh, bclr = self:mkTileHoverBox(c[1], c[2])
    if not hbox then
        local w = BOX_MARGIN + CHAR_WIDTH * MAX_WORD
        local h = BOX_MARGIN + LINE_HEIGHT
        local clr = { 0, 0, 0 }
        return { mkEle('text', 'Empty', HALF_MARGIN, HALF_MARGIN) }, w, h, clr
    end
    return hbox, bw, bh, bclr
end

function Battle:renderTargetHoverBoxes()

    -- Get skill range
    local dir    = self:getTargetDirection()
    local sk     = self:getSkill()
    local c      = self:getCursor()
    local sp     = self:getSprite()
    local tiles  = self:skillRange(sk, dir, c)

    -- Iterate over tiles to see which ones need to render boxes
    local max_y = VIRTUAL_HEIGHT - BOX_MARGIN * 2 - FONT_SIZE - LINE_HEIGHT
    local cur_y = BOX_MARGIN
    for i = 1, #tiles do

        -- Switch tile of current sprite with prospective tile it's moving to
        local t = self.grid[tiles[i][1]][tiles[i][2]].occupied
        local move_c = self:getCursor(2)
        if t == sp then
            tiles[i][1] = move_c[2]
            tiles[i][2] = move_c[1]
        elseif tiles[i][1] == move_c[2] and tiles[i][2] == move_c[1] then
            local y, x = self:findSprite(sp:getId())
            tiles[i][1] = y
            tiles[i][2] = x
        end
        t = self.grid[tiles[i][1]][tiles[i][2]].occupied

        -- If there's a sprite on the tile and the skill affects that sprite,
        -- render the sprite's hover box
        if t and sk:hits(sp, t, self.status) then
            local box, w, h, clr = self:mkTileHoverBox(tiles[i][2], tiles[i][1])

            -- Only render if there's room for the whole box on screen
            if cur_y + h <= max_y then
                local cur_x = VIRTUAL_WIDTH - BOX_MARGIN - w
                table.insert(clr, RECT_ALPHA)
                love.graphics.setColor(unpack(clr))
                love.graphics.rectangle('fill', cur_x, cur_y, w, h)
                self:renderBoxElements(box, cur_x, cur_y)
                cur_y = cur_y + h + BOX_MARGIN
            else
                local cur_x = VIRTUAL_WIDTH - BOX_MARGIN - CHAR_WIDTH * 3
                renderString("...", cur_x, cur_y)
                break
            end
        end
    end
end

function Battle:renderBoxElements(box, base_x, base_y)
    for i = 1, #box do
        local e = box[i]
        if e['type'] == 'text' then
            local clr = ite(e['color'], e['color'], WHITE)
            love.graphics.setColor(unpack(clr))
            renderString(e['data'],
                base_x + e['x'], base_y + e['y'], true, e['auto_color']
            )
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

function Battle:renderHoverBoxes(ibox, w, ih, obox, oh, clr)

    -- Base coordinates for both boxes
    local outer_x = VIRTUAL_WIDTH - BOX_MARGIN - w
    local inner_x = outer_x
    local inner_y = BOX_MARGIN
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

function Battle:renderBattleText()

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
    local x = VIRTUAL_WIDTH - BOX_MARGIN - #hover_str * CHAR_WIDTH
    local y = VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE
    renderString(hover_str, x, y)
end

function Battle:renderBexp()
    local bexp = self.render_bexp
    local saved = self.turnlimit - self.turn
    local msg1 = saved .. " turns saved * 15 exp"
    local msg2 = bexp .. " bonus exp"

    local computeX = function(s)
        return VIRTUAL_WIDTH - BOX_MARGIN - #s * CHAR_WIDTH
    end
    local base_y = BOX_MARGIN
    love.graphics.setColor(unpack(DISABLE))
    renderString(msg1, computeX(msg1), base_y, true)
    love.graphics.setColor(unpack(HIGHLIGHT))
    renderString(msg2, computeX(msg2), base_y + LINE_HEIGHT, true)
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
end

function Battle:renderUnderlay()

    -- Render green squares on assisted grid tiles
    self:renderAssistSpaces()

    -- Render views over grid if we aren't watching a scene
    local s = self:getStage()
    if s ~= STAGE_WATCH and s ~= STAGE_LEVELUP then

        -- Render active views below the cursor, in stack order
        self:renderViews(BEFORE)

        -- Draw cursors always
        self:renderCursors()

        -- Render active views above the cursor, in stack order
        self:renderViews(AFTER)
    end
end

function Battle:renderOverlay()

    -- Render healthbars below each sprite, and status markers above
    love.graphics.push()
    love.graphics.origin()
    for i = 1, #self.participants do
        if self.chapter:getMap():getSprite(self.participants[i]:getId()) then
            self:renderHealthbar(self.participants[i])
            self:renderStatus(self.participants[i])
        end
    end
    love.graphics.pop()

    -- No overlay if stack has no cursors
    local s = self:getStage()
    if self:getCursor() then

        -- Dont render any other overlays while watching an action
        if s ~= STAGE_WATCH and s ~= STAGE_LEVELUP then

            -- Make and render hover boxes
            if s == STAGE_TARGET then
                self:renderTargetHoverBoxes()
            else
                local ibox, w, ih, clr = self:mkInnerHoverBox()
                local obox, oh = self:mkOuterHoverBox(w)
                self:renderHoverBoxes(ibox, w, ih, obox, oh, clr)
            end

            -- Render battle text if not in a menu
            if s ~= STAGE_MENU then
                self:renderBattleText()
            end
        elseif s == STAGE_WATCH then
            self:renderSkillInUse()
        end
    end

    -- Render menu if there is one
    local m = self:getMenu()
    if m then
        m:render(self.chapter)
        if self.render_bexp then self:renderBexp() end
    end

    -- Render what turn it is in the lower right
    if s and s ~= STAGE_WATCH and s ~= STAGE_LEVELUP then
        local turn_str = 'Turn ' .. self.turn
        renderString(turn_str,
            VIRTUAL_WIDTH - BOX_MARGIN - #turn_str * CHAR_WIDTH,
            VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE - LINE_HEIGHT
        )
    end
end

wincons = {
    ['rout'] = { "defeat all enemies",
        function(b)
            for _,v in pairs(b.status) do
                if v['team'] == ENEMY and v['alive'] then
                    return false
                end
            end
            return true
        end
    },
    ['escape'] = { "escape the battlefield",
        function(b)
             return false
        end
    }
}

losscons = {
    ['death'] = { "any ally dies",
        function(b)
            for k,v in pairs(b.status) do
                if v['team'] == ALLY and not v['alive'] then
                    return k
                end
            end
            return false
        end
    },
    ['defend'] = { "any enemy breaches the defended area",
        function(b)
             return false
        end
    }
}
