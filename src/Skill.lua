require 'src.Util'
require 'src.Constants'

require 'src.Menu'

Scaling = class('Scaling')

function Scaling:initialize(base, attr, mul)
    self.base = base
    self.attr = ite(attr, attr, 'force')
    self.mul  = ite(mul, mul, 0)
end

Buff = class('Buff')

function Buff:initialize(attr, val, ty, owner, xp_tags)
    self.attr    = attr
    self.val     = val
    self.type    = ty
    self.owner   = owner
    self.xp_tags = ite(xp_tags ~= nil, xp_tags, {})
end

function Buff:toStr()
    if self.attr == 'special' then
        return EFFECT_NAMES[self.val]
    end
    if self.val == 0 then
        return nil
    end
    local attr = self.attr:sub(1,1):upper() .. self.attr:sub(2)
    return ite(self.val > 0, '+', '-') .. abs(self.val) .. ' ' .. self.attr
end

Effect = class('Effect')

function Effect:initialize(buff, dur)
    self.buff     = buff
    self.duration = dur
end

Skill = class('Skill')

function Skill:initialize(id, n, desc, ti, st, prio, anim_type, si, tr, r, at, c,
                          affects, scaling, sp_effects, ts_effects, ts_displace,
                          modifiers, buff_templates, owner_exp_when)

    -- Identifying info
    self.id           = id
    self.name         = n
    self.tree_id      = ti
    self.type         = st
    self.prio         = prio
    self.scaling_icon = si
    self.desc         = desc

    -- Requirements to learn
    self.reqs = tr

    -- Battle effects
    self.range  = r  -- Shape of ability (cursor is center of 2d table, for
                     -- directional abilities, shape points north)
    self.aim    = at -- directional (cursor on adjacent square),
                     -- self_cast (cursor on self)
                     -- free_aim(scale, target) (cursor on any target within
                     -- diamond of size scale centered on caster)
    self.cost   = c  -- Ignea cost

    -- Is the skill animation played relative to the caster?
    -- Or on each targeted grid tile?
    self.anim_type = anim_type

    -- Upvalues for use function
    self.dmg_type = st
    self.affects = affects
    self.scaling = scaling
    self.sp_effects = ite(sp_effects, sp_effects, {})
    self.ts_effects = ite(ts_effects, ts_effects, {})
    self.ts_displace = ite(ts_displace, ts_displace, {})
    self.modifiers = ite(modifiers, modifiers, {})
    self.buff_templates = buff_templates
    self.owner_exp_when = owner_exp_when
end

function Skill:use(a, b, c, d, e, f, g, h)
    if self.type == ASSIST then return self:assist(a, b)
    else                        return self:attack(a, b, c, d, e, f, g, h)
    end
end

function Skill:hits(caster, target, t_team)
    local oppo_team = ite(t_team == ALLY, ENEMY, ALLY)
    return (self.type == ASSIST and t_team == ALLY)
        or (self.type ~= ASSIST and oppo_team ~= self.affects)
        or (caster == target and self.modifiers['self'])
end

function Skill:assist(attrs, sp)
    local buffs = {}
    for i = 1, #self.buff_templates do
        local exp_tag = ite(i == 1, self.owner_exp_when, {})
        table.insert(buffs, mkBuff(attrs, self.buff_templates[i], sp, exp_tag))
    end
    return buffs
end

function Skill:attack(sp, sp_assists, ts, ts_assists, atk_dir, status, grid, dryrun)

    -- Bring upvalues into scope
    local dmg_type = self.dmg_type
    local affects = self.affects
    local scaling = self.scaling
    local sp_effects = self.sp_effects
    local ts_effects = self.ts_effects
    local ts_displace = self.ts_displace
    local modifiers = self.modifiers

    -- Who was moved/hurt/killed by this attack?
    local moved = {}
    local hurt = {}
    local dead = {}

    -- Levelups gained by each sprite
    local lvlups = {}
    local exp_gain = { [sp:getId()] = 0 }

    -- Temporary attributes and special effects for the caster
    local sp_team = status[sp:getId()]['team']
    local sp_stat = status[sp:getId()]['effects']
    local sp_tmp_attrs, sp_helpers = mkTmpAttrs(sp.attributes, sp_stat, sp_assists)

    -- Affect targets
    local dryrun_res = {}
    local z = 1
    local total_dealt = 0
    local status_xp = 0
    for i = 1, #ts do

        -- Temporary attributes and special effects for the target
        local t = ts[i]
        local t_team = status[t:getId()]['team']
        local t_stat = status[t:getId()]['effects']
        local t_ass = ts_assists[i]
        local t_tmp_attrs, t_helpers = mkTmpAttrs(t.attributes, t_stat, t_ass)

        -- If attacker is an enemy and target has forbearance, the target
        -- switches to Kath
        if hasSpecial(t_stat, t_ass, 'forbearance')
        and sp_team == ENEMY then
            local s_kath = status['kath']
            local loc = s_kath['location']
            t = s_kath['sp']
            t_stat = s_kath['effects']
            t_ass = grid[loc[2]][loc[1]].assists
            t_tmp_attrs, t_helpers = mkTmpAttrs(t.attributes, t_stat, t_ass)
        end

        -- Only hit targets passing the team filter
        if self:hits(sp, t, t_team) then

            -- Dryrun just computes results, doesn't deal damage or apply effects
            dryrun_res[z] = {
                ['sp'] = t,
                ['flat'] = 0,
                ['percent'] = 0,
                ['new_stat'] = t_stat,
                ['died'] = false
            }

            -- Some modifiers prevent a target from taking damage
            -- except under special circumstances
            if not modifiers['br'] 
            or modifiers['br'](sp, sp_tmp_attrs, t, t_tmp_attrs, status) then

                -- If there's no scaling, the attack does no damage
                if scaling then

                    -- Compute damage or healing (MUST be a SPELL to heal)
                    local atk = scaling.base
                            + math.floor(sp_tmp_attrs[scaling.attr]
                            * scaling.mul)
                    local dmg = atk
                    if dmg_type == WEAPON then
                        local def = math.floor(t_tmp_attrs['reaction'])
                        dmg = math.max(0, atk - def)
                    end

                    -- If this is a self hit or the target has guardian angel
                    -- they can't die
                    local min = 0
                    if (t == sp and modifiers['self'])
                    or hasSpecial(t_stat, t_ass, 'guardian_angel') then
                        min = 1
                    end

                    -- Deal damage or healing
                    local max_hp = t_tmp_attrs['endurance'] * 2
                    local pre_hp = t.health
                    local n_hp = math.max(min, math.min(max_hp, t.health - dmg))
                    local dealt = pre_hp - n_hp
                    total_dealt = total_dealt + dealt
                    if not dryrun then
                        t.health = n_hp
                    end

                    dryrun_res[z]['flat'] = dealt
                    dryrun_res[z]['percent'] = dealt / pre_hp

                    -- Allies gain exp for damage dealt to enemies
                    -- and half exp for healing dealt to allies
                    if sp_team == ALLY and t_team == ENEMY and dealt > 0 then
                        local xp = math.floor(dealt * EXP_DMG_RATIO)
                        exp_gain[sp:getId()] = exp_gain[sp:getId()] + xp

                        -- Each buff owner with an EXP_TAG_ATTACK buff 
                        -- gets EXP_FOR_ASSIST
                        for owner_id,tags in pairs(sp_helpers) do
                            if tags[EXP_TAG_ATTACK] then
                                if owner_id ~= sp:getId() then
                                    exp_gain[owner_id] = EXP_FOR_ASSIST
                                end
                            end
                        end
                    elseif sp_team == ALLY and t_team == ALLY and dealt < 0 then
                        local xp = math.floor(abs(dealt) * EXP_HEAL_RATIO)
                        exp_gain[sp:getId()] = exp_gain[sp:getId()] + xp
                    end

                    -- Determine if target is hurt, or dead
                    if n_hp == 0 then
                        if not find(dead, t) then
                            table.insert(dead, t)
                            -- Experience for getting a kill
                            exp_gain[sp:getId()] = exp_gain[sp:getId()] + EXP_ON_KILL
                            dryrun_res[z]['died'] = true
                        end
                    elseif n_hp < pre_hp then
                        if not find(hurt, t) then
                            table.insert(hurt, t)
                        end
                    end

                    -- If the target is an ally hit by an enemy and didn't die,
                    -- gain exp for getting hit
                    -- Assisting allies gain xp if one of their assists has 
                    -- tag RECV
                    if not dryrun and sp_team == ENEMY and t_team == ALLY
                    and t.health > 0
                    then
                        -- Exp for taking damage
                        local tid = t:getId()
                        if not exp_gain[tid] then exp_gain[tid] = 0 end
                        exp_gain[tid] = exp_gain[tid] + EXP_ON_ATTACKED

                        -- Each buff owner with an EXP_TAG_RECV buff 
                        -- gets EXP_FOR_ASSIST
                        for owner_id,tags in pairs(t_helpers) do
                            if tags[EXP_TAG_RECV] then
                                if owner_id ~= tid then
                                    exp_gain[owner_id] = EXP_FOR_ASSIST
                                end
                            end
                        end
                    end
                end

                -- Apply status effects to target
                if dryrun then
                    t_stat = copy(t_stat)
                end
                ts_effects = copy(ts_effects)
                if hasSpecial(sp_stat, sp_assists, 'flanking') then
                    table.insert(ts_effects,
                        { { 'reaction', Scaling:new(-6) }, 1 }
                    )
                end
                for j = 1, #ts_effects do
                    local b = mkBuff(sp_tmp_attrs, ts_effects[j][1])
                    addStatus(t_stat, Effect:new(b, ts_effects[j][2]))

                    -- Allies gain exp for applying negative status to enemies
                    -- or applying positive statuses to allies
                    local exp = 0
                    if (b.type == DEBUFF and sp_team == ALLY and t_team == ENEMY)
                    or (b.type == BUFF and sp_team == ALLY and t_team == ALLY)
                    then
                        exp = EXP_ON_SPECIAL
                        if b.attr ~= 'special' then exp = abs(b.val) end
                    end
                    status_xp = math.min(status_xp + exp, EXP_STATUS_MAX)
                end
                dryrun_res[z]['new_stat'] = t_stat

                -- Compute x/y displacement tile based on direction and grid state
                -- Only record if displacement is non-zero
                if #ts_displace > 0 then
                    
                    -- Compute actual direction
                    local dirs = { UP, RIGHT, DOWN, LEFT }
                    local dir = ts_displace[1]
                    local k = find(dirs, dir) - 1
                    local h = find(dirs, atk_dir) - 1
                    dir = dirs[((k + h) % 4) + 1]

                    -- Compute actual displacement
                    local d = ts_displace[2]
                    local loc = status[t:getId()]['location']
                    local x, y = loc[1], loc[2]
                    if dir == UP then
                        while y > loc[2] - d and grid[y-1] and grid[y-1][x] 
                        and not grid[y-1][x].occupied do
                            y = y - 1
                        end
                    elseif dir == RIGHT then
                        while x < loc[1] + d and grid[y] and grid[y][x+1] 
                        and not grid[y][x+1].occupied do
                            x = x + 1
                        end
                    elseif dir == DOWN then
                        while y < loc[2] + d and grid[y+1] and grid[y+1][x] 
                        and not grid[y+1][x].occupied do
                            y = y + 1
                        end
                    elseif dir == LEFT then
                        while x > loc[1] - d and grid[y] and grid[y][x-1] 
                        and not grid[y][x-1].occupied do
                            x = x - 1
                        end
                    end

                    -- Record final tile displaced to
                    if x ~= loc[1] or y ~= loc[2] then
                        local do_move = true
                        for w=1, #moved do
                            if moved[w]['sp'] == t then
                                do_move = false
                            end
                        end
                        if do_move then
                            table.insert(moved, { ['sp'] = t, ['x'] = x, ['y'] = y })
                        end
                        if dryrun then
                            dryrun_res[z]['moved'] = {
                                ['x'] = x, ['y'] = y, ['dir'] = dir
                            }
                        end
                    end
                end

                -- Target turns to face the caster
                if not dryrun then
                    if abs(t.x - sp.x) > TILE_WIDTH / 2 then
                        t.dir = ite(t.x > sp.x, LEFT, RIGHT)
                    end
                end

                -- Additional effects given by the 'and' modifier
                if not dryrun and modifiers['and'] then
                    modifiers['and'](sp, sp_tmp_attrs, t, t_tmp_attrs, status)
                end

                z = z + 1
            end
        end
    end

    -- Affect caster
    if dryrun then
        sp_stat = copy(sp_stat)
    end
    for j = 1, #sp_effects do
        local b = mkBuff(sp_tmp_attrs, sp_effects[j][1])
        addStatus(sp_stat, Effect:new(b, sp_effects[j][2]))

        -- Allies gain exp for applying positive status to themselves
        local exp = 0
        if b.type == BUFF and sp_team == ALLY then
            exp = EXP_ON_SPECIAL
            if b.attr ~= 'special' then exp = abs(b.val) end
        end
        status_xp = math.min(status_xp + exp, EXP_STATUS_MAX)
    end
    if #sp_effects > 0 or modifiers['lifesteal'] then
        dryrun_res['caster'] = { ['sp'] = sp, ['flat'] = 0, ['new_stat'] = sp_stat }
        if modifiers['lifesteal'] then
            local heal = math.floor(total_dealt * modifiers['lifesteal'])
            local healed = math.min(sp.attributes['endurance'] * 2 - sp.health, heal)
            dryrun_res['caster']['flat'] = -healed
            if not dryrun then
                sp.health = sp.health + healed
            end
        end
    end

    -- If the attacker is an ally, record exp gained
    if sp_team == ALLY then
        exp_gain[sp:getId()] = exp_gain[sp:getId()] + status_xp
    end

    if not dryrun then
        -- Return which targets were hurt/killed, and exp gained
        return moved, hurt, dead, exp_gain
    else
        return dryrun_res
    end
end

function Skill:toMenuItem(itex, icons, with_skilltrees, with_prio)
    local hbox = self:mkSkillBox(itex, icons, with_skilltrees, with_prio)
    return MenuItem:new(self.name, {}, nil, {
        ['elements'] = hbox,
        ['w'] = HBOX_WIDTH
    }, nil, nil, nil, self.id)
end

function Skill:mkSkillBox(itex, icons, with_skilltrees, with_prio)
    local req_x = 410
    local req_y = HALF_MARGIN
    local desc_x = HALF_MARGIN * 3 + PORTRAIT_SIZE - 5
    local range_x = BOX_MARGIN
    local range_y = HALF_MARGIN + 6 + LINE_HEIGHT
    local hbox = {
        mkEle('text', {self.name}, HALF_MARGIN + 55, HALF_MARGIN),
        mkEle('image', icons[self:treeToIcon()],
            HALF_MARGIN, 7, itex),
        mkEle('image', icons[self.type],
            HALF_MARGIN + 25, 7, itex),
        mkEle('text', splitByCharLimit(self.desc, 28),
            desc_x, BOX_MARGIN + LINE_HEIGHT - 3, nil, true),
        mkEle('text', {'Cost: ' .. self.cost},
            req_x + 5, req_y + LINE_HEIGHT * 4 + HALF_MARGIN),
        mkEle('text', {'Scaling:'},
            req_x + 5, req_y + LINE_HEIGHT * 5 + HALF_MARGIN + 5),
        mkEle('image', icons[str_to_icon['focus']],
            req_x + 10 + CHAR_WIDTH * 8,
            req_y + LINE_HEIGHT * 4 + HALF_MARGIN - 2, itex),
        mkEle('image', icons[self.scaling_icon],
            req_x + 10 + CHAR_WIDTH * 8,
            req_y + LINE_HEIGHT * 5 + HALF_MARGIN + 3, itex),
        mkEle('range', { self.range, self.aim, self.type },
            range_x, range_y)
    }
    if with_skilltrees then
        hbox = concat(hbox, {
            mkEle('image', icons[str_to_icon[self.reqs[1][1]]],
                req_x, req_y, itex),
            mkEle('image', icons[str_to_icon[self.reqs[2][1]]],
                req_x + BOX_MARGIN * 2, req_y, itex),
            mkEle('image', icons[str_to_icon[self.reqs[3][1]]],
                req_x + BOX_MARGIN * 4, req_y, itex),
            mkEle('text', {tostring(self.reqs[1][2])},
                req_x + 8, req_y + LINE_HEIGHT + 2),
            mkEle('text', {tostring(self.reqs[2][2])},
                req_x + BOX_MARGIN * 2 + 8, req_y + LINE_HEIGHT + 2),
            mkEle('text', {tostring(self.reqs[3][2])},
                req_x + BOX_MARGIN * 4 + 8, req_y + LINE_HEIGHT + 2),
            mkEle('text', {'Requirements'},
                req_x, req_y + LINE_HEIGHT * 2),
            mkEle('text', {'  to learn  '},
                req_x, req_y + LINE_HEIGHT * 3)
        })
    elseif with_prio then
        hbox = concat(hbox, self:mkPrioElements({self.prio}))
    end
    return hbox
end

function Skill:mkPrioElements(prio)
    local header  = { 'Target:' }
    local ps = {
        [ CLOSEST   ] = { 'Closest',  'enemy'   },
        [ KILL      ] = { 'Killable', 'enemies' },
        [ DAMAGE    ] = { 'Highest',  'damage'  },
        [ STRONGEST ] = { 'Biggest',  'threat'  },
    }
    if prio[1] == MANUAL then
        return {}
    else
        local x = 415
        local y = HALF_MARGIN + LINE_HEIGHT + 5
        local str = ite(prio[1] < MANUAL, ps[prio[1]], { prio[2] })
        return {
            mkEle('text', header, x,      y),
            mkEle('text', str,    x + 30, y + LINE_HEIGHT, RED)
        }
    end
end

function Skill:treeToIcon()
    return str_to_icon[self.tree_id]
end

function mkLine(n)
    local size = n * 2 - 1
    local shape = {}
    for i = 1, size do
        local row = {}
        for j = 1, size do
            if i <= n and j == n then
                table.insert(row, T)
            else
                table.insert(row, F)
            end
        end
        table.insert(shape, row)
    end
    return shape
end

-- Create new stats based on original stats, plus stat boosting/lowering
-- effects and assists on the sprite
function mkTmpAttrs(bases, effects, assists)

    -- Retrieve buffs and collect buff owners (for xp gain)
    local buffs = {}
    local helpers = {}
    for i = 1, #assists do
        local a = assists[i]
        table.insert(buffs, a)
        for j = 1, #a.xp_tags do
            local tag = a.xp_tags[j]
            if not helpers[a.owner:getId()] then
                helpers[a.owner:getId()] = {}
            end
            helpers[a.owner:getId()][tag] = true
        end
    end
    for i = 1, #effects do table.insert(buffs, effects[i].buff) end

    -- Make attrs
    local tmp_attrs = {}
    for k, v in pairs(bases) do tmp_attrs[k] = v end
    for i = 1, #buffs do
        local a = buffs[i].attr
        if tmp_attrs[a] then
            tmp_attrs[a] = tmp_attrs[a] + buffs[i].val
        end
    end

    -- No negative attributes
    for k,v in pairs(tmp_attrs) do
        tmp_attrs[k] = math.max(0, tmp_attrs[k])
    end
    return tmp_attrs, helpers
end

-- Create a buff, given an attribute set, the buffed stat, and buff scaling
function mkBuff(attrs, template, sp, exp_tag)
    if template[1] == 'special' then
        return Buff:new(template[1], template[2], template[3], sp, exp_tag)
    else
        local s = template[2]
        local ty = ite(s.mul > 0 or (s.mul == 0 and s.base >= 0), BUFF, DEBUFF)
        local val = attrs[s.attr] * s.mul
        val = s.base + ite(val < 0, math.ceil(val), math.floor(val))
        return Buff:new(template[1], val, ty, sp, exp_tag)
    end
end

-- Add effect to a sprite's status effects, maintaining rendering order
function addStatus(stat, eff)
    local spc = function(e) return e.buff.attr == 'special' end
    local dur = function(e) return e.duration               end

    local f = false
    for i = 1, #stat do
        local st = stat[i]
        if spc(eff) and not spc(st) then                              f = true
        elseif spc(eff) and spc(st) and dur(eff) >= dur(st) then      f = true
        elseif not (spc(eff) or spc(st)) and dur(eff) >= dur(st) then f = true
        end
        if f then
            table.insert(stat, i, eff)
            return
        end
    end
    table.insert(stat, eff)
end

-- Determine whether the status effects on a character include a given special
function hasSpecial(stat, ass, spec)
    for i = 1, #stat do
        if stat[i].buff.attr == 'special' and stat[i].buff.val == spec then
            return true
        end
    end
    for i = 1, #ass do
        if ass[i].attr == 'special' and ass[i].val == spec then
            return true
        end
    end
    return false
end

function isDebuffed(sp, stat)
    local es = stat[sp:getId()]['effects']
    for i = 1, #es do if es[i].buff.type == DEBUFF then return true end end
    return false
end

skills = {


    -- ABELON
    ['sever'] = Skill:new('sever', 'Sever',
        "Slice at an enemy's exposed limbs. Deals (Force * 1.0) Weapon damage \z
         to an enemy next to you and lowers their Force by 3.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_RELATIVE, str_to_icon['force'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.0),
        nil, { { { 'force', Scaling:new(-3) }, 1 } }
    ),
    ['trust'] = Skill:new('trust', 'Trust',
        "Place your faith in your comrades. Increases your Affinity by 8 \z
         for 1 turn.",
        'Veteran', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Demon', 0 }, { 'Veteran', 1 }, { 'Executioner', 0 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'affinity', Scaling:new(8) }, 1 } }
    ),
    ['punish'] = Skill:new('punish', 'Punish',
        "Exploit a brief weakness with a precise stab. Deals 10 + (Force * \z
         1.0) Weapon damage only if the enemy is impaired or debuffed.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Demon', 0 }, { 'Veteran', 1 }, { 'Executioner', 1 } },
        { { F, F, F },
          { T, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(10, 'force', 1.0),
        nil, nil, nil,
        { ['br'] = function(a, a_a, b, b_a, st) return isDebuffed(b, st) end }
    ),
    ['pursuit'] = Skill:new('pursuit', 'Pursuit',
        "Give chase. Gain (Agility * 0.5) Force and (Force * 0.5) Agility \z
         for 2 turns.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['agility'], -- GRID
        { { 'Demon', 2 }, { 'Veteran', 3 }, { 'Executioner', 3 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'force', Scaling:new(0, 'agility', 0.5) }, 2 }, 
               { { 'agility', Scaling:new(0, 'force', 0.5) }, 2 } }
    ),
    ['siphon'] = Skill:new('siphon', 'Siphon',
        "Strike an evil, life draining blow. Deals \z
         (Force * 1.0) Weapon damage to an adjacent enemy and \z
         heals you for the damage dealt.",
        'Demon', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Demon', 2 }, { 'Veteran', 0 }, { 'Executioner', 3 } },
        { { T } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 1.0),
        nil, nil, nil,
        { ['lifesteal'] = 1 }
    ),
    ['gambit'] = Skill:new('gambit', 'Gambit',
        "Attack relentlessly. Deals 40 Weapon damage to an adjacent enemy, \z
         but lowers your Affinity and Agility to 0 for 1 turn.",
        'Veteran', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- RELATIVE
        { { 'Demon', 3 }, { 'Veteran', 5 }, { 'Executioner', 3 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(40),
        { { { 'affinity', Scaling:new(-99) }, 1 }, 
          { { 'agility',  Scaling:new(-99) }, 1 } }, nil
    ),
    ['execute'] = Skill:new('execute', 'Execute',
        "Fulfill your duty. Deals (Force * 2.0) Weapon damage \z
         to an adjacent enemy with less than half of their health \z
         remaining.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 4 } },
        { { T } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 2.0),
        nil, nil, nil,
        {
            ['br'] = function(a, a_a, b, b_a, st)
                return b.health < b_a['endurance']
            end
        }
    ),
    ['conflagration'] = Skill:new('conflagration', 'Conflagration',
        "Scour the battlefield with unholy fire. Deals 30 Spell \z
         damage to all enemies in a line across the entire field.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_GRID, str_to_icon['empty'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        mkLine(10), DIRECTIONAL_AIM, 5,
        ENEMY, Scaling:new(30)
    ),
    ['clutches'] = Skill:new('clutches', 'Clutches',
        "Pull an enemy to you, dealing (Force * 0.5) Spell damage and \z
         reducing the enemy's Reaction by (Force * 0.2) for 2 turns.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Demon', 1 }, { 'Veteran', 0 }, { 'Executioner', 1 } },
        { { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(0, 'force', 0.5),
        nil, { { { 'reaction', Scaling:new(0, 'force', -0.2) }, 2 } },
        { DOWN, 2 }
    ),
    ['judgement'] = Skill:new('judgement', 'Judgement',
        "Instantly kill an enemy anywhere on the field with less than 10 \z
         health remaining.",
        'Executioner', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Demon', 2 }, { 'Veteran', 0 }, { 'Executioner', 2 } },
        { { T } }, FREE_AIM(100), 1,
        ENEMY, Scaling:new(1000),
        nil, nil, nil,
        { ['br'] = function(a, a_a, b, b_a, st) return b.health <= 10 end }
    ),
    ['contempt'] = Skill:new('contempt', 'Contempt',
        "Glare with an evil eye lit by ignea, reducing the Force of \z
         affected enemies by (Focus * 0.5) for 2 turns.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['focus'], -- RELATIVE
        { { 'Demon', 2 }, { 'Veteran', 2 }, { 'Executioner', 0 } },
        { { F, T, F, T, F },
          { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, nil,
        nil, { { { 'force', Scaling:new(0, 'focus', -0.5) }, 2 } }
    ),
    ['crucible'] = Skill:new('crucible', 'Crucible',
        "Unleash a scorching ignaeic miasma. You and nearby enemies suffer \z
         (Force * 2.0) Spell damage (cannot kill you).",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- GRID
        { { 'Demon', 4 }, { 'Veteran', 0 }, { 'Executioner', 4 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, T, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 8,
        ENEMY, Scaling:new(0, 'force', 2.0),
        nil, nil, nil,
        { ['self'] = true }
    ),
    ['guard_blindspot'] = Skill:new('guard_blindspot', 'Guard Blindspot',
        "Protect an adjacent ally from wounds to the back. Adds \z
         (Affinity * 0.5) to the assisted ally's Reaction.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_GRID, str_to_icon['affinity'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'affinity', 0.5) } }, { EXP_TAG_RECV }
    ),
    ['inspire'] = Skill:new('inspire', 'Inspire',
        "Inspire an ally with a courageous cry. They gain (Affinity * 1.0) \z
         Force and Affinity, and (Affinity * 0.5) Reaction.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Demon', 1 }, { 'Veteran', 2 }, { 'Executioner', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        {
            { 'force',    Scaling:new(0, 'affinity', 1.0) },
            { 'affinity', Scaling:new(0, 'affinity', 1.0) },
            { 'reaction', Scaling:new(0, 'affinity', 0.5) }
        }, { EXP_TAG_ATTACK, EXP_TAG_RECV, EXP_TAG_ASSIST }
    ),
    ['confidence'] = Skill:new('confidence', 'Confidence',
        "Fill allies with reckless confidence. They gain \z
        (Affinity * 1.0) Force, but lose 6 Reaction \z
         and Affinity.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Demon', 2 }, { 'Veteran', 3 }, { 'Executioner', 1 } },
        { { T, T, T, T, T },
          { T, T, T, T, T },
          { T, T, F, T, T },
          { T, T, T, T, T },
          { T, T, T, T, T } }, SELF_CAST_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        {
            { 'force',    Scaling:new(0,  'affinity', 1.0) },
            { 'reaction', Scaling:new(-6, 'affinity',   0) },
            { 'affinity', Scaling:new(-6, 'affinity',   0) }
        }, { EXP_TAG_ATTACK }
    ),
    ['flank'] = Skill:new('flank', 'Flank',
        "Prepare to surround and overwhelm an enemy. Ally \z
         attacks will reduce enemy Reaction by 6 for 1 turn.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Demon', 0 }, { 'Veteran', 4 }, { 'Executioner', 2 } },
        { { F, T, F },
          { T, F, T },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'special', 'flanking', BUFF } }, { EXP_TAG_ATTACK }
    ),



    -- KATH
    ['sweep'] = Skill:new('sweep', 'Sweep',
        "Slash in a wide arc. Deals (Force * 0.8) Weapon damage to enemies in \z
         front of Kath, and grants 2 Reaction for 1 turn.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { F, F, F },
          { T, T, T },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 0.8),
        { { { 'reaction', Scaling:new(2) }, 1 } }, nil
    ),
    ['stun'] = Skill:new('stun', 'Stun',
        "A blunt lance blow. Deals (Force * 0.5) Weapon damage. If Kath's \z
         Reaction is higher than his foe's, they cannot act for 1 turn.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['reaction'], -- RELATIVE
        { { 'Defender', 1 }, { 'Hero', 1 }, { 'Cleric', 0 } },
        { { T } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 0.5),
        nil, { { { 'special', 'stun', DEBUFF }, 1 } }, nil,
        { ['br'] = function(a, a_a, b, b_a, st)
            return a_a['reaction'] > b_a['reaction'] end
        }
    ),
    ['shove'] = Skill:new('shove', 'Shove',
        "Kath shoves an ally or enemy, moving them by 1 tile and raising \z
         Kath's Reaction by 3 for 1 turn.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- RELATIVE
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { F, F, F },
          { F, T, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ALL, nil,
        { { { 'reaction', Scaling:new(3) }, 1 } }, nil, 
        { UP, 1 }
    ),
    ['javelin'] = Skill:new('javelin', 'Javelin',
        "Kath hurls a javelin at an enemy, dealing (Force * 1.2) Weapon \z
         damage.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 0 }, { 'Hero', 1 }, { 'Cleric', 0 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.2)
    ),
    ['thrust'] = Skill:new('thrust', 'Thrust',
        "Kath throws his body into a thrust, dealing (Force * 1.0) Weapon \z
         damage to up to 2 enemies in a line.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 0 }, { 'Hero', 3 }, { 'Cleric', 0 } },
        { { F, T, F },
          { F, T, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.0)
    ),
    ['enrage'] = Skill:new('enrage', 'Enrage',
        "Enrage nearby enemies with an ignaeic fog, so that their next \z
         actions will target Kath (whether or not they can reach him).",
        'Defender', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Defender', 3 }, { 'Hero', 2 }, { 'Cleric', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, F, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 1,
        ENEMY, nil,
        nil, { { { 'special', 'enrage', DEBUFF }, 1 } }
    ),
    ['healing_mist'] = Skill:new('healing_mist', 'Healing Mist',
        "Infuse the air to close wounds. Allies in the area recover \z
         (Affinity * 1.0) health. Can target a square within 3 spaces of \z
         Kath.",
        'Cleric', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { T, T, T },
          { T, T, T },
          { T, T, T } }, FREE_AIM(3), 1,
        ALLY, Scaling:new(0, 'affinity', -1.0)
    ),
    ['haste'] = Skill:new('haste', 'Haste',
        "Kath raises the Agility of allies around him by 4 for 2 turns.",
        'Cleric', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Defender', 1 }, { 'Hero', 0 }, { 'Cleric', 2 } },
        { { F, F, T, F, F },
          { F, F, T, F, F },
          { T, T, F, T, T },
          { F, F, T, F, F },
          { F, F, T, F, F } }, SELF_CAST_AIM, 1,
        ALLY, nil,
        nil, { { { 'agility', Scaling:new(4) }, 2 } }
    ),
    ['storm_thrust'] = Skill:new('storm_thrust', 'Storm Thrust',
        "Kath launches a thrust powered by lightning, dealing (Force * 1.0) \z
         Spell damage to up to 4 enemies in a line.",
        'Hero', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 0 }, { 'Hero', 5 }, { 'Cleric', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 1.0)
    ),
    ['caution'] = Skill:new('caution', 'Caution',
        "Kath enters a defensive stance, raising his Reaction by 4 and \z
         lowering his Force by 2 for 5 turns.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Defender', 3 }, { 'Hero', 0 }, { 'Cleric', 2 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil, nil,
        { { { 'reaction', Scaling:new(4) }, 5 }, { { 'force', Scaling:new(-2) }, 5 } }
    ),
    ['sacrifice'] = Skill:new('sacrifice', 'Sacrifice',
        "Kath transfers his vitality, losing 10 Reaction for 1 turn \z
         to restore 10 + (Force * 1.0) health to nearby allies.",
        'Cleric', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 0 }, { 'Hero', 3 }, { 'Cleric', 3 } },
        { { F, T, F },
          { T, F, T },
          { F, T, F } }, SELF_CAST_AIM, 1,
        ALLY, Scaling:new(-10, 'force', -1.0),
        { { { 'reaction', Scaling:new(-10) }, 1 } }, nil, nil
    ),
    ['bond'] = Skill:new('bond', 'Bond',
        "Kath ignites a bond, raising his and an ally's \z
         Affinity by (Force * 0.5) for 3 turns. Can target any \z
         ally within 3 tiles.",
        'Hero', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- GRID
        { { 'Defender', 0 }, { 'Hero', 3 }, { 'Cleric', 3 } },
        { { T } }, FREE_AIM(3), 2,
        ALLY, nil,
        { { { 'affinity', Scaling:new(0, 'force', 0.5) }, 3 } },
        { { { 'affinity', Scaling:new(0, 'force', 0.5) }, 3 } },
        nil
    ),
    ['great_javelin'] = Skill:new('great_javelin', 'Great Javelin',
        "Kath catapults an empowered javelin which deals (Force * 2.0) \z
         Weapon Damage and pushes the enemy back 2 tiles.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 4 }, { 'Hero', 6 }, { 'Cleric', 0 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 3,
        ENEMY, Scaling:new(0, 'force', 2.0), nil, nil, { UP, 2 }
    ),
    ['great_sweep'] = Skill:new('great_sweep', 'Great Sweep',
        "Kath swings an ignaeic crescent which deals (Force * 1.0) \z
         Weapon Damage and grants 5 Reaction for 1 turn.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Defender', 5 }, { 'Hero', 4 }, { 'Cleric', 0 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, T, F, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, F, T, T, T },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 3,
        ENEMY, Scaling:new(0, 'force', 1.0),
        { { { 'reaction', Scaling:new(5) }, 1 } }, nil

    ),
    ['forbearance'] = Skill:new('forbearance', 'Forbearance',
        "Kath receives all attacks meant for an adjacent assisted ally.",
        'Defender', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['endurance'], -- GRID
        { { 'Defender', 2 }, { 'Hero', 1 }, { 'Cleric', 1 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'special', 'forbearance', BUFF } }, { EXP_TAG_RECV }
    ),
    ['invigorate'] = Skill:new('invigorate', 'Invigorate',
        "Kath renews allies near him with a cantrip. Allies on the assist gain \z
         (Affinity * 1.0) Force.",
        'Cleric', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Defender', 0 }, { 'Hero', 1 }, { 'Cleric', 1 } },
        { { T, F, T },
          { F, F, F },
          { T, F, T } }, SELF_CAST_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'force', Scaling:new(0, 'affinity', 1.0) } }, { EXP_TAG_ATTACK }
    ),
    ['hold_the_line'] = Skill:new('hold_the_line', 'Hold the Line',
        "Kath forms a wall with his allies, raising the Reaction of assisted \z
         allies by (Reaction * 0.5).",
        'Hero', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['reaction'], -- GRID
        { { 'Defender', 2 }, { 'Hero', 2 }, { 'Cleric', 0 } },
        mkLine(10), DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'reaction', 0.5) } }, { EXP_TAG_RECV }
    ),
    ['guardian_angel'] = Skill:new('guardian_angel', 'Guardian Angel',
        "Kath casts a powerful protective ward. Allies on the assist cannot \z
         drop below 1 health.",
        'Cleric', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Defender', 4 }, { 'Hero', 0 }, { 'Cleric', 4 } },
        { { F, F, T, T, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 3,
        nil, nil, nil, nil, nil, nil,
        { { 'special', 'guardian_angel', BUFF } }, { EXP_TAG_RECV }
    ),
    ['steadfast'] = Skill:new('steadfast', 'Steadfast',
        "Kath helps allies fortify their positions. Allies on the assist \z
         lose all Agility but gain (Affinity * 1.0) Reaction.",
        'Defender', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Defender', 4 }, { 'Hero', 3 }, { 'Cleric', 2 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F } }, DIRECTIONAL_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        { 
            { 'agility', Scaling:new(-99) }, 
            { 'reaction', Scaling:new(0, 'affinity', 1.0) }
        }, { EXP_TAG_RECV }
    ),


    -- ELAINE
    ['hunting_shot'] = Skill:new('hunting_shot', 'Hunting Shot',
        "Elaine shoots from close range as though hunting, \z
         dealing 12 + (Force * 0.5) Weapon damage.",
        'Huntress', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Huntress', 1 }, { 'Apprentice', 0 }, { 'Sniper', 1 } },
        { { F, F, F },
          { T, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(12, 'force', 0.5)
    ),
    ['lay_traps'] = Skill:new('lay_traps', 'Lay Traps',
        "Elaine anticipates foes in her path and sets traps to reduce their \z
         Reaction by (Reaction * 1.0) for 2 turn.",
        'Huntress', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['reaction'], -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 1 }, { 'Sniper', 0 } },
        { { F, F, F, F, F },
          { F, T, T, T, F },
          { F, T, T, T, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, nil,
        nil, { { { 'reaction', Scaling:new(0, 'reaction', -1.0) }, 2 } }
    ),
    ['butcher'] = Skill:new('butcher', 'Butcher',
        "Elaine expertly carves up an adjacent enemy with her hunting knife, \z
         dealing 30 Weapon damage.",
        'Huntress', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- RELATIVE
        { { 'Huntress', 4 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(30)
    ),
    ['precise_shot'] = Skill:new('precise_shot', 'Precise Shot',
        "Elaine takes careful aim to hit a faraway target with an arrow, \z
         dealing 2 + (Force * 1.0) Weapon damage.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(2, 'force', 1.0)
    ),
    ['volley'] = Skill:new('volley', 'Volley',
        "Elaine rapidly fires arrows across the field to stagger foes, \z
         dealing (Force * 0.8) Weapon damage to each target.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Huntress', 1 }, { 'Apprentice', 0 }, { 'Sniper', 2 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, F, T, F, F },
          { F, T, F, F, F, T, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 0.8)
    ),
    ['piercing_arrow'] = Skill:new('piercing_arrow', 'Piercing Arrow',
        "Elaine shoots with such strength as to pierce through enemies, \z
         dealing (Force * 1.0) Weapon damage to all targets.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 1 }, { 'Sniper', 3 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, T },
          { F, F, F, F, F, T, F },
          { F, F, F, F, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(0, 'force', 1)
    ),
    ['deadeye'] = Skill:new('deadeye', 'Deadeye',
        "Elaine aims an impossible shot after a heavy draw, \z
         dealing (Force * 1.5) Weapon damage and pushing the target 1 tile.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 4 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.5), nil, nil, { UP, 1 }
    ),
    ['observe'] = Skill:new('observe', 'Observe',
        "Once per battle, Elaine chooses an ally to learn from, permanently \z
         gaining 1 point in their signature attribute.",
        'Apprentice', WEAPON, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { T } }, FREE_AIM(100), 0,
        ALLY, nil,
        { { { 'special', 'observe', BUFF }, math.huge } }, nil, nil,
        { ['and'] =
            function(a, a_a, b, b_a, st)
                best_attr = nil
                hi = 0
                if b:getId() == 'kath' then
                    best_attr = 'reaction'
                else
                    for k,v in pairs(b.attributes) do
                        if v > hi then
                            hi = v
                            best_attr = k
                        end
                    end
                end
                a.attributes[best_attr] = a.attributes[best_attr] + 1
            end
        }
    ),
    ['snare'] = Skill:new('snare', 'Snare',
        "Elaine swiftly lays a magical hunting snare, reducing a nearby foe's \z
         Agility by 4 + (Agility * 0.5) for 1 turn.",
        'Huntress', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['agility'], -- RELATIVE
        { { 'Huntress', 3 }, { 'Apprentice', 2 }, { 'Sniper', 0 } },
        { { F, F, F },
          { T, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, nil,
        nil, { { { 'agility', Scaling:new(-4, 'agility', -0.5) }, 1 } }
    ),
    ['ignea_arrowheads'] = Skill:new('ignea_arrowheads', 'Ignea Arrowheads',
        "Elaine fashions arrowheads from Ignea and charges them with magic, \z
         increasing her Force by 2 + (Focus * 1.0) for 4 turns.",
        'Apprentice', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['focus'], -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 1 }, { 'Sniper', 1 } },
        { { T } }, SELF_CAST_AIM, 1,
        ALLY, nil,
        nil, { { { 'force', Scaling:new(2, 'focus', 1.0) }, 4 } }
    ),
    ['wind_blast'] = Skill:new('wind_blast', 'Wind Blast',
        "Elaine conjures a concussive gust of wind to blow an enemy back \z
         3 tiles.",
        'Apprentice', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- RELATIVE
        { { 'Huntress', 1 }, { 'Apprentice', 2 }, { 'Sniper', 0 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, nil,
        nil, nil, { UP, 3 }
    ),
    ['exploding_shot'] = Skill:new('exploding_shot', 'Exploding Shot',
        "Elaine primes a chunk of Ignea to explode and ties it to an arrow, \z
         dealing (Force * 1.2) Spell damage to all foes hit.",
        'Apprentice', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 2 }, { 'Sniper', 2 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 4,
        ENEMY, Scaling:new(0, 'force', 1.2)
    ),
    ['seeking_arrow'] = Skill:new('seeking_arrow', 'Seeking Arrow',
        "Elaine enchants an arrow to hunt down a target, firing at any foe \z
         within 8 tiles to deal 20 + (Force * 0.5) Spell damage.",
        'Sniper', SPELL, MANUAL, SKILL_ANIM_NONE, str_to_icon['force'], -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 2 }, { 'Sniper', 3 } },
        { { T } }, FREE_AIM(8), 3,
        ENEMY, Scaling:new(20, 'force', 0.5)
    ),
    ['terrain_survey'] = Skill:new('terrain_survey', 'Terrain Survey',
        "Elaine surveys the field and how to navigate it. Allies on the \z
         assist share her knowledge and gain (Affinity * 0.5) Agility.",
        'Huntress', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'agility', Scaling:new(0, 'affinity', 0.5) } }, { EXP_TAG_MOVE }
    ),
    ['camouflage'] = Skill:new('camouflage', 'Camouflage',
        "Elaine builds a makeshift camouflaged shelter. The assisted ally \z
         will not be directly targeted by enemies.",
        'Huntress', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 2 }, { 'Sniper', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'special', 'hidden', BUFF } }, {} -- TODO: implement hidden
    ),
    ['harmonize'] = Skill:new('harmonize', 'Harmonize',
        "Elaine channels her power into Ignea and projects it outwards. \z
         Allies on the assist take on Elaine's attributes.",
        'Apprentice', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['empty'], -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 3 }, { 'Sniper', 0 } },
        { { F, F, T, F, F },
          { F, F, F, F, F },
          { T, F, F, F, T },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        { { 'special', 'harmony', BUFF } }, -- TODO: change this
        { EXP_TAG_ATTACK, EXP_TAG_RECV, EXP_TAG_MOVE }
    ),
    ['flight'] = Skill:new('flight', 'Flight',
        "Elaine whips the wind into currents, letting allies fly. They gain \z
         (Affinity * 1.0) Agility and can move through foes.",
        'Apprentice', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 4 }, { 'Sniper', 0 } },
        { { F, T, F },
          { T, F, T },
          { F, T, F } }, SELF_CAST_AIM, 4,
        nil, nil, nil, nil, nil, nil,
        {
            { 'special', 'flight', BUFF }, -- TODO: implement flight
            { 'agility', Scaling:new(0, 'affinity', 1.0) }
        }, { EXP_TAG_MOVE }
    ),
    ['farsight'] = Skill:new('farsight', 'Farsight',
        "Elaine extends her superior perception to those nearby, granting \z
         assisted allies 2 + (Affinity * 0.5) Reaction.",
        'Sniper', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 2 }, { 'Sniper', 1 } },
        { { T, T, T, T, T },
          { T, F, F, F, T },
          { T, F, F, F, T },
          { T, F, F, F, T },
          { T, T, T, T, T } }, SELF_CAST_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(2, 'affinity', 0.5) } }, { EXP_TAG_RECV }
    ),
    ['cover_fire'] = Skill:new('cover_fire', 'Cover Fire',
        "Elaine lays down a hail of arrows around an ally position, granting \z
         them the advantage and (Affinity * 0.5) Reaction and Force.",
        'Sniper', ASSIST, MANUAL, SKILL_ANIM_NONE, str_to_icon['affinity'], -- GRID
        { { 'Huntress', 1 }, { 'Apprentice', 0 }, { 'Sniper', 1 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        {
            { 'reaction', Scaling:new(0, 'affinity', 0.5) },
            { 'force', Scaling:new(0, 'affinity', 0.5) },
        }, { EXP_TAG_ATTACK, EXP_TAG_RECV }
    ),


    -- ENEMY
    ['bite'] = Skill:new('bite', 'Bite',
        "Leap at an adjacent enemy and bite into them. Deals \z
         (Force * 1.0) Weapon damage to an enemy next to the user.",
        'Enemy', WEAPON, KILL, SKILL_ANIM_NONE, str_to_icon['force'], -- RELATIVE
        {},
        { { T } }, DIRECTIONAL_AIM, 0,
        ALLY, Scaling:new(0, 'force', 1.0)
    )
}
