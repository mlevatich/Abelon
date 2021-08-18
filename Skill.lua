require 'Util'
require 'Constants'

require 'Menu'

Skill = Class{}

function Skill:init(id, n, ti, st, tr, r, at, c, e, d)

    -- Identifying info
    self.id = id
    self.name = n
    self.tree_id = ti
    self.type = st
    self.desc = d

    -- Requirements to learn
    self.reqs = tr

    -- Battle effects
    self.range = r
    self.aim = at
    self.cost = c
    self.effect = e
end

function Skill:toMenuItem()
    local hbox = {}
    return MenuItem(self.name, {}, nil, hbox)
end

skills = {
    ['cleave'] = Skill('cleave', 'Cleave',
        'Executioner', WEAPON, {},
        nil, nil, 0, nil,
        "Slice across an enemy's body, cutting them open. Deals 17 \z
         (Force) weapon damage to an enemy next to Abelon."
    ),
    ['conflagration'] = Skill('conflagration', 'Conflagration',
        'Demon', SPELL, {},
        nil, nil, 5, nil,
        "Scour the battlefield with unholy fire. Deals 34 (Force * 2) spell \z
         damage to all enemies in a line."
    ),
    ['guard_blindspot'] = Skill('guard_blindspot', 'Guard Blindspot',
        'Champion', ASSIST, {},
        nil, nil, 0, nil,
        "Protect an ally from wounds to the back. Adds 4 (Affinity) to \z
         ally's Reaction."
    ),
    ['enrage'] = Skill('enrage', 'Enrage',
        'Defender', SPELL, {},
        nil, nil, 1, nil,
        "Confuse and enrage nearby enemies with a mist of activated ignea, so \z
         that their next actions will target Kath."
    ),
    ['sweep'] = Skill('sweep', 'Sweep',
        'Hero', WEAPON, {},
        nil, nil, 0, nil,
        "Sweep in a wide arc with a lance before raising a shield. Deals 5 \z
         (Force * 0.5) weapon damage to enemies in front of Kath, and grants \z
         him 2 Reaction until his next turn."
    ),
    ['blessed_sky'] = Skill('blessed_sky', 'Blessed Sky',
        'Cleric', ASSIST, {},
        nil, nil, 1, nil,
        "Infuse the nearby air with ignea so that it stitches wounds back \z
         together. Allies who end their turn near Kath immediately recover 10 \z
         (Affinity) health."
    )
}
