require 'Util'
require 'Constants'

require 'Menu'

Scaling = Class{}

function Scaling:init(base, attr, mul)
    self.base = base
    self.attr = attr
    self.mul  = mul
end

Buff = Class{}

function Buff:init(attr, val, type)
    self.attr = attr
    self.val  = val
    self.type = type
end

function Buff:toStr()
    if self.attr == 'special' then
        return EFFECT_NAMES[self.val]
    end
    local attr = self.attr:sub(1,1):upper() .. self.attr:sub(2)
    return ite(self.val > 0, '+', '-') .. abs(self.val) .. ' ' .. self.attr
end

Effect = Class{}

function Effect:init(buff, dur)
    self.buff     = buff
    self.duration = dur
end

Skill = Class{}

function Skill:init(id, n, ti, st, prio, si, tr, r, at, c, e, d)

    -- Identifying info
    self.id           = id
    self.name         = n
    self.tree_id      = ti
    self.type         = st
    self.prio         = prio
    self.scaling_icon = si
    self.desc         = d

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
    self.use    = e  -- Function taking the caster and target as inputs
                     -- returns targets hurt and targets dead
end

function Skill:toMenuItem(itex, icons, with_skilltrees, with_prio)
    local hbox = self:mkSkillBox(itex, icons, with_skilltrees, with_prio)
    return MenuItem(self.name, {}, nil, {
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
            desc_x, BOX_MARGIN + LINE_HEIGHT - 3),
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

    -- Retrieve buffs
    local buffs = {}
    for i = 1, #assists do table.insert(buffs, assists[i]) end
    for i = 1, #effects do table.insert(buffs, effects[i].buff) end

    -- Make attrs
    local tmp_attrs = {}
    for k, v in pairs(bases) do tmp_attrs[k] = v end
    for i = 1, #buffs do
        local a = buffs[i].attr
        if tmp_attrs[a] then
            tmp_attrs[a] = math.max(0, tmp_attrs[a] + buffs[i].val)
        end
    end
    return tmp_attrs
end

-- Create a buff, given an attribute set, the buffed stat, and buff scaling
function mkBuff(attrs, template)
    if template[1] == 'special' then
        return Buff(unpack(template))
    else
        local s = template[2]
        local tp = ite(s.mul > 0 or (s.mul == 0 and s.base >= 0), BUFF, DEBUFF)
        return Buff(template[1], s.base + math.floor(attrs[s.attr] * s.mul), tp)
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
function hasSpecial(stat, spec)
    for i = 1, #stat do
        if stat[i].buff.attr == 'special' and stat[i].buff.val == spec then
            return true
        end
    end
    return false
end

-- Generate a generic assist function given the buff templates
function genericAssist(templates)
    return function(attrs)
        return mapf(function(b) return mkBuff(attrs, b) end, templates)
    end
end

-- Generate a generic attack function given the attack's parameters
function genericAttack(dmg_type, affects, scaling,
                       sp_buffs, sp_buff_turns,
                       ts_buffs, ts_buff_turns,
                       modifiers)

    -- Filling in optional args
    if not modifiers then modifiers = {} end
    if not ts_buffs  then ts_buffs  = {} end
    if not sp_buffs  then sp_buffs  = {} end

    -- Generate attack function
    return function(sp, sp_assists, ts, ts_assists, status, grid)

        -- Who was hurt/killed by this attack?
        local hurt = {}
        local dead = {}

        -- Temporary attributes and special effects for the caster
        local sp_stat = status[sp:getId()]['effects']
        local sp_tmp_attrs = mkTmpAttrs(sp.attributes, sp_stat, sp_assists)

        -- Affect targets
        for i = 1, #ts do

            -- Temporary attributes and special effects for the target
            local t = ts[i]
            local t_stat = status[t:getId()]['effects']
            local t_ass = ts_assists[i]
            local t_tmp_attrs = mkTmpAttrs(t.attributes, t_stat, t_ass)

            -- If attacker is an enemy and target has forbearance, the target
            -- switches to Kath
            if hasSpecial(t_stat, 'forbearance')
            and status[sp:getId()]['team'] == ENEMY then
                local s_kath = status['kath']
                local loc = s_kath['location']
                t = s_kath['sp']
                t_stat = s_kath['effects']
                t_ass = grid[loc[2]][loc[1]].assists
                t_tmp_attrs = mkTmpAttrs(t.attributes, t_stat, t_ass)
            end

            -- Only hit targets passing the team filter
            local team = ite(status[t:getId()]['team'] == ALLY, ENEMY, ALLY)
            local valid = (team ~= affects or (t == sp and modifiers['self']))
            valid = valid and (not modifiers['br'] or
                               modifiers['br'](sp_tmp_attrs, t_tmp_attrs))
            if valid then

                -- If there's no scaling, the attack does no damage
                if scaling then

                    -- Compute damage or healing (MUST be a SPELL to heal)
                    local atk = scaling.base
                              + math.floor(sp_tmp_attrs[scaling.attr]
                              * scaling.mul)
                    local dmg = atk
                    if dmg_type == WEAPON then
                        local def = math.floor(t_tmp_attrs['reaction'] / 2)
                        dmg = math.max(0, atk - def)
                    end

                    -- If this is a self hit or the target has guardian angel
                    -- they can't die
                    local min = 0
                    if (t == sp and modifiers['self'])
                    or hasSpecial(t_stat, 'guardian_angel') then
                        min = 1
                    end

                    -- Deal damage or healing
                    local max_hp = t_tmp_attrs['endurance']
                    local prev_hp = t.health
                    t.health = math.max(min, math.min(max_hp, t.health - dmg))

                    -- Determine if target is hurt, or dead
                    if t.health == 0 then
                        table.insert(dead, t)
                    elseif t.health < prev_hp then
                        table.insert(hurt, t)
                    end
                end

                -- Apply status effects to target
                for j = 1, #ts_buffs do
                    local b = mkBuff(sp_tmp_attrs, ts_buffs[j])
                    addStatus(t_stat, Effect(b, ts_buff_turns))
                end

                -- Target turns to face the caster
                if abs(t.x - sp.x) > TILE_WIDTH / 2 then
                    t.dir = ite(t.x > sp.x, LEFT, RIGHT)
                end
            end
        end

        -- Affect caster
        for j = 1, #sp_buffs do
            local b = mkBuff(sp_tmp_attrs, sp_buffs[j])
            addStatus(sp_stat, Effect(b, sp_buff_turns))
        end

        -- Return which targets were hurt/killed
        return hurt, dead
    end
end

skills = {
    ['sever'] = Skill('sever', 'Sever',
        'Executioner', WEAPON, MANUAL, str_to_icon['force'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        genericAttack(
            WEAPON, ENEMY, Scaling(0, 'force', 1.0)
        ),
        "Slice at an adjacent enemy's exposed limbs, crippling them. Deals \z
         (Force * 1.0) weapon damage to an enemy next to Abelon."
    ),
    ['conflagration'] = Skill('conflagration', 'Conflagration',
        'Demon', SPELL, MANUAL, str_to_icon['empty'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        mkLine(10), DIRECTIONAL_AIM, 5,
        genericAttack(
            SPELL, ENEMY, Scaling(30, 'force', 0)
        ),
        "Scour the battlefield with unholy fire. Deals 30 spell \z
         damage to all enemies in a line across the entire map."
    ),
    ['guard_blindspot'] = Skill('guard_blindspot', 'Guard Blindspot',
        'Veteran', ASSIST, MANUAL, str_to_icon['affinity'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        genericAssist({
            { 'reaction', Scaling(0, 'affinity', 1.0) }
        }),
        "Protect an adjacent ally from wounds to the back. Adds \z
         (Affinity * 1.0) to ally's Reaction."
    ),
    ['judgement'] = Skill('judgement', 'Judgement',
        'Executioner', SPELL, MANUAL, str_to_icon['empty'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 1 } },
        { { T } }, FREE_AIM(100, ENEMY), 2,
        function(sp, assists, ts, ts_assists, status)
            local dead = {}
            for i = 1, #ts do
                if ts[i].health <= 10 then
                    ts[i].health = 0
                    table.insert(dead, ts[i])
                end
            end
            return {}, dead
        end,
        "Instantly kill an enemy anywhere on the field with less than 10 \z
         health remaining, bypassing protective status effects."
    ),
    ['inspire'] = Skill('inspire', 'Inspire',
        'Veteran', ASSIST, MANUAL, str_to_icon['affinity'],
        { { 'Demon', 1 }, { 'Veteran', 1 }, { 'Executioner', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 0,
        genericAssist({
            { 'force',    Scaling(0, 'affinity', 1.0) },
            { 'reaction', Scaling(0, 'affinity', 1.0) },
            { 'affinity', Scaling(0, 'affinity', 1.0) }
        }),
        "Inspire a distant ally with a courageous cry. Adds (Affinity * 1.0) \z
         to ally's Force, Reaction, and Affinity."
    ),
    ['trust'] = Skill('trust', 'Trust',
        'Veteran', WEAPON, MANUAL, str_to_icon['affinity'],
        { { 'Demon', 0 }, { 'Veteran', 2 }, { 'Executioner', 0 } },
        { { T } }, SELF_CAST_AIM, 0,
        genericAttack(
            WEAPON, ALLY, nil,
            { { 'affinity', Scaling(0, 'affinity', 2.0) } }, 1
        ),
        "Place your faith in your comrades. Triples Abelon's Affinity for the \z
         rest of the turn."
    ),
    ['crucible'] = Skill('crucible', 'Crucible',
        'Demon', SPELL, MANUAL, str_to_icon['force'],
        { { 'Demon', 2 }, { 'Veteran', 0 }, { 'Executioner', 1 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, T, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 8,
        genericAttack(
            SPELL, ENEMY, Scaling(0, 'force', 2.0),
            nil, nil,
            nil, nil,
            { ['self'] = true }
        ),
        "Unleash a scorching miasma. Abelon and nearby enemies suffer \z
         (Force * 2.0) spell damage (cannot kill Abelon)."
    ),
    ['contempt'] = Skill('contempt', 'Contempt',
        'Demon', SPELL, MANUAL, str_to_icon['focus'],
        { { 'Demon', 1 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { F, T, F, T, F },
          { F, F, T, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F },
          { F, F, F, F, F } }, DIRECTIONAL_AIM, 2,
        genericAttack(
            SPELL, ENEMY, nil,
            nil, nil,
            { { 'reaction', Scaling(0, 'focus', -1.0) } }, 2
        ),
        "Glare with an evil eye lit by ignea, reducing the Reaction of \z
         affected enemies by (Focus * 1.0) for two turns."
    ),
    ['enrage'] = Skill('enrage', 'Enrage',
        'Defender', SPELL, MANUAL, str_to_icon['empty'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, F, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, 1,
        genericAttack(
            SPELL, ENEMY, nil,
            nil, nil,
            { { 'special', 'enrage', DEBUFF } }, 1
        ),
        "Confuse and enrage nearby enemies with a mist of activated ignea, so \z
         that their next actions will target Kath."
    ),
    ['sweep'] = Skill('sweep', 'Sweep',
        'Hero', WEAPON, MANUAL, str_to_icon['force'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { F, F, F },
          { T, T, T },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        genericAttack(
            WEAPON, ENEMY, Scaling(0, 'force', 0.5),
            { { 'reaction', Scaling(2, 'force', 0) } }, 1
        ),
        "Slash in a wide arc. Deals (Force * 0.5) weapon damage to enemies in \z
         front of Kath, and grants 2 Reaction until his next turn."
    ),
    ['stun'] = Skill('stun', 'Stun',
        'Defender', WEAPON, MANUAL, str_to_icon['reaction'],
        { { 'Defender', 1 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { T } }, DIRECTIONAL_AIM, 1,
        genericAttack(
            WEAPON, ENEMY, nil,
            nil, nil,
            { { 'special', 'stun', DEBUFF } }, 1,
            { ['br'] = function(a, b) return a['reaction'] > b['reaction'] end }
        ),
        "Kath pushes ignea into his lance and strikes. If Kath's Reaction is \z
         higher than his foe's, they are unable to act for a turn."
    ),
    ['blessed_mist'] = Skill('blessed_mist', 'Blessed Mist',
        'Cleric', SPELL, MANUAL, str_to_icon['affinity'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { T, T, T },
          { T, F, T },
          { T, T, T } }, FREE_AIM(3, ALL), 3,
        genericAttack(
            SPELL, ALLY, Scaling(0, 'affinity', -1.0)
        ),
        "Infuse the air to close wounds. Allies in the area recover \z
         (Affinity * 1.0) health. Can target a square within three spaces of \z
         Kath."
    ),
    ['javelin'] = Skill('javelin', 'Javelin',
        'Hero', WEAPON, MANUAL, str_to_icon['force'],
        { { 'Defender', 0 }, { 'Hero', 1 }, { 'Cleric', 0 } },
        { { F, T, F },
          { F, F, F },
          { F, F, F } }, DIRECTIONAL_AIM, 0,
        genericAttack(
            WEAPON, ENEMY, Scaling(0, 'force', 1.5)
        ),
        "Kath hurls a javelin at an enemy, dealing (Force * 1.5) weapon \z
         damage."
    ),
    ['forbearance'] = Skill('forbearance', 'Forbearance',
        'Defender', ASSIST, MANUAL, str_to_icon['endurance'],
        { { 'Defender', 1 }, { 'Hero', 1 }, { 'Cleric', 0 } },
        { { T } }, DIRECTIONAL_AIM, 0,
        genericAssist({
            { 'special', 'forbearance', BUFF }
        }),
        "Kath receives all attacks meant for an adjacent ally."
    ),
    ['haste'] = Skill('haste', 'Haste',
        'Cleric', SPELL, MANUAL, str_to_icon['empty'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 1 } },
        { { F, F, T, F, F },
          { F, F, T, F, F },
          { T, T, F, T, T },
          { F, F, T, F, F },
          { F, F, T, F, F } }, SELF_CAST_AIM, 2,
        genericAttack(
            SPELL, ALLY, nil,
            nil, nil,
            { { 'agility', Scaling(10, 'force', 0) } }, 1
        ),
        "Kath raises the agility of allies around him by 10."
    ),
    ['guardian_angel'] = Skill('guardian_angel', 'Guardian Angel',
        'Cleric', ASSIST, MANUAL, str_to_icon['empty'],
        { { 'Defender', 2 }, { 'Hero', 0 }, { 'Cleric', 2 } },
        { { F, F, T, T, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, 5,
        genericAssist({
            { 'special', 'guardian_angel', BUFF }
        }),
        "Kath casts a powerful protective spell. Assisted allies cannot \z
         drop below 1 health for the remainder of the turn."
    ),
    ['hold_the_line'] = Skill('hold_the_line', 'Hold the Line',
        'Hero', ASSIST, MANUAL, str_to_icon['force'],
        { { 'Defender', 1 }, { 'Hero', 2 }, { 'Cleric', 0 } },
        mkLine(10), DIRECTIONAL_AIM, 0,
        genericAssist({
            { 'reaction', Scaling(0, 'force', 0.5) }
        }),
        "Kath forms a wall with his allies, raising the Reaction of assisted \z
         allies by (Force * 0.5)"
    ),
    ['bite'] = Skill('bite', 'Bite',
        'Enemy', WEAPON, KILL, str_to_icon['force'],
        {},
        { { T } }, DIRECTIONAL_AIM, 0,
        genericAttack(
            WEAPON, ALLY, Scaling(0, 'force', 1.0)
        ),
        "Leap at an adjacent enemy and bite into them. Deals \z
         (Force * 1.0) weapon damage to an enemy next to the user."
    ),
}
