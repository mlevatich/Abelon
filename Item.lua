require 'Util'
require 'Constants'

require 'Menu'
require 'Scripts'

Item = Class{}

function Item:init(id, name, f_use, f_present, can_discard)
    self.id = id
    self.name = name
    self.f_use = f_use
    self.f_present = f_present
    self.can_discard = can_discard

    scripts[self.id .. '_use_fail'] = {
        ['ids'] = {self.id},
        ['events'] = {
            say(1, 0, false,
                "There's no use for the " .. string.lower(self.name) .. " at \z
                 the moment."
            )
        },
        ['result'] = {}
    }
    scripts[self.id .. '_present_fail'] = {
        ['ids'] = {self.id},
        ['events'] = {
            say(1, 0, false,
                "You remove the " .. string.lower(self.name) .. " from your \z
                 pack, but no one nearby seems to notice."

            )
        },
        ['result'] = {}
    }

    if self.can_discard then
        scripts[self.id .. '_discard'] = {
            ['ids'] = {self.id},
            ['events'] = {
                say(1, 0, false,
                    "You remove the " .. string.lower(self.name) .. " from \z
                     your pack and leave it behind."
                )
            },
            ['result'] = {
                ['do'] = function(c)
                    c.player:discard(self.id)
                end
            }
        }
    end

    self.sp = nil -- Filled when the item enters the player's inventory
end

function Item:toMenuItem()
    local n = self.name
    local u = MenuItem('Use', {}, nil, nil, self.f_use)
    local p = MenuItem('Present', {}, nil, nil, self.f_present)
    local children = {u, p}
    if self.can_discard then
        local f_discard = mkDiscard(self.id)
        local d = MenuItem('Discard', {}, nil, nil, f_discard,
            "Discard the " .. string.lower(n) .. "? It will be gone forever."
        )
        table.insert(children, d)
    end
    return MenuItem(n, children, 'See item options')
end

function mkUseOrPresent(checks, actions, default)
    return function(c)
        for i=1, #checks do
            if checks[i](c) then
                actions[i](c)
                return
            end
        end
        c:launchScene(default)
    end
end

function mkUse(id, checks, actions)
    return mkUseOrPresent(checks, actions, id .. '_use_fail')
end

function mkPresent(id, checks, actions)
    return mkUseOrPresent(checks, actions, id .. '_present_fail')
end

function mkDiscard(id)
    return function(c)
        c:launchScene(id .. '_discard')
    end
end

function launch(script_id)
    return function(c)
        c:launchScene(script_id)
    end
end

function nearKath(c)
    local x, y = c.player.sp:getPosition()
    local kx, ky = c.current_map:getSpriteById('kath'):getPosition()
    return abs(x - kx) <= TILE_WIDTH * 4 and abs(y - ky) <= TILE_HEIGHT * 4
end

items = {

    ['medallion'] = Item(
        'medallion',
        'Silver medallion',
        mkUse('medallion',
            { function(c) return true end },
            { launch('medallion_use') }
        ),
        mkPresent('medallion',
            { nearKath },
            { launch('medallion_present_kath') }
        ),
        true
    ),

    ["sword"] = Item(
        'sword',
        "Sword",
        mkUse('sword', {}, {}),
        mkPresent('sword', {}, {}),
        false
    ),

    ["cloak"] = Item(
        'cloak',
        "Cloak",
        mkUse('cloak', {}, {}),
        mkPresent('cloak', {}, {}),
        false
    ),

    ["boots"] = Item(
        'boots',
        "Boots",
        mkUse('boots', {}, {}),
        mkPresent('boots', {}, {}),
        false
    ),

    ["armor"] = Item(
        'armor',
        "Armor",
        mkUse('armor', {}, {}),
        mkPresent('armor', {}, {}),
        false
    ),

    ["helmet"] = Item(
        'helmet',
        "Helmet",
        mkUse('helmet', {}, {}),
        mkPresent('helmet', {}, {}),
        false
    ),

    ["rock_of_ignea"] = Item(
        'rock_of_ignea',
        'Rock of ignea',
        mkUse('rock_of_ignea', {}, {}),
        mkPresent('rock_of_ignea', {}, {}),
        false
    ),

    ["wornfleet_leaf"] = Item(
        'wornfleet_leaf',
        'Wornfleet leaf',
        mkUse('wornfleet_leaf', {}, {}),
        mkPresent('wornfleet_leaf', {}, {}),
        false
    ),

    ["spelltonic"] = Item(
        'spelltonic',
        'Spelltonic',
        mkUse('spelltonic', {}, {}),
        mkPresent('spelltonic', {}, {}),
        false
    ),

    ["healing_salve"] = Item(
        'healing_salve',
        'Healing Salve',
        mkUse('healing_salve', {}, {}),
        mkPresent('healing_salve', {}, {}),
        false
    ),

    ["longbow"] = Item(
        'longbow',
        'Longbow',
        mkUse('longbow', {}, {}),
        mkPresent('longbow', {}, {}),
        false
    )
}
