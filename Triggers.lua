require 'Util'
require 'Constants'

require 'Scripts'

function mkAreaTrigger(scene_id, map_id, xTrigger, yTrigger)
    return function(c)
        local x, y = c.player:getPosition()
        local id = c.current_map:getName()
        if id == map_id then
            local tile = c.current_map:tileAt(x, y)
            if xTrigger(tile['x']) and yTrigger(tile['y']) then
                return scene_id
            end
        end
        return nil
    end
end

function mkSimpleTrigger(check, action)
    return function(c)
        if check(c) then
            action(c)
            return DELETE
        else
            return nil
        end
    end
end

scene_triggers = {
    ['1-1-entry'] = mkAreaTrigger('1-1-entry', 'east-forest',
        function(x) return true end,
        function(y) return true end
    ),
    ['meet-kath'] = mkAreaTrigger('meet-kath', 'west-forest',
        function(x) return x > 24 end,
        function(y) return true end
    )
}

function mkUseTrigger(id, checks, actions)
    return function(c)
        for i=1, #checks do
            if checks[i](c) then
                actions[i](c)
                return
            end
        end
        c:launchScene(id .. '-use-fail')
    end
end

item_triggers = {
    ['medallion'] = mkUseTrigger('medallion',
        { function(c) return true end },
        { function(c) c:launchScene('medallion-use') end }
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
        [SELECT] = {
            ['select-kath'] = mkSelectTrigger('kath')
        },
        [ALLY] = {
            ['ally-turn1'] = mkTurnTrigger(1, ALLY),
            ['ally-turn2'] = mkTurnTrigger(2, ALLY)
        },
        [ENEMY] = {
            ['enemy-turn1'] = mkTurnTrigger(1, ENEMY)
        },
        [END_ACTION] = {
            ['first-demonic-spell'] =  function(b)
                local saw = b.chapter.state['kath-saw-spell']
                local atk = b.status['abelon']['attack']
                if atk then atk = atk.id end
                if not saw and atk == 'conflagration' or atk == 'crucible' then
                    return 'abelon-demon'
                end
                return false
            end
        }
    }
}
