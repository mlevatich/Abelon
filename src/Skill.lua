require 'src.Util'
require 'src.Constants'

require 'src.Menu'

Scaling = class('Scaling')

function Scaling:initialize(base, attr, mul)
    self.base = base
    self.attr = ite(attr, attr, 'force')
    self.mul  = ite(mul, mul, 0)
end

function Scaling:none()
    return self.base == 0 and self.mul == 0
end

Buff = class('Buff')

function Buff:initialize(attr, val, ty, owner, xp_tags, value_hidden, ty_fixed)
    self.attr     = attr
    self.val      = val
    self.type     = ty
    self.owner    = owner
    self.ty_fixed = ite(ty_fixed, true, false)
    self.hide_val = ite(value_hidden, true, false)
    self.xp_tags  = ite(xp_tags ~= nil, xp_tags, {})
end

function Buff:copy()
    return Buff:new(
        self.attr, self.val, self.type, self.owner, self.xp_tags, self.hide_val, self.ty_fixed
    )
end

function Buff:toStr()
    local name = EFFECT_NAMES[self.attr]
    if self.val == 0 then
        return ite(isSpecial(self.attr), name, nil)
    elseif self.hide_val then
        return name
    end
    return ite(self.val > 0, '+', '-') .. abs(self.val) .. name
end

Effect = class('Effect')

function Effect:initialize(buff, dur, hidden)
    self.buff     = buff
    self.duration = dur
    self.hidden   = ite(hidden, true, false)
end

function Effect:copy()
    return Effect:new(self.buff:copy(), self.duration, self.hidden)
end

Skill = class('Skill')

function Skill:initialize(id, n, alt_anim, alt_sfx, desc, ti, st, prio, anim_type, tr, r, at, c,
                          affects, scaling, sp_effects, ts_effects, ts_displace,
                          modifiers, buff_templates, owner_exp_when)

    -- Identifying info
    self.id           = id
    self.name         = n
    self.tree_id      = ti
    self.type         = st
    self.prio         = prio
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

    -- Keys for the animation and sound effects for this skill
    self.anim = self.id
    self.sfx = self.id
    if alt_anim then self.anim = alt_anim end
    if alt_sfx then self.sfx = alt_sfx end

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

function Skill:getCost(sp_specials)
    local cost_mod = sp_specials['ignea_efficiency']
    return math.max(0, self.cost + ite(cost_mod, cost_mod, 0))
end

function Skill:use(a, b, c, d, e, f, g, h)
    if self.type == ASSIST then return self:assist(a, b, c, d)
    else                        return self:attack(a, b, c, d, e, f, g, h)
    end
end

function Skill:hits(caster, target, t_team)
    local oppo_team = ite(t_team == ALLY, ENEMY, ALLY)
    return (self.type == ASSIST and t_team == ALLY)
        or (self.type ~= ASSIST and oppo_team ~= self.affects)
        or (caster == target and self.modifiers['self'])
end

function Skill:assist(attrs, specials, dryrun, sp)

    -- Spend ignea
    if not dryrun then
        sp.ignea = sp.ignea - self:getCost(specials)
        assert(sp.ignea >= 0)
    end

    -- Assemble buffs
    local buffs = {}
    for i = 1, #self.buff_templates do
        local exp_tag = ite(i == 1, self.owner_exp_when, {})
        table.insert(buffs, mkBuff(attrs, self.buff_templates[i], specials, sp, exp_tag))
    end
    return buffs
end

function Skill:attack(sp, sp_assists, ts, ts_assists, atk_dir, status, grid, dryrun)

    -- Bring upvalues into scope
    local dmg_type = self.dmg_type
    local scaling = self.scaling
    local sp_effects = self.sp_effects
    local ts_effects = self.ts_effects
    local ts_displace = self.ts_displace
    local modifiers = self.modifiers

    -- Who was moved/hurt/killed/counters by this attack?
    local moved = {}
    local hurt = {}
    local dead = {}
    local counters = {}

    -- Levelups gained by each sprite
    local exp_gain = { [sp:getId()] = 0 }

    -- Temporary attributes and special effects for the caster
    local sp_team = status[sp:getId()]['team']
    local sp_stat = status[sp:getId()]['effects']
    local sp_tmp_attrs, sp_helpers, sp_specials = mkTmpAttrs(sp.attributes, sp_stat, sp_assists)

    -- Spend ignea
    if not dryrun then
        sp.ignea = sp.ignea - self:getCost(sp_specials)
        assert(sp.ignea >= 0)
    end

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
        local t_tmp_attrs, t_helpers, t_specials = mkTmpAttrs(t.attributes, t_stat, t_ass)

        -- If attacker is an enemy and target has forbearance, the target
        -- switches to Kath
        if t_specials['forbearance']
        and sp_team == ENEMY then
            local s_kath = status['kath']
            local loc = s_kath['location']
            if s_kath['inbattle'] then
                t = s_kath['sp']
                t_stat = s_kath['effects']
                t_ass = grid[loc[2]][loc[1]].assists
                t_tmp_attrs, t_helpers, t_specials = mkTmpAttrs(t.attributes, t_stat, t_ass)
            end
        end

        -- Only hit targets passing the team filter
        local dealt = 0
        if self:hits(sp, t, t_team) then

            -- Dryrun just computes results, doesn't deal damage or apply effects
            dryrun_res[z] = {
                ['sp'] = t,
                ['flat'] = 0,
                ['flat_ignea'] = 0,
                ['percent'] = 0,
                ['new_stat'] = t_stat,
                ['died'] = false
            }

            -- Some modifiers prevent a target from taking damage
            -- except under special circumstances
            if not modifiers['br']
            or modifiers['br'](sp, sp_tmp_attrs, t, t_tmp_attrs, status) then

                -- If there's no scaling, the attack does no damage
                if scaling or modifiers['dmg'] then

                    -- Compute damage or healing (MUST be a SPELL to heal)
                    local atk = 0
                    if scaling then
                        local attr = scaling.attr
                        if sp_specials['inversion'] then
                            if attr == 'force' then attr = 'affinity' elseif attr == 'affinity' then attr = 'force' end
                        end
                        atk = atk + scaling.base + math.floor(sp_tmp_attrs[attr] * scaling.mul)
                    end
                    if modifiers['dmg'] then
                        atk = atk + modifiers['dmg'](sp, sp_tmp_attrs, t, t_tmp_attrs, status)
                    end
                    local dmg = atk
                    if dmg_type == WEAPON then
                        local def = math.floor(t_tmp_attrs['reaction'])
                        dmg = math.max(0, atk - def)
                    end
                    if t_specials['noheal'] and dmg < 0 then
                        dmg = 0
                    end

                    -- If the target is warded, they take no spell damage (but can still be healed)
                    if t_specials['ward'] and dmg_type == SPELL then
                        dmg = math.min(dmg, 0)
                    end

                    -- If this is a self hit or the target has guardian angel
                    -- they can't die
                    local min = 0
                    if (t == sp and modifiers['self']) or t_specials['guardian_angel'] then
                        min = 1
                    end

                    -- Deal damage or healing
                    local max_hp = t_tmp_attrs['endurance'] * 2
                    local pre_hp = t.health
                    local n_hp = math.max(min, math.min(max_hp, t.health - dmg))
                    dealt = pre_hp - n_hp
                    total_dealt = total_dealt + dealt
                    if not dryrun then
                        t.health = n_hp
                    end

                    dryrun_res[z]['flat'] = dealt
                    dryrun_res[z]['percent'] = dealt / pre_hp

                    -- Band-aid for demo: Terror should de-prioritize Shanti when using Eldritch Gaze.
                    -- (unless it can kill her)
                    if self.id == 'the_eye' and t_specials['busy'] and dryrun_res[z]['percent'] ~= 1 then
                        dryrun_res[z]['percent'] = 0
                    end

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
                if sp_specials['flanking'] then
                    table.insert(ts_effects, { { 'reaction', Scaling:new(sp_specials['flanking']) }, 1 })
                    table.insert(ts_effects, { { 'agility', Scaling:new(-4) }, 1 })
                end
                if sp_specials['poison_coat'] and dmg_type == WEAPON then
                    table.insert(ts_effects, { { 'force', Scaling:new(sp_specials['poison_coat']) }, 1 })
                end
                for j = 1, #ts_effects do
                    local b = mkBuff(sp_tmp_attrs, ts_effects[j][1], sp_specials)
                    addStatus(t_stat, Effect:new(b, ts_effects[j][2], ts_effects[j][3]))

                    -- Allies gain exp for applying negative status to enemies
                    -- or applying positive statuses to allies
                    local exp = 0
                    if ((b.type == DEBUFF and sp_team == ALLY and t_team == ENEMY)
                    or (b.type == BUFF and sp_team == ALLY and t_team == ALLY)) and not ts_effects[j][3]
                    then
                        exp = EXP_ON_SPECIAL
                        if not isSpecial(b.attr) then exp = abs(b.val) end
                    end
                    status_xp = math.min(status_xp + exp, EXP_STATUS_MAX)
                end
                dryrun_res[z]['new_stat'] = t_stat

                -- Compute x/y displacement tile based on direction and grid state
                -- Only record if displacement is non-zero
                local nomove = t_specials['busy'] or t_specials['unconscious'] or t_specials['injured']
                if #ts_displace > 0 and not nomove then
                    
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
                if not dryrun and not nomove then
                    if abs(t.x - sp.x) > TILE_WIDTH / 2 then
                        t.dir = ite(t.x > sp.x, LEFT, RIGHT)
                    end
                end

                -- Additional effects given by the 'and' modifier
                if modifiers['and'] then
                    modifiers['and'](sp, sp_tmp_attrs, t, t_tmp_attrs, status, dryrun, dryrun_res[z])
                end

                z = z + 1
            end

            -- Registering counters
            if t_team ~= sp_team then
                if t_specials['riposte'] or t_specials['martyr'] then
                    if dmg_type == WEAPON then
                        local already = false
                        for h=1,#counters do
                            if counters[h][1] == t then already = true end
                        end
                        if not already then -- Kath can't counter an AoE attack twice via forbearance
                            table.insert(counters, { t, ite(t_specials['riposte'], 'riposte', 'martyr'), 0 } )
                        end
                    end
                elseif t_specials['retribution'] then
                    if dealt > 0 then
                        table.insert(counters, { t, 'retribution', dealt } )
                    end
                end
            end
        end
    end

    -- Affect caster
    if dryrun then
        sp_stat = copy(sp_stat)
    end

    sp_effects = copy(sp_effects)
    if #dead > 0 then
        if sp_specials['spelltheft'] then
            local recovered = math.min(sp.attributes['focus'] - sp.ignea, 3)
            -- TODO: dryrun_res['caster'] doesn't exist here. Need to merge logic with line 499 so multiple flat_ignea values don't overwrite each other
            dryrun_res['caster']['flat_ignea'] = -recovered
            if not dryrun then
                sp.ignea = sp.ignea + recovered
            end
        end
        if sp_specials['overrun'] then
            table.insert(sp_effects, { { 'affinity', Scaling:new(sp_specials['overrun']) }, 1 })
            table.insert(sp_effects, { { 'agility', Scaling:new(sp_specials['overrun']) }, 1 })
        end
    end

    for j = 1, #sp_effects do
        local b = mkBuff(sp_tmp_attrs, sp_effects[j][1], sp_specials)
        addStatus(sp_stat, Effect:new(b, sp_effects[j][2], sp_effects[j][3]))

        -- Allies gain exp for applying positive status to themselves
        local exp = 0
        if b.type == BUFF and sp_team == ALLY and not sp_effects[j][3] then
            exp = EXP_ON_SPECIAL
            if not isSpecial(b.attr) then exp = abs(b.val) end
        end
        status_xp = math.min(status_xp + exp, EXP_STATUS_MAX)
    end

    -- Set lifesteal
    local lifesteal = 0
    if sp_specials['lifesteal'] then lifesteal = sp_specials['lifesteal'] / 100 end
    if modifiers['lifesteal'] then lifesteal = lifesteal + modifiers['lifesteal'] / 100 end

    -- Set igneadrain
    local igneadrain = 0
    if sp_specials['igneadrain'] then igneadrain = sp_specials['igneadrain'] / 100 end
    if modifiers['igneadrain'] then igneadrain = igneadrain + modifiers['igneadrain'] / 100 end

    -- Effects on caster
    if #sp_effects > 0 or lifesteal > 0 or igneadrain > 0 then
        dryrun_res['caster'] = { ['sp'] = sp, ['flat'] = 0, ['flat_ignea'] = 0, ['new_stat'] = sp_stat }
        if lifesteal > 0 and dmg_type == WEAPON then
            local heal = math.floor(total_dealt * lifesteal)
            local healed = math.min(sp.attributes['endurance'] * 2 - sp.health, heal)
            dryrun_res['caster']['flat'] = -healed
            if not dryrun then
                sp.health = sp.health + healed
            end
        end
        if igneadrain > 0 and dmg_type == WEAPON then
            local drain = math.floor(total_dealt * igneadrain)
            local drained = math.min(sp.attributes['focus'] - sp.ignea, drain)
            dryrun_res['caster']['flat_ignea'] = -drained
            if not dryrun then
                sp.ignea = sp.ignea + drained
            end
        end
    end

    -- If the attacker is an ally, record exp gained
    if sp_team == ALLY then
        exp_gain[sp:getId()] = exp_gain[sp:getId()] + status_xp
    end

    if not dryrun then
        -- Return which targets were hurt/killed, and exp gained
        return moved, hurt, dead, counters, exp_gain
    else
        return dryrun_res
    end
end

function Skill:toMenuItem(itex, icons, with_skilltrees, with_prio, attrs, specs)
    local hbox = self:mkSkillBox(itex, icons, with_skilltrees, with_prio, attrs, specs)
    return MenuItem:new(self.name, {}, nil, {
        ['elements'] = hbox,
        ['w'] = HBOX_WIDTH
    }, nil, nil, nil, self.id)
end

function Skill:prepareDesc(tmp_attrs, specials, show_scaling)

    -- Combine all sources of scaling, in order
    local scalings = {}
    if self.scaling then table.insert(scalings, self.scaling) end
    for i=1, #self.sp_effects do
        local eff = self.sp_effects[i][1]
        if not eff[2]:none() then
            table.insert(scalings, eff[2])
        end
    end
    for i=1, #self.ts_effects do
        local eff = self.ts_effects[i][1]
        if not eff[2]:none() then
            table.insert(scalings, eff[2])
        end
    end
    if self.buff_templates then
        for i=1, #self.buff_templates do
            local eff = self.buff_templates[i]
            if not eff[2]:none() then
                table.insert(scalings, eff[2])
            end
        end
    end

    -- Create a colored string template for each scaling
    local sc_strs = {}
    local formats = {}
    for i=1, #scalings do
        local sc = copy(scalings[i])
        local sc_str = nil
        if specials['inversion'] then
            if sc.attr == 'force' then sc.attr = 'affinity' elseif sc.attr == 'affinity' then sc.attr = 'force' end
        end
        if (not sc.mul) or sc.mul == 0 then
            sc_str = {{tostring(abs(sc.base))}}
        else
            local actual = tostring(math.floor(tmp_attrs[sc.attr] * abs(sc.mul)) + abs(sc.base))
            sc_str = {{actual}}
            if show_scaling then
                local attr_name = capitalize(sc.attr)
                local cl = AUTO_COLOR[attr_name]
                if sc.base ~= 0 then
                    sc_str = {
                        {actual},
                        {"(" .. tostring(abs(sc.base)), cl, 1, 0}, {"+", cl},
                        {attr_name, cl}, {"*", cl}, {string.format("%.1f", abs(sc.mul)) .. ")", cl, 0, 1}
                    }
                else
                    sc_str = {
                        {actual},
                        {"(" .. attr_name, cl, 1, 0}, {"*", cl}, {string.format("%.1f", abs(sc.mul)) .. ")", cl, 0, 1}
                    }
                end
            end
        end
        sc_strs = concat(sc_strs, sc_str)

        -- Create placeholder format
        local fmt = {}
        for j = 1, #sc_str do
            table.insert(fmt, string.rep('#', #sc_str[j][1]))
        end
        table.insert(formats, table.concat(fmt, " "))
    end

    -- Prepare spoofed description string before splitting into lines
    local spoof_d = string.format(self.desc, unpack(formats))

    -- Prepare actual description by coloring each line
    local lines = splitByCharLimit(spoof_d, 28)
    if #lines > 5 then
        log("WARN: Description of skill " .. self.id .. " is too long!")
    end
    local sc_idx = 1
    for i = 1, #lines do
        local line = splitSep2(lines[i], ' ')
        for j = 1, #line do
            local sep = ite(j == #line, '', ' ')
            local k = 0
            while #line[j] > k and line[j]:sub(k+1,k+1) == '#' do
                k = k + 1
            end
            if k > 0 then
                line[j] = line[j]:gsub(string.rep("#", k), sc_strs[sc_idx][1]) .. sep
                line[j] = {line[j], sc_strs[sc_idx][2], sc_strs[sc_idx][3], sc_strs[sc_idx][4]}
                sc_idx = sc_idx + 1
            else
                line[j] = {line[j] .. sep}
            end
        end
        lines[i] = autoColor(line)
    end
    return lines
end

function Skill:mkSkillBox(itex, icons, with_skilltrees, with_prio, attrs, specs)
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
        mkEle('text', self:prepareDesc(attrs, specs, false),
            desc_x, BOX_MARGIN + LINE_HEIGHT - 3, nil, true, self:prepareDesc(attrs, specs, true)),
        mkEle('text', {ite(self.cost == 0, 'No Ignea cost', 'Ignea cost')},
            req_x + BOX_MARGIN * 2 - ite(self.cost == 0, 45, 33), req_y + LINE_HEIGHT * 4 + HALF_MARGIN + ite(self.cost == 0, 10, 25)),
        mkEle('text', {"Hold 'R' to see attribute scaling"},
            5, -LINE_HEIGHT),
        mkEle('range', { self.range, self.aim, self.type },
            range_x, range_y)
    }
    for i=1, self.cost do
        table.insert(hbox, 
            mkEle('image', icons[str_to_icon['focus']],
                req_x + 35 - (self.cost / 2) * 10 + (10 * i),
                req_y + LINE_HEIGHT * 4 + HALF_MARGIN - 2, itex)
        )
    end
    if with_skilltrees then
        hbox = concat(hbox, {
            mkEle('text', {'Requirements'}, req_x, req_y + LINE_HEIGHT * 2),
            mkEle('text', {'  to learn  '}, req_x, req_y + LINE_HEIGHT * 3)
        })
        for i=1, #self.reqs do
            local tree_base = (3 - #self.reqs) * BOX_MARGIN + 2
            table.insert(hbox,
                mkEle('image',
                    icons[str_to_icon[self.reqs[i][1]]], req_x + tree_base + BOX_MARGIN * (i-1) * 2, req_y, itex
                )
            )
            table.insert(hbox,
                mkEle('text', 
                    { tostring(self.reqs[i][2]) }, req_x + 8 + tree_base + BOX_MARGIN * (i-1) * 2, req_y + LINE_HEIGHT + 2
                )
            )
        end
    elseif with_prio then
        hbox = concat(hbox, self:mkPrioElements({self.prio}))
    end
    return hbox
end

function Skill:mkPrioElements(prio)
    local header  = { 'Target:' }
    local ps = {
        [ KILL      ] = { 'Killable', 'enemies' }
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
    local specials = {}
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
        elseif specials[a] then
            specials[a] = specials[a] + buffs[i].val
        else
            specials[a] = buffs[i].val
        end
    end

    -- No negative attributes
    for k,v in pairs(tmp_attrs) do
        tmp_attrs[k] = math.max(0, v)
    end
    return tmp_attrs, helpers, specials
end

-- Create a buff, given an attribute set, the buffed stat, and buff scaling
function mkBuff(attrs, template, specials, sp, exp_tag)
    local s = template[2]
    local ty = ite(template[3], template[3], ite(s.mul > 0 or (s.mul == 0 and s.base >= 0), BUFF, DEBUFF))
    local attr = s.attr
    local value_hidden = template[4]
    if specials['inversion'] then
        if attr == 'force' then attr = 'affinity' elseif attr == 'affinity' then attr = 'force' end
    end
    local val = attrs[attr] * s.mul
    val = s.base + ite(val < 0, math.ceil(val), math.floor(val))
    return Buff:new(template[1], val, ty, sp, exp_tag, value_hidden, template[3])
end

function isSpecial(attr)
    return find({'endurance', 'focus', 'force', 'affinity', 'reaction', 'agility'}, attr) == nil
end

-- Add effect to a sprite's status effects, maintaining rendering order and merging effects as needed
function addStatus(stat, eff)

    -- First merge the effect with an existing one if possible
    local dur = function(e) return e.duration end
    for i = 1, #stat do
        local st = stat[i]:copy()
        if eff.buff.attr == st.buff.attr then

            -- Effects with the same name, same duration, and a value, are merged by summing the values
            if dur(st) == dur(eff) and eff.buff.val ~= 0 then
                st.buff.val = st.buff.val + eff.buff.val
                if not st.buff.ty_fixed then
                    st.buff.ty = ite(st.buff.val > 0, BUFF, DEBUFF)
                end
                stat[i] = st
                return

            -- Special effects with the same name and no value are merged by taking the longer duration
            elseif isSpecial(eff) and eff.buff.val == 0 then
                if dur(st) < dur(eff) then
                    st.duration = dur(eff)
                end
                stat[i] = st
                return
            end
        end
    end

    -- If no merge, add the effect to the list, while maintaining rendering order
    for i = 1, #stat do
        local st = stat[i]
        if isSpecial(eff) and not isSpecial(st) then
            table.insert(stat, i, eff)
            return
        end
        if isSpecial(eff) and isSpecial(st) and dur(eff) >= dur(st) then
            table.insert(stat, i, eff)
            return
        end
        if not (isSpecial(eff) or isSpecial(st)) and dur(eff) >= dur(st) then
            table.insert(stat, i, eff)
            return
        end
    end
    table.insert(stat, eff)
end

function isDebuffed(sp, stat)
    local es = stat[sp:getId()]['effects']
    for i = 1, #es do if es[i].buff.type == DEBUFF then return true end end
    return false
end

-- Counter skill templates
mkCounterSkill = {

    ['riposte'] = function(v)
        return Skill:new('riposte_active', 'Riposte', nil, nil,
            "",
            'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
            {},
            { { T } }, FREE_AIM(100), 0,
            ENEMY, Scaling:new(0, 'reaction', 1.0)
        )
    end,

    ['martyr'] = function(v)
        return Skill:new('martyr_active', 'Martyr', nil, nil,
            "",
            'Assassin', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
            {},
            { { T } }, FREE_AIM(100), 0,
            ENEMY, Scaling:new(0, 'force', 1.5)
        )
    end,

    ['retribution'] = function(v)
        return Skill:new('retribution_active', 'Retribution', 'conflagration', 'conflagration',
            "",
            'Demon', SPELL, MANUAL, SKILL_ANIM_GRID,
            {},
            { { T } }, FREE_AIM(100), 0,
            ENEMY, Scaling:new(math.floor(v * 1.5))
        )
    end

}

-- All skills
skills = {


    -- ABELON
    ['sever'] = Skill:new('sever', 'Sever', nil, nil,
        "Slice at an enemy's exposed limbs. Deals %s Weapon damage \z
         to an enemy next to you and lowers their Force by %s.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_RELATIVE,
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.0),
        nil, { { { 'force', Scaling:new(-3) }, 1 } }
    ),
    ['trust'] = Skill:new('trust', 'Trust', nil, nil,
        "Place your faith in your comrades. Increases your Affinity by %s \z
         for 1 turn.",
        'Veteran', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 0 }, { 'Veteran', 1 }, { 'Executioner', 0 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'affinity', Scaling:new(0, 'affinity', 0.5) }, 1 } }
    ),
    ['punish'] = Skill:new('punish', 'Punish', nil, nil,
        "Exploit a brief weakness with a precise stab. Deals %s \z
         Weapon damage only if the enemy has a debuff.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Demon', 0 }, { 'Veteran', 1 }, { 'Executioner', 1 } },
        { { F, F, F },
          { T, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(10, 'force', 1.0),
        nil, nil, nil,
        { ['br'] = function(a, a_a, b, b_a, st) return isDebuffed(b, st) end }
    ),
    ['pursuit'] = Skill:new('pursuit', 'Pursuit', nil, nil,
        "Give chase. Gain %s Force and %s Agility \z
         for 2 turns. Cannot stack.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 0 }, { 'Veteran', 3 }, { 'Executioner', 2 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'force', Scaling:new(0, 'agility', 0.5) }, 2 },
               { { 'agility', Scaling:new(0, 'force', 0.5) }, 2 },
               { { 'pursuit', Scaling:new(0), BUFF }, 2, HIDDEN } }
    ),
    ['siphon'] = Skill:new('siphon', 'Siphon', nil, nil,
        "Cut a siphoning swath. Deals \z
         %s Weapon damage to enemies in front of you and \z
         heals you for 100 %% of total damage.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Demon', 1 }, { 'Veteran', 2 }, { 'Executioner', 3 } },
        { { F, F, F },
          { T, T, T },
          { F, F, F } }, DIRECTIONAL_AIM, 3,
        ENEMY, Scaling:new(0, 'force', 1.3),
        nil, nil, nil,
        { ['lifesteal'] = 100 }
    ),
    ['deaths_door'] = Skill:new('deaths_door', "Death's Door", nil, nil,
        "Summon the last of your strength. Deals 100 %% of your missing health as Weapon damage \z
         to all adjacent enemies.",
        'Demon', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Demon', 2 }, { 'Veteran', 0 }, { 'Executioner', 3 } },
        { { F, T, F },
          { T, F, T },
          { F, T, F } }, SELF_CAST_AIM, 0,
        ENEMY, nil,
        nil, nil, nil,
        { ['dmg'] =
            function(a, a_a, b, b_a, st, dry, dry_res)
                return a.attributes['endurance'] * 2 - a.health
            end
        }
    ),
    ['gambit'] = Skill:new('gambit', 'Gambit', nil, nil,
        "Attack relentlessly. Deals %s Weapon damage to an adjacent enemy, \z
         but lowers your Affinity and Agility to 0 for 1 turn.",
        'Veteran', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Demon', 3 }, { 'Veteran', 5 }, { 'Executioner', 2 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(40),
        { { { 'affinity', Scaling:new(-99) }, 1 },
          { { 'agility',  Scaling:new(-99) }, 1 } }, nil
    ),
    ['execute'] = Skill:new('execute', 'Execute', nil, nil,
        "Fulfill your duty. Deals %s Weapon damage \z
         to an adjacent enemy with less than half of their health \z
         remaining.",
        'Executioner', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
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
    ['conflagration'] = Skill:new('conflagration', 'Conflagration', nil, nil,
        "Scour the battlefield with unholy fire. Deals %s Spell \z
         damage to all enemies in a line across the entire field.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_GRID,
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        mkLine(10), DIRECTIONAL_AIM, 5,
        ENEMY, Scaling:new(30)
    ),
    ['clutches'] = Skill:new('clutches', 'Clutches', nil, nil,
        "Pull an enemy in, dealing %s Spell damage and \z
         reducing Reaction by %s for 2 turns.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
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
    ['judgement'] = Skill:new('judgement', 'Judgement', nil, nil,
        "Instantly kill an enemy anywhere on the field with less than 15 \z
         health remaining.",
        'Executioner', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 2 }, { 'Veteran', 0 }, { 'Executioner', 2 } },
        { { T } }, FREE_AIM(100), 1,
        ENEMY, Scaling:new(1000),
        nil, nil, nil,
        { ['br'] = function(a, a_a, b, b_a, st) return b.health <= 15 end }
    ),
    ['retribution'] = Skill:new('retribution', 'Retribution', nil, nil,
        "For 1 turn, 150 %% of any damage you receive is dealt back \z
         to the attacker as Spell damage.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 2 }, { 'Veteran', 0 }, { 'Executioner', 2 } },
        { { T } }, SELF_CAST_AIM, 1,
        ALLY, nil,
        nil, { { { 'retribution', Scaling:new(0), BUFF }, 1 } }
    ),
    ['contempt'] = Skill:new('contempt', 'Contempt', nil, nil,
        "Glare with an evil eye lit by Ignea, reducing the Force of \z
         affected enemies by %s for 2 turns.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Demon', 2 }, { 'Veteran', 2 }, { 'Executioner', 0 } },
        { { F, T, F, T, F },
          { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, nil,
        nil, { { { 'force', Scaling:new(0, 'focus', -0.7) }, 2 } }
    ),
    ['wrath'] = Skill:new('wrath', 'Wrath', nil, nil,
        "Channel your rage into an Ignea stone until it overflows, causing a blast dealing \z
         %s Spell damage.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Demon', 3 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { F, F, F, F, F },
          { F, T, F, T, F },
          { F, F, T, F, F },
          { F, T, F, T, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'focus', 1.5),
        nil, nil
    ),
    ['crucible'] = Skill:new('crucible', 'Crucible', 'conflagration', 'conflagration',
        "Unleash a scorching ignaeic miasma. You and nearby enemies suffer \z
         %s Spell damage (cannot kill you).",
        'Demon', SPELL, MANUAL, SKILL_ANIM_GRID,
        { { 'Demon', 4 }, { 'Veteran', 0 }, { 'Executioner', 2 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, T, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 7,
        ENEMY, Scaling:new(0, 'force', 2.0),
        nil, nil, nil,
        { ['self'] = true }
    ),
    ['killall'] = Skill:new('killall', 'KILLALL', nil, nil,
        "Debug tool, %s Spell damage.",
        'Demon', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T },
          { T, T, T, T, T, T, T, T, T, T, T, T, T } }, SELF_CAST_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 10.0)
    ),
    ['guard_blindspot'] = Skill:new('guard_blindspot', 'Guard Blindspot', 'guard_blindspot', nil,
        "Protect an adjacent ally from wounds to the back. Adds \z
         %s to the assisted ally's Reaction.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_GRID,
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'affinity', 0.7) } }, { EXP_TAG_RECV }
    ),
    ['inspire'] = Skill:new('inspire', 'Courage', nil, nil,
        "Inspire an ally with a courageous cry. They gain %s \z
         Force and %s Reaction.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
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
            { 'reaction', Scaling:new(0, 'affinity', 0.5) }
        }, { EXP_TAG_ATTACK, EXP_TAG_RECV, EXP_TAG_ASSIST }
    ),
    ['confidence'] = Skill:new('confidence', 'Confidence', nil, nil,
        "Fill allies with reckless confidence. They gain \z
        %s Force, but lose 6 Reaction \z
         and Affinity.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 2 }, { 'Veteran', 3 }, { 'Executioner', 1 } },
        { { T, T, T, T, T },
          { T, T, T, T, T },
          { T, T, F, T, T },
          { T, T, T, T, T },
          { T, T, T, T, T } }, SELF_CAST_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        {
            { 'force',    Scaling:new(0,  'affinity', 0.8) },
            { 'reaction', Scaling:new(-6, 'affinity',   0) },
            { 'affinity', Scaling:new(-6, 'affinity',   0) }
        }, { EXP_TAG_ATTACK }
    ),
    ['flank'] = Skill:new('flank', 'Flank', nil, nil, -- TODO: Rework effect to be powerful, worth 2 ignea
        "Surround and overwhelm an enemy. Ally \z
         attacks will reduce enemy Force, Reaction, and Agility by %s for 2 turns.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 0 }, { 'Veteran', 4 }, { 'Executioner', 2 } },
        { { F, T, F },
          { T, F, T },
          { F, T, F } }, FREE_AIM(3), 2,
        nil, nil, nil, nil, nil, nil,
        { { 'flanking', Scaling:new(0, 'affinity', -1.0), BUFF, VALUE_HIDDEN } }, { EXP_TAG_ATTACK }
    ),
    ["spelltheft"] = Skill:new('spelltheft', "Spelltheft", nil, nil,
        "Cast a grim enchantment to drain magic from fallen foes. \z 
         Assisted allies who kill an enemy recover 3 ignea.",
        'Executioner', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 2 }, { 'Veteran', 1 }, { 'Executioner', 3 } },
        { { F, F, F },
          { F, F, T },
          { F, F, F } }, DIRECTIONAL_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'spelltheft', Scaling:new(0), BUFF } }, { EXP_TAG_ATTACK }
    ),
    ["overrun"] = Skill:new('overrun', "Overrun", nil, nil,
        "Keep momentum. Assisted allies who kill an enemy \z
         gain %s Agility and Affinity for the rest of the turn.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 2 }, { 'Veteran', 3 }, { 'Executioner', 2 } },
        { { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, T, F, F } }, DIRECTIONAL_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'overrun', Scaling:new(0, 'affinity', 1.5), BUFF, VALUE_HIDDEN } }, { EXP_TAG_ATTACK }
    ),
    ['leadership'] = Skill:new('leadership', 'Leadership', nil, nil,
        "Take command and lead your knights. Assisted allies gain %s Force and Affinity.",
        'Veteran', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Demon', 0 }, { 'Veteran', 5 }, { 'Executioner', 3 } },
        { { F, T, T, T, F },
          { T, T, T, T, T },
          { T, T, F, T, T },
          { T, T, T, T, T },
          { F, T, T, T, F } }, SELF_CAST_AIM, 6,
        nil, nil, nil, nil, nil, nil,
        {
            { 'affinity', Scaling:new(0, 'affinity', 1.0) },
            { 'force',    Scaling:new(0, 'affinity', 1.0) }
        }, { EXP_TAG_ATTACK, EXP_TAG_ASSIST }
    ),



    -- KATH
    ['sweep'] = Skill:new('sweep', 'Sweep', nil, nil,
        "Slash in a wide arc. Deals %s Weapon damage to enemies in \z
         front of Kath, and grants %s Reaction for 1 turn.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 0 }, { 'Defender', 0 }, { 'Cleric', 0 } },
        { { F, F, F },
          { T, T, T },
          { T, F, T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 0.8),
        { { { 'reaction', Scaling:new(3) }, 1 } }, nil
    ),
    ['stun'] = Skill:new('stun', 'Stun', nil, nil,
        "A blunt lance blow. Deals %s Weapon damage. If Kath's \z
         Reaction is higher than his foe's, they cannot act for 1 turn.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 1 }, { 'Defender', 1 }, { 'Cleric', 0 } },
        { { T } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(0, 'force', 0.5),
        nil, { { { 'stun', Scaling:new(0), DEBUFF }, 1 } }, nil,
        { ['br'] = function(a, a_a, b, b_a, st)
            return a_a['reaction'] > b_a['reaction'] end
        }
    ),
    ['riposte'] = Skill:new('riposte', 'Riposte', nil, nil,
        "For 1 turn, Kath will retaliate against any \z
         Weapon skills used on him, dealing Weapon damage equal to \z
         his Reaction.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 2 }, { 'Defender', 2 }, { 'Cleric', 1 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'riposte', Scaling:new(0), BUFF }, 1 } }
    ),
    ['shove'] = Skill:new('shove', 'Shove', nil, nil,
        "Kath shoves an ally or enemy out of the way, moving them 1 tile and raising \z
         Kath's Reaction and Affinity by %s for 1 turn.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 3 }, { 'Defender', 3 }, { 'Cleric', 0 } },
        { { F, F, F },
          { F, T, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ALL, nil,
        { { { 'reaction', Scaling:new(3) }, 1 }, { { 'affinity', Scaling:new(3) }, 1 } }, nil,
        { UP, 1 }
    ),
    ['javelin'] = Skill:new('javelin', 'Javelin', nil, nil,
        "Kath hurls a javelin at an enemy, dealing %s Weapon \z
         damage.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 1 }, { 'Defender', 0 }, { 'Cleric', 0 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.2)
    ),
    ['thrust'] = Skill:new('thrust', 'Thrust', nil, nil,
        "Kath thrusts, dealing %s Weapon \z
         damage in a line and raising his Force by %s for 2 turns.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 3 }, { 'Defender', 3 }, { 'Cleric', 0 } },
        { { F, T, F },
          { F, T, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.0),
        { { { 'force', Scaling:new(0, 'force', 0.3) }, 2 } }, nil
    ),
    ['taunt'] = Skill:new('taunt', 'Taunt', nil, nil,
        "Taunt nearby enemies, so that their next \z
         actions will target Kath (whether or not they can reach him).",
        'Defender', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 2 }, { 'Defender', 3 }, { 'Cleric', 2 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, F, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 0,
        ENEMY, nil,
        nil, { { { 'taunt', Scaling:new(0), DEBUFF }, 1 } }
    ),
    ['healing_mist'] = Skill:new('healing_mist', 'Healing Mist', nil, nil,
        "Infuse the air to close wounds. Allies in the area recover \z
         %s health. Can target a square within 3 spaces of \z
         Kath.",
        'Cleric', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 0 }, { 'Defender', 0 }, { 'Cleric', 0 } },
        { { T, T, T },
          { T, T, T },
          { T, T, T } }, FREE_AIM(3), 1,
        ALLY, Scaling:new(0, 'affinity', -1.5)
    ),
    ['haste'] = Skill:new('haste', 'Haste', nil, nil,
        "Kath raises the Agility of allies around him by %s for 2 turns.",
        'Cleric', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 1 }, { 'Defender', 0 }, { 'Cleric', 2 } },
        { { F, F, T, F, F },
          { F, F, T, F, F },
          { T, T, F, T, T },
          { F, F, T, F, F },
          { F, F, T, F, F } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'agility', Scaling:new(0, 'affinity', 0.3) }, 2 } }
    ),
    ['storm_thrust'] = Skill:new('storm_thrust', 'Storm Thrust', nil, nil,
        "Kath launches a thrust powered by lightning, dealing %s \z
         Spell damage to up to 4 enemies in a line.",
        'Hero', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 4 }, { 'Defender', 0 }, { 'Cleric', 2 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 1.0)
    ),
    ['caution'] = Skill:new('caution', 'Caution', nil, nil,
        "Kath enters a defensive stance, raising his Reaction by %s and \z
         lowering his Force by %s for 5 turns. Cannot stack.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 0 }, { 'Defender', 3 }, { 'Cleric', 2 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil, nil,
        { { { 'reaction', Scaling:new(4) }, 5 }, { { 'force', Scaling:new(-2) }, 5 }, { { 'caution', Scaling:new(0), BUFF }, 5, HIDDEN } }
    ),
    ['rescue'] = Skill:new('rescue', 'Rescue', nil, nil,
        "Kath pulls an ally 2 tiles, heals them %s health, and grants %s Reaction and Force for 1 turn.",
        'Cleric', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 3 }, { 'Defender', 0 }, { 'Cleric', 3 } },
        { { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ALLY, Scaling:new(0, 'affinity', -1.0),
        nil, {
            { { 'reaction', Scaling:new(0, 'affinity', 0.5) }, 1 },
            { { 'force', Scaling:new(0, 'affinity', 0.5) }, 1 }
        },
        { DOWN, 2 }
    ),
    ['bond'] = Skill:new('bond', 'Bond', nil, nil,
        "Kath raises his and an ally's \z
         Affinity by %s for 3 turns. Can target any \z
         ally within 3 tiles. Cannot stack.",
        'Hero', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 3 }, { 'Defender', 0 }, { 'Cleric', 3 } },
        { { T } }, FREE_AIM(3), 2,
        ALLY, nil,
        { { { 'affinity', Scaling:new(0, 'force', 0.5) }, 3 }, { { 'bond', Scaling:new(0), BUFF }, 3, HIDDEN } },
        { { { 'affinity', Scaling:new(0, 'force', 0.5) }, 3 } },
        nil
    ),
    ['great_javelin'] = Skill:new('great_javelin', 'Great Javelin', nil, nil,
        "Kath catapults an empowered javelin which deals %s \z
         Weapon damage and pushes the enemy back 2 tiles.",
        'Hero', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 5 }, { 'Defender', 3 }, { 'Cleric', 0 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 3,
        ENEMY, Scaling:new(0, 'force', 1.5), nil, nil, { UP, 2 }
    ),
    ['great_sweep'] = Skill:new('great_sweep', 'Great Sweep', nil, nil,
        "Kath swings an ignaeic crescent which deals %s \z
         Weapon damage and grants %s Reaction for 1 turn.",
        'Defender', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Hero', 3 }, { 'Defender', 5 }, { 'Cleric', 0 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { F, T, T, F, T, T, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 1.0),
        { { { 'reaction', Scaling:new(5) }, 1 } }, nil
    ),
    ['forbearance'] = Skill:new('forbearance', 'Forbearance', nil, nil,
        "Kath receives all attacks meant for an adjacent assisted ally.",
        'Defender', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 0 }, { 'Defender', 0 }, { 'Cleric', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'forbearance', Scaling:new(0), BUFF } }, { EXP_TAG_RECV }
    ),
    ['invigorate'] = Skill:new('invigorate', 'Invigorate', nil, nil,
        "Kath renews allies near him with a cantrip. Allies on the assist gain \z
         %s Force.",
        'Cleric', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 1 }, { 'Defender', 0 }, { 'Cleric', 1 } },
        { { T, F, T },
          { F, F, F },
          { T, F, T } }, SELF_CAST_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'force', Scaling:new(0, 'affinity', 1.0) } }, { EXP_TAG_ATTACK }
    ),
    ['hold_the_line'] = Skill:new('hold_the_line', 'Hold the Line', nil, nil,
        "Kath forms a wall with his allies, raising the Reaction of assisted \z
         allies by %s.",
        'Hero', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 2 }, { 'Defender', 2 }, { 'Cleric', 0 } },
        mkLine(10), DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'reaction', 0.5) } }, { EXP_TAG_RECV }
    ),
    ['guardian_angel'] = Skill:new('guardian_angel', 'Guardian Angel', nil, nil,
        "Kath consecrates the ground. Allies on the assist cannot \z
         drop below 1 health. Kath also receives the assist.",
        'Cleric', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 0 }, { 'Defender', 3 }, { 'Cleric', 4 } },
        { { F, F, F, T, F, F, F },
          { F, T, T, T, T, T, F },
          { F, T, F, T, F, T, F },
          { T, T, T, T, T, T, T },
          { F, T, F, T, F, T, F },
          { F, T, T, T, T, T, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 3,
        nil, nil, nil, nil, nil, nil,
        { { 'guardian_angel', Scaling:new(0), BUFF } }, { EXP_TAG_RECV }
    ),
    ['steadfast'] = Skill:new('steadfast', 'Steadfast', nil, nil,
        "Kath helps allies fortify their positions. Allies on the assist \z
         gain %s Reaction.",
        'Defender', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 3 }, { 'Defender', 4 }, { 'Cleric', 2 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, T, F, T, F, F },
          { F, F, T, F, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, T, F, T, F, F },
          { F, F, T, F, T, F, F } }, DIRECTIONAL_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'affinity', 1.0) } }, { EXP_TAG_RECV }
    ),
    ['ward'] = Skill:new('ward', 'Spell Ward', nil, nil,
        "Kath casts a protective ward, rendering assisted allies immune to Spell damage \z
         and granting %s Force.",
        'Cleric', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 0 }, { 'Defender', 4 }, { 'Cleric', 2 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, T, F, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        { { 'ward', Scaling:new(0), BUFF }, { 'force', Scaling:new(0, 'affinity', 0.5) } },
        { EXP_TAG_RECV, EXP_TAG_ATTACK }
    ),
    ['peace'] = Skill:new('peace', 'Peace', nil, nil,
        "Kath performs a calming meditation. Allies on the assist lose all Force but gain %s Affinity.",
        'Cleric', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Hero', 0 }, { 'Defender', 3 }, { 'Cleric', 2 } },
        { { T, T, T },
          { T, F, T },
          { T, T, T } }, SELF_CAST_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        {
            { 'affinity', Scaling:new(0, 'affinity', 1.0) },
            { 'force', Scaling:new(-99) }
        }, { EXP_TAG_ASSIST }
    ),


    -- ELAINE
    ['hunting_shot'] = Skill:new('hunting_shot', 'Hunting Shot', nil, nil,
        "Elaine shoots from close range, \z
         dealing %s Weapon damage. Can target any enemy within 2 tiles.",
        'Huntress', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 1 }, { 'Apprentice', 0 }, { 'Sniper', 1 } },
        { { T } }, FREE_AIM(2), 0,
        ENEMY, Scaling:new(10, 'force', 0.5)
    ),
    ['lay_traps'] = Skill:new('lay_traps', 'Lay Traps', nil, nil,
        "Elaine anticipates foes in her path and sets traps to reduce their \z
         Reaction by %s for 2 turns.",
        'Huntress', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 1 }, { 'Sniper', 0 } },
        { { F, F, F, F, F },
          { F, T, T, T, F },
          { F, T, T, T, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, nil,
        nil, { { { 'reaction', Scaling:new(0, 'reaction', -0.8) }, 2 } }
    ),
    ['butcher'] = Skill:new('butcher', 'Butcher', nil, nil,
        "Elaine enchants her hunting knife and carves up an adjacent enemy, \z
         dealing %s Weapon damage.",
        'Huntress', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 4 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { T } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(35)
    ),
    ['precise_shot'] = Skill:new('precise_shot', 'Precise Shot', nil, nil,
        "Elaine takes careful aim to hit a faraway target with an arrow, \z
         dealing %s Weapon damage.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(2, 'force', 1.0)
    ),
    ['volley'] = Skill:new('volley', 'Volley', nil, nil,
        "Elaine rapidly fires arrows across the field to stagger foes, \z
         dealing %s Weapon damage to each target.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
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
    ['piercing_arrow'] = Skill:new('piercing_arrow', 'Piercing Arrow', nil, nil,
        "Elaine shoots with such strength as to pierce enemies, \z
         dealing %s Weapon damage to all targets.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 1 }, { 'Sniper', 3 } },
        { { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, T },
          { F, F, F, F, F, T, F },
          { F, F, F, F, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(5, 'force', 1)
    ),
    ['deadeye'] = Skill:new('deadeye', 'Deadeye', nil, nil,
        "Elaine aims an impossible shot from an empowered draw, \z
         dealing %s Weapon damage and pushing the target 1 tile.",
        'Sniper', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 2 }, { 'Apprentice', 0 }, { 'Sniper', 5 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 1.5), nil, nil, { UP, 1 }
    ),
    ['observe'] = Skill:new('observe', 'Observe', nil, nil,
        "Once per battle, Elaine chooses an ally to learn from, permanently \z
         gaining 1 point in their signature attribute.",
        'Apprentice', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { T } }, FREE_AIM(100), 0,
        ALLY, nil,
        { { { 'observe', Scaling:new(0), BUFF }, math.huge } }, nil, nil,
        { ['and'] =
            function(a, a_a, b, b_a, st, dry, dry_res)
                if not dry then
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
            end
        }
    ),
    ['snare'] = Skill:new('snare', 'Snare', nil, nil,
        "Elaine lays a magical hunting snare, dealing %s Spell damage and reducing a nearby foe's \z
         Agility by %s for 2 turns.",
        'Huntress', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 3 }, { 'Apprentice', 2 }, { 'Sniper', 0 } },
        { { F, F, F },
          { T, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(10),
        nil, { { { 'agility', Scaling:new(0, 'agility', -0.5) }, 1 } }
    ),
    ['ignea_arrowheads'] = Skill:new('ignea_arrowheads', 'Ignea Arrowheads', nil, nil,
        "Elaine fashions activated Ignea arrowheads, \z
         increasing her Force by %s for 4 turns. Cannot stack.",
        'Apprentice', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 1 }, { 'Sniper', 1 } },
        { { T } }, SELF_CAST_AIM, 1,
        ALLY, nil,
        nil, { { { 'force', Scaling:new(2, 'focus', 1.0) }, 4 }, { { 'ignea_arrowheads', Scaling:new(0), BUFF }, 4, HIDDEN } }
    ),
    ['wind_blast'] = Skill:new('wind_blast', 'Wind Blast', nil, nil,
        "Elaine conjures a concussive gust of wind to blow an enemy back \z
         3 tiles.",
        'Apprentice', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 2 }, { 'Apprentice', 1 }, { 'Sniper', 0 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, nil,
        nil, nil, { UP, 3 }
    ),
    ['exploding_shot'] = Skill:new('exploding_shot', 'Exploding Shot', nil, nil,
        "Elaine primes a chunk of Ignea to explode and ties it to an arrow, \z
         dealing %s Spell damage to all foes hit.",
        'Apprentice', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Huntress', 0 }, { 'Apprentice', 3 }, { 'Sniper', 3 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 4,
        ENEMY, Scaling:new(0, 'force', 1.2)
    ),
    ['seeking_arrow'] = Skill:new('seeking_arrow', 'Seeking Arrow', nil, nil,
        "Elaine enchants an arrow to hunt down a target, firing at any foe \z
         within 8 tiles to deal %s Spell damage.",
        'Sniper', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 3 }, { 'Sniper', 3 } },
        { { T } }, FREE_AIM(8), 3,
        ENEMY, Scaling:new(20, 'force', 0.5)
    ),
    ['terrain_survey'] = Skill:new('terrain_survey', 'Terrain Survey', nil, nil,
        "Elaine surveys the field and how to navigate it. Allies on the \z
         assist share her knowledge and gain %s Agility.",
        'Huntress', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 0 }, { 'Sniper', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'agility', Scaling:new(0, 'affinity', 0.5) } }, { EXP_TAG_MOVE }
    ),
    ['weak_point'] = Skill:new('weak_point', 'Weak Point', nil, nil,
        "Elaine reveals the enemy's weaknesses with a spell. Allies on the assist \z
         gain %s Force.",
        'Huntress', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 3 }, { 'Apprentice', 1 }, { 'Sniper', 2 } },
        { { F, F, F, F, F },
          { F, F, F, F, F },
          { F, T, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'force', Scaling:new(0, 'affinity', 1) } }, { EXP_TAG_MOVE }
    ),
    ['camouflage'] = Skill:new('camouflage', 'Camouflage', nil, nil,
        "Elaine builds a camouflaged shelter. The assisted ally \z
         will not be targeted by enemies and has their ignea costs reduced by %s.",
        'Huntress', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 2 }, { 'Sniper', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'ignea_efficiency', Scaling:new(-1), BUFF }, { 'hidden', Scaling:new(0), BUFF } }, {}
    ),
    ['inversion'] = Skill:new('inversion', 'Inversion', nil, nil,
        "Elaine creates a field of emotional distortion. \z
         Allies on the assist gain %s Force and Affinity, but swap them when using skills.",
        'Apprentice', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 0 }, { 'Apprentice', 2 }, { 'Sniper', 0 } },
        { { T } }, FREE_AIM(3), 1,
        nil, nil, nil, nil, nil, nil,
        { { 'force', Scaling:new(5) }, { 'affinity', Scaling:new(5) }, { 'inversion', Scaling:new(0), BUFF } },
        { EXP_TAG_ATTACK, EXP_TAG_ASSIST }
    ),
    ['flight'] = Skill:new('flight', 'Flight', nil, nil,
        "Elaine whips the wind into currents, letting allies fly. They gain \z
         %s Agility and can move through other units.",
        'Apprentice', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 4 }, { 'Sniper', 0 } },
        { { F, T, F },
          { T, F, T },
          { F, T, F } }, SELF_CAST_AIM, 3,
        nil, nil, nil, nil, nil, nil,
        {
            { 'agility', Scaling:new(0, 'affinity', 1.0) },
            { 'ghosting', Scaling:new(1), BUFF, VALUE_HIDDEN }
        }, { EXP_TAG_MOVE }
    ),
    ['farsight'] = Skill:new('farsight', 'Farsight', nil, nil,
        "Elaine extends her superior perception to those nearby, granting \z
         assisted allies %s Reaction.",
        'Sniper', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 2 }, { 'Apprentice', 1 }, { 'Sniper', 1 } },
        { { T, T, T, T, T },
          { T, F, F, F, T },
          { T, F, F, F, T },
          { T, F, F, F, T },
          { T, T, T, T, T } }, SELF_CAST_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'affinity', 0.8) } }, { EXP_TAG_RECV }
    ),
    ['cover_fire'] = Skill:new('cover_fire', 'Cover Fire', nil, nil,
        "Elaine lays down a hail of arrows around an ally position, granting \z
         them %s Force.",
        'Sniper', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Huntress', 1 }, { 'Apprentice', 0 }, { 'Sniper', 1 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'force', Scaling:new(0, 'affinity', 0.5) } }, { EXP_TAG_ATTACK }
    ),



    -- SHANTI
    ['knockback'] = Skill:new('knockback', 'Knockback', nil, nil,
        "Shanti spins her lantern by its chain, knocking back nearby enemies \z
         and dealing %s Weapon damage.",
        'Lanternfaire', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Lanternfaire', 0 }, { 'Sorceress', 0 } },
        { { F, F, F },
          { T, T, T },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 0.7),
        nil, nil,
        { UP, 1 }
    ),
    ['lasso'] = Skill:new('lasso', 'Lasso', nil, nil,
        "Shanti equips a long chain and flings her lantern, ensnaring an enemy \z
         and lowering its Agility by %s for 1 turn.",
        'Lanternfaire', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Lanternfaire', 2 }, { 'Sorceress', 0 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, nil,
        nil, { { { 'agility', Scaling:new(0, 'reaction', -1.0) }, 1 } }
    ),
    ['crushing_swing'] = Skill:new('crushing_swing', 'Crushing Swing', nil, nil,
        "Shanti brings her lantern down hard on an adjacent enemy, \z
         dealing %s Weapon damage.",
        'Lanternfaire', WEAPON, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Lanternfaire', 4 }, { 'Sorceress', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'force', 1.3)
    ),
    ['ignite_lantern'] = Skill:new('ignite_lantern', 'Ignite Lantern', nil, nil,
        "Shanti lights her lantern with activated Ignea to draw from, reducing all of her \z
         Ignea costs by 1 for 5 turns. Cannot stack.",
        'Lanternfaire', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 3 }, { 'Sorceress', 3 } },
        { { T } }, SELF_CAST_AIM, 1,
        ALLY, nil,
        nil, { { { 'ignea_efficiency', Scaling:new(-1), BUFF }, 5 },
               { { 'ignite_lantern', Scaling:new(0), BUFF }, 5, HIDDEN } }
    ),
    ['searing_light'] = Skill:new('searing_light', 'Searing Light', nil, nil,
        "Shanti scorches enemies with burning ignaeic light, dealing %s Spell damage.",
        'Sorceress', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Lanternfaire', 0 }, { 'Sorceress', 0 } },
        { { F, F, F, F, F },
          { F, T, F, T, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(0, 'force', 1.0)
    ),
    ['detonate'] = Skill:new('detonate', 'Detonate', nil, nil,
        "Shanti over-activates a chunk of Ignea and propels it at an enemy, \z
         blowing them up and dealing %s Spell damage.",
        'Sorceress', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Lanternfaire', 1 }, { 'Sorceress', 2 } },
        { { F, F, F },
          { F, F, T },
          { F, F, F } }, DIRECTIONAL_AIM, 3,
        ENEMY, Scaling:new(3, 'focus', 1.5)
    ),
    ['smite'] = Skill:new('smite', 'Smite', nil, nil,
        "Shanti calls down a bolt of Ignaeic energy, dealing %s Spell damage to an enemy within 6 tiles.",
        'Sorceress', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 2 }, { 'Sorceress', 4 } },
        { { T } }, FREE_AIM(6), 2,
        ENEMY, Scaling:new(0, 'focus', 1.0),
        nil, nil
    ),
    ['flashbang'] = Skill:new('flashbang', 'Flashbang', nil, nil,
        "Shanti blinds nearby enemies, dealing %s Spell damage \z
         and raising her Reaction by %s for 1 turn.",
         'Lanternfaire', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
         { { 'Lanternfaire', 4 }, { 'Sorceress', 4 } },
         { { F, T, F },
           { T, F, T },
           { F, T, F } }, SELF_CAST_AIM, 1,
         ENEMY, Scaling:new(0, 'reaction', 1.5),
         { { { 'reaction', Scaling:new(5) }, 1 } }
    ),
    ['gravity'] = Skill:new('gravity', 'Gravity', nil, nil,
        "Shanti pulls enemies 3 tiles towards her, \z
         dealing %s Spell damage and lowering their Reaction by %s.",
        'Sorceress', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Lanternfaire', 0 }, { 'Sorceress', 5 } },
        { { F, T, T, T, T, T, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 4,
        ENEMY, Scaling:new(0, 'force', 1.0),
        nil, { { { 'reaction', Scaling:new(0, 'focus', -0.5) }, 1 } },
        { DOWN, 3 }
    ),
    ['shine'] = Skill:new('shine', 'Shine', nil, nil,
        "Shanti shines her empowered lantern brightly, improving most attributes \z
         of nearby assisted allies by %s.",
        'Lanternfaire', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 1 }, { 'Sorceress', 1 } },
        { { F, F, T, F, F },
          { F, T, T, T, F },
          { T, T, F, T, T },
          { F, T, T, T, F },
          { F, F, T, F, F } }, SELF_CAST_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        {
            { 'force',    Scaling:new(1, 'affinity', 0.2) },
            { 'reaction', Scaling:new(1, 'affinity', 0.2) },
            { 'agility',  Scaling:new(1, 'affinity', 0.2) },
            { 'affinity', Scaling:new(1, 'affinity', 0.2) }
        }, { EXP_TAG_ATTACK, EXP_TAG_RECV, EXP_TAG_ASSIST }
    ),
    ['hypnotize'] = Skill:new('hypnotize', 'Hypnotize', nil, nil,
        "Shanti hypnotizes an assisted ally into a frenzied state, raising their Force by %s.",
        'Sorceress', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 1 }, { 'Sorceress', 1 } },
        { { T } }, DIRECTIONAL_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'force', Scaling:new(15, 'affinity', 0.3) } }, { EXP_TAG_ATTACK }
    ),
    ['bleed_vitality'] = Skill:new('bleed_vitality', 'Bleed Vitality', nil, nil,
        "Shanti empowers the assisted ally's Weapon attacks to heal them for %s %% of the damage dealt.",
        'Sorceress', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 2 }, { 'Sorceress', 3 } },
        { { T } }, FREE_AIM(3), 1,
        nil, nil, nil, nil, nil, nil,
        { { 'lifesteal', Scaling:new(40, 'affinity', 10.0), BUFF } }, { EXP_TAG_ATTACK }
    ),
    ['ignaeic_veins'] = Skill:new('ignaeic_veins', 'Ignaeic Veins', nil, nil,
        "Shanti surfaces veins of Ignea from underground. Allies on the assist have their ignea costs \z
         reduced by %s.",
        'Lanternfaire', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 5 }, { 'Sorceress', 4 } },
        { { T, F, F, T, F, F, T },
          { F, T, F, T, F, T, F },
          { F, F, F, F, F, F, F },
          { T, T, F, F, F, T, T },
          { F, F, F, F, F, F, F },
          { F, T, F, T, F, T, F },
          { T, F, F, T, F, F, T } }, SELF_CAST_AIM, 2,
        nil, nil, nil, nil, nil, nil,
        { { 'ignea_efficiency', Scaling:new(-1, 'affinity', -0.2), BUFF } }, { EXP_TAG_ATTACK, EXP_TAG_ASSIST }
    ),
    ['bleed_ignea'] = Skill:new('bleed_ignea', 'Bleed Ignea', nil, nil,
        "Shanti empowers the assisted ally's Weapon attacks to restore Ignea equal to %s %% of the damage dealt.",
        'Sorceress', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Lanternfaire', 4 }, { 'Sorceress', 5 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 6,
        nil, nil, nil, nil, nil, nil,
        { { 'igneadrain', Scaling:new(0, 'affinity', 4.0), BUFF } }, { EXP_TAG_ATTACK, EXP_TAG_ASSIST }
    ),



    -- LESTER
    ['thrown_dagger'] = Skill:new('thrown_dagger', 'Thrown Dagger', nil, nil,
        "Lester throws a carefully aimed dagger at any enemy within 2 tiles. \z
         Deals %s Weapon damage.",
        'Assassin', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 0 }, { 'Naturalist', 0 } },
        { { T } }, FREE_AIM(2), 0,
        ENEMY, Scaling:new(7, 'force', 1.0)
    ),
    ['assassinate'] = Skill:new('assassinate', 'Assassinate', nil, nil,
        "Lester goes all out for an enemy's vitals. Deals %s Weapon damage to an \z
         adjacent enemy.",
        'Assassin', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 3 }, { 'Naturalist', 0 } },
        { { T } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(0, 'force', 2.0)
    ),
    ['blade_dance'] = Skill:new('blade_dance', 'Blade Dance', nil, nil,
        "Lester nimbly whirls his blades to cut through a group of enemies, dealing \z
         %s Weapon damage.",
        'Assassin', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 5 }, { 'Naturalist', 0 } },
        { { F, F, F, F, F },
          { F, T, T, T, F },
          { F, T, T, T, F },
          { F, T, F, T, F },
          { F, T, T, T, F } }, DIRECTIONAL_AIM, 0,
        ENEMY, Scaling:new(0, 'agility', 1.2)
    ),
    ['first_aid'] = Skill:new('first_aid', 'First Aid', nil, nil,
        "Lester quickly patches up an adjacent ally with his medicinal kit, restoring \z
         %s health to them.",
        'Naturalist', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 0 }, { 'Naturalist', 1 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        ALLY, Scaling:new(0, 'agility', -1.0)
    ),
    ['shadowed'] = Skill:new('shadowed', 'Shadowed', nil, nil,
        "Lester conceals his presence. He gains 8 Agility for 2 turns and \z
         won't be directly targeted on the next enemy phase.",
        'Assassin', WEAPON, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 4 }, { 'Naturalist', 3 } },
        { { T } }, SELF_CAST_AIM, 0,
        ALLY, nil,
        nil, { { { 'agility', Scaling:new(8) }, 2 }, { { 'hidden', Scaling:new(0), BUFF }, 1 } }
    ),
    ['martyr'] = Skill:new('martyr', 'Martyr', nil, nil,
        "For 1 turn, enemies who attack Lester with \z
         Weapon skills explode, taking 150 %% of Lester's Force as Spell damage.",
        'Assassin', SPELL, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 2 }, { 'Naturalist', 2 } },
        { { T } }, SELF_CAST_AIM, 1,
        ALLY, nil,
        nil, { { { 'martyr', Scaling:new(0), BUFF }, 1 } }
    ),
    ['stalagmite'] = Skill:new('stalagmite', 'Stalagmite', nil, nil,
        "Lester conjures a stone spike, dealing %s Spell damage \z
         to an enemy and pushing them 1 tile.",
        'Naturalist', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Assassin', 3 }, { 'Naturalist', 3 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 1,
        ENEMY, Scaling:new(7, 'force', 1.0),
        nil, nil, { UP, 1 }
    ),
    ['quake'] = Skill:new('quake', 'Quake', nil, nil,
        "Lester causes a targeted earthquake, dealing %s Spell damage to enemies hit.",
        'Naturalist', SPELL, MANUAL, SKILL_ANIM_NONE, -- RELATIVE
        { { 'Assassin', 4 }, { 'Naturalist', 4 } },
        { { F, T, F, T, F, T, F },
          { F, F, T, F, T, F, F },
          { F, T, F, T, F, T, F },
          { F, F, T, F, T, F, F },
          { F, T, F, F, F, T, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        ENEMY, Scaling:new(20, 'force', 0.5)
    ),
    ['warning'] = Skill:new('warning', 'Warning', nil, nil,
        "Lester shouts at an ally to warn them of nearby danger. They gain %s \z
         Reaction.",
        'Naturalist', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 0 }, { 'Naturalist', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'reaction', Scaling:new(0, 'affinity', 1.0) } }, { EXP_TAG_RECV }
    ),
    ['poison_coating'] = Skill:new('poison_coating', 'Poison Coating', nil, nil,
        "Lester shares a deadly poison with allies. Their Weapon attacks will \z
         reduce enemy Force by %s for 1 turn.",
        'Naturalist', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 2 }, { 'Naturalist', 2 } },
        { { F, T, F },
          { T, F, T },
          { F, T, F } }, SELF_CAST_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'poison_coat', Scaling:new(0, 'affinity', -0.6), BUFF, VALUE_HIDDEN } }, { EXP_TAG_ATTACK }
    ),
    ['escape'] = Skill:new('escape', 'Escape', nil, nil,
        "Lester identifies an escape route with Ignea-enhanced perception. Assisted allies \z
         lose 10 Force but gain %s Agility.",
        'Assassin', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 1 }, { 'Naturalist', 1 } },
        { { F, F, T, T, T, F, F },
          { F, F, T, T, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 1,
        nil, nil, nil, nil, nil, nil,
        {
            { 'agility', Scaling:new(0, 'affinity', 1.0) },
            { 'force', Scaling:new(-10) }
        },
        { EXP_TAG_MOVE }
    ),
    ['suspicious_tonic'] = Skill:new('suspicious_tonic', 'Suspicious Tonic', nil, nil,
        "Lester gives assisted allies a dubious remedy. Their Ignea costs \z
         are raised by %s, but they gain %s Force.",
        'Naturalist', ASSIST, MANUAL, SKILL_ANIM_NONE, -- GRID
        { { 'Assassin', 0 }, { 'Naturalist', 3 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        nil, nil, nil, nil, nil, nil,
        { { 'ignea_efficiency', Scaling:new(1), DEBUFF }, { 'force', Scaling:new(0, 'affinity', 1.0) } },
        { EXP_TAG_ATTACK }
    ),

    -- ENEMY
    ['bite'] = Skill:new('bite', 'Bite', nil, nil,
        "Leap at an adjacent enemy and bite into them. Deals \z
         %s Weapon damage to an enemy next to the user.",
        'Enemy', WEAPON, KILL, SKILL_ANIM_NONE, -- RELATIVE
        {},
        { { T } }, DIRECTIONAL_AIM, 0,
        ALLY, Scaling:new(0, 'force', 1.0)
    ),
    ['bludgeon'] = Skill:new('bludgeon', 'Bludgeon', nil, nil,
        "Bring down a mighty stone appendage, crushing an adjacent enemy. Deals \z
         %s Weapon damage.",
        'Enemy', WEAPON, KILL, SKILL_ANIM_NONE, -- RELATIVE
        {},
        { { F, F, F },
          { F, T, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        ALLY, Scaling:new(0, 'force', 1.0)
    ),
    ['shockwave'] = Skill:new('shockwave', 'Shockwave', nil, nil,
        "Emit an ignaeic shockwave. Deals \z
        %s Spell damage to nearby enemies and lowers their Agility by 4 for 1 turn.",
        'Enemy', SPELL, KILL, SKILL_ANIM_NONE, -- RELATIVE
        {},
        { { F, F, T, F, F },
          { F, T, T, T, F },
          { T, T, F, T, T },
          { F, T, T, T, F },
          { F, F, T, F, F } }, SELF_CAST_AIM, 4,
        ALLY, Scaling:new(0, 'force', 0.5),
        nil, { { { 'agility', Scaling:new(-4) }, 2 } }
    ),
    ['the_howl'] = Skill:new('the_howl', 'Howl', nil, nil,
        "The Terror looses a blood- curdling howl, dealing %s Spell damage and \z
         lowering victims' Force by %s for 1 turn.",
        'Enemy', SPELL, KILL, SKILL_ANIM_NONE, -- RELATIVE
        {},
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, F, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 2,
        ALLY, Scaling:new(0, 'force', 0.5),
        nil, { { { 'force', Scaling:new(-5) }, 2 } }
    ),
    ['the_eye'] = Skill:new('the_eye', 'Eldritch Gaze', nil, nil,
        "The Terror lowers its own Agility by 12 to level a haunting gaze. \z
         Deals %s Spell damage and stuns victims for 1 turn.",
        'Enemy', SPELL, KILL, SKILL_ANIM_NONE, -- RELATIVE
        {},
        { { F, F, F, F, F },
          { F, T, T, T, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 4,
        ALLY, Scaling(5),
        { { { 'agility', Scaling:new(-12) }, 2 } }, { { { 'stun', Scaling:new(0), DEBUFF }, 2 } }
    ),
    ['the_claws'] = Skill:new('the_claws', 'Rake', nil, nil,
        "The Terror slashes wildly with its claws, dealing \z
         %s Weapon damage but lowering its own Reaction by 15 for 1 turn.",
        'Enemy', WEAPON, KILL, SKILL_ANIM_NONE, -- RELATIVE
        {},
        { { F, F, F, F, F },
          { F, T, T, T, F },
          { F, T, T, T, F },
          { F, T, F, T, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        ALLY, Scaling:new(0, 'force', 1.5),
        { { { 'reaction', Scaling:new(-15) }, 2 } }
    ),
}