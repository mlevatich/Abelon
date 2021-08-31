require 'Util'
require 'Constants'

require 'Menu'

Skill = Class{}

function Skill:init(id, n, ti, st, si, tr, r, at, t, c, e, d)

    -- Identifying info
    self.id           = id
    self.name         = n
    self.tree_id      = ti
    self.type         = st
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
    self.target = t  -- Who does your cursor have to be on for this to succeed?
    self.cost   = c  -- Ignea cost
    self.use    = e  -- Function taking the caster and target as inputs
                     -- returns targets hurt and targets dead
end

function Skill:toMenuItem(itex, icons, with_skilltrees)
    local hbox = self:mkSkillBox(itex, icons, with_skilltrees)
    return MenuItem(self.name, {}, nil, {
        ['elements'] = hbox,
        ['w'] = HBOX_WIDTH
    }, nil, nil, nil, self.id)
end

function Skill:mkSkillBox(itex, icons, with_skilltrees)
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
                req_x + 8, req_y + LINE_HEIGHT + 2, itex),
            mkEle('text', {tostring(self.reqs[2][2])},
                req_x + BOX_MARGIN * 2 + 8, req_y + LINE_HEIGHT + 2, itex),
            mkEle('text', {tostring(self.reqs[3][2])},
                req_x + BOX_MARGIN * 4 + 8, req_y + LINE_HEIGHT + 2, itex),
            mkEle('text', {'Requirements'},
                req_x, req_y + LINE_HEIGHT * 2),
            mkEle('text', {'  to learn  '},
                req_x, req_y + LINE_HEIGHT * 3)
        })
    end
    return hbox
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

skills = {
    ['sever'] = Skill('sever', 'Sever',
        'Executioner', WEAPON, str_to_icon['force'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, ENEMY, 0,
        function(sp, assists, ts, ts_assists, status)
            local atk = sp.attributes['force'] * 1
            local hurt = {}
            local dead = {}
            for i = 1, #ts do
                if abs(ts[i].x - sp.x) > TILE_WIDTH / 2 then
                    ts[i].dir = ite(ts[i].x > sp.x, LEFT, RIGHT)
                end
                local def = math.floor(ts[i].attributes['reaction'] / 2)
                ts[i].health = math.max(0,
                    ts[i].health - math.max(0, (atk - def)))
                table.insert(ite(ts[i].health == 0, dead, hurt), ts[i])
            end
            return hurt, dead
        end,
        "Slice at an adjacent enemy's exposed limbs, crippling them. Deals \z
         (Force * 1.0) weapon damage to an enemy next to Abelon."
    ),
    ['conflagration'] = Skill('conflagration', 'Conflagration',
        'Demon', SPELL, str_to_icon['force'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        mkLine(10), DIRECTIONAL_AIM, ALL, 5,
        function(sp, assists, ts, ts_assists, status)
            local atk = sp.attributes['force'] * 2
            local hurt = {}
            local dead = {}
            for i = 1, #ts do
                if abs(ts[i].x - sp.x) > TILE_WIDTH / 2 then
                    ts[i].dir = ite(ts[i].x > sp.x, LEFT, RIGHT)
                end
                ts[i].health = math.max(0, ts[i].health - atk)
                table.insert(ite(ts[i].health == 0, dead, hurt), ts[i])
            end
            sp.ignea = sp.ignea - 5
            return hurt, dead
        end,
        "Scour the battlefield with unholy fire. Deals (Force * 2.0) spell \z
         damage to all enemies in a line across the entire map."
    ),
    ['guard_blindspot'] = Skill('guard_blindspot', 'Guard Blindspot',
        'Veteran', ASSIST, str_to_icon['affinity'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 0 } },
        { { T } }, DIRECTIONAL_AIM, ALLY, 0,
        function(attributes)
            return
        end,
        "Protect an adjacent ally from wounds to the back. Adds \z
         (Affinity * 1.0) to ally's Reaction."
    ),
    ['judgement'] = Skill('judgement', 'Judgement',
        'Executioner', SPELL, str_to_icon['empty'],
        { { 'Demon', 0 }, { 'Veteran', 0 }, { 'Executioner', 1 } },
        { { T } }, FREE_AIM(100, ENEMY), ENEMY, 2,
        function(sp, assists, ts, ts_assists, status)
            local dead = {}
            for i = 1, #ts do
                if ts[i].health <= 10 then
                    ts[i].health = 0
                    table.insert(dead, ts[i])
                end
            end
            sp.ignea = sp.ignea - 2
            return {}, dead
        end,
        "Instantly kill an enemy anywhere on the field with less than 10 \z
         health remaining."
    ),
    ['inspire'] = Skill('inspire', 'Inspire',
        'Veteran', ASSIST, str_to_icon['affinity'],
        { { 'Demon', 1 }, { 'Veteran', 1 }, { 'Executioner', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, ALLY, 0,
        function(attributes)
            return
        end,
        "Inspire a distant ally with a courageous cry. Adds (Affinity * 1.0) \z
         to ally's Force, Reaction, and Affinity."
    ),
    ['trust'] = Skill('trust', 'Trust',
        'Veteran', WEAPON, str_to_icon['affinity'],
        { { 'Demon', 0 }, { 'Veteran', 2 }, { 'Executioner', 0 } },
        { { T } }, SELF_CAST_AIM, ALL, 0,
        function(sp, assists, ts, ts_assists, status)
            return
        end,
        "Place your faith in your comrades. Triples Abelon's Affinity for the \z
         rest of the turn."
    ),
    ['crucible'] = Skill('crucible', 'Crucible',
        'Demon', SPELL, str_to_icon['force'],
        { { 'Demon', 1 }, { 'Veteran', 0 }, { 'Executioner', 1 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, T, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, ALL, 8,
          function(sp, assists, ts, ts_assists, status)
              local atk = sp.attributes['force'] * 3
              local hurt = {}
              local dead = {}
              for i = 1, #ts do
                  if abs(ts[i].x - sp.x) > TILE_WIDTH / 2 then
                      ts[i].dir = ite(ts[i].x > sp.x, LEFT, RIGHT)
                  end
                  local remain = ite(ts[i] == sp, 1, 0)
                  ts[i].health = math.max(remain, ts[i].health - atk)
                  table.insert(ite(ts[i].health == 0, dead, hurt), ts[i])
              end
              sp.ignea = sp.ignea - 8
              return hurt, dead
          end,
          "Unleash a scorching miasma. Abelon and nearby enemies suffer \z
          (Force * 3.0) spell damage (cannot kill Abelon)."
    ),
    ['enrage'] = Skill('enrage', 'Enrage',
        'Defender', SPELL, str_to_icon['empty'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { F, F, F, T, F, F, F },
          { F, F, T, T, T, F, F },
          { F, T, T, T, T, T, F },
          { T, T, T, F, T, T, T },
          { F, T, T, T, T, T, F },
          { F, F, T, T, T, F, F },
          { F, F, F, T, F, F, F } }, SELF_CAST_AIM, ALL, 1,
        function(sp, assists, ts, ts_assists, status)
            for i = 1, #ts do
                if abs(ts[i].x - sp.x) > TILE_WIDTH / 2 then
                    ts[i].dir = ite(ts[i].x > sp.x, LEFT, RIGHT)
                end
            end
            return {}, {}
        end,
        "Confuse and enrage nearby enemies with a mist of activated ignea, so \z
         that their next actions will target Kath."
    ),
    ['sweep'] = Skill('sweep', 'Sweep',
        'Hero', WEAPON, str_to_icon['force'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { F, F, F },
          { T, T, T },
          { F, F, F } }, DIRECTIONAL_AIM, ALL, 0,
        function(sp, assists, ts, ts_assists, status)
            local atk = sp.attributes['force'] * 1
            local hurt = {}
            local dead = {}
            for i = 1, #ts do
                if abs(ts[i].x - sp.x) > TILE_WIDTH / 2 then
                    ts[i].dir = ite(ts[i].x > sp.x, LEFT, RIGHT)
                end
                local def = math.floor(ts[i].attributes['reaction'] / 2)
                ts[i].health = math.max(0,
                    ts[i].health - math.max(0, math.max(0, (atk - def))))
                table.insert(ite(ts[i].health == 0, dead, hurt), ts[i])
            end
            return hurt, dead
        end,
        "Slash in a wide arc. Deals (Force * 0.5) weapon damage to enemies in \z
         front of Kath, and grants 2 Reaction until his next turn."
    ),
    ['blessed_sky'] = Skill('blessed_sky', 'Blessed Sky',
        'Cleric', ASSIST, str_to_icon['affinity'],
        { { 'Defender', 0 }, { 'Hero', 0 }, { 'Cleric', 0 } },
        { { T, T, T },
          { T, T, T },
          { T, T, T } }, FREE_AIM(3, ALL), ALL, 1,
        function(attributes)
            return
        end,
        "Infuse the air to heal wounds. Assisted allies recover \z
         (Affinity * 1.0) health. Can target a square within three spaces of \z
         Kath."
    ),
    ['forbearance'] = Skill('forbearance', 'Forbearance',
        'Defender', ASSIST, str_to_icon['affinity'],
        { { 'Defender', 1 }, { 'Hero', 1 }, { 'Cleric', 0 } },
        { { T } }, DIRECTIONAL_AIM, ALLY, 0,
        function(attributes)
            return
        end,
        "Kath gains (Affinity * 0.5) Reaction and receives all damage meant \z
         for an adjacent ally."
    ),
    ['guardian_angel'] = Skill('guardian_angel', 'Guardian Angel',
        'Cleric', ASSIST, str_to_icon['empty'],
        { { 'Defender', 1 }, { 'Hero', 0 }, { 'Cleric', 1 } },
        { { F, F, T, T, T, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F },
          { F, F, F, F, F, F, F } }, DIRECTIONAL_AIM, ALLY, 5,
          function(attributes)
              return
          end,
          "Kath casts a powerful protective spell. Assisted allies cannot \z
           receive damage until the next turn."
    ),
    ['hold_the_line'] = Skill('hold_the_line', 'Hold the Line',
        'Hero', ASSIST, str_to_icon['force'],
        { { 'Defender', 1 }, { 'Hero', 2 }, { 'Cleric', 0 } },
        mkLine(10), DIRECTIONAL_AIM, ALLY, 0,
        function(attributes)
            return
        end,
        "Kath forms a wall with his allies, raising the Reaction of assisted \z
         allies by (Force * 0.5)"
    ),
    ['bite'] = Skill('bite', 'Bite',
        'Enemy', WEAPON, str_to_icon['force'],
        {},
        { { T } }, DIRECTIONAL_AIM, ENEMY, 0,
        function(sp, assists, ts, ts_assists, status)
            local atk = sp.attributes['force'] * 1
            local hurt = {}
            local dead = {}
            for i = 1, #ts do
                if abs(ts[i].x - sp.x) > TILE_WIDTH / 2 then
                    ts[i].dir = ite(ts[i].x > sp.x, LEFT, RIGHT)
                end
                local def = math.floor(ts[i].attributes['reaction'] / 2)
                ts[i].health = math.max(0,
                    ts[i].health - math.max(0, (atk - def)))
                table.insert(ite(ts[i].health == 0, dead, hurt), ts[i])
            end
            return hurt, dead
        end,
        "Leap at an adjacent enemy and bite into them. Deals \z
         (Force * 1.0) weapon damage to an enemy next to the user."
    ),
}
