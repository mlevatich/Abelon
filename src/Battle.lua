require 'src.Util'
require 'src.Constants'

require 'src.Menu'
require 'src.Music'
require 'src.Sounds'
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

function Battle:initialize(player, game, id)

    self.game = game
    self.id = game.chapter_id
    if id then self.id = self.id .. "-" .. id end

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
    local grid_index = 15
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
    self.escaped = {}
    self.n_allies = 0
    local player_at = nil
    for i = 1, #self.participants do
        local p = self.participants[i]
        if self:isAlly(p) then
            self.n_allies = self.n_allies + 1
        end
        if p == self.player.sp then
            player_at = i
        end
    end
    if player_at then
        table.remove(self.participants, player_at)
        table.insert(self.participants, 1, self.player.sp)
    end
    
    self.enemy_action = nil

    -- Win conditions and loss conditions
    self.win_names = readArray(data[7])
    self.loss_names = readArray(data[8])
    self.win = mapf(function(s) return wincons[s] end, self.win_names)
    self.lose = mapf(function(s) return losscons[s] end, self.loss_names)
    self.turnlimits = readArray(data[9], tonumber)
    self.scene_tiles = readDict(data[10], ARR, nil, tonumber)
    self:adjustDifficulty()

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
    self.render_exp = {}
    self.levelup_queue = {}

    -- Music
    self.game:stopMusic()
    self.game.current_music = readField(data[11])

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
        local team = ite(idx == 4, ALLY, ENEMY)

        -- Ignore listed allies not in the player's party
        if team == ENEMY or find(self.player.party, sp) then
            table.insert(t, sp)
            self.grid[v[2]][v[1]] = GridSpace:new(sp)

            -- Initialize sprite status
            self.status[sp:getId()] = {
                ['sp']       = sp,
                ['team']     = team,
                ['location'] = { v[1], v[2] },
                ['effects']  = {},
                ['alive']    = true,
                ['acted']    = false,
                ['inbattle'] = true,
                ['attack']   = nil,
                ['assist']   = nil,
                ['prepare']  = nil
            }
            local x_tile = self.origin_x + v[1]
            local y_tile = self.origin_y + v[2]
            local sp_size_x_offset = (-1 * (sp.w - TILE_WIDTH) / 2 - 0.5) / TILE_WIDTH
            local sp_size_y_offset = (-1 * (sp.h - TILE_HEIGHT) - 1) / TILE_HEIGHT
            local x, y = tileToPixels(x_tile + sp_size_x_offset, y_tile + sp_size_y_offset)
            self.game:warpSprite(sp, x, y, self.game:getMap():getName())

            -- If an enemy, prepare their first skill
            if self.status[sp:getId()]['team'] == ENEMY then
                if v[3] then
                    self:prepareSkill(sp, tonumber(v[3]))
                end
            end
        end
    end
    return t
end

function Battle:addTiles(tiles)
    for i=1, #tiles do
        local t_x = tiles[i][1]
        local t_y = tiles[i][2]
        if not self.grid[t_y][t_x] then
            self.grid[t_y][t_x] = GridSpace:new()
        end
    end
end

function Battle:joinBattle(sp, team, t_x, t_y, prep_id)

    -- Add sprite to grid
    self:addTiles({{t_x, t_y}})
    self.grid[t_y][t_x].occupied = sp

    -- Add status for sprite
    self.status[sp:getId()] = {
        ['sp']       = sp,
        ['team']     = team,
        ['location'] = { t_x, t_y },
        ['effects']  = {},
        ['alive']    = true,
        ['acted']    = false,
        ['attack']   = nil,
        ['assist']   = nil,
        ['prepare']  = nil
    }

    -- Add to participants, update n_allies
    table.insert(self.participants, sp)
    if team == ALLY then 
        self.n_allies = self.n_allies + 1
    else
        table.insert(self.enemy_order, sp:getId())
        self:prepareSkill(sp, tonumber(prep_id))
    end

    -- Change behavior to battle
    sp:changeBehavior('battle')
end

function Battle:adjustDifficulty()

    -- Adjust enemy stats
    local new = self.game.difficulty
    for i = 1, #self.participants do
        local sp = self.participants[i]
        if not self:isAlly(sp) then
            sp.attributes = sp.attrs_on[new]
            sp.health = math.min(sp.health, sp.attributes['endurance'] * 2)
            sp.ignea = math.min(sp.ignea, sp.attributes['focus'])
        end
    end

    -- Adjust turn limit, if there is one
    if next(self.turnlimits) then
        self.turnlimit = self.turnlimits[new + 1]
        turnlimitReached = function(b) return ite(b.turn > b.turnlimit, 'turnlimit', false) end
        if find(self.win_names, 'turns') then
            self.win[#self.win] = { 'Survive for ' .. self.turnlimit .. ' turns', turnlimitReached }
        elseif find(self.loss_names, 'turns') then
            self.lose[#self.lose] = { self.turnlimit .. ' turns pass', turnlimitReached }
        end

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
            for i = 1, new do m:hover(DOWN) end
        end
    end
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
        local change = (c[1] ~= x) or (c[2] ~= y)
        c[1] = x
        c[2] = y
        return change
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
    local bs, hs, ss = mkTmpAttrs(
        sp.attributes,
        ite(with_eff, with_eff, self.status[sp:getId()]['effects']),
        ite(self:isAlly(sp), self.grid[y][x].assists, {})
    )
    return bs, hs, ss
end

function Battle:getSpriteRenderFlags(sp)

    -- Use defaults if the sprite isn't in the battle
    local mono, alpha, skull = false, 1, false
    if self.status[sp:getId()] then

        -- Sprite has acted and needs to be rendered monochrome
        if self.status[sp:getId()]['acted'] then
            mono = true
        end

        if self:getStage() ~= STAGE_WATCH and self:getStage() ~= STAGE_LEVELUP then

            -- Sprite is moving and original position should be translucent
            if self:getSprite() == sp then
                alpha = 0.5
    
                local ns = ite(self.stack[5], {5,2}, ite(self.stack[2], {2}, {}))
                for _,n in pairs(ns) do
                    local active_c = self.stack[n]['cursor']
                    local lb = self.stack[n]['leave_behind']
                    if lb then active_c = lb end
                    if  self.stack[1]['cursor'][1] == active_c[1]
                    and self.stack[1]['cursor'][2] == active_c[2] then
                        alpha = 0
                    end
                end
            end
            
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

function Battle:checkSceneTiles()
    local sp = self:getSprite()
    local end_y, end_x = self:findSprite(sp)
    for k, v in pairs(self.scene_tiles) do
        if end_x == v[1] and end_y == v[2] and self.status[sp:getId()]['inbattle'] and self:isAlly(sp) then
            local scene_id = k:gsub('%d','')
            if scene_id == 'escape' then
                scene_id = sp:getId() .. '-escape'
                self:escape(sp)
            else
                scene_id = scene_id .. '-' .. sp:getId()
                self.scene_tiles[k] = nil
            end
            self:suspend(self.id .. '-' .. scene_id)
            return true
        end
    end
    return false
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

    -- Nobody has acted, unless an ally is stunned
    for i = 1, #self.participants do
        self.status[self.participants[i]:getId()]['acted'] = false
    end
    for i = 1, #self.participants do
        local stat = self.status[self.participants[i]:getId()]
        if self:isAlly(self.participants[i]) then
            for j = 1, #stat['effects'] do
                local attr = stat['effects'][j].buff.attr
                if attr == 'stun' or attr == 'unconscious' or attr == 'busy' or attr == 'injured' then
                    stat['acted'] = true
                end
            end
        end
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
            self.game:stopMusic()
            self.game.current_music = 'Defeat'
            self.game:modMusicVolume(1, 10000)
            local scene_id = self.id .. '-' .. defeat_scene .. '-defeat'
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

-- After battle is over
function Battle:cleanupBattle()

    -- Restore ignea, health, and stats to all participants
    -- Ignea is restored by 0% on master, 25% on adept, 50% on normal/novice
    local ign_mul = 0.75 - (math.max(NORMAL, self.game.difficulty) * 0.25)
    local affected = {}
    for i = 1, #self.participants do table.insert(affected, self.participants[i]) end
    for i = 1, #self.escaped do table.insert(affected, self.escaped[i]) end
    for i = 1, #affected do
        local sp = affected[i]
        if self:isAlly(sp) then
            local max_ign = sp.attributes['focus']
            sp.ignea = math.min(sp.ignea + math.floor(max_ign * ign_mul), max_ign)
        else
            sp.attributes = sp.attrs_on[MASTER]
            sp.ignea = sp.attributes['focus']
            sp:changeBehavior('idle')
        end
        sp.health = sp.attributes['endurance'] * 2
    end
end

function Battle:awardBonusExp()
    local bexp = 10
    if self.turnlimit and not find(self.win_names, 'turns') then
        bexp = bexp + (self.turnlimit - self.turn) * 10
    end
    self.render_bexp = bexp

    local affected = {}
    for i = 1, #self.participants do table.insert(affected, self.participants[i]) end
    for i = 1, #self.escaped do table.insert(affected, self.escaped[i]) end
    for i = 1, #affected do
        local sp = affected[i]
        if self:isAlly(sp) then
            local lvlups = sp:gainExp(bexp)
            if lvlups > 0 then
                local lq = self.levelup_queue
                if not lq[sp:getId()] then lq[sp:getId()] = 0 end
                lq[sp:getId()] = lq[sp:getId()] + lvlups
            end
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
    local party = self.player:mkPartyMenu(true)
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
                self:cleanupBattle()
                self.game:launchScene(self.id .. '-victory')
                self.game:startMapMusic()
                self.game.battle = nil
            end
        end
    )}

    self.game:stallInputs(1)
    local v = { "     V I C T O R Y     " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(v), true, v, GREEN, nil, true), {})
end

function Battle:openDefeatMenu()
    local m = { MenuItem:new('Restart battle', {}, 'Start the battle over', nil,
        function(c) c:reloadBattle() end
    )}

    self.game:stallInputs(1)
    local d = { "     D E F E A T     " }
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(d), true, d, RED, nil, true), {
        { AFTER, TEMP, function(b) b:renderLens({ 0.5, 0, 0 }) end }
    })
end

function Battle:openEndTurnMenu()
    self.stack = {}
    local m = { MenuItem:new('End turn', {}, 'Begin enemy phase', nil,
        function(c)
            self.game:modMusicVolume(1, 2)
            self:closeMenu()
            self:endTurn()
        end
    )}

    self.game:modMusicVolume(0.3, 2)
    self.game:stallInputs(1.5)
    sfx['enemy-phase']:play()
    local t = self.turnlimit - self.turn
    local msg = "   E N E M Y   P H A S E   " .. self.turn .. "   "
    if t == 0 then msg = "   F I N A L   E N E M Y   P H A S E   " end
    local e = { msg }
    local clr = ite(t == 0, AUTO_COLOR['Focus'], RED)
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(e), true, e, clr, nil, true), {})
end

function Battle:openBeginTurnMenu()
    self.stack = {}
    local m = { MenuItem:new('Begin turn', {}, 'Begin ally phase', nil,
        function(c)
            self.game:modMusicVolume(1, 2)
            self:closeMenu()
            self:turnRefresh()
            self.stack = { self:stackBase() }
            local focus_sp = nil
            for i=1, #self.participants do
                local sp = self.participants[i]
                if self:isAlly(sp) and self.status[sp:getId()]['inbattle'] then
                    focus_sp = sp
                    break
                end
            end
            local y, x = self:findSprite(focus_sp)
            local c = self:getCursor()
            c[1] = x
            c[2] = y
            self:checkTriggers(ALLY)
        end
    )}

    self.game:modMusicVolume(0.3, 2)
    self.game:stallInputs(1.5)
    sfx['ally-phase']:play()
    local t = self.turnlimit - self.turn
    local msg = "   A L L Y   P H A S E   " .. self.turn .. "   "
    if t == 0 then msg = "   F I N A L   T U R N   " end
    local e = { msg }
    local clr = ite(t == 0, AUTO_COLOR['Focus'], HIGHLIGHT)
    self:openMenu(Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(e), true, e, clr, nil, true), {})
end

function Battle:openAttackMenu()
    local sp = self:getSprite()
    local atk_loc = self:getCursor()
    local attrs, _, specials = self:getTmpAttributes(sp, nil, { atk_loc[2], atk_loc[1] })
    local wait = MenuItem:new('Skip', {},
        'Skip ' .. sp.name .. "'s attack", nil, function(c)
            self:push(self:stackBubble())
            self:selectTarget()
        end
    )
    local skills_menu = sp:mkSkillsMenu(true, false, attrs, specials, nil, nil)
    local weapon = skills_menu.children[1]
    local spell = skills_menu.children[2]
    for i = 1, #weapon.children do self:mkUsable(sp, weapon.children[i], sp.ignea, specials) end
    for i = 1, #spell.children do self:mkUsable(sp, spell.children[i], sp.ignea, specials) end
    local opts = { weapon, spell, wait }
    local moves = self:getMoves()
    self:openMenu(Menu:new(nil, opts, BOX_MARGIN, BOX_MARGIN, false), {
        { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end }
    })
end

function Battle:openAssistMenu()
    local sp = self:getSprite()
    local attrs, specials, hp, ign = self:dryrunAttributes(self:getCursor())
    local wait = MenuItem:new('Skip', {},
        'Skip ' .. sp.name .. "'s assist", nil, function(c)
            self:endAction(false)
        end
    )
    local skills_menu = sp:mkSkillsMenu(true, false, attrs, specials, hp, ign)
    local assist = skills_menu.children[3]
    for i = 1, #assist.children do self:mkUsable(sp, assist.children[i], ign, specials) end
    local opts = { assist, wait }
    local moves = self:getMoves()
    self:openMenu(Menu:new(nil, opts, BOX_MARGIN, BOX_MARGIN, false), {
        { BEFORE, TEMP, function(b) b:renderMovement(moves, 1) end }
    })
end

function Battle:openAllyMenu(sp)
    local tmp_attrs, _, specials = self:getTmpAttributes(sp)
    local attrs = MenuItem:new('Attributes', {},
        'View ' .. sp.name .. "'s attributes", {
        ['elements'] = sp:buildAttributeBox(tmp_attrs),
        ['w'] = HBOX_WIDTH
    })
    local sks = sp:mkSkillsMenu(true, false, tmp_attrs, specials)
    sfx['open']:play()
    self:openMenu(Menu:new(nil, { attrs, sks }, BOX_MARGIN, BOX_MARGIN, false), {})
end

function Battle:openEnemyMenu(sp)
    local attrs, _, specials = self:getTmpAttributes(sp)
    local readying = MenuItem:new('Next Attack', {},
        'Prepared skill and target', {
        ['elements'] = self:buildReadyingBox(sp, attrs, specials),
        ['w'] = HBOX_WIDTH
    })
    local skills = sp:mkSkillsMenu(false, true, attrs, specials, nil, nil, 380)
    local opts = { skills, readying }
    sfx['open']:play()
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
    sfx['open']:play()
    self:openMenu(Menu:new(nil, m, BOX_MARGIN, BOX_MARGIN, false), {})
end

function Battle:openLevelupMenu(sp, n)
    local m = { MenuItem:new('Level up', {}, nil, nil,
        function(c)
            self.game:stallInputs(1, {'f'})
            self.stack[#self.stack]['menu'] = LevelupMenu(sp, n)
        end
    )}

    self.game:stallInputs(1)
    self.game:modMusicVolume(0.3, 2)
    sfx['levelup']:play()
    local l = { "     L E V E L   U P     " }
    local menu = Menu:new(nil, m, CONFIRM_X, CONFIRM_Y(l), true, l, GREEN, nil, true)
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

function Battle:buildReadyingBox(sp, attrs, specials)

    -- Start with basic skill box
    local stat = self.status[sp:getId()]
    local prep = stat['prepare']
    local hbox = prep['sk']:mkSkillBox(icon_texture, icons, false, false, attrs, specials)

    -- Update priority for this sprite (would happen later anyway)
    if specials['taunt'] then
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

function Battle:mkUsable(sp, sk_menu, ign_left, specials)
    local sk = skills[sk_menu.id]
    sk_menu.hover_desc = 'Use ' .. sk_menu.name
    if ign_left < sk:getCost(specials) or specials[sk.id] then
        sk_menu.hover_desc = ite(specials[sk.id], 'Already active', 'Not enough ignea')
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
                    local active_c = self.stack[5]['cursor']
                    local lb = self.stack[5]['leave_behind']
                    if lb then active_c = lb end

                    local dir = b.stack[2]['sp_dir']
                    if new_c[1] ~= active_c[1] or new_c[2] ~= active_c[2] then
                        b:renderSpriteImage(new_c[1], new_c[2], sp, dir, 0.5)
                    end
                end
            end }
        }
    })
    sfx['select']:play()
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
    local attrs, specials, _, _ = self:dryrunAttributes({ j, i }, sp)
    local pts = math.floor(attrs['agility'] / 4)
    local spent = self:getSpent(i, j)
    return math.max(0, pts - spent), specials
end

function Battle:validMoves(sp, i, j)

    -- Get sprite's base movement points
    local move, specials = self:getMovement(sp, i, j)

    -- Spoof a shallow copy of the grid dryrun-move tiles occupied
    local grid = self:dryrunGrid(false)

    -- Run djikstra's algorithm on grid
    local dist, _ = sp:djikstra(grid, { i, j }, nil, move, specials['ghosting'])

    -- Reachable nodes have distance < move and are not occupied
    local moves = {}
    for y = math.max(i - move, 1), math.min(i + move, #self.grid) do
        for x = math.max(j - move, 1), math.min(j + move, #self.grid[y]) do
            if dist[y][x] <= move and (not grid[y][x].occupied or grid[y][x].occupied == sp) then
                table.insert(moves, { ['to'] = { y, x }, ['spend'] = dist[y][x] })
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
            self:openAssistMenu()
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
        atk_loc = self.stack[2]['cursor']
        local _, _, specials_before = self:getTmpAttributes(sp, nil, { atk_loc[2], atk_loc[1] })
        ign = ign - atk:getCost(specials_before)
        local dry = self:dryrunAttack()
        for i=1, #dry do
            if dry[i]['sp'] == sp then
                eff = dry[i]['new_stat']
                hp = sp.health - dry[i]['flat']
                ign = ign - dry[i]['flat_ignea']
                break
            end
        end
    end

    local loc = { standing[2], standing[1] }
    local attrs, _, specials = self:getTmpAttributes(sp, eff, loc)
    return attrs, specials, hp, ign
end

function Battle:dryrunAttack()
    local atk = self:getAttack()
    local dry = nil
    if atk then
        local sp_c = self.stack[2]['cursor']
        local atk_c = self.stack[4]['cursor']
        local sp = self:getSprite()
        local dir = self:getTargetDirection(atk, sp_c, atk_c)
        dry = self:useAttack(sp, atk, dir, atk_c, true, sp_c)
        if dry['caster'] then
            local found = false
            for i = 1, #dry do
                if dry[i]['sp'] == dry['caster']['sp'] then
                    dry[i]['flat'] = dry[i]['flat'] + dry['caster']['flat']
                    dry[i]['flat_ignea'] = dry[i]['flat_ignea'] + dry['caster']['flat_ignea']
                    dry[i]['new_stat'] = concat(dry[i]['new_stat'], dry['caster']['new_stat'])
                    found = true
                    break
                end
            end
            if not found then table.insert(dry, dry['caster']) end
            dry['caster'] = nil
        end
        return dry
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
    local enemies_hit = {}
    for k = 1, #t do
        local space = grid[t[k][1]][t[k][2]]
        local target = space.occupied
        if target then
            table.insert(ts, target)
            table.insert(ts_a, ite(self:isAlly(target), space.assists, {}))
            if not self:isAlly(target) then
                table.insert(enemies_hit, target)
            end
        end
    end
    if not dryrun then
        local mv, hurt, dead, cnts, ex = atk:use(sp, sp_a, ts, ts_a, dir, self.status, grid, dryrun)
        -- In case target lost ignea and needs to prepare a different skill
        for k=1, #enemies_hit do self:prepareSkill(enemies_hit[k], nil, true) end
        return mv, hurt, dead, cnts, ex
    else
        return atk:use(sp, sp_a, ts, ts_a, dir, self.status, grid, dryrun)
    end
end

function Battle:escape(sp)

    -- Remove sprite from participants, add to escaped
    if self:isAlly(sp) then
        for i=1, #self.participants do
            if self.participants[i] == sp then
                table.remove(self.participants, i)
                break
            end
        end
        table.insert(self.escaped, sp)
    end

    -- Remove sprite from grid and battle (escape scene will handle teleporting them out)
    local i, j = self:findSprite(sp)
    self.status[sp:getId()]['inbattle'] = false
    self.grid[i][j].occupied = nil
end

function Battle:kill(sp)
    local i, j = self:findSprite(sp)
    self.grid[i][j].occupied = nil
    self.status[sp:getId()]['alive'] = false
    self.status[sp:getId()]['inbattle'] = false
    for k=1, #self.enemy_order do
        if self.enemy_order[k] == sp:getId() then
            table.remove(self.enemy_order, k)
            break
        end
    end
end

function Battle:pathToWalk(sp, path, next_sk, ghosting)
    local move_seq = {}
    if #path == 0 then
        table.insert(move_seq, function(d)
            self.skill_in_use = next_sk
            d()
        end)
    end
    local sp_size_x_offset = -1 * (sp.w - TILE_WIDTH) / 2 - 0.5
    local sp_size_y_offset = -1 * (sp.h - TILE_HEIGHT) - 1
    for i = 1, #path do
        table.insert(move_seq, function(d)
            sp.flying = ite(ghosting, true, false)
            self.skill_in_use = next_sk
            return sp:walkToBehaviorGeneric(
                function()
                    if i == #path then
                        self:moveSprite(sp, path[i][2], path[i][1])
                        sp.flying = false
                    end
                    d()
                end,
                self.origin_x + path[i][2] + sp_size_x_offset / TILE_WIDTH, 
                self.origin_y + path[i][1] + sp_size_y_offset / TILE_HEIGHT,
                true
            )
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

function Battle:mkAttackBehavior(sp, attack, attack_dir, c_attack)
    local ox = self.origin_x
    local oy = self.origin_y
    local exp = {}
    local countering_sps = {}
    local any_response = { false }
    return exp, countering_sps, any_response, function(d)
        if not attack then
            return sp:waitBehaviorGeneric(d, 'combat', 0.2)
        end
        atk_range = self:skillRange(attack, attack_dir, c_attack)
        for i = 1, #atk_range do
            atk_range[i][1] = atk_range[i][1] + oy - 1
            atk_range[i][2] = atk_range[i][2] + ox - 1
        end
        self.skill_in_use = attack
        return sp:skillBehaviorGeneric(function()
            local moved, hurt, dead, counters, exp_gained = self:useAttack(sp,
                attack, attack_dir, c_attack
            )
            for k,v in pairs(exp_gained) do 
                if v ~= 0 then exp[k] = v end
            end
            for i=1, #counters do table.insert(countering_sps, counters[i]) end
            local dont_hurt = { [sp:getId()] = true }
            for i = 1, #moved do
                any_response[1] = true
                local t = moved[i]['sp']
                if not find(dead, t) then
                    local sp_size_x_offset = (-1 * (t.w - TILE_WIDTH) / 2 - 0.5) / TILE_WIDTH
                    local sp_size_y_offset = (-1 * (t.h - TILE_HEIGHT) - 1) / TILE_HEIGHT
                    t:behaviorSequence({ function(d)
                        local to_x = self.origin_x + moved[i]['x'] + sp_size_x_offset
                        local to_y = self.origin_y + moved[i]['y'] + sp_size_y_offset
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
                any_response[1] = true
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
        end, attack, attack_dir, c_attack[1] + ox, c_attack[2] + oy, atk_range)
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
    local _, _, m1_specials = self:getTmpAttributes(sp)
    local move1_path = sp:djikstra(self.grid,
        { sp_y, sp_x },
        { c_move1[2], c_move1[1] },
        nil, m1_specials['ghosting']
    )
    local seq = self:pathToWalk(sp, move1_path, attack, m1_specials['ghosting'])

    -- Attack
    self.exp_sources = {}
    local atk_exp, countering_sps, any_response, attackBehavior = self:mkAttackBehavior(sp, attack, attack_dir, c_attack)
    table.insert(self.exp_sources, atk_exp)
    table.insert(seq, attackBehavior)

    -- If there was an attack, check for and handle counters
    local atleast_one_counter = false
    if attack then

        -- First, if there are counters, hold on a moment to let the hurt animation finish
        table.insert(seq, function(d)
            local ttw = 0
            if #countering_sps > 0 then ttw = 1 end
            return sp:waitBehaviorGeneric(d, 'combat', ttw)
        end)

        table.insert(seq, function(d)
            local counter_behaviors = {}

            -- For each living sprite which is able to counter, register the counterattack behavior
            for i=1, #countering_sps do
                local ally_sp = countering_sps[i][1]
                local cnt_sk_id = countering_sps[i][2]
                local dmg_received = countering_sps[i][3]
                if self.status[ally_sp:getId()]['alive'] and self.status[sp:getId()]['alive'] then
                    atleast_one_counter = true
                    local counter_sk = mkCounterSkill[cnt_sk_id](dmg_received)
                    local cnt_c_y, cnt_c_x = self:findSprite(sp)
                    local cnt_exp, _, _, counterBehavior = self:mkAttackBehavior(ally_sp, counter_sk, UP, { cnt_c_x, cnt_c_y })
                    table.insert(self.exp_sources, cnt_exp)
                    table.insert(counter_behaviors, { ally_sp, counterBehavior })
                end
            end

            -- Create a behavior sequence for the first counterattacking sprite. As a doneaction, this
            -- behavior passes control to the next counterattacking sprite, and so on. The final
            -- counterattacking sprite concludes the entire action.
            local k = 1
            function counter_doneAction()
                k = k + 1

                -- Don't signal the next counterattacker if the attacker is already dead or is currently dying
                if k <= #counter_behaviors and self.status[sp:getId()]['alive'] and sp.animation_name ~= 'death' then
                    -- Pass control to the next counterattacker
                    counter_behaviors[k][1]:behaviorSequence({ counter_behaviors[k][2] }, counter_doneAction)
                    counter_behaviors[k-1][1]:changeBehavior('battle')
                else
                    -- Final counter should set action finished after a moment of waiting
                    counter_behaviors[k-1][1]:behaviorSequence(
                        {  function(d) return counter_behaviors[k-1][1]:waitBehaviorGeneric(d, 'combat', 1) end },
                        function()
                            self.action_in_progress = nil
                            self.skill_in_use = nil
                            counter_behaviors[k-1][1]:changeBehavior('battle')
                        end
                    )
                end
            end
            if #counter_behaviors > 0 then
                counter_behaviors[k][1]:behaviorSequence({ counter_behaviors[k][2] }, counter_doneAction)
            end

            -- If the sprite was damaged by a counterattack, this
            -- behavior will be overridden by a hurt/death sequence and the attacker's original
            -- sequence will be broken. Hence, the final counterattacker closes out the action.
            -- If there were no counterattacks or none did damage, this behavior is added to the sequence.
            return sp:waitBehaviorGeneric(d, 'combat', 0)
        end)
    end

    -- Only allies get a second move and assist
    if self:isAlly(sp) then

        -- If anyone was moved or killed, wait a moment for the animations to finish
        table.insert(seq, function(d)
            local ttw = 0
            if any_response[1] then ttw = 1 end
            return sp:waitBehaviorGeneric(d, 'combat', ttw)
        end)

        -- Move 2 (with spoofed grid)
        local grid = self:dryrunGrid(false)
        local _, m2_specials = self:dryrunAttributes(c_move1)
        local move2_path = sp:djikstra(grid,
            { c_move1[2], c_move1[1] },
            { c_move2[2], c_move2[1] },
            nil, m2_specials['ghosting']
        )
        seq = concat(seq, self:pathToWalk(sp, move2_path, assist, m2_specials['ghosting']))

        -- Helper gains exp if sprite started on, or moved off, their agility
        -- assist
        local ass_exp = {}
        table.insert(self.exp_sources, ass_exp)
    
        local assists_1 = self.grid[sp_y][sp_x].assists
        local assists_2 = self.grid[c_move1[2]][c_move1[1]].assists
        local all_assists = concat(assists_1, assists_2)
        for i = 1, #all_assists do
            local a = all_assists[i]
            for j = 1, #a.xp_tags do
                if a.xp_tags[j] == EXP_TAG_MOVE then
                    ass_exp[a.owner:getId()] = EXP_FOR_ASSIST
                end
            end
        end

        -- Assist
        table.insert(seq, function(d)
            if not assist then
                return sp:waitBehaviorGeneric(d, 'combat', 0.2)
            end
            ass_range = self:skillRange(assist, assist_dir, c_assist)
            for i = 1, #ass_range do
                ass_range[i][1] = ass_range[i][1] + oy - 1
                ass_range[i][2] = ass_range[i][2] + ox - 1
            end
            return sp:skillBehaviorGeneric(function()
                

                -- Get the buffs this assist will confer, based on
                -- the sprite's attributes
                local attrs, helpers, specials = self:getTmpAttributes(sp)
                local buffs = assist:use(attrs, specials, false, sp)

                -- Each buff owner with an EXP_TAG_ASSIST buff 
                -- gets EXP_FOR_ASSIST
                for owner_id,tags in pairs(helpers) do
                    if tags[EXP_TAG_ASSIST] then
                        if owner_id ~= sp:getId() then
                            ass_exp[owner_id] = EXP_FOR_ASSIST
                        end
                    end
                end

                -- Put the buffs on the grid
                local t = self:skillRange(assist, assist_dir, c_assist)
                for i = 1, #t do
                    local g = self.grid[t[i][1]][t[i][2]]
                    for j = 1, #buffs do
                        table.insert(g.assists, buffs[j])
                    end
                    g.n_assists = g.n_assists + 1
                end
                d()
            end, assist, assist_dir, c_assist[1] + ox, c_assist[2] + oy, ass_range)
        end)

        -- Wait a moment before continuing
        if assist then
            table.insert(seq, function(d)
                return sp:waitBehaviorGeneric(d, 'combat', 1)
            end)
        end
    end

    -- Register behavior sequence with sprite
    sp:behaviorSequence(seq, function()

        -- Set action finished
        -- (if there were counters, the last counter will handle cleanup. Otherwise, this sprite will)
        if not atleast_one_counter then
            self.action_in_progress = nil
            self.skill_in_use = nil
        end
        sp:changeBehavior('battle')
    end)

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
    local i = 1
    while i <= #self.render_exp do
        local re = self.render_exp[i]
        re[4] = re[4] - dt
        if re[4] < 0 then
            table.remove(self.render_exp, i)
        else
            i = i + 1
        end
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
        local done = false
        if d then
            done = m:back()
        elseif f then
            m:forward(self.game)
        elseif up ~= down then
            m:hover(ite(up, UP, DOWN))
        end

        if done then
            self:closeMenu()
            sfx['cancel']:play()
        end
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
                    sfx['select']:play()
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
                local change = self:moveCursor(nx, ny)
                if change then
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
            end

            if f then
                if sk.type ~= ASSIST then
                    local c_cur = self:getCursor()
                    local t = self.grid[c_cur[2]][c_cur[1]].occupied
                    local can_obsv = t and self:isAlly(t) and t.id ~= 'elaine'
                    if not (sk.id == 'observe' and not can_obsv) then
                        sfx['select']:play()
                        self:selectTarget()
                    end
                else
                    sfx['select']:play()
                    self:endAction(true)
                end
            end
        end

    elseif s == STAGE_WATCH then

        -- Clean up after actions are performed
        if not self.action_in_progress then

            -- Everyone gains experience
            local total_exp = {}
            for i=1, #self.exp_sources do
                for sp_id, e in pairs(self.exp_sources[i]) do
                    if total_exp[sp_id] ~= nil then
                        total_exp[sp_id] = total_exp[sp_id] + e
                    else
                        total_exp[sp_id] = e
                    end
                end
            end
            for sp_id, e in pairs(total_exp) do
                local sp = self.status[sp_id]['sp']
                local _, _, specials = self:getTmpAttributes(sp)
                if self:isAlly(sp) and e > 0 and self.status[sp_id]['inbattle'] and not specials['unconscious'] then

                    -- Render experience gained
                    local y, x = self:findSprite(sp)
                    table.insert(self.render_exp, { x, y, e, 2 })

                    -- Gain experience and queue levelups
                    local lvls = sp:gainExp(e)
                    if lvls > 0 then self.levelup_queue[sp_id] = lvls end
                end
            end
            self.exp_sources = {}

            -- Check levelups
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

            -- Check scene tiles
            if self:checkSceneTiles() then
                self.stall_battle_cam = true
                return
            end

            -- Say this sprite acted and reset stack
            self.status[self:getSprite():getId()]['acted'] = true
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
                self.game:modMusicVolume(1, 2)
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
function Battle:prepareSkill(e, i, no_increment, spent)

    if not spent then spent = 0 end

    local stat = self.status[e:getId()]
    if not i then
        local prev = 0
        if stat['prepare'] then prev = stat['prepare']['index'] end
        i = ite(no_increment, prev, prev % #e.skills + 1)
    end
    local sk = e.skills[i]
    while sk.cost > e.ignea - spent do
        i = i % #e.skills + 1
        sk = e.skills[i]
    end
    stat['prepare'] = { ['sk'] = sk, ['prio'] = { sk.prio }, ['index'] = i }
end

function Battle:planAction(e, plan, other_plans)

    -- Get targeting priority
    local stat = self.status[e:getId()]
    local prio = stat['prepare']['prio'][1]

    -- Pick a target from the set of choices based on the sprite's priorities
    local tgt = nil -- Who to target
    local candidate_moves = {} -- Candidate moves to get to this target

    -- If the target is forced, it doesn't matter where they are. Target them.
    if prio == FORCED then
        local sp = self.status[stat['prepare']['prio'][2]]['sp']
        local found = false
        for i = 1, #plan['options'] do
            if sp == plan['options'][i]['sp'] then
                found = true
                tgt = plan['options'][i]
                candidate_moves = tgt['moves']
            end
        end
        if not found then prio = KILL end
    end

    -- The set of choices is all ally sprites that can be reached in the lowest possible
    -- number of turns
    local tgts = {}
    local best_ttr = math.huge
    for i=1, #plan['options'] do
        local ttr = plan['options'][i]['ttr']
        if ttr < best_ttr then
            tgts = {}
            best_ttr = ttr
        end
        if ttr == best_ttr then
            table.insert(tgts, plan['options'][i])
        end
    end

    if prio == KILL then

        -- Find target that will suffer the maximum percentage of their current health
        -- as damage, and target that will allow the maximum percentage of current health
        -- to be dealt overall (potentiall across multiple targets).
        local max_percent_ind = 0
        local max_percent_sum = 0
        local ind_tgt = nil
        local sum_tgt = nil
        for i = 1, #tgts do
            for j = 1, #tgts[i]['moves'] do
                local a = tgts[i]['moves'][j]['attack']
                local d = self:useAttack(e, plan['sk'], a['dir'], a['c'], true)
                local sum = 0
                for k = 1, #d do
                    sum = sum + d[k]['percent']
                    if d[k]['percent'] >= max_percent_ind then
                        max_percent_ind = d[k]['percent']
                        ind_tgt = tgts[i]
                    end
                end
                if sum >= max_percent_sum then
                    max_percent_sum = sum
                    sum_tgt = tgts[i]
                end
            end
        end

        -- Assemble candidate moves
        -- If a target can be killed, they're the target
        local y, x = self:findSprite(e)
        if max_percent_ind == 1 then
            tgt = ind_tgt
            if tgt == nil then return { x, y }, nil, nil end
            candidate_moves = tgt['moves']
        else
            tgt = sum_tgt
            if tgt == nil then return { x, y }, nil, nil end
            for j = 1, #tgt['moves'] do
                local a = tgt['moves'][j]['attack']
                local d = self:useAttack(e, plan['sk'], a['dir'], a['c'], true)
                local sum = 0
                for k = 1, #d do sum = sum + d[k]['percent'] end
                if sum == max_percent_sum then table.insert(candidate_moves, tgt['moves'][j]) end
            end
        end
    end

    -- After the best target and candidate moves have been found, pick the move
    -- which lands closest to the target (as the crow flies), with ties broken
    -- by lower movement cost (to avoid, e.g. circling around an adjacent target).
    local mv = nil
    local min_cost = math.huge
    local min_proximity = math.huge
    for i = 1, #candidate_moves do
        local cost = candidate_moves[i]['attack']['dist']
        local mv_c = candidate_moves[i]['move_c']
        local y, x = self:findSprite(tgt['sp'])
        local proximity = abs(mv_c[1] - x) + abs(mv_c[2] - y)
        if proximity < min_proximity then
            min_proximity = proximity
            min_cost = cost
            mv = candidate_moves[i]
        elseif proximity == min_proximity then
            if cost < min_cost then
                min_cost = cost
                mv = candidate_moves[i]
            end
        end
    end

    -- Return move data, and attack data if target is reachable
    if tgt['ttr'] == 1 then
        return mv['move_c'], mv['attack']['c'], tgt['sp']
    end
    return mv['move_c'], nil, nil
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

function Battle:collectMoves(e, sps)

    -- Get skill
    local sk = self.status[e:getId()]['prepare']['sk']

    -- Preemptively get shortest paths for the grid, and enemy movement
    local y, x = self:findSprite(e)
    local paths_dist, paths_prev = e:djikstra(self.grid, { y, x })
    local attrs = self:getTmpAttributes(e)
    local movement = math.floor(attrs['agility'] / 4)

    -- Compute ALL movement options!
    local opts = {}
    for i = 1, #sps do
        local _, _, specials = self:getTmpAttributes(sps[i])
        if not specials['hidden'] then
            local sp_opts = { ['sp'] = sps[i], ['ttr'] = math.huge, ['moves'] = {} }

            -- Get all attacks that can be made against this sprite using the skill
            local attacks = self:getAttackAngles(e, sps[i], sk)
            for j = 1, #attacks do

                -- Get distance and path to attack location
                local attack_from = attacks[j]['from']
                local dist = paths_dist[attack_from[1]][attack_from[2]]
                if dist ~= math.huge then

                    -- Sprite should move to path node with dist == movement
                    local turns_to_reach = math.max(1, math.ceil(dist / movement))
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
                            ['from'] = attack_from,
                            ['dir'] = attacks[j]['dir']
                        }
                    }

                    -- New best ttr, erase all other moves
                    if turns_to_reach < sp_opts['ttr'] then
                        sp_opts['moves'] = {}
                        sp_opts['ttr'] = turns_to_reach
                    end

                    -- If this ttr matches our best, save it as a possible move
                    if turns_to_reach == sp_opts['ttr'] then
                        table.insert(sp_opts['moves'], c)
                    end
                end
            end
            table.insert(opts, sp_opts)
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
    local _, _, specials = self:getTmpAttributes(e)
    if specials['stun'] then
        local y, x = self:findSprite(e)
        local move = { ['cursor'] = { x, y }, ['sp'] = e }
        self.enemy_action = { self:stackBase(), move, {}, {}, move, {}, {} }
        return
    end

    -- If the current enemy is enraged, force it to target Kath
    if specials['taunt'] then
        stat['prepare']['prio'] = { FORCED, 'kath' }
    end

    -- For every enemy who hasn't acted, make a tentative plan for their action
    local sps = filter(function(p) return self:isAlly(p) end, self.participants)
    local plans = {}
    for i = 1, #enemies do

        -- Precompute options for targeting all ally sprites
        plans[i] = self:collectMoves(enemies[i], sps)

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

    -- Declare next enemy action to be played as an action stack
    local move = { ['cursor'] = m_c, ['sp'] = e }
    local attack = ite(a_c, { ['cursor'] = a_c, ['sk'] = plans[1]['sk'] }, {})
    self.enemy_action = { self:stackBase(), move, {}, attack, move, {}, {} }

    -- Prepare the skill this enemy will use next turn, accounting for any ignea they spent
    local spent = 0
    if attack['sk'] then spent = attack['sk'].cost end
    self:prepareSkill(e, nil, false, spent)
end

function Battle:renderSceneTiles()
    for _, v in pairs(self.scene_tiles) do
        self:shadeSquare(v[2], v[1], AUTO_COLOR['Weapon'], 1)
    end
end

function Battle:renderCursors()
    for i = 1, #self.stack do
        local c = self.stack[i]['cursor']
        if c then
            local x_tile = self.origin_x + c[1]
            local y_tile = self.origin_y + c[2]
            local x, y = tileToPixels(x_tile, y_tile)
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
    drawBox(x, y, w, h, {0, 0, 0, RECT_ALPHA})
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
    local sp_size_x_offset = -1 * (sp.w - TILE_WIDTH) / 2 - 0.5
    local sp_size_y_offset = -1 * (sp.h - TILE_HEIGHT) - 1
    love.graphics.draw(
        spritesheet,
        sp:getCurrentQuad(),
        TILE_WIDTH * (x + self.origin_x - 1) + sp.w / 2 + sp_size_x_offset,
        TILE_HEIGHT * (y + self.origin_y - 1) + sp.h / 2 + sp_size_y_offset,
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

function Battle:renderAttackable(sp, moves)
    local sk = self.status[sp:getId()]['prepare']['sk']
    local is_move = {}
    for i=1, #moves do
        local m = moves[i]['to']
        if not is_move[m[1]] then is_move[m[1]] = {} end
        is_move[m[1]][m[2]] = true
    end
    local added_attack = {}
    local attackable = {}
    for i=1, #moves do
        local y = moves[i]['to'][1]
        local x = moves[i]['to'][2]
        local cursors_dirs = { { x, y, UP } }
        if sk.aim['type'] == DIRECTIONAL then
            cursors_dirs = {
                { x, y - 1, UP },
                { x, y + 1, DOWN },
                { x - 1, y, LEFT },
                { x + 1, y, RIGHT }
            }
        end
        for j=1, #cursors_dirs do
            local cd = cursors_dirs[j]
            local atk_tiles = self:skillRange(sk, cd[3], { cd[1], cd[2] })
            for k=1, #atk_tiles do
                local t = atk_tiles[k]
                if (not is_move[t[1]] or not is_move[t[1]][t[2]])
                and (not added_attack[t[1]] or not added_attack[t[1]][t[2]]) then
                    table.insert(attackable, t)
                    if not added_attack[t[1]] then added_attack[t[1]] = {} end
                    added_attack[t[1]][t[2]] = true
                end
            end
        end
    end
    for i = 1, #attackable do
        self:shadeSquare(attackable[i][1], attackable[i][2], {1, 0, 0}, 0.5)
    end
end

function Battle:renderMovementHover()
    local c = self:getCursor()
    local sp = self.grid[c[2]][c[1]].occupied
    if sp and not self.status[sp:getId()]['acted'] then
        local i, j = self:findSprite(sp)
        local moves = self:validMoves(sp, i, j)
        self:renderMovement(moves, 0.5)
        if not self:isAlly(sp) then
            self:renderAttackable(sp, moves)
        end
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
    
    local sp_size_x_offset = -1 * (sp.w - TILE_WIDTH) / 2 - 0.5
    local sp_size_y_offset = -1 * (sp.h - TILE_HEIGHT) - 1
    y = y + sp.h + ite(self.pulse, 0, -1) - 1
    x = x + 3
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x + sp_size_x_offset, y + sp_size_y_offset, sp.w - 6, 3)
    love.graphics.setColor(0.4, 0, 0.2, 1)
    love.graphics.rectangle('fill', x + sp_size_x_offset, y + sp_size_y_offset, (sp.w - 6) * ratio, 3)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('line', x + sp_size_x_offset, y + sp_size_y_offset, sp.w - 6, 3)
end

function Battle:renderStatus(x, y, statuses)

    -- Collect what icons need to be rendered
    local buffed    = false
    local debuffed  = false
    local augmented = false
    local impaired  = false
    for i = 1, #statuses do
        if not statuses[i].hidden then
            local b = statuses[i].buff
            if isSpecial(b.attr) then
                if b.type == BUFF   then augmented = true end
                if b.type == DEBUFF then impaired  = true end
            else
                if b.type == BUFF   then buffed   = true end
                if b.type == DEBUFF then debuffed = true end
            end
        end
    end

    -- Render icons
    local y_off = ite(self.pulse, 0, 1)
    if buffed then
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.draw(icon_texture, status_icons[1],
            x + TILE_WIDTH - 8, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if debuffed then
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.draw(icon_texture, status_icons[2],
            x + TILE_WIDTH - 16, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if augmented then
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.draw(icon_texture, status_icons[4],
            x + 8, y + y_off, 0, 1, 1, 0, 0
        )
    end
    if impaired then
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
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

            -- Adjust for sprite size
            x = x + (sp.w - TILE_WIDTH) / 2 + 0.5
            y = y + (sp.h - TILE_WIDTH) + 1

            -- If we aren't watching an action play out!
            local s = self:getStage()
            if s and s ~= STAGE_WATCH and s ~= STAGE_LEVELUP then

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
                        if v['sp'] == sp then
                            if v['moved'] and not v['died'] then
                                t_y, t_x = v['moved']['y'], v['moved']['x']
                                break
                            elseif v['died'] then
                                goto continue
                            end
                        end
                    end
                end
                
                -- Convert tile coords to x and y on screen
                local px, py = tileToPixels(
                    self.origin_x + t_x, self.origin_y + t_y
                )
                x = px - self.game.camera_x
                y = py - self.game.camera_y
            end

            -- Render everything
            self:renderHealthbar(sp, x, y, ratio)
            self:renderStatus(x, y, statuses)
        end
        ::continue::
    end
end

function Battle:renderExpGain()
    for i=1, #self.render_exp do
        local re = self.render_exp[i]
        local t_x, t_y, e, timer = re[1], re[2], re[3], re[4]
        local x,y = tileToPixels(
            self.origin_x + t_x, self.origin_y + t_y
        )
        x = x - self.game.camera_x + 20
        y = y - self.game.camera_y + timer * 5
        love.graphics.push('all')
        local clr = { HIGHLIGHT[1], HIGHLIGHT[2], HIGHLIGHT[3], timer / 2 }
        love.graphics.setColor(unpack(clr))
        love.graphics.setFont(EXP_FONT)
        love.graphics.print(e .. "xp", x, y)
        love.graphics.pop()
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
    if not find(self.win_names, 'turns') then
        local bexp = self.render_bexp
        local saved = self.turnlimit - self.turn
        local msg1 = saved .. " turns saved * 10 exp"
        local msg2 = bexp .. " bonus exp"

        local computeX = function(s)
            return VIRTUAL_WIDTH - BOX_MARGIN - #s * CHAR_WIDTH
        end
        local base_y = BOX_MARGIN
        renderString(msg1, computeX(msg1), base_y, DISABLE)
        renderString(msg2, computeX(msg2), base_y + LINE_HEIGHT, HIGHLIGHT)
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
    local hp_str   = hp  .. "/" .. (sp.attributes['endurance'] * 2)
    local ign_str  = ign .. "/" ..  sp.attributes['focus']

    -- Compute box width from longest status
    local longest_status = 0
    for i = 1, #statuses do
        if not statuses[i].hidden then

            -- Space (in characters) between two strings in hover box
            local buf = 3

            -- Length of duration string
            local d = statuses[i].duration
            local dlen = ite(d == math.huge, 0, ite(d < 10, 2, 3))

            -- Length of buff string
            local b = statuses[i].buff
            local blen = 0
            if b:toStr() then blen = #b:toStr() end

            -- Combine them all to get character size
            longest_status = math.max(longest_status, dlen + blen + buf)
        end
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
    local n_hidden = 0
    for i = 1, #statuses do
        if not statuses[i].hidden then
            local cy = y + LINE_HEIGHT * (i - n_hidden - 1)
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
        else
            n_hidden = n_hidden + 1
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
    local ign = sp.ignea - result['flat_ignea']
    if sp == self:getSprite() then
        local move1 = self:getCursor(2)
        local _, _, specials = self:getTmpAttributes(sp, nil, { move1[2], move1[1] })
        ign = ign - sk:getCost(specials)
    end
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
end

function Battle:renderAssistHoverBox(sk)

    -- Get the sprites new attributes and assist effect after
    -- attacking and moving
    local attrs, specials, _, _ = self:dryrunAttributes(self:getCursor(2))
    local buffs = sk:use(attrs, specials, true)
    
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
    drawBox(x, y, w, h, clr)

    -- Render box elements
    for i = 1, #box do
        local e = box[i]
        if e['type'] == 'text' then
            local clr = ite(e['color'], e['color'], WHITE)
            renderString(e['data'], x + e['x'], y + e['y'], clr)
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

    local res, atk = nil, nil
    local dry = self:dryrunAttack()
    if dry then
        atk = self:getAttack()
        for _,v in pairs(dry) do
            if sp and v['sp'] == sp then res = v end
        end
        if sp and not res then
            res = { ['flat'] = 0, ['flat_ignea'] = 0, ['new_stat'] = self.status[sp:getId()]['effects'] }
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
        local alt_text = nil
        for k, v in pairs(self.scene_tiles) do
            if v[1] == c[1] and v[2] == c[2] then
                alt_text = capitalize(k):gsub('_', ' '):gsub('%d','')

            end
        end
        if alt_text then
            local clr = { 0.4, 0.4, 0.2 }
            return { mkEle('text', alt_text, HALF_MARGIN, HALF_MARGIN) }, w, h, clr
        else
            local clr = { 0, 0, 0 }
            return { mkEle('text', 'Empty', HALF_MARGIN, HALF_MARGIN) }, w, h, clr
        end
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

    -- Shade escape tiles yellow if there are any
    self:renderSceneTiles()

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
    self:renderExpGain()
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
    ['escape'] = { "all allies escape the battlefield",
        function(b)
            for _,sp in pairs(b.participants) do
                if b.status[sp:getId()]['team'] == ALLY then
                    return false
                end
            end
            return true
        end
    },
    ['turns'] = {} -- Filled in with turnlimit programmatically
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
    ['turns'] = {} -- Filled in with turnlimit programmatically
}