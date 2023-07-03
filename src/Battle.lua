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

function Battle:initialize(player, game)

    self.game = game

    -- Tracking state
    self.turn = 0
    self.seen = {}

    -- Data file
    local data_file = 'Abelon/data/battles/' .. self:getId() .. '.txt'
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
    self.n_allies = 0
    for i = 1, #self.participants do
        if self:isAlly(self.participants[i]) then
            self.n_allies = self.n_allies + 1
        end
    end
    self.enemy_action = nil

    -- Win conditions and loss conditions
    self.win  = readArray(data[7], function(s) return wincons[s]  end)
    self.lose = readArray(data[8], function(s) return losscons[s] end)
    self.turnlimits = readArray(data[9], tonumber)
    if next(self.turnlimits) then table.insert(self.lose, {}) end
    self:adjustDifficultyFrom(MASTER)

    -- Battle cam starting location
    self.battle_cam_x = self.game.camera_x
    self.battle_cam_y = self.game.camera_y
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
    self.game:stopMusic()
    self.game.current_music = readField(data[10])

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
        local sp = self.game:getSprite(k)
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
        local x, y = self.game:getMap():tileToPixels(x_tile, y_tile)
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
    local new = self.game.difficulty
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
    return self.game.chapter_id
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

function Battle:stackBubble(c, moves, dir, views)
    local x = 1
    local y = 1
    if c then
        x = c[1]
        y = c[2]
    end
    bubble = {
        ['stage'] = STAGE_BUBBLE,
        ['cursor'] = { x, y, false, { 0, 0, 0, 0 } },
        ['sp_dir'] = dir,
        ['views'] = ite(views, views, {})
    }
    if moves then bubble['moves'] = moves end
    return bubble
end

function Battle:getCursor(n)
    found = 0
    n = ite(n, n, 1)
    for i = 1, #self.stack do
        local c = self.stack[#self.stack - i + 1]['cursor']
        if c then
            found = found + 1
            if found == n then
                return c
            end
        end
    end
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

function Battle:getAttack()
    if self.stack[4] then
        return self.stack[4]['sk']
    end
end

function Battle:getAssist()
    if self.stack[7] then
        return self.stack[7]['sk']
    end
end

function Battle:getSkill()
    for i = 1, #self.stack do
        if self.stack[#self.stack - i + 1]['sk'] then
            return self.stack[#self.stack - i + 1]['sk']
        end
    end
end

function Battle:findSprite(sp)
    local loc = self.status[sp:getId()]['location']
    return loc[2], loc[1]
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
    local old_y, old_x = self:findSprite(sp)
    self.status[sp:getId()]['location'] = { x, y }
    self.grid[old_y][old_x].occupied = nil
    self.grid[y][x].occupied = sp
end

function Battle:isAlly(sp)
    return self.status[sp:getId()]['team'] == ALLY
end

function Battle:getTmpAttributes(sp, with_eff, with_tile)
    local y, x = self:findSprite(sp)
    if with_tile then
        y = with_tile[1]
        x = with_tile[2]
    end
    return mkTmpAttrs(
        sp.attributes,
        ite(with_eff, with_eff, self.status[sp:getId()]['effects']),
        ite(self:isAlly(sp), self.grid[y][x].assists, {})
    )
end

function Battle:getSpriteRenderFlags(sp)

    -- Sprite has acted and needs to be rendered monochrome
    local mono, alpha, skull = false, 1, false
    if self.status[sp:getId()] and self.status[sp:getId()]['acted'] then
        mono = true
    end

    if self:getStage() ~= STAGE_WATCH then

        -- Sprite is moving and original position should be translucent
        if self:getSprite() == sp then alpha = 0.5 end
        
        -- Sprite is being moved by another action and should be translucent
        local dry = self:dryrunAttack()
        if dry then
            for _,d in pairs(dry) do
                if d['sp'] == sp then 
                    if d['moved'] and not d['died'] then
                        alpha = 0.5
                    elseif d['died'] then
                        alpha = 0.5
                        mono = true
                        skull = true
                    end
                end
            end
        end
    end
    return mono, alpha, skull
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
    local triggers = battle_triggers[self:getId()][phase]
    for k, v in pairs(triggers) do
        if not self.seen[k] then
            local scene_id = v(self)
            if scene_id then
                self.seen[k] = true
                self:suspend(self:getId() .. '-' .. scene_id, doneAction)
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
    self.game:launchScene(scene_id, doneAction)
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
            local scene_id = self:getId() .. '-' .. defeat_scene .. '-defeat'
            self:suspend(scene_id, function()
                self.stack = {}
                self.battle_cam_x = self.game.camera_x
                self.battle_cam_y = self.game.camera_y
                self:openDefeatMenu()
            end)
            return true
        end
    end
    for i = 1, #self.win do
        if self.win[i][2](self) then
            self.game:stopMusic()
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
    if self.game.difficulty == ADEPT then
        factor = 0.25
    elseif self.game.difficulty == NORMAL then
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
                self.game:launchScene(self:getId() .. '-victory')
                self.game:startMapMusic()
                self.game.battle = nil
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
    local e = { "   E N E M Y   P H A S E   " .. self.turn .. "   " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(e), true, e, RED), {})
end

function Battle:openBeginTurnMenu()
    self.stack = {}
    local m = { MenuItem:new('Begin turn', {}, 'Begin ally phase', nil,
        function(c)
            self:closeMenu()
            self:turnRefresh()
            self.stack = { self:stackBase() }
            local y, x = self:findSprite(self.player.sp)
            local c = self:getCursor()
            c[1] = x
            c[2] = y
            self:checkTriggers(ALLY)
        end
    )}
    local t = self.turnlimit - self.turn
    local msg = "   A L L Y   P H A S E   " .. self.turn .. "   "
    if t == 0 then msg = "   F I N A L   T U R N   " end
    local e = { msg }
    local clr = ite(t == 0, AUTO_COLOR['Focus'], HIGHLIGHT)
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(e), true, e, clr), {})
end

function Battle:openAttackMenu()
    local sp = self:getSprite()
    local atk_loc = self:getCursor()
    local loc = { atk_loc[2], atk_loc[1] }
    local attrs = self:getTmpAttributes(sp, nil, loc)
    local wait = MenuItem:new('Skip', {},
        'Skip ' .. sp.name .. "'s attack", nil, function(c)
            self:push(self:stackBubble())
            self:selectTarget()
        end
    )
    local skills_menu = sp:mkSkillsMenu(true, false, attrs)
    local weapon = skills_menu.children[1]
    local spell = skills_menu.children[2]
    for i = 1, #weapon.children do self:mkUsable(sp, weapon.children[i]) end
    for i = 1, #spell.children do self:mkUsable(sp, spell.children[i]) end
    local opts = { weapon, spell, wait }
    local moves = self:getMoves()
    self:openMenu(Menu:new(nil, opts, BOX_MARGIN, BOX_MARGIN, false), {
        { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end }
    })
end

function Battle:openAssistMenu()
    local sp = self:getSprite()
    local attrs, hp, ign = self:dryrunAttributes(self:getCursor())
    local wait = MenuItem:new('Skip', {},
        'Skip ' .. sp.name .. "'s assist", nil, function(c)
            self:endAction(false)
        end
    )
    local skills_menu = sp:mkSkillsMenu(true, false, attrs, hp, ign)
    local assist = skills_menu.children[3]
    for i = 1, #assist.children do self:mkUsable(sp, assist.children[i]) end
    local opts = { assist, wait }
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
    local readying = MenuItem:new('Next Attack', {},
        'Prepared skill and target', {
        ['elements'] = self:buildReadyingBox(sp),
        ['w'] = HBOX_WIDTH
    })
    local attrs = self:getTmpAttributes(sp)
    local skills = sp:mkSkillsMenu(false, true, attrs, nil, nil, 380)
    local opts = { skills, readying }
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
            b:renderSkillRange()
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

function Battle:getCursorSuggestion(sp, sk)

    -- Sprite cursor position
    local move_c = self:getCursor()
    local cx = move_c[1]
    local cy = move_c[2]
    local c3 = move_c[3]

    -- Assemble options for initial cursor position. Favor the direction
    -- the sprite is already facing
    local try_dir = self.stack[2]['sp_dir']
    if self.stack[5] then
        try_dir = self.stack[5]['sp_dir']
    end
    local options = {}
    if sk.aim['type'] ~= SELF_CAST then
        if self.grid[cy][cx+try_dir] then options[#options+1] = {cx+try_dir,cy,c3} end
        if self.grid[cy][cx-try_dir] then options[#options+1] = {cx-try_dir,cy,c3} end
        if self.grid[cy + 1] and self.grid[cy + 1][cx] then 
            options[#options+1] = {cx,cy + 1,c3} 
        end
        if self.grid[cy - 1] and self.grid[cy - 1][cx] then 
            options[#options+1] = {cx,cy - 1,c3}
        end
    else
        options = {{cx,cy,c3}}
    end

    -- If there's only one option, we're done
    if #options == 1 then
        return options[1]
    end

    -- If there are multiple options, pick the one that hits the most targets
    local most_hit = 0
    local most_hit_i = 1
    for i = 1, #options do
        local dir = self:getTargetDirection(sk, move_c, options[i])
        local tiles = self:skillRange(sk, dir, options[i])
        local n_hit = 0
        for k = 1, #tiles do
            local t = self.grid[tiles[k][1]][tiles[k][2]].occupied
            if t == sp then
                t = self.grid[move_c[2]][move_c[1]].occupied
            elseif tiles[k][1] == move_c[2] and tiles[k][2] == move_c[1] then
                t = sp
            end
            if t and sk:hits(sp, t, self.status[t:getId()]['team']) then
                n_hit = n_hit + 1
            end
        end
        if n_hit > most_hit then
            most_hit = n_hit
            most_hit_i = i
        end
    end
    return options[most_hit_i]
end

function Battle:mkUsable(sp, sk_menu)
    local sk = skills[sk_menu.id]
    sk_menu.hover_desc = 'Use ' .. sk_menu.name
    local ignea_spent = sk.cost
    local sk2 = self:getSkill()
    if sk2 then ignea_spent = ignea_spent + sk2.cost end
    local obsrv = hasSpecial(self.status[sp:getId()]['effects'], {}, 'observe')
    if sp.ignea < ignea_spent or (sk.id == 'observe' and obsrv) then
        sk_menu.setPen = function(g) return DISABLE end
    else
        sk_menu.setPen = function(g) return WHITE end
        sk_menu.action = function(g)

            -- Pick best based on number of hittable targets range intersects
            best_c = self:getCursorSuggestion(sp, sk)
            local cclr = ite(sk.type == ASSIST, { 0.4, 1, 0.4, 1 },
                                                { 1, 0.4, 0.4, 1 })
            local new_c = { best_c[1], best_c[2], best_c[3], cclr }

            -- Set initial direction of sprite copy based on new cursor
            local move_c = self:getCursor()
            local stk = self.stack[ite(sk.type == ASSIST, 5, 2)]
            local sp_dir = stk['sp_dir']
            if best_c[1] > move_c[1] then
                stk['sp_dir'] = RIGHT
            elseif best_c[1] < move_c[1] then
                stk['sp_dir'] = LEFT
            end
            self:push({
                ['stage'] = STAGE_TARGET,
                ['cursor'] =  new_c,
                ['sp'] = sp,
                ['sk'] = sk,
                ['views'] = {
                    { BEFORE, PERSIST, function(b)
                        b:renderSkillRange(sk, move_c, new_c)
                    end },
                    { BEFORE, TEMP, function(b)
                        b:renderSkillRangeOutline(sk, move_c, new_c)
                    end },
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
        ['sp_dir'] = sp.dir,
        ['cursor'] = new_c,
        ['moves'] = moves,
        ['views'] = {
            { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end },
            { AFTER, PERSIST, function(b)
                if b.stack[5] then
                    local y, x = b:findSprite(sp)
                    local dir = b.stack[2]['sp_dir']
                    b:renderSpriteImage(new_c[1], new_c[2], sp, dir, 0.5)
                end
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
    local attrs, _, _ = self:dryrunAttributes({ j, i }, sp)
    local spent = self:getSpent(i, j)
    return math.max(0, math.floor(attrs['agility'] / 4) - spent)
end

function Battle:validMoves(sp, i, j)

    -- Get sprite's base movement points
    local move = self:getMovement(sp, i, j)

    -- Spoof a shallow copy of the grid dryrun-move tiles occupied
    local grid = self:dryrunGrid(false)

    -- Run djikstra's algorithm on grid
    local dist, _ = sp:djikstra(grid, { i, j }, nil, move)

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
        self:push(self:stackBubble(c, moves, self.stack[2]['sp_dir']))
        if self.n_allies > 1 then
            self:openAssistMenu(sp)
        else
            self:endAction(false)
        end
    else
        local nc = { c[1], c[2], c[3], { 0.6, 0.4, 0.8, 1 } }
        self:push({
            ['stage'] = STAGE_MOVE,
            ['sp'] = sp,
            ['sp_dir'] = self.stack[2]['sp_dir'],
            ['cursor'] = nc,
            ['moves'] = moves,
            ['views'] = {
                { BEFORE, TEMP, function(b)
                    b:renderMovement(moves, 1)
                end }
            }
        })
    end
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

function Battle:getTargetDirection(sk, sp_c, sk_c)

    -- Get skill and cursor info
    local c  = ite(sk_c, sk_c, self:getCursor())
    local sk = ite(sk, sk, self:getSkill())

    -- Get direction to point the skill
    local dir = UP
    if sk.aim['type'] == DIRECTIONAL then
        local o = ite(sp_c, sp_c, self:getCursor(2))
        dir = ite(c[1] > o[1], RIGHT,
                  ite(c[1] < o[1], LEFT,
                      ite(c[2] > o[2], DOWN, UP)))
    end
    return dir
end

function Battle:gridCopy()
    local g = {}
    for h = 1, self.grid_h do
        g[h] = {}
        for k = 1, self.grid_w do
            if self.grid[h][k] then
                g[h][k] = GridSpace:new()
                g[h][k].occupied  = self.grid[h][k].occupied
                g[h][k].assists   = self.grid[h][k].assists
                g[h][k].n_assists = self.grid[h][k].n_assists
            else
                g[h][k] = F
            end
        end
    end
    return g
end

function Battle:dryrunGrid(keep_sprite)

    local grid = self:gridCopy()
    local dry = self:dryrunAttack()

    -- Move 'moved' sprites to new locations on grid copy
    -- Delete dead sprites
    if dry then
        for _,d in pairs(dry) do
            local sp = d['sp']
            local i, j = self:findSprite(sp)
            if d['moved'] then
                grid[i][j].occupied = nil
                if not d['died'] then
                    grid[d['moved']['y']][d['moved']['x']].occupied = sp
                end
            elseif d['died'] then
                grid[i][j].occupied = nil
            end
        end
    end

    local n = ite(self.stack[5] and keep_sprite, 5, ite(self.stack[2], 2, nil))
    if n and self:getSprite() then

        -- Move current sprite to where they attacked from
        local sp = self:getSprite()
        local i, j = self:findSprite(sp)
        local c = self.stack[n]['cursor']
        local lb = self.stack[n]['leave_behind']
        if lb then c = lb end
        grid[i][j].occupied = grid[c[2]][c[1]].occupied
        grid[c[2]][c[1]].occupied = sp
    end

    return grid
end

function Battle:dryrunAttributes(standing, other)

    local sp = ite(other, other, self:getSprite())
    local atk = self:getAttack()
    local eff = self.status[sp:getId()]['effects']
    local hp = sp.health
    local ign = sp.ignea
    if atk then
        ign = ign - atk.cost
        local dry = self:dryrunAttack()
        if dry['caster'] then
            eff = dry['caster']['new_stat']
        else
            for i=1, #dry do
                if dry[i]['sp'] == sp then
                    eff = dry[i]['new_stat']
                    hp = sp.health - dry[i]['flat']
                    break
                end
            end
        end
    end
    local loc = { standing[2], standing[1] }
    local attrs = self:getTmpAttributes(sp, eff, loc)
    return attrs, hp, ign
end

function Battle:dryrunAttack()
    local atk = self:getAttack()
    if atk then
        local sp_c = self.stack[2]['cursor']
        local atk_c = self.stack[4]['cursor']
        local sp = self:getSprite()
        local dir = self:getTargetDirection(atk, sp_c, atk_c)
        return self:useAttack(sp, atk, dir, atk_c, true, sp_c)
    end
end

function Battle:useAttack(sp, atk, dir, atk_c, dryrun, sp_c)
    local i, j = self:findSprite(sp)
    local ass = self.grid[i][j].assists
    local grid = self:gridCopy()
    if sp_c then
        ass = self.grid[sp_c[2]][sp_c[1]].assists
        grid[i][j].occupied = grid[sp_c[2]][sp_c[1]].occupied
        grid[sp_c[2]][sp_c[1]].occupied = sp
    end
    local sp_a = ite(self:isAlly(sp), ass, {})
    local t = self:skillRange(atk, dir, atk_c)
    local ts = {}
    local ts_a = {}
    for k = 1, #t do
        local space = grid[t[k][1]][t[k][2]]
        local target = space.occupied
        if target then
            table.insert(ts, target)
            table.insert(ts_a, ite(self:isAlly(target), space.assists, {}))
        end
    end
    return atk:use(sp, sp_a, ts, ts_a, dir, self.status, grid, dryrun)
end

function Battle:kill(sp)
    local i, j = self:findSprite(sp)
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

function Battle:computeDir(c1, c2)
    if     c1[1] - c2[1] ==  1 then return RIGHT
    elseif c1[1] - c2[1] == -1 then return LEFT
    elseif c1[2] - c2[2] ==  1 then return DOWN
    else                            return UP
    end
end

function Battle:playAction()

    -- Skills used
    local sp     = self:getSprite()
    local attack = self:getAttack()
    local assist = self:getAssist()

    -- Cursor locations
    local c_sp     = self.stack[1]['cursor']
    local c_move1  = self.stack[2]['cursor']
    local c_attack = self.stack[4]['cursor']
    local c_move2  = self.stack[5]['cursor']
    local c_assist = nil
    if self.stack[7] then
        c_assist = self.stack[7]['cursor']
    end

    -- Derive directions from cursor locations
    local attack_dir = UP
    if attack and attack.aim['type'] == DIRECTIONAL then
        attack_dir = self:computeDir(c_attack, c_move1)
    end
    local assist_dir = UP
    if assist and assist.aim['type'] == DIRECTIONAL then
        assist_dir = self:computeDir(c_assist, c_move2)
    end

    -- Shorthand
    local ox = self.origin_x
    local oy = self.origin_y
    local sp_y, sp_x = self:findSprite(sp)

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
            local moved, hurt, dead, lvlups = self:useAttack(sp,
                attack, attack_dir, c_attack
            )
            sp.ignea = sp.ignea - attack.cost
            for k, v in pairs(lvlups) do
                if lvlups[k] > 0 then self.levelup_queue[k] = v end
            end
            local dont_hurt = { [sp:getId()] = true }
            for i = 1, #moved do
                any_displaced = true
                local t = moved[i]['sp']
                if not find(dead, t) then
                    t:behaviorSequence({ function(d)
                        local to_x = self.origin_x + moved[i]['x']
                        local to_y = self.origin_y + moved[i]['y']
                        return t:walkToBehaviorGeneric(function()
                            t:changeBehavior('battle')
                            if abs(t.x - sp.x) > TILE_WIDTH / 2 then
                                t.dir = ite(t.x > sp.x, LEFT, RIGHT)
                            end
                            self:moveSprite(t, moved[i]['x'], moved[i]['y'])
                        end, to_x, to_y, true, 'displace')
                    end }, pass)
                    dont_hurt[t:getId()] = true
                end
            end
            for i = 1, #hurt do
                local t = hurt[i]
                if dont_hurt[t:getId()] == nil then
                    t:behaviorSequence({ function(d)
                        t:fireAnimation('hurt', function()
                            t:changeBehavior('battle')
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
                            self.game:getMap():dropSprite(did)
                        end
                    end)
                    return pass
                end }, pass)
                self:kill(dead[i])
            end
            d()
        end, attack, attack_dir, c_attack[1] + ox, c_attack[2] + oy)
    end)

    -- If a sprite moved or died, wait a moment before continuing
    local dry = self:dryrunAttack()
    if dry then
        for i = 1, #dry do
            if dry[i]['moved'] or dry[i]['died'] then
                table.insert(seq, function(d)
                    return sp:waitBehaviorGeneric(d, 'combat', 0.8)
                end)
                break
            end
        end
    end

    -- Move 2 (with spoofed grid)
    local grid = self:dryrunGrid(false)
    local move2_path = sp:djikstra(grid,
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
            m:forward(self.game)
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

        if d then
            self:pop()
        else
            -- Move a sprite to a new location
            local old_c = self:getCursor()
            local cx, cy = old_c[1], old_c[2]
            local x, y = self:newCursorPosition(up, down, left, right)
            local moves = self:getMoves()
            self:moveCursor(x, y)

            -- Is the move out of bounds?
            local oob = true
            for i = 1, #moves do
                if moves[i]['to'][1] == y and moves[i]['to'][2] == x then
                    oob = false
                    break
                end
            end
            local sp = self:getSprite()
            local c = self:getCursor(2)
            local stack_n = 2
            if self:getCursor(3) then
                c = self:getCursor(3)
                stack_n = 5
            end
            if not oob then
                self.stack[stack_n]['leave_behind'] = nil

                -- Adjust direction
                if x > c[1] then
                    self.stack[stack_n]['sp_dir'] = RIGHT
                    if stack_n == 2 then sp.dir = RIGHT end
                elseif x < c[1] then
                    self.stack[stack_n]['sp_dir'] = LEFT
                    if stack_n == 2 then sp.dir = LEFT end
                else
                    if stack_n == 5 then
                        self.stack[stack_n]['sp_dir'] = self.stack[2]['sp_dir']
                    end
                end

                -- Make sure tile is unoccupied before continuing
                local grid = self:dryrunGrid(false)
                local space = grid[y][x].occupied
                if f and not (space and space ~= self:getSprite()) then
                    if not self:getCursor(3) then
                        self:openAttackMenu()
                    elseif self.n_allies > 1 then
                        self:openAssistMenu()
                    else
                        self:endAction(false)
                    end
                end
            else

                -- Setup where the sprite is left behind
                if not self.stack[stack_n]['leave_behind'] then
                    self.stack[stack_n]['leave_behind'] = { cx, cy }
                end
            end
        end

    elseif s == STAGE_TARGET then

        local sp = self:getSprite()
        local sk = self:getSkill()
        if d then
            local stack_n = 2
            if sk.type == ASSIST then stack_n = 5 end
            local stk = self.stack[stack_n]
            if stack_n == 2 then
                stk['sp_dir'] = sp.dir
            else
                if stk['cursor'][1] < self.stack[2]['cursor'][1] then
                    stk['sp_dir'] = LEFT
                elseif stk['cursor'][1] > self.stack[2]['cursor'][1] then
                    stk['sp_dir'] = RIGHT
                else
                    stk['sp_dir'] = self.stack[2]['sp_dir']
                end
            end
            self:pop()
        else
            local c = self:getCursor(2)
            local x_move, y_move = self:newCursorMove(up, down, left, right)
            local nx, ny = nil, nil
            if sk.aim['type'] == DIRECTIONAL then
                if x_move == 1 then
                    nx, ny = c[1] + 1, c[2]
                elseif x_move == -1 then
                    nx, ny = c[1] - 1, c[2]
                elseif y_move == 1 then
                    nx, ny = c[1], c[2] + 1
                elseif y_move == -1 then
                    nx, ny = c[1], c[2] - 1
                end
            elseif sk.aim['type'] == FREE then
                local scale = sk.aim['scale']
                local c_cur = self:getCursor()
                if abs(c_cur[1] + x_move - c[1]) +
                   abs(c_cur[2] + y_move - c[2]) <= scale then
                    nx, ny = c_cur[1] + x_move, c_cur[2] + y_move
                end
            end
            if nx then
                self:moveCursor(nx, ny)
                local stack_n = 2
                if sk.type == ASSIST then stack_n = 5 end
                local stk = self.stack[stack_n]
                if nx > c[1] then
                    stk['sp_dir'] =  RIGHT
                elseif nx < c[1] then
                    stk['sp_dir'] =  LEFT
                else
                    if stack_n == 2 then
                        stk['sp_dir'] = sp.dir
                    else
                        if stk['cursor'][1] < self.stack[2]['cursor'][1] then
                            stk['sp_dir'] = LEFT
                        elseif stk['cursor'][1] > self.stack[2]['cursor'][1] then
                            stk['sp_dir'] = RIGHT
                        else
                            stk['sp_dir'] = self.stack[2]['sp_dir']
                        end
                    end
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
                self.stall_battle_cam = true
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
            if ally_phase_over and self.game.turn_autoend then
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
    if self.stall_battle_cam then
        self.stall_battle_cam = false
        return
    end
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
    local y,  x  = self:findSprite(sp)
    local ey, ex = self:findSprite(e)
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
    local y, x = self:findSprite(e)
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
        local y, x = self:findSprite(e)
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
            local x, y = self.game:getMap():tileToPixels(x_tile, y_tile)
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
    local map = self.game.current_map
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

function Battle:renderSpriteImage(x, y, sp, dir, a)
    love.graphics.push('all')
    if self.status[sp:getId()]['acted'] then
        love.graphics.setColor(0.3, 0.3, 0.3, a)
    else
        love.graphics.setColor(1, 1, 1, a)
    end
    love.graphics.draw(
        spritesheet,
        sp:getCurrentQuad(),
        TILE_WIDTH * (x + self.origin_x - 1) + sp.w / 2,
        TILE_HEIGHT * (y + self.origin_y - 1) + sp.h / 2,
        0,
        dir,
        1,
        sp.w / 2,
        sp.h / 2
    )
    love.graphics.pop()
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

function Battle:renderSkillRangeOutline(sk, sp_c, sk_c)

    -- For bounded free aim skills, render the boundary
    local clr = ite(sk.type == ASSIST, { 0, 1, 0 }, { 1, 0, 0 })
    if sk.aim['type'] == FREE and sk.aim['scale'] < 100 then
        local t = sp_c
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

function Battle:renderSkillRange(sk, sp_c, sk_c)

    -- What skill?
    if not sk then
        sp_c = self:getCursor(2)
        sk_c = self:getCursor()
        sk = self:getSkill()
    end
    local clr = ite(sk.type == ASSIST, { 0, 1, 0 }, { 1, 0, 0 })

    -- Get direction to point the skill
    local dir = self:getTargetDirection(sk, sp_c, sk_c)

    -- Render squares given by the skill range
    local tiles = self:skillRange(sk, dir, sk_c)
    for i = 1, #tiles do
        self:shadeSquare(tiles[i][1], tiles[i][2], clr, 1)
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
        local i, j = self:findSprite(sp)
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

function Battle:renderHealthbar(sp, x, y, ratio)
    
    y = y + sp.h + ite(self.pulse, 0, -1) - 1
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x + 3, y, sp.w - 6, 3)
    love.graphics.setColor(0.4, 0, 0.2, 1)
    love.graphics.rectangle('fill', x + 3, y, (sp.w - 6) * ratio, 3)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('line', x + 3, y, sp.w - 6, 3)
end

function Battle:renderStatus(x, y, statuses)

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

function Battle:renderSpriteOverlays()

    local dry = self:dryrunAttack()
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if self.game:getMap():getSprite(sp:getId()) then

            -- Defaults
            local x, y = sp:getPositionOnScreen()
            local ratio = sp.health / (sp.attributes['endurance'] * 2)
            local statuses = self.status[sp:getId()]['effects']

            -- If we aren't watching an action play out!
            if self:getStage() and self:getStage() ~= STAGE_WATCH then

                -- Get post-dryrun health and status effects
                if dry then
                    for _,v in pairs(dry) do
                        if v['sp'] == sp then
                            statuses = v['new_stat']
                            local hp = sp.health - v['flat']
                            ratio = hp / (sp.attributes['endurance'] * 2)
                            break
                        end
                    end
                end

                -- Figure out where this sprite is after dryrun
                local t_y, t_x = self:findSprite(sp)
                if sp == self:getSprite() then
                    local n = ite(self.stack[5], 5, ite(self.stack[2], 2, nil))
                    if n then
                        local c = self.stack[n]['cursor']
                        local lb = self.stack[n]['leave_behind']
                        if lb then c = lb end
                        t_y, t_x = c[2], c[1]
                    end
                elseif dry then
                    for _,v in pairs(dry) do
                        if v['sp'] == sp and v['moved'] and not v['died'] then
                            t_y, t_x = v['moved']['y'], v['moved']['x']
                            break
                        elseif v['died'] then
                            return
                        end
                    end
                end
                
                -- Convert tile coords to x and y on screen
                local px, py = self.game.current_map:tileToPixels(
                    self.origin_x + t_x, self.origin_y + t_y
                )
                x = px - self.game.camera_x
                y = py - self.game.camera_y
            end
            
            -- Render everything
            self:renderHealthbar(sp, x, y, ratio)
            self:renderStatus(x, y, statuses)
        end
    end
end

function Battle:renderDisplacement()

    -- If an attack exists, do dryrun
    local dry = self:dryrunAttack()
    if dry then

        -- Render arrow and shadow target for each target
        for i=1, #dry do
            local t = dry[i]['sp']
            if dry[i]['moved'] and not dry[i]['died'] then

                -- Get position and rotation of arrow
                local dir = dry[i]['moved']['dir']
                local to_x = dry[i]['moved']['x']
                local to_y = dry[i]['moved']['y']
                local from_y, from_x = self:findSprite(t)
                local arrow_x = (self.origin_x + (from_x + to_x - 1) / 2) * TILE_WIDTH
                local arrow_y = (self.origin_y + (from_y + to_y - 1) / 2) * TILE_HEIGHT
                
                -- Offset depends on direction
                local off = TILE_WIDTH / 4
                local rot = 0
                local x_off, y_off = -off, -off
                if     dir == DOWN then rot, x_off, y_off =     math.pi / 2,  off, -off
                elseif dir == LEFT then rot, x_off, y_off =     math.pi,      off,  off
                elseif dir == UP   then rot, x_off, y_off = 3 * math.pi / 2, -off,  off
                end
                
                -- Render arrow
                love.graphics.push('all')
                if self.pulse then
                    love.graphics.setColor(AUTO_COLOR['Focus'])
                    if dir == RIGHT or dir == LEFT then arrow_x = arrow_x - 1 end
                    if dir == UP    or dir == DOWN then arrow_y = arrow_y - 1 end
                else
                    love.graphics.setColor(RED)
                end
                love.graphics.print(">>>", arrow_x + x_off, arrow_y + y_off, rot)
                love.graphics.pop()

                -- Render sprite image at the new location
                self:renderSpriteImage(to_x, to_y, t, t.dir, 1)
            end
        end
    end
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
    renderString(msg1, computeX(msg1), base_y, DISABLE)
    renderString(msg2, computeX(msg2), base_y + LINE_HEIGHT, HIGHLIGHT)
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

function Battle:mkAssistElements(assists, w)
    local eles = { mkEle('text', 'Assist', HALF_MARGIN, HALF_MARGIN) }
    for i = 1, #assists do
        local str = assists[i]:toStr()
        if str then
            table.insert(eles, mkEle('text', str,
                w - #str * CHAR_WIDTH - HALF_MARGIN,
                HALF_MARGIN + LINE_HEIGHT * i
            ))
        end
    end
    local h = LINE_HEIGHT * (#eles) + BOX_MARGIN
    return eles, h
end

function Battle:boxElementsFromInfo(sp, hp, ign, statuses)
    local w = BOX_MARGIN + CHAR_WIDTH * MAX_WORD

    -- Box contains sprite's name and status
    local name_str = sp.name
    local hp_str   = hp  .. "/" .. (sp.attributes['endurance'] * 2)
    local ign_str  = ign .. "/" ..  sp.attributes['focus']

    -- Compute box width from longest status
    local longest_status = 0
    for i = 1, #statuses do

        -- Space (in characters) between two strings in hover box
        local buf = 3

        -- Length of duration string
        local d = statuses[i].duration
        local dlen = ite(d == math.huge, 0, ite(d < 10, 2, 3))

        -- Length of buff string
        local b = statuses[i].buff
        local blen = ite(b:toStr(), #b:toStr(), 0)

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
        local dur = ite(d ~= math.huge, d .. 't', '')
        table.insert(stat_eles, mkEle('text', dur,
            w - #dur * CHAR_WIDTH - HALF_MARGIN, cy
        ))
        local str = b:toStr()
        if str then
            table.insert(stat_eles, mkEle('text', str, HALF_MARGIN, cy))
        end
    end

    -- Concat info with statuses
    local h = BOX_MARGIN + HALF_MARGIN + LINE_HEIGHT
            * (#sp_eles - 2 + #stat_eles / 2)
    if next(statuses) ~= nil then h = h + HALF_MARGIN end
    local clr = ite(self:isAlly(sp), { 0, 0.1, 0.1 }, { 0.1, 0, 0 })
    return concat(sp_eles, stat_eles), w, h, clr
end

function Battle:boxElementsFromDryrun(sp, sk, result)
    local hp = sp.health - result['flat']
    local ign = ite(sp == self:getSprite(), sp.ignea - sk.cost, sp.ignea)
    return self:boxElementsFromInfo(sp, hp, ign, result['new_stat'])
end

function Battle:boxElementsFromSprite(sp)
    local stat = self.status[sp:getId()]['effects']
    return self:boxElementsFromInfo(sp, sp.health, sp.ignea, stat)
end

function Battle:renderAttackHoverBoxes(sk)

    -- Function to render before/after dryrun boxes with an arrow between
    local max_y = VIRTUAL_HEIGHT - BOX_MARGIN * 2 - FONT_SIZE - LINE_HEIGHT
    local cur_y = BOX_MARGIN
    function renderBoxIfRoom(t, result)
        
        local box, w, h, clr = self:boxElementsFromSprite(t)
        local box2, w2, h2, _ = self:boxElementsFromDryrun(t, sk, result)

        -- Only render if there's room for the whole box on screen
        if cur_y + math.max(h, h2) <= max_y then

            -- Result box goes to the right
            local cur_x = VIRTUAL_WIDTH - BOX_MARGIN - w2
            self:renderHoverBox(box2, cur_x, cur_y, w2, h2, clr)

            -- Arrow connecting them
            cur_x = cur_x - BOX_MARGIN - 10
            love.graphics.setColor(unpack(WHITE))
            love.graphics.print(">>", cur_x, cur_y + (h + h2) / 4 - TEXT_MARGIN_Y / 2)

            -- Initial box left of it
            cur_x = cur_x - BOX_MARGIN - w
            self:renderHoverBox(box, cur_x, cur_y, w, h, clr)
            cur_y = cur_y + math.max(h, h2) + BOX_MARGIN

        else
            -- Render '...' if out of room
            local cur_x = VIRTUAL_WIDTH - BOX_MARGIN - CHAR_WIDTH * 3
            renderString("...", cur_x, cur_y)
            return true
        end
        return false
    end

    -- Dryrun and render all boxes
    local dry = self:dryrunAttack()
    local room = true
    for i = 1, #dry do
        if renderBoxIfRoom(dry[i]['sp'], dry[i]) then
            room = false
            break
        end
    end
    if room and dry['caster'] then
        renderBoxIfRoom(self:getSprite(), dry['caster'])
    end
end

function Battle:renderAssistHoverBox(sk)

    -- Get the sprites new attributes and assist effect after
    -- attacking and moving
    local attrs, _, _ = self:dryrunAttributes(self:getCursor(2))
    local buffs = sk:use(attrs)
    
    -- Get box elements and render box
    local w = BOX_MARGIN + CHAR_WIDTH * MAX_WORD
    local x = VIRTUAL_WIDTH - w - BOX_MARGIN
    local eles, h = self:mkAssistElements(buffs, w)
    self:renderHoverBox(eles, x, BOX_MARGIN, w, h, { 0.05, 0.15, 0.05 })
end

function Battle:renderTargetHoverBoxes()
    local sk = self:getSkill()
    if sk.type == ASSIST then self:renderAssistHoverBox(sk)
    else                      self:renderAttackHoverBoxes(sk)
    end
end

-- Render a box of the specified dimensions and color, and the elements inside
function Battle:renderHoverBox(box, x, y, w, h, clr)

    -- Render box rectangle
    table.insert(clr, RECT_ALPHA)
    love.graphics.setColor(unpack(clr))
    love.graphics.rectangle('fill', x, y, w, h)

    -- Render box elements
    for i = 1, #box do
        local e = box[i]
        if e['type'] == 'text' then
            local clr = ite(e['color'], e['color'], WHITE)
            renderString(e['data'], x + e['x'], y + e['y'], clr, e['auto_color'])
        else
            love.graphics.setColor(unpack(WHITE))
            love.graphics.draw(
                e['texture'],
                e['data'],
                x + e['x'],
                y + e['y'],
                0, 1, 1, 0, 0
            )
        end
    end
end

-- Render both inner (sprite/status) and outer (assists) hover boxes
function Battle:renderHoverBoxes()

    -- Sprite at cursor
    local c = self:getCursor()
    local grid = self:dryrunGrid(true)

    local g = grid[c[2]][c[1]]
    local sp = g.occupied

    local res, atk = nil
    local dry = self:dryrunAttack()
    if dry then
        atk = self:getAttack()
        for _,v in pairs(dry) do
            if sp and v['sp'] == sp then res = v end
        end
        if sp and not res then
            res = { ['flat'] = 0, ['new_stat'] = self.status[sp:getId()]['effects'] }
        end
    end

    -- Get box elements for sprite and statuses, or 'empty' if no sprite
    function mkInnerHoverBox()
        if sp then
            if res then
                return self:boxElementsFromDryrun(sp, atk, res)
            else
                return self:boxElementsFromSprite(sp)
            end
        end
        local w = BOX_MARGIN + CHAR_WIDTH * MAX_WORD
        local h = BOX_MARGIN + LINE_HEIGHT
        local clr = { 0, 0, 0 }
        return { mkEle('text', 'Empty', HALF_MARGIN, HALF_MARGIN) }, w, h, clr
    end
    
    -- Get box elements for assists, only for ally sprite or empty space
    function mkOuterHoverBox(w)
        if ((not sp) or self:isAlly(sp)) and g.n_assists > 0 then
            return self:mkAssistElements(g.assists, w)
        end
        return {}, 0
    end

    -- Draw inner box
    local ibox, w, ih, clr = mkInnerHoverBox()
    local x = VIRTUAL_WIDTH - BOX_MARGIN - w
    self:renderHoverBox(ibox, x, BOX_MARGIN, w, ih, clr)
    
    -- If there are assists, draw outer box
    local obox, oh = mkOuterHoverBox(w)
    if next(obox) ~= nil then
        self:renderHoverBox(obox, x, BOX_MARGIN + ih, w, oh, { 0.05, 0.15, 0.05 })
    end
end

function Battle:renderActingSpriteImage()
    local sp = self:getSprite()
    local st = self:getStage()
    if self.stack[2] and sp and st ~= STAGE_WATCH then
        local n = ite(self.stack[5], 5, 2)
        local c = self.stack[n]['cursor']
        local lb = self.stack[n]['leave_behind']
        if lb then c = lb end
        local dir = self.stack[n]['sp_dir']
        self:renderSpriteImage(c[1], c[2], sp, dir, 1)
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

        -- Render arrow on grid associated with displacement skills dryrun
        self:renderDisplacement()

        -- Render active views above the cursor, in stack order
        self:renderViews(AFTER)
    end
end

function Battle:renderOverlay()

    -- Render healthbars below each sprite, and status markers above
    love.graphics.push()
    love.graphics.origin()
    self:renderSpriteOverlays()
    love.graphics.pop()

    -- No overlay if stack has no cursors
    local s = self:getStage()
    if self:getCursor() then

        -- Dont render any other overlays while watching an action
        if s ~= STAGE_WATCH and s ~= STAGE_LEVELUP then

            -- Make and render hover boxes
            if s == STAGE_TARGET then
                self:renderTargetHoverBoxes()
            elseif not (s == STAGE_MENU and self:getCursor(4)) then
                self:renderHoverBoxes()
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
        m:render(self.game)
        if self.render_bexp then self:renderBexp() end
    end

    -- Render what turn it is in the lower right
    if s and s ~= STAGE_WATCH and s ~= STAGE_LEVELUP then
        local turn_str = 'Turn ' .. self.turn .. '/' .. self.turnlimit
        renderString(turn_str,
            VIRTUAL_WIDTH - BOX_MARGIN - #turn_str * CHAR_WIDTH,
            VIRTUAL_HEIGHT - BOX_MARGIN - FONT_SIZE - LINE_HEIGHT,
            ite(self.turnlimit - self.turn == 0, AUTO_COLOR['Focus'], WHITE)
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