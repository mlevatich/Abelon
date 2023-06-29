require 'src.Util'
require 'src.Constants'

require 'src.Script'

function mkAreaTrigger(scene_id, map_id, xTrigger, yTrigger)
    return function(g)
        local x, y = g.player:getPosition()
        local id = g.current_map:getName()
        if id == map_id then
            local tile = g.current_map:tileAt(x, y)
            if xTrigger(tile['x']) and yTrigger(tile['y']) then
                return scene_id
            end
        end
        return nil
    end
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
        ['close-tutorial1'] = mkAreaTrigger('1-1-close-tutorial1', 'south-forest',
            function(x) return true end,
            function(y) return true end
        )
    },
    ['1-2'] = {
        ['1-2-battle'] = mkAreaTrigger('1-2-battle', 'west-forest',
            function(x) return true end,
            function(y) return true end
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

item_triggers = {
    ['medallion'] = mkUseTrigger('medallion',
        function(g) return true end
    )
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
        [SELECT]     = {},
        [ALLY]       = {
            ['tutorial2'] = mkTurnTrigger(1, ALLY),
            ['tutorial3'] = mkTurnTrigger(2, ALLY)
        },
        [ENEMY]      = {},
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
            ['demonic-spell'] =  function(b)
                local atk = b.status['abelon']['attack']
                if atk and (atk.id == 'conflagration' or atk.id == 'crucible') then
                    return 'demonic-spell'
                end
                return false
            end,
            ['end-tutorial1'] = function(b)
                if b.game.current_tutorial then
                    return 'close-tutorial-1'
                end
                return false
            end,
            ['end-tutorial2'] = function(b)
                if b.game.current_tutorial then
                    return 'close-tutorial-2'
                end
                return false
            end,
            ['end-tutorial3'] = function(b)
                if b.game.current_tutorial then
                    return 'close-tutorial-3'
                end
                return false
            end,
            ['end-tutorial4'] = function(b)
                if b.game.current_tutorial then
                    return 'close-tutorial-4'
                end
                return false
            end
        }
    }
}
