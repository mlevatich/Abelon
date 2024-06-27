require 'src.Util'
require 'src.Constants'

require 'src.Script'

function mkAreaTrigger(scene_id, map_id, xTrigger, yTrigger, persist)
    return {
        function(g)
            local x, y = g.player:getPosition()
            local id = g.current_map:getName()
            if id == map_id then
                local tile = g.current_map:tileAtExact(x, y)
                if xTrigger(tile['x']) and yTrigger(tile['y']) then
                    return scene_id
                end
            end
            return nil
        end,
        persist
    }
end

function mkSimpleTrigger(check, action)
    return function(g)
        if check(g) then
            action(g)
            return DELETE
        else
            return nil
        end
    end
end

scene_triggers = {
    ['1-1'] = {
        ['1-1-entry'] = mkAreaTrigger('1-1-entry', 'east-forest',
            function(x) return true end,
            function(y) return true end
        ),
        ['1-1-battle'] = mkAreaTrigger('1-1-battle', 'south-forest',
            function(x) return x < 47 end,
            function(y) return y < 15 end
        ),
        ['1-1-see-camp'] = mkAreaTrigger('1-1-see-camp', 'west-forest',
            function(x) return x < 70 end,
            function(y) return true end
        ),
        ['end-tutorial1'] = mkAreaTrigger('1-1-close-tutorial-1', 'south-forest',
            function(x) return true end,
            function(y) return true end
        )
    },
    ['1-2'] = {
        ['1-2-battle'] = mkAreaTrigger('1-2-battle', 'west-forest',
            function(x) return true end,
            function(y) return true end
        ),
        ['end-tutorial-lvl1'] = mkAreaTrigger('1-2-close-tutorial-lvl', 'south-forest',
            function(x) return true end,
            function(y) return true end
        ),
        ['north-transition'] = mkAreaTrigger('1-2-north-transition', 'west-forest',
            function (x) return x < 51 end,
            function (y) return y < 1.4 end, true
        )
    },
    ['1-3'] = {
        ['1-3-entry'] = mkAreaTrigger('1-3-entry', 'west-forest',
            function(x) return true end,
            function(y) return true end
        ),
        ['1-3-battle'] = mkAreaTrigger('1-3-battle', 'monastery-approach',
            function(x) return x > 12 and x < 28 end,
            function(y) return y < 47 end
        ),
        ['1-3-golem-battle'] = mkAreaTrigger('1-3-golem-battle', 'monastery-entrance',
            function(x) return x > 42 and x < 65 end,
            function(y) return true end
        ),
        ['1-3-north-prevent'] = {
            function(g)
                local x, y = g.player:getPosition()
                local id = g.current_map:getName()
                if id == 'monastery-entrance' then
                    local tile = g.current_map:tileAtExact(x, y)
                    if tile['y'] < 43 and g.state['golem-battle-win'] then
                        return '1-3-north-prevent'
                    end
                end
                return nil
            end,
            true
        },
        ['1-3-south-transition'] = {
            function(g)
                local x, y = g.player:getPosition()
                local id = g.current_map:getName()
                if id == 'monastery-entrance' then
                    local tile = g.current_map:tileAtExact(x, y)
                    if tile['y'] > 53.3 and g.state['golem-battle-win'] then
                        return '1-3-south-transition'
                    end
                end
                return nil
            end,
            true
        }
    },
    ['1-4'] = {
        ['1-4-entry'] = mkAreaTrigger('1-4-entry', 'monastery-entrance',
            function(x) return true end,
            function(y) return true end
        ),
        ['1-4-battle'] = mkAreaTrigger('1-4-battle', 'monastery-approach',
            function(x) return x > 34 and x < 48 end,
            function(y) return y < 16 end
        ),
        ['1-4-final-battle'] = mkAreaTrigger('1-4-final-battle', 'monastery-entrance',
            function(x) return x < 42 end,
            function(y) return y < 42 end
        )
    }
}

function mkUseTrigger(id, check)
    return function(g)
        if check(g) then
            g:launchScene(id .. '-use')
            return
        end
        g:launchScene(id .. '-use-fail')
    end
end

function mkSimpleUseTrigger(id)
    return mkUseTrigger(id, function(g) return true end)
end

item_triggers = {
    ['medallion']    = mkSimpleUseTrigger('medallion'),
    ['journal']      = mkSimpleUseTrigger('journal'),
    ['scroll']       = mkSimpleUseTrigger('scroll'),
    ['igneashard1']  = mkSimpleUseTrigger('igneashard1'),
    ['igneashard2']  = mkSimpleUseTrigger('igneashard2'),
    ['igneashard3']  = mkSimpleUseTrigger('igneashard3'),
    ['igneashard4']  = mkSimpleUseTrigger('igneashard4'),
    ['igneashard5']  = mkSimpleUseTrigger('igneashard5'),
    ['igneashard6']  = mkSimpleUseTrigger('igneashard6'),
    ['igneashard7']  = mkSimpleUseTrigger('igneashard7'),
    ['igneashard8']  = mkSimpleUseTrigger('igneashard8'),
    ['igneashard9']  = mkSimpleUseTrigger('igneashard9'),
    ['igneashard10'] = mkSimpleUseTrigger('igneashard10')
}

function mkTurnTrigger(t, phase)
    return function(b)
        if b.turn == t then
            return ite(phase == ALLY, 'ally', 'enemy') .. '-turn-' .. t
        end
        return false
    end
end

function mkSelectTrigger(sp_id)
    return function(b)
        if b:getSprite():getId() == sp_id then
            return 'select-' .. sp_id
        end
        return false
    end
end

battle_triggers = {
    ['1-1'] = {
        [SELECT] = {},
        [ALLY] = {
            ['tutorial2'] = mkTurnTrigger(1, ALLY),
            ['tutorial3'] = mkTurnTrigger(2, ALLY)
        },
        [ENEMY] = {},
        [END_ACTION] = {
            ['end-tutorial2'] = function(b)
                if b.game.current_tutorial then
                    return 'close-tutorial2'
                end
                return false
            end,
            ['end-tutorial3'] = function(b)
                if b.game.current_tutorial then
                    return 'close-tutorial3'
                end
                return false
            end
        }
    },
    ['1-2'] = {
        [SELECT] = {
            ['select-kath'] = mkSelectTrigger('kath'),
            ['select-abelon'] = mkSelectTrigger('abelon')
        },
        [ALLY] = {
            ['ally-turn1'] = mkTurnTrigger(1, ALLY),
            ['ally-turn2'] = mkTurnTrigger(2, ALLY),
            ['ally-turn3'] = mkTurnTrigger(3, ALLY),
            ['ally-turn4'] = mkTurnTrigger(4, ALLY)
        },
        [ENEMY] = {
            ['enemy-turn1'] = mkTurnTrigger(1, ENEMY)
        },
        [END_ACTION] = {
            ['demonic-spell'] = function(b)
                local atk = b.status['abelon']['attack']
                if atk and (atk.id == 'conflagration' or atk.id == 'crucible') then
                    return 'demonic-spell'
                end
                return false
            end,
            ['end-tutorial1'] = function(b)
                if b.game.current_tutorial == "Battle: Assists" then
                    return 'close-tutorial-1'
                end
                return false
            end,
            ['end-tutorial2'] = function(b)
                if b.game.current_tutorial == "Battle: Ignea" then
                    return 'close-tutorial-2'
                end
                return false
            end,
            ['end-tutorial3'] = function(b)
                if b.game.current_tutorial == "Battle: Attributes" then
                    return 'close-tutorial-3'
                end
                return false
            end,
            ['end-tutorial4'] = function(b)
                if b.game.current_tutorial == "Battle: Reminder" then
                    return 'close-tutorial-4'
                end
                return false
            end
        }
    },
    ['1-3'] = {
        [SELECT] = {},
        [ALLY] = {},
        [ENEMY] = {},
        [END_ACTION] = {
            ['demonic-spell'] = function(b)
                local unseen = not b.game.state['kath-saw-spell']
                local atk = b.status['abelon']['attack']
                if unseen and atk and (atk.id == 'conflagration' or atk.id == 'crucible') then
                    return 'demonic-spell'
                end
                return false
            end
        }
    },
    ['1-3-golem-battle'] = {
        [SELECT] = {},
        [ALLY] = {
            ['ally-turn1'] = mkTurnTrigger(1, ALLY),
            ['ally-turn3'] = mkTurnTrigger(3, ALLY),
            ['ally-turn4'] = mkTurnTrigger(4, ALLY)
        },
        [ENEMY] = {},
        [END_ACTION] = {
            ['demonic-spell'] = function(b)
                local unseen = not b.game.state['kath-saw-spell']
                local atk = b.status['abelon']['attack']
                if unseen and atk and (atk.id == 'conflagration' or atk.id == 'crucible') then
                    return 'demonic-spell'
                end
                return false
            end,
            ['end-tutorial1'] = function(b)
                if b.game.current_tutorial == "Battle: Objectives" then
                    return 'close-tutorial-1'
                end
                return false
            end
        }
    },
    ['1-4'] = {
        [SELECT] = {},
        [ALLY] = {
            ['ally-turn1'] = mkTurnTrigger(1, ALLY),
            ['ally-turn2'] = mkTurnTrigger(2, ALLY),
            ['ally-turn4'] = mkTurnTrigger(4, ALLY),
            ['ally-turn6'] = mkTurnTrigger(6, ALLY),
            ['ally-turn8'] = mkTurnTrigger(8, ALLY),
            ['ally-turn9'] = mkTurnTrigger(9, ALLY)
        },
        [ENEMY] = {},
        [END_ACTION] = {
            ['demonic-spell'] = function(b)
                local unseen = not b.game.state['kath-saw-spell']
                local atk = b.status['abelon']['attack']
                if unseen and atk and (atk.id == 'conflagration' or atk.id == 'crucible') then
                    return 'demonic-spell'
                end
                return false
            end,
            ['lester-healed'] = function(b)
                local atk = b.status['kath']['attack']
                local lester_hp = b.status['lester']['sp'].health
                if atk and (atk.id == 'healing_mist' or atk.id == 'sacrifice') and lester_hp > 1 then
                    return 'lester-healed'
                end
                return false
            end
        }
    },
    ['1-4-final-battle'] = {
        [SELECT] = {},
        [ALLY] = {},
        [ENEMY] = {},
        [END_ACTION] = {
            ['demonic-spell'] = function(b)
                local unseen = not b.game.state['kath-saw-spell']
                local atk = b.status['abelon']['attack']
                if unseen and atk and (atk.id == 'conflagration' or atk.id == 'crucible') then
                    return 'demonic-spell'
                end
                return false
            end
        }
    }
}
